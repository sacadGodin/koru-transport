import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

        // Who made the bookings: each coordinator and translator.
        _Panel(
          title: context.t('Booked by coordinators and translators',
              'Koordinatör ve tercümanlara göre'),
          child: report.bookers.isEmpty
              ? Text(
                  context.t(
                      'No bookings this month.', 'Bu ay rezervasyon yok.'),
                  style: const TextStyle(color: AppColors.muted))
              : _Table(
                  head: [
                    context.t('Booked by', 'Rezervasyonu yapan'),
                    context.t('Bookings', 'Rez.'),
                    context.t('People', 'Kişi'),
                  ],
                  rows: [
                    for (final b in report.bookers)
                      [
                        _bookerText(
                            b.role,
                            b.name,
                            {
                              for (final r in BookedBy.values)
                                r: r.label(context)
                            },
                            context.t),
                        '${b.bookings}',
                        '${b.people}',
                      ],
                  ],
                ),
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

// "Translator · Ahmet", or "Not recorded" for bookings made before the
// form asked who was booking.
String _bookerText(BookedBy? role, String name, Map<BookedBy, String> roles,
        String Function(String en, String tr) t,
        {String separator = ' · '}) =>
    role == null
        ? t('Not recorded', 'Kayıtlı değil')
        : name.isEmpty
            ? roles[role]!
            : '${roles[role]}$separator$name';

// Every text the PDF needs (the PDF is built away from the widget tree).
// The report is in Turkish when the site is in Turkish and in English
// otherwise: only those two are written out in full for every report text.
class _PdfTexts {
  _PdfTexts(this.t, this.types, this.stages, this.roles, this.completed);

  factory _PdfTexts.of(BuildContext context) {
    final turkish = context.lang == Lang.tr;
    String t(String en, String tr) => turkish ? tr : en;
    return _PdfTexts(
      t,
      {for (final type in TransportType.values) type: type.labelIn(t)},
      {for (final s in Stage.values) s: s.labelIn(t)},
      {for (final r in BookedBy.values) r: r.labelIn(t)},
      t('Trip completed', 'Yolculuk tamamlandı'),
    );
  }

  final String Function(String en, String tr) t;
  final Map<TransportType, String> types;
  final Map<Stage, String> stages;
  final Map<BookedBy, String> roles;
  final String completed;
}

// The fonts are part of the site (assets/fonts), so the PDF works without
// downloading anything. Noto Sans has every Turkish, French and Russian
// letter; Noto Sans Math fills in the arrows (→) used in routes and airport
// ride names, and Noto Sans Arabic the Arabic letters (an Arabic name typed
// on the booking form, or the report in Arabic).
Future<pw.ThemeData> _pdfTheme() async {
  Future<pw.Font> font(String file) async =>
      pw.Font.ttf(await rootBundle.load('assets/fonts/$file'));
  final (base, bold, symbols, arabic) = await (
    font('NotoSans-Regular.ttf'),
    font('NotoSans-Bold.ttf'),
    font('NotoSansMath-Regular.ttf'),
    font('NotoSansArabic-Regular.ttf'),
  ).wait;
  return pw.ThemeData.withFont(
      base: base, bold: bold, fontFallback: [symbols, arabic]);
}

// Right to left for text with Arabic letters (a name typed in Arabic).
pw.TextDirection _direction(String text) =>
    RegExp(r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]')
            .hasMatch(text)
        ? pw.TextDirection.rtl
        : pw.TextDirection.ltr;

// For tests: the PDF in the language of [context].
@visibleForTesting
Future<Uint8List> monthReportPdf(
        BuildContext context, MonthReport report, List<MonthReport> year) =>
    _buildMonthReportPdf(report, year, _PdfTexts.of(context));

// The printable monthly report (A4).
Future<Uint8List> _buildMonthReportPdf(
    MonthReport report, List<MonthReport> year, _PdfTexts x) async {
  final t = x.t;
  final (theme, logoData) = await (
    _pdfTheme(),
    rootBundle.load('assets/images/koru_transport_logo.png'),
  ).wait;
  final logo = pw.MemoryImage(logoData.buffer.asUint8List());
  final doc = pw.Document(
    theme: theme,
    title: 'Koru Transport ${monthName(report.month, t)}',
    author: 'Koru Hospital Transport',
  );

  const navy = PdfColor.fromInt(0xFF0B2A4A);
  const blue = PdfColor.fromInt(0xFF1E5AA8);
  const gold = PdfColor.fromInt(0xFFB8913A);
  const grey = PdfColor.fromInt(0xFF52627A);
  const line = PdfColor.fromInt(0xFFDDE3EC);
  const soft = PdfColor.fromInt(0xFFF3F6FA);

  final month = monthName(report.month, t);
  final now = DateTime.now();
  final prev = year.length > 1 ? year[year.length - 2] : null;

  // "12 bookings" / "1 booking" (Turkish has no plural after a number).
  String n(int count, String one, String many, String tr) =>
      t('$count ${count == 1 ? one : many}', '$count $tr');
  String pct(num part, num whole) =>
      whole == 0 ? '0%' : '${(part * 100 / whole).round()}%';

  // ---- Building blocks ----

  pw.Widget section(String title, [String? subtitle]) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 20, bottom: 8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(children: [
              pw.Container(width: 3, height: 13, color: gold),
              pw.SizedBox(width: 7),
              pw.Text(title,
                  style: pw.TextStyle(
                      fontSize: 12.5,
                      fontWeight: pw.FontWeight.bold,
                      color: navy)),
            ]),
            if (subtitle != null)
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 10, top: 2),
                child: pw.Text(subtitle,
                    style: const pw.TextStyle(fontSize: 8.5, color: grey)),
              ),
          ],
        ),
      );

  // A table with a navy header, light row lines and an optional bold total
  // row. Columns after the first are numbers (right-aligned) unless
  // [textColumns] says otherwise.
  pw.Widget table(
    List<String> head,
    List<List<String>> rows, {
    List<String>? total,
    Map<int, double>? widths,
    Set<int> textColumns = const {0},
    double fontSize = 9,
  }) {
    // Each line is its own text, so an Arabic name on one line is
    // written right to left without turning the other lines around.
    pw.Widget cell(String text, int col,
            {bool header = false, bool bold = false}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: pw.Column(
            crossAxisAlignment: textColumns.contains(col)
                ? pw.CrossAxisAlignment.start
                : pw.CrossAxisAlignment.end,
            children: [
              for (final part in text.split('\n'))
                pw.Text(part,
                    textDirection: _direction(part),
                    style: pw.TextStyle(
                        fontSize: header ? fontSize - 0.5 : fontSize,
                        fontWeight: header || bold
                            ? pw.FontWeight.bold
                            : pw.FontWeight.normal,
                        color: header ? PdfColors.white : navy)),
            ],
          ),
        );
    return pw.Table(
      columnWidths: {
        for (var i = 0; i < head.length; i++)
          i: pw.FlexColumnWidth(widths?[i] ?? (i == 0 ? 2.4 : 1)),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: navy),
          repeat: true,
          children: [
            for (var i = 0; i < head.length; i++) cell(head[i], i, header: true)
          ],
        ),
        for (var r = 0; r < rows.length; r++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: r.isOdd ? soft : null,
              border: const pw.Border(
                  bottom: pw.BorderSide(color: line, width: 0.5)),
            ),
            children: [
              for (var i = 0; i < rows[r].length; i++) cell(rows[r][i], i)
            ],
          ),
        if (total != null)
          pw.TableRow(
            decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: navy, width: 1))),
            children: [
              for (var i = 0; i < total.length; i++)
                cell(total[i], i, bold: true)
            ],
          ),
      ],
    );
  }

  pw.Widget stat(String value, String label, {String? note}) => pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.only(right: 8),
          padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: const pw.BoxDecoration(
            color: soft,
            border: pw.Border(top: pw.BorderSide(color: blue, width: 2.5)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(value,
                  style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: navy)),
              pw.SizedBox(height: 2),
              pw.Text(label,
                  style: const pw.TextStyle(fontSize: 8.5, color: grey)),
              // Always a note line, so the four boxes are the same height.
              pw.Text(note ?? ' ',
                  style: const pw.TextStyle(fontSize: 7.5, color: grey)),
            ],
          ),
        ),
      );

  String status(Booking b) =>
      b.trip == TripStatus.completed ? x.completed : x.stages[b.stage]!;

  // ---- Written summary ----

  final total = report.total;
  final air = report.airportToHospital;
  final toAir = report.hospitalToAirport;
  final busiest = report.busiestBranch;
  final coordinators = report.byRole[BookedBy.coordinator]?.bookings ?? 0;
  final translators = report.byRole[BookedBy.translator]?.bookings ?? 0;

  final summary = <String>[
    if (report.bookings.isEmpty)
      t('No transport bookings were recorded for $month.',
          '$month ayı için kayıtlı ulaşım rezervasyonu bulunmamaktadır.')
    else ...[
      t(
          'In $month, Koru Hospital Transport handled '
              '${n(total.bookings, 'booking', 'bookings', 'rezervasyon')}, '
              'serving ${n(total.people, 'person', 'people', 'kişi')}. '
              '${n(total.completed, 'trip has', 'trips have', '')} been '
              'completed to date.',
          '$month ayında Koru Hastanesi Ulaşım birimi '
              '${total.bookings} rezervasyon ile ${total.people} kişiye '
              'hizmet vermiştir. Bugüne kadar ${total.completed} yolculuk '
              'tamamlanmıştır.'),
      if (report.cancelled > 0)
        t(
            '${n(report.cancelled, 'booking was', 'bookings were', '')} '
                'cancelled, ${report.cancelRate.round()}% of all requests.',
            '${report.cancelled} rezervasyon iptal edilmiştir; bu, tüm '
                'taleplerin %${report.cancelRate.round()} kadarıdır.'),
      if (prev != null && prev.total.people > 0)
        () {
          final change =
              ((total.people - prev.total.people) * 100 / prev.total.people)
                  .round();
          final prevName = monthName(prev.month, t);
          return change == 0
              ? t(
                  'The number of people served was the same as in '
                      '$prevName.',
                  'Hizmet verilen kişi sayısı $prevName ayı ile aynıdır.')
              : t(
                  'This is ${change.abs()}% ${change > 0 ? 'more' : 'fewer'} '
                      'people than in $prevName (${prev.total.people}).',
                  'Bu sayı $prevName ayına (${prev.total.people}) göre '
                      '%${change.abs()} ${change > 0 ? 'daha fazladır' : 'daha azdır'}.');
        }(),
      if (air.people + toAir.people > 0)
        t(
            'Airport transfers carried '
                '${n(air.people + toAir.people, 'person', 'people', '')}: '
                '${air.people} arriving and ${toAir.people} departing.',
            'Havalimanı transferlerinde ${air.people + toAir.people} kişi '
                'taşınmıştır: ${air.people} geliş, ${toAir.people} gidiş.'),
      if (busiest != null)
        t(
            'The busiest destination was ${busiest.key} with '
                '${n(busiest.value.bookings, 'booking', 'bookings', '')}.',
            'En yoğun varış noktası ${busiest.value.bookings} rezervasyon '
                'ile ${busiest.key} olmuştur.'),
      if (coordinators + translators > 0)
        t(
            'Coordinators made $coordinators and translators made '
                '$translators of the bookings.',
            'Rezervasyonların $coordinators tanesi koordinatörler, '
                '$translators tanesi tercümanlar tarafından yapılmıştır.'),
    ],
  ];

  // ---- Pages ----

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 32, 40, 32),
      header: (ctx) => ctx.pageNumber == 1
          ? pw.SizedBox()
          : pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.only(bottom: 6),
              decoration: const pw.BoxDecoration(
                  border: pw.Border(
                      bottom: pw.BorderSide(color: line, width: 0.75))),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(logo, height: 16),
                  pw.Text(
                      t('Monthly Transport Report · $month',
                          'Aylık Ulaşım Raporu · $month'),
                      style: const pw.TextStyle(fontSize: 8.5, color: grey)),
                ],
              ),
            ),
      footer: (ctx) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 12),
        padding: const pw.EdgeInsets.only(top: 6),
        decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: line, width: 0.75))),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
                t('Koru Hospital Transport · Confidential, for internal use',
                    'Koru Hastanesi Ulaşım · Gizli, kurum içi kullanım içindir'),
                style: const pw.TextStyle(fontSize: 7.5, color: grey)),
            pw.Text(
                t('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                    'Sayfa ${ctx.pageNumber} / ${ctx.pagesCount}'),
                style: const pw.TextStyle(fontSize: 7.5, color: grey)),
          ],
        ),
      ),
      build: (ctx) => [
        // Title block.
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Image(logo, height: 34),
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: pw.BoxDecoration(
                color: report.inProgress
                    ? const PdfColor.fromInt(0xFFFFF4E0)
                    : const PdfColor.fromInt(0xFFE6F4EA),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Text(
                  report.inProgress
                      ? t('PROVISIONAL', 'GEÇİCİ')
                      : t('FINAL', 'KESİN'),
                  style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: report.inProgress
                          ? const PdfColor.fromInt(0xFF9A5B00)
                          : const PdfColor.fromInt(0xFF1E7B3A))),
            ),
          ],
        ),
        pw.SizedBox(height: 18),
        pw.Text(t('Monthly Transport Report', 'Aylık Ulaşım Raporu'),
            style: pw.TextStyle(
                fontSize: 24, fontWeight: pw.FontWeight.bold, color: navy)),
        pw.SizedBox(height: 2),
        pw.Text(month,
            style: pw.TextStyle(
                fontSize: 14, color: blue, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(
            '${t('Prepared on', 'Hazırlanma tarihi')} ${formatDate(now)}, '
            '${formatTime(TimeOfDay.fromDateTime(now))}',
            style: const pw.TextStyle(fontSize: 8.5, color: grey)),
        if (report.inProgress)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text(
                t(
                    'The month is still in progress; figures may change '
                        'until it ends.',
                    'Ay henüz tamamlanmadığından rakamlar ay sonuna kadar '
                        'değişebilir.'),
                style: const pw.TextStyle(
                    fontSize: 8.5, color: PdfColor.fromInt(0xFF9A5B00))),
          ),
        pw.SizedBox(height: 16),

        // Key figures.
        pw.Padding(
          padding: pw.EdgeInsets.zero,
          child: pw.Row(children: [
            stat('${total.people}', t('People served', 'Hizmet verilen kişi')),
            stat('${total.bookings}', t('Bookings', 'Rezervasyon')),
            stat('${total.completed}',
                t('Trips completed', 'Tamamlanan yolculuk'),
                note: total.bookings == 0
                    ? null
                    : t('${pct(total.completed, total.bookings)} of bookings',
                        'rezervasyonların ${pct(total.completed, total.bookings)}')),
            stat('${report.cancelled}', t('Cancelled', 'İptal edilen'),
                note: report.bookings.isEmpty
                    ? null
                    : t('${report.cancelRate.round()}% of requests',
                        'taleplerin %${report.cancelRate.round()}')),
          ]),
        ),

        // Written summary.
        section(t('Summary', 'Özet')),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(left: pw.BorderSide(color: blue, width: 2)),
            color: soft,
          ),
          child: pw.Text(summary.join(' '),
              style: const pw.TextStyle(
                  fontSize: 9.5, lineSpacing: 3, color: navy)),
        ),

        section(
            t('Airport transfers', 'Havalimanı transferleri'),
            t('Arrivals to the hospital or hotel, and departures to the airport.',
                'Hastane veya otele gelişler ve havalimanına gidişler.')),
        table([
          t('Direction', 'Yön'),
          t('Bookings', 'Rezervasyon'),
          t('People', 'Kişi'),
          t('Completed', 'Tamamlanan'),
        ], [
          for (final (type, c) in [
            (TransportType.airport, air),
            (TransportType.toAirport, toAir),
          ])
            [x.types[type]!, '${c.bookings}', '${c.people}', '${c.completed}'],
        ], total: [
          t('Total', 'Toplam'),
          '${air.bookings + toAir.bookings}',
          '${air.people + toAir.people}',
          '${air.completed + toAir.completed}',
        ]),

        section(t('By transport type', 'Ulaşım tipine göre')),
        table([
          t('Transport type', 'Ulaşım tipi'),
          t('Bookings', 'Rezervasyon'),
          t('People', 'Kişi'),
          t('Completed', 'Tamamlanan'),
          t('Share', 'Pay'),
        ], [
          for (final type in TransportType.values)
            [
              x.types[type]!,
              '${report.byType[type]?.bookings ?? 0}',
              '${report.byType[type]?.people ?? 0}',
              '${report.byType[type]?.completed ?? 0}',
              pct(report.byType[type]?.bookings ?? 0, total.bookings),
            ],
        ], total: [
          t('Total', 'Toplam'),
          '${total.bookings}',
          '${total.people}',
          '${total.completed}',
          total.bookings == 0 ? '0%' : '100%',
        ]),

        section(t('By destination', 'Varış noktasına göre')),
        table([
          t('Branch / destination', 'Şube / varış noktası'),
          t('Bookings', 'Rezervasyon'),
          t('People', 'Kişi'),
          t('Share', 'Pay'),
        ], [
          for (final br in {...destinations, ...report.byBranch.keys})
            [
              br,
              '${report.byBranch[br]?.bookings ?? 0}',
              '${report.byBranch[br]?.people ?? 0}',
              pct(report.byBranch[br]?.bookings ?? 0, total.bookings),
            ],
        ], total: [
          t('Total', 'Toplam'),
          '${total.bookings}',
          '${total.people}',
          total.bookings == 0 ? '0%' : '100%',
        ]),

        section(
            t('Bookings by coordinators and translators',
                'Koordinatör ve tercümanlara göre rezervasyonlar'),
            t('Who filled in the booking form for each patient.',
                'Her hasta için rezervasyon formunu dolduran kişi.')),
        if (report.bookers.isEmpty)
          pw.Text(t('No bookings this month.', 'Bu ay rezervasyon yok.'),
              style: const pw.TextStyle(fontSize: 9, color: grey))
        else
          table(
            [
              t('Role', 'Görev'),
              t('Name', 'Ad'),
              t('Bookings', 'Rezervasyon'),
              t('People', 'Kişi'),
              t('Share', 'Pay'),
            ],
            [
              for (final b in report.bookers)
                [
                  b.role == null
                      ? t('Not recorded', 'Kayıtlı değil')
                      : x.roles[b.role]!,
                  b.role == null || b.name.isEmpty ? '—' : b.name,
                  '${b.bookings}',
                  '${b.people}',
                  pct(b.bookings, total.bookings),
                ],
            ],
            total: [
              t('Total', 'Toplam'),
              '',
              '${total.bookings}',
              '${total.people}',
              total.bookings == 0 ? '0%' : '100%',
            ],
            widths: {0: 1.4, 1: 2.2},
            textColumns: {0, 1},
          ),

        section(t('12-month trend', '12 aylık eğilim'),
            t('People served per month.', 'Aylara göre hizmet verilen kişi.')),
        table([
          t('Month', 'Ay'),
          t('Bookings', 'Rezervasyon'),
          t('People', 'Kişi'),
          x.types[TransportType.airport]!,
          x.types[TransportType.toAirport]!,
        ], [
          for (final m in year.reversed)
            [
              monthName(m.month, t),
              '${m.total.bookings}',
              '${m.total.people}',
              '${m.airportToHospital.people}',
              '${m.hospitalToAirport.people}',
            ],
        ], widths: {
          0: 1.6,
          3: 1.4,
          4: 1.4
        }),

        // Full list on its own page.
        pw.NewPage(),
        section(
            t('Booking details', 'Rezervasyon ayrıntıları'),
            t('Every booking with a ride date in $month, cancelled ones included.',
                '$month ayında yolculuk tarihi olan tüm rezervasyonlar (iptaller dahil).')),
        if (report.bookings.isEmpty)
          pw.Text(t('No bookings this month.', 'Bu ay rezervasyon yok.'),
              style: const pw.TextStyle(fontSize: 9, color: grey))
        else
          table(
            [
              t('Ref', 'No'),
              t('Date', 'Tarih'),
              t('Type', 'Tip'),
              t('Route', 'Güzergâh'),
              t('People', 'Kişi'),
              t('Booked by', 'Rezervasyonu yapan'),
              t('Status', 'Durum'),
            ],
            [
              for (final b in report.bookings)
                [
                  b.ref,
                  '${formatDate(b.date)}\n${formatTime(b.time)}',
                  x.types[b.type]!,
                  b.route,
                  '${b.passengers}',
                  _bookerText(b.bookedBy, b.bookedByName, x.roles, t,
                      separator: '\n'),
                  status(b),
                ],
            ],
            widths: {0: 0.9, 1: 1.0, 2: 1.4, 3: 2.4, 4: 0.8, 5: 1.6, 6: 1.2},
            textColumns: {0, 1, 2, 3, 5, 6},
            fontSize: 7.5,
          ),

        pw.SizedBox(height: 14),
        pw.Text(t('Notes', 'Notlar'),
            style: pw.TextStyle(
                fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: navy)),
        pw.SizedBox(height: 3),
        for (final note in [
          t(
              'People = passengers on bookings that were not cancelled, the '
                  'patient included.',
              'Kişi = iptal edilmeyen rezervasyonlardaki yolcular (hasta dahil).'),
          t('Bookings are counted in the month of their ride date.',
              'Rezervasyonlar yolculuk tarihinin olduğu ayda sayılır.'),
          t(
              'Cancelled bookings are listed in the details but not included '
                  'in the totals.',
              'İptal edilen rezervasyonlar ayrıntılarda listelenir, '
                  'toplamlara dahil edilmez.'),
          t(
              '"Not recorded" marks bookings made before the form asked who '
                  'was booking.',
              '"Kayıtlı değil", form rezervasyonu yapan kişiyi sormadan önce '
                  'alınan rezervasyonları gösterir.'),
        ])
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Text('•  $note',
                style: const pw.TextStyle(fontSize: 7.5, color: grey)),
          ),
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
