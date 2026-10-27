import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../lang.dart';
import 'staff_auth.dart';

// Contact details used across the site.
// Replace the [PLACEHOLDERS] with the hospital's real details.
class ContactInfo {
  static const phone = '[PHONE]';
  static const whatsapp = '[WHATSAPP NUMBER]';
  static const email = '[EMAIL]';
  static const address = '[ADDRESS]';
}

// Hospital branches (used in dropdowns, the branch finder and contact page).
const branches = [
  'Koru Hospital Çukurambar',
  'Koru Hospital Sincan',
  'Koru Hospital Kavaklıdere',
];

// Where each branch is on the map (latitude, longitude).
// TODO: replace these placeholder points with each branch's real location.
const branchLocations = {
  'Koru Hospital Çukurambar': LatLng(39.9208, 32.8541),
  'Koru Hospital Sincan': LatLng(39.8890, 32.6640),
  'Koru Hospital Kavaklıdere': LatLng(39.9700, 32.5800),
};

// Map point of a branch (Ankara city centre if the branch has no point yet).
LatLng branchLocation(String branch) =>
    branchLocations[branch] ?? const LatLng(39.9334, 32.8597);

// The 4 kinds of transport a patient can book.
enum TransportType { ambulance, wheelchair, standard, airport }

extension TransportTypeText on TransportType {
  // Name shown to the user, in the current language.
  String label(BuildContext context) => switch (this) {
        TransportType.ambulance => context.t('Ambulance', 'Ambulans'),
        TransportType.wheelchair =>
          context.t('Wheelchair vehicle', 'Engelli aracı'),
        TransportType.standard => context.t('Standard car', 'Standart araç'),
        TransportType.airport =>
          context.t('Airport transfer', 'Havalimanı transferi'),
      };

  // Icon shown on cards and in tables.
  IconData get icon => switch (this) {
        TransportType.ambulance => Icons.local_hospital_outlined,
        TransportType.wheelchair => Icons.accessible,
        TransportType.standard => Icons.directions_car_outlined,
        TransportType.airport => Icons.flight_land,
      };
}

// Extra help the patient may need during the ride.
enum MobilityNeed { wheelchair, stretcher, oxygen, companion }

extension MobilityNeedText on MobilityNeed {
  String label(BuildContext context) => switch (this) {
        MobilityNeed.wheelchair =>
          context.t('Wheelchair', 'Tekerlekli sandalye'),
        MobilityNeed.stretcher => context.t('Stretcher', 'Sedye'),
        MobilityNeed.oxygen => context.t('Oxygen', 'Oksijen'),
        MobilityNeed.companion => context.t('Companion', 'Refakatçi'),
      };
}

// The stages a booking moves through, in order. The admin does every step:
// New request -> (confirm) -> Confirmed -> (reserve) -> Reserved
// -> (assign driver) -> Arranged.
enum Stage { newRequest, confirmed, reserved, arranged }

extension StageText on Stage {
  String label(BuildContext context) => switch (this) {
        Stage.newRequest => context.t('New requests', 'Yeni talepler'),
        Stage.confirmed => context.t('Confirmed', 'Onaylandı'),
        Stage.reserved => context.t('Reserved', 'Rezerve edildi'),
        Stage.arranged => context.t('Arranged', 'Araç atandı'),
      };

  // What the admin does next with bookings in this stage.
  String todo(BuildContext context) => switch (this) {
        Stage.newRequest => context.t('Next: confirm', 'Sıradaki: onayla'),
        Stage.confirmed => context.t('Next: reserve', 'Sıradaki: rezerve et'),
        Stage.reserved =>
          context.t('Next: assign driver', 'Sıradaki: sürücü ata'),
        Stage.arranged => context.t('Ready to go', 'Yola hazır'),
      };

  // The stage that comes after this one (none after "arranged").
  Stage? get next => this == Stage.arranged ? null : Stage.values[index + 1];
}

// After the admin assigns a driver, the driver moves the trip through these
// steps from the driver dashboard. The patient sees each one live.
enum TripStatus { assigned, enRoute, arrived, onBoard, completed }

