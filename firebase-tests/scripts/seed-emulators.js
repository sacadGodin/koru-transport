// Creates test accounts in the LOCAL emulators, for trying the site on
// this computer:
//   coordinators: coordinator@koru.test / staff-pass-123
//                 deniz123@koruhatane.com / koru2026
//   drivers:      emre123@koruhastane.com / koru2026
//                 mustafa123@koruhastane.com / koru2026
// Refuses to run against the real project.

const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  console.error('Emulators not running: refusing to touch the real project.');
  process.exit(1);
}

// Returns the account with this email, creating it if needed.
async function account(email, password, displayName) {
  const user = await getAuth().getUserByEmail(email).catch(() =>
    getAuth().createUser({ email, password, displayName }));
  console.log(`Account ready: ${email} / ${password}`);
  return user;
}

async function main() {
  initializeApp({ projectId: process.env.GCLOUD_PROJECT });
  const db = getFirestore();

  for (const [email, password, name] of [
    ['coordinator@koru.test', 'staff-pass-123', 'Coordinator'],
    ['deniz123@koruhatane.com', 'koru2026', 'Deniz'],
  ]) {
    const user = await account(email, password, name);
    await db.doc(`staff/${user.uid}`).set({ name });
  }

  for (const [email, password, name] of [
    ['emre123@koruhastane.com', 'koru2026', 'Emre'],
    ['mustafa123@koruhastane.com', 'koru2026', 'Mustafa'],
  ]) {
    const user = await account(email, password, name);
    // Only when missing, so details edited in the dashboard are kept.
    const profile = db.doc(`drivers/${user.uid}`);
    if (!(await profile.get()).exists) {
      await profile.set({
        name, phone: '', vehicle: '', email: user.email, active: true,
      });
    }
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
