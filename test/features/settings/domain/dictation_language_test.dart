import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/settings/domain/app_language.dart';
import 'package:traviato/features/settings/domain/dictation_language.dart';

void main() {
  const ids = ['en_US', 'en_GB', 'ru_RU', 'de_DE'];

  group('recognizerLocaleFor', () {
    test('finds the recogniser locale for a language', () {
      expect(recognizerLocaleFor(AppLanguage.ru, ids, const []), 'ru_RU');
    });

    test("prefers the device's region for that language", () {
      expect(
        recognizerLocaleFor(AppLanguage.en, ids, const [Locale('en', 'GB')]),
        'en_GB',
      );
      expect(recognizerLocaleFor(AppLanguage.en, ids, const []), 'en_US');
    });

    test('accepts dash-separated ids (et-EE)', () {
      expect(
        recognizerLocaleFor(AppLanguage.et, const ['et-EE'], const []),
        'et-EE',
      );
    });

    test('is null for a language the recogniser lacks', () {
      expect(recognizerLocaleFor(AppLanguage.et, ids, const []), isNull);
      expect(recognizerLocaleFor(AppLanguage.system, ids, const []), isNull);
    });
  });

  group('defaultDictationLanguage', () {
    test('uses the UI language when speech supports it', () {
      expect(
        defaultDictationLanguage(
          uiLanguage: AppLanguage.ru,
          supportedIds: ids,
          deviceLocales: const [Locale('en')],
        ),
        AppLanguage.ru,
      );
    });

    test('else the first supported language the device prefers', () {
      expect(
        defaultDictationLanguage(
          uiLanguage: AppLanguage.et,
          supportedIds: ids,
          deviceLocales: const [Locale('et'), Locale('ru'), Locale('en')],
        ),
        AppLanguage.ru,
      );
    });

    test('else English', () {
      expect(
        defaultDictationLanguage(
          uiLanguage: AppLanguage.et,
          supportedIds: ids,
          deviceLocales: const [Locale('et')],
        ),
        AppLanguage.en,
      );
    });

    test('with support unknown, the UI language wins', () {
      expect(
        defaultDictationLanguage(
          uiLanguage: AppLanguage.et,
          supportedIds: null,
          deviceLocales: const [],
        ),
        AppLanguage.et,
      );
    });
  });
}
