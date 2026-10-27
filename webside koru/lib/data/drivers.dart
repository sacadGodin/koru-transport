import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import 'bookings.dart';
import 'staff_auth.dart';

// One driver account (drivers/{uid} in Firestore).
class Driver {
  Driver({
    required this.uid,
    required this.name,
    required this.phone,
    required this.vehicle,
    required this.email,
    required this.active,
  });

  final String uid;
  final String name;
  final String phone;
  // Plate of the vehicle the driver usually drives (may be empty).
  final String vehicle;
  final String email;
  // Switched-off drivers cannot sign in or see any booking.
  bool active;
}

// Keeps the driver list in sync for the admin dashboard (staff only).
class DriverStore extends ChangeNotifier {
  DriverStore() {
    staffAuth.addListener(_listen);
    _listen();
  }

  final _db = FirebaseFirestore.instance.collection('drivers');
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  final List<Driver> drivers = [];

  // Drivers who can be given a booking.
  List<Driver> get active => drivers.where((d) => d.active).toList();

  void _listen() {
    _sub?.cancel();
    _sub = null;
    drivers.clear();
    notifyListeners();
    if (!staffAuth.isStaff) return;
    _sub = _db.orderBy('name').snapshots().listen(
      (snap) {
        drivers
          ..clear()
          ..addAll(snap.docs.map(_fromDoc));
        notifyListeners();
      },
      onError: (Object e) => debugPrint('Loading drivers failed: $e'),
    );
  }

  // Creates the driver's sign-in account and profile (createDriver
  // function). Returns null when it worked, otherwise the error code, e.g.
  // "already-exists" or "invalid-argument".
  Future<String?> add({
    required String name,
    required String phone,
    required String vehicle,
    required String email,
    required String password,
  }) =>
      _call('createDriver', {
        'name': name,
        'phone': phone,
        'vehicle': vehicle,
        'email': email,
        'password': password,
      });

  // Saves new details for a driver (updateDriver function). An empty
  // password keeps the old one. Returns null or the error code, like add.
  Future<String?> edit(
    Driver driver, {
    required String name,
    required String phone,
    required String vehicle,
    required String email,
    required String password,
  }) =>
      _call('updateDriver', {
        'uid': driver.uid,
        'name': name,
        'phone': phone,
        'vehicle': vehicle,
        'email': email,
        if (password.isNotEmpty) 'password': password,
      });

  // Removes the driver's sign-in account and profile (deleteDriver
  // function). Returns null or the error code.
  Future<String?> delete(Driver driver) =>
      _call('deleteDriver', {'uid': driver.uid});

  Future<String?> _call(String name, Map<String, Object> data) async {
    try {
      await cloudFunctions.httpsCallable(name).call(data);
      return null;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('$name failed: ${e.code} ${e.message}');
      return e.code;
    } catch (e) {
      debugPrint('$name failed: $e');
      return 'unknown';
    }
  }

  // Switches a driver on or off.
  Future<void> setActive(Driver driver, bool value) async {
    driver.active = value;
    notifyListeners();
    try {
      await _db.doc(driver.uid).update({'active': value});
    } catch (e) {
      debugPrint('Saving driver ${driver.uid} failed: $e');
    }
  }

  static Driver _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return Driver(
      uid: doc.id,
      name: d['name'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      vehicle: d['vehicle'] as String? ?? '',
      email: d['email'] as String? ?? '',
      active: d['active'] as bool? ?? false,
    );
  }

  @override
  void dispose() {
    staffAuth.removeListener(_listen);
    _sub?.cancel();
    super.dispose();
  }
}

// The one driver store for the whole app.
final driverStore = DriverStore();
