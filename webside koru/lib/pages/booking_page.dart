import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../data/bookings.dart';
import '../data/tracking.dart';
import '../lang.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/route_map.dart';
import '../widgets/site_layout.dart';
import '../widgets/slot_grid.dart';

// Answers already given elsewhere (homepage booking bar, airport button)
// that the booking page fills in for the user.
class BookingDraft {
  const BookingDraft({this.type, this.from, this.branch, this.date});

  final TransportType? type;
  final String? from;
  final String? branch;
  final DateTime? date;
}

// "Book transport" page: a 3-step form with a summary panel and an
// emergency notice next to it.
//   Step 1: transport type
//   Step 2: patient details and mobility needs
//   Step 3: pickup, destination, route map, date, a one-hour time slot
//           (full slots cannot be picked) and KVKK consent
class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  // Which step is shown: 0, 1 or 2.
  int _step = 0;

  // Step 1 answer.
  TransportType? _type;

  // Step 2 answers.
  final _step2Key = GlobalKey<FormState>();
  final _patient = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();
  final Set<MobilityNeed> _needs = {};

  // Step 3 answers.
  final _step3Key = GlobalKey<FormState>();
  final _from = TextEditingController();
  String _branch = branches.first;
  // Pickup point tapped on the map (optional).
  LatLng? _pickup;
  DateTime? _date;
  // Start of the chosen one-hour slot, e.g. 09:00.
  TimeOfDay? _time;
  bool _consent = false;

  // Shows the red error texts on steps 1 and 3 after a failed "Next"/"Send".
  bool _showErrors = false;

  // The booking that was sent with its tracking code (when set, the
  // thank-you message is shown).
  BookingReceipt? _sent;

  // true while the booking is being saved.
  bool _sending = false;

  // Makes sure the homepage answers are only copied in once.
  bool _draftApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Copy answers sent from the homepage into the form.
    if (_draftApplied) return;
    _draftApplied = true;
    final draft = ModalRoute.of(context)?.settings.arguments;
    if (draft is BookingDraft) {
      _type = draft.type;
      _from.text = draft.from ?? '';
      _branch = draft.branch ?? _branch;
      _date = draft.date;
    }
  }

  @override
  void dispose() {
    for (final c in [_patient, _phone, _notes, _from]) {
      c.dispose();
    }
    super.dispose();
  }

  // "Required" error for empty text fields.
  String? _required(String? v) => (v == null || v.trim().isEmpty)
      ? context.t('Required', 'Zorunlu alan')
      : null;

  // Checks the current step; if it is OK, goes to the next one.
  void _next() {
    final ok = switch (_step) {
      0 => _type != null,
      1 => _step2Key.currentState!.validate(),
      _ => false,
    };
    setState(() {
      _showErrors = !ok;
      if (ok) _step++;
    });
  }

  // Checks step 3 and sends the booking.
  Future<void> _send() async {
    if (_sending) return;
    final formOk = _step3Key.currentState!.validate();
    final ok = formOk && _date != null && _time != null && _consent;
    if (!ok) {
      setState(() => _showErrors = true);
      return;
    }
    // TODO: also notify the coordinators (e.g. email) about new bookings.
    setState(() => _sending = true);
    final BookingReceipt receipt;
    try {
      receipt = await bookingStore.add(
        patient: _patient.text.trim(),
        phone: _phone.text.trim(),
        type: _type!,
        from: _from.text.trim(),
        branch: _branch,
        date: _date!,
        time: _time!,
        needs: {..._needs},
        notes: _notes.text.trim(),
        pickup: _pickup,
      );
    } on SlotFullException {
      // Someone took the last place first. The slot list shows the slot as
      // full now, with other free times.
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.t(
              'This time slot is fully booked. Please choose another '
                  'available time.',
              'Bu saat dilimi tamamen dolu. Lütfen başka bir müsait saat '
                  'seçin.'))));
      return;
    } catch (e) {
      debugPrint('Sending booking failed: $e');
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.t(
              'Could not send your request. Please try again or call us.',
              'Talebiniz gönderilemedi. Lütfen tekrar deneyin veya bizi arayın.'))));
      return;
    }
    // This browser can now open the tracking page without the code.
    await tracking.remember(receipt.token);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = receipt;
    });
  }

  // Clears everything to start a new booking.
  void _reset() {
    for (final c in [_patient, _phone, _notes, _from]) {
      c.clear();
    }
    setState(() {
      _step = 0;
      _type = null;
      _needs.clear();
      _branch = branches.first;
      _pickup = null;
      _date = null;
      _time = null;
      _consent = false;
      _showErrors = false;
      _sent = null;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    // Free times differ per day, so the time is chosen again.
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
        _time = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tablet = Responsive.isTablet(context);

    // Left: the form (or the thank-you message after sending).
    final main = _sent != null ? _confirmation() : _form();

    // Right: summary and emergency notice.
    final side = Column(
      children: [
        _summary(),
        const SizedBox(height: 20),
        const EmergencyNotice(),
      ],
    );

    return SiteScaffold(
      current: NavItem.book,
      children: [
        SectionContainer(
          top: 40,
          bottom: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeading(context.t('Book transport', 'Ulaşım rezervasyonu'),
                  subtitle: context.t(
                      'Three short steps. A coordinator calls you to confirm.',
                      'Üç kısa adım. Bir koordinatör onay için sizi arar.')),
              const SizedBox(height: 32),
              // Small screens: summary under the form. Wide: side by side.
              if (tablet) ...[
                main,
                const SizedBox(height: 24),
                side,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: main),
                    const SizedBox(width: 32),
                    Expanded(flex: 2, child: side),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  // White card holding the step indicator, the current step and the
  // Back / Next buttons.
  Widget _form() {
    final stepTitles = [
      context.t('Transport type', 'Ulaşım tipi'),
      context.t('Patient', 'Hasta'),
      context.t('Pickup & time', 'Adres ve saat'),
    ];

    return Container(
      padding: EdgeInsets.all(Responsive.isMobile(context) ? 20 : 32),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step indicator: done = light blue with a check, current = blue.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < stepTitles.length; i++)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: i == _step
                        ? AppColors.blue
                        : i < _step
                            ? AppColors.blueSoft
                            : AppColors.surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (i < _step) ...[
                        Icon(Icons.check, size: 16, color: AppColors.blue),
                        const SizedBox(width: 6),
                      ],
                      Text('${i + 1}. ${stepTitles[i]}',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: i == _step
                                  ? Colors.white
                                  : i < _step
                                      ? AppColors.blueDark
                                      : AppColors.muted)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),
          // The current step.
          switch (_step) {
            0 => _stepType(),
            1 => _stepPatient(),
            _ => _stepPickup(),
          },
          const SizedBox(height: 28),
          // Back / Next (or Send on the last step).
          Row(
            children: [
              if (_step > 0)
                OutlinedButton(
                  onPressed: () => setState(() {
                    _step--;
                    _showErrors = false;
                  }),
                  child: Text(context.t('Back', 'Geri')),
                ),
              const Spacer(),
              FilledButton(
                onPressed: _step < 2 ? _next : (_sending ? null : _send),
                child: Text(_step < 2
                    ? context.t('Next', 'İleri')
                    : _sending
                        ? context.t('Sending...', 'Gönderiliyor...')
                        : context.t('Send request', 'Talebi gönder')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Step 1: four selectable transport type cards.
  Widget _stepType() {
    // Short description under each type.
    String description(TransportType type) => switch (type) {
          TransportType.ambulance => context.t(
              'Stretcher transfer with medical staff.',
              'Sağlık personeli eşliğinde sedyeli transfer.'),
          TransportType.wheelchair => context.t(
              'Ramp or lift, room for a companion.',
              'Rampa veya lift, refakatçi için yer.'),
          TransportType.standard => context.t(
              'For patients who can walk on their own.',
              'Kendi başına yürüyebilen hastalar için.'),
          TransportType.airport => context.t(
              'Meet at arrivals, drive to the hospital or hotel.',
              'Gelen yolcu çıkışında karşılama, hastane veya otele transfer.'),
        };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveGrid(
          desktopColumns: 2,
          spacing: 14,
          children: [
            for (final type in TransportType.values)
              _SelectCard(
                selected: _type == type,
                icon: type.icon,
                title: type.label(context),
                body: description(type),
                onTap: () => setState(() {
                  _type = type;
                  _showErrors = false;
                }),
              ),
          ],
        ),
        // Error when "Next" is pressed without choosing.
        if (_showErrors && _type == null) ...[
          const SizedBox(height: 12),
          Text(
              context.t('Please choose a transport type.',
                  'Lütfen bir ulaşım tipi seçin.'),
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ],
    );
  }

  // Step 2: patient name, phone, mobility needs and notes.
  Widget _stepPatient() {
    return Form(
      key: _step2Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldLabel(
            context.t('Patient full name', 'Hastanın adı soyadı'),
            child: TextFormField(
                controller: _patient,
                validator: _required,
                onChanged: (_) => setState(() {})),
          ),
          const SizedBox(height: 16),
          FieldLabel(
            context.t('Contact phone', 'İletişim telefonu'),
            child: TextFormField(
                controller: _phone,
                validator: _required,
                keyboardType: TextInputType.phone),
          ),
          const SizedBox(height: 20),
          FieldLabel(
            context.t('Mobility needs', 'Hareket ihtiyaçları'),
            // Chips the user can switch on and off.
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final need in MobilityNeed.values)
                  FilterChip(
                    label: Text(need.label(context)),
                    selected: _needs.contains(need),
                    onSelected: (on) => setState(
                        () => on ? _needs.add(need) : _needs.remove(need)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FieldLabel(
            context.t('Notes for the team (optional)',
                'Ekip için notlar (isteğe bağlı)'),
            child: TextFormField(controller: _notes, maxLines: 3),
          ),
        ],
      ),
    );
  }

  // Step 3: pickup address, destination branch, date, time and KVKK.
  Widget _stepPickup() {
    final error = Theme.of(context).colorScheme.error;
    final mustPick = context.t('Required', 'Zorunlu alan');

    return Form(
      key: _step3Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldLabel(
            context.t('Pickup address', 'Alınış adresi'),
            child: TextFormField(
                controller: _from,
                validator: _required,
                onChanged: (_) => setState(() {})),
          ),
          const SizedBox(height: 16),
          FieldLabel(
            context.t('Destination branch', 'Gidilecek şube'),
            child: DropdownButtonFormField<String>(
              initialValue: _branch,
              items: [
                for (final b in branches)
                  DropdownMenuItem(value: b, child: Text(b)),
              ],
              onChanged: (v) => setState(() => _branch = v!),
            ),
          ),
          const SizedBox(height: 16),
          // Map of the trip: tap to set the pickup point.
          RouteMap(
            destination: branchLocation(_branch),
            pickup: _pickup,
            onPickupChanged: (p) => setState(() => _pickup = p),
          ),
          const SizedBox(height: 16),
          FieldLabel(
            context.t('Date', 'Tarih'),
            child: PickerField(
              value: _date == null ? null : formatDate(_date!),
              hint: context.t('Select', 'Seçin'),
              icon: Icons.calendar_today_outlined,
              onTap: _pickDate,
              errorText: _showErrors && _date == null ? mustPick : null,
            ),
          ),
          const SizedBox(height: 16),
          // One-hour time slots of the chosen day, with places left.
          FieldLabel(
            context.t('Time', 'Saat'),
            child: _date == null
                ? Text(
                    context.t('Choose a date to see the free times.',
                        'Boş saatleri görmek için bir tarih seçin.'),
                    style: const TextStyle(color: AppColors.muted))
                : SlotGrid(
                    day: _date!,
                    selected: _time?.hour,
                    onSelected: (hour) => setState(
                        () => _time = TimeOfDay(hour: hour, minute: 0)),
                    errorText: _showErrors && _time == null ? mustPick : null,
                  ),
          ),
          const SizedBox(height: 20),
          // KVKK privacy consent (must be ticked to send).
          InkWell(
            onTap: () => setState(() => _consent = !_consent),
            borderRadius: BorderRadius.circular(AppRadius.control),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                    value: _consent,
                    onChanged: (v) => setState(() => _consent = v!)),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                        context.t(
                            'I agree that my personal and health data is '
                                'processed under KVKK to arrange this transport.',
                            'Kişisel ve sağlık verilerimin bu ulaşımın '
                                'düzenlenmesi amacıyla KVKK kapsamında '
                                'işlenmesini kabul ediyorum.'),
                        style: const TextStyle(height: 1.5)),
                  ),
                ),
              ],
            ),
          ),
          if (_showErrors && !_consent)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Text(
                  context.t('Please accept the KVKK notice.',
                      'Lütfen KVKK onayını verin.'),
                  style: TextStyle(color: error)),
            ),
        ],
      ),
    );
  }

  // Panel showing the answers so far ("—" when not answered yet).
  Widget _summary() {
    String orDash(String? v) => (v == null || v.isEmpty) ? '—' : v;

    final rows = [
      (context.t('Transport', 'Ulaşım'), _type?.label(context)),
      (context.t('Patient', 'Hasta'), _patient.text.trim()),
      (
        context.t('Needs', 'İhtiyaçlar'),
        _needs.map((n) => n.label(context)).join(', ')
      ),
      (context.t('From', 'Nereden'), _from.text.trim()),
      (context.t('To', 'Nereye'), _branch),
      (context.t('Date', 'Tarih'), _date == null ? null : formatDate(_date!)),
      (context.t('Time', 'Saat'), _time == null ? null : formatTime(_time!)),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.t('Summary', 'Özet'),
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
                    child: Text(orDash(value),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Thank-you message shown after sending, with the reference number and
  // the secret tracking code.
  Widget _confirmation() {
    final b = _sent!.booking;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 48),
          const SizedBox(height: 16),
          Text(context.t('Request received', 'Talebiniz alındı'),
              style:
                  const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(
              context.t(
                  'Reference: ${b.ref}. A coordinator will call ${b.phone} '
                      'to confirm your ride.',
                  'Referans: ${b.ref}. Bir koordinatör yolculuğunuzu onaylamak '
                      'için ${b.phone} numarasını arayacak.'),
              style: const TextStyle(
                  fontSize: 17, height: 1.6, color: AppColors.muted)),
          const SizedBox(height: 20),
          // Tracking code: with the reference, it opens the live status.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.t('Your tracking code', 'Takip kodunuz'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.muted)),
                const SizedBox(height: 6),
                SelectableText(_sent!.code,
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        color: AppColors.blueDark)),
                const SizedBox(height: 8),
                Text(
                    context.t(
                        'Write it down or take a screenshot. With your '
                            'reference ${b.ref} it shows your ride live. '
                            'Do not share it with others.',
                        'Not alın veya ekran görüntüsü alın. ${b.ref} '
                            'referansınızla birlikte yolculuğunuzu canlı '
                            'gösterir. Başkalarıyla paylaşmayın.'),
                    style: const TextStyle(height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/track',
                    arguments: _sent!.token),
                icon: const Icon(Icons.my_location),
                label: Text(context.t('Track my ride', 'Yolculuğumu takip et')),
              ),
              OutlinedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, '/', (_) => false),
                child: Text(context.t('Back to homepage', 'Ana sayfaya dön')),
              ),
              OutlinedButton(
                onPressed: _reset,
                child: Text(context.t('New booking', 'Yeni rezervasyon')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// A card the user can select (used for the transport types).
// Selected = blue border, light blue background and a check mark.
class _SelectCard extends StatelessWidget {
  const _SelectCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.blueSoft : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
            color: selected ? AppColors.blue : AppColors.border,
            width: selected ? 2 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.blue, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(body,
                        style: const TextStyle(
                            height: 1.4, color: AppColors.muted)),
                  ],
                ),
              ),
              Icon(selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? AppColors.blue : AppColors.inputBorder),
            ],
          ),
        ),
      ),
    );
  }
}
