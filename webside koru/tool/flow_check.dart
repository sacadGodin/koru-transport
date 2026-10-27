// Full flow through the app's own code, against the local Firebase
// emulators (never the real database):
//   patient books -> looks up with ref + code -> watches live tracking
//   coordinator adds a driver, confirms, reserves, assigns the driver
//   driver signs in, sees the trip and drives it to "completed"
//   coordinator sets a free bus route; visitors see it but cannot change it
//
// It is built as a small web app (the Firebase web SDK only loads in a
// real page, not inside "flutter test"). Run from the functions folder:
//   npm run test:app
// which starts the emulators, adds a coordinator account, builds this file,
// opens it in headless Chrome and prints "FLOW OK" or "FLOW FAILED".

// Prints the result to the browser console, which the runner reads.
// ignore_for_file: avoid_print

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:koru_website/data/bookings.dart';
import 'package:koru_website/data/drivers.dart';
import 'package:koru_website/data/shuttles.dart';
import 'package:koru_website/data/staff_auth.dart';
import 'package:koru_website/data/tracking.dart';
import 'package:koru_website/firebase_options.dart';
import 'package:latlong2/latlong.dart';

// Stops the check with a message when something is not as expected.
void expect(Object? actual, Object? expected, {String? reason}) {
  if (actual != expected) {
    throw StateError('Expected $expected but got $actual'
        '${reason == null ? '' : ' ($reason)'}');
  }
}

void check(bool ok, String what) {
  if (!ok) throw StateError('Check failed: $what');
}

// Waits until [check] is true, re-checking whenever [store] changes.
Future<void> waitFor(Listenable store, bool Function() check) {
  if (check()) return Future.value();
  final done = Completer<void>();
  void listener() {
    if (check() && !done.isCompleted) done.complete();
  }

  store.addListener(listener);
  return done.future
      .timeout(const Duration(seconds: 20))
      .whenComplete(() => store.removeListener(listener));
}

// Waits until the patient's live tracking page would show [check].
Future<TrackingInfo> waitForTracking(
        String token, bool Function(TrackingInfo) check) =>
    tracking
        .watch(token)
        .where((info) => info != null && check(info))
        .cast<TrackingInfo>()
        .first
        .timeout(const Duration(seconds: 20));

