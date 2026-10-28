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
// Staff may cancel a booking at any stage (its place in the time slot is
// freed) and restore it later, which starts it again as a new request.
enum Stage { newRequest, confirmed, reserved, arranged, cancelled }

extension StageText on Stage {
  String label(BuildContext context) => switch (this) {
        Stage.newRequest => context.t('New requests', 'Yeni talepler'),
        Stage.confirmed => context.t('Confirmed', 'Onaylandı'),
        Stage.reserved => context.t('Reserved', 'Rezerve edildi'),
        Stage.arranged => context.t('Arranged', 'Araç atandı'),
        Stage.cancelled => context.t('Cancelled', 'İptal edildi'),
      };

  // What the admin does next with bookings in this stage.
  String todo(BuildContext context) => switch (this) {
        Stage.newRequest => context.t('Next: confirm', 'Sıradaki: onayla'),
        Stage.confirmed => context.t('Next: reserve', 'Sıradaki: rezerve et'),
        Stage.reserved =>
          context.t('Next: assign driver', 'Sıradaki: sürücü ata'),
        Stage.arranged => context.t('Ready to go', 'Yola hazır'),
        Stage.cancelled =>
          context.t('Time slot freed', 'Saat dilimi boşaltıldı'),
      };

  // The stage that comes after this one (none after "arranged", and a
  // cancelled booking is only restored by hand).
  Stage? get next => switch (this) {
        Stage.newRequest => Stage.confirmed,
        Stage.confirmed => Stage.reserved,
        Stage.reserved => Stage.arranged,
        Stage.arranged || Stage.cancelled => null,
      };
}

// Bookings are taken in one-hour time slots, 00:00 to 23:00. Each slot has
// a document slots/{id} counting the bookings in it, so the rules can
// refuse a booking once the slot is full. The id is the day and the hour,
// e.g. 2026-11-03T09.
String slotId(DateTime day, int hour) =>
    '${dayKey(day)}T${hour.toString().padLeft(2, '0')}';

// The day part of a slot id, e.g. 2026-11-03.
String dayKey(DateTime day) => '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

// The time slot a booking should hold a place in (none once cancelled).
String? slotOf(Booking b) =>
    b.stage == Stage.cancelled ? null : slotId(b.date, b.time.hour);

// Bookings per slot when the admin has not set a number yet. Must match
// defaultCapacity() in firestore.rules.
const defaultSlotCapacity = 3;

// How many bookings a slot takes: its own number if the admin set one
// (0 = closed), otherwise the admin's number for every slot.
int slotCapacity(Map<String, dynamic>? slot, Map<String, dynamic>? settings) =>
    slot?['capacity'] as int? ??
    settings?['capacity'] as int? ??
    defaultSlotCapacity;

// Thrown when the chosen time slot has no places left.
class SlotFullException implements Exception {
  const SlotFullException(this.slot);

  final String slot;

  @override
  String toString() => 'Time slot $slot is fully booked';
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
  // The time slot this booking holds a place in, as saved (null when it
  // holds none: cancelled, or made before slots existed).
  String? slot;
  // When the patient sent the request.
  DateTime? createdAt;

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
        ..trackingId = trackingId
        ..slot = slot
        ..createdAt = createdAt;
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
  final _slots = FirebaseFirestore.instance.collection('slots');
  final _settings = FirebaseFirestore.instance.doc('settings/booking');
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  final List<Booking> bookings = [];

  // Each booking as last saved, to put back on screen if a change could
  // not be saved.
  final Map<String, Map<String, dynamic>> _saved = {};

  // Bookings that arrive while a staff member has the site open (not the
  // ones already there when it loaded). The dashboard shows a message.
  final _arrivals = StreamController<Booking>.broadcast();
  Stream<Booking> get arrivals => _arrivals.stream;

  // How many requests are waiting to be confirmed.
  int get waiting => bookings.where((b) => b.stage == Stage.newRequest).length;

  // Staff signed in: load all bookings (newest first) and keep them updated.
  // Driver signed in: only their own trips, by date (not cancelled ones).
  // Signed out: forget them.
  void _listen() {
    _sub?.cancel();
    _sub = null;
    bookings.clear();
    _saved.clear();
    notifyListeners();
    final Query<Map<String, dynamic>> query;
    if (staffAuth.isStaff) {
      query = _db.orderBy('createdAt', descending: true);
    } else if (staffAuth.isDriver) {
      query = _db.where('driverUid', isEqualTo: staffAuth.uid);
    } else {
      return;
    }
    // Becomes true once the list has come from the server, so the bookings
    // that were already there do not count as new.
    var loaded = false;
    _sub = query.snapshots().listen(
      (snap) {
        _saved
          ..clear()
          ..addAll({for (final d in snap.docs) d.id: d.data()});
        bookings
          ..clear()
          ..addAll(snap.docs.map((d) => _fromDoc(d.data())));
        if (staffAuth.isDriver) {
          bookings
            ..removeWhere((b) => b.stage == Stage.cancelled)
            ..sort((a, b) => a.date.compareTo(b.date));
        }
        if (loaded && staffAuth.isStaff) {
          for (final change in snap.docChanges) {
            if (change.type == DocumentChangeType.added) {
              _arrivals.add(_fromDoc(change.doc.data()!));
            }
          }
        }
        if (!snap.metadata.isFromCache) loaded = true;
        notifyListeners();
      },
      onError: (Object e) => debugPrint('Loading bookings failed: $e'),
    );
  }

