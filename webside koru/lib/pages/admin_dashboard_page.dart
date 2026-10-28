import 'dart:async';

import 'package:flutter/material.dart';

import '../data/bookings.dart';
import '../data/drivers.dart';
import '../data/feedback.dart';
import '../data/messages.dart';
import '../data/shuttles.dart';
import '../data/staff_auth.dart';
import '../lang.dart';
import '../theme.dart';
import '../widgets/color_picker.dart';
import '../widgets/common.dart';
import '../widgets/site_layout.dart';
import 'admin_login_page.dart';
import 'admin_overview.dart';
import 'admin_schedule.dart';

// Admin dashboard. The admin confirms new requests, books the date, time and
// vehicle type, then assigns the vehicle and driver.
// Each booking moves: New request -> Confirmed -> Reserved -> Arranged.
// After that, the driver moves the trip forward from the driver dashboard
// and the admin sees each step live. Any booking can be rescheduled or
// cancelled (and a cancelled one restored) from its ⋮ menu.
// The "Schedule" section shows each day's one-hour slots, how full they
// are and who booked them, and sets how many bookings a slot takes.
// A message pops up when a new booking arrives.
// The "Drivers" section adds, edits and deletes driver accounts and
// switches them on or off.
// The "Messages" section lists what visitors sent with the contact form.
// The "Feedback" section lists patient comments; staff choose which ones
// appear on the homepage.
// The "Free buses" section sets the destination, departure times and
// frequency of the free bus routes shown on the homepage.
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

// The sections of the dashboard (chosen in the side menu).
enum _View {
  overview,
  bookings,
  schedule,
  drivers,
  messages,
  feedback,
  shuttles
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  // The section that is open.
  _View _view = _View.overview;

  // The stage tab that is open.
  Stage _tab = Stage.newRequest;

  // Text typed in the bookings search box (patient, phone or ref).
  final _search = TextEditingController();

  // New bookings arriving while the dashboard is open.
  StreamSubscription<Booking>? _arrivals;

  @override
  void initState() {
    super.initState();
    _arrivals = bookingStore.arrivals.listen(_announce);
  }

  @override
  void dispose() {
    _arrivals?.cancel();
    _search.dispose();
    super.dispose();
  }

