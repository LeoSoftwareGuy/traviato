import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:traviato/core/config/router/route_constants.dart';
import 'package:traviato/features/journal/presentation/providers/day_note_providers.dart';
import 'package:traviato/features/photo/presentation/providers/photo_providers.dart';
import 'package:traviato/features/quest/presentation/pages/plan_page.dart';
import 'package:traviato/features/quest/presentation/providers/quest_providers.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';

import '../../../helpers/localized_app.dart';
import '../../journal/fakes/fake_day_note_repository.dart';
import '../../photo/fakes/fake_photo_repository.dart';
import '../../trip/fakes/fake_trip_repository.dart';
import '../fakes/fake_quest_repository.dart';

DateTime get _today {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

Future<void> _pump(WidgetTester tester, Locale locale) async {
  final router = GoRouter(
    initialLocation: '/plan',
    routes: [
      GoRoute(
        path: '/plan',
        builder: (context, state) => const PlanPage(tripId: 't1'),
      ),
      GoRoute(
        path: '/memory/:tripId/checklist',
        name: RouteNames.tripChecklist,
        builder: (context, state) => const Scaffold(),
      ),
      GoRoute(
        path: '/home',
        name: RouteNames.home,
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
        questRepositoryProvider.overrideWithValue(
          FakeQuestRepository()
            ..questsResult = Right([
              buildQuestEntity(id: 'q1', dayDate: _today, title: 'Old Town'),
              buildQuestEntity(id: 'q2', dayDate: _today, title: 'Kadriorg'),
            ]),
        ),
        photoRepositoryProvider.overrideWithValue(FakePhotoRepository()),
        dayNoteRepositoryProvider.overrideWithValue(FakeDayNoteRepository()),
      ],
      child: localizedRouterApp(locale: locale, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Plan reads in Russian; user quest titles untouched', (
    tester,
  ) async {
    setScreenSize(tester, height: 1600);
    await _pump(tester, const Locale('ru'));

    expect(find.text('ПЛАН'), findsOneWidget);
    expect(find.text('Изменить'), findsOneWidget);
    expect(find.text('День 2 из 5'), findsOneWidget);
    expect(find.text('2 дела в плане · всего 5 дней'), findsOneWidget);
    expect(find.text('День 2'), findsOneWidget);
    expect(find.textContaining('готово 0 из 2'), findsOneWidget);
    expect(find.text('+ Добавить дело на день 2'), findsOneWidget);
    expect(find.text('Old Town'), findsOneWidget);
    expect(find.text('Главная'), findsOneWidget);

    await tester.tap(find.byKey(const Key('quest-check-q1')));
    await tester.pump();
    expect(find.text('+1 ✦ · дело сделано'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('manage sheet reads in Russian', (tester) async {
    setScreenSize(tester, height: 1600);
    await _pump(tester, const Locale('ru'));

    await tester.tap(find.text('Изменить'));
    await tester.pumpAndSettle();

    expect(find.text('Изменить событие'), findsOneWidget);
    expect(find.text('Переименовать'), findsOneWidget);
    expect(find.text('ОБЛОЖКА'), findsOneWidget);
    expect(find.text('НАЧАЛО'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final locale in const [Locale('en'), Locale('ru')]) {
    testWidgets('Plan lays out without overflow at 360pt in '
        '${locale.languageCode}', (tester) async {
      setScreenSize(tester, height: 1600);
      await _pump(tester, locale);

      expect(tester.takeException(), isNull);
    });
  }
}
