import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:traviato/core/config/router/route_constants.dart';
import 'package:traviato/features/home/presentation/providers/profile_stats_provider.dart';
import 'package:traviato/features/journal/presentation/pages/journal_page.dart';
import 'package:traviato/features/journal/presentation/providers/day_note_providers.dart';
import 'package:traviato/features/photo/presentation/providers/photo_providers.dart';
import 'package:traviato/features/quest/presentation/providers/quest_providers.dart';
import 'package:traviato/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';

import '../../../helpers/localized_app.dart';
import '../../home/fakes/fake_profile_stats_repository.dart';
import '../../photo/fakes/fake_photo_repository.dart';
import '../../quest/fakes/fake_quest_repository.dart';
import '../../subscription/fakes/fake_subscription_repository.dart';
import '../../trip/fakes/fake_trip_repository.dart';
import '../fakes/fake_day_note_repository.dart';

DateTime get _today {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

Future<void> _pump(
  WidgetTester tester,
  Locale locale, {
  bool withEntries = true,
}) async {
  final router = GoRouter(
    initialLocation: '/journal',
    routes: [
      GoRoute(
        path: '/journal',
        builder: (context, state) => const JournalPage(tripId: 't1'),
      ),
      GoRoute(
        path: '/memory/:tripId/wrap-up',
        name: RouteNames.tripWrapUp,
        builder: (context, state) => const Scaffold(),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tripRepositoryProvider.overrideWithValue(
          FakeTripRepository()
            ..tripCardResult = Right(
              buildTripCard(
                id: 't1',
                name: 'Tallinn',
                startDate: _today.subtract(const Duration(days: 1)),
                endDate: _today.add(const Duration(days: 3)),
              ),
            ),
        ),
        photoRepositoryProvider.overrideWithValue(
          FakePhotoRepository()
            ..photosResult = Right([
              if (withEntries) ...[
                buildPhotoEntity(
                  id: 'p1',
                  dayDate: _today,
                  takenAt: _today.add(const Duration(hours: 21, minutes: 5)),
                ),
                buildPhotoEntity(id: 'p2', dayDate: _today),
              ],
            ]),
        ),
        dayNoteRepositoryProvider.overrideWithValue(
          FakeDayNoteRepository()
            ..getNoteResult = Right(
              withEntries
                  ? buildDayNoteEntity(
                      dayDate: _today,
                      content: 'Old Town walk.',
                    )
                  : null,
            )
            ..notesForTripResult = Right([
              if (withEntries)
                buildDayNoteEntity(dayDate: _today, content: 'Old Town walk.'),
            ]),
        ),
        questRepositoryProvider.overrideWithValue(FakeQuestRepository()),
        profileStatsRepositoryProvider.overrideWithValue(
          FakeProfileStatsRepository(),
        ),
        subscriptionRepositoryProvider.overrideWithValue(
          FakeSubscriptionRepository(),
        ),
      ],
      child: localizedRouterApp(locale: locale, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Journal reads in Russian; the note stays as written', (
    tester,
  ) async {
    setScreenSize(tester, height: 2000);
    await _pump(tester, const Locale('ru'));

    expect(find.text('ДНЕВНИК'), findsOneWidget);
    expect(find.text('День 2 — Tallinn'), findsOneWidget);
    expect(find.text('Old Town walk.'), findsOneWidget);
    expect(find.textContaining('3 СЛОВА'), findsOneWidget);
    expect(find.text('✎ Продолжить запись'), findsOneWidget);
    expect(find.text('Фото'), findsOneWidget);
    expect(find.text('сохранено: 2'), findsOneWidget);
    expect(find.text('Добавить ✦2'), findsOneWidget);
    expect(find.text('21:05'), findsOneWidget);
    expect(find.text('Главная'), findsOneWidget);
  });

  testWidgets('an empty day reads in Estonian', (tester) async {
    setScreenSize(tester, height: 2000);
    await _pump(tester, const Locale('et'), withEntries: false);

    expect(find.text('PÄEVIK'), findsOneWidget);
    expect(find.text('Päev 2 — vaikne päev'), findsOneWidget);
    expect(
      find.text('Veel pole fotosid ega märkmeid · 0 tegevust tehtud'),
      findsOneWidget,
    );
    expect(find.text('2. päevast pole veel midagi'), findsOneWidget);
    expect(find.text('＋ Lisa foto'), findsOneWidget);
  });

  for (final locale in const [Locale('en'), Locale('ru'), Locale('et')]) {
    for (final withEntries in const [true, false]) {
      testWidgets('Journal lays out without overflow at 360pt in '
          '${locale.languageCode} (entries: $withEntries)', (tester) async {
        setScreenSize(tester, height: 2000);
        await _pump(tester, locale, withEntries: withEntries);

        expect(tester.takeException(), isNull);
      });
    }
  }
}
