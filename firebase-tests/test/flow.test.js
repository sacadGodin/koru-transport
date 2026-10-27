// Full booking flow against the Firebase emulators, written the same way
// the website does it (there is no server code: the rules guard everything):
//   patient books -> looks up with ref + code -> watches live tracking
//   staff add drivers, confirm, reserve, assign a driver
//   driver sees only their trips and moves the trip forward
// plus the things that must NOT work (reading other people's data, faking
// booking numbers or tracking copies, skipping steps, making yourself a
// driver).
//
// Run with:  npm run test:emulators   (from the firebase-tests folder)

const crypto = require('node:crypto');
const test = require('node:test');
const assert = require('node:assert/strict');
const adminApp = require('firebase-admin/app');
const { getAuth: getAdminAuth } = require('firebase-admin/auth');
const { getFirestore: getAdminDb } = require('firebase-admin/firestore');
const { initializeApp, deleteApp } = require('firebase/app');
const {
  getAuth, connectAuthEmulator, signInWithEmailAndPassword,
  createUserWithEmailAndPassword, signOut,
} = require('firebase/auth');
const {
  getFirestore, connectFirestoreEmulator, doc, getDoc, setDoc, updateDoc,
  deleteDoc, collection, query, where, orderBy, getDocs, addDoc,
  serverTimestamp, GeoPoint, Timestamp, runTransaction, writeBatch,
} = require('firebase/firestore');

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
  return {
    auth, db,
    signIn: (email, pw) => signInWithEmailAndPassword(auth, email, pw),
  };
}

async function denied(promise) {
  await assert.rejects(promise, (e) => {
    assert.match(String(e.code), /permission-denied/);
    return true;
  });
}

async function addStaff(email, password) {
  const user = await getAdminAuth(adminSdk).createUser({ email, password });
  await getAdminDb(adminSdk).doc(`staff/${user.uid}`).set({ name: email });
  return user;
}

// --- The same steps as webside koru/lib/data/bookings.dart -----------------

const trackingIdFor = (ref, code) =>
  crypto.createHash('sha256').update(`${ref}:${code}`).digest('hex');

function trackingDoc(b, driverLocation = null) {
  return {
    ref: b.ref, type: b.type, branch: b.branch, date: b.date, time: b.time,
    stage: b.stage, trip: b.trip ?? null,
    driver: b.driver ? b.driver.split(' ')[0] : null,
    vehicle: b.vehicle ?? null, driverLocation, updatedAt: serverTimestamp(),
  };
}

const form = {
  patient: 'Ayşe Yılmaz',
  phone: '0555 111 22 33',
  type: 'wheelchair',
  from: 'Atatürk Blv. 1, Ankara',
  branch: 'Koru Hospital Çukurambar',
  date: Timestamp.fromMillis(Date.UTC(2026, 10, 3)),
  time: '09:30',
  needs: ['wheelchair', 'companion'],
  notes: 'Third floor, no lift.',
  pickup: new GeoPoint(39.92, 32.85),
};

// Books like the website: next number, booking and tracking copy in one
// transaction. [change] lets a test tamper with what is written.
async function book(db, { code = 'ABCD2345', change = (w) => w } = {}) {
  return runTransaction(db, async (tx) => {
    const counterRef = doc(db, 'counters', 'bookings');
    const counter = await tx.get(counterRef);
    const n = counter.exists() ? counter.get('next') : 1001;
    const ref = `KR-${n}`;
    const trackingId = trackingIdFor(ref, code);
    const booking = {
      ...form, ref, stage: 'newRequest', vehicle: null, driver: null,
      driverUid: null, trip: null, driverLocation: null, trackingId,
      createdAt: serverTimestamp(),
    };
    const w = change({
      counter: { next: n + 1 }, ref, booking,
      tracking: trackingDoc(booking), trackingId,
    });
    tx.set(counterRef, w.counter);
    tx.set(doc(db, 'bookings', w.ref), w.booking);
    if (w.tracking) tx.set(doc(db, 'tracking', w.trackingId), w.tracking);
    return { ref, code, trackingId };
  });
}

// Saves a booking change together with its tracking copy, like the
// dashboards do. [location] is the driver's position for the patient.
async function save(db, ref, changes, { location = null, tracking = true } = {}) {
  const snap = await getDoc(doc(db, 'bookings', ref));
  const after = { ...snap.data(), ...changes };
  const batch = writeBatch(db);
  batch.update(doc(db, 'bookings', ref), changes);
  if (tracking) {
    batch.set(doc(db, 'tracking', after.trackingId), trackingDoc(after, location));
  }
  return batch.commit();
}

