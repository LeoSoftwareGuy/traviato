import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traviato/features/auth/presentation/providers/auth_providers.dart';
import 'package:traviato/features/journal/presentation/pages/note_page.dart';
import 'package:traviato/features/journal/presentation/providers/dictation_providers.dart';
import 'package:traviato/features/profile/presentation/providers/profile_providers.dart';
import 'package:traviato/features/settings/domain/app_language.dart';
import 'package:traviato/features/settings/presentation/providers/settings_providers.dart';

import '../../../../helpers/localized_app.dart';
import '../../../auth/fakes/fake_auth_repository.dart';
import '../../../profile/fakes/fake_profile_repository.dart';
import '../../fakes/fake_dictation_service.dart';

late FakeDictationService _service;
late FakeAuthRepository _auth;

Future<void> _open(
  WidgetTester tester, {
  AppLanguage? dictation,
  List<String>? supported = const ['en_US', 'ru_RU', 'et_EE'],
  Locale locale = const Locale('en'),
}) async {
  _service = FakeDictationService()..supported = supported;
  _auth = FakeAuthRepository();
  addTearDown(_auth.dispose);
  setScreenSize(tester, height: 800);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dictationServiceProvider.overrideWithValue(_service),
        authRepositoryProvider.overrideWithValue(_auth),
        profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
        initialDictationLanguageProvider.overrideWithValue(dictation),
        // In the app MaterialApp's locale *is* the resolved UI language.
        initialAppLanguageProvider.overrideWithValue(
          AppLanguage.fromCode(locale.languageCode),
        ),
      ],
      child: localizedApp(
        locale: locale,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                NotePageRoute(
                  stamp: 'Day 2 · 25 Aug',
                  title: 'Thin air, cold lakes',
                  existingText: '',
                  photoCount: 0,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

final _slot = find.byKey(const Key('note-page-language-slot'));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('2a · idle: chip with the language and the word count', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('EN'), findsOneWidget);
    expect(find.text('▾'), findsOneWidget);
    expect(find.text('0 W'), findsOneWidget);
    expect(find.text('Tap to talk'), findsOneWidget);
  });

  testWidgets('2b · picking Русский is remembered and used to listen', (
    tester,
  ) async {
    await _open(tester);

    await tester.tap(_slot);
    await tester.pumpAndSettle();
    expect(find.text('Speak in…'), findsOneWidget);
    expect(
      find.text('Only changes dictation. The app stays in English.'),
      findsOneWidget,
    );
    expect(
      find.text("We'll remember this for your next note."),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('dictation-row-ru')));
    await tester.pumpAndSettle();
    expect(find.text('RU'), findsOneWidget);
    final stored = await SharedPreferences.getInstance();
    expect(stored.getString('dictation_language'), 'ru');

    await tester.tap(find.byKey(const Key('note-page-mic')));
    await tester.pump();
    await tester.pump();
    expect(_service.lastLocaleId, 'ru_RU');

    // 2c · locked while listening: status shows the language; no caret;
    // tapping the chip does nothing.
    expect(find.text('LISTENING · RU · 0:00'), findsOneWidget);
    expect(find.text('▾'), findsNothing);
    await tester.tap(_slot, warnIfMissed: false);
    await tester.pump();
    expect(find.text('Speak in…'), findsNothing);

    await tester.tap(find.byKey(const Key('note-page-mic')));
    await tester.pumpAndSettle();
  });

  // An Estonian user reads the app in English but dictates in Estonian
  // (#245).
  testWidgets('2d · chosen language unavailable: mic disabled, Aa accented, '
      'warning opens the picker with the row disabled', (tester) async {
    await _open(
      tester,
      dictation: AppLanguage.et,
      supported: const ['en_US', 'ru_RU'],
      locale: const Locale('en'),
    );

    expect(find.byKey(const Key('note-page-mic-unavailable')), findsOneWidget);
    expect(find.text('Not available'), findsOneWidget);
    expect(
      find.byKey(const Key('note-page-language-warning-dot')),
      findsOneWidget,
    );
    expect(
      find.text('Keep typing or pick another language and speak.'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        "Estonian speech recognition isn't available",
        findRichText: true,
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('note-page-language-warning')));
    await tester.pumpAndSettle();
    expect(find.text('Speak in…'), findsOneWidget);
    expect(
      find.textContaining('You can still type in Estonian.'),
      findsOneWidget,
    );

    // The disabled row can't be picked; another one can.
    await tester.tap(find.byKey(const Key('dictation-row-et')));
    await tester.pumpAndSettle();
    expect(find.text('Speak in…'), findsOneWidget);
    await tester.tap(find.byKey(const Key('dictation-row-ru')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('note-page-mic-unavailable')), findsNothing);
    expect(find.text('RU'), findsOneWidget);
    expect(_service.listenCallCount, 0);
  });

  testWidgets('first use defaults to the UI language when speech has it', (
    tester,
  ) async {
    await _open(tester, locale: const Locale('ru'));
    expect(find.text('RU'), findsOneWidget);
    expect(find.text('Нажмите, чтобы говорить'), findsOneWidget);
  });

  for (final locale in const [Locale('en'), Locale('ru')]) {
    testWidgets('unavailable state lays out at 360pt in '
        '${locale.languageCode}', (tester) async {
      await _open(
        tester,
        dictation: AppLanguage.et,
        supported: const ['en_US'],
        locale: locale,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