  // "New booking KR-1005 · 03.11.2026 09:00" with a button to open it.
  void _announce(Booking b) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 10),
      content: Text(
          '${context.t('New booking', 'Yeni rezervasyon')} ${b.ref} · '
          '${b.patient} · ${formatDate(b.date)} ${formatTime(b.time)}'),
      action: SnackBarAction(
        label: context.t('Open', 'Aç'),
        onPressed: () => _openStage(b.stage),
      ),
    ));
  }

  // Opens the bookings section on one stage tab (used by the overview).
  void _openStage(Stage stage) => setState(() {
        _view = _View.bookings;
        _tab = stage;
      });

  // Runs the action button of a row and moves the booking to the next stage.
  // Reserving and assigning a driver first open a small form in a dialog.
  // If the new time slot is full, nothing changes and a message says so.
  Future<void> _act(Booking booking) async {
    bool? go;
    switch (booking.stage) {
      case Stage.newRequest:
        go = true;
      case Stage.confirmed:
        go = await showDialog<bool>(
            context: context, builder: (_) => _ReserveDialog(booking));
      case Stage.reserved:
        go = await showDialog<bool>(
            context: context, builder: (_) => _DispatchDialog(booking));
      case Stage.arranged || Stage.cancelled:
        return;
    }
    if (go != true) return;
    final error = await bookingStore.advance(booking);
    if (mounted) showSaveError(context, error);
  }

  @override
  Widget build(BuildContext context) {
    // Not signed in: show the login page instead.
    if (!staffAuth.isStaff) return const AdminLoginPage();

    final wide = !Responsive.isTablet(context);

    // Rebuild the content whenever a booking, driver or comment changes.
    final content = ListenableBuilder(
      listenable: Listenable.merge([
        bookingStore,
        driverStore,
        messageStore,
        feedbackStore,
        shuttleStore
      ]),
      builder: (context, _) => SingleChildScrollView(
        padding: EdgeInsets.all(Responsive.isMobile(context) ? 16 : 32),
        child: switch (_view) {
          _View.overview => AdminOverview(
              onOpenStage: _openStage,
              onOpenSchedule: () => setState(() => _view = _View.schedule)),
          _View.schedule => const AdminSchedule(),
          _View.feedback => const _FeedbackList(),
          _View.drivers => const _DriverList(),
          _View.messages => const _MessageList(),
          _View.shuttles => const _ShuttleList(),
          _View.bookings => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: 24),
                _stageTiles(),
                const SizedBox(height: 28),
                _tabs(),
                const SizedBox(height: 16),
                _searchBox(),
                const SizedBox(height: 16),
                _table(),
              ],
            ),
        },
      ),
    );

    // Side menu that switches between the two sections.
    final menu =
        _SideMenu(view: _view, onView: (view) => setState(() => _view = view));

    return Scaffold(
      backgroundColor: AppColors.surface,
      // Small screens: top bar with a button that opens the menu.
      appBar: wide
          ? null
          : AppBar(
              backgroundColor: AppColors.blueDark,
              foregroundColor: Colors.white,
              title: Text(switch (_view) {
                _View.overview => context.t('Overview', 'Genel bakış'),
                _View.bookings => context.t('Bookings', 'Rezervasyonlar'),
                _View.schedule => context.t('Schedule', 'Takvim'),
                _View.drivers => context.t('Drivers', 'Sürücüler'),
                _View.messages => context.t('Messages', 'Mesajlar'),
                _View.feedback => context.t('Feedback', 'Görüşler'),
                _View.shuttles => context.t('Free buses', 'Ücretsiz servisler'),
              }),
            ),
      drawer: wide
          ? null
          : Drawer(backgroundColor: AppColors.blueDark, child: menu),
      // Wide screens: dark blue menu always visible on the left.
      body: wide
          ? Row(
              // Full height, so short sections start at the top.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 250, child: menu),
                Expanded(child: content),
              ],
            )
          : content,
    );
  }

  // Page title.
  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.t('Bookings', 'Rezervasyonlar'),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
        Text(
            context.t('Move each booking to the next stage.',
                'Her rezervasyonu bir sonraki aşamaya taşıyın.'),
            style: const TextStyle(color: AppColors.muted)),
      ],
    );
  }

  // One count tile per stage. Tapping a tile opens that tab.
  Widget _stageTiles() {
    return ResponsiveGrid(
      tabletColumns: 3,
      spacing: 16,
      desktopColumns: 5,
      children: [
        for (final stage in Stage.values)
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                  color: stage == _tab ? AppColors.blue : AppColors.border,
                  width: stage == _tab ? 2 : 1),
            ),
            child: InkWell(
              onTap: () => setState(() => _tab = stage),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stage.label(context),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.muted)),
                    const SizedBox(height: 6),
                    // How many bookings are in this stage.
                    Text(
                        '${bookingStore.bookings.where((b) => b.stage == stage).length}',
                        style: const TextStyle(
                            fontSize: 36, fontWeight: FontWeight.w800)),
                    // What happens next in this stage.
                    Text(stage.todo(context),
                        style: TextStyle(fontSize: 13, color: AppColors.blue)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Tabs: New requests / Confirmed / Reserved / Arranged / Cancelled.
  Widget _tabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<Stage>(
        showSelectedIcon: false,
        segments: [
          for (final stage in Stage.values)
            ButtonSegment(value: stage, label: Text(stage.label(context))),
        ],
        selected: {_tab},
        onSelectionChanged: (s) => setState(() => _tab = s.first),
      ),
    );
  }

  // Search box above the table: filters by patient name, phone or ref.
  Widget _searchBox() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: TextField(
        controller: _search,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: context.t(
              'Search patient, phone or ref', 'Hasta, telefon veya numara ara'),
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: _search.text.isEmpty
              ? null
              : IconButton(
                  tooltip: context.t('Clear', 'Temizle'),
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(_search.clear),
                ),
        ),
      ),
    );
  }

  // Table of the bookings in the open tab, with an action on each row.
  Widget _table() {
    final q = _search.text.trim().toLowerCase();
    final rows = bookingStore.bookings
        .where((b) => b.stage == _tab)
        .where((b) =>
            q.isEmpty ||
            b.patient.toLowerCase().contains(q) ||
            b.phone.contains(q) ||
            b.ref.toLowerCase().contains(q))
        .toList();

    // Button text for each stage's action.
    final actionLabel = switch (_tab) {
      Stage.newRequest => context.t('Confirm', 'Onayla'),
      Stage.confirmed => context.t('Reserve', 'Rezerve et'),
      Stage.reserved => context.t('Assign driver', 'Sürücü ata'),
      Stage.arranged || Stage.cancelled => '',
    };

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: rows.isEmpty
          // Nothing in this tab.
          ? Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                  context.t('No bookings here.', 'Burada rezervasyon yok.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted)),
            )
          // The table scrolls sideways on small screens.
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.muted),
                columns: [
                  DataColumn(label: Text(context.t('Ref', 'No'))),
                  DataColumn(label: Text(context.t('Patient', 'Hasta'))),
                  DataColumn(label: Text(context.t('Transport', 'Ulaşım'))),
                  DataColumn(label: Text(context.t('Route', 'Güzergâh'))),
                  DataColumn(
                      label: Text(context.t('Date & time', 'Tarih ve saat'))),
                  DataColumn(label: Text(context.t('Needs', 'İhtiyaçlar'))),
                  DataColumn(
                      label:
                          Text(context.t('Vehicle / driver', 'Araç / sürücü'))),
                  if (_tab == Stage.arranged)
                    DataColumn(label: Text(context.t('Trip', 'Yolculuk'))),
                  DataColumn(label: Text(context.t('Received', 'Alındı'))),
                  DataColumn(label: Text(context.t('Action', 'İşlem'))),
                ],
                rows: [
                  for (final b in rows)
                    DataRow(cells: [
                      DataCell(Text(b.ref,
                          style: const TextStyle(fontWeight: FontWeight.w800))),
                      // Name, and the phone to call them on.
                      DataCell(Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.patient),
                            Text(b.phone,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.muted)),
                          ])),
                      DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(b.type.icon, size: 18, color: AppColors.blue),
                        const SizedBox(width: 6),
                        Text(b.type.label(context)),
                      ])),
                      DataCell(Text('${b.from} → ${b.branch}')),
                      DataCell(
                          Text('${formatDate(b.date)}  ${formatTime(b.time)}')),
                      DataCell(Text(b.needs.isEmpty
                          ? '—'
                          : b.needs.map((n) => n.label(context)).join(', '))),
                      DataCell(Text(b.vehicle == null
                          ? '—'
                          : '${b.vehicle} / ${b.driver}')),
                      // Arranged bookings: the driver's latest step, live.
                      if (_tab == Stage.arranged)
                        DataCell(b.trip == null
                            ? const Text('—')
                            : Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(b.trip!.icon,
                                    size: 18,
                                    color: b.trip == TripStatus.completed
                                        ? AppColors.success
                                        : AppColors.blue),
                                const SizedBox(width: 6),
                                Text(b.trip!.label(context)),
                              ])),
                      // When the patient sent the request.
                      DataCell(Text(b.createdAt == null
                          ? '—'
                          : '${formatDate(b.createdAt!)} '
                              '${formatTime(TimeOfDay.fromDateTime(b.createdAt!))}')),
                      // Moves the booking to the next stage; the ⋮ menu
                      // reschedules, cancels or restores it.
                      DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                        switch (b.stage) {
                          Stage.arranged => Chip(
                              avatar: const Icon(Icons.check,
                                  size: 16, color: AppColors.success),
                              label: Text(context.t('Done', 'Tamamlandı')),
                            ),
                          Stage.cancelled => const SizedBox.shrink(),
                          _ => FilledButton(
                              onPressed: () => _act(b),
                              style: FilledButton.styleFrom(
                                  minimumSize: const Size(44, 40),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10)),
                              child: Text(actionLabel),
                            ),
                        },
                        BookingMenu(b),
                      ])),
                    ]),
                ],
              ),
            ),
    );
  }
}

