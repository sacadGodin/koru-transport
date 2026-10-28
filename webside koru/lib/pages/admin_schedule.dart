import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/bookings.dart';
import '../data/schedule.dart';
import '../lang.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/slot_grid.dart';
import 'admin_overview.dart';

// Schedule section of the admin dashboard: one day at a time, the 24
// one-hour slots with how many bookings each has out of how many it takes
// (Available / Booked / Fully booked / Closed), and who booked each slot
// and when. The admin sets how many bookings a slot takes, for every slot
// or for one slot, and can reschedule, cancel or call each booking.
class AdminSchedule extends StatefulWidget {
  const AdminSchedule({super.key});

  @override
  State<AdminSchedule> createState() => _AdminScheduleState();
}

class _AdminScheduleState extends State<AdminSchedule> {
  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // The day shown.
  DateTime _day = _today();
  late Stream<Map<String, Map<String, dynamic>>> _docs =
      scheduleStore.watchDay(_day);

  void _show(DateTime day) => setState(() {
        _day = DateTime(day.year, day.month, day.day);
        _docs = scheduleStore.watchDay(_day);
      });

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2020),
      lastDate: _today().add(const Duration(days: 730)),
    );
    if (picked != null) _show(picked);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: scheduleStore,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.t('Schedule', 'Takvim'),
              style:
                  const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
          Text(
              context.t(
                  'Bookings by day and hour. A full hour cannot be booked '
                      'on the website.',
                  'Gün ve saate göre rezervasyonlar. Dolu bir saat sitede '
                      'rezerve edilemez.'),
              style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [_dayPicker(), _capacityCard()],
          ),
          const SizedBox(height: 20),
          StreamBuilder(
            stream: _docs,
            builder: (context, snap) {
              if (snap.hasError) {
                return Text(context.t('Could not load the schedule.',
                    'Takvim yüklenemedi.'));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final slots = scheduleStore.slotsOf(_day, snap.data!);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legend(slots),
                  const SizedBox(height: 16),
                  for (final s in slots) _SlotRow(slot: s),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // < [date] >  Today
  Widget _dayPicker() {
    final isToday = _day == _today();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: context.t('Previous day', 'Önceki gün'),
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _show(_day.subtract(const Duration(days: 1))),
          ),
          TextButton.icon(
            onPressed: _pickDay,
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text(formatDate(_day),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
          ),
          IconButton(
            tooltip: context.t('Next day', 'Sonraki gün'),
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _show(_day.add(const Duration(days: 1))),
          ),
          if (!isToday)
            TextButton(
              onPressed: () => _show(_today()),
              child: Text(context.t('Today', 'Bugün')),
            ),
        ],
      ),
    );
  }

  // "Bookings per hour: 3  [Change]"
  Widget _capacityCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.t('Bookings per hour:', 'Saat başına rezervasyon:'),
              style: const TextStyle(color: AppColors.muted)),
          const SizedBox(width: 8),
          Text('${scheduleStore.defaultCapacity}',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () async {
              final n = await _askNumber(context,
                  title: context.t(
                      'Bookings per hour', 'Saat başına rezervasyon'),
                  help: context.t(
                      'How many rides can start in the same hour, for every '
                          'hour that has no number of its own.',
                      'Kendi sayısı olmayan her saat için, aynı saatte '
                          'kaç yolculuk başlayabilir.'),
                  initial: scheduleStore.defaultCapacity,
                  min: 1);
              if (n == null || !mounted) return;
              final ok = await scheduleStore.setDefaultCapacity(n);
              if (!ok && mounted) showSaveError(context, 'failed');
            },
            child: Text(context.t('Change', 'Değiştir')),
          ),
        ],
      ),
    );
  }

  // How many slots of the day are in each state, with their colors.
  Widget _legend(List<Slot> slots) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        for (final status in [
          SlotStatus.available,
          SlotStatus.booked,
          SlotStatus.full,
          SlotStatus.closed
        ])
          _StatusChip(status,
              count: slots.where((s) => s.status == status).length),
      ],
    );
  }
}

