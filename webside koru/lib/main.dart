import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/staff_auth.dart';
import 'firebase_options.dart';
import 'lang.dart';
import 'pages/admin_dashboard_page.dart';
import 'pages/admin_login_page.dart';
import 'pages/booking_page.dart';
import 'pages/contact_page.dart';
import 'pages/driver_dashboard_page.dart';
import 'pages/feedback_page.dart';
import 'pages/home_page.dart';
import 'pages/track_page.dart';
import 'theme.dart';

// App entry point: Flutter starts here.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Connect to Firebase (bookings and feedback are saved in Firestore) and,
  // at the same time, read the main color picked last time in this browser.
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    colorController.load(),
  ]);
  // For testing on this computer: use the local Firebase emulators instead
  // of the real database. Run with --dart-define=USE_EMULATORS=true
  if (const bool.fromEnvironment('USE_EMULATORS')) {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  }
  // Keep a staff member or driver signed in after a page refresh.
  await staffAuth.load();
  runApp(const KoruApp());
}

// Root widget: theme, languages and the list of pages (routes).
class KoruApp extends StatefulWidget {
  const KoruApp({super.key});

  @override
  State<KoruApp> createState() => _KoruAppState();
}

class _KoruAppState extends State<KoruApp> {
  @override
  void initState() {
    super.initState();
    colorController.addListener(_recolor);
  }

  @override
  void dispose() {
    colorController.removeListener(_recolor);
    super.dispose();
  }

  // The main color changed: rebuild every widget on screen so they all
  // pick up the new AppColors (open pages and form inputs are kept).
  void _recolor() {
    void rebuild(Element element) {
      element.markNeedsBuild();
      element.visitChildren(rebuild);
    }

    setState(() {});
    (context as Element).visitChildren(rebuild);
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when the language changes, so built-in widgets like the
    // date picker also switch language. Arabic also turns the whole page
    // right-to-left.
    return ValueListenableBuilder<Lang>(
      valueListenable: langController,
      builder: (context, lang, _) => MaterialApp(
        title: 'Koru Hospital Transport',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        locale: Locale(lang.name),
        supportedLocales: [for (final l in Lang.values) Locale(l.name)],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // Makes the current language available to every page and dialog
        // (see context.t in lang.dart).
        builder: (context, child) => LangScope(child: child!),
        // Each page has its own address:
        //   /              homepage
        //   /booking       book transport
        //   /track         patients follow their booking live
        //   /contact       contact
        //   /feedback      patients rate their ride
        //   /admin/login   staff sign-in
        //   /admin         admin dashboard
        //   /driver/login  driver sign-in
        //   /driver        driver dashboard
        initialRoute: '/',
        routes: {
          '/': (_) => const HomePage(),
          '/booking': (_) => const BookingPage(),
          '/track': (_) => const TrackPage(),
          '/contact': (_) => const ContactPage(),
          '/feedback': (_) => const FeedbackPage(),
          '/admin/login': (_) => const AdminLoginPage(),
          '/admin': (_) => const AdminDashboardPage(),
          '/driver/login': (_) => const AdminLoginPage(role: Role.driver),
          '/driver': (_) => const DriverDashboardPage(),
        },
      ),
    );
  }
}
