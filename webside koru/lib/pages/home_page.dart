import 'dart:async';
import 'dart:math';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../data/bookings.dart';
import '../data/feedback.dart';
import '../lang.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/site_layout.dart';
import 'booking_page.dart';

// Homepage: hero + booking bar, transport services, patient comments,
// branch finder and our drivers.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // One key per homepage part the menu can scroll to.
  final _anchors = {
    'directions': GlobalKey(),
    'drivers': GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    // If another page sent us here with a part name (e.g. "drivers"),
    // scroll to it once the page is drawn.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final anchor = ModalRoute.of(context)?.settings.arguments;
      if (anchor is String) _scrollTo(anchor);
    });
  }

  // Smoothly scrolls the page to the named part.
  void _scrollTo(String anchor) {
    final ctx = _anchors[anchor]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return SiteScaffold(
      onAnchor: _scrollTo,
      children: [
        const _Hero(),
        const _Services(),
        const _PatientComments(),
        _BranchFinder(key: _anchors['directions']),
        _Drivers(key: _anchors['drivers']),
      ],
    );
  }
}

// Top part: badge, big headline, short text, large photo and the
// floating booking bar under the photo.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobile(context);
    final tablet = Responsive.isTablet(context);

    // Headline in 3 parts; the middle part is blue.
    final headline = switch (context.lang) {
      Lang.tr => ('Randevunuza\n', 'huzurlu', ' bir yolculuk.'),
      Lang.en => ('A calm ride\nto your ', 'appointment', '.'),
      Lang.fr => ('Un trajet serein\njusqu\'à votre ', 'rendez-vous', '.'),
      Lang.ar => ('رحلة ', 'هادئة', '\nإلى موعدك.'),
      Lang.ru => ('Спокойная поездка\nна ваш ', 'приём', '.'),
    };

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Light blue badge with a green "available" dot.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.blueSoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: AppColors.success, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                  context.t('Coordinators available 24/7',
                      'Koordinatörler 7/24 hizmetinizde'),
                  style: TextStyle(
                      color: AppColors.blueDark, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text.rich(
          TextSpan(children: [
            TextSpan(text: headline.$1),
            TextSpan(
                text: headline.$2, style: TextStyle(color: AppColors.blue)),
            TextSpan(text: headline.$3),
          ]),
          style: TextStyle(
            fontSize: mobile ? 40 : 60,
            fontWeight: FontWeight.w800,
            letterSpacing: mobile ? -1 : -1.8,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 22),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            context.t(
                'Ambulance transfers, Koru Hotel rides and airport pickups '
                    'for Koru Hospital patients and visitors.',
                'Koru Hastanesi hastaları ve ziyaretçileri için ambulans '
                    'transferi, Koru Otel ulaşımı ve havalimanı karşılama.'),
            style: const TextStyle(
                fontSize: 19, height: 1.6, color: AppColors.muted),
          ),
        ),
      ],
    );

    final photo = _HeroPhoto(height: mobile ? 360 : 520);

    return SectionContainer(
      top: 32,
      bottom: 24,
      child: Column(
        children: [
          // Small screens: text above photo. Wide screens: side by side.
          if (tablet) ...[
            text,
            const SizedBox(height: 28),
            photo,
          ] else
            Row(
              children: [
                Expanded(child: text),
                const SizedBox(width: 40),
                Expanded(child: photo),
              ],
            ),
          // The booking bar sits just below the photo.
          Transform.translate(
            offset: Offset(0, tablet ? 20 : 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: _BookingBar(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Large hero photo that fades to a random branch photo every few seconds.
class _HeroPhoto extends StatefulWidget {
  const _HeroPhoto({required this.height});

  final double height;

  @override
  State<_HeroPhoto> createState() => _HeroPhotoState();
}

class _HeroPhotoState extends State<_HeroPhoto> {
  static final _photos = branchPhotos.values.toList();
  final _random = Random();
  late int _index = _random.nextInt(_photos.length);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_photos.length < 2) return;
      // Pick a different photo than the one showing now.
      var next = _random.nextInt(_photos.length - 1);
      if (next >= _index) next++;
      setState(() => _index = next);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 800),
          // The whole photo is shown (not cropped); a blurred copy of it
          // fills the space around it.
          child: Stack(
            key: ValueKey(_index),
            fit: StackFit.expand,
            children: [
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Image.asset(_photos[_index], fit: BoxFit.cover),
              ),
              Image.asset(_photos[_index], fit: BoxFit.contain),
            ],
          ),
        ),
      ),
    );
  }
}

