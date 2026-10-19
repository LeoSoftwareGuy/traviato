import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/journal/presentation/pages/note_page.dart';
import 'package:traviato/features/journal/presentation/providers/dictation_providers.dart';

import '../../../../helpers/localized_app.dart';
import '../../fakes/fake_dictation_service.dart';

Future<void> _open(WidgetTester tester, Locale locale) async {
  setScreenSize(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dictationServiceProvider.overrideWithValue(FakeDictationService()),
      ],
      child: localizedApp(
        locale: locale,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                NotePageRoute(
                  stamp: 'День 2 · 13 авг.',
                  title: 'Tallinn',
                  existingText: 'Old Town walk.',
                  photoCount: 5,
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

void main() {
  testWidgets('note page reads in Russian', (tester) async {
    await _open(tester, const Locale('ru'));

    expect(find.text('Отмена'), findsOneWidget);
    expect(find.text('Готово'), findsOneWidget);
    expect(find.text('Нажмите, чтобы говорить'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final (locale, tapToTalk) in const [
    (Locale('en'), 'Tap to talk'),
    (Locale('ru'), 'Нажмите, чтобы говорить'),
  ]) {
    testWidgets('note page toolbar lays out at 360pt in '
        '${locale.languageCode}', (tester) async {
      await _open(tester, locale);

      expect(find.text(tapToTalk), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
