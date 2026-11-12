import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/photo/presentation/providers/photo_providers.dart';
import 'package:traviato/features/settings/domain/app_language.dart';
import 'package:traviato/features/settings/presentation/controllers/app_language_controller.dart';
import 'package:traviato/features/wrap_up/domain/entities/film_director_report.dart';
import 'package:traviato/features/wrap_up/domain/entities/film_photo_analysis.dart';
import 'package:traviato/features/wrap_up/domain/entities/film_plan_chapter.dart';
import 'package:traviato/features/wrap_up/domain/entities/film_plan_inspection.dart';
import 'package:traviato/features/wrap_up/domain/entities/film_plan_scene.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_sky.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';
import 'package:traviato/features/wrap_up/presentation/pages/film_plan_inspector_page.dart';
import 'package:traviato/features/wrap_up/presentation/providers/film_director_providers.dart';
import 'package:traviato/features/wrap_up/presentation/providers/wrap_up_providers.dart';

import '../../../photo/fakes/fake_photo_repository.dart';
import '../../../trip/fakes/fake_trip_repository.dart';
import '../../fakes/fake_film_director_repository.dart';
import '../../fakes/fake_wrap_up_repository.dart';

const _planned = FilmDirectorReport(
  isPlanned: true,
  occasion: 'city',
  recipe: 'keepsake',
  musicEnergy: 'calm',
  reasoning: 'A quiet city trip.',
  chapters: [
    FilmPlanChapter(
      bridgeLine: 'You came for the canals.',
      scenes: [
        FilmPlanScene(
          type: 'card_flip',
          photoIds: ['p1'],
          durationSeconds: 5,
          isHero: true,
        ),
        FilmPlanScene(
          type: 'text_card',
          text: 'Then the rain.',
          durationSeconds: 4,
        ),
      ],
    ),
  ],
  footnoteLine: 'Three days, one umbrella.',
  closingLine: 'You left with dry socks, barely.',
  attempts: 1,
  model: 'claude-sonnet-5',
  inputTokens: 5800,
  outputTokens: 680,
  estimatedUsd: 0.0184,
);

const _analysis = FilmPhotoAnalysis(
  photoId: 'p1',
  summary: 'A canal at dusk',
  setting: 'city',
  people: '0',
  energy: 'calm',
  quality: 'sharp',
  heroScore: 4,
);

Future<void> _pump(
  WidgetTester tester,
  FakeFilmDirectorRepository repo, {
  WrapUpSky? sky,
}) {
  return tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        filmDirectorRepositoryProvider.overrideWithValue(repo),
        wrapUpRepositoryProvider.overrideWithValue(
          FakeWrapUpRepository()
            ..getOrGenerateResult = Right(buildWrapUpEntity(sky: sky)),
        ),
        tripRepositoryProvider.overrideWithValue(FakeTripRepository()),
        photoRepositoryProvider.overrideWithValue(
          FakePhotoRepository()
            ..photosResult = Right([
              for (final id in ['p1', 'p2', 'p3'])
                buildPhotoEntity(
                  id: id,
                  imageUrl: 'https://img.test/$id.jpg',
                  placeText: 'Alfama',
                ),
            ]),
        ),
        resolvedAppLanguageProvider.overrideWithValue(AppLanguage.en),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const FilmPlanInspectorPage(tripId: 't1'),
      ),
    ),
  );
}

void main() {
  testWidgets('shows a spinner while loading', (tester) async {
    final repo = FakeFilmDirectorRepository()
      ..delay = const Duration(milliseconds: 100);
    await _pump(tester, repo);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('shows the failure with a retry', (tester) async {
    final repo = FakeFilmDirectorRepository()
      ..inspectionResult = const Left(ServerFailure(message: 'boom'));
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    repo.inspectionResult = const Right(FilmPlanInspection());
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(repo.getInspectionCallCount, 2);
  });

  testWidgets('says when the director never ran', (tester) async {
    await _pump(tester, FakeFilmDirectorRepository());
    await tester.pumpAndSettle();

    expect(find.textContaining('has not run'), findsOneWidget);
  });

  testWidgets('shows the plan: recipe, chapters, scenes, lines and cost', (
    tester,
  ) async {
    final repo = FakeFilmDirectorRepository()
      ..inspectionResult = const Right(
        FilmPlanInspection(report: _planned, analyses: {'p1': _analysis}),
      );
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    expect(find.text('planned · keepsake · city'), findsOneWidget);
    expect(find.text('You came for the canals.'), findsOneWidget);
    expect(find.text('card_flip · 5.0s · HERO'), findsOneWidget);
    expect(find.text('“Then the rain.”'), findsOneWidget);
    expect(find.textContaining('A canal at dusk'), findsOneWidget);
    expect(find.textContaining('0.0184', findRichText: true), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('dry socks', findRichText: true),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.textContaining('dry socks', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('a fallback shows its problems', (tester) async {
    final repo = FakeFilmDirectorRepository()
      ..inspectionResult = const Right(
        FilmPlanInspection(
          report: FilmDirectorReport(
            isPlanned: false,
            problems: ['closing_line: banned phrase "epic"'],
          ),
        ),
      );
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    expect(find.text('fallback — the template film plays'), findsOneWidget);
    expect(find.textContaining('banned phrase'), findsOneWidget);
  });

  testWidgets('Re-run director reruns in the UI language and reloads', (
    tester,
  ) async {
    final repo = FakeFilmDirectorRepository();
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('film-plan-rerun')));
    await tester.pumpAndSettle();

    expect(repo.rerunCallCount, 1);
    expect(repo.lastLanguage, 'en');
    expect(repo.getInspectionCallCount, 2);
  });

  group('Sky Story card (#345)', () {
    final sky = WrapUpSky(
      isFromDirector: false,
      title: 'Lisbon',
      momentCount: 3,
      pages: [
        WrapUpSkyPage(
          firstDay: 1,
          date: DateTime(2026, 6, 12),
          photoCount: 3,
          heroPhotoId: 'p1',
          extraPhotoIds: const ['p2', 'p3', 'gone'],
        ),
      ],
    );

    Future<void> scrollTo(WidgetTester tester, Finder finder) =>
        tester.scrollUntilVisible(
          finder,
          200,
          scrollable: find.byType(Scrollable).first,
        );

    testWidgets('shows the pages the film will play and why', (tester) async {
      final repo = FakeFilmDirectorRepository()
        ..inspectionResult = const Right(
          FilmPlanInspection(
            report: FilmDirectorReport(
              isPlanned: true,
              runCount: 2,
              skyProblems: ['sky_story.pages[0].days: [0, 9] is not within'],
            ),
          ),
        );
      await _pump(tester, repo, sky: sky);
      await tester.pumpAndSettle();

      await scrollTo(tester, find.byKey(const Key('film-plan-sky-preview')));
      expect(find.text('code-built pages (fallback)'), findsOneWidget);
      expect(find.textContaining('is not within'), findsOneWidget);
      expect(find.text('Day 1 · fan · 3 photos'), findsOneWidget);
      expect(find.text('(Alfama — no headline)'), findsOneWidget);
      expect(
        find.textContaining('caption goes on the sky', findRichText: true),
        findsOneWidget,
      );
      // 1 page: 5 + 2 + 14.5 + 3 + 8.
      expect(
        find.textContaining('1 page(s) · 32.5s', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('says when the classic film plays instead', (tester) async {
      await _pump(tester, FakeFilmDirectorRepository());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('film-plan-sky-none')), findsOneWidget);
    });
  });
}