// Quick booking bar: service, from, to, date and "Book ride".
// The button opens the booking page with these answers already filled in.
class _BookingBar extends StatefulWidget {
  const _BookingBar();

  @override
  State<_BookingBar> createState() => _BookingBarState();
}

class _BookingBarState extends State<_BookingBar> {
  TransportType _type = TransportType.ambulance;
  final _from = TextEditingController();
  String _branch = branches.first;
  DateTime? _date;

  @override
  void dispose() {
    _from.dispose();
    super.dispose();
  }

  // Opens the calendar to choose the date.
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  // Opens the booking page with the bar's answers.
  void _book() {
    Navigator.pushNamed(context, '/booking',
        arguments: BookingDraft(
            type: _type, from: _from.text, branch: _branch, date: _date));
  }

  @override
  Widget build(BuildContext context) {
    final fields = [
      FieldLabel(
        context.t('Service', 'Hizmet'),
        child: DropdownButtonFormField<TransportType>(
          initialValue: _type,
          isExpanded: true,
          items: [
            for (final type in TransportType.values)
              DropdownMenuItem(value: type, child: Text(type.label(context))),
          ],
          onChanged: (v) => setState(() => _type = v!),
        ),
      ),
      FieldLabel(
        context.t('From', 'Nereden'),
        child: TextField(
          controller: _from,
          decoration: InputDecoration(
              hintText: context.t('Pickup address', 'Alınış adresi')),
        ),
      ),
      FieldLabel(
        context.t('To', 'Nereye'),
        child: DropdownButtonFormField<String>(
          initialValue: _branch,
          isExpanded: true,
          items: [
            for (final b in destinations)
              DropdownMenuItem(value: b, child: Text(b)),
          ],
          onChanged: (v) => setState(() => _branch = v!),
        ),
      ),
      FieldLabel(
        context.t('Date', 'Tarih'),
        child: PickerField(
          value: _date == null ? null : formatDate(_date!),
          hint: context.t('Select', 'Seçin'),
          icon: Icons.calendar_today_outlined,
          onTap: _pickDate,
        ),
      ),
    ];

    final button = FilledButton(
      onPressed: _book,
      style: FilledButton.styleFrom(minimumSize: const Size(140, 54)),
      child: Text(context.t('Book ride', 'Araç ayırt')),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A101828), blurRadius: 40, offset: Offset(0, 20)),
        ],
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        // Narrow: fields stacked. Wide: all in one row.
        if (constraints.maxWidth < 800) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final f in fields) ...[f, const SizedBox(height: 12)],
              button,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(flex: 4, child: fields[0]),
            const SizedBox(width: 12),
            Expanded(flex: 5, child: fields[1]),
            const SizedBox(width: 12),
            Expanded(flex: 3, child: fields[2]),
            const SizedBox(width: 12),
            Expanded(flex: 3, child: fields[3]),
            const SizedBox(width: 12),
            button,
          ],
        );
      }),
    );
  }
}

// Our transport services: one detailed card per service (what it covers,
// what is included and a button to book it), then the extras that can be
// added to any ride.
class _Services extends StatelessWidget {
  const _Services();

