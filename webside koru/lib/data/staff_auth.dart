import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';

// What happened when a staff member or driver tried to sign in.
enum SignInResult { ok, wrongLogin, notStaff, tooManyTries, offline, failed }

// Who can sign in. Staff only use the main site (book rides, see
// information), admins manage everything in the admin dashboard, drivers use
// the driver dashboard. The tab picked on the sign-in page decides: an admin
// account signed in with the Staff tab is treated as staff.
enum Role { staff, admin, driver }

// Staff and driver sign-in with Firebase Auth (email + password).
// Signing in is not enough: the account must also be on a list in Firestore.
//   Staff:   a document at staff/{uid} (added by hand in the Firebase console).
//            Its optional role field is "staff" or "admin"; without it the
//            account is an admin (accounts made before roles existed).
//   Drivers: a document at drivers/{uid} with active == true (added by staff
//            in the admin dashboard).
// The Firestore rules check the same lists.
class StaffAuth extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // Remember which tab this browser signed in with, so an account that is
  // on both lists keeps the same role after a page refresh: an admin signed
  // in as staff stays staff, and a staff member signed in as a driver stays
  // a driver.
  static const _staffOnlyKey = 'signed_in_as_staff';
  static const _driverKey = 'signed_in_as_driver';

  // True when a staff member is signed in on this browser.
  bool isStaff = false;
  // True when signed in with the Admin tab (admin dashboard allowed).
  bool isAdmin = false;
  // True when a driver is signed in on this browser.
  bool isDriver = false;
  // The signed-in account (null when signed out).
  String? uid;
  // The signed-in driver's name, shown on the driver dashboard.
  String driverName = '';

  // Called once at start-up. A sign-in only lasts while the tab is open: a
  // page refresh keeps it, but opening the site again in a new tab or after
  // closing the browser shows the sign-in page.
  Future<void> load() async {
    if (kIsWeb) {
      try {
        await _auth.setPersistence(Persistence.SESSION);
      } catch (e) {
        debugPrint('Setting sign-in persistence failed: $e');
      }
    }
    final user = await _auth.authStateChanges().first;
    if (user == null) return;
    // Both lists are checked at the same time: each check is a trip to the
    // database, and waiting for one before the next slows the first page.
    final (staffRole, onDrivers, staffOnly, signedInAsDriver) = await (
      _staffRole(user),
      _onDriverList(user),
      _flag(_staffOnlyKey),
      _flag(_driverKey),
    ).wait;
    final asDriver = signedInAsDriver && onDrivers;
    isStaff = !asDriver && staffRole != null;
    isAdmin = isStaff && staffRole == 'admin' && !staffOnly;
    isDriver = asDriver || (!isStaff && onDrivers);
    if (!isDriver) driverName = '';
    uid = isStaff || isDriver ? user.uid : null;
  }

  // Phone keyboards (especially Turkish ones) may capitalise the first letter
  // or type a dotless ı / dotted İ, which Firebase would see as a different
  // email.
  static String cleanEmail(String email) =>
      email.trim().replaceAll('ı', 'i').replaceAll('İ', 'i').toLowerCase();

  Future<SignInResult> signIn(String email, String password,
      {Role role = Role.staff}) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: cleanEmail(email), password: password);
      final user = cred.user!;
      final staffRole = role == Role.driver ? null : await _staffRole(user);
      final allowed = switch (role) {
        Role.staff => staffRole != null,
        Role.admin => staffRole == 'admin',
        Role.driver => await _onDriverList(user),
      };
      if (!allowed) {
        await _auth.signOut();
        return SignInResult.notStaff;
      }
      isStaff = role != Role.driver;
      isAdmin = role == Role.admin;
      await _setFlag(_staffOnlyKey, role == Role.staff);
      await _setFlag(_driverKey, role == Role.driver);
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

  // Makes a new email + password account (for a driver or staff member)
  // without signing the admin out: it signs up through a second copy of
  // Firebase that only lives for this, then signs that copy out again.
  // Returns the new account's uid.
  Future<String> createAccount(String email, String password) async {
    final auth = await (_signUpAuth ??= _openSignUpAuth());
    final cred = await auth.createUserWithEmailAndPassword(
        email: cleanEmail(email), password: password);
    await auth.signOut();
    return cred.user!.uid;
  }

  Future<FirebaseAuth>? _signUpAuth;

  static Future<FirebaseAuth> _openSignUpAuth() async {
    final app = await Firebase.initializeApp(
        name: 'account-sign-up',
        options: DefaultFirebaseOptions.currentPlatform);
    final auth = FirebaseAuth.instanceFor(app: app);
    if (const bool.fromEnvironment('USE_EMULATORS')) {
      await auth.useAuthEmulator('localhost', 9099);
    }
    return auth;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _setFlag(_staffOnlyKey, false);
    await _setFlag(_driverKey, false);
    isStaff = false;
    isAdmin = false;
    isDriver = false;
    uid = null;
    driverName = '';
    notifyListeners();
  }

  Future<bool> _flag(String key) async {
    try {
      return (await SharedPreferences.getInstance()).getBool(key) ?? false;
    } catch (_) {
      // Storage blocked (e.g. private window).
      return false;
    }
  }

  Future<void> _setFlag(String key, bool value) async {
    try {
      (await SharedPreferences.getInstance()).setBool(key, value);
    } catch (_) {}
  }

  // "staff" or "admin", or null when the account is not on the staff list.
  Future<String?> _staffRole(User user) async {
    try {
      final doc = await _db.collection('staff').doc(user.uid).get();
      if (!doc.exists) return null;
      return doc.data()?['role'] == 'staff' ? 'staff' : 'admin';
    } catch (e) {
      debugPrint('Staff check failed: $e');
      return null;
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