// Dark blue left menu: logo, menu links, language switch, sign out.
class _SideMenu extends StatelessWidget {
  const _SideMenu({required this.view, required this.onView});

  // The open section and what to do when another one is tapped.
  final _View view;
  final ValueChanged<_View> onView;

  // Opens a section; on small screens also closes the drawer menu.
  void _open(BuildContext context, _View next) {
    Scaffold.maybeOf(context)?.closeDrawer();
    onView(next);
  }

  @override
  Widget build(BuildContext context) {
    // One white menu link.
    Widget link(IconData icon, String label, VoidCallback onTap,
            {bool selected = false}) =>
        ListTile(
          leading: Icon(icon, color: Colors.white),
          title: Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
          selected: selected,
          selectedTileColor: Colors.white.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.control)),
          onTap: onTap,
        );

    // Material (not a plain colored box), so the highlight of the open
    // section and the tap ripples show on the dark blue.
    return Material(
      color: AppColors.blueDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(8, 8, 8, 32),
                child: Logo(light: true),
              ),
              link(
                  Icons.insights_outlined,
                  context.t('Overview', 'Genel bakış'),
                  () => _open(context, _View.overview),
                  selected: view == _View.overview),
              // Shows how many requests are waiting to be confirmed.
              ListenableBuilder(
                listenable: bookingStore,
                builder: (context, _) => link(
                    Icons.dashboard_outlined,
                    bookingStore.waiting == 0
                        ? context.t('Bookings', 'Rezervasyonlar')
                        : '${context.t('Bookings', 'Rezervasyonlar')} (${bookingStore.waiting})',
                    () => _open(context, _View.bookings),
                    selected: view == _View.bookings),
              ),
              link(
                  Icons.calendar_view_day_outlined,
                  context.t('Schedule', 'Takvim'),
                  () => _open(context, _View.schedule),
                  selected: view == _View.schedule),
              link(Icons.badge_outlined, context.t('Drivers', 'Sürücüler'),
                  () => _open(context, _View.drivers),
                  selected: view == _View.drivers),
              // Shows how many messages are still unanswered.
              ListenableBuilder(
                listenable: messageStore,
                builder: (context, _) => link(
                    Icons.mail_outline,
                    messageStore.open == 0
                        ? context.t('Messages', 'Mesajlar')
                        : '${context.t('Messages', 'Mesajlar')} (${messageStore.open})',
                    () => _open(context, _View.messages),
                    selected: view == _View.messages),
              ),
              link(
                  Icons.rate_review_outlined,
                  context.t('Feedback', 'Görüşler'),
                  () => _open(context, _View.feedback),
                  selected: view == _View.feedback),
              link(
                  Icons.directions_bus_outlined,
                  context.t('Free buses', 'Ücretsiz servisler'),
                  () => _open(context, _View.shuttles),
                  selected: view == _View.shuttles),
              link(
                  Icons.public,
                  context.t('View website', 'Siteyi görüntüle'),
                  () => Navigator.pushNamedAndRemoveUntil(
                      context, '/', (_) => false)),
              const Spacer(),
              // Choose the language (opens a list of all languages).
              link(Icons.translate, context.lang.nativeName,
                  () => showLanguageDialog(context)),
              // Change the site's main color.
              link(
                  Icons.palette_outlined,
                  context.t('Site color', 'Site rengi'),
                  () => showColorPicker(context)),
              // Sign out and go back to the login page.
              link(Icons.logout, context.t('Sign out', 'Çıkış yap'), () async {
                await staffAuth.signOut();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                    context, '/admin/login', (_) => false);
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// Feedback section: average rating, then one card per comment with
// buttons to show it on the homepage or delete it.
class _FeedbackList extends StatelessWidget {
  const _FeedbackList();

  @override
  Widget build(BuildContext context) {
    final items = feedbackStore.items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.t('Feedback', 'Görüşler'),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
        Text(
            context.t(
                'Read patient comments. Approved comments appear on the '
                    'homepage with the first name only.',
                'Hasta yorumlarını okuyun. Onaylanan yorumlar ana sayfada '
                    'yalnızca adla görünür.'),
            style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 24),
        // Summary: average stars and how many comments.
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(feedbackStore.averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.w800)),
              Stars(feedbackStore.averageRating.round(), size: 24),
              Text(
                  context.t(
                      '${items.length} comments', '${items.length} yorum'),
                  style: const TextStyle(color: AppColors.muted)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          Text(context.t('No comments yet.', 'Henüz yorum yok.'),
              style: const TextStyle(color: AppColors.muted)),
        for (final f in items)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                  color: f.published ? AppColors.success : AppColors.border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Stars(f.rating, size: 18),
                    Text(f.type.label(context),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                        [
                          formatDate(f.date),
                          if (f.name.isNotEmpty) f.name,
                          if (f.ref.isNotEmpty) f.ref,
                        ].join(' · '),
                        style: const TextStyle(color: AppColors.muted)),
                    if (f.published)
                      Text(context.t('On homepage', 'Ana sayfada'),
                          style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(f.comment, style: const TextStyle(height: 1.5)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    f.published
                        ? OutlinedButton(
                            onPressed: () =>
                                feedbackStore.setPublished(f, false),
                            child: Text(context.t(
                                'Hide from website', 'Siteden kaldır')),
                          )
                        : FilledButton(
                            onPressed: () =>
                                feedbackStore.setPublished(f, true),
                            child: Text(
                                context.t('Show on website', 'Sitede göster')),
                          ),
                    TextButton(
                      onPressed: () => feedbackStore.remove(f),
                      child: Text(context.t('Delete', 'Sil')),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// Reserve form: set the date, time and vehicle type, then save.
class _ReserveDialog extends StatefulWidget {
  const _ReserveDialog(this.booking);

  final Booking booking;

  @override
  State<_ReserveDialog> createState() => _ReserveDialogState();
}

class _ReserveDialogState extends State<_ReserveDialog> {
  // Start with what the patient asked for.
  late DateTime _date = widget.booking.date;
  late TimeOfDay _time = widget.booking.time;
  late TransportType _type = widget.booking.type;

  // Saves the changes into the booking and closes the dialog.
  void _save() {
    widget.booking
      ..date = _date
      ..time = _time
      ..type = _type;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text('${context.t('Reserve', 'Rezerve et')} ${widget.booking.ref}'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FieldLabel(
              context.t('Date', 'Tarih'),
              child: PickerField(
                value: formatDate(_date),
                hint: '',
                icon: Icons.calendar_today_outlined,
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                      context: context,
                      initialDate: _date.isBefore(now) ? now : _date,
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 365)));
                  if (picked != null) setState(() => _date = picked);
                },
              ),
            ),
            const SizedBox(height: 14),
            FieldLabel(
              context.t('Time', 'Saat'),
              child: PickerField(
                value: formatTime(_time),
                hint: '',
                icon: Icons.schedule,
                onTap: () async {
                  final picked = await showTimePicker(
                      context: context, initialTime: _time);
                  if (picked != null) setState(() => _time = picked);
                },
              ),
            ),
            const SizedBox(height: 14),
            FieldLabel(
              context.t('Vehicle type', 'Araç tipi'),
              child: DropdownButtonFormField<TransportType>(
                initialValue: _type,
                isExpanded: true,
                items: [
                  for (final type in TransportType.values)
                    DropdownMenuItem(
                        value: type, child: Text(type.label(context))),
                ],
                onChanged: (v) => setState(() => _type = v!),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.t('Cancel', 'İptal'))),
        FilledButton(
            onPressed: _save,
            child: Text(context.t('Save & reserve', 'Kaydet ve rezerve et'))),
      ],
    );
  }
}

// Driver form: choose one of the driver accounts and the vehicle plate,
// then save. Only that driver will see the booking.
class _DispatchDialog extends StatefulWidget {
  const _DispatchDialog(this.booking);

  final Booking booking;

  @override
  State<_DispatchDialog> createState() => _DispatchDialogState();
}

class _DispatchDialogState extends State<_DispatchDialog> {
  final _formKey = GlobalKey<FormState>();
  final _vehicle = TextEditingController();
  Driver? _driver;

  @override
  void dispose() {
    _vehicle.dispose();
    super.dispose();
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty)
      ? context.t('Required', 'Zorunlu alan')
      : null;

  // Saves the vehicle and driver into the booking and closes the dialog.
  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.booking
      ..vehicle = _vehicle.text.trim()
      ..driver = _driver!.name
      ..driverUid = _driver!.uid
      ..trip = TripStatus.assigned;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          '${context.t('Assign driver', 'Sürücü ata')} ${widget.booking.ref}'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FieldLabel(
                context.t('Driver', 'Sürücü'),
                child: DropdownButtonFormField<Driver>(
                  initialValue: _driver,
                  isExpanded: true,
                  validator: (v) =>
                      v == null ? context.t('Required', 'Zorunlu alan') : null,
                  items: [
                    for (final d in driverStore.active)
                      DropdownMenuItem(value: d, child: Text(d.name)),
                  ],
                  // Fill in the driver's usual vehicle.
                  onChanged: (d) => setState(() {
                    _driver = d;
                    if (d != null && d.vehicle.isNotEmpty) {
                      _vehicle.text = d.vehicle;
                    }
                  }),
                ),
              ),
              if (driverStore.active.isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                    context.t('No drivers yet. Add one in the Drivers section.',
                        'Henüz sürücü yok. Sürücüler bölümünden ekleyin.'),
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 14),
              FieldLabel(context.t('Vehicle plate', 'Araç plakası'),
                  child: TextFormField(
                      controller: _vehicle,
                      validator: _required,
                      decoration:
                          const InputDecoration(hintText: '[34 ABC 123]'))),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.t('Cancel', 'İptal'))),
        FilledButton(
            onPressed: _save,
            child: Text(context.t('Save & assign', 'Kaydet ve ata'))),
      ],
    );
  }
}