// Adds a driver like the dashboard: the sign-in account through a second
// app, then the profile as the signed-in coordinator.
async function addDriver(staff, name, email, password) {
  const signUp = browser(`signup-${email}`);
  const { user } = await createUserWithEmailAndPassword(signUp.auth, email, password);
  await signOut(signUp.auth);
  await setDoc(doc(staff.db, 'drivers', user.uid), {
    name, phone: '0555 000 00 00', vehicle: '06 KRU 001', email,
    active: true, createdAt: serverTimestamp(),
  });
  return user.uid;
}

test.after(async () => {
  await Promise.all(apps.map((a) => deleteApp(a)));
  await adminApp.deleteApp(adminSdk);
});

test('full flow: patient booking to completed trip', async (t) => {
  const staffUser = await addStaff('coordinator@koru.test', 'staff-pass-123');
  const patient = browser('patient');
  const staff = browser('staff');
  const driverA = browser('driverA');
  const driverB = browser('driverB');

  // 1. Patient books; the next one gets the next number.
  const booked = await book(patient.db);
  assert.equal(booked.ref, 'KR-1001');
  const second = await book(browser('patient2').db, { code: 'ZZZZ9999' });
  assert.equal(second.ref, 'KR-1002');

  await t.test('bad or faked bookings are refused', async () => {
    const fake = (change) => denied(book(patient.db, { change }));
    // Bad form values.
    await fake((w) => ({ ...w, booking: { ...w.booking, type: 'rocket' } }));
    await fake((w) => ({ ...w, booking: { ...w.booking, patient: ' ' } }));
    await fake((w) => ({ ...w, booking: { ...w.booking, time: '25:00' } }));
    await fake((w) => ({ ...w, booking: { ...w.booking, needs: ['jetpack'] } }));
    await fake((w) => ({ ...w, booking: { ...w.booking, extra: 1 } }));
    // Starting further along, or with a driver already set.
    await fake((w) => ({ ...w, booking: { ...w.booking, stage: 'arranged' } }));
    await fake((w) => ({ ...w, booking: { ...w.booking, driverUid: 'x' } }));
    // Picking your own number, or not moving the counter on.
    await fake((w) => ({ ...w, ref: 'KR-9999', booking: { ...w.booking, ref: 'KR-9999' } }));
    await fake((w) => ({ ...w, counter: { next: w.counter.next + 5 } }));
    // No tracking copy, or one that does not match the booking.
    await fake((w) => ({ ...w, tracking: null }));
    await fake((w) => ({ ...w, tracking: { ...w.tracking, stage: 'arranged' } }));
    await fake((w) => ({ ...w, tracking: { ...w.tracking, patient: 'Ayşe' } }));
    // Writing over someone else's tracking copy.
    await fake((w) => ({
      ...w, trackingId: booked.trackingId,
      booking: { ...w.booking, trackingId: booked.trackingId },
    }));
    // Counter moved on without a booking.
    const counter = await getDoc(doc(patient.db, 'counters', 'bookings'));
    await denied(setDoc(doc(patient.db, 'counters', 'bookings'),
        { next: counter.get('next') + 1 }));
  });

  await t.test('patient cannot read or write private data', async () => {
    await denied(getDoc(doc(patient.db, 'bookings', booked.ref)));
    await denied(getDocs(collection(patient.db, 'tracking')));
    await denied(getDocs(collection(patient.db, 'bookings')));
    await denied(updateDoc(doc(patient.db, 'bookings', booked.ref), { stage: 'arranged' }));
    await denied(setDoc(doc(patient.db, 'tracking', booked.trackingId),
        { stage: 'arranged' }));
  });

  // 2. Patient looks the booking up: the tracking id comes from ref + code.
  let live = (await getDoc(doc(patient.db, 'tracking', booked.trackingId))).data();
  assert.equal(live.ref, 'KR-1001');
  assert.equal(live.stage, 'newRequest');
  assert.equal(live.type, 'wheelchair');
  for (const secret of ['patient', 'phone', 'from', 'notes', 'pickup', 'needs']) {
    assert.equal(secret in live, false, `${secret} must not be in tracking`);
  }
  const wrong = await getDoc(doc(patient.db, 'tracking', trackingIdFor('KR-1001', 'AAAA2222')));
  assert.equal(wrong.exists(), false);

  await t.test('only staff can make someone a driver', async () => {
    // Anyone can sign up an account, but that alone gives no access.
    const intruder = browser('intruder');
    const { user } = await createUserWithEmailAndPassword(
        intruder.auth, 'intruder@koru.test', 'intruder-pass');
    await denied(setDoc(doc(intruder.db, 'drivers', user.uid), {
      name: 'I', phone: '1', vehicle: '', email: 'intruder@koru.test',
      active: true, createdAt: serverTimestamp(),
    }));
    await denied(setDoc(doc(intruder.db, 'staff', user.uid), { name: 'I' }));
    await denied(getDocs(collection(intruder.db, 'bookings')));
  });

  // 3. Staff add two drivers.
  await staff.signIn('coordinator@koru.test', 'staff-pass-123');
  const driverAUid = await addDriver(staff, 'Mehmet Demir', 'mehmet@koru.test', 'driver-pass-1');
  const driverBUid = await addDriver(staff, 'Ali Kaya', 'ali@koru.test', 'driver-pass-2');
  assert.equal(staff.auth.currentUser.uid, staffUser.uid, 'staff stay signed in');

  // 4. Staff move the booking through the stages.
  await save(staff.db, booked.ref, { stage: 'confirmed' });
  await save(staff.db, booked.ref, { stage: 'reserved', time: '10:00' });
  await t.test('staff cannot change patient details, skip the tracking copy or assign a non-driver',
      async () => {
        await denied(save(staff.db, booked.ref, { patient: 'Someone else' }));
        await denied(save(staff.db, booked.ref, { trackingId: 'x'.repeat(64) }));
        await denied(save(staff.db, booked.ref, { time: '11:00' }, { tracking: false }));
        await denied(save(staff.db, booked.ref, {
          stage: 'arranged', driverUid: staffUser.uid,
          driver: 'Coord', vehicle: '06 X', trip: 'assigned',
        }));
      });
  await save(staff.db, booked.ref, {
    stage: 'arranged', driverUid: driverAUid, driver: 'Mehmet Demir',
    vehicle: '06 KRU 001', trip: 'assigned',
  });

  live = (await getDoc(doc(patient.db, 'tracking', booked.trackingId))).data();
  assert.equal(live.stage, 'arranged');
  assert.equal(live.trip, 'assigned');
  assert.equal(live.driver, 'Mehmet');
  assert.equal(live.time, '10:00');
  assert.equal(live.vehicle, '06 KRU 001');

  // 5. Drivers see only their own trips.
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

  // 6. Driver moves the trip forward one step at a time.
  const step = (db, trip, opts) =>
    save(db, booked.ref, { trip, tripUpdatedAt: serverTimestamp() }, opts);

  await t.test('driver cannot skip steps, edit the booking or fake the tracking copy',
      async () => {
        await denied(step(driverA.db, 'arrived'));
        await denied(save(driverA.db, booked.ref, { stage: 'confirmed' }));
        await denied(save(driverA.db, booked.ref, { time: '23:00' }));
        await denied(step(driverB.db, 'enRoute'));
        await denied(step(driverA.db, 'enRoute', { tracking: false }));
        // Location shown to the patient must be the real one, and only while driving.
        await denied(save(driverA.db, booked.ref,
            { driverLocation: new GeoPoint(39.93, 32.86) },
            { location: new GeoPoint(1, 1) }));
        await denied(save(driverA.db, booked.ref,
            { driverLocation: new GeoPoint(39.93, 32.86) },
            { location: new GeoPoint(39.93, 32.86) }));
      });

  await step(driverA.db, 'enRoute');
  const here = new GeoPoint(39.93, 32.86);
  await save(driverA.db, booked.ref, { driverLocation: here }, { location: here });
  live = (await getDoc(doc(patient.db, 'tracking', booked.trackingId))).data();
  assert.equal(live.trip, 'enRoute');
  assert.equal(live.driverLocation.latitude, 39.93);

  await step(driverA.db, 'arrived');
  live = (await getDoc(doc(patient.db, 'tracking', booked.trackingId))).data();
  assert.equal(live.trip, 'arrived');
  assert.equal(live.driverLocation, null, 'location hidden while waiting');

  await step(driverA.db, 'onBoard');
  await step(driverA.db, 'completed');
  live = (await getDoc(doc(patient.db, 'tracking', booked.trackingId))).data();
  assert.equal(live.trip, 'completed');
  await denied(step(driverA.db, 'enRoute'));

  // 7. A switched-off driver loses access.
  await updateDoc(doc(staff.db, 'drivers', driverAUid), { active: false });
  await denied(mine(driverA.db, driverAUid));
  await denied(updateDoc(doc(driverB.db, 'drivers', driverBUid), { active: true }));
});

