import 'package:flutter/material.dart';

import '../data/bookings.dart';
import '../data/feedback.dart';
import '../lang.dart';
import '../theme.dart';
import '../widgets/common.dart';

// "Overview" section of the admin dashboard: how many patients rode today,
// yesterday and this month, a day-by-day chart, what kind of transport they
// needed, which branches they went to, and the rides coming up.
// Counts use the ride date (the day the patient is picked up).
class AdminOverview extends StatefulWidget {
  const AdminOverview({super.key, required this.onOpenStage});

  // Opens the bookings section on one stage tab.
  final ValueChanged<Stage> onOpenStage;

  @override
  State<AdminOverview> createState() => _AdminOverviewState();
}

class _AdminOverviewState extends State<AdminOverview> {
  // The month shown in the chart and the breakdowns (first day of it).
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  // Bookings whose ride is on [day].
  List<Booking> _on(DateTime day) =>
      bookingStore.bookings.where((b) => _day(b.date) == day).toList();

  // Bookings whose ride is in the month that starts on [month].
  List<Booking> _inMonth(DateTime month) => bookingStore.bookings
      .where((b) => b.date.year == month.year && b.date.month == month.month)
      .toList();

  String _monthName(DateTime m) {
    const names = [
      ('January', 'Ocak'),
      ('February', 'Şubat'),
      ('March', 'Mart'),
      ('April', 'Nisan'),
      ('May', 'Mayıs'),
      ('June', 'Haziran'),
      ('July', 'Temmuz'),
      ('August', 'Ağustos'),
      ('September', 'Eylül'),
      ('October', 'Ekim'),
      ('November', 'Kasım'),
      ('December', 'Aralık'),
    ];
    final (en, tr) = names[m.month - 1];
    return '${context.t(en, tr)} ${m.year}';
  }

