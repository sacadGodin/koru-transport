import 'package:flutter/material.dart';

import '../data/bookings.dart';
import '../data/tracking.dart';
import '../lang.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/route_map.dart';
import '../widgets/site_layout.dart';

// "Track my ride" page.
// The patient types their booking reference and the secret tracking code
// they got after booking. The page then shows the booking's progress live:
// confirmed, driver assigned, driver on the way (with the car on the map),
// and so on. This browser remembers the booking, so a refresh keeps it open.
class TrackPage extends StatefulWidget {
  const TrackPage({super.key});

  @override
  State<TrackPage> createState() => _TrackPageState();
}

class _TrackPageState extends State<TrackPage> {
  final _formKey = GlobalKey<FormState>();
  final _ref = TextEditingController();
  final _code = TextEditingController();

  // Tracking link of the booking being shown (null = show the form).
  String? _token;
  // true until we know whether this browser remembers a booking.
  bool _loading = true;
  // true while the code is being checked.
  bool _busy = false;
  // Shown under the form when the lookup fails.
  String? _error;

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Coming from the booking page: the tracking link is passed along.
    // Otherwise use the one this browser remembers, if any.
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is String) {
      _token = arg;
      _loading = false;
    } else {
      tracking.saved().then((token) {
        if (!mounted) return;
        setState(() {
          _token = token;
          _loading = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _ref.dispose();
    _code.dispose();
    super.dispose();
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty)
      ? context.t('Required', 'Zorunlu alan')
      : null;

  Future<void> _lookup() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final (result, token) = await tracking.lookup(_ref.text, _code.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _token = token;
      _error = switch (result) {
        LookupResult.ok => null,
        LookupResult.notFound => context.t(
            'The reference or tracking code is not correct.',
            'Referans veya takip kodu hatalı.'),
        LookupResult.failed => context.t(
            'Could not check your booking. Please try again.',
            'Rezervasyonunuz kontrol edilemedi. Lütfen tekrar deneyin.'),
      };
    });
  }

  // Back to the form to look up another booking.
  Future<void> _close() async {
    await tracking.forget();
    if (!mounted) return;
    setState(() {
      _token = null;
      _code.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SiteScaffold(
      current: NavItem.track,
      children: [
        SectionContainer(
          top: 40,
          bottom: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeading(context.t('Track my ride', 'Yolculuğumu takip et'),
                  subtitle: context.t('See your booking and your driver live.',
                      'Rezervasyonunuzu ve sürücünüzü canlı görün.')),
              const SizedBox(height: 32),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_token == null)
                _form()
              else
                _TrackingView(token: _token!, onClose: _close),
            ],
          ),
        ),
      ],
    );
  }

  // Reference + tracking code form.
  Widget _form() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Container(
        padding: EdgeInsets.all(Responsive.isMobile(context) ? 20 : 32),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FieldLabel(
                context.t('Booking reference', 'Rezervasyon numarası'),
                child: TextFormField(
                    controller: _ref,
                    validator: _required,
                    decoration: const InputDecoration(hintText: 'KR-1001')),
              ),
              const SizedBox(height: 16),
              FieldLabel(
                context.t('Tracking code', 'Takip kodu'),
                child: TextFormField(
                    controller: _code,
                    validator: _required,
                    textCapitalization: TextCapitalization.characters,
                    onFieldSubmitted: (_) => _lookup(),
                    decoration: const InputDecoration(hintText: 'ABCD2345')),
              ),
              const SizedBox(height: 8),
              Text(
                  context.t('You got the code on screen right after booking.',
                      'Kodu rezervasyondan hemen sonra ekranda gördünüz.'),
                  style: const TextStyle(color: AppColors.muted)),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _lookup,
                child: Text(_busy
                    ? context.t('Checking...', 'Kontrol ediliyor...')
                    : context.t('Show my booking', 'Rezervasyonumu göster')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// One step of the progress list on the tracking page.
typedef _Step = ({String label, IconData icon});

// Live view of one booking: progress steps, details and the map.
class _TrackingView extends StatefulWidget {
  const _TrackingView({required this.token, required this.onClose});

  final String token;
  final VoidCallback onClose;

  @override
  State<_TrackingView> createState() => _TrackingViewState();
}

class _TrackingViewState extends State<_TrackingView> {
  // Opened once, so rebuilds (e.g. a language change) keep the same
  // live connection.
  late final _stream = tracking.watch(widget.token);

  VoidCallback get onClose => widget.onClose;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TrackingInfo?>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return _message(
              context,
              context.t('Could not load your booking. Please try again.',
                  'Rezervasyonunuz yüklenemedi. Lütfen tekrar deneyin.'));
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final info = snap.data;
        // Just booked: the live copy appears a moment later.
        if (info == null) {
          return _message(
              context,
              context.t(
                  'Your booking is being prepared. This page updates '
                      'by itself.',
                  'Rezervasyonunuz hazırlanıyor. Bu sayfa kendiliğinden '
                      'güncellenir.'));
        }

        final tablet = Responsive.isTablet(context);
        final steps = _progress(context, info);
        final side = Column(
          children: [
            _details(context, info),
            const SizedBox(height: 20),
            const EmergencyNotice(),
          ],
        );
        return tablet
            ? Column(children: [steps, const SizedBox(height: 24), side])
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: steps),
                  const SizedBox(width: 32),
                  Expanded(flex: 2, child: side),
                ],
              );
      },
    );
  }

  Widget _message(BuildContext context, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text,
            style: const TextStyle(fontSize: 17, color: AppColors.muted)),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: onClose,
          child: Text(context.t(
              'Look up another booking', 'Başka bir rezervasyon sorgula')),
        ),
      ],
    );
  }

  // All steps of a booking, from request to arrival at the hospital.
  List<_Step> _steps(BuildContext context) => [
        (
          label: context.t('Request received', 'Talep alındı'),
          icon: Icons.inbox_outlined
        ),
        (
          label: context.t('Confirmed', 'Onaylandı'),
          icon: Icons.thumb_up_alt_outlined
        ),
        (
          label: context.t('Reserved', 'Rezerve edildi'),
          icon: Icons.event_available_outlined
        ),
        for (final trip in TripStatus.values)
          (label: trip.label(context), icon: trip.icon),
      ];

  // Index in [_steps] of the step the booking has reached.
  int _current(TrackingInfo info) => info.trip != null
      ? Stage.values.length - 1 + info.trip!.index
      : switch (info.stage) {
          Stage.newRequest => 0,
          Stage.confirmed => 1,
          Stage.reserved => 2,
          // Arranged without a trip status (older bookings).
          Stage.arranged => 3,
          // Shown by [_cancelled] instead.
          Stage.cancelled => 0,
        };

  // Card with the steps: done = blue check, current = big and blue,
  // not yet = grey. Plus the map while the driver is driving.
  Widget _progress(BuildContext context, TrackingInfo info) {
    if (info.stage == Stage.cancelled) return _cancelled(context);
    final steps = _steps(context);
    final current = _current(info);
    return Container(
      padding: EdgeInsets.all(Responsive.isMobile(context) ? 20 : 32),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(steps[current].label,
              style:
                  const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.circle, size: 10, color: AppColors.success),
              const SizedBox(width: 8),
              Text(
                  context.t('Live: updates by itself',
                      'Canlı: kendiliğinden güncellenir'),
                  style: const TextStyle(color: AppColors.muted)),
            ],
          ),
          if (info.driverLocation != null) ...[
            const SizedBox(height: 20),
            RouteMap(
              destination: branchLocation(info.branch),
              driver: info.driverLocation,
            ),
          ],
          const SizedBox(height: 24),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: i < current
                        ? AppColors.blueSoft
                        : i == current
                            ? AppColors.blue
                            : AppColors.surface,
                    child: Icon(i < current ? Icons.check : steps[i].icon,
                        size: 18,
                        color: i < current
                            ? AppColors.blue
                            : i == current
                                ? Colors.white
                                : AppColors.muted),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(steps[i].label,
                        style: TextStyle(
                            fontWeight: i == current
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: i > current
                                ? AppColors.muted
                                : AppColors.text)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Card shown instead of the steps once the booking was cancelled.
  Widget _cancelled(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.isMobile(context) ? 20 : 32),
      decoration: BoxDecoration(
        color: AppColors.emergencyBg,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.event_busy_outlined,
              size: 40, color: AppColors.emergencyText),
          const SizedBox(height: 12),
          Text(context.t('Booking cancelled', 'Rezervasyon iptal edildi'),
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.emergencyText)),
          const SizedBox(height: 8),
          Text(
              context.t(
                  'This ride will not take place. If you still need '
                      'transport, please book a new time or call us.',
                  'Bu yolculuk gerçekleşmeyecek. Hâlâ ulaşıma ihtiyacınız '
                      'varsa lütfen yeni bir saat seçin veya bizi arayın.'),
              style: const TextStyle(height: 1.5)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: () => Navigator.pushNamed(context, '/booking'),
                child: Text(context.t('Book again', 'Yeniden rezervasyon')),
              ),
              OutlinedButton.icon(
                onPressed: () => openLink('tel:${ContactInfo.phone}'),
                icon: const Icon(Icons.call_outlined),
                label: Text(context.t('Call us', 'Bizi arayın')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Light blue panel with the booking details.
  Widget _details(BuildContext context, TrackingInfo info) {
    final rows = [
      (context.t('Reference', 'Referans'), info.ref),
      (context.t('Transport', 'Ulaşım'), info.type.label(context)),
      (context.t('To', 'Nereye'), info.branch),
      (
        context.t('Date & time', 'Tarih ve saat'),
        '${formatDate(info.date)}  ${formatTime(info.time)}'
      ),
      if (info.driver != null) (context.t('Driver', 'Sürücü'), info.driver!),
      if (info.vehicle != null)
        (context.t('Vehicle plate', 'Araç plakası'), info.vehicle!),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.t('Your booking', 'Rezervasyonunuz'),
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(label,
                        style: const TextStyle(color: AppColors.muted)),
                  ),
                  Expanded(
                    child: Text(value,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onClose,
            child: Text(context.t(
                'Look up another booking', 'Başka bir rezervasyon sorgula')),
          ),
        ],
      ),
    );
  }
}
