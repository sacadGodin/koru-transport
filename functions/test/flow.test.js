// Full booking flow against the Firebase emulators:
//   patient books -> looks up with ref + code -> watches live tracking
//   staff confirm, reserve, assign a driver
//   driver sees only their trips and moves the trip forward
// plus the things that must NOT work (reading other people's data,
// skipping steps, guessing codes).
//
// Run with:  npm run test:emulators   (from the functions folder)

const test = require('node:test');
const assert = require('node:assert/strict');
const adminApp = require('firebase-admin/app');
const { getAuth: getAdminAuth } = require('firebase-admin/auth');
const { getFirestore: getAdminDb } = require('firebase-admin/firestore');
const { initializeApp, deleteApp } = require('firebase/app');
const {
  getAuth, connectAuthEmulator, signInWithEmailAndPassword,
} = require('firebase/auth');
const {
  getFirestore, connectFirestoreEmulator, doc, getDoc, setDoc, updateDoc,
  collection, query, where, getDocs, onSnapshot, serverTimestamp, GeoPoint,
} = require('firebase/firestore');
const {
  getFunctions, connectFunctionsEmulator, httpsCallable,
} = require('firebase/functions');

const projectId = process.env.GCLOUD_PROJECT || 'demo-koru';
const adminSdk = adminApp.initializeApp({ projectId }, 'admin');

// One browser = one Firebase app with its own sign-in.
const apps = [];
function browser(name) {
  const app = initializeApp({ projectId, apiKey: 'fake-key' }, name);
  apps.push(app);
  const auth = getAuth(app);
  connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
  const db = getFirestore(app);
  connectFirestoreEmulator(db, '127.0.0.1', 8080);
  const fns = getFunctions(app, 'asia-northeast1');
  connectFunctionsEmulator(fns, '127.0.0.1', 5001);
  return {
    auth, db,
    call: (fn, data) => httpsCallable(fns, fn)(data).then((r) => r.data),
    signIn: (email, pw) => signInWithEmailAndPassword(auth, email, pw),
  };
}

async function denied(promise) {
  await assert.rejects(promise, (e) => {
    assert.match(String(e.code), /permission-denied/);
    return true;
  });
}

async function callFails(promise, code) {
  await assert.rejects(promise, (e) => {
    assert.equal(e.code, `functions/${code}`);
    return true;
  });
}

// Waits until the live tracking document matches [check] (the
// syncTracking function runs a moment after each booking change).
function waitForTracking(db, token, check, ms = 15000) {
  return new Promise((resolve, reject) => {
    let last;
    const timer = setTimeout(() => {
      unsub();
      reject(new Error(`Tracking never matched. Last: ${JSON.stringify(last)}`));
    }, ms);
    const unsub = onSnapshot(doc(db, 'tracking', token), (snap) => {
      last = snap.data();
      if (last && check(last)) {
        clearTimeout(timer);
        unsub();
        resolve(last);
      }
    }, reject);
  });
}

const form = {
  patient: 'Ayşe Yılmaz',
  phone: '0555 111 22 33',
  type: 'wheelchair',
  from: 'Atatürk Blv. 1, Ankara',
  branch: '[BRANCH 1]',
  date: Date.UTC(2026, 10, 3),
  time: '09:30',
  needs: ['wheelchair', 'companion'],
  notes: 'Third floor, no lift.',
  pickup: { lat: 39.92, lng: 32.85 },
};

test.after(async () => {
  await Promise.all(apps.map((a) => deleteApp(a)));
  await adminApp.deleteApp(adminSdk);
});

