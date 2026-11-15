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
  // Redraws every minute so the "in 25 min" countdowns stay right.
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(
        const Duration(minutes: 1), (_) => mounted ? setState(() {}) : null);
    bookingStore.addListener(_syncLocation);
    // After the first frame, because it may update the screen.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncLocation());
  }

  @override
  void dispose() {
    bookingStore.removeListener(_syncLocation);
    _positions?.cancel();
    _tick?.cancel();
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
          content: Text(context.t('Has the patient arrived at ${b.end}?',
              'Hasta ${b.end} noktasına ulaştı mı?')),
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
      body: ListenableBuilder(
        listenable: bookingStore,
        builder: (context, _) {
          final all = bookingStore.bookings;
          final active = all
              .where((b) => b.trip != TripStatus.completed)
              .toList()
            ..sort((a, b) => _when(a).compareTo(_when(b)));
          final done = all.where((b) => b.trip == TripStatus.completed).toList()
            ..sort((a, b) => _when(b).compareTo(_when(a)));
          final mobile = Responsive.isMobile(context);

          // Active trips grouped by day: today, tomorrow, later (and any
          // from earlier days that were never finished, first).
          final today = _day(DateTime.now());
          final groups = <String, List<Booking>>{};
          for (final b in active) {
            final d = _day(b.date);
            final key = d.isBefore(today)
                ? context.t('Not finished yet', 'Henüz bitmedi')
                : d == today
                    ? context.t('Today', 'Bugün')
                    : d == today.add(const Duration(days: 1))
                        ? context.t('Tomorrow', 'Yarın')
                        : context.t('Later', 'Daha sonra');
            groups.putIfAbsent(key, () => []).add(b);
          }
          final next = active.isEmpty ? null : active.first;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _header(all, active, done)),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          mobile ? 16 : 32, 20, mobile ? 16 : 32, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _locationBanner(),
                          if (active.isEmpty) _empty(),
                          for (final entry in groups.entries) ...[
                            _groupTitle(entry.key, entry.value.length),
                            for (final b in entry.value)
                              _tripCard(b, isNext: b == next),
                          ],
                          if (done.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _groupTitle(context.t('Completed', 'Tamamlanan'),
                                done.length),
                            for (final b in done.take(20)) _doneRow(b),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  // When a trip starts.
  static DateTime _when(Booking b) => DateTime(
      b.date.year, b.date.month, b.date.day, b.time.hour, b.time.minute);

  // "in 2 h 15 min" / "now" / "10 min late" for a trip that has not started.
  String _countdown(Booking b) {
    final diff = _when(b).difference(DateTime.now());
    final mins = diff.inMinutes;
    String span(int m) {
      final d = m ~/ (60 * 24), h = (m % (60 * 24)) ~/ 60, min = m % 60;
      if (d > 0) return context.t('$d d $h h', '$d g $h sa');
      if (h > 0) return context.t('$h h $min min', '$h sa $min dk');
      return context.t('$min min', '$min dk');
    }

    if (mins.abs() <= 5) return context.t('Now', 'Şimdi');
    return mins > 0
        ? context.t('in ${span(mins)}', '${span(mins)} sonra')
        : context.t('${span(-mins)} late', '${span(-mins)} gecikme');
  }

  // Good morning / afternoon / evening.
  String _greeting() {
    final h = DateTime.now().hour;
    return h < 12
        ? context.t('Good morning', 'Günaydın')
        : h < 18
            ? context.t('Good afternoon', 'İyi günler')
            : context.t('Good evening', 'İyi akşamlar');
  }

  // Coloured top: logo, language and sign-out, greeting and the counters.
  Widget _header(List<Booking> all, List<Booking> active, List<Booking> done) {
    final mobile = Responsive.isMobile(context);
    final now = DateTime.now();
    final today = _day(now);
    final name = staffAuth.driverName.trim();
    final initials = name.isEmpty
        ? '?'
        : name
            .split(RegExp(r'\s+'))
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join();
    final todayCount = all.where((b) => _day(b.date) == today).length;
    final driving = active.where((b) => b.trip?.sharesLocation ?? false).length;
    final doneToday = done.where((b) => _day(b.date) == today).length;
    final peopleMonth = done
        .where((b) => b.date.year == now.year && b.date.month == now.month)
        .fold<int>(0, (sum, b) => sum + b.passengers);

    Widget stat(IconData icon, String value, String label) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1.1)),
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.blueDark, AppColors.blue],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  mobile ? 16 : 32, 12, mobile ? 8 : 24, mobile ? 20 : 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Logo(light: true),
                      const Spacer(),
                      IconButton(
                        tooltip: context.lang.nativeName,
                        color: Colors.white,
                        icon: const Icon(Icons.translate),
                        onPressed: () => showLanguageDialog(context),
                      ),
                      IconButton(
                        tooltip: context.t('Sign out', 'Çıkış yap'),
                        color: Colors.white,
                        icon: const Icon(Icons.logout),
                        onPressed: () async {
                          await staffAuth.signOut();
                          if (!mounted) return;
                          Navigator.of(context)
                              .pushNamedAndRemoveUntil('/', (_) => false);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: mobile ? 26 : 32,
                        backgroundColor: Colors.white,
                        child: Text(initials,
                            style: TextStyle(
                                color: AppColors.blueDark,
                                fontWeight: FontWeight.w900,
                                fontSize: mobile ? 18 : 22)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${_greeting()}${name.isEmpty ? '' : ', $name'}',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: mobile ? 22 : 28,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(
                                '${formatDate(now)}  ·  ${context.t('Your trips, updated live', 'Yolculuklarınız, canlı güncellenir')}',
                                style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.85))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Counters: 2 per row on phones, 4 on wider screens.
                  Padding(
                    padding: EdgeInsets.only(right: mobile ? 8 : 8),
                    child: LayoutBuilder(builder: (context, c) {
                      final perRow = mobile ? 2 : 4;
                      const gap = 10.0;
                      final w = (c.maxWidth - gap * (perRow - 1)) / perRow;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final box in [
                            stat(Icons.today, '$todayCount',
                                context.t('Trips today', 'Bugünkü yolculuk')),
                            stat(Icons.directions_car, '$driving',
                                context.t('Driving now', 'Şu an yolda')),
                            stat(Icons.check_circle_outline, '$doneToday',
                                context.t('Done today', 'Bugün biten')),
                            stat(
                                Icons.groups_outlined,
                                '$peopleMonth',
                                context.t(
                                    'People this month', 'Bu ay taşınan')),
                          ])
                            SizedBox(width: w, child: box),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _groupTitle(String title, int count) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        child: Row(
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
              decoration: BoxDecoration(
                  color: AppColors.blueSoft,
                  borderRadius: BorderRadius.circular(20)),
              child: Text('$count',
                  style: TextStyle(
                      color: AppColors.blueDark, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );

  // No trips: a friendly message instead of an empty page.
  Widget _empty() => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.blueSoft,
              child: Icon(Icons.local_cafe_outlined,
                  size: 40, color: AppColors.blue),
            ),
            const SizedBox(height: 16),
            Text(context.t('No trips right now', 'Şu anda yolculuk yok'),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
                context.t(
                    'New trips appear here by themselves as soon as the office '
                        'assigns them to you.',
                    'Ofis size yolculuk atadığında burada kendiliğinden '
                        'görünür.'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, height: 1.5)),
          ],
        ),
      );

  // Tells the driver whether their location is reaching the patient.
  Widget _locationBanner() {
    final (color, fg, icon, text) = switch (_location) {
      _LocationState.off => (null, null, null, null),
      _LocationState.asking => (
          AppColors.blueSoft,
          AppColors.blueDark,
          Icons.my_location,
          context.t(
              'Allow location in your browser so the patient can see '
                  'you coming.',
              'Hastanın sizi görebilmesi için tarayıcıda konuma izin verin.')
        ),
      _LocationState.sharing => (
          AppColors.success.withValues(alpha: 0.1),
          AppColors.success,
          Icons.share_location,
          context.t('Your location is shared with the patient while you drive.',
              'Sürüş sırasında konumunuz hastayla paylaşılıyor.')
        ),
      _LocationState.denied => (
          AppColors.emergencyBg,
          AppColors.emergencyText,
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
          Icon(icon, color: fg),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  // Colour of each trip step (and of the button that leads to it).
  static Color _stepColor(TripStatus s) => switch (s) {
        TripStatus.assigned => AppColors.muted,
        TripStatus.enRoute => AppColors.blue,
        TripStatus.arrived => AppColors.gold,
        TripStatus.onBoard => const Color(0xFF7A5AF8),
        TripStatus.completed => AppColors.success,
      };

  // One trip: time, route, patient, progress, map and the next-step button.
  Widget _tripCard(Booking b, {required bool isNext}) {
    final trip = b.trip ?? TripStatus.assigned;
    final mobile = Responsive.isMobile(context);
    final color = _stepColor(trip);

    // Before the patient is on board, navigation goes to the pickup;
    // after, to the destination.
    final toEnd = trip == TripStatus.onBoard;
    final target = toEnd ? b.endPoint : b.startPoint;
    final navigateTo = target != null
        ? '${target.latitude},${target.longitude}'
        : Uri.encodeComponent(toEnd ? b.end : b.start);

    // Turkish numbers like 0536... become 90536... for WhatsApp.
    var digits = b.phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0')) digits = '90${digits.substring(1)}';

    Widget chip(IconData icon, String text, {Color? bg, Color? fg}) =>
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg ?? AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 16, color: fg ?? AppColors.muted),
            const SizedBox(width: 6),
            Text(text,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: fg ?? AppColors.text)),
          ]),
        );

    // One end of the route: dot, label and place.
    Widget stop(IconData icon, Color c, String label, String place) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: c.withValues(alpha: 0.12),
              child: Icon(icon, size: 18, color: c),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 12)),
                  Text(place,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                ],
              ),
            ),
          ],
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isNext ? color : AppColors.border, width: isNext ? 2 : 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isNext ? 0.08 : 0.03),
              blurRadius: 18,
              offset: const Offset(0, 6)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top band: big start time, countdown, reference and step.
          Container(
            padding: EdgeInsets.fromLTRB(mobile ? 16 : 22, 14, 14, 14),
            color: color.withValues(alpha: 0.08),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formatTime(b.time),
                        style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: color == AppColors.muted
                                ? AppColors.text
                                : color,
                            height: 1)),
                    const SizedBox(height: 4),
                    Text(
                        trip == TripStatus.assigned
                            ? '${formatDate(b.date)}  ·  ${_countdown(b)}'
                            : formatDate(b.date),
                        style: const TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isNext)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(context.t('NEXT', 'SIRADAKİ'),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 0.8)),
                      ),
                    Text(b.ref,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(mobile ? 16 : 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _progress(trip, b),
                const SizedBox(height: 18),
                // Route as a small timeline.
                stop(b.startIcon, AppColors.success,
                    context.t('Pickup', 'Alınış'), b.start),
                Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Container(
                      width: 2,
                      height: 18,
                      color: AppColors.border,
                      margin: const EdgeInsets.symmetric(vertical: 4)),
                ),
                stop(b.endIcon, AppColors.blueDark,
                    context.t('Destination', 'Varış'), b.end),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    chip(Icons.person_outline, b.patient),
                    chip(
                        Icons.group_outlined,
                        context.t(
                            '${b.passengers} people', '${b.passengers} kişi')),
                    chip(b.type.icon, b.type.label(context)),
                    for (final n in b.needs)
                      chip(Icons.medical_services_outlined, n.label(context),
                          bg: AppColors.emergencyBg,
                          fg: AppColors.emergencyText),
                  ],
                ),
                if (b.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFE08A)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.sticky_note_2_outlined,
                            size: 20, color: Color(0xFF9A6700)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(b.notes,
                                style: const TextStyle(height: 1.4))),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                RouteMap(
                  destination: b.endPoint,
                  pickup: b.startPoint,
                  destinationIcon: b.endIcon,
                  pickupIcon: b.startIcon,
                  driver: trip.sharesLocation ? _here : null,
                  height: mobile ? 220 : 260,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => openLink('tel:${b.phone}'),
                        icon: const Icon(Icons.call_outlined),
                        label: Text(context.t('Call', 'Ara')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => openLink('https://wa.me/$digits'),
                        icon: const Icon(Icons.chat_outlined),
                        label: const Text('WhatsApp'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => openLink(
                            'https://www.google.com/maps/dir/?api=1&destination=$navigateTo'),
                        icon: const Icon(Icons.navigation_outlined),
                        label: Text(context.t('Navigate', 'Yol tarifi'),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                ),
                if (trip.next != null) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _saving == b.ref ? null : () => _next(b),
                    style: FilledButton.styleFrom(
                      backgroundColor: _stepColor(trip.next!),
                      minimumSize: const Size.fromHeight(58),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: Icon(trip.next!.icon),
                    label: Text(
                        _saving == b.ref
                            ? context.t('Saving...', 'Kaydediliyor...')
                            : trip.action(context),
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // The 5 trip steps as a bar: done steps filled, the current one named.
  Widget _progress(TripStatus trip, Booking b) {
    final steps = TripStatus.values;
    final color = _stepColor(trip);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(trip.icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(trip.label(context, b.type, b.branch),
                style: TextStyle(color: color, fontWeight: FontWeight.w800)),
            const Spacer(),
            Text('${trip.index + 1}/${steps.length}',
                style: const TextStyle(
                    color: AppColors.muted, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: i <= trip.index ? color : AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              if (i < steps.length - 1) const SizedBox(width: 4),
            ],
          ],
        ),
      ],
    );
  }

  // A finished trip: one short line.
  Widget _doneRow(Booking b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.success.withValues(alpha: 0.12),
            child: const Icon(Icons.check, color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.route,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                    '${b.ref}  ·  ${formatDate(b.date)} ${formatTime(b.time)}  ·  ${b.patient}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
