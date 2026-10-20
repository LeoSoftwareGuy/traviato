import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/features/auth/presentation/providers/auth_providers.dart';
import 'package:traviato/features/checklist/presentation/providers/checklist_providers.dart';
import 'package:traviato/features/home/domain/entities/profile_stats_entity.dart';
import 'package:traviato/features/home/presentation/pages/home_page.dart';
import 'package:traviato/features/home/presentation/providers/profile_stats_provider.dart';
import 'package:traviato/features/journal/presentation/providers/day_note_providers.dart';
import 'package:traviato/features/photo/presentation/providers/photo_providers.dart';
import 'package:traviato/features/quest/presentation/providers/quest_providers.dart';
import 'package:traviato/features/trip/domain/entities/trip_card_entity.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';

import '../../../../helpers/localized_app.dart';
import '../../../auth/fakes/fake_auth_repository.dart';
import '../../../checklist/fakes/fake_checklist_repository.dart';
import '../../../journal/fakes/fake_day_note_repository.dart';
import '../../../photo/fakes/fake_photo_repository.dart';
import '../../../quest/fakes/fake_quest_repository.dart';
import '../../../trip/fakes/fake_trip_repository.dart';
import '../../fakes/fake_profile_stats_repository.dart';

DateTime get _today {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

List<TripCardEntity> _trips() => [
  buildTripCard(
    id: 'now',
    name: 'Tallinn weekend',
    startDate: _today.subtract(const Duration(days: 1)),
    endDate: _today.add(const Duration(days: 3)),
    vibes: const ['Road trip'],
    status: TripStatus.current,
  ),
  buildTripCard(
    id: 'soon',
    name: 'Riga',
    startDate: _today.add(const Duration(days: 4)),
    endDate: _today.add(const Duration(days: 6)),
    status: TripStatus.upcoming,
    questCount: 5,
  ),
  buildTripCard(
    id: 'done',
    name: 'Tartu',
    startDate: _today.subtract(const Duration(days: 30)),
    endDate: _today.subtract(const Duration(days: 30)),
    status: TripStatus.finished,
    durationDays: 1,
    photoCount: 21,
    wrapUpPublishedAt: _today,
  ),
];

Future<void> _pump(WidgetTester tester, Locale locale) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        tripRepositoryProvider.overrideWithValue(
          FakeTripRepository()..tripsResult = Right(_trips()),
        ),
        questRepositoryProvider.overrideWithValue(FakeQuestRepository()),
        checklistRepositoryProvider.overrideWithValue(
          FakeChecklistRepository(),
        ),
        profileStatsRepositoryProvider.overrideWithValue(
          FakeProfileStatsRepository()
            ..statsResult = const Right(
              ProfileStatsEntity(
                memories: 5,
                places: 2,
                countries: 1,
                days: 21,
                stars: 47,
                photos: 0,
                notes: 0,
              ),
            ),
        ),
        photoRepositoryProvider.overrideWithValue(FakePhotoRepository()),
        dayNoteRepositoryProvider.overrideWithValue(FakeDayNoteRepository()),
      ],
      child: localizedApp(locale: locale, home: const HomePage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Home reads in Russian', (tester) async {
    setScreenSize(tester, height: 2400);
    await _pump(tester, const Locale('ru'));

    // No username in this fixture: the greeting has no placeholder name.
    expect(find.text('Привет!'), findsOne);
    expect(find.text('5'), findsWidgets);
    expect(find.text('СОБЫТИЙ'), findsOneWidget);
    expect(find.text('МЕСТА'), findsOneWidget);
    expect(find.text('ДЕНЬ'), findsOneWidget);
    expect(find.text('СЕЙЧАС'), findsOneWidget);
    expect(find.text('День 2 из 5'), findsOneWidget);
    expect(find.text('Автопутешествие'), findsOneWidget);
    expect(find.text('Дневник'), findsOneWidget);
    expect(find.text('Чек-лист'), findsOneWidget);
    expect(find.text('СКОРО'), findsOneWidget);
    expect(find.text('через 4 дн.'), findsOneWidget);
    expect(find.text('5 дел в плане'), findsOneWidget);
    expect(find.text('СОХРАНЕНО НАВСЕГДА'), findsOneWidget);
    expect(find.text('✦ Сохранено навсегда'), findsOneWidget);
    expect(find.text('1 ДЕНЬ · 21 ФОТО'), findsOneWidget);
  });

  for (final locale in const [Locale('en'), Locale('ru')]) {
    testWidgets('Home lays out without overflow at 360pt in '
        '${locale.languageCode}', (tester) async {
      setScreenSize(tester, height: 2400);
      await _pump(tester, locale);

      expect(tester.takeException(), isNull);
    });
  }
}
