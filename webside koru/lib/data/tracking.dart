import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bookings.dart';

// What happened when a patient looked up their booking.
enum LookupResult { ok, notFound, failed }

// What the patient's tracking page shows. A safe copy of the booking, saved
// with every change to it (no name, phone or address).
class TrackingInfo {
  TrackingInfo({
    required this.ref,
    required this.type,
    required this.branch,
    required this.date,
    required this.time,
    required this.stage,
    this.trip,
    this.driver,
    this.vehicle,
    this.driverLocation,
  });

  final String ref;
  final TransportType type;
  final String branch;
  final DateTime date;
  final TimeOfDay time;
  final Stage stage;
  final TripStatus? trip;
  // Driver's first name and vehicle plate, once a driver is assigned.
  final String? driver;
  final String? vehicle;
  // Where the driver is now (only while driving).
  final LatLng? driverLocation;

  static TrackingInfo fromDoc(Map<String, dynamic> d) {
    final time = (d['time'] as String? ?? '00:00').split(':');
    final trip = d['trip'] as String?;
    final location = d['driverLocation'] as GeoPoint?;
    return TrackingInfo(
      ref: d['ref'] as String,
      type: TransportType.values.byName(d['type'] as String),
      branch: d['branch'] as String? ?? '',
      date: (d['date'] as Timestamp).toDate(),
      time: TimeOfDay(hour: int.parse(time[0]), minute: int.parse(time[1])),
      stage: Stage.values.byName(d['stage'] as String),
      trip: trip == null ? null : TripStatus.values.byName(trip),
      driver: d['driver'] as String?,
      vehicle: d['vehicle'] as String?,
      driverLocation: location == null
          ? null
          : LatLng(location.latitude, location.longitude),
    );
  }
}

// Booking lookup and live tracking for patients.
// The tracking link (token) is remembered in this browser, so the patient
// does not need to type the code again after a refresh.
class Tracking {
  static const _key = 'tracking_token';

  // Works out the tracking link from reference + code and checks that it
  // exists. On success returns the tracking link and remembers it.
  // Patients may type the code in lower case or with spaces/dashes.
  Future<(LookupResult, String?)> lookup(String ref, String code) async {
    ref = ref.trim().toUpperCase();
    code = code.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
    if (!RegExp(r'^KR-\d{1,9}$').hasMatch(ref) ||
        code.length != trackingCodeLength) {
      return (LookupResult.notFound, null);
    }
    final token = trackingIdFor(ref, code);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('tracking')
          .doc(token)
          .get(const GetOptions(source: Source.server));
      if (!doc.exists) return (LookupResult.notFound, null);
      await remember(token);
      return (LookupResult.ok, token);
    } catch (e) {
      debugPrint('Lookup failed: $e');
      return (LookupResult.failed, null);
    }
  }

  // Live updates for one booking (null while it is not there yet).
  Stream<TrackingInfo?> watch(String token) => FirebaseFirestore.instance
      .collection('tracking')
      .doc(token)
      .snapshots()
      .map((s) => s.exists ? TrackingInfo.fromDoc(s.data()!) : null);

  Future<void> remember(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, token);
    } catch (e) {
      debugPrint('Saving tracking link failed: $e');
    }
  }

  Future<String?> saved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_key);
    } catch (e) {
      return null;
    }
  }

  Future<void> forget() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      debugPrint('Forgetting tracking link failed: $e');
    }
  }
}

// The one tracking helper for the whole app.
final tracking = Tracking();
