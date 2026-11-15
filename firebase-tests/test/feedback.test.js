// Patient feedback rules, against the Firebase emulators: a visitor with no
// account can send feedback, but cannot publish it, read hidden comments,
// add unknown fields or change/delete comments.
//
// Run with:  npm run test:emulators   (from the firebase-tests folder)

const test = require('node:test');
const assert = require('node:assert/strict');
const { initializeApp, deleteApp } = require('firebase/app');
const {
  getFirestore, connectFirestoreEmulator, doc, setDoc, getDoc, updateDoc,
  deleteDoc, Timestamp,
} = require('firebase/firestore');

const projectId = process.env.GCLOUD_PROJECT || 'demo-koru';
const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';

const app = initializeApp({ projectId, apiKey: 'fake-key' }, 'feedback-visitor');
const db = getFirestore(app);
connectFirestoreEmulator(db, ...firestoreHost.split(':').map((v, i) => (i ? Number(v) : v)));

async function denied(promise) {
  await assert.rejects(promise, (e) => {
    assert.match(String(e.code), /permission-denied/);
    return true;
  });
}

const good = () => ({
  rating: 5,
  type: 'standard',
  comment: 'Very kind driver.',
  date: Timestamp.now(),
  name: 'Ayşe',
  ref: 'KR-1001',
  aspects: ['driver', 'punctuality'],
  published: false,
});

test.after(() => deleteApp(app));

test('visitor can send feedback but not publish, read or change it', async () => {
  const id = `fb-${Date.now()}`;
  const ref = doc(db, 'feedback', id);
  await setDoc(ref, good());

  // Only rating is required to be filled in.
  await setDoc(doc(db, 'feedback', `${id}-min`),
    { ...good(), comment: '', name: '', ref: '', aspects: [] });

  await denied(getDoc(ref));
  await denied(updateDoc(ref, { published: true }));
  await denied(deleteDoc(ref));

  const bad = (patch) => setDoc(doc(db, 'feedback', `${id}-${Math.random()}`), { ...good(), ...patch });
  await denied(bad({ published: true }));
  await denied(bad({ rating: 0 }));
  await denied(bad({ rating: 6 }));
  await denied(bad({ aspects: ['hacked'] }));
  await denied(bad({ name: 'x'.repeat(81) }));
  await denied(bad({ ref: 'x'.repeat(21) }));
  await denied(bad({ extra: 'field' }));
  await denied(bad({ date: 'today' }));
});
