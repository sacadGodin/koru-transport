// Cloud Functions for Koru Hospital Transport.
//
//   createBooking   Patient sends the booking form. Saves the booking and
//                   returns its reference plus a secret tracking code.
//   lookupBooking   Patient types reference + code. Returns a tracking link
//                   (a long random token). Locks after too many wrong codes.
//   createDriver    Staff add a driver account (email + password).
//   updateDriver    Staff edit a driver's details, email or password.
//   deleteDriver    Staff remove a driver's account and profile.
//   syncTracking    Copies the safe parts of a booking (no name, phone or
//                   address) to tracking/{token}, which the patient's
//                   browser listens to for live updates.
//
// Secrets (code hash, tracking token, failed attempts) live in
// bookingSecrets/{ref}, which no browser can read (see firestore.rules).

const crypto = require('node:crypto');
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const {
  getFirestore,
  FieldValue,
  GeoPoint,
  Timestamp,
} = require('firebase-admin/firestore');
const { setGlobalOptions } = require('firebase-functions/v2');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');

initializeApp();
const db = getFirestore();

// Same place as the Firestore database, so triggers work and calls are fast.
setGlobalOptions({ region: 'asia-northeast1', maxInstances: 10 });

// Patients wait on these two, so one copy is always kept running. Without
// it the first call after a quiet period starts a new server ("cold start")
// and takes several seconds. Costs a few dollars a month per function; set
// to 0 to save that money and accept the slow first call.
const PATIENT_FACING = { minInstances: 1 };

const TYPES = ['ambulance', 'wheelchair', 'standard', 'airport'];
const NEEDS = ['wheelchair', 'stretcher', 'oxygen', 'companion'];

// Tracking codes use letters and digits that are hard to mix up
// (no 0/O, 1/I/L). 8 characters = about 850 billion possible codes.
const CODE_ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
const CODE_LENGTH = 8;

// Wrong codes allowed before a reference is locked, and for how long.
const MAX_FAILED_LOOKUPS = 5;
const LOCK_MINUTES = 15;

// ---------------------------------------------------------------------------
// Small helpers
// ---------------------------------------------------------------------------

function newCode() {
  let code = '';
  for (let i = 0; i < CODE_LENGTH; i++) {
    code += CODE_ALPHABET[crypto.randomInt(CODE_ALPHABET.length)];
  }
  return code;
}

// Long random id for tracking/{token}. Nobody can guess it, so knowing it
// is what gives access to the live status.
function newToken() {
  return crypto.randomBytes(24).toString('base64url');
}

function hashCode(ref, code) {
  return crypto.createHash('sha256').update(`${ref}:${code}`).digest('hex');
}

// Patients may type the code in lower case or with spaces/dashes.
function normalizeCode(code) {
  return String(code ?? '').toUpperCase().replace(/[^A-Z0-9]/g, '');
}

function text(value, name, max, { required = true } = {}) {
  if (typeof value !== 'string' || value.length > max ||
      (required && value.trim() === '')) {
    throw new HttpsError('invalid-argument', `Invalid ${name}.`);
  }
  return value.trim();
}

async function requireStaff(auth) {
  if (!auth) throw new HttpsError('unauthenticated', 'Sign in first.');
  const staff = await db.doc(`staff/${auth.uid}`).get();
  if (!staff.exists) throw new HttpsError('permission-denied', 'Staff only.');
}

// ---------------------------------------------------------------------------
// createBooking
// ---------------------------------------------------------------------------

