import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../data/bookings.dart';
import '../data/staff_auth.dart';
import '../lang.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/route_map.dart';
import '../widgets/site_layout.dart';
import 'admin_login_page.dart';

// Driver dashboard. A signed-in driver sees only the trips the admin gave
// them (updated live) and moves each one forward with one big button:
// Start trip -> I have arrived -> Patient on board -> Complete trip.
// While driving, the driver's location is shared with the patient's
// tracking page.
class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({super.key});

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

// Whether the browser lets us use the driver's location.
enum _LocationState { off, asking, sharing, denied }

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  StreamSubscription<Position>? _positions;
  _LocationState _location = _LocationState.off;
  // Last known position (shown on the map as the car).
  LatLng? _here;
  // When the location was last sent, so it is sent at most every 15 s.
  DateTime? _lastSent;
  // Booking whose button is being saved.
  String? _saving;

  @override
  void initState() {
    super.initState();
    bookingStore.addListener(_syncLocation);
    // After the first frame, because it may update the screen.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncLocation());
  }

  @override
  void dispose() {
    bookingStore.removeListener(_syncLocation);
    _positions?.cancel();
    super.dispose();
  }

  // Trips where the driver is driving right now.
  List<Booking> get _driving => bookingStore.bookings
      .where((b) => b.trip?.sharesLocation ?? false)
      .toList();

  // Starts sharing the location while a trip is being driven, and stops
  // when none is.
  Future<void> _syncLocation() async {
    if (_driving.isEmpty) {
      await _positions?.cancel();
      _positions = null;
      if (mounted && _location == _LocationState.sharing) {
        setState(() => _location = _LocationState.off);
      }
      return;
    }
    if (!mounted || _positions != null || _location == _LocationState.asking) {
      return;
    }
    setState(() => _location = _LocationState.asking);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _location = _LocationState.denied);
        return;
      }
    } catch (e) {
      debugPrint('Location permission failed: $e');
      if (mounted) setState(() => _location = _LocationState.denied);
      return;
    }
    if (!mounted) return;
    setState(() => _location = _LocationState.sharing);
    _positions = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 20),
    ).listen(
      _onPosition,
      onError: (Object e) {
        debugPrint('Location failed: $e');
        if (mounted) setState(() => _location = _LocationState.denied);
      },
    );
  }

  void _onPosition(Position p) {
    final here = LatLng(p.latitude, p.longitude);
    setState(() => _here = here);
    final now = DateTime.now();
    if (_lastSent != null &&
        now.difference(_lastSent!) < const Duration(seconds: 15)) {
      return;
    }
    _lastSent = now;
    for (final b in _driving) {
      bookingStore.shareLocation(b, here);
    }
  }

  // Moves a trip to its next step. Completing a trip asks first.
  Future<void> _next(Booking b) async {
    if (b.trip == TripStatus.onBoard) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.t('Complete trip', 'Yolculuğu bitir')),
          content: Text(context.t('Has the patient arrived at ${b.branch}?',
              'Hasta ${b.branch} şubesine ulaştı mı?')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.t('Cancel', 'İptal'))),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.t('Complete trip', 'Yolculuğu bitir'))),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _saving = b.ref);
    try {
      await bookingStore.nextTripStep(b);
      // Send the location right away when the driver sets off.
      _lastSent = null;
    } catch (e) {
      debugPrint('Updating trip ${b.ref} failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.t('Could not save. Please try again.',
                'Kaydedilemedi. Lütfen tekrar deneyin.'))));
      }
    }
    if (mounted) setState(() => _saving = null);
  }

  @override
  Widget build(BuildContext context) {
    // Not signed in as a driver: show the driver login instead.
    if (!staffAuth.isDriver) return const AdminLoginPage(role: Role.driver);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.blueDark,
        foregroundColor: Colors.white,
        toolbarHeight: 72,
        // No back arrow: the driver leaves by signing out.
        automaticallyImplyLeading: false,
        title: const Logo(light: true),
        actions: [
          IconButton(
            tooltip: context.lang.nativeName,
            icon: const Icon(Icons.translate),
            onPressed: () => showLanguageDialog(context),
          ),
          IconButton(
            tooltip: context.t('Sign out', 'Çıkış yap'),
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await staffAuth.signOut();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                  context, '/driver/login', (_) => false);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: bookingStore,
        builder: (context, _) {
          final all = bookingStore.bookings;
          final active =
              all.where((b) => b.trip != TripStatus.completed).toList();
          final done =
              all.where((b) => b.trip == TripStatus.completed).toList();
          return SingleChildScrollView(
            padding: EdgeInsets.all(Responsive.isMobile(context) ? 16 : 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        context.t('Hello ${staffAuth.driverName}',
                            'Merhaba ${staffAuth.driverName}'),
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.w800)),
                    Text(
                        context.t('Your trips, updated live.',
                            'Yolculuklarınız, canlı güncellenir.'),
                        style: const TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 20),
                    _locationBanner(),
                    if (active.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                            context.t('No trips assigned to you right now.',
                                'Şu anda size atanmış yolculuk yok.'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.muted)),
                      ),
                    for (final b in active) _tripCard(b),
                    if (done.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(context.t('Completed', 'Tamamlanan'),
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      for (final b in done.reversed) _doneRow(b),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Tells the driver whether their location is reaching the patient.
  Widget _locationBanner() {
    final (color, icon, text) = switch (_location) {
      _LocationState.off => (null, null, null),
      _LocationState.asking => (
          AppColors.blueSoft,
          Icons.my_location,
          context.t(
              'Allow location in your browser so the patient can see '
                  'you coming.',
              'Hastanın sizi görebilmesi için tarayıcıda konuma izin verin.')
        ),
      _LocationState.sharing => (
          AppColors.blueSoft,
          Icons.my_location,
          context.t('Your location is shared with the patient while you drive.',
              'Sürüş sırasında konumunuz hastayla paylaşılıyor.')
        ),
      _LocationState.denied => (
          AppColors.emergencyBg,
          Icons.location_disabled,
          context.t(
              'Location is blocked. The patient still sees each step, but '
                  'not the car on the map.',
              'Konum engelli. Hasta her adımı görür ama aracı haritada '
                  'göremez.')
        ),
    };
    if (text == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(AppRadius.control)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.blueDark),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  // One trip: everything the driver needs, and the button for the next step.
  Widget _tripCard(Booking b) {
    final trip = b.trip ?? TripStatus.assigned;
    // Opens the pickup point (or address) in the phone's map app.
    final navigateTo = b.pickup != null
        ? '${b.pickup!.latitude},${b.pickup!.longitude}'
        : Uri.encodeComponent(b.from);

    Widget row(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: AppColors.blue),
              const SizedBox(width: 10),
              SizedBox(
                width: 100,
                child:
                    Text(label, style: const TextStyle(color: AppColors.muted)),
              ),
              Expanded(
                child: Text(value,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(Responsive.isMobile(context) ? 18 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
            color:
                trip == TripStatus.assigned ? AppColors.border : AppColors.blue,
            width: trip == TripStatus.assigned ? 1 : 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(b.ref,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              Chip(
                avatar: Icon(trip.icon, size: 18, color: AppColors.blue),
                label: Text(trip.label(context)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          row(Icons.schedule, context.t('When', 'Ne zaman'),
              '${formatDate(b.date)}  ${formatTime(b.time)}'),
          row(Icons.person_outline, context.t('Patient', 'Hasta'), b.patient),
          row(b.type.icon, context.t('Transport', 'Ulaşım'),
              b.type.label(context)),
          row(Icons.location_on_outlined, context.t('From', 'Nereden'), b.from),
          row(Icons.local_hospital_outlined, context.t('To', 'Nereye'),
              b.branch),
          if (b.needs.isNotEmpty)
            row(Icons.accessible, context.t('Needs', 'İhtiyaçlar'),
                b.needs.map((n) => n.label(context)).join(', ')),
          if (b.notes.isNotEmpty)
            row(Icons.sticky_note_2_outlined, context.t('Notes', 'Notlar'),
                b.notes),
          const SizedBox(height: 14),
          RouteMap(
            destination: branchLocation(b.branch),
            pickup: b.pickup,
            driver: trip.sharesLocation ? _here : null,
            height: 260,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () => openLink('tel:${b.phone}'),
                icon: const Icon(Icons.call_outlined),
                label: Text(context.t('Call patient', 'Hastayı ara')),
              ),
              OutlinedButton.icon(
                onPressed: () => openLink(
                    'https://www.google.com/maps/dir/?api=1&destination=$navigateTo'),
                icon: const Icon(Icons.navigation_outlined),
                label: Text(context.t('Navigate', 'Yol tarifi')),
              ),
            ],
          ),
          if (trip.next != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving == b.ref ? null : () => _next(b),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56)),
                icon: Icon(trip.next!.icon),
                label: Text(
                    _saving == b.ref
                        ? context.t('Saving...', 'Kaydediliyor...')
                        : trip.action(context),
                    style: const TextStyle(fontSize: 17)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // A finished trip: one short line.
  Widget _doneRow(Booking b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
                '${b.ref}  ·  ${formatDate(b.date)} ${formatTime(b.time)}  ·  '
                '${b.patient}  ·  ${b.from} → ${b.branch}',
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