  @override
  Widget build(BuildContext context) {
    // The same transport types as on the booking page.
    final services = [
      _Service(
        type: TransportType.wheelchair,
        route: context.t('$hotelName ⇄ Hospital', 'Koru Otel ⇄ Hastane'),
        body: context.t(
            'Rides between Koru Hotel and the hospital for every check-up, '
                'test, surgery and follow-up visit during your treatment.',
            'Tedaviniz boyunca her kontrol, tetkik, ameliyat ve takip '
                'randevusu için Koru Otel ile hastane arasında ulaşım.'),
        included: [
          context.t('Planned around your appointment times',
              'Randevu saatlerinize göre planlanır'),
          context.t('Driver waits and takes you back',
              'Şoför bekler ve sizi geri götürür'),
          context.t('A family member can ride with you',
              'Bir yakınınız sizinle gelebilir'),
        ],
      ),
      _Service(
        type: TransportType.standard,
        route: context.t('Your address ⇄ Hospital', 'Adresiniz ⇄ Hastane'),
        body: context.t(
            'A comfortable car from your home or any address to the hospital, '
                'for patients who can walk on their own.',
            'Kendi başına yürüyebilen hastalar için evinizden veya '
                'istediğiniz adresten hastaneye konforlu araç.'),
        included: [
          context.t('Pickup from any address', 'Her adresten alınış'),
          context.t('Driver waits and takes you back',
              'Şoför bekler ve sizi geri götürür'),
          context.t('A family member can ride with you',
              'Bir yakınınız sizinle gelebilir'),
        ],
      ),
      _Service(
        type: TransportType.airport,
        route: context.t(
            'Airport → Hospital or hotel', 'Havalimanı → Hastane veya otel'),
        body: context.t(
            'We meet you at arrivals and take you to the hospital or your '
                'hotel.',
            'Sizi gelen yolcu çıkışında karşılar, hastaneye veya otelinize '
                'götürürüz.'),
        included: [
          context.t('Driver waiting with your name sign',
              'İsminizle tabela tutan şoför'),
          context.t('Flight tracking: on time even if your flight is late',
              'Uçuş takibi: uçağınız gecikse bile zamanında'),
          context.t('Help with your luggage', 'Bagaj yardımı'),
        ],
      ),
      _Service(
        type: TransportType.toAirport,
        route: context.t(
            'Hospital → $airportName', 'Hastane → Esenboğa Havalimanı (ESB)'),
        body: context.t(
            'We pick you up at the hospital and take you to the airport in '
                'good time for your flight.',
            'Sizi hastaneden alır, uçuşunuza zamanında yetişmeniz için '
                'havalimanına götürürüz.'),
        included: [
          context.t(
              'Pickup timed to your flight', 'Uçuşunuza göre planlanan alınış'),
          context.t('Help with your luggage', 'Bagaj yardımı'),
          context.t('Drop-off at the departures door',
              'Giden yolcu kapısına bırakış'),
        ],
      ),
    ];

    // Extras that can be added to any ride.
    final extras = [
      (Icons.translate, context.t('Interpreter', 'Tercüman')),
      (Icons.star_outline, context.t('VIP car', 'VIP araç')),
      (
        Icons.medical_services_outlined,
        context.t('Nurse escort', 'Hemşire eşliği')
      ),
      (Icons.air, context.t('Oxygen on board', 'Araçta oksijen')),
      (Icons.people_outline, context.t('Companion seat', 'Refakatçi koltuğu')),
      (Icons.child_friendly_outlined, context.t('Child seat', 'Çocuk koltuğu')),
    ];

    return SectionContainer(
      top: 64,
      child: Column(
        children: [
          SectionHeading(
              context.t('Our transport services', 'Ulaşım hizmetlerimiz'),
              subtitle: context.t(
                  'Airport, hotel and hospital: we take care of every ride '
                      'during your treatment.',
                  'Havalimanı, otel ve hastane: tedaviniz boyunca her '
                      'yolculuğunuzla biz ilgileniriz.'),
              center: true),
          const SizedBox(height: 32),
          ResponsiveGrid(
            desktopColumns: 2,
            children: [for (final s in services) _ServiceCard(s)],
          ),
          const SizedBox(height: 40),
          Text(context.t('Add to any ride', 'Her yolculuğa ekleyin'),
              style:
                  const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final (icon, label) in extras)
                Chip(
                  avatar: Icon(icon, size: 18, color: AppColors.blue),
                  label: Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.border),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// What one service card shows.
class _Service {
  const _Service({
    required this.route,
    required this.body,
    required this.included,
    required this.type,
  });

  // Short line under the title, e.g. "Airport → Hospital or hotel".
  final String route;
  final String body;
  // "What's included" list.
  final List<String> included;
  // Transport type chosen on the booking page when "Book" is tapped (also
  // gives the card its icon and title).
  final TransportType type;
}

// Light blue card: icon, title, route, text, included list and Book button.
class _ServiceCard extends StatelessWidget {
  const _ServiceCard(this.service);

  final _Service service;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 420),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // White circle with the service icon.
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white,
            child: Icon(service.type.icon, color: AppColors.blue, size: 26),
          ),
          const SizedBox(height: 18),
          Text(service.type.label(context),
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(service.route,
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.blue)),
          const SizedBox(height: 12),
          Text(service.body,
              style: const TextStyle(height: 1.6, color: AppColors.muted)),
          const SizedBox(height: 18),
          // What's included, one line each with a green check.
          for (final item in service.included)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle,
                      size: 20, color: AppColors.success),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(item,
                          style: const TextStyle(
                              height: 1.4, fontWeight: FontWeight.w600))),
                ],
              ),
            ),
          const SizedBox(height: 12),
          // Opens the booking page with this service's transport type chosen.
          FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/booking',
                arguments: BookingDraft(type: service.type)),
            icon: const Icon(Icons.arrow_forward),
            label: Text(context.t('Book this service', 'Bu hizmeti ayırtın')),
          ),
        ],
      ),
    );
  }
}

// Patient comments that staff chose to show and a button to leave
// feedback. All approved comments take turns in random order, 3 at a time,
// so every one of them appears. Before any comment is approved, only the
// button shows.
class _PatientComments extends StatefulWidget {
  const _PatientComments();

