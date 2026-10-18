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
        AppLanguage.et,
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

  test('native names are never translated', () {
    expect(
      [for (final l in AppLanguage.pinned) l.nativeName],
      ['English', 'Русский', 'Eesti'],
    );
  });
}
