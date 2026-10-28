import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// What happened when a staff member or driver tried to sign in.
enum SignInResult { ok, wrongLogin, notStaff, tooManyTries, offline, failed }

// Who can sign in: coordinators (admin dashboard) and drivers (driver
// dashboard).
enum Role { staff, driver }

// Staff and driver sign-in with Firebase Auth (email + password).
// Signing in is not enough: the account must also be on a list in Firestore.
//   Staff:   a document at staff/{uid} (added by hand in the Firebase console).
//   Drivers: a document at drivers/{uid} with active == true (added by staff
//            in the admin dashboard).
// The Firestore rules check the same lists.
class StaffAuth extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // True when a staff member is signed in on this browser.
  bool isStaff = false;
  // True when a driver is signed in on this browser.
  bool isDriver = false;
  // The signed-in account (null when signed out).
  String? uid;
  // The signed-in driver's name, shown on the driver dashboard.
  String driverName = '';

  // Called once at start-up: Firebase remembers the last sign-in, so a staff
  // member or driver stays signed in after a page refresh.
  Future<void> load() async {
    final user = await _auth.authStateChanges().first;
    if (user == null) return;
    // Both lists are checked at the same time: each check is a trip to the
    // database, and waiting for one before the next slows the first page.
    final (onStaff, onDrivers) =
        await (_onStaffList(user), _onDriverList(user)).wait;
    isStaff = onStaff;
    isDriver = !isStaff && onDrivers;
    if (!isDriver) driverName = '';
    uid = isStaff || isDriver ? user.uid : null;
  }

  // Phone keyboards (especially Turkish ones) may capitalise the first letter
  // or type a dotless ı / dotted İ, which Firebase would see as a different
  // email.
  static String cleanEmail(String email) => email
      .trim()
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .toLowerCase();

  Future<SignInResult> signIn(String email, String password,
      {Role role = Role.staff}) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: cleanEmail(email), password: password);
      final user = cred.user!;
      final allowed = switch (role) {
        Role.staff => await _onStaffList(user),
        Role.driver => await _onDriverList(user),
      };
      if (!allowed) {
        await _auth.signOut();
        return SignInResult.notStaff;
      }
      isStaff = role == Role.staff;
      isDriver = role == Role.driver;
      uid = user.uid;
      notifyListeners();
      return SignInResult.ok;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign-in failed: ${e.code}');
      return switch (e.code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' ||
        'invalid-email' =>
          SignInResult.wrongLogin,
        'too-many-requests' => SignInResult.tooManyTries,
        'network-request-failed' => SignInResult.offline,
        _ => SignInResult.failed,
      };
    } catch (e) {
      debugPrint('Sign-in failed: $e');
      return SignInResult.failed;
    }
  }

  // Emails a link for choosing a new password. Returns false if it could not
  // be sent. For privacy Firebase does not say whether the email has an
  // account, so a wrong email also returns true.
  Future<bool> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: cleanEmail(email));
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Password reset failed: ${e.code}');
      return e.code == 'user-not-found';
    } catch (e) {
      debugPrint('Password reset failed: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    isStaff = false;
    isDriver = false;
    uid = null;
    driverName = '';
    notifyListeners();
  }

  Future<bool> _onStaffList(User user) async {
    try {
      final doc = await _db.collection('staff').doc(user.uid).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Staff check failed: $e');
      return false;
    }
  }

  // Also remembers the driver's name.
  Future<bool> _onDriverList(User user) async {
    try {
      final doc = await _db.collection('drivers').doc(user.uid).get();
      if (doc.data()?['active'] != true) return false;
      driverName = doc.data()?['name'] as String? ?? '';
      return true;
    } catch (e) {
      debugPrint('Driver check failed: $e');
      return false;
    }
  }
}

// The one staff/driver sign-in for the whole app.
final staffAuth = StaffAuth();
