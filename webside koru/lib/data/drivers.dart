import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
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

  // Creates the driver's sign-in account and profile. Returns null when it
  // worked, otherwise the error code, e.g. "already-exists" or
  // "invalid-argument".
  Future<String?> add({
    required String name,
    required String phone,
    required String vehicle,
    required String email,
    required String password,
  }) async {
    final String uid;
    try {
      uid = await _createAccount(email, password);
    } on FirebaseAuthException catch (e) {
      debugPrint('Creating driver account failed: ${e.code}');
      return switch (e.code) {
        'email-already-in-use' => 'already-exists',
        'invalid-email' || 'weak-password' => 'invalid-argument',
        _ => 'unknown',
      };
    } catch (e) {
      debugPrint('Creating driver account failed: $e');
      return 'unknown';
    }
    return _write(
        uid,
        () => _db.doc(uid).set({
              'name': name,
              'phone': phone,
              'vehicle': vehicle,
              'email': email,
              'active': true,
              'createdAt': FieldValue.serverTimestamp(),
            }));
  }

  // Saves new details for a driver. The sign-in email cannot be changed
  // from the website (only in the Firebase console). Returns null or the
  // error code, like add.
  Future<String?> edit(
    Driver driver, {
    required String name,
    required String phone,
    required String vehicle,
  }) =>
      _write(
          driver.uid,
          () => _db
              .doc(driver.uid)
              .update({'name': name, 'phone': phone, 'vehicle': vehicle}));

  // Emails the driver a link to choose a new password. Returns null or the
  // error code.
  Future<String?> sendPasswordReset(Driver driver) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: driver.email);
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Password reset for ${driver.uid} failed: ${e.code}');
      return e.code;
    }
  }

  // Removes the driver's profile. Without it the account can no longer
  // sign in to the driver dashboard or see any booking. (The sign-in
  // account itself stays in Firebase Authentication, where it can be
  // deleted by hand.) Returns null or the error code.
  Future<String?> delete(Driver driver) =>
      _write(driver.uid, () => _db.doc(driver.uid).delete());

  Future<String?> _write(String uid, Future<void> Function() action) async {
    try {
      await action();
      return null;
    } on FirebaseException catch (e) {
      debugPrint('Saving driver $uid failed: ${e.code}');
      return e.code;
    } catch (e) {
      debugPrint('Saving driver $uid failed: $e');
      return 'unknown';
    }
  }

  // Makes a new email + password account without signing the coordinator
  // out: it signs up through a second copy of Firebase that only lives
  // for this, then signs that copy out again.
  Future<String> _createAccount(String email, String password) async {
    final auth = await (_signUpAuth ??= _openSignUpAuth());
    final cred = await auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await auth.signOut();
    return cred.user!.uid;
  }

  Future<FirebaseAuth>? _signUpAuth;

  static Future<FirebaseAuth> _openSignUpAuth() async {
    final app = await Firebase.initializeApp(
        name: 'driver-sign-up',
        options: DefaultFirebaseOptions.currentPlatform);
    final auth = FirebaseAuth.instanceFor(app: app);
    if (const bool.fromEnvironment('USE_EMULATORS')) {
      await auth.useAuthEmulator('localhost', 9099);
    }
    return auth;
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