// One hour: status, places used, the slot's own limit, and its bookings.
class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.slot});

  final Slot slot;

  @override
  Widget build(BuildContext context) {
    final bookings = bookingStore.bookings
        .where((b) => slotOf(b) == slot.id)
        .toList()
      ..sort((a, b) => (a.time.minute).compareTo(b.time.minute));
    final status = slot.status;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(
        color: status == SlotStatus.past ? AppColors.surface : Colors.white,
        border: Border.all(
            color: status == SlotStatus.full
                ? AppColors.emergencyText
                : AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 64,
                child: Text(slot.time,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _StatusChip(slot.isPast && slot.count == 0
                        ? SlotStatus.past
                        : _bookedStatus(slot)),
                    // Places used out of the limit.
                    SizedBox(
                      width: 120,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${slot.count} / ${slot.capacity} '
                              '${context.t('booked', 'dolu')}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: slot.capacity == 0
                                ? 1
                                : (slot.count / slot.capacity).clamp(0, 1),
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                            backgroundColor: AppColors.surface,
                            color: slot.count >= slot.capacity
                                ? AppColors.emergencyText
                                : AppColors.blue,
                          ),
                        ],
                      ),
                    ),
                    if (slot.ownCapacity != null)
                      Text(
                          context.t('Own limit for this hour',
                              'Bu saate özel sınır'),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.muted)),
                  ],
                ),
              ),
              _SlotMenu(slot: slot),
            ],
          ),
          for (final b in bookings) _BookingLine(b),
        ],
      ),
    );
  }

  // Past hours still show whether they were full.
  static SlotStatus _bookedStatus(Slot s) => s.capacity == 0
      ? SlotStatus.closed
      : s.count >= s.capacity
          ? SlotStatus.full
          : s.count > 0
              ? SlotStatus.booked
              : SlotStatus.available;
}

// ⋮ menu of a slot: give it its own limit, close it, or use the default.
class _SlotMenu extends StatelessWidget {
  const _SlotMenu({required this.slot});

  final Slot slot;

  @override
  Widget build(BuildContext context) {
    Future<void> set(int? capacity) async {
      final ok = await scheduleStore.setSlotCapacity(slot, capacity);
      if (!ok && context.mounted) showSaveError(context, 'failed');
    }

    return PopupMenuButton<String>(
      tooltip: context.t('Change this hour', 'Bu saati değiştir'),
      onSelected: (action) async {
        switch (action) {
          case 'limit':
            final n = await _askNumber(context,
                title: '${slot.time} · '
                    '${context.t('Bookings this hour', 'Bu saatteki rezervasyon')}',
                help: context.t(
                    'Only for ${formatDate(slot.day)} ${slot.time}. Bookings '
                        'already made stay.',
                    'Yalnızca ${formatDate(slot.day)} ${slot.time} için. '
                        'Yapılmış rezervasyonlar kalır.'),
                initial: slot.capacity,
                min: 0);
            if (n != null) await set(n);
          case 'close':
            await set(0);
          case 'default':
            await set(null);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
            value: 'limit',
            child: Text(context.t(
                'Set a limit for this hour', 'Bu saat için sınır belirle'))),
        if (slot.capacity != 0)
          PopupMenuItem(
              value: 'close',
              child: Text(context.t(
                  'Close this hour (no new bookings)',
                  'Bu saati kapat (yeni rezervasyon yok)'))),
        if (slot.ownCapacity != null)
          PopupMenuItem(
              value: 'default',
              child: Text(context.t(
                  'Use the usual limit (${scheduleStore.defaultCapacity})',
                  'Genel sınırı kullan (${scheduleStore.defaultCapacity})'))),
      ],
    );
  }
}

// One booking in a slot: who, how to reach them, its stage, when it was
// made, and buttons to reschedule or cancel it.
class _BookingLine extends StatelessWidget {
  const _BookingLine(this.b);