extension TripStatusText on TripStatus {
  String label(BuildContext context) => switch (this) {
        TripStatus.assigned => context.t('Driver assigned', 'Sürücü atandı'),
        TripStatus.enRoute => context.t('Driver on the way', 'Sürücü yolda'),
        TripStatus.arrived => context.t('Driver has arrived', 'Sürücü geldi'),
        TripStatus.onBoard =>
          context.t('On the way to the hospital', 'Hastaneye gidiliyor'),
        TripStatus.completed =>
          context.t('Trip completed', 'Yolculuk tamamlandı'),
      };

  // Button the driver presses to reach the next step.
  String action(BuildContext context) => switch (this) {
        TripStatus.assigned => context.t('Start trip', 'Yola çık'),
        TripStatus.enRoute => context.t('I have arrived', 'Vardım'),
        TripStatus.arrived => context.t('Patient on board', 'Hasta araçta'),
        TripStatus.onBoard => context.t('Complete trip', 'Yolculuğu bitir'),
        TripStatus.completed => '',
      };

  IconData get icon => switch (this) {
        TripStatus.assigned => Icons.assignment_ind_outlined,
        TripStatus.enRoute => Icons.directions_car_outlined,
        TripStatus.arrived => Icons.place_outlined,
        TripStatus.onBoard => Icons.local_hospital_outlined,
        TripStatus.completed => Icons.check_circle_outline,
      };

  // The step that comes after this one (none after "completed").
  TripStatus? get next =>
      this == TripStatus.completed ? null : TripStatus.values[index + 1];

  // While the driver is driving, their location is shared with the patient.
  bool get sharesLocation =>
      this == TripStatus.enRoute || this == TripStatus.onBoard;
}

// One transport booking.
class Booking {
  Booking({
    required this.ref,
    required this.patient,
    required this.phone,
    required this.type,
    required this.from,
    required this.branch,
    required this.date,
    required this.time,
    this.needs = const {},
    this.notes = '',
    this.pickup,
    this.stage = Stage.newRequest,
  });

  // Reference number shown to the patient, e.g. KR-1004.
  final String ref;
  final String patient;
  final String phone;
  final String from;
  final String branch;
  final Set<MobilityNeed> needs;
  final String notes;
  // Pickup point the patient tapped on the map (null if not set).
  final LatLng? pickup;

  // These change while the admin works on the booking.
  TransportType type;
  DateTime date;
  TimeOfDay time;
  Stage stage;
  // Filled in when the admin assigns a driver.
  String? vehicle;
  String? driver;
  // The driver's account (drivers/{uid}); only that driver sees the booking.
  String? driverUid;
  // Set by the driver once the booking is arranged.
  TripStatus? trip;
  // Where the driver is now (shared while driving).
  LatLng? driverLocation;
  // Id of the patient's tracking copy (tracking/{trackingId}).
  String? trackingId;

  // Same booking with the same values (to change a copy before saving).
  Booking copy() => Booking(
        ref: ref,
        patient: patient,
        phone: phone,
        type: type,
        from: from,
        branch: branch,
        date: date,
        time: time,
        needs: needs,
        notes: notes,
        pickup: pickup,
        stage: stage,
      )
        ..vehicle = vehicle
        ..driver = driver
        ..driverUid = driverUid
        ..trip = trip
        ..driverLocation = driverLocation
        ..trackingId = trackingId;
}

// What the patient gets back after booking: the reference, the secret
// tracking code to type on the tracking page, and the tracking link itself.
class BookingReceipt {
  const BookingReceipt(this.booking, this.code, this.token);

  final Booking booking;
  final String code;
  final String token;
}

// Tracking codes use letters and digits that are hard to mix up
// (no 0/O, 1/I/L). 8 characters = about 850 billion possible codes.
const _codeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
const trackingCodeLength = 8;

String _newTrackingCode() {
  final random = Random.secure();
  return [
    for (var i = 0; i < trackingCodeLength; i++)
      _codeAlphabet[random.nextInt(_codeAlphabet.length)]
  ].join();
}

// The id of a booking's tracking copy: a hash of the reference and the
// secret code. Only someone who has both can work it out, and the code
// itself is never saved anywhere.
String trackingIdFor(String ref, String code) =>
    sha256.convert(utf8.encode('$ref:$code')).toString();

