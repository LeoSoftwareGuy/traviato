import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/photo/presentation/providers/photo_providers.dart';
import 'package:traviato/features/settings/domain/app_language.dart';
import 'package:traviato/features/settings/presentation/controllers/app_language_controller.dart';
import 'package:traviato/features/wrap_up/domain/entities/film_neon_slot.dart';
import 'package:traviato/features/wrap_up/domain/entities/film_director_report.dart';
import 'package:traviato/features/wrap_up/domain/entities/film_photo_analysis.dart';
import 'package:traviato/features/wrap_up/domain/entities/film_plan_chapter.dart';
import 'package:traviato/features/wrap_up/domain/entities/film_plan_inspection.dart';
import 'package:traviato/features/wrap_up/domain/entities/film_plan_scene.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_golden_vows.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_neon_night.dart';
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
  WrapUpNeonNight? neonNight,
  WrapUpGoldenVows? goldenVows,
}) {
  return tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        filmDirectorRepositoryProvider.overrideWithValue(repo),
        wrapUpRepositoryProvider.overrideWithValue(
          FakeWrapUpRepository()
            ..getOrGenerateResult = Right(
              buildWrapUpEntity(
                sky: sky,
                neonNight: neonNight,
                goldenVows: goldenVows,
              ),
            ),
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

  group('Neon Night card (#363)', () {
    final neonNight = WrapUpNeonNight(
      title: 'Night out',
      startDate: DateTime(2026, 11, 14),
      chapters: [
        WrapUpNeonChapter(
          title: 'Doors open',
          note: 'Queue was worth it.',
          photos: [
            WrapUpNeonPhoto(id: 'p1', takenAt: DateTime(2026, 11, 14, 22)),
            WrapUpNeonPhoto(id: 'p2', takenAt: DateTime(2026, 11, 14, 23)),
          ],
          moments: const [
            WrapUpNeonMoment(type: 'split', photoIds: ['p1', 'p2']),
          ],
        ),
      ],
      headline: 'Best night ever',
    );

    Future<void> scrollTo(WidgetTester tester, Finder finder) =>
        tester.scrollUntilVisible(
          finder,
          200,
          scrollable: find.byType(Scrollable).first,
        );

    testWidgets('shows the chapters the film will play', (tester) async {
      final repo = FakeFilmDirectorRepository()
        ..inspectionResult = const Right(
          FilmPlanInspection(
            report: FilmDirectorReport(isPlanned: true, hasNeonNight: true),
          ),
        );
      await _pump(tester, repo, neonNight: neonNight);
      await tester.pumpAndSettle();

      await scrollTo(
        tester,
        find.byKey(const Key('film-plan-neon-night-plays')),
      );
      expect(find.text('Plays first'), findsOneWidget);
      expect(
        find.textContaining('Doors open (22:00–23:00)', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('split · Queue was worth it.', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('Copy storyboard copies the film as a table (#442)', (
      tester,
    ) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final repo = FakeFilmDirectorRepository()
        ..inspectionResult = const Right(
          FilmPlanInspection(
            report: FilmDirectorReport(isPlanned: true, hasNeonNight: true),
          ),
        );
      await _pump(tester, repo, neonNight: neonNight);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('film-plan-storyboard')));
      await tester.pumpAndSettle();

      expect(copied, contains('· Neon Night'));
      expect(copied, contains('Ch 1 card · Doors open'));
      expect(find.text('Storyboard copied'), findsOneWidget);
    });

    testWidgets(
      'Golden Vows: its slots, why a wedding, photos shown, trims (#458)',
      (
        tester,
      ) async {
        final repo = FakeFilmDirectorRepository()
          ..inspectionResult = const Right(
            FilmPlanInspection(
              report: FilmDirectorReport(
                isPlanned: false,
                gvSlots: [
                  FilmNeonSlot(
                    slot: 'ch1.title',
                    candidates: [
                      FilmNeonCandidate(id: 'c:p2', text: 'Сена', score: 23),
                    ],
                    chosenIds: ['free'],
                    chosen: ['Утро у Сены'],
                    freeText: 'Утро у Сены',
                    source: 'director',
                    reason: "director's pick",
                  ),
                ],
                gvTrims: ['main3.note: no note'],
                gvShownPages: 2,
                gvShownPhotos: 3,
                gvUnlisted: ['Было хорошо. — generic'],
                gvTrigger: '«свадьба» in note n1',
              ),
            ),
          );
        await _pump(
          tester,
          repo,
          goldenVows: WrapUpGoldenVows(
            occasion: 'wedding',
            names: 'Анна и Марко',
            startDate: DateTime(2026, 6, 14),
            heroes: const [
              WrapUpGoldenVowsHero(photoId: 'p1', label: 'Клятвы'),
            ],
            chapters: const [
              WrapUpGoldenVowsChapter(
                title: 'Утро у Сены',
                photoIds: ['p2', 'p3'],
              ),
            ],
            heartPhotoIds: const ['p1', 'p2', 'p3'],
          ),
        );
        await tester.pumpAndSettle();

        await scrollTo(tester, find.byKey(const Key('film-plan-gv-trims')));
        expect(
          find.textContaining('«свадьба» in note n1', findRichText: true),
          findsOneWidget,
        );
        expect(
          find.textContaining('2 / 3 photos on pages', findRichText: true),
          findsOneWidget,
        );
        expect(
          find.textContaining('main3.note: no note', findRichText: true),
          findsOneWidget,
        );
        expect(
          find.textContaining('Было хорошо. — generic', findRichText: true),
          findsOneWidget,
        );
        await scrollTo(
          tester,
          find.byKey(const Key('film-plan-gv-slot-ch1.title')),
        );
        expect(find.text('free: Утро у Сены'), findsOneWidget);
      },
    );

    testWidgets('shows every slot: candidates, the pick, what plays (#454)', (
      tester,
    ) async {
      final repo = FakeFilmDirectorRepository()
        ..inspectionResult = const Right(
          FilmPlanInspection(
            report: FilmDirectorReport(
              isPlanned: true,
              neonSlots: [
                FilmNeonSlot(
                  slot: 'ch5.title',
                  candidates: [
                    FilmNeonCandidate(
                      id: 'n:a:1',
                      text: 'В Брюсель',
                      score: 25,
                    ),
                  ],
                  pickedIds: ['n:a:1'],
                  freeText: 'Брюссель',
                  chosenIds: ['free'],
                  chosen: ['Брюссель'],
                  source: 'director',
                  reason: "director's pick",
                ),
                FilmNeonSlot(
                  slot: 'ch2.card',
                  candidates: [
                    FilmNeonCandidate(id: 'n:b:1', text: 'Пиво!', score: 9),
                  ],
                  pickedIds: ['n:x:9'],
                  chosenIds: ['n:b:1'],
                  chosen: ['Пиво!'],
                  source: 'code',
                  reason: "ch1.m1/n:x:9: from ch1.m1's list, valid only there",
                ),
              ],
            ),
          ),
        );
      await _pump(tester, repo);
      await tester.pumpAndSettle();

      await scrollTo(
        tester,
        find.byKey(const Key('film-plan-neon-slot-ch2.card')),
      );
      expect(
        find.textContaining(
          '1 of 2 slot(s) by the director',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('ch5.title · director', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('free: Брюссель'), findsOneWidget);
      // ✓ plays, → the director picked.
      expect(find.text(' → 25 · В Брюсель'), findsOneWidget);
      expect(find.text('✓  9 · Пиво!'), findsOneWidget);
      expect(find.textContaining('valid only there'), findsOneWidget);
    });

    testWidgets('says why there is none', (tester) async {
      final repo = FakeFilmDirectorRepository()
        ..inspectionResult = const Right(
          FilmPlanInspection(
            report: FilmDirectorReport(
              isPlanned: true,
              neonNightProblems: ['neon_night.chapters: 0'],
            ),
          ),
        );
      await _pump(tester, repo);
      await tester.pumpAndSettle();

      await scrollTo(
        tester,
        find.byKey(const Key('film-plan-neon-night-none')),
      );
      expect(find.textContaining('stayed invalid'), findsOneWidget);
      expect(
        find.textContaining('neon_night.chapters: 0'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('film-plan-neon-night-plays')), findsNothing);
    });
  });
}
