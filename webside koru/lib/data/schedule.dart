import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../lang.dart';
import 'bookings.dart';

// How full a one-hour time slot is.
enum SlotStatus { available, booked, full, closed, past }

extension SlotStatusText on SlotStatus {
  String label(BuildContext context) => switch (this) {
        SlotStatus.available => context.t('Available', 'Müsait'),
        SlotStatus.booked => context.t('Booked', 'Rezervasyon var'),
        SlotStatus.full => context.t('Fully booked', 'Tamamen dolu'),
        SlotStatus.closed => context.t('Closed', 'Kapalı'),
        SlotStatus.past => context.t('Past', 'Geçti'),
      };
}

// One time slot: how many bookings it has and how many it takes.
class Slot {
  const Slot({
    required this.day,
    required this.hour,
    required this.count,
    required this.capacity,
    this.ownCapacity,
  });

  final DateTime day;
  final int hour;
  final int count;
  // Bookings this slot takes (its own number, or the admin's default).
  final int capacity;
  // The number the admin set for this slot only (null = the default).
  final int? ownCapacity;

  String get id => slotId(day, hour);
  int get left => (capacity - count).clamp(0, capacity);
  String get time => '${hour.toString().padLeft(2, '0')}:00';

  // Hours that have already started cannot be booked any more.
  bool get isPast =>
      DateTime(day.year, day.month, day.day, hour + 1).isBefore(DateTime.now());

  SlotStatus get status => isPast
      ? SlotStatus.past
      : capacity == 0
          ? SlotStatus.closed
          : count >= capacity
              ? SlotStatus.full
              : count > 0
                  ? SlotStatus.booked
                  : SlotStatus.available;

  // Whether a patient can still pick this slot.
  bool get open => status == SlotStatus.available || status == SlotStatus.booked;
}

// The 24 slots of a day, live from the "slots" collection, plus the
// admin's number of bookings per slot (settings/booking). Everyone may read
// these (they hold no personal data); only staff change the numbers.
class ScheduleStore extends ChangeNotifier {
  ScheduleStore() {
    _settings.snapshots().listen(
      (snap) {
        defaultCapacity =
            snap.data()?['capacity'] as int? ?? defaultSlotCapacity;
        notifyListeners();
      },
      onError: (Object e) => debugPrint('Loading booking settings failed: $e'),
    );
  }

  final _slots = FirebaseFirestore.instance.collection('slots');
  final _settings = FirebaseFirestore.instance.doc('settings/booking');

  // Bookings per slot, unless a slot has its own number.
  int defaultCapacity = defaultSlotCapacity;

  // Live slot documents of [day] by id (slots nobody booked yet have none).
  // Turn them into the 24 slots with [slotsOf].
  Stream<Map<String, Map<String, dynamic>>> watchDay(DateTime day) => _slots
      .where('date', isEqualTo: dayKey(day))
      .snapshots()
      .map((snap) => {for (final d in snap.docs) d.id: d.data()});

  // The 24 slots of [day], 00:00 to 23:00, from its slot documents.
  List<Slot> slotsOf(DateTime day, Map<String, Map<String, dynamic>> docs) => [
        for (var hour = 0; hour < 24; hour++)
          () {
            final d = docs[slotId(day, hour)];
            return Slot(
              day: day,
              hour: hour,
              count: d?['count'] as int? ?? 0,
              capacity: slotCapacity(d, {'capacity': defaultCapacity}),
              ownCapacity: d?['capacity'] as int?,
            );
          }(),
      ];

  // Staff: sets how many bookings every slot takes. Returns false if it
  // could not be saved.
  Future<bool> setDefaultCapacity(int capacity) async {
    try {
      await _settings.set(
          {'capacity': capacity, 'updatedAt': FieldValue.serverTimestamp()});
      return true;
    } catch (e) {
      debugPrint('Saving booking settings failed: $e');
      return false;
    }
  }

  // Staff: gives one slot its own number of bookings (0 closes it), or
  // null to use the default again. Bookings already in the slot stay.
  // Returns false if it could not be saved.
  Future<bool> setSlotCapacity(Slot slot, int? capacity) async {
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final doc = _slots.doc(slot.id);
        final saved = await tx.get(doc);
        tx.set(doc, {
          'date': dayKey(slot.day),
          'count': saved.data()?['count'] as int? ?? 0,
          'capacity': capacity,
          'lastRef': saved.data()?['lastRef'],
        });
      });
      return true;
    } catch (e) {
      debugPrint('Saving slot ${slot.id} failed: $e');
      return false;
    }
  }
}

// The one schedule store for the whole app.
final scheduleStore = ScheduleStore();

// Open slots on the same day, nearest to [hour] first (for "this time is
// fully booked, how about...").
List<Slot> alternativesFor(List<Slot> day, int hour, {int max = 4}) =>
    (day.where((s) => s.open && s.hour != hour).toList()
          ..sort((a, b) =>
              (a.hour - hour).abs().compareTo((b.hour - hour).abs())))
        .take(max)
        .toList()
      ..sort((a, b) => a.hour.compareTo(b.hour));
