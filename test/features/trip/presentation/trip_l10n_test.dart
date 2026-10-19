import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/features/journal/presentation/providers/day_note_providers.dart';
import 'package:traviato/features/photo/presentation/providers/photo_providers.dart';
import 'package:traviato/features/trip/presentation/pages/create_memory_page.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';
import 'package:traviato/features/trip/presentation/widgets/delete_memory_sheet.dart';

import '../../../helpers/localized_app.dart';
import '../../journal/fakes/fake_day_note_repository.dart';
import '../../photo/fakes/fake_photo_repository.dart';
import '../fakes/fake_trip_repository.dart';

Future<void> _pumpCreate(WidgetTester tester, Locale locale) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tripRepositoryProvider.overrideWithValue(FakeTripRepository()),
      ],
      child: localizedApp(locale: locale, home: const CreateMemoryPage()),
    ),
  );
  await tester.pump();
}

void main() {
  group('create memory', () {
    testWidgets('reads in Russian, vibes translated', (tester) async {
      setScreenSize(tester, height: 2000);
      await _pumpCreate(tester, const Locale('ru'));

      expect(find.text('НОВОЕ ВОСПОМИНАНИЕ'), findsOneWidget);
      expect(find.text('Что достойно'), findsOneWidget);
      expect(find.text('Настроение'), findsOneWidget);
      expect(find.text('выбрано: 0'), findsOneWidget);
      expect(find.text('Автопутешествие'), findsOneWidget);
      expect(find.text('Road trip'), findsNothing);
      expect(find.textContaining('10 звёзд', findRichText: true), findsWidgets);

      await tester.tap(find.text('Автопутешествие'));
      await tester.pump();
      expect(find.text('выбрано: 1'), findsOneWidget);
    });

    for (final locale in const [Locale('en'), Locale('ru')]) {
      testWidgets('lays out without overflow at 360pt in '
          '${locale.languageCode}', (tester) async {
        setScreenSize(tester, height: 2000);
        await _pumpCreate(tester, locale);

        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('delete sheet warns with Russian plurals', (tester) async {
    setScreenSize(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tripRepositoryProvider.overrideWithValue(FakeTripRepository()),
          photoRepositoryProvider.overrideWithValue(
            FakePhotoRepository()
              ..photosResult = Right([
                for (var i = 0; i < 5; i++) buildPhotoEntity(id: 'p$i'),
              ]),
          ),
          dayNoteRepositoryProvider.overrideWithValue(
            FakeDayNoteRepository()
              ..notesForTripResult = Right([
                for (var i = 0; i < 3; i++) buildDayNoteEntity(id: 'n$i'),
              ]),
          ),
        ],
        child: localizedApp(
          locale: const Locale('ru'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => DeleteMemorySheet.show(
                  context,
                  tripId: 't1',
                  tripName: 'Рига',
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить воспоминание').last);
    await tester.pumpAndSettle();

    expect(find.text('Да! Удалить навсегда'), findsOneWidget);
    expect(
      find.textContaining('Будут удалены 5 фото и 3 дня заметок.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