Future<void> runFlow() async {
  // 1. Patient sends the booking form.
  final receipt = await bookingStore.add(
    patient: 'Ayşe Yılmaz',
    phone: '0555 111 22 33',
    type: TransportType.wheelchair,
    from: 'Atatürk Blv. 1, Ankara',
    branch: branches.first,
    date: DateTime.now().add(const Duration(days: 2)),
    time: const TimeOfDay(hour: 9, minute: 30),
    needs: {MobilityNeed.wheelchair, MobilityNeed.companion},
    notes: 'Third floor, no lift.',
    pickup: const LatLng(39.92, 32.85),
  );
  final ref = receipt.booking.ref;
  check(ref.startsWith('KR-'), 'reference looks like KR-1001');
  expect(receipt.code.length, 8);

  // 2. Wrong code is refused; right code (typed in lower case) works.
  expect((await tracking.lookup(ref, 'AAAA2222')).$1, LookupResult.notFound);
  final (result, token) =
      await tracking.lookup(ref.toLowerCase(), receipt.code.toLowerCase());
  expect(result, LookupResult.ok);
  expect(token, receipt.token);
  expect(await tracking.saved(), token);

  // 3. The tracking page shows the new request.
  var info = await waitForTracking(token!, (i) => i.stage == Stage.newRequest);
  expect(info.ref, ref);
  expect(info.type, TransportType.wheelchair);
  expect(info.time, const TimeOfDay(hour: 9, minute: 30));

  // 4. Coordinator signs in and adds a driver.
  expect(await staffAuth.signIn('coordinator@koru.test', 'staff-pass-123'),
      SignInResult.ok);
  final email = 'driver${DateTime.now().millisecondsSinceEpoch}@koru.test';
  expect(
      await driverStore.add(
          name: 'Mehmet Demir',
          phone: '0555 000 00 01',
          vehicle: '06 KRU 001',
          email: email,
          password: 'driver-pass-1'),
      null);
  await waitFor(
      driverStore, () => driverStore.active.any((d) => d.email == email));
  final driver = driverStore.active.firstWhere((d) => d.email == email);

  // 5. Coordinator confirms, reserves (changing the time) and assigns the
  //    driver, the same way the dashboard buttons and dialogs do.
  Booking booking() => bookingStore.bookings.firstWhere((b) => b.ref == ref);
  await waitFor(
      bookingStore, () => bookingStore.bookings.any((b) => b.ref == ref));
  expect(booking().patient, 'Ayşe Yılmaz');

  check(await bookingStore.advance(booking()), 'booking saved');
  await waitForTracking(token, (i) => i.stage == Stage.confirmed);

  booking().time = const TimeOfDay(hour: 10, minute: 0);
  check(await bookingStore.advance(booking()), 'booking saved');
  await waitForTracking(token, (i) => i.stage == Stage.reserved);

  booking()
    ..vehicle = driver.vehicle
    ..driver = driver.name
    ..driverUid = driver.uid
    ..trip = TripStatus.assigned;
  check(await bookingStore.advance(booking()), 'booking saved');
  info = await waitForTracking(token, (i) => i.stage == Stage.arranged);
  expect(info.trip, TripStatus.assigned);
  expect(info.driver, 'Mehmet');
  expect(info.vehicle, '06 KRU 001');
  expect(info.time, const TimeOfDay(hour: 10, minute: 0));

  // 6. Driver signs in on the driver dashboard and sees the trip.
  await staffAuth.signOut();
  expect(
      await staffAuth.signIn('coordinator@koru.test', 'staff-pass-123',
          role: Role.driver),
      SignInResult.notStaff,
      reason: 'a coordinator is not a driver');
  expect(await staffAuth.signIn(email, 'driver-pass-1', role: Role.driver),
      SignInResult.ok);
  expect(staffAuth.isDriver, true);
  expect(staffAuth.driverName, 'Mehmet Demir');
  await waitFor(
      bookingStore, () => bookingStore.bookings.any((b) => b.ref == ref));
  expect(bookingStore.bookings.map((b) => b.ref).join(','), ref);

  // 7. Driver drives the trip; the patient sees each step live.
  await bookingStore.nextTripStep(booking());
  await waitFor(bookingStore, () => booking().trip == TripStatus.enRoute);
  check(await bookingStore.shareLocation(booking(), const LatLng(39.93, 32.86)),
      'location saved');
  info = await waitForTracking(
      token, (i) => i.trip == TripStatus.enRoute && i.driverLocation != null);
  expect(info.driverLocation, const LatLng(39.93, 32.86));

  for (final step in [
    TripStatus.arrived,
    TripStatus.onBoard,
    TripStatus.completed,
  ]) {
    await bookingStore.nextTripStep(booking());
    await waitFor(bookingStore, () => booking().trip == step);
    info = await waitForTracking(token, (i) => i.trip == step);
  }
  expect(info.driverLocation, null);

  // What the server really has (not only what this browser wrote).
  const server = GetOptions(source: Source.server);
  final saved =
      await FirebaseFirestore.instance.doc('bookings/$ref').get(server);
  expect(saved.get('trip'), 'completed', reason: 'booking on the server');
  final live =
      await FirebaseFirestore.instance.doc('tracking/$token').get(server);
  expect(live.get('trip'), 'completed', reason: 'tracking on the server');

  await staffAuth.signOut();
  await tracking.forget();
  print('Flow finished for $ref');

  // 8. Free buses: empty until a coordinator fills a route in.
  ShuttleRoute route(ShuttleBranch b) =>
      shuttleStore.routes.firstWhere((r) => r.branch == b);
  expect(route(ShuttleBranch.sincan).announced, false,
      reason: 'no schedule before staff set one');
  expect(
      await shuttleStore.save(const ShuttleRoute(
          branch: ShuttleBranch.sincan,
          destination: 'Test stop',
          times: ['08:00'])),
      false,
      reason: 'visitors cannot change the free buses');

  expect(await staffAuth.signIn('coordinator@koru.test', 'staff-pass-123'),
      SignInResult.ok);
  expect(
      await shuttleStore.save(ShuttleRoute(
          branch: ShuttleBranch.sincan,
          destination: 'Test stop',
          times: parseTimes('17:45, 8:15')!,
          frequency: 30)),
      true);
  await staffAuth.signOut();

  // A visitor's homepage picks the change up by itself.
  await waitFor(shuttleStore, () => route(ShuttleBranch.sincan).announced);
  final sincan = route(ShuttleBranch.sincan);
  expect(sincan.destination, 'Test stop');
  expect(sincan.times.join(','), '08:15,17:45');
  expect(sincan.frequency, 30);
  expect(route(ShuttleBranch.cukurambar).announced, false);
  expect(route(ShuttleBranch.kavaklidere).announced, false);
  print('Free bus routes OK');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The app's own code (e.g. adding a driver) only uses the emulators when
  // built with this flag; without it, it would write to the real project.
  if (!const bool.fromEnvironment('USE_EMULATORS')) {
    print('FLOW FAILED: build with --dart-define=USE_EMULATORS=true');
    _showResult('FLOW FAILED: build with --dart-define=USE_EMULATORS=true');
    return;
  }
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    await runFlow().timeout(const Duration(minutes: 2));
    print('FLOW OK');
    _showResult('FLOW OK');
  } catch (e, stack) {
    print('FLOW FAILED: $e\n$stack');
    _showResult('FLOW FAILED: $e');
  }
}

// Also puts the result in the page title, for browsers whose console cannot
// be read from a script (e.g. Safari).
void _showResult(String text) => SystemChrome.setApplicationSwitcherDescription(
    ApplicationSwitcherDescription(label: text, primaryColor: 0xFF000000));
