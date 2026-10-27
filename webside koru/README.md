# Koru Hospital Transport website

Flutter Web site with a Firebase backend (Auth, Firestore, Cloud Functions).

## Who uses what

| Page | Who | What |
|---|---|---|
| `/booking` | Patients | Book a ride. Afterwards they see a reference (`KR-1001`) and a secret 8-letter **tracking code**. |
| `/track` | Patients | Type reference + code to follow the booking live (steps, driver, car on the map). |
| `/admin` | Coordinators (`staff/{uid}`) | Confirm → reserve → assign a driver. Add, edit, delete and switch off drivers. |
| `/driver` | Drivers (`drivers/{uid}`, active) | See only their own trips. Start trip → arrived → patient on board → complete. Location is shared while driving. |

## How it is kept safe

- Bookings are created only by the `createBooking` Cloud Function (it hands out the number and the tracking code). Browsers cannot write bookings directly.
- Booking references are sequential, so a reference alone opens nothing. `lookupBooking` checks reference + code and locks the reference for 15 minutes after 5 wrong codes.
- The tracking code is stored only as a hash in `bookingSecrets/`, which no browser can read.
- The patient's live page reads `tracking/{token}`, which holds a copy without personal details (no name, phone or address), kept up to date by the `syncTracking` function. The token is long and random, and the collection cannot be listed.
- Drivers can read only the bookings assigned to them, and can change only the trip step (one step forward) and their location.

Rules: `../firestore.rules`. Functions: `../functions/index.js`.

## Try it on this computer (emulators, not the real database)

Needs Java (`brew install openjdk@21`, then put `/opt/homebrew/opt/openjdk@21/bin` on your PATH).

```sh
cd functions
npm install
npm run emulators            # starts Auth/Firestore/Functions + adds coordinator@koru.test / staff-pass-123
# in another terminal:
cd "webside koru"
flutter run -d chrome --dart-define=USE_EMULATORS=true
```

Emulator UI: http://localhost:4000

## Tests

```sh
cd functions
npm run test:emulators   # backend + security rules: whole flow and what must be refused
npm run test:app         # the app's own code in Chrome: booking → tracking → admin → driver → completed
cd "../webside koru" && flutter test
```

## Going live (first time)

1. Cloud Functions need the **Blaze** (pay-as-you-go) plan on the Firebase project.
2. Deploy the backend and the new site **together**. The new rules stop the old site from saving bookings, so the old site must not stay online after the rules change:
   ```sh
   firebase deploy --only functions,firestore:rules
   ```
   then publish the new web build (`flutter build web`).
3. In the admin dashboard, open **Drivers** and add each driver (email + first password).
4. Open **Free buses** and set each route's destination, departure times and frequency. Until a route has a destination and at least one time, the homepage shows "Schedule to be announced".

Bookings made before this change have no tracking code, so patients cannot track them. They still work in the admin dashboard.