  @override
  Widget build(BuildContext context) {
    final today = _day(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    final thisMonth = DateTime(today.year, today.month);
    final lastMonth = DateTime(today.year, today.month - 1);

    final todayCount = _on(today).length;
    final yesterdayCount = _on(yesterday).length;
    final dayBefore = _on(today.subtract(const Duration(days: 2))).length;
    final monthCount = _inMonth(thisMonth).length;
    final lastMonthCount = _inMonth(lastMonth).length;

    final waiting =
        bookingStore.bookings.where((b) => b.stage == Stage.newRequest).length;
    final todayNotReady =
        _on(today).where((b) => b.stage != Stage.arranged).length;

    final selected = _inMonth(_month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.t('Overview', 'Genel bakış'),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
        Text(
            '${context.t('Today', 'Bugün')}: ${formatDate(today)}  ·  '
            '${context.t('Patients are counted by ride date.', 'Hastalar yolculuk tarihine göre sayılır.')}',
            style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 24),

        // Headline numbers.
        ResponsiveGrid(
          desktopColumns: 4,
          tabletColumns: 2,
          spacing: 16,
          children: [
            _StatTile(
              icon: Icons.today_outlined,
              label: context.t('Patients today', 'Bugünkü hastalar'),
              value: '$todayCount',
              note: context.t('$todayNotReady not arranged yet',
                  '$todayNotReady henüz hazır değil'),
              noteColor: todayNotReady > 0 ? AppColors.emergencyText : null,
            ),
            _StatTile(
              icon: Icons.history,
              label: context.t('Yesterday', 'Dün'),
              value: '$yesterdayCount',
              change: _Change(yesterdayCount, dayBefore,
                  context.t('vs. the day before', 'önceki güne göre')),
            ),
            _StatTile(
              icon: Icons.calendar_month_outlined,
              label: context.t('This month', 'Bu ay'),
              value: '$monthCount',
              change: _Change(monthCount, lastMonthCount,
                  context.t('vs. last month', 'geçen aya göre')),
            ),
            _StatTile(
              icon: Icons.star_outline,
              label: context.t('Patient rating', 'Hasta puanı'),
              value: feedbackStore.items.isEmpty
                  ? '—'
                  : feedbackStore.averageRating.toStringAsFixed(1),
              note: context.t('${feedbackStore.items.length} comments',
                  '${feedbackStore.items.length} yorum'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Things that need a coordinator now.
        if (waiting > 0 || todayNotReady > 0)
          _Card(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.notifications_active_outlined,
                    color: AppColors.emergencyText),
                Text(context.t('Needs attention', 'İlgilenilmesi gerekenler'),
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                if (waiting > 0)
                  ActionChip(
                    label: Text(context.t('$waiting new requests to confirm',
                        '$waiting yeni talep onay bekliyor')),
                    onPressed: () => widget.onOpenStage(Stage.newRequest),
                  ),
                if (todayNotReady > 0)
                  ActionChip(
                    label: Text(context.t(
                        '$todayNotReady rides today without a driver',
                        'Bugün $todayNotReady yolculuğun sürücüsü yok')),
                    onPressed: () => widget.onOpenStage(Stage.reserved),
                  ),
              ],
            ),
          ),
        if (waiting > 0 || todayNotReady > 0) const SizedBox(height: 16),

        // Day-by-day chart for the chosen month.
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            context.t(
                                'Patients per day', 'Günlük hasta sayısı'),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        Text(
                            context.t('${selected.length} patients in total',
                                'Toplam ${selected.length} hasta'),
                            style: const TextStyle(color: AppColors.muted)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: context.t('Previous month', 'Önceki ay'),
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(
                        () => _month = DateTime(_month.year, _month.month - 1)),
                  ),
                  Text(_monthName(_month),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  IconButton(
                    tooltip: context.t('Next month', 'Sonraki ay'),
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => setState(
                        () => _month = DateTime(_month.year, _month.month + 1)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _DailyChart(month: _month, bookings: selected, today: today),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // What kind of transport, which branch, which extra help.
        ResponsiveGrid(
          desktopColumns: 3,
          tabletColumns: 2,
          spacing: 16,
          children: [
            _Breakdown(
              title: context.t('Transport type', 'Ulaşım türü'),
              rows: [
                for (final t in TransportType.values)
                  (
                    t.icon,
                    t.label(context),
                    selected.where((b) => b.type == t).length
                  ),
              ],
              total: selected.length,
            ),
            _Breakdown(
              title: context.t('Branch', 'Şube'),
              rows: [
                for (final br in branches)
                  (
                    Icons.local_hospital_outlined,
                    br,
                    selected.where((b) => b.branch == br).length
                  ),
              ],
              total: selected.length,
            ),
            _Breakdown(
              title: context.t('Extra help needed', 'Ek ihtiyaçlar'),
              rows: [
                for (final n in MobilityNeed.values)
                  (
                    Icons.medical_services_outlined,
                    n.label(context),
                    selected.where((b) => b.needs.contains(n)).length
                  ),
              ],
              total: selected.length,
            ),
          ],
        ),
        const SizedBox(height: 16),

        _Upcoming(today: today, onOpenStage: widget.onOpenStage),
      ],
    );
  }
}

// White rounded card used by every block on this page.
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: child,
      );
}

// Change between two periods, e.g. +25% vs. last month.
class _Change {
  const _Change(this.now, this.before, this.label);

  final int now;
  final int before;
  final String label;
}

// One headline number with an icon and an optional note or change.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.note,
    this.noteColor,
    this.change,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? note;
  final Color? noteColor;
  final _Change? change;

  @override
  Widget build(BuildContext context) {
    Widget? bottom;
    if (change != null) {
      final c = change!;
      final diff = c.now - c.before;
      final up = diff >= 0;
      // Percent only makes sense when there was something before.
      final text = c.before == 0
          ? (c.now == 0 ? '0' : '+${c.now}')
          : '${up ? '+' : ''}${(diff / c.before * 100).round()}%';
      final color = diff == 0
          ? AppColors.muted
          : up
              ? AppColors.success
              : AppColors.emergencyText;
      bottom = Row(
        children: [
          Icon(
              diff == 0
                  ? Icons.trending_flat
                  : up
                      ? Icons.trending_up
                      : Icons.trending_down,
              size: 18,
              color: color),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(color: color, fontWeight: FontWeight.w800)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(c.label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          ),
        ],
      );
    } else if (note != null) {
      bottom = Text(note!,
          style: TextStyle(
              color: noteColor ?? AppColors.muted,
              fontSize: 13,
              fontWeight: noteColor != null ? FontWeight.w700 : null));
    }

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppColors.blueSoft,
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 20, color: AppColors.blue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.muted)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style:
                  const TextStyle(fontSize: 36, fontWeight: FontWeight.w800)),
          if (bottom != null) bottom,
        ],
      ),
    );
  }
}

// Bar chart: one bar per day of the month, height = number of patients.
// Hover or long-press a bar to see the exact number.
class _DailyChart extends StatelessWidget {
  const _DailyChart(
      {required this.month, required this.bookings, required this.today});