test('contact messages: visitors send, only staff read', async () => {
  await addStaff('desk@koru.test', 'staff-pass-456');
  const visitor = browser('visitor');
  const staff = browser('desk');
  const message = {
    name: 'Ali', reply: '0555 123 45 67', topic: 'booking', reference: 'KR-1001',
    message: 'Can I change the time?', date: serverTimestamp(), handled: false,
  };

  const sent = await addDoc(collection(visitor.db, 'messages'), message);
  await denied(getDoc(sent));
  await denied(getDocs(collection(visitor.db, 'messages')));
  await denied(addDoc(collection(visitor.db, 'messages'), { ...message, handled: true }));
  await denied(addDoc(collection(visitor.db, 'messages'), { ...message, topic: 'spam' }));
  await denied(addDoc(collection(visitor.db, 'messages'), { ...message, message: '' }));
  await denied(addDoc(collection(visitor.db, 'messages'), { ...message, extra: 1 }));

  await staff.signIn('desk@koru.test', 'staff-pass-456');
  const list = await getDocs(query(collection(staff.db, 'messages'), orderBy('date', 'desc')));
  assert.equal(list.size, 1);
  assert.equal(list.docs[0].get('message'), 'Can I change the time?');
  await updateDoc(doc(staff.db, 'messages', sent.id), { handled: true });
  await denied(updateDoc(doc(staff.db, 'messages', sent.id), { message: 'edited' }));
});