  // Inside a transaction: checks there is room in slot [to] and returns the
  // writes that free the place held in [from] and take one in [to] (either
  // may be null). Reads must come before writes in a transaction, so the
  // caller runs the returned writes after its own reads. Throws
  // SlotFullException if [to] is full.
  Future<void Function()> _moveSlot(
      Transaction tx, String? from, String? to, String ref) async {
    if (from == to) return () {};
    final old = from == null ? null : await tx.get(_slots.doc(from));
    final next = to == null ? null : await tx.get(_slots.doc(to));
    final settings = to == null ? null : await tx.get(_settings);
    final nextCount = next?.data()?['count'] as int? ?? 0;
    if (next != null &&
        nextCount >= slotCapacity(next.data(), settings!.data())) {
      throw SlotFullException(to!);
    }
    return () {
      final oldCount = old?.data()?['count'] as int? ?? 0;
      if (old != null && oldCount > 0) {
        tx.update(old.reference, {'count': oldCount - 1});
      }
      if (next != null) {
        tx.set(next.reference, {
          'date': to!.split('T').first,
          'count': nextCount + 1,
          'capacity': next.data()?['capacity'],
          'lastRef': ref,
        });
      }
    };
  }

  // Sends a new booking from the website form. Takes the next number
  // (KR-1001, KR-1002, ...) and a place in the time slot, and saves the
  // booking with its tracking copy in one step, so two patients never get
  // the same number and a slot never takes more bookings than allowed.
  // Returns the reference and the secret tracking code. Throws
  // SlotFullException if the slot is full, or another error if it could
  // not be saved.
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
      booking.slot = slotOf(booking);
      final takeSlot = await _moveSlot(tx, null, booking.slot, booking.ref);
      tx.set(_counter, {'next': n + 1});
      tx.set(_db.doc(booking.ref), {
        ..._toDoc(booking),
        'driverLocation': null,
        'trackingId': booking.trackingId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.set(_tracking.doc(booking.trackingId), _trackingDoc(booking));
      takeSlot();
      return booking;
    });
    return BookingReceipt(booking, code, booking.trackingId!);
  }

  // Moves a booking to the next stage and saves it (also saves any changes
  // the admin made in the dialog, like date, time, driver). Returns null
  // when saved, 'slot-full' if the new time slot has no room, or 'failed'.
  Future<String?> advance(Booking booking) async {
    final next = booking.stage.next;
    if (next == null) return 'failed';
    booking.stage = next;
    notifyListeners();
    return _save(booking);
  }

  // Cancels a booking and frees its place in the time slot. The patient
  // sees "Cancelled" on the tracking page.
  Future<String?> cancel(Booking booking) {
    booking.stage = Stage.cancelled;
    notifyListeners();
    return _save(booking);
  }

  // Brings a cancelled booking back as a new request, without a driver.
  // It needs a free place in its time slot again.
  Future<String?> restore(Booking booking) {
    booking
      ..stage = Stage.newRequest
      ..vehicle = null
      ..driver = null
      ..driverUid = null
      ..trip = null;
    notifyListeners();
    return _save(booking);
  }

  // Moves a booking to another day and time, in a slot with room.
  Future<String?> reschedule(Booking booking, DateTime date, TimeOfDay time) {
    booking
      ..date = date
      ..time = time;
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

  // Saves the admin's changes to a booking, with its tracking copy. If the
  // time changed or the booking was cancelled or restored, its place moves
  // to the right time slot in the same step. Returns null when saved,
  // 'slot-full' if the new slot has no room, or 'failed'; either way the
  // booking goes back to how it was saved.
  Future<String?> _save(Booking b) async {
    final slot = slotOf(b);
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        // The slot as saved now (another coordinator may have changed it).
        final saved = await tx.get(_db.doc(b.ref));
        final moveSlot = await _moveSlot(
            tx, saved.data()?['slot'] as String?, slot, b.ref);
        tx.update(_db.doc(b.ref), {..._toDoc(b), 'slot': slot});
        if (b.trackingId != null) {
          tx.set(_tracking.doc(b.trackingId), _trackingDoc(b));
        }
        moveSlot();
      });
      b.slot = slot;
      return null;
    } on SlotFullException {
      _undo(b);
      return 'slot-full';
    } catch (e) {
      debugPrint('Saving booking ${b.ref} failed: $e');
      _undo(b);
      return 'failed';
    }
  }

  // Shows a booking as it was last saved again.
  void _undo(Booking b) {
    final saved = _saved[b.ref];
    final i = bookings.indexOf(b);
    if (saved == null || i < 0) return;
    bookings[i] = _fromDoc(saved);
    notifyListeners();
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
        'slot': b.slot,
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
      ..trackingId = d['trackingId'] as String?
      ..slot = d['slot'] as String?
      ..createdAt = (d['createdAt'] as Timestamp?)?.toDate();
  }

  @override
  void dispose() {
    staffAuth.removeListener(_listen);
    _sub?.cancel();
    _arrivals.close();
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