// Drivers section: one card per driver account, a switch to turn the
// account on or off, buttons to edit or delete it, and a button to add a
// new driver.
class _DriverList extends StatelessWidget {
  const _DriverList();

  @override
  Widget build(BuildContext context) {
    final drivers = driverStore.drivers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.t('Drivers', 'Sürücüler'),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
        Text(
            context.t(
                'Drivers sign in at /driver and only see the trips you give '
                    'them. Switched-off drivers cannot sign in.',
                'Sürücüler /driver adresinden giriş yapar ve yalnızca '
                    'onlara verdiğiniz yolculukları görür. Kapalı sürücüler '
                    'giriş yapamaz.'),
            style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => showDialog<void>(
              context: context, builder: (_) => const _AddDriverDialog()),
          icon: const Icon(Icons.person_add_alt),
          label: Text(context.t('Add driver', 'Sürücü ekle')),
        ),
        const SizedBox(height: 16),
        if (drivers.isEmpty)
          Text(context.t('No drivers yet.', 'Henüz sürücü yok.'),
              style: const TextStyle(color: AppColors.muted)),
        for (final d in drivers)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.blueSoft,
                  child: Icon(Icons.badge_outlined, color: AppColors.blue),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.name,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800)),
                      Text(
                          [
                            d.phone,
                            d.email,
                            if (d.vehicle.isNotEmpty) d.vehicle
                          ].join(' · '),
                          style: const TextStyle(color: AppColors.muted)),
                    ],
                  ),
                ),
                Text(
                    d.active
                        ? context.t('Active', 'Aktif')
                        : context.t('Off', 'Kapalı'),
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: d.active ? AppColors.success : AppColors.muted)),
                Switch(
                  value: d.active,
                  onChanged: (v) => driverStore.setActive(d, v),
                ),
                IconButton(
                  tooltip: context.t('Edit', 'Düzenle'),
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => _AddDriverDialog(driver: d)),
                ),
                IconButton(
                  tooltip: context.t('Delete', 'Sil'),
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(context, d),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Asks first, then removes the driver's account and profile.
  Future<void> _delete(BuildContext context, Driver d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t('Delete driver', 'Sürücüyü sil')),
        content: Text(context.t(
            '${d.name} will no longer be able to sign in to the driver '
                'dashboard. This cannot be undone. Their past trips keep '
                'their name.',
            '${d.name} artık sürücü paneline giriş yapamayacak. Bu işlem '
                'geri alınamaz. Geçmiş yolculuklarda adı kalır.')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.t('Cancel', 'İptal'))),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error),
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.t('Delete', 'Sil'))),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final error = await driverStore.delete(d);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.t(
              'Could not delete the driver.', 'Sürücü silinemedi.'))));
    }
  }
}