  final DateTime month;
  final List<Booking> bookings;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final counts = List.filled(days, 0);
    for (final b in bookings) {
      counts[b.date.day - 1]++;
    }
    final max = counts.fold(0, (a, b) => a > b ? a : b);
    // Round the top of the scale up so the bars never touch the top.
    final top = max < 4 ? 4 : max + (max / 4).ceil();
    const height = 180.0;

    return Column(
      children: [
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Scale on the left: top, middle and zero.
              SizedBox(
                width: 28,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final v in [top, top ~/ 2, 0])
                      Text('$v',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.muted)),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < days; i++)
                      Expanded(
                        child: Tooltip(
                          message:
                              '${formatDate(DateTime(month.year, month.month, i + 1))}: '
                              '${context.t('${counts[i]} patients', '${counts[i]} hasta')}',
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                // Days without patients still show a thin line.
                                height: counts[i] == 0
                                    ? 2
                                    : height * counts[i] / top,
                                decoration: BoxDecoration(
                                  color: DateTime(
                                              month.year, month.month, i + 1) ==
                                          today
                                      ? AppColors.gold
                                      : counts[i] == 0
                                          ? AppColors.border
                                          : AppColors.blue,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Day numbers under the bars (every 5th day, to keep it readable).
        Row(
          children: [
            const SizedBox(width: 28),
            for (var i = 0; i < days; i++)
              Expanded(
                child: Text(i == 0 || (i + 1) % 5 == 0 ? '${i + 1}' : '',
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(fontSize: 11, color: AppColors.muted)),
              ),
          ],
        ),
      ],
    );
  }
}

// List of categories with a count and a bar showing the share of the total.
class _Breakdown extends StatelessWidget {
  const _Breakdown(
      {required this.title, required this.rows, required this.total});

  final String title;
  final List<(IconData, String, int)> rows;
  final int total;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          for (final (icon, label, count) in rows) ...[
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.blue),
                const SizedBox(width: 8),
                Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
                Text('$count',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                SizedBox(
                  width: 48,
                  child: Text(
                      total == 0 ? '' : '${(count / total * 100).round()}%',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : count / total,
                minHeight: 6,
                backgroundColor: AppColors.surface,
                color: AppColors.blue,
              ),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

// Rides today and tomorrow, in time order, with their stage.
class _Upcoming extends StatelessWidget {
  const _Upcoming({required this.today, required this.onOpenStage});

  final DateTime today;
  final ValueChanged<Stage> onOpenStage;

  @override
  Widget build(BuildContext context) {
    final tomorrow = today.add(const Duration(days: 1));
    final rides = bookingStore.bookings.where((b) {
      final d = DateTime(b.date.year, b.date.month, b.date.day);
      return d == today || d == tomorrow;
    }).toList()
      ..sort((a, b) {
        final byDay = a.date.compareTo(b.date);
        if (byDay != 0) return byDay;
        return (a.time.hour * 60 + a.time.minute)
            .compareTo(b.time.hour * 60 + b.time.minute);
      });

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.t('Upcoming rides', 'Yaklaşan yolculuklar'),
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text(context.t('Today and tomorrow', 'Bugün ve yarın'),
              style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 12),
          if (rides.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                  context.t('No rides planned.', 'Planlanmış yolculuk yok.'),
                  style: const TextStyle(color: AppColors.muted)),
            ),
          for (final b in rides)
            ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () => onOpenStage(b.stage),
              leading: CircleAvatar(
                backgroundColor: AppColors.blueSoft,
                child: Icon(b.type.icon, color: AppColors.blue, size: 20),
              ),
              title: Text('${formatTime(b.time)}  ·  ${b.patient}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                  '${DateTime(b.date.year, b.date.month, b.date.day) == today ? context.t('Today', 'Bugün') : context.t('Tomorrow', 'Yarın')}'
                  '  ·  ${b.ref}  ·  ${b.from} → ${b.branch}',
                  overflow: TextOverflow.ellipsis),
              trailing: _StageBadge(b.stage),
            ),
        ],
      ),
    );
  }
}

// Small colored label with the booking's stage.
class _StageBadge extends StatelessWidget {
  const _StageBadge(this.stage);

  final Stage stage;

  @override
  Widget build(BuildContext context) {
    final color = switch (stage) {
      Stage.newRequest => AppColors.emergencyText,
      Stage.confirmed => AppColors.gold,
      Stage.reserved => AppColors.blue,
      Stage.arranged => AppColors.success,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(stage.label(context),
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