// The parts of a booking the patient's tracking page may show. No name,
// phone, address or notes, the driver's first name only, and their location
// only while driving. The Firestore rules check this copy matches the
// booking on every write.
Map<String, dynamic> _trackingDoc(Booking b, {LatLng? driverLocation}) => {
      'ref': b.ref,
      'type': b.type.name,
      'branch': b.branch,
      'date': Timestamp.fromDate(b.date),
      'time': formatTime(b.time),
      'stage': b.stage.name,
      'trip': b.trip?.name,
      'driver': b.driver?.split(' ').first,
      'vehicle': b.vehicle,
      'driverLocation': driverLocation == null
          ? null
          : GeoPoint(driverLocation.latitude, driverLocation.longitude),
      'updatedAt': FieldValue.serverTimestamp(),
    };

// Keeps bookings in sync with the "bookings" collection in Firestore and
// tells the screens when something changes. Signed-in staff see every
// booking, a signed-in driver sees the bookings assigned to them, and
// patients can only add new ones.
class BookingStore extends ChangeNotifier {
  BookingStore() {
    staffAuth.addListener(_listen);
    _listen();
  }

  final _db = FirebaseFirestore.instance.collection('bookings');
  final _tracking = FirebaseFirestore.instance.collection('tracking');
  final _counter = FirebaseFirestore.instance.doc('counters/bookings');
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  final List<Booking> bookings = [];

  // Staff signed in: load all bookings (newest first) and keep them updated.
  // Driver signed in: only their own trips, by date.
  // Signed out: forget them.
  void _listen() {
    _sub?.cancel();
    _sub = null;
    bookings.clear();
    notifyListeners();
    final Query<Map<String, dynamic>> query;
    if (staffAuth.isStaff) {
      query = _db.orderBy('createdAt', descending: true);
    } else if (staffAuth.isDriver) {
      query = _db.where('driverUid', isEqualTo: staffAuth.uid);
    } else {
      return;
    }
    _sub = query.snapshots().listen(
      (snap) {
        bookings
          ..clear()
          ..addAll(snap.docs.map((d) => _fromDoc(d.data())));
        if (staffAuth.isDriver) {
          bookings.sort((a, b) => a.date.compareTo(b.date));
        }
        notifyListeners();
      },
      onError: (Object e) => debugPrint('Loading bookings failed: $e'),
    );
  }

