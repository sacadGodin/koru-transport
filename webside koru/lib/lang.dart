import 'package:flutter/widgets.dart';

import 'translations.dart';

// The languages of the site. Turkish and English are written directly in
// the code; French, Arabic and Russian come from translations.dart.
enum Lang {
  tr('TR', 'Türkçe'),
  en('EN', 'English'),
  fr('FR', 'Français'),
  ar('AR', 'العربية'),
  ru('RU', 'Русский');

  const Lang(this.code, this.nativeName);

  // Short code shown on the language button, e.g. "FR".
  final String code;
  // Name of the language in that language, shown in the language menu.
  final String nativeName;
}

// Holds the current language. Turkish is the default.
class LangController extends ValueNotifier<Lang> {
  LangController() : super(Lang.tr);
}

// The one language controller for the whole app.
final langController = LangController();

// Puts the language into the widget tree (see main.dart), so every widget
// that shows text rebuilds when the language changes.
class LangScope extends InheritedNotifier<LangController> {
  LangScope({super.key, required super.child})
      : super(notifier: langController);
}

// Lets any widget write: context.t('English text', 'Türkçe metin')
extension LangText on BuildContext {
  // Current language (also makes this widget rebuild when it changes).
  Lang get lang =>
      dependOnInheritedWidgetOfExactType<LangScope>()!.notifier!.value;

  // Returns the text in the current language. French, Arabic and Russian
  // are looked up by the English text; if missing, English is shown.
  String t(String en, String tr) => switch (lang) {
        Lang.tr => tr,
        Lang.en => en,
        final other => translate(en, other),
      };
}

// Texts in translations.dart that contain "{}" (a value filled in by the
// code), turned into patterns that find those values in the English text.
final _templates = [
  for (final entry in translations.entries)
    if (entry.key.contains('{}'))
      (
        RegExp('^${entry.key.split('{}').map(RegExp.escape).join('(.*)')}\$',
            dotAll: true),
        entry.value,
      ),
];

// Translates [en] into [lang] using translations.dart.
String translate(String en, Lang lang) {
  final exact = translations[en]?[lang];
  if (exact != null) return exact;
  // Texts with values, e.g. "Call 444 7 678" matches "Call {}".
  for (final (pattern, texts) in _templates) {
    final match = pattern.firstMatch(en);
    final text = texts[lang];
    if (match == null || text == null) continue;
    var i = 1;
    return text.replaceAllMapped('{}', (_) => match.group(i++) ?? '');
  }
  return en;
}
