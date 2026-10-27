import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// The free bus routes. Each route starts at a fixed Koru Hospital branch;
// staff set the destination, departure times and frequency in the admin
// dashboard (shuttleRoutes/{id} in Firestore).
enum ShuttleBranch {
  cukurambar('A', 'Koru Hospital Çukurambar', 'Koru Hastanesi Çukurambar'),
  sincan('B', 'Koru Hospital Sincan', 'Koru Hastanesi Sincan'),
  kavaklidere('C', 'Koru Hospital Kavaklıdere', 'Koru Hastanesi Kavaklıdere');

  const ShuttleBranch(this.id, this.en, this.tr);

  // Route letter, also the Firestore document id.
  final String id;
  // Branch name in English and Turkish.
  final String en;
  final String tr;
}

// What staff set for one route. Empty until an administrator fills it in.
class ShuttleRoute {
  const ShuttleRoute({
    required this.branch,
    this.destination = '',
    this.times = const [],
    this.frequency,
  });

  final ShuttleBranch branch;
  final String destination;
  // Departure times from the branch, "HH:MM", sorted.
  final List<String> times;
  // Minutes between buses (null when not set).
  final int? frequency;

  // Only shown to visitors once it has a destination and at least one time;
  // until then the homepage says "Schedule to be announced".
  bool get announced => destination.isNotEmpty && times.isNotEmpty;
}

// Turns "9:30" or "09:30" into "09:30". Returns null for anything that is
// not a time of day.
String? normalizeTime(String text) {
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(text.trim());
  if (match == null) return null;
  final h = int.parse(match.group(1)!);
  final m = int.parse(match.group(2)!);
  if (h > 23 || m > 59) return null;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

// Reads a list of times typed by staff ("08:00, 9:30 12:00"). Returns the
// sorted times without duplicates, or null if one of them is not a time.
List<String>? parseTimes(String text) {
  final times = <String>{};
  for (final part in text.split(RegExp(r'[\s,;]+'))) {
    if (part.isEmpty) continue;
    final time = normalizeTime(part);
    if (time == null) return null;
    times.add(time);
  }
  return times.toList()..sort();
}

// Current time in Ankara (Turkey is UTC+3 all year), so visitors see the
// right next bus whatever their device's time zone.
DateTime ankaraNow() => DateTime.now().toUtc().add(const Duration(hours: 3));

// The next departure after [now] (Ankara time): the time and whether it is
// tomorrow's first bus. Null when there are no times.
({String time, bool tomorrow})? nextDeparture(
    List<String> times, DateTime now) {
  if (times.isEmpty) return null;
  final current =
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  for (final t in times) {
    if (t.compareTo(current) >= 0) return (time: t, tomorrow: false);
  }
  return (time: times.first, tomorrow: true);
}

// Keeps the three routes in sync with the "shuttleRoutes" collection.
// Everyone (visitors too) reads them; only staff may save changes.
class ShuttleStore extends ChangeNotifier {
  ShuttleStore() {
    _sub = _db.snapshots().listen(
      (snap) {
        _saved
          ..clear()
          ..addEntries(snap.docs.map((d) => MapEntry(d.id, d.data())));
        notifyListeners();
      },
      onError: (Object e) => debugPrint('Loading free buses failed: $e'),
    );
  }

  final _db = FirebaseFirestore.instance.collection('shuttleRoutes');
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  // Saved documents by route id.
  final Map<String, Map<String, dynamic>> _saved = {};

  // All three routes in order A, B, C (empty ones too).
  List<ShuttleRoute> get routes => [
        for (final branch in ShuttleBranch.values)
          _fromData(branch, _saved[branch.id]),
      ];

  // Saves a route. Empty destination and no times puts it back to
  // "Schedule to be announced". Returns false if saving failed.
  Future<bool> save(ShuttleRoute route) async {
    try {
      await _db.doc(route.branch.id).set({
        'destination': route.destination,
        'times': route.times,
        'frequency': route.frequency,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Saving free bus ${route.branch.id} failed: $e');
      return false;
    }
  }

  // Turns a saved document into a route. Anything malformed is ignored, so
  // a bad value never shows on the homepage.
  static ShuttleRoute _fromData(ShuttleBranch branch, Map<String, dynamic>? d) {
    if (d == null) return ShuttleRoute(branch: branch);
    final times = <String>{
      for (final t in (d['times'] as List?) ?? const [])
        if (t is String && normalizeTime(t) != null) normalizeTime(t)!,
    }.toList()
      ..sort();
    final frequency = d['frequency'];
    return ShuttleRoute(
      branch: branch,
      destination: (d['destination'] as String? ?? '').trim(),
      times: times,
      frequency: frequency is int && frequency > 0 ? frequency : null,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// The one free bus store for the whole app.
final shuttleStore = ShuttleStore();
