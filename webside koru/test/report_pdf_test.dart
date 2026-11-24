import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koru_website/data/bookings.dart';
import 'package:koru_website/data/reports.dart';
import 'package:koru_website/lang.dart';
import 'package:koru_website/pages/admin_reports.dart';

Booking _b(String ref, TransportType type, DateTime date,
        {int people = 1,
        Stage stage = Stage.newRequest,
        TripStatus? trip,
        String branch = 'Koru Hospital Çukurambar',
        BookedBy? by,
        String name = ''}) =>
    Booking(
      ref: ref,
      patient: 'Ayşe Yılmaz',
      phone: '1',
      type: type,
      from: type == TransportType.toAirport ? airportName : 'Kızılay, Ankara',
      branch: branch,
      date: date,
      time: const TimeOfDay(hour: 9, minute: 0),
      passengers: people,
      stage: stage,
      bookedBy: by,
      bookedByName: name,
    )..trip = trip;

final _all = [
  _b('KR-1001', TransportType.airport, DateTime(2026, 11, 2),
      people: 3, by: BookedBy.translator, name: 'Ahmet Şahin'),
  _b('KR-1002', TransportType.toAirport, DateTime(2026, 11, 5),
      people: 2,
      stage: Stage.arranged,
      trip: TripStatus.completed,
      by: BookedBy.coordinator,
      name: 'Gülşen İnce'),
  _b('KR-1003', TransportType.wheelchair, DateTime(2026, 11, 6),
      branch: hotelName, by: BookedBy.translator, name: 'ahmet şahin '),
  _b('KR-1004', TransportType.standard, DateTime(2026, 11, 7),
      people: 4, stage: Stage.cancelled, by: BookedBy.translator, name: 'محمد'),
  _b('KR-1005', TransportType.standard, DateTime(2026, 11, 9),
      branch: 'Koru Hospital Sincan'),
  _b('KR-0999', TransportType.airport, DateTime(2026, 10, 30), people: 5),
];

void main() {
  test('report groups bookings by coordinator and translator', () {
    final r = MonthReport(DateTime(2026, 11), _all);
    final bookers = r.bookers;
    // "Ahmet Şahin" and "ahmet şahin " are the same person.
    expect(bookers.first.name, 'Ahmet Şahin');
    expect(bookers.first.bookings, 2);
    expect(bookers.first.people, 4);
    expect(bookers.last.role, isNull); // not recorded comes last
    expect(r.byRole[BookedBy.coordinator]!.bookings, 1);
    expect(r.cancelRate, 20);
  });

  for (final lang in [Lang.en, Lang.tr, Lang.ar]) {
    testWidgets('PDF report builds in ${lang.code}', (tester) async {
      langController.value = lang;
      late BuildContext ctx;
      await tester.pumpWidget(LangScope(
          child: Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      })));
      final month = DateTime(2026, 11);
      final bytes = await tester.runAsync(() => monthReportPdf(
          ctx, MonthReport(month, _all), lastTwelveMonths(month, _all)));
      expect(String.fromCharCodes(bytes!.take(4)), '%PDF');
      // Set REPORT_PDF_DIR to keep the PDFs and look at them.
      final dir = Platform.environment['REPORT_PDF_DIR'];
      if (dir != null) {
        File('$dir/report-${lang.code}.pdf').writeAsBytesSync(bytes);
      }
    });
  }
}
