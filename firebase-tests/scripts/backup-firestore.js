// Saves a full copy of the REAL Firestore database to a file on this
// computer: every collection, every document, sub-collections included.
// Only reads; it never changes anything.
//
//   node scripts/backup-firestore.js
//
// Needs your Google sign-in, once per computer:
//   brew install --cask google-cloud-sdk
//   gcloud auth application-default login   (use the Firebase project's owner)
// The file holds patient names and phone numbers: keep it private. The
// backups/ folder is ignored by git.

const fs = require('node:fs');
const path = require('node:path');
const { initializeApp, getApps } = require('firebase-admin/app');
const {
  getFirestore,
  Timestamp,
  GeoPoint,
  DocumentReference,
} = require('firebase-admin/firestore');

const PROJECT = 'project-transportation-5b6d8';

// Firestore values that JSON cannot hold are saved with a "$type" marker,
// so a restore can turn them back into the same kind of value.
function encode(value) {
  if (value instanceof Timestamp) {
    return { $type: 'timestamp', seconds: value.seconds, nanos: value.nanoseconds };
  }
  if (value instanceof GeoPoint) {
    return { $type: 'geopoint', lat: value.latitude, lng: value.longitude };
  }
  if (value instanceof DocumentReference) {
    return { $type: 'reference', path: value.path };
  }
  if (Buffer.isBuffer(value) || value instanceof Uint8Array) {
    return { $type: 'bytes', base64: Buffer.from(value).toString('base64') };
  }
  if (Array.isArray(value)) return value.map(encode);
  if (value !== null && typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value).map(([k, v]) => [k, encode(v)]));
  }
  return value;
}

// { "<collection path>": { "<doc id>": { ...fields } } }
async function dumpCollection(collection, out) {
  const snap = await collection.get();
  const docs = (out[collection.path] = {});
  for (const doc of snap.docs) {
    docs[doc.id] = encode(doc.data());
    for (const sub of await doc.ref.listCollections()) {
      await dumpCollection(sub, out);
    }
  }
}

// Returns the path of the saved file.
async function backup() {
  if (process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error('FIRESTORE_EMULATOR_HOST is set: this would back up the ' +
      'emulator, not the real database. Unset it and run again.');
  }
  if (!getApps().length) initializeApp({ projectId: PROJECT });
  const db = getFirestore();

  const out = {};
  for (const collection of await db.listCollections()) {
    await dumpCollection(collection, out);
  }

  const dir = path.join(__dirname, '..', 'backups');
  fs.mkdirSync(dir, { recursive: true, mode: 0o700 });
  const stamp = new Date().toISOString().replace(/[:.]/g, '-');
  const file = path.join(dir, `firestore-${stamp}.json`);
  fs.writeFileSync(file, JSON.stringify({
    project: PROJECT,
    takenAt: new Date().toISOString(),
    collections: out,
  }, null, 2), { mode: 0o600 });

  // Read it back, so a half-written file is never taken for a good backup.
  const check = JSON.parse(fs.readFileSync(file, 'utf8'));
  for (const [name, docs] of Object.entries(out)) {
    const saved = Object.keys(check.collections[name] ?? {}).length;
    if (saved !== Object.keys(docs).length) {
      throw new Error(`Backup check failed for ${name}.`);
    }
    console.log(`  ${name}: ${saved} documents`);
  }
  console.log(`Backup saved: ${file}`);
  return file;
}

module.exports = { backup };

if (require.main === module) {
  backup().catch((e) => {
    console.error(e.message ?? e);
    process.exit(1);
  });
}
