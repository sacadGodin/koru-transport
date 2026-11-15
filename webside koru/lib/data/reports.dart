import 'bookings.dart';

// Bookings and people for one line of a report.
class ReportCount {
  int bookings = 0;
  int people = 0;
  // Trips the driver marked as completed.
  int completed = 0;

  void add(Booking b) {
    bookings++;
    people += b.passengers;
    if (b.trip == TripStatus.completed) completed++;
  }
}

// What the monthly report shows: every booking whose ride is in [month],
// cancelled ones counted apart.
class MonthReport {
  MonthReport(DateTime month, Iterable<Booking> all)
      : month = DateTime(month.year, month.month) {
    bookings = all
        .where((b) =>
            b.date.year == this.month.year && b.date.month == this.month.month)
        .toList()
      ..sort((a, b) {
        final byDay = a.date.compareTo(b.date);
        if (byDay != 0) return byDay;
        return (a.time.hour * 60 + a.time.minute)
            .compareTo(b.time.hour * 60 + b.time.minute);
      });
    for (final b in bookings) {
      if (b.stage == Stage.cancelled) {
        cancelled++;
        continue;
      }
      total.add(b);
      byType.putIfAbsent(b.type, ReportCount.new).add(b);
      byBranch.putIfAbsent(b.branch, ReportCount.new).add(b);
    }
  }

  // First day of the month.
  final DateTime month;
  // Every booking of the month in ride order, cancelled ones included.
  late final List<Booking> bookings;

  // Bookings that were not cancelled, and the people on them.
  final total = ReportCount();
  int cancelled = 0;
  final Map<TransportType, ReportCount> byType = {};
  final Map<String, ReportCount> byBranch = {};

  ReportCount get airportToHospital =>
      byType[TransportType.airport] ?? ReportCount();
  ReportCount get hospitalToAirport =>
      byType[TransportType.toAirport] ?? ReportCount();

  // Whether the month has not ended yet (figures can still change).
  bool get inProgress {
    final now = DateTime.now();
    return !DateTime(month.year, month.month + 1).isBefore(now) &&
        !month.isAfter(now);
  }
}

// The 12 months up to and including [month], oldest first.
List<MonthReport> lastTwelveMonths(DateTime month, Iterable<Booking> all) => [
      for (var i = 11; i >= 0; i--)
        MonthReport(DateTime(month.year, month.month - i), all),
    ];

// "November 2026" / "Kasım 2026".
String monthName(DateTime m, String Function(String en, String tr) t) {
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
  return '${t(en, tr)} ${m.year}';
}