// Checks the booking form. Returns the Firestore fields of the new booking
// (without ref/createdAt) or throws "invalid-argument".
function bookingFields(data) {
  if (!TYPES.includes(data.type)) {
    throw new HttpsError('invalid-argument', 'Invalid type.');
  }
  const needs = Array.isArray(data.needs) ? data.needs : [];
  if (needs.length > NEEDS.length || !needs.every((n) => NEEDS.includes(n))) {
    throw new HttpsError('invalid-argument', 'Invalid needs.');
  }
  // Date as milliseconds since 1970 (the day of the ride).
  if (!Number.isFinite(data.date)) {
    throw new HttpsError('invalid-argument', 'Invalid date.');
  }
  // Time as "09:30".
  if (typeof data.time !== 'string' ||
      !/^([01]\d|2[0-3]):[0-5]\d$/.test(data.time)) {
    throw new HttpsError('invalid-argument', 'Invalid time.');
  }
  let pickup = null;
  if (data.pickup != null) {
    const { lat, lng } = data.pickup;
    if (!Number.isFinite(lat) || !Number.isFinite(lng) ||
        Math.abs(lat) > 90 || Math.abs(lng) > 180) {
      throw new HttpsError('invalid-argument', 'Invalid pickup.');
    }
    pickup = new GeoPoint(lat, lng);
  }
  return {
    patient: text(data.patient, 'patient', 200),
    phone: text(data.phone, 'phone', 50),
    type: data.type,
    from: text(data.from, 'from', 500),
    branch: text(data.branch, 'branch', 200),
    date: Timestamp.fromMillis(data.date),
    time: data.time,
    needs: [...new Set(needs)],
    notes: text(data.notes ?? '', 'notes', 2000, { required: false }),
    pickup,
    stage: 'newRequest',
    vehicle: null,
    driver: null,
    driverUid: null,
    trip: null,
    driverLocation: null,
  };
}

exports.createBooking = onCall(PATIENT_FACING, async (request) => {
  const fields = bookingFields(request.data ?? {});
  const code = newCode();
  const token = newToken();

  // Takes the next number (KR-1001, KR-1002, ...) and saves the booking and
  // its secrets in one step, so two patients never get the same number.
  const ref = await db.runTransaction(async (tx) => {
    const counterRef = db.doc('counters/bookings');
    const counter = await tx.get(counterRef);
    const n = counter.get('next') ?? 1001;
    const ref = `KR-${n}`;
    tx.set(counterRef, { next: n + 1 });
    tx.create(db.doc(`bookings/${ref}`), {
      ...fields,
      ref,
      createdAt: FieldValue.serverTimestamp(),
    });
    tx.create(db.doc(`bookingSecrets/${ref}`), {
      codeHash: hashCode(ref, code),
      token,
      failedLookups: 0,
      lockedUntil: null,
    });
    return ref;
  });

  return { ref, code, token };
});

// ---------------------------------------------------------------------------
// lookupBooking
// ---------------------------------------------------------------------------

exports.lookupBooking = onCall(PATIENT_FACING, async (request) => {
  const ref = String(request.data?.ref ?? '').trim().toUpperCase();
  const code = normalizeCode(request.data?.code);
  // Same answer for "no such booking" and "wrong code", so the lookup does
  // not reveal which references exist.
  const notFound = new HttpsError('not-found',
      'Reference or code is not correct.');
  if (!/^KR-\d{1,9}$/.test(ref) || code.length !== CODE_LENGTH) throw notFound;

  const secretRef = db.doc(`bookingSecrets/${ref}`);
  const result = await db.runTransaction(async (tx) => {
    const secret = await tx.get(secretRef);
    if (!secret.exists) return { error: 'not-found' };

    const now = Date.now();
    const lockedUntil = secret.get('lockedUntil');
    if (lockedUntil && lockedUntil.toMillis() > now) {
      return { error: 'locked' };
    }

    const expected = Buffer.from(secret.get('codeHash'), 'hex');
    const given = Buffer.from(hashCode(ref, code), 'hex');
    if (crypto.timingSafeEqual(expected, given)) {
      tx.update(secretRef, { failedLookups: 0, lockedUntil: null });
      return { token: secret.get('token') };
    }

    // Wrong code: count it, and lock the reference after too many.
    const failed = (secret.get('failedLookups') ?? 0) + 1;
    tx.update(secretRef, failed >= MAX_FAILED_LOOKUPS
      ? {
        failedLookups: 0,
        lockedUntil: Timestamp.fromMillis(now + LOCK_MINUTES * 60 * 1000),
      }
      : { failedLookups: failed });
    return { error: 'not-found' };
  });

  if (result.error === 'locked') {
    throw new HttpsError('resource-exhausted',
        `Too many wrong codes. Try again in ${LOCK_MINUTES} minutes.`);
  }
  if (result.error) throw notFound;
  return { token: result.token };
});

// ---------------------------------------------------------------------------
// createDriver, updateDriver, deleteDriver
// ---------------------------------------------------------------------------