test('free bus routes: everyone reads, only staff set them', async () => {
  await addStaff('buses@koru.test', 'staff-pass-789');
  const visitor = browser('busVisitor');
  const staff = browser('busStaff');
  const route = {
    destination: 'Test stop', times: ['08:00', '08:30'], frequency: 30,
    updatedAt: serverTimestamp(),
  };

  // Nothing set yet: the homepage shows "Schedule to be announced".
  assert.equal((await getDocs(collection(visitor.db, 'shuttleRoutes'))).size, 0);
  await denied(setDoc(doc(visitor.db, 'shuttleRoutes', 'A'), route));

  await staff.signIn('buses@koru.test', 'staff-pass-789');
  await setDoc(doc(staff.db, 'shuttleRoutes', 'A'), route);
  await setDoc(doc(staff.db, 'shuttleRoutes', 'B'), { ...route, frequency: null });
  await denied(setDoc(doc(staff.db, 'shuttleRoutes', 'D'), route));
  await denied(setDoc(doc(staff.db, 'shuttleRoutes', 'A'), { ...route, frequency: 0 }));
  await denied(setDoc(doc(staff.db, 'shuttleRoutes', 'A'), { ...route, frequency: '30' }));
  await denied(setDoc(doc(staff.db, 'shuttleRoutes', 'A'), { ...route, times: '08:00' }));
  await denied(setDoc(doc(staff.db, 'shuttleRoutes', 'A'), { ...route, extra: 1 }));
  await denied(setDoc(doc(staff.db, 'shuttleRoutes', 'A'),
      { ...route, destination: 'x'.repeat(201) }));

  const seen = await getDoc(doc(visitor.db, 'shuttleRoutes', 'A'));
  assert.equal(seen.get('destination'), 'Test stop');
  assert.deepEqual(seen.get('times'), ['08:00', '08:30']);
  await denied(updateDoc(doc(visitor.db, 'shuttleRoutes', 'A'), { destination: 'Hacked' }));
});

test('staff edit and delete drivers', async () => {
  await addStaff('fleet@koru.test', 'staff-pass-321');
  const staff = browser('fleetStaff');
  const driver = browser('fleetDriver');
  await staff.signIn('fleet@koru.test', 'staff-pass-321');
  const uid = await addDriver(staff, 'Mustafa', 'mustafa@koru.test', 'driver-pass-3');
  await driver.signIn('mustafa@koru.test', 'driver-pass-3');
  const profile = doc(staff.db, 'drivers', uid);

  // Staff edit the details; not the email, and nobody else may edit.
  await updateDoc(profile, {
    name: 'Mustafa Yılmaz', phone: '0555 000 00 04', vehicle: '06 KRU 004',
  });
  await denied(updateDoc(profile, { email: 'other@koru.test' }));
  await denied(updateDoc(profile, { name: '' }));
  await denied(updateDoc(doc(driver.db, 'drivers', uid), { name: 'Me' }));
  const saved = await getDoc(profile);
  assert.equal(saved.get('name'), 'Mustafa Yılmaz');
  assert.equal(saved.get('vehicle'), '06 KRU 004');
  assert.equal(saved.get('active'), true);

  // Delete removes the profile: the driver can no longer read it.
  await denied(deleteDoc(doc(driver.db, 'drivers', uid)));
  await deleteDoc(profile);
  assert.equal((await getDoc(profile)).exists(), false);
  await denied(getDocs(query(collection(driver.db, 'bookings'),
      where('driverUid', '==', uid))));
});
