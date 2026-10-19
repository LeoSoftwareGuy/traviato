import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/settings/domain/app_language.dart';

void main() {
  group('resolveAppLanguage', () {
    test('a pinned choice is itself, whatever the device says', () {
      expect(
        resolveAppLanguage(AppLanguage.ru, const [Locale('et')]),
        AppLanguage.ru,
      );
    });

    test('system takes the first supported device locale', () {
      expect(
        resolveAppLanguage(AppLanguage.system, const [
          Locale('de'),
          Locale('et', 'EE'),
          Locale('ru'),
        ]),
        AppLanguage.ru,
      );
    });

    test('a language the UI lacks resolves like system (#245)', () {
      expect(
        resolveAppLanguage(AppLanguage.et, const [Locale('ru')]),
        AppLanguage.ru,
      );
    });

    test('an Estonian phone reads the app in English (#245)', () {
      expect(
        resolveAppLanguage(AppLanguage.system, const [Locale('et', 'EE')]),
        AppLanguage.en,
      );
    });

    test('system falls back to English when nothing matches', () {
      expect(
        resolveAppLanguage(AppLanguage.system, const [Locale('fi')]),
        AppLanguage.en,
      );
      expect(resolveAppLanguage(AppLanguage.system, const []), AppLanguage.en);
    });
  });

  test('fromCode round-trips and treats unknown values as system', () {
    for (final language in AppLanguage.values) {
      expect(AppLanguage.fromCode(language.code), language);
    }
    expect(AppLanguage.fromCode('de'), AppLanguage.system);
    expect(AppLanguage.fromCode('system'), AppLanguage.system);
  });

  test('uiFromCode treats a language the UI lacks as system', () {
    expect(AppLanguage.uiFromCode('ru'), AppLanguage.ru);
    expect(AppLanguage.uiFromCode('et'), AppLanguage.system);
    expect(AppLanguage.uiFromCode(null), AppLanguage.system);
  });

  test('the UI is en/ru; dictation adds Estonian', () {
    expect(AppLanguage.uiLanguages, [AppLanguage.en, AppLanguage.ru]);
    expect(AppLanguage.et.isUiLanguage, isFalse);
    expect(AppLanguage.dictationLanguages, [
      AppLanguage.en,
      AppLanguage.ru,
      AppLanguage.et,
    ]);
  });

  test('native names are never translated', () {
    expect(
      [for (final l in AppLanguage.dictationLanguages) l.nativeName],
      ['English', 'Русский', 'Eesti'],
    );
  });
}