  // Sends a new booking from the website form. Takes the next number
  // (KR-1001, KR-1002, ...) and saves the booking with its tracking copy in
  // one step, so two patients never get the same number. Returns the
  // reference and the secret tracking code. Throws if it could not be saved.
  Future<BookingReceipt> add({
    required String patient,
    required String phone,
    required TransportType type,
    required String from,
    required String branch,
    required DateTime date,
    required TimeOfDay time,
    required Set<MobilityNeed> needs,
    required String notes,
    LatLng? pickup,
  }) async {
    final code = _newTrackingCode();
    final booking = await FirebaseFirestore.instance.runTransaction((tx) async {
      final counter = await tx.get(_counter);
      final n = counter.data()?['next'] as int? ?? 1001;
      final booking = Booking(
        ref: 'KR-$n',
        patient: patient,
        phone: phone,
        type: type,
        from: from,
        branch: branch,
        date: date,
        time: time,
        needs: needs,
        notes: notes,
        pickup: pickup,
      )..trackingId = trackingIdFor('KR-$n', code);
      tx.set(_counter, {'next': n + 1});
      tx.set(_db.doc(booking.ref), {
        ..._toDoc(booking),
        'driverLocation': null,
        'trackingId': booking.trackingId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.set(_tracking.doc(booking.trackingId), _trackingDoc(booking));
      return booking;
    });
    return BookingReceipt(booking, code, booking.trackingId!);
  }

  // Moves a booking to the next stage and saves it (also saves any changes
  // the admin made in the dialog, like date, time, driver). Returns false
  // if it could not be saved.
  Future<bool> advance(Booking booking) async {
    final next = booking.stage.next;
    if (next == null) return false;
    booking.stage = next;
    notifyListeners();
    return _save(booking);
  }

  // Driver dashboard: moves the trip to its next step. The location is
  // shared again from the next GPS update.
  Future<void> nextTripStep(Booking booking) async {
    final next = booking.trip?.next;
    if (next == null) return;
    final batch = FirebaseFirestore.instance.batch()
      ..update(_db.doc(booking.ref), {
        'trip': next.name,
        'tripUpdatedAt': FieldValue.serverTimestamp(),
        // Stop showing the old location once the driver stops driving.
        if (!next.sharesLocation) 'driverLocation': null,
      });
    _refreshTracking(batch, booking.copy()..trip = next);
    await batch.commit();
  }

  // Driver dashboard: shares where the driver is now. Returns false if it
  // could not be saved.
  Future<bool> shareLocation(Booking booking, LatLng point) async {
    try {
      final batch = FirebaseFirestore.instance.batch()
        ..update(_db.doc(booking.ref),
            {'driverLocation': GeoPoint(point.latitude, point.longitude)});
      _refreshTracking(batch, booking,
          driverLocation: booking.trip?.sharesLocation == true ? point : null);
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Sharing location for ${booking.ref} failed: $e');
      return false;
    }
  }

  // Saves the admin's changes to a booking. Returns false if it could not
  // be saved.
  Future<bool> _save(Booking b) async {
    try {
      final batch = FirebaseFirestore.instance.batch()
        ..update(_db.doc(b.ref), _toDoc(b));
      _refreshTracking(batch, b);
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Saving booking ${b.ref} failed: $e');
      return false;
    }
  }

  // Every change to a booking also updates the patient's tracking copy in
  // the same write (the rules refuse one without the other).
  void _refreshTracking(WriteBatch batch, Booking b, {LatLng? driverLocation}) {
    final id = b.trackingId;
    if (id == null) return;
    batch.set(
        _tracking.doc(id), _trackingDoc(b, driverLocation: driverLocation));
  }

  // A booking as a Firestore document (the reference is the document id).
  static Map<String, dynamic> _toDoc(Booking b) => {
        'ref': b.ref,
        'patient': b.patient,
        'phone': b.phone,
        'type': b.type.name,
        'from': b.from,
        'branch': b.branch,
        'date': Timestamp.fromDate(b.date),
        'time': formatTime(b.time),
        'needs': [for (final n in b.needs) n.name],
        'notes': b.notes,
        'pickup': b.pickup == null
            ? null
            : GeoPoint(b.pickup!.latitude, b.pickup!.longitude),
        'stage': b.stage.name,
        'vehicle': b.vehicle,
        'driver': b.driver,
        'driverUid': b.driverUid,
        'trip': b.trip?.name,
      };

  // Turns a saved Firestore document back into a Booking.
  static Booking _fromDoc(Map<String, dynamic> d) {
    final time = (d['time'] as String? ?? '00:00').split(':');
    final pickup = d['pickup'] as GeoPoint?;
    final driverLocation = d['driverLocation'] as GeoPoint?;
    final trip = d['trip'] as String?;
    return Booking(
      ref: d['ref'] as String,
      patient: d['patient'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      type: TransportType.values.byName(d['type'] as String),
      from: d['from'] as String? ?? '',
      branch: d['branch'] as String? ?? '',
      date: (d['date'] as Timestamp).toDate(),
      time: TimeOfDay(hour: int.parse(time[0]), minute: int.parse(time[1])),
      needs: {
        for (final n in (d['needs'] as List? ?? []))
          MobilityNeed.values.byName(n as String)
      },
      notes: d['notes'] as String? ?? '',
      pickup: pickup == null ? null : LatLng(pickup.latitude, pickup.longitude),
      stage: Stage.values.byName(d['stage'] as String),
    )
      ..vehicle = d['vehicle'] as String?
      ..driver = d['driver'] as String?
      ..driverUid = d['driverUid'] as String?
      ..trip = trip == null ? null : TripStatus.values.byName(trip)
      ..driverLocation = driverLocation == null
          ? null
          : LatLng(driverLocation.latitude, driverLocation.longitude)
      ..trackingId = d['trackingId'] as String?;
  }

  @override
  void dispose() {
    staffAuth.removeListener(_listen);
    _sub?.cancel();
    super.dispose();
  }
}

// The one booking store for the whole app.
final bookingStore = BookingStore();

// Date as 25.10.2026 (Turkish style, clear in both languages).
String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

// Time as 09:30.
String formatTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
