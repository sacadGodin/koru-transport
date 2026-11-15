// One-time fix for bookings made while the site still used Cloud Functions.
//
// Those bookings kept their tracking copy at tracking/{random token}, with
// the code's hash in bookingSecrets/{ref}. The website now finds the copy at
// tracking/{sha256("<ref>:<code>")}, which is exactly that saved hash. So
// for each old booking this:
//   - sets bookings/{ref}.trackingId to the hash
//   - creates tracking/{hash} from the booking (same safe fields as before)
// Nothing is deleted or overwritten: bookingSecrets and the old tracking
// documents stay as they are, and a booking that already has a trackingId
// is left alone. Running it twice changes nothing the second time.
//
//   node scripts/migrate-tracking.js           only shows what it would do
//   node scripts/migrate-tracking.js --apply   backs up, then makes the changes

const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { backup } = require('./backup-firestore');

const PROJECT = 'project-transportation-5b6d8';
const apply = process.argv.includes('--apply');

// Same fields the website writes in _trackingDoc (lib/data/bookings.dart)
// and firestore.rules accepts in isTrackingOf.
function trackingFields(b) {
  return {
    ref: b.ref,
    type: b.type,
    branch: b.branch,
    date: b.date,
    time: b.time,
    stage: b.stage,
    trip: b.trip ?? null,
    driver: b.driver ? String(b.driver).split(' ')[0] : null,
    vehicle: b.vehicle ?? null,
    driverLocation: ['enRoute', 'onBoard'].includes(b.trip)
      ? b.driverLocation ?? null
      : null,
    updatedAt: FieldValue.serverTimestamp(),
  };
}

async function main() {
  if (process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error('FIRESTORE_EMULATOR_HOST is set: unset it to work on ' +
      'the real database.');
  }
  initializeApp({ projectId: PROJECT });
  const db = getFirestore();

  if (apply) {
    console.log('Backing up first...');
    await backup();
  }

  const secrets = await db.collection('bookingSecrets').get();
  const bookings = await db.collection('bookings').get();
  console.log(`\n${bookings.size} bookings, ${secrets.size} with an old tracking code.\n`);

  const counts = { fixed: 0, alreadyOk: 0, skipped: 0 };
  for (const secret of secrets.docs) {
    const ref = secret.id;
    const hash = secret.get('codeHash');
    if (typeof hash !== 'string' || !/^[0-9a-f]{64}$/.test(hash)) {
      console.log(`  ${ref}: SKIPPED, saved code hash looks wrong`);
      counts.skipped++;
      continue;
    }

    // Checked again inside a transaction, so nothing changes if the booking
    // was edited meanwhile, and an existing document is never overwritten.
    const result = await db.runTransaction(async (tx) => {
      const bookingRef = db.doc(`bookings/${ref}`);
      const trackingRef = db.doc(`tracking/${hash}`);
      const [booking, tracking] = await Promise.all([
        tx.get(bookingRef), tx.get(trackingRef)]);
      if (!booking.exists) return 'SKIPPED, booking not found';
      if (booking.get('trackingId') != null) return 'ok';
      if (tracking.exists) return 'SKIPPED, tracking/' + hash + ' already exists';
      if (apply) {
        tx.update(bookingRef, { trackingId: hash });
        tx.create(trackingRef, trackingFields(booking.data()));
      }
      return 'fix';
    });

    if (result === 'ok') {
      counts.alreadyOk++;
    } else if (result === 'fix') {
      counts.fixed++;
      console.log(`  ${ref}: ${apply ? 'fixed' : 'would fix'}`);
    } else {
      counts.skipped++;
      console.log(`  ${ref}: ${result}`);
    }
  }

  const noCode = bookings.docs.filter((b) =>
    b.get('trackingId') == null && !secrets.docs.some((s) => s.id === b.id));
  for (const b of noCode) {
    console.log(`  ${b.id}: no tracking code was ever made, nothing to do ` +
      '(staff still see it in the dashboard)');
  }

  console.log(`\n${apply ? 'Fixed' : 'Would fix'}: ${counts.fixed}, ` +
    `already fine: ${counts.alreadyOk}, skipped: ${counts.skipped}, ` +
    `without a code: ${noCode.length}`);
  if (!apply && counts.fixed > 0) {
    console.log('Nothing was changed. Run again with --apply to make these changes.');
  }
}

main().catch((e) => {
  console.error(e.message ?? e);
  process.exit(1);
});