test('full flow: patient booking to completed trip', async (t) => {
  // Staff account (staff are added by hand in the console in production).
  const staffUser = await getAdminAuth(adminSdk).createUser({
    email: 'coordinator@koru.test', password: 'staff-pass-123',
  });
  await getAdminDb(adminSdk).doc(`staff/${staffUser.uid}`).set({ name: 'Coord' });

  const patient = browser('patient');
  const staff = browser('staff');
  const driverA = browser('driverA');
  const driverB = browser('driverB');

  // 1. Patient books.
  const booked = await patient.call('createBooking', form);
  assert.equal(booked.ref, 'KR-1001');
  assert.match(booked.code, /^[A-HJ-NP-Z2-9]{8}$/);
  assert.ok(booked.token.length >= 32);

  await t.test('bad booking forms are rejected', async () => {
    await callFails(patient.call('createBooking', { ...form, type: 'rocket' }),
        'invalid-argument');
    await callFails(patient.call('createBooking', { ...form, patient: ' ' }),
        'invalid-argument');
    await callFails(patient.call('createBooking', { ...form, time: '25:00' }),
        'invalid-argument');
  });

  await t.test('patient cannot read or write private data', async () => {
    await denied(getDoc(doc(patient.db, 'bookings', booked.ref)));
    await denied(getDoc(doc(patient.db, 'bookingSecrets', booked.ref)));
    await denied(getDoc(doc(patient.db, 'counters', 'bookings')));
    await denied(getDocs(collection(patient.db, 'tracking')));
    await denied(setDoc(doc(patient.db, 'bookings', 'KR-9999'), form));
    await denied(setDoc(doc(patient.db, 'tracking', booked.token), { stage: 'arranged' }));
  });

  // 2. Patient looks the booking up with ref + code (any case, with a dash).
  const typed = `${booked.code.slice(0, 4).toLowerCase()}-${booked.code.slice(4)}`;
  const found = await patient.call('lookupBooking', { ref: 'kr-1001', code: typed });
  assert.equal(found.token, booked.token);

  // 3. Live tracking shows the safe fields only.
  let live = await waitForTracking(patient.db, booked.token,
      (d) => d.stage === 'newRequest');
  assert.equal(live.ref, 'KR-1001');
  assert.equal(live.type, 'wheelchair');
  for (const secret of ['patient', 'phone', 'from', 'notes', 'pickup', 'needs']) {
    assert.equal(secret in live, false, `${secret} must not be in tracking`);
  }

  // 4. Staff add two drivers. Patients cannot.
  await callFails(patient.call('createDriver', {
    email: 'x@koru.test', password: 'password1', name: 'X', phone: '1',
  }), 'unauthenticated');
  await staff.signIn('coordinator@koru.test', 'staff-pass-123');
  const { uid: driverAUid } = await staff.call('createDriver', {
    email: 'mehmet@koru.test', password: 'driver-pass-1',
    name: 'Mehmet Demir', phone: '0555 000 00 01', vehicle: '06 KRU 001',
  });
  const { uid: driverBUid } = await staff.call('createDriver', {
    email: 'ali@koru.test', password: 'driver-pass-2',
    name: 'Ali Kaya', phone: '0555 000 00 02', vehicle: '06 KRU 002',
  });
  await callFails(staff.call('createDriver', {
    email: 'mehmet@koru.test', password: 'driver-pass-1', name: 'M', phone: '1',
  }), 'already-exists');

  // 5. Staff move the booking through the stages.
  const bookingDoc = doc(staff.db, 'bookings', booked.ref);
  await updateDoc(bookingDoc, { stage: 'confirmed' });
  await updateDoc(bookingDoc, { stage: 'reserved', time: '10:00' });
  await t.test('staff cannot change patient details or assign a non-driver',
      async () => {
        await denied(updateDoc(bookingDoc, { patient: 'Someone else' }));
        await denied(updateDoc(bookingDoc, {
          stage: 'arranged', driverUid: staffUser.uid,
          driver: 'Coord', vehicle: '06 X', trip: 'assigned',
        }));
      });
  await updateDoc(bookingDoc, {
    stage: 'arranged', driverUid: driverAUid, driver: 'Mehmet Demir',
    vehicle: '06 KRU 001', trip: 'assigned',
  });

  live = await waitForTracking(patient.db, booked.token,
      (d) => d.stage === 'arranged');
  assert.equal(live.trip, 'assigned');
  assert.equal(live.driver, 'Mehmet');
  assert.equal(live.time, '10:00');
  assert.equal(live.vehicle, '06 KRU 001');

  // 6. Drivers see only their own trips.
  await driverA.signIn('mehmet@koru.test', 'driver-pass-1');
  await driverB.signIn('ali@koru.test', 'driver-pass-2');
  const mine = (db, uid) =>
    getDocs(query(collection(db, 'bookings'), where('driverUid', '==', uid)));
  assert.deepEqual((await mine(driverA.db, driverAUid)).docs.map((d) => d.id),
      ['KR-1001']);
  assert.equal((await mine(driverB.db, driverBUid)).size, 0);
  await denied(getDoc(doc(driverB.db, 'bookings', booked.ref)));
  await denied(getDocs(collection(driverA.db, 'bookings')));
  await denied(mine(driverA.db, driverBUid));

  // 7. Driver moves the trip forward one step at a time.
  const tripDoc = doc(driverA.db, 'bookings', booked.ref);
  const step = (trip) => updateDoc(tripDoc, { trip, tripUpdatedAt: serverTimestamp() });

  await t.test('driver cannot skip steps or edit the booking', async () => {
    await denied(step('arrived'));
    await denied(updateDoc(tripDoc, { stage: 'confirmed' }));
    await denied(updateDoc(tripDoc, { time: '23:00' }));
    await denied(updateDoc(doc(driverB.db, 'bookings', booked.ref),
        { trip: 'enRoute', tripUpdatedAt: serverTimestamp() }));
  });

  await step('enRoute');
  await updateDoc(tripDoc, { driverLocation: new GeoPoint(39.93, 32.86) });
  live = await waitForTracking(patient.db, booked.token,
      (d) => d.trip === 'enRoute' && d.driverLocation != null);
  assert.equal(live.driverLocation.latitude, 39.93);

  await step('arrived');
  live = await waitForTracking(patient.db, booked.token, (d) => d.trip === 'arrived');
  assert.equal(live.driverLocation, null, 'location hidden while waiting');

  await step('onBoard');
  await step('completed');
  await waitForTracking(patient.db, booked.token, (d) => d.trip === 'completed');
  await denied(step('enRoute'));

  // 8. A switched-off driver loses access.
  await updateDoc(doc(staff.db, 'drivers', driverAUid), { active: false });
  await denied(mine(driverA.db, driverAUid));
  await denied(updateDoc(doc(driverB.db, 'drivers', driverBUid), { active: true }));
});

test('wrong codes lock the reference', async () => {
  const patient = browser('guesser');
  const booked = await patient.call('createBooking', { ...form, pickup: null });
  const wrong = booked.code === 'AAAAAAAA' ? 'BBBBBBBB' : 'AAAAAAAA';

  await callFails(patient.call('lookupBooking', { ref: 'KR-424242', code: wrong }),
      'not-found');
  for (let i = 0; i < 5; i++) {
    await callFails(patient.call('lookupBooking', { ref: booked.ref, code: wrong }),
        'not-found');
  }
  // Locked now: even the right code is refused for a while.
  await callFails(patient.call('lookupBooking', { ref: booked.ref, code: booked.code }),
      'resource-exhausted');
});
