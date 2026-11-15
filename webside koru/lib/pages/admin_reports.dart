import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/bookings.dart';
import '../data/reports.dart';
import '../lang.dart';
import '../theme.dart';
import '../widgets/common.dart';

// Monthly report for the admin: how many people were served, airport
// rides in both directions, transport types and branches, with a
// printable / downloadable PDF. Counts every booking whose ride is in the
// month; cancelled ones are counted apart and not in the totals.
class AdminReports extends StatefulWidget {
  const AdminReports({super.key});

  @override
  State<AdminReports> createState() => _AdminReportsState();
}

class _AdminReportsState extends State<AdminReports> {
  // In the first days of a month, start on the month that just ended
  // (the end-of-month report); otherwise on the current month.
  DateTime _month = () {
    final now = DateTime.now();
    return DateTime(now.year, now.day <= 7 ? now.month - 1 : now.month);
  }();

  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final report = MonthReport(_month, bookingStore.bookings);
    final year = lastTwelveMonths(_month, bookingStore.bookings);
    final narrow = Responsive.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Month picker and the print / download buttons.
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: context.t('Previous month', 'Önceki ay'),
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(
                      () => _month = DateTime(_month.year, _month.month - 1)),
                ),
                Text(monthName(_month, context.t),
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800)),
                IconButton(
                  tooltip: context.t('Next month', 'Sonraki ay'),
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(
                      () => _month = DateTime(_month.year, _month.month + 1)),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed:
                      _busy ? null : () => _pdf(report, year, print: true),
                  icon: const Icon(Icons.print_outlined),
                  label: Text(context.t('Print report', 'Raporu yazdır')),
                ),
                OutlinedButton.icon(
                  onPressed:
                      _busy ? null : () => _pdf(report, year, print: false),
                  icon: const Icon(Icons.download_outlined),
                  label: Text(context.t('Download PDF', 'PDF indir')),
                ),
              ],
            ),
          ],
        ),
        if (report.inProgress)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(
                context.t(
                    'This month is not over yet, so the numbers can still '
                        'change. Print the final report after the month ends.',
                    'Bu ay henüz bitmedi, sayılar değişebilir. Kesin raporu '
                        'ay bittikten sonra yazdırın.'),
                style: const TextStyle(color: AppColors.muted)),
          ),
        const SizedBox(height: 16),

        // Headline numbers.
        ResponsiveGrid(
          desktopColumns: 4,
          tabletColumns: 2,
          spacing: 16,
          children: [
            _Stat(
                icon: Icons.groups_outlined,
                value: '${report.total.people}',
                label: context.t('People served', 'Hizmet verilen kişi')),
            _Stat(
                icon: Icons.event_note_outlined,
                value: '${report.total.bookings}',
                label: context.t('Bookings', 'Rezervasyon')),
            _Stat(
                icon: Icons.check_circle_outline,
                value: '${report.total.completed}',
                label: context.t('Trips completed', 'Tamamlanan yolculuk')),
            _Stat(
                icon: Icons.cancel_outlined,
                value: '${report.cancelled}',
                label: context.t('Cancelled', 'İptal edilen')),
          ],
        ),
        const SizedBox(height: 16),

        // The two airport directions side by side.
        ResponsiveGrid(
          desktopColumns: 2,
          tabletColumns: 2,
          spacing: 16,
          children: [
            _AirportCard(
                icon: Icons.flight_land,
                title: TransportType.airport.label(context),
                count: report.airportToHospital),
            _AirportCard(
                icon: Icons.flight_takeoff,
                title: TransportType.toAirport.label(context),
                count: report.hospitalToAirport),
          ],
        ),
        const SizedBox(height: 16),

        ResponsiveGrid(
          desktopColumns: 2,
          tabletColumns: 1,
          spacing: 16,
          children: [
            _Panel(
              title: context.t('By transport type', 'Ulaşım tipine göre'),
              child: _Table(
                head: [
                  context.t('Type', 'Tip'),
                  context.t('Bookings', 'Rez.'),
                  context.t('People', 'Kişi'),
                ],
                rows: [
                  for (final t in TransportType.values)
                    [
                      t.label(context),
                      '${report.byType[t]?.bookings ?? 0}',
                      '${report.byType[t]?.people ?? 0}',
                    ],
                ],
              ),
            ),
            _Panel(
              title: context.t('By branch', 'Şubeye göre'),
              child: _Table(
                head: [
                  context.t('Branch', 'Şube'),
                  context.t('Bookings', 'Rez.'),
                  context.t('People', 'Kişi'),
                ],
                rows: [
                  for (final br in {...branches, ...report.byBranch.keys})
                    [
                      br,
                      '${report.byBranch[br]?.bookings ?? 0}',
                      '${report.byBranch[br]?.people ?? 0}',
                    ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _Panel(
          title: context.t('Last 12 months', 'Son 12 ay'),
          child: _Table(
            head: [
              context.t('Month', 'Ay'),
              context.t('People', 'Kişi'),
              if (!narrow) context.t('Bookings', 'Rez.'),
              narrow
                  ? context.t('Airport→H.', 'Hav.→Hast.')
                  : TransportType.airport.label(context),
              narrow
                  ? context.t('H.→Airport', 'Hast.→Hav.')
                  : TransportType.toAirport.label(context),
            ],
            rows: [
              for (final m in year.reversed)
                [
                  monthName(m.month, context.t),
                  '${m.total.people}',
                  if (!narrow) '${m.total.bookings}',
                  '${m.airportToHospital.people}',
                  '${m.hospitalToAirport.people}',
                ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
            context.t(
                'People = passengers on bookings that were not cancelled, the '
                    'patient included. Bookings are counted in the month of '
                    'their ride date.',
                'Kişi = iptal edilmeyen rezervasyonlardaki yolcular (hasta '
                    'dahil). Rezervasyonlar yolculuk tarihinin ayında sayılır.'),
            style: const TextStyle(color: AppColors.muted, fontSize: 13)),
      ],
    );
  }

  // Builds the PDF, then opens the print dialog or downloads it.
  Future<void> _pdf(MonthReport report, List<MonthReport> year,
      {required bool print}) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.t('Could not create the report. Please try again.',
        'Rapor oluşturulamadı. Lütfen tekrar deneyin.');
    final texts = _PdfTexts.of(context);
    final name = 'koru-transport-report-'
        '${report.month.year}-${report.month.month.toString().padLeft(2, '0')}';
    setState(() => _busy = true);
    try {
      final bytes = await _buildMonthReportPdf(report, year, texts);
      if (print) {
        await Printing.layoutPdf(onLayout: (_) async => bytes, name: name);
      } else {
        await Printing.sharePdf(bytes: bytes, filename: '$name.pdf');
      }
    } catch (e) {
      debugPrint('Report PDF failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

// Every text the PDF needs, in the current language (the PDF is built
// away from the widget tree).
class _PdfTexts {
  _PdfTexts(this.t, this.types, this.stages, this.completed);

  factory _PdfTexts.of(BuildContext context) => _PdfTexts(
        context.t,
        {for (final t in TransportType.values) t: t.label(context)},
        {for (final s in Stage.values) s: s.label(context)},
        TripStatus.completed.label(context),
      );

  final String Function(String en, String tr) t;
  final Map<TransportType, String> types;
  final Map<Stage, String> stages;
  final String completed;
}

// The printable monthly report (A4).
Future<Uint8List> _buildMonthReportPdf(
    MonthReport report, List<MonthReport> year, _PdfTexts x) async {
  final t = x.t;
  // A font with Turkish letters (ş, ğ, ı, İ).
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(
      base: await PdfGoogleFonts.notoSansRegular(),
      bold: await PdfGoogleFonts.notoSansBold(),
    ),
  );
  const navy = PdfColor.fromInt(0xFF0B2A4A);
  const grey = PdfColor.fromInt(0xFF52627A);

  pw.Widget heading(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 16, bottom: 6),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: 13, fontWeight: pw.FontWeight.bold, color: navy)),
      );

  pw.Widget table(List<String> head, List<List<String>> rows) =>
      pw.TableHelper.fromTextArray(
        headers: head,
        data: rows,
        headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            fontSize: 9),
        headerDecoration: const pw.BoxDecoration(color: navy),
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellAlignments: {
          for (var i = 1; i < head.length; i++) i: pw.Alignment.centerRight
        },
        cellAlignment: pw.Alignment.centerLeft,
        oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
        border: null,
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      );

  pw.Widget stat(String value, String label) => pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.only(right: 8),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(6)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(value,
                  style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: navy)),
              pw.Text(label,
                  style: const pw.TextStyle(fontSize: 9, color: grey)),
            ],
          ),
        ),
      );

  String status(Booking b) =>
      b.trip == TripStatus.completed ? x.completed : x.stages[b.stage]!;

  final month = monthName(report.month, t);
  final now = DateTime.now();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      header: (ctx) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 8),
        decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: navy, width: 1.5))),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(t('Koru Hospital Transport', 'Koru Hastanesi Ulaşım'),
                    style: const pw.TextStyle(fontSize: 10, color: grey)),
                pw.Text(t('Monthly report: $month', 'Aylık rapor: $month'),
                    style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: navy)),
              ],
            ),
            pw.Text(
                '${t('Printed', 'Yazdırıldı')}: ${formatDate(now)} '
                '${formatTime(TimeOfDay.fromDateTime(now))}',
                style: const pw.TextStyle(fontSize: 9, color: grey)),
          ],
        ),
      ),
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
            '${t('Page', 'Sayfa')} ${ctx.pageNumber} / ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: grey)),
      ),
      build: (ctx) => [
        if (report.inProgress)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 8),
            child: pw.Text(
                t('Month not finished yet: numbers can still change.',
                    'Ay henüz bitmedi: sayılar değişebilir.'),
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.red800)),
          ),
        pw.SizedBox(height: 12),
        pw.Row(children: [
          stat('${report.total.people}',
              t('People served', 'Hizmet verilen kişi')),
          stat('${report.total.bookings}', t('Bookings', 'Rezervasyon')),
          stat('${report.total.completed}',
              t('Trips completed', 'Tamamlanan yolculuk')),
          stat('${report.cancelled}', t('Cancelled', 'İptal edilen')),
        ]),
        heading(t('Airport rides', 'Havalimanı yolculukları')),
        table([
          t('Direction', 'Yön'),
          t('Bookings', 'Rezervasyon'),
          t('People', 'Kişi'),
          t('Completed', 'Tamamlanan'),
        ], [
          for (final (type, c) in [
            (TransportType.airport, report.airportToHospital),
            (TransportType.toAirport, report.hospitalToAirport),
          ])
            [x.types[type]!, '${c.bookings}', '${c.people}', '${c.completed}'],
        ]),
        heading(t('By transport type', 'Ulaşım tipine göre')),
        table([
          t('Type', 'Tip'),
          t('Bookings', 'Rezervasyon'),
          t('People', 'Kişi'),
          t('Completed', 'Tamamlanan'),
        ], [
          for (final type in TransportType.values)
            [
              x.types[type]!,
              '${report.byType[type]?.bookings ?? 0}',
              '${report.byType[type]?.people ?? 0}',
              '${report.byType[type]?.completed ?? 0}',
            ],
          [
            t('Total', 'Toplam'),
            '${report.total.bookings}',
            '${report.total.people}',
            '${report.total.completed}',
          ],
        ]),
        heading(t('By branch', 'Şubeye göre')),
        table([
          t('Branch', 'Şube'),
          t('Bookings', 'Rezervasyon'),
          t('People', 'Kişi'),
        ], [
          for (final br in {...branches, ...report.byBranch.keys})
            [
              br,
              '${report.byBranch[br]?.bookings ?? 0}',
              '${report.byBranch[br]?.people ?? 0}',
            ],
        ]),
        heading(t('Last 12 months (people)', 'Son 12 ay (kişi)')),
        table([
          t('Month', 'Ay'),
          t('All rides', 'Tüm yolculuklar'),
          x.types[TransportType.airport]!,
          x.types[TransportType.toAirport]!,
        ], [
          for (final m in year.reversed)
            [
              monthName(m.month, t),
              '${m.total.people}',
              '${m.airportToHospital.people}',
              '${m.hospitalToAirport.people}',
            ],
        ]),
        heading(t('All bookings of the month', 'Ayın tüm rezervasyonları')),
        if (report.bookings.isEmpty)
          pw.Text(t('No bookings this month.', 'Bu ay rezervasyon yok.'),
              style: const pw.TextStyle(fontSize: 9, color: grey))
        else
          table([
            t('Ref', 'No'),
            t('Date', 'Tarih'),
            t('Type', 'Tip'),
            t('Route', 'Güzergâh'),
            t('People', 'Kişi'),
            t('Status', 'Durum'),
          ], [
            for (final b in report.bookings)
              [
                b.ref,
                '${formatDate(b.date)} ${formatTime(b.time)}',
                x.types[b.type]!,
                b.route,
                '${b.passengers}',
                status(b),
              ],
          ]),
        pw.SizedBox(height: 10),
        pw.Text(
            t(
                'People = passengers on bookings that were not cancelled, the '
                    'patient included. Bookings are counted in the month of '
                    'their ride date.',
                'Kişi = iptal edilmeyen rezervasyonlardaki yolcular (hasta '
                    'dahil). Rezervasyonlar yolculuk tarihinin ayında sayılır.'),
            style: const pw.TextStyle(fontSize: 8, color: grey)),
      ],
    ),
  );
  return doc.save();
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => _Panel(
        child: Row(
          children: [
            Icon(icon, color: AppColors.blue, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w900)),
                  Text(label, style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _AirportCard extends StatelessWidget {
  const _AirportCard(
      {required this.icon, required this.title, required this.count});

  final IconData icon;
  final String title;
  final ReportCount count;

  @override
  Widget build(BuildContext context) => _Panel(
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.blue.withValues(alpha: 0.1),
              child: Icon(icon, color: AppColors.blue, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                      context.t(
                          '${count.people} people · ${count.bookings} bookings '
                              '· ${count.completed} completed',
                          '${count.people} kişi · ${count.bookings} '
                              'rezervasyon · ${count.completed} tamamlandı'),
                      style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
            Text('${count.people}',
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: AppColors.blue)),
          ],
        ),
      );
}

// White rounded box, with an optional title.
class _Panel extends StatelessWidget {
  const _Panel({this.title, required this.child});

  final String? title;
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title!,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      );
}

// Simple table: first column left, numbers right.
class _Table extends StatelessWidget {
  const _Table({required this.head, required this.rows});

  final List<String> head;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    Widget cell(String text, int col, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(text,
              textAlign: col == 0 ? TextAlign.left : TextAlign.right,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                  color: bold ? AppColors.muted : AppColors.text,
                  fontSize: bold ? 12 : 14)),
        );
    return Table(
      columnWidths: const {0: FlexColumnWidth(2.2)},
      defaultColumnWidth: const FlexColumnWidth(1),
      children: [
        TableRow(
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border))),
          children: [
            for (var i = 0; i < head.length; i++) cell(head[i], i, bold: true)
          ],
        ),
        for (final r in rows)
          TableRow(
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.surface))),
            children: [for (var i = 0; i < r.length; i++) cell(r[i], i)],
          ),
      ],
    );
  }
}