  @override
  State<_PatientComments> createState() => _PatientCommentsState();
}

class _PatientCommentsState extends State<_PatientComments> {
  static const _perPage = 3;

  // Ids of the approved comments in shuffled order.
  List<String> _order = [];
  // Where the comments shown now start in _order.
  int _start = 0;
  late final Timer _turn;

  @override
  void initState() {
    super.initState();
    feedbackStore.addListener(_sync);
    _sync();
    _turn = Timer.periodic(const Duration(seconds: 8), (_) => _next());
  }

  @override
  void dispose() {
    feedbackStore.removeListener(_sync);
    _turn.cancel();
    super.dispose();
  }

  // Reshuffles when comments are approved, hidden or deleted.
  void _sync() {
    final ids = feedbackStore.published.map((f) => f.id).toList();
    if (ids.length == _order.length && ids.every(_order.contains)) {
      setState(() {}); // Same comments, but one may have been edited.
      return;
    }
    setState(() {
      _order = ids..shuffle();
      _start = 0;
    });
  }

  // Shows the next comments; after the last ones, starts a new shuffle.
  void _next() {
    if (_order.length <= _perPage) return;
    setState(() {
      _start += _perPage;
      if (_start >= _order.length) {
        _order.shuffle();
        _start = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final byId = {for (final f in feedbackStore.published) f.id: f};
    // Fills up from the start of the list when the last page is short.
    final comments = [
      for (var i = 0; i < _order.length && i < _perPage; i++)
        byId[_order[(_start + i) % _order.length]]!,
    ];
    final button = OutlinedButton.icon(
      onPressed: () => Navigator.pushNamed(context, '/feedback'),
      icon: const Icon(Icons.rate_review_outlined, size: 18),
      label: Text(context.t('Leave feedback', 'Yorum bırakın')),
    );
    return SectionContainer(
      top: 24,
      child: Column(
        children: [
          SectionHeading(
              context.t('What patients say', 'Hastalarımız ne diyor'),
              subtitle: comments.isEmpty
                  ? context.t('Did you ride with us? Tell us how it went.',
                      'Bizimle yolculuk ettiniz mi? Nasıl geçtiğini anlatın.')
                  : null,
              size: 36,
              center: true),
          const SizedBox(height: 24),
          if (comments.isNotEmpty) ...[
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: ResponsiveGrid(
                key: ValueKey(comments.map((f) => f.id).join()),
                children: [
                  for (final f in comments)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stars(f.rating),
                          const SizedBox(height: 12),
                          Text('“${f.comment}”',
                              style:
                                  const TextStyle(fontSize: 16, height: 1.6)),
                          const SizedBox(height: 12),
                          // First name only, to protect the patient.
                          Text(
                              '${f.name.isEmpty ? context.t('A patient', 'Bir hasta') : f.name.split(' ').first}'
                              ' · ${f.type.label(context)}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.muted)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          button,
        ],
      ),
    );
  }
}

// "Find your branch": choose a branch, see its address, transit and
// parking, and open directions. Map placeholder on the right.
class _BranchFinder extends StatefulWidget {
  const _BranchFinder({super.key});

  @override
  State<_BranchFinder> createState() => _BranchFinderState();
}

class _BranchFinderState extends State<_BranchFinder> {
  String _branch = branches.first;

  @override
  Widget build(BuildContext context) {
    // One "label: value" line.
    Widget info(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                TextSpan(text: value),
              ]),
              style: const TextStyle(fontSize: 15, height: 1.5)),
        );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(context.t('Find your branch', 'Şubenizi bulun'),
            size: 32),
        const SizedBox(height: 20),
        FieldLabel(
          context.t('Branch', 'Şube'),
          child: DropdownButtonFormField<String>(
            initialValue: _branch,
            items: [
              for (final b in branches)
                DropdownMenuItem(value: b, child: Text(b)),
            ],
            onChanged: (v) => setState(() => _branch = v!),
          ),
        ),
        const SizedBox(height: 18),
        // Replace the placeholders with each branch's real details.
        info(context.t('Address', 'Adres'), '[ADDRESS – $_branch]'),
        info(context.t('Transit', 'Toplu taşıma'),
            context.t('[Metro / bus lines]', '[Metro / otobüs hatları]')),
        info(context.t('Parking', 'Otopark'),
            context.t('[Car park details]', '[Otopark bilgisi]')),
        const SizedBox(height: 8),
        // Opens Google Maps with a search for the branch.
        FilledButton.icon(
          onPressed: () => openLink(
              'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('Koru Hastanesi $_branch')}'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.text),
          icon: const Icon(Icons.directions, size: 18),
          label: Text(context.t('Get directions', 'Yol tarifi al')),
        ),
      ],
    );

    // Photo of the chosen branch, or a placeholder if it has none yet.
    final photoPath = branchPhotos[_branch];
    final map = photoPath == null
        ? const PlaceholderBox('[MAP EMBED]', height: 340)
        // The whole photo is shown (not cropped), centred in the box.
        : SizedBox(
            height: 440,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(photoPath, fit: BoxFit.contain),
              ),
            ),
          );

    return SectionContainer(
      child: Container(
        padding: EdgeInsets.all(Responsive.isMobile(context) ? 20 : 40),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Responsive.isTablet(context)
            ? Column(children: [details, const SizedBox(height: 24), map])
            : Row(
                children: [
                  Expanded(flex: 2, child: details),
                  const SizedBox(width: 32),
                  Expanded(flex: 3, child: map),
                ],
              ),
      ),
    );
  }
}

