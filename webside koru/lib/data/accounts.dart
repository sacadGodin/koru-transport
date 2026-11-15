import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'staff_auth.dart';

// One staff account (staff/{uid} in Firestore). Accounts added by hand in
// the Firebase console may have no name, email or role.
class StaffAccount {
  StaffAccount({
    required this.uid,
    required this.name,
    required this.email,
    required this.admin,
  });

  final String uid;
  final String name;
  final String email;
  // true = admin (manages everything), false = staff (main site only).
  final bool admin;
}

// Keeps the staff account list in sync for the admin dashboard (admins
// only). Drivers are in drivers.dart.
class AccountStore extends ChangeNotifier {
  AccountStore() {
    staffAuth.addListener(_listen);
    _listen();
  }

  final _db = FirebaseFirestore.instance.collection('staff');
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  final List<StaffAccount> accounts = [];

  void _listen() {
    _sub?.cancel();
    _sub = null;
    accounts.clear();
    notifyListeners();
    if (!staffAuth.isAdmin) return;
    _sub = _db.snapshots().listen(
      (snap) {
        accounts
          ..clear()
          ..addAll(snap.docs.map(_fromDoc))
          // Admins first, then by name.
          ..sort((a, b) => a.admin != b.admin
              ? (a.admin ? -1 : 1)
              : a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        notifyListeners();
      },
      onError: (Object e) => debugPrint('Loading staff accounts failed: $e'),
    );
  }

  // Creates the sign-in account and adds it to the staff list. Returns null
  // when it worked, otherwise the error code, e.g. "already-exists" or
  // "invalid-argument".
  Future<String?> add({
    required String name,
    required String email,
    required String password,
    required bool admin,
  }) async {
    final String uid;
    try {
      uid = await staffAuth.createAccount(email, password);
    } on FirebaseAuthException catch (e) {
      debugPrint('Creating staff account failed: ${e.code}');
      return switch (e.code) {
        'email-already-in-use' => 'already-exists',
        'invalid-email' || 'weak-password' => 'invalid-argument',
        _ => 'unknown',
      };
    } catch (e) {
      debugPrint('Creating staff account failed: $e');
      return 'unknown';
    }
    return _write(
        uid,
        () => _db.doc(uid).set({
              'name': name,
              'email': StaffAuth.cleanEmail(email),
              'role': admin ? 'admin' : 'staff',
              'createdAt': FieldValue.serverTimestamp(),
            }));
  }

  // Saves a new name and role. The sign-in email cannot be changed from the
  // website (only in the Firebase console). Returns null or the error code.
  Future<String?> edit(StaffAccount account,
          {required String name, required bool admin}) =>
      _write(
          account.uid,
          () => _db
              .doc(account.uid)
              .update({'name': name, 'role': admin ? 'admin' : 'staff'}));

  // Emails a link to choose a new password. Returns null or the error code.
  Future<String?> sendPasswordReset(StaffAccount account) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: account.email);
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Password reset for ${account.uid} failed: ${e.code}');
      return e.code;
    }
  }

  // Removes the account from the staff list, so it can no longer sign in.
  // (The sign-in account itself stays in Firebase Authentication, where it
  // can be deleted by hand.) Returns null or the error code.
  Future<String?> delete(StaffAccount account) =>
      _write(account.uid, () => _db.doc(account.uid).delete());

  Future<String?> _write(String uid, Future<void> Function() action) async {
    try {
      await action();
      return null;
    } on FirebaseException catch (e) {
      debugPrint('Saving staff account $uid failed: ${e.code}');
      return e.code;
    } catch (e) {
      debugPrint('Saving staff account $uid failed: $e');
      return 'unknown';
    }
  }

  static StaffAccount _fromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return StaffAccount(
      uid: doc.id,
      name: d['name'] as String? ?? '',
      email: d['email'] as String? ?? '',
      admin: d['role'] != 'staff',
    );
  }

  @override
  void dispose() {
    staffAuth.removeListener(_listen);
    _sub?.cancel();
    super.dispose();
  }
}

// The one staff account store for the whole app.
final accountStore = AccountStore();
