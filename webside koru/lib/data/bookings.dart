import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
}

// What the patient gets back after booking: the reference, the secret
// tracking code to type on the tracking page, and the tracking link itself.
class BookingReceipt {
  const BookingReceipt(this.booking, this.code, this.token);

  final Booking booking;
  final String code;
  final String token;
}

// Cloud Functions live in the same region as the Firestore database.
FirebaseFunctions get cloudFunctions =>
    FirebaseFunctions.instanceFor(region: 'asia-northeast1');

// Keeps bookings in sync with the "bookings" collection in Firestore and
// tells the screens when something changes. Signed-in staff see every
// booking, a signed-in driver sees the bookings assigned to them, and
// patients can only add new ones (through the createBooking function).
class BookingStore extends ChangeNotifier {
  BookingStore() {
    staffAuth.addListener(_listen);
    _listen();
  }

  final _db = FirebaseFirestore.instance.collection('bookings');
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

  // Sends a new booking from the website form. The createBooking Cloud
  // Function checks it, gives it the next number (KR-1001, KR-1002, ...)
  // and a secret tracking code. Throws if it could not be saved.
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
    final result =
        await cloudFunctions.httpsCallable('createBooking').call<Map>({
      'patient': patient,
      'phone': phone,
      'type': type.name,
      'from': from,
      'branch': branch,
      'date': date.millisecondsSinceEpoch,
      'time': formatTime(time),
      'needs': [for (final n in needs) n.name],
      'notes': notes,
      'pickup': pickup == null
          ? null
          : {'lat': pickup.latitude, 'lng': pickup.longitude},
    });
    final data = result.data;
    final booking = Booking(
      ref: data['ref'] as String,
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
    );
    return BookingReceipt(
        booking, data['code'] as String, data['token'] as String);
  }

  // Moves a booking to the next stage and saves it (also saves any changes
  // the admin made in the dialog, like date, time, driver).
  void advance(Booking booking) {
    final next = booking.stage.next;
    if (next == null) return;
    booking.stage = next;
    notifyListeners();
    _save(booking);
  }

  // Driver dashboard: moves the trip to its next step.
  Future<void> nextTripStep(Booking booking) async {
    final next = booking.trip?.next;
    if (next == null) return;
    await _db.doc(booking.ref).update({
      'trip': next.name,
      'tripUpdatedAt': FieldValue.serverTimestamp(),
      // Stop showing the old location once the driver stops driving.
      if (!next.sharesLocation) 'driverLocation': null,
    });
  }

  // Driver dashboard: shares where the driver is now.
  Future<void> shareLocation(Booking booking, LatLng point) async {
    try {
      await _db.doc(booking.ref).update(
          {'driverLocation': GeoPoint(point.latitude, point.longitude)});
    } catch (e) {
      debugPrint('Sharing location for ${booking.ref} failed: $e');
    }
  }

  // Saves the admin's changes to a booking.
  Future<void> _save(Booking b) async {
    try {
      await _db.doc(b.ref).update(_toDoc(b));
    } catch (e) {
      debugPrint('Saving booking ${b.ref} failed: $e');
    }
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
          : LatLng(driverLocation.latitude, driverLocation.longitude);
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
