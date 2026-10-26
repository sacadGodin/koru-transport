import 'package:flutter_test/flutter_test.dart';
import 'package:koru_website/lang.dart';

void main() {
  test('plain text is translated', () {
    expect(translate('Book ride', Lang.fr), 'Réserver');
    expect(translate('Book ride', Lang.ar), 'احجز رحلة');
  });

  test('text with values keeps the values', () {
    expect(translate('Call 444 7 678', Lang.ru), 'Позвонить 444 7 678');
    expect(
        translate('Reference: KR-1005. A coordinator will call 0555 to '
            'confirm your ride.', Lang.fr),
        'Référence : KR-1005. Un coordinateur appellera le 0555 pour '
        'confirmer votre trajet.');
  });

  test('unknown text falls back to English', () {
    expect(translate('[BRANCH 1]', Lang.ar), '[BRANCH 1]');
  });
}