  final Booking b;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 64, top: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(b.type.icon, size: 18, color: AppColors.blue),
          Text('${formatTime(b.time)}  ${b.ref}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(b.patient, style: const TextStyle(fontWeight: FontWeight.w700)),
          InkWell(
            onTap: () => openLink('tel:${b.phone}'),
            child: Text(b.phone,
                style: TextStyle(
                    color: AppColors.blue, fontWeight: FontWeight.w700)),
          ),
          Text('${b.from} → ${b.branch}',
              style: const TextStyle(color: AppColors.muted)),
          StageBadge(b.stage),
          if (b.createdAt != null)
            Text(
                context.t(
                    'Booked ${formatDate(b.createdAt!)} '
                        '${formatTime(TimeOfDay.fromDateTime(b.createdAt!))}',
                    '${formatDate(b.createdAt!)} '
                        '${formatTime(TimeOfDay.fromDateTime(b.createdAt!))} '
                        'tarihinde alındı'),
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          BookingMenu(b),
        ],
      ),
    );
  }
}

// Colored label for a slot state, optionally with how many slots.
class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status, {this.count});

  final SlotStatus status;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      SlotStatus.available => AppColors.success,
      SlotStatus.booked => AppColors.blue,
      SlotStatus.full => AppColors.emergencyText,
      SlotStatus.closed || SlotStatus.past => AppColors.muted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
          count == null
              ? status.label(context)
              : '${status.label(context)}: $count',
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

// ⋮ menu of a booking: reschedule, cancel or restore, call the patient.
// Used in the schedule and in the bookings table.
class BookingMenu extends StatelessWidget {
  const BookingMenu(this.booking, {super.key});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final cancelled = b.stage == Stage.cancelled;
    return PopupMenuButton<String>(
      tooltip: context.t('More', 'Diğer'),
      onSelected: (action) async {
        switch (action) {
          case 'reschedule':
            await rescheduleBooking(context, b);
          case 'cancel':
            await cancelBooking(context, b);
          case 'restore':
            final error = await bookingStore.restore(b);
            if (context.mounted) showSaveError(context, error);
          case 'call':
            await openLink('tel:${b.phone}');
        }
      },
      itemBuilder: (context) => [
        if (!cancelled) ...[
          PopupMenuItem(
              value: 'reschedule',
              child: Text(context.t('Reschedule', 'Yeniden planla'))),
          PopupMenuItem(
              value: 'cancel',
              child: Text(context.t('Cancel booking', 'Rezervasyonu iptal et'))),
        ] else
          PopupMenuItem(
              value: 'restore',
              child: Text(context.t('Restore as new request',
                  'Yeni talep olarak geri al'))),
        PopupMenuItem(
            value: 'call',
            child: Text(
                '${context.t('Call patient', 'Hastayı ara')} (${b.phone})')),
      ],
    );
  }
}

// Message for a booking change that could not be saved (nothing for null).
void showSaveError(BuildContext context, String? error) {
  if (error == null) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error == 'slot-full'
          ? context.t(
              'That time slot is fully booked. Choose another time, or raise '
                  'the limit for that hour in Schedule.',
              'Bu saat dilimi tamamen dolu. Başka bir saat seçin veya '
                  'Takvim\'den o saatin sınırını artırın.')
          : context.t('Could not save. Please try again.',
              'Kaydedilemedi. Lütfen tekrar deneyin.'))));
}

// Asks first, then cancels the booking and frees its place.
Future<void> cancelBooking(BuildContext context, Booking b) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('${context.t('Cancel booking', 'Rezervasyonu iptal et')} '
          '${b.ref}'),
      content: Text(context.t(
          '${b.patient}, ${formatDate(b.date)} ${formatTime(b.time)}. The '
              'time slot is freed and the patient sees "Cancelled" on the '
              'tracking page. Please also call them on ${b.phone}.',
          '${b.patient}, ${formatDate(b.date)} ${formatTime(b.time)}. Saat '
              'dilimi boşaltılır ve hasta takip sayfasında "İptal edildi" '
              'görür. Lütfen ${b.phone} numarasından hastayı da arayın.')),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.t('Keep booking', 'Rezervasyonu koru'))),
        FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.t('Cancel booking', 'İptal et'))),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  final error = await bookingStore.cancel(b);
  if (context.mounted) showSaveError(context, error);
}

