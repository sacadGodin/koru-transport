// Creates a coordinator account in the LOCAL emulators, for trying the
// site on this computer:  coordinator@koru.test / staff-pass-123
// Refuses to run against the real project.

const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  console.error('Emulators not running: refusing to touch the real project.');
  process.exit(1);
}

async function main() {
  initializeApp({ projectId: process.env.GCLOUD_PROJECT });
  const email = 'coordinator@koru.test';
  const user = await getAuth().getUserByEmail(email).catch(() =>
    getAuth().createUser({ email, password: 'staff-pass-123' }));
  await getFirestore().doc(`staff/${user.uid}`).set({ name: 'Coordinator' });
  console.log(`Staff account ready: ${email} / staff-pass-123`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
