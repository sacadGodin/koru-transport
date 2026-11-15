import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koru_website/data/bookings.dart';
import 'package:koru_website/data/reports.dart';

Booking _b(String ref, TransportType type, DateTime date,
        {int people = 1, Stage stage = Stage.newRequest, TripStatus? trip}) =>
    Booking(
      ref: ref,
      patient: 'P',
      phone: '1',
      type: type,
      from: 'Somewhere',
      branch: branches.first,
      date: date,
      time: const TimeOfDay(hour: 9, minute: 0),
      passengers: people,
      stage: stage,
    )..trip = trip;

void main() {
  test('monthly report counts people and both airport directions', () {
    final all = [
      _b('KR-1', TransportType.airport, DateTime(2026, 11, 2), people: 3),
      _b('KR-2', TransportType.toAirport, DateTime(2026, 11, 5),
          people: 2, stage: Stage.arranged, trip: TripStatus.completed),
      _b('KR-3', TransportType.toAirport, DateTime(2026, 11, 6)),
      _b('KR-4', TransportType.standard, DateTime(2026, 11, 7),
          people: 4, stage: Stage.cancelled),
      _b('KR-5', TransportType.airport, DateTime(2026, 10, 30), people: 5),
    ];
    final r = MonthReport(DateTime(2026, 11, 20), all);

    expect(r.bookings.map((b) => b.ref), ['KR-1', 'KR-2', 'KR-3', 'KR-4']);
    expect(r.total.bookings, 3);
    expect(r.total.people, 6); // cancelled KR-4 not counted
    expect(r.total.completed, 1);
    expect(r.cancelled, 1);
    expect(r.airportToHospital.people, 3);
    expect(r.hospitalToAirport.bookings, 2);
    expect(r.hospitalToAirport.people, 3);

    final year = lastTwelveMonths(DateTime(2026, 11), all);
    expect(year.length, 12);
    expect(year.last.month, DateTime(2026, 11));
    expect(year[10].airportToHospital.people, 5); // October
  });
}