// Add / edit driver form: name, phone, usual vehicle, email and a password
// the coordinator gives to the driver. When editing, the email stays as it
// is and a new password is chosen by the driver from a reset email.
class _AddDriverDialog extends StatefulWidget {
  const _AddDriverDialog({this.driver});

  // The driver being edited, or null to add a new one.
  final Driver? driver;

  @override
  State<_AddDriverDialog> createState() => _AddDriverDialogState();
}

class _AddDriverDialogState extends State<_AddDriverDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.driver?.name);
  late final _phone = TextEditingController(text: widget.driver?.phone);
  late final _vehicle = TextEditingController(text: widget.driver?.vehicle);
  late final _email = TextEditingController(text: widget.driver?.email);
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  bool get _editing => widget.driver != null;

  @override
  void dispose() {
    for (final c in [_name, _phone, _vehicle, _email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty)
      ? context.t('Required', 'Zorunlu alan')
      : null;

  Future<void> _save() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final fields = (
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      vehicle: _vehicle.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
    );
    final error = _editing
        ? await driverStore.edit(widget.driver!,
            name: fields.name, phone: fields.phone, vehicle: fields.vehicle)
        : await driverStore.add(
            name: fields.name,
            phone: fields.phone,
            vehicle: fields.vehicle,
            email: fields.email,
            password: fields.password);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _busy = false;
      _error = switch (error) {
        'already-exists' => context.t('This email already has an account.',
            'Bu e-posta ile zaten bir hesap var.'),
        'invalid-argument' => context.t('Please check the email and password.',
            'Lütfen e-posta ve şifreyi kontrol edin.'),
        'permission-denied' => context.t(
            'The account was made, but the profile could not be saved.',
            'Hesap oluşturuldu ancak profil kaydedilemedi.'),
        _ => context.t('Could not save the driver. Please try again.',
            'Sürücü kaydedilemedi. Lütfen tekrar deneyin.'),
      };
    });
  }

  // Emails the driver a link to choose a new password.
  Future<void> _sendReset() async {
    final error = await driverStore.sendPasswordReset(widget.driver!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error == null
            ? context.t(
                'A link to choose a new password was sent to '
                    '${widget.driver!.email}.',
                'Yeni şifre bağlantısı ${widget.driver!.email} adresine '
                    'gönderildi.')
            : context.t(
                'Could not send the email.', 'E-posta gönderilemedi.'))));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_editing
          ? context.t('Edit driver', 'Sürücüyü düzenle')
          : context.t('Add driver', 'Sürücü ekle')),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FieldLabel(context.t('Full name', 'Ad soyad'),
                    child:
                        TextFormField(controller: _name, validator: _required)),
                const SizedBox(height: 14),
                FieldLabel(context.t('Phone', 'Telefon'),
                    child: TextFormField(
                        controller: _phone,
                        validator: _required,
                        keyboardType: TextInputType.phone)),
                const SizedBox(height: 14),
                FieldLabel(
                    context.t('Usual vehicle plate (optional)',
                        'Genel araç plakası (isteğe bağlı)'),
                    child: TextFormField(
                        controller: _vehicle,
                        decoration:
                            const InputDecoration(hintText: '[34 ABC 123]'))),
                const SizedBox(height: 14),
                FieldLabel(
                    context.t('Email (to sign in)', 'E-posta (giriş için)'),
                    child: TextFormField(
                        controller: _email,
                        // The sign-in email can only be changed in the
                        // Firebase console.
                        readOnly: _editing,
                        validator: _required,
                        keyboardType: TextInputType.emailAddress)),
                const SizedBox(height: 14),
                if (_editing)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _sendReset,
                      icon: const Icon(Icons.lock_reset),
                      label: Text(context.t('Email a new-password link',
                          'Yeni şifre bağlantısı gönder')),
                    ),
                  )
                else
                  FieldLabel(context.t('First password', 'İlk şifre'),
                      child: TextFormField(
                          controller: _password,
                          validator: (v) => (v ?? '').length < 8
                              ? context.t(
                                  'At least 8 characters', 'En az 8 karakter')
                              : null)),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.t('Cancel', 'İptal'))),
        FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(_busy
                ? context.t('Saving...', 'Kaydediliyor...')
                : _editing
                    ? context.t('Save', 'Kaydet')
                    : context.t('Add driver', 'Sürücü ekle'))),
      ],
    );
  }
}