// Lets the admin pick another day and free hour, then moves the booking.
Future<void> rescheduleBooking(BuildContext context, Booking b) async {
  final picked = await showDialog<(DateTime, int)>(
      context: context, builder: (_) => _RescheduleDialog(b));
  if (picked == null || !context.mounted) return;
  final (date, hour) = picked;
  final error = await bookingStore.reschedule(
      b, date, TimeOfDay(hour: hour, minute: 0));
  if (context.mounted) showSaveError(context, error);
}

class _RescheduleDialog extends StatefulWidget {
  const _RescheduleDialog(this.booking);

  final Booking booking;

  @override
  State<_RescheduleDialog> createState() => _RescheduleDialogState();
}

class _RescheduleDialogState extends State<_RescheduleDialog> {
  late DateTime _date = widget.booking.date;
  int? _hour;

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    return AlertDialog(
      title: Text('${context.t('Reschedule', 'Yeniden planla')} ${b.ref}'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                  context.t(
                      'Now: ${formatDate(b.date)} ${formatTime(b.time)}. '
                          'The patient sees the new time on the tracking '
                          'page; please also call them on ${b.phone}.',
                      'Şu an: ${formatDate(b.date)} ${formatTime(b.time)}. '
                          'Hasta yeni saati takip sayfasında görür; lütfen '
                          '${b.phone} numarasından da arayın.'),
                  style: const TextStyle(color: AppColors.muted, height: 1.4)),
              const SizedBox(height: 16),
              FieldLabel(
                context.t('Date', 'Tarih'),
                child: PickerField(
                  value: formatDate(_date),
                  hint: '',
                  icon: Icons.calendar_today_outlined,
                  onTap: () async {
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final picked = await showDatePicker(
                        context: context,
                        initialDate: _date.isBefore(today) ? today : _date,
                        firstDate: today,
                        lastDate: today.add(const Duration(days: 365)));
                    if (picked != null && picked != _date) {
                      setState(() {
                        _date = picked;
                        _hour = null;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 14),
              FieldLabel(
                context.t('New time', 'Yeni saat'),
                child: SlotGrid(
                  day: _date,
                  selected: _hour,
                  heldSlot: b.slot,
                  onSelected: (h) => setState(() => _hour = h),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.t('Back', 'Geri'))),
        FilledButton(
            onPressed:
                _hour == null ? null : () => Navigator.pop(context, (_date, _hour!)),
            child: Text(context.t('Move booking', 'Rezervasyonu taşı'))),
      ],
    );
  }
}

// Small dialog asking for a whole number (a slot limit).
Future<int?> _askNumber(BuildContext context,
        {required String title,
        required String help,
        required int initial,
        required int min}) =>
    showDialog<int>(
        context: context,
        builder: (_) => _NumberDialog(
            title: title, help: help, initial: initial, min: min));

class _NumberDialog extends StatefulWidget {
  const _NumberDialog(
      {required this.title,
      required this.help,
      required this.initial,
      required this.min});

  final String title;
  final String help;
  final int initial;
  // Smallest number allowed (the largest is 50, as in firestore.rules).
  final int min;

  @override
  State<_NumberDialog> createState() => _NumberDialogState();
}

class _NumberDialogState extends State<_NumberDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _number = TextEditingController(text: '${widget.initial}');

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  void _done() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, int.parse(_number.text.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.help,
                  style: const TextStyle(color: AppColors.muted, height: 1.4)),
              const SizedBox(height: 14),
              TextFormField(
                controller: _number,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onFieldSubmitted: (_) => _done(),
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  return n == null || n < widget.min || n > 50
                      ? context.t('A number from ${widget.min} to 50',
                          '${widget.min} ile 50 arasında bir sayı')
                      : null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.t('Cancel', 'İptal'))),
        FilledButton(
            onPressed: _done, child: Text(context.t('Save', 'Kaydet'))),
      ],
    );
  }
}
