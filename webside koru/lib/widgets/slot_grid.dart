import 'package:flutter/material.dart';

import '../data/schedule.dart';
import '../lang.dart';
import '../theme.dart';

// The 24 one-hour time slots of a day (00:00 to 23:00), live. Each shows
// how many places are left, "Fully booked", "Closed" or that it has passed.
// Picking a full slot (or the chosen one filling up meanwhile) shows a
// message with other open times on the same day.
// Used on the booking form and in the admin's reschedule dialog.
class SlotGrid extends StatefulWidget {
  const SlotGrid({
    super.key,
    required this.day,
    required this.selected,
    required this.onSelected,
    this.heldSlot,
    this.errorText,
  });

  final DateTime day;
  // The chosen hour (null = none yet).
  final int? selected;
  final ValueChanged<int> onSelected;
  // Slot the booking already holds a place in (when rescheduling): its own
  // place counts as free for it.
  final String? heldSlot;
  // Shown under the grid, e.g. "Required".
  final String? errorText;

  @override
  State<SlotGrid> createState() => _SlotGridState();
}

class _SlotGridState extends State<SlotGrid> {
  late Stream<Map<String, Map<String, dynamic>>> _docs =
      scheduleStore.watchDay(widget.day);

  // A full slot the user tapped (to explain why it cannot be picked).
  int? _fullTapped;

  @override
  void didUpdateWidget(SlotGrid old) {
    super.didUpdateWidget(old);
    if (old.day != widget.day) {
      _docs = scheduleStore.watchDay(widget.day);
      _fullTapped = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: scheduleStore,
      builder: (context, _) => StreamBuilder(
        stream: _docs,
        builder: (context, snap) {
          if (snap.hasError) {
            return Text(
                context.t('Could not load the free times. Please call us.',
                    'Müsait saatler yüklenemedi. Lütfen bizi arayın.'),
                style: TextStyle(color: Theme.of(context).colorScheme.error));
          }
          if (!snap.hasData) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final slots = [
            for (final s in scheduleStore.slotsOf(widget.day, snap.data!))
              // The booking's own place is free for it.
              s.id == widget.heldSlot && s.count > 0
                  ? Slot(
                      day: s.day,
                      hour: s.hour,
                      count: s.count - 1,
                      capacity: s.capacity,
                      ownCapacity: s.ownCapacity)
                  : s,
          ];
          return _grid(context, slots);
        },
      ),
    );
  }

  Widget _grid(BuildContext context, List<Slot> slots) {
    // Explain when the tapped slot, or the chosen one, is full.
    final selected = widget.selected == null ? null : slots[widget.selected!];
    final problem = _fullTapped != null
        ? slots[_fullTapped!]
        : (selected != null && !selected.open ? selected : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in slots)
              _SlotTile(
                slot: s,
                selected: s.hour == widget.selected,
                onTap: () {
                  if (s.open) {
                    setState(() => _fullTapped = null);
                    widget.onSelected(s.hour);
                  } else if (s.status == SlotStatus.full ||
                      s.status == SlotStatus.closed) {
                    setState(() => _fullTapped = s.hour);
                  }
                },
              ),
          ],
        ),
        if (widget.errorText != null && problem == null) ...[
          const SizedBox(height: 8),
          Text(widget.errorText!,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error, fontSize: 12)),
        ],
        if (problem != null) ...[
          const SizedBox(height: 14),
          _FullNotice(
            slot: problem,
            alternatives: alternativesFor(slots, problem.hour),
            onPick: (s) {
              setState(() => _fullTapped = null);
              widget.onSelected(s.hour);
            },
          ),
        ],
      ],
    );
  }
}

// One slot: the time and how full it is.
//   Selected: blue.  Open: white.  Full: red.  Closed or past: grey.
class _SlotTile extends StatelessWidget {
  const _SlotTile(
      {required this.slot, required this.selected, required this.onTap});

  final Slot slot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = slot.status;
    final (bg, fg, border) = selected && slot.open
        ? (AppColors.blue, Colors.white, AppColors.blue)
        : switch (status) {
            SlotStatus.available ||
            SlotStatus.booked =>
              (Colors.white, AppColors.text, AppColors.border),
            SlotStatus.full => (
                AppColors.emergencyBg,
                AppColors.emergencyText,
                selected ? AppColors.emergencyText : AppColors.emergencyBg
              ),
            SlotStatus.closed ||
            SlotStatus.past =>
              (AppColors.surface, AppColors.muted, AppColors.surface),
          };
    final note = switch (status) {
      SlotStatus.available || SlotStatus.booked =>
        context.t('${slot.left} left', '${slot.left} yer'),
      _ => status.label(context),
    };

    return Semantics(
      button: true,
      selected: selected,
      label: '${slot.time}, $note',
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          side: BorderSide(color: border, width: selected ? 2 : 1),
        ),
        child: InkWell(
          onTap: status == SlotStatus.past ? null : onTap,
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: SizedBox(
            width: 92,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ExcludeSemantics(
                child: Column(
                  children: [
                    Text(slot.time,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: fg,
                            decoration: status == SlotStatus.past
                                ? TextDecoration.lineThrough
                                : null)),
                    const SizedBox(height: 2),
                    Text(note,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: fg)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// "This time slot is fully booked" with buttons for the nearest open times
// on the same day.
class _FullNotice extends StatelessWidget {
  const _FullNotice(
      {required this.slot, required this.alternatives, required this.onPick});

  final Slot slot;
  final List<Slot> alternatives;
  final ValueChanged<Slot> onPick;

  @override
  Widget build(BuildContext context) {
    final closed = slot.status == SlotStatus.closed;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.emergencyBg,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              closed
                  ? context.t(
                      '${slot.time} is not available. Please choose another '
                          'available time.',
                      '${slot.time} müsait değil. Lütfen başka bir müsait '
                          'saat seçin.')
                  : context.t(
                      'The ${slot.time} time slot is fully booked. Please '
                          'choose another available time.',
                      '${slot.time} saat dilimi tamamen dolu. Lütfen başka '
                          'bir müsait saat seçin.'),
              style: const TextStyle(
                  color: AppColors.emergencyText,
                  fontWeight: FontWeight.w700,
                  height: 1.4)),
          const SizedBox(height: 10),
          if (alternatives.isEmpty)
            Text(
                context.t(
                    'No times are left on this day. Please choose another '
                        'date or call us.',
                    'Bu günde boş saat kalmadı. Lütfen başka bir tarih seçin '
                        'veya bizi arayın.'),
                style: const TextStyle(height: 1.4))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(context.t('Free on this day:', 'Bu gün boş olanlar:')),
                for (final s in alternatives)
                  ActionChip(
                    label: Text(s.time),
                    onPressed: () => onPick(s),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