// Messages section: one card per contact form message, newest first, with
// buttons to mark it as answered or delete it. Unanswered ones have a blue
// border.
class _MessageList extends StatelessWidget {
  const _MessageList();

  @override
  Widget build(BuildContext context) {
    final items = messageStore.items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.t('Messages', 'Mesajlar'),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
        Text(
            context.t('Sent with the contact form on the website.',
                'Sitedeki iletişim formuyla gönderilenler.'),
            style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 24),
        if (items.isEmpty)
          Text(context.t('No messages yet.', 'Henüz mesaj yok.'),
              style: const TextStyle(color: AppColors.muted)),
        for (final m in items)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                  color: m.handled ? AppColors.border : AppColors.blue,
                  width: m.handled ? 1 : 2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(m.name,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    Text(m.topic.label(context),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                        [
                          '${formatDate(m.date)} '
                              '${formatTime(TimeOfDay.fromDateTime(m.date))}',
                          if (m.reference.isNotEmpty) m.reference,
                        ].join(' · '),
                        style: const TextStyle(color: AppColors.muted)),
                    if (m.handled)
                      Text(context.t('Answered', 'Yanıtlandı'),
                          style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                // Phone or email to answer to.
                SelectableText(m.reply,
                    style: TextStyle(
                        color: AppColors.blue, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text(m.message, style: const TextStyle(height: 1.5)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    m.handled
                        ? OutlinedButton(
                            onPressed: () => messageStore.setHandled(m, false),
                            child: Text(context.t(
                                'Mark as not answered', 'Yanıtlanmadı yap')),
                          )
                        : FilledButton(
                            onPressed: () => messageStore.setHandled(m, true),
                            child: Text(context.t('Mark as answered',
                                'Yanıtlandı olarak işaretle')),
                          ),
                    TextButton(
                      onPressed: () => messageStore.remove(m),
                      child: Text(context.t('Delete', 'Sil')),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// Free buses section: one card per route (A, B, C) with what visitors see
// on the homepage and a button to change it.
class _ShuttleList extends StatelessWidget {
  const _ShuttleList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.t('Free buses', 'Ücretsiz servisler'),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
        Text(
            context.t(
                'Shown on the homepage under "Next free buses". A route says '
                    '"Schedule to be announced" until it has a destination '
                    'and at least one departure time.',
                'Ana sayfada "Sıradaki ücretsiz servisler" altında görünür. '
                    'Bir hat, varış noktası ve en az bir kalkış saati '
                    'girilene kadar "Sefer saatleri yakında duyurulacak" '
                    'olarak görünür.'),
            style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 24),
        for (final route in shuttleStore.routes)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.blue,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(route.branch.id,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${context.t(route.branch.en, route.branch.tr)} → '
                          '${route.destination.isEmpty ? context.t('[No destination]', '[Varış noktası yok]') : route.destination}',
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800)),
                      Text(
                          [
                            route.times.isEmpty
                                ? context.t(
                                    'No departure times', 'Kalkış saati yok')
                                : route.times.join(', '),
                            if (route.frequency != null)
                              context.t('Every ${route.frequency} min',
                                  'Her ${route.frequency} dk'),
                          ].join(' · '),
                          style: const TextStyle(color: AppColors.muted)),
                      Text(
                          route.announced
                              ? context.t('Shown on the homepage',
                                  'Ana sayfada görünüyor')
                              : context.t(
                                  'Visitors see "Schedule to be announced"',
                                  'Ziyaretçiler "Sefer saatleri yakında duyurulacak" görür'),
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: route.announced
                                  ? AppColors.success
                                  : AppColors.muted)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => showDialog<void>(
                      context: context, builder: (_) => _ShuttleDialog(route)),
                  child: Text(context.t('Edit', 'Düzenle')),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// Edit form for one free bus route: destination, departure times and how
// often it runs. Leaving destination and times empty hides the schedule.
class _ShuttleDialog extends StatefulWidget {
  const _ShuttleDialog(this.route);

  final ShuttleRoute route;

  @override
  State<_ShuttleDialog> createState() => _ShuttleDialogState();
}

class _ShuttleDialogState extends State<_ShuttleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _destination =
      TextEditingController(text: widget.route.destination);
  late final _times =
      TextEditingController(text: widget.route.times.join(', '));
  late final _frequency =
      TextEditingController(text: widget.route.frequency?.toString() ?? '');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_destination, _times, _frequency]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final frequency = _frequency.text.trim();
    final saved = await shuttleStore.save(ShuttleRoute(
      branch: widget.route.branch,
      destination: _destination.text.trim(),
      times: parseTimes(_times.text)!,
      frequency: frequency.isEmpty ? null : int.parse(frequency),
    ));
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _busy = false;
      _error = context.t('Could not save. Please try again.',
          'Kaydedilemedi. Lütfen tekrar deneyin.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final branch = widget.route.branch;
    return AlertDialog(
      title: Text('${context.t('Route', 'Hat')} ${branch.id} · '
          '${context.t(branch.en, branch.tr)}'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FieldLabel(context.t('Destination', 'Varış noktası'),
                    child: TextFormField(
                        controller: _destination,
                        maxLength: 200,
                        validator: (v) => (v == null || v.trim().isEmpty) &&
                                (parseTimes(_times.text)?.isNotEmpty ?? false)
                            ? context.t('Add a destination for these times',
                                'Bu saatler için varış noktası girin')
                            : null)),
                const SizedBox(height: 14),
                FieldLabel(
                    context.t('Departure times (24-hour, comma separated)',
                        'Kalkış saatleri (24 saat, virgülle ayırın)'),
                    child: TextFormField(
                        controller: _times,
                        maxLines: 3,
                        minLines: 1,
                        decoration:
                            const InputDecoration(hintText: '[08:00, 08:30]'),
                        validator: (v) {
                          final times = parseTimes(v ?? '');
                          if (times == null) {
                            return context.t('Use times like 08:30, 14:00',
                                '08:30, 14:00 gibi saatler girin');
                          }
                          if (times.length > 100) {
                            return context.t(
                                'At most 100 times', 'En fazla 100 saat');
                          }
                          return null;
                        })),
                const SizedBox(height: 14),
                FieldLabel(
                    context.t('Every how many minutes (optional)',
                        'Kaç dakikada bir (isteğe bağlı)'),
                    child: TextFormField(
                        controller: _frequency,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final text = v?.trim() ?? '';
                          if (text.isEmpty) return null;
                          final n = int.tryParse(text);
                          return n == null || n < 1 || n > 1440
                              ? context.t('A number of minutes, 1 to 1440',
                                  '1 ile 1440 arasında dakika')
                              : null;
                        })),
                const SizedBox(height: 8),
                Text(
                    context.t(
                        'Leave destination and times empty to show '
                            '"Schedule to be announced".',
                        '"Sefer saatleri yakında duyurulacak" göstermek için '
                            'varış noktası ve saatleri boş bırakın.'),
                    style: const TextStyle(color: AppColors.muted)),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.t('Cancel', 'İptal'))),
        FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(_busy
                ? context.t('Saving...', 'Kaydediliyor...')
                : context.t('Save', 'Kaydet'))),
      ],
    );
  }
}