// Checks the driver form. Returns the profile fields (without active /
// createdAt) and the password, which may be null when it is optional.
function driverFields(data, { passwordRequired }) {
  const email = text(data.email, 'email', 200);
  let password = null;
  if (passwordRequired || data.password) {
    password = text(data.password, 'password', 200);
    if (password.length < 8) {
      throw new HttpsError('invalid-argument',
          'Password must be at least 8 characters.');
    }
  }
  return {
    profile: {
      name: text(data.name, 'name', 200),
      phone: text(data.phone, 'phone', 50),
      vehicle: text(data.vehicle ?? '', 'vehicle', 50, { required: false }),
      email,
    },
    password,
  };
}

// Turns Authentication errors about the email into clear messages.
function authError(e) {
  if (e.code === 'auth/email-already-exists') {
    return new HttpsError('already-exists', 'This email is already used.');
  }
  if (e.code === 'auth/invalid-email') {
    return new HttpsError('invalid-argument', 'Invalid email.');
  }
  return e;
}

// Returns the drivers/{uid} document of an existing driver.
async function driverDoc(data) {
  const ref = db.doc(`drivers/${text(data.uid, 'uid', 128)}`);
  if (!(await ref.get()).exists) {
    throw new HttpsError('not-found', 'No such driver.');
  }
  return ref;
}

exports.createDriver = onCall(async (request) => {
  await requireStaff(request.auth);
  const { profile, password } =
    driverFields(request.data ?? {}, { passwordRequired: true });

  let user;
  try {
    user = await getAuth().createUser({
      email: profile.email, password, displayName: profile.name,
    });
  } catch (e) {
    throw authError(e);
  }
  await db.doc(`drivers/${user.uid}`).set({
    ...profile, active: true, createdAt: FieldValue.serverTimestamp(),
  });
  return { uid: user.uid };
});

// The password is only changed when a new one is given.
exports.updateDriver = onCall(async (request) => {
  await requireStaff(request.auth);
  const data = request.data ?? {};
  const ref = await driverDoc(data);
  const { profile, password } = driverFields(data, { passwordRequired: false });

  try {
    await getAuth().updateUser(ref.id, {
      email: profile.email,
      displayName: profile.name,
      ...(password && { password }),
    });
  } catch (e) {
    throw authError(e);
  }
  await ref.update(profile);
  return { uid: ref.id };
});

// Bookings the driver had keep their name for the record, but the deleted
// account can no longer sign in or read them.
exports.deleteDriver = onCall(async (request) => {
  await requireStaff(request.auth);
  const ref = await driverDoc(request.data ?? {});
  await getAuth().deleteUser(ref.id).catch((e) => {
    if (e.code !== 'auth/user-not-found') throw e;
  });
  await ref.delete();
  return { uid: ref.id };
});

// ---------------------------------------------------------------------------
// syncTracking
// ---------------------------------------------------------------------------

// The parts of a booking the patient's tracking page may show. No name,
// phone, address or notes: only someone with the tracking link sees this,
// but it is kept to the minimum anyway (KVKK).
function trackingFields(b) {
  return {
    ref: b.ref,
    type: b.type,
    branch: b.branch,
    date: b.date,
    time: b.time,
    stage: b.stage,
    trip: b.trip ?? null,
    // First name only.
    driver: b.driver ? String(b.driver).split(' ')[0] : null,
    vehicle: b.vehicle ?? null,
    // Only shown while the driver is on the way or driving the patient.
    driverLocation: ['enRoute', 'onBoard'].includes(b.trip)
      ? b.driverLocation ?? null
      : null,
    updatedAt: FieldValue.serverTimestamp(),
  };
}

exports.syncTracking = onDocumentWritten('bookings/{ref}', async (event) => {
  const secret = await db.doc(`bookingSecrets/${event.params.ref}`).get();
  // Bookings made before tracking existed have no secret: nothing to do.
  if (!secret.exists) return;
  const trackingRef = db.doc(`tracking/${secret.get('token')}`);

  const after = event.data.after;
  if (!after.exists) {
    await Promise.all([trackingRef.delete(), secret.ref.delete()]);
    return;
  }
  await trackingRef.set(trackingFields(after.data()));
});