// One Koru Hospital driver shown in "Our drivers".
class _Driver {
  const _Driver({
    required this.name,
    required this.role,
    required this.since,
    required this.vehicle,
    required this.languages,
    this.photo,
  });

  final String name;
  // Job title under the name (English, Turkish).
  final (String, String) role;
  // Year they started driving for Koru.
  final String since;
  // Vehicle they usually drive.
  final TransportType vehicle;
  final String languages;
  // Photo in assets/images (null = a person icon instead).
  final String? photo;
}

// "Our drivers": a card for each Koru Hospital driver with photo, name,
// years with Koru, vehicle and languages.
class _Drivers extends StatelessWidget {
  const _Drivers({super.key});

  // TODO: replace the placeholders with the real drivers (with their
  // permission).
  static const _drivers = [
    _Driver(
        name: 'Mustafa Sevinbi',
        role: ('Medical Transport Driver', 'Tıbbi Nakil Sürücüsü'),
        since: '[YEAR]',
        vehicle: TransportType.ambulance,
        languages: '[TR, EN]',
        photo: 'assets/images/driver_01.jpg'),
    _Driver(
        name: 'Anil Yilmaz',
        role: ('Hotel Transfer Driver', 'Otel Transfer Sürücüsü'),
        since: '[YEAR]',
        vehicle: TransportType.wheelchair,
        languages: '[TR, EN]',
        photo: 'assets/images/driver_02.jpg'),
    _Driver(
        name: 'Emrullah Barug',
        role: ('Airport Transfer Driver', 'Havalimanı Transfer Sürücüsü'),
        since: '[YEAR]',
        vehicle: TransportType.airport,
        languages: '[TR, EN]',
        photo: 'assets/images/driver_03.jpg'),
    _Driver(
        name: 'Erhan Kayadasi',
        role: ('Patient Transfer Driver', 'Hasta Transfer Sürücüsü'),
        since: '[YEAR]',
        vehicle: TransportType.standard,
        languages: '[TR, EN]',
        photo: 'assets/images/driver_04_web.jpg'),
  ];

  @override
  Widget build(BuildContext context) {
    // Grey icon + text line on a driver card.
    Widget detail(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.blue),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(text,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.muted))),
            ],
          ),
        );

    return SectionContainer(
      bottom: 80,
      child: Column(
        children: [
          SectionHeading(context.t('Our drivers', 'Sürücülerimiz'),
              subtitle: context.t(
                  'Koru Hospital\'s own drivers, trained to help patients '
                      'safely in and out of the vehicle.',
                  'Hastaların araca güvenle binip inmesine yardım etmek için '
                      'eğitilmiş Koru Hastanesi sürücüleri.'),
              center: true),
          const SizedBox(height: 32),
          ResponsiveGrid(
            desktopColumns: 4,
            children: [
              for (final d in _drivers)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Square photo cropped to head and shoulders.
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: d.photo == null
                              ? Container(
                                  color: AppColors.blueSoft,
                                  child: Icon(Icons.person_outline,
                                      size: 64, color: AppColors.blue),
                                )
                              : Image.asset(d.photo!,
                                  fit: BoxFit.cover,
                                  alignment: const Alignment(0, -0.5)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(d.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(context.t(d.role.$1, d.role.$2),
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.blue)),
                      const SizedBox(height: 6),
                      detail(
                          Icons.badge_outlined,
                          context.t('With Koru since ${d.since}',
                              '${d.since} yılından beri Koru\'da')),
                      detail(d.vehicle.icon, d.vehicle.label(context)),
                      detail(Icons.translate, d.languages),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
