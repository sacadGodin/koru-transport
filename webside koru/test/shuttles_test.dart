import 'package:flutter_test/flutter_test.dart';
import 'package:koru_website/data/shuttles.dart';
import 'package:koru_website/lang.dart';

void main() {
  test('routes start at the three branches, in order', () {
    expect(ShuttleBranch.values.map((b) => '${b.id} ${b.en}'), [
      'A Koru Hospital Çukurambar',
      'B Koru Hospital Sincan',
      'C Koru Hospital Kavaklıdere',
    ]);
  });

  test('an empty route is not announced', () {
    const empty = ShuttleRoute(branch: ShuttleBranch.sincan);
    expect(empty.announced, isFalse);
    expect(
        const ShuttleRoute(
                branch: ShuttleBranch.sincan, destination: 'Somewhere')
            .announced,
        isFalse);
    expect(
        const ShuttleRoute(branch: ShuttleBranch.sincan, times: ['08:00'])
            .announced,
        isFalse);
    expect(
        const ShuttleRoute(
            branch: ShuttleBranch.sincan,
            destination: 'Somewhere',
            times: ['08:00']).announced,
        isTrue);
  });

  test('typed times are cleaned up, sorted and checked', () {
    expect(parseTimes('12:00, 9:30  08:00;12:00'), ['08:00', '09:30', '12:00']);
    expect(parseTimes(''), isEmpty);
    expect(parseTimes('08:00, 24:00'), isNull);
    expect(parseTimes('8am'), isNull);
    expect(normalizeTime('7:05'), '07:05');
    expect(normalizeTime('07:60'), isNull);
  });

  test('next departure is the next time today, else tomorrow\'s first', () {
    const times = ['07:00', '12:30', '18:00'];
    expect(nextDeparture(times, DateTime(2026, 10, 27, 6, 59)),
        (time: '07:00', tomorrow: false));
    expect(nextDeparture(times, DateTime(2026, 10, 27, 12, 30)),
        (time: '12:30', tomorrow: false));
    expect(nextDeparture(times, DateTime(2026, 10, 27, 18, 1)),
        (time: '07:00', tomorrow: true));
    expect(nextDeparture(const [], DateTime(2026, 10, 27)), isNull);
  });

  test('free bus texts are translated', () {
    expect(translate('Every 15 min', Lang.fr), 'Toutes les 15 min');
    expect(translate('Schedule to be announced', Lang.ru),
        'Расписание будет объявлено');
  });
}
