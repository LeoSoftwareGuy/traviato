import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/route_constants.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/async_error_retry_scaffold.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../../domain/entities/film_director_report.dart';
import '../../domain/entities/film_photo_analysis.dart';
import '../../domain/entities/film_plan_chapter.dart';
import '../../domain/entities/film_plan_inspection.dart';
import '../../domain/entities/film_plan_scene.dart';
import '../controllers/wrap_up_controller.dart';
import '../film/golden_vows/golden_vows_timeline.dart';
import '../film/sky_story/sky_story.dart';
import '../film/sky_story/sky_story_copy.dart';
import '../film/sky_story/sky_story_timeline.dart';
import '../mutations/film_director_mutations.dart';
import '../providers/film_director_providers.dart';

/// Debug-only Plan inspector (#328): what the wrap-up director decided for
/// one memory — recipe and reasoning, chapters and scenes with their
/// photos, the lines, and what the run cost — so plans can be judged on
/// real memories. Routed only in debug builds and never shown to users, so
/// its copy is plain English rather than localized.
class FilmPlanInspectorPage extends ConsumerWidget {
  const FilmPlanInspectorPage({required this.tripId, super.key});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inspection = ref.watch(filmPlanInspectionProvider(tripId));
    final isRerunning = ref.watch(rerunDirectorMutation) is MutationPending;
    ref.listen<MutationState<void>>(rerunDirectorMutation, (_, next) {
      if (next is MutationError) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(next.error, context.l10n),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Plan inspector', style: AppTypography.screenTitle),
        actions: [
          IconButton(
            key: const Key('film-plan-sky-story'),
            tooltip: 'Preview Sky Story',
            onPressed: () => context.pushNamed(RouteNames.skyStoryPreview),
            icon: const Icon(Icons.air),
          ),
          IconButton(
            key: const Key('film-plan-golden-vows'),
            tooltip: 'Preview Golden Vows',
            onPressed: () => context.pushNamed(RouteNames.goldenVowsPreview),
            icon: const Icon(Icons.favorite_border),
          ),
          IconButton(
            key: const Key('film-plan-neon-night'),
            tooltip: 'Preview Neon Night',
            onPressed: () => context.pushNamed(RouteNames.neonNightPreview),
            icon: const Icon(Icons.nightlife),
          ),
          TextButton.icon(
            key: const Key('film-plan-rerun'),
            onPressed: isRerunning
                ? null
                : () => runRerunDirector(ref: ref, tripId: tripId),
            icon: isRerunning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: const Text('Re-run director'),
          ),
        ],
      ),
      body: inspection.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AsyncErrorRetryScaffold(
          message: presentationFailureMessage(error, context.l10n),
          onRetry: () => ref.invalidate(filmPlanInspectionProvider(tripId)),
        ),
        data: (data) => _InspectionBody(tripId: tripId, inspection: data),
      ),
    );
  }
}

class _InspectionBody extends ConsumerWidget {
  const _InspectionBody({required this.tripId, required this.inspection});

  final String tripId;
  final FilmPlanInspection inspection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = inspection.report;
    if (report == null) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'The director has not run for this memory yet. Re-run it, '
              'or check that WRAP_UP_DIRECTOR_USER_IDS is not "off".',
              textAlign: TextAlign.center,
            ),
          ),
          _GoldenVowsCard(tripId: tripId, report: null),
          _SkyStoryCard(tripId: tripId, report: null),
        ],
      );
    }
    final urls =
        ref.watch(filmPlanPhotoUrlsProvider(tripId)).value ??
        const <String, String>{};
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.base),
      children: [
        _SummaryCard(report: report),
        _GoldenVowsCard(tripId: tripId, report: report),
        _SkyStoryCard(tripId: tripId, report: report),
        if (report.problems.isNotEmpty)
          _ProblemsCard(problems: report.problems),
        for (final (index, chapter) in report.chapters.indexed)
          _ChapterCard(
            index: index,
            chapter: chapter,
            urls: urls,
            analyses: inspection.analyses,
          ),
        if (report.isPlanned) _LinesCard(report: report),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.surfaceBorder),
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: AppTypography.mono),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label  ',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            TextSpan(text: value, style: AppTypography.bodyInput),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.report});

  final FilmDirectorReport report;

  @override
  Widget build(BuildContext context) {
    final status = report.isPlanned
        ? 'planned · ${report.recipe} · ${report.occasion}'
        : 'fallback — the template film plays';
    return _Card(
      title: 'Director',
      children: [
        Text(
          status,
          key: const Key('film-plan-status'),
          style: AppTypography.headlineSerif.copyWith(
            color: report.isPlanned ? AppColors.success : AppColors.accentCoral,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (report.reasoning != null) _Line('Reasoning', report.reasoning!),
        if (report.isPlanned) ...[
          _Line('Music', report.musicEnergy ?? '—'),
          _Line(
            'Length',
            '${report.durationSeconds.toStringAsFixed(1)}s of scenes in '
                '${report.chapters.length} chapters',
          ),
        ],
        _Line(
          'Photos',
          '${report.plannablePhotos} plannable · ${report.analysedNow} '
              'analysed now · ${report.cachedPhotos} cached · '
              '${report.failedPhotos} failed',
        ),
        _Line(
          'Tokens',
          '${report.inputTokens} in · ${report.outputTokens} out · '
              '≈ \$${report.estimatedUsd.toStringAsFixed(4)}',
        ),
        _Line(
          'Run',
          '${report.model} · ${report.attempts} plan attempt(s) · '
              'run ${report.runCount} · ${report.ranAt?.toLocal() ?? '—'}',
        ),
      ],
    );
  }
}

class _ProblemsCard extends StatelessWidget {
  const _ProblemsCard({required this.problems});

  final List<String> problems;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Problems (${problems.length})',
      children: [
        for (final problem in problems)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              '• $problem',
              style: AppTypography.caption.copyWith(
                color: AppColors.accentCoral,
              ),
            ),
          ),
      ],
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.index,
    required this.chapter,
    required this.urls,
    required this.analyses,
  });

  final int index;
  final FilmPlanChapter chapter;
  final Map<String, String> urls;
  final Map<String, FilmPhotoAnalysis> analyses;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title:
          'Chapter ${index + 1} · '
          '${chapter.durationSeconds.toStringAsFixed(1)}s',
      children: [
        Text(chapter.bridgeLine, style: AppTypography.pullQuote),
        const SizedBox(height: AppSpacing.sm),
        for (final scene in chapter.scenes)
          _SceneRow(scene: scene, urls: urls, analyses: analyses),
      ],
    );
  }
}

class _SceneRow extends StatelessWidget {
  const _SceneRow({
    required this.scene,
    required this.urls,
    required this.analyses,
  });

  final FilmPlanScene scene;
  final Map<String, String> urls;
  final Map<String, FilmPhotoAnalysis> analyses;

  @override
  Widget build(BuildContext context) {
    final header = [
      scene.type,
      '${scene.durationSeconds}s',
      if (scene.isHero) 'HERO',
      if (scene.captionNoteId != null) 'note ${scene.captionNoteId}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            header,
            style: AppTypography.mono.copyWith(color: AppColors.primary),
          ),
          if (scene.text != null)
            Text('“${scene.text}”', style: AppTypography.bodyInput),
          if (scene.photoIds.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: 112,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final id in scene.photoIds)
                    _PhotoThumb(url: urls[id], analysis: analyses[id]),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.url, required this.analysis});

  final String? url;
  final FilmPhotoAnalysis? analysis;

  @override
  Widget build(BuildContext context) {
    final a = analysis;
    return Container(
      width: 88,
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.xs),
            child: SizedBox(
              width: 88,
              height: 66,
              child: url == null
                  ? const ColoredBox(color: AppColors.surfaceDisabled)
                  : CachedNetworkImage(
                      imageUrl: url!,
                      fit: BoxFit.cover,
                      memCacheWidth: 264,
                    ),
            ),
          ),
          if (a != null)
            Text(
              '★${a.heroScore} ${a.quality} · ${a.summary}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption,
            ),
        ],
      ),
    );
  }
}

class _LinesCard extends StatelessWidget {
  const _LinesCard({required this.report});

  final FilmDirectorReport report;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Lines',
      children: [
        _Line('Footnote', report.footnoteLine ?? '—'),
        _Line('Closing', report.closingLine ?? '—'),
      ],
    );
  }
}

/// Golden Vows as the film will play it (#346): from the draft's
/// `content.golden_vows` with the memory's photos, else what the director
/// chose and why its section wasn't used.
class _GoldenVowsCard extends ConsumerWidget {
  const _GoldenVowsCard({required this.tripId, required this.report});

  final String tripId;
  final FilmDirectorReport? report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wrapUpControllerProvider(tripId));
    final problems = report?.goldenVowsProblems ?? const <String>[];
    return _Card(
      title: 'Golden Vows',
      children: state.when(
        loading: () => const [LinearProgressIndicator()],
        error: (error, _) => [Text('Could not load the wrap-up: $error')],
        data: (data) {
          final story = data.goldenVows;
          if (story == null) {
            return [
              Text(
                problems.isEmpty
                    ? 'No Golden Vows: the director read this memory as '
                          'another occasion (or the section no longer fits '
                          'it). Sky Story plays.'
                    : "No Golden Vows: the director's section stayed "
                          'invalid. Sky Story plays.',
                key: const Key('film-plan-golden-vows-none'),
              ),
              for (final problem in problems) _ProblemLine(problem),
            ];
          }
          final length = GoldenVowsTimeline.forStory(story).total;
          return [
            Text(
              '${data.wrapUp.goldenVows?.occasion ?? '—'} · plays first',
              key: const Key('film-plan-golden-vows-occasion'),
              style: AppTypography.headlineSerif.copyWith(
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _Line(
              'Film',
              '${length.toStringAsFixed(1)}s · ${story.heroes.length} '
                  'hero(es) · ${story.chapters.length} chapter(s) · '
                  'carousel ${story.hasCarousel ? story.carousel!.photoIds.length : '—'}'
                  ' · ${story.heartPhotos.length} in the heart',
            ),
            _Line(
              'Packing',
              story.hasPackingCard
                  ? '${story.isPackedFromQuests ? 'quests' : 'checklist'}: '
                        '${story.packedShown.join(' · ')}'
                  : '— (no card)',
            ),
            _Line('Occasion line', story.occasionLine ?? '—'),
            for (final hero in story.heroes)
              _Line(hero.caption ?? 'Hero', hero.note ?? '— (no note)'),
            for (final chapter in story.chapters)
              _Line(
                '${chapter.title} (${chapter.layout?.name.toUpperCase() ?? 'cycle'})',
                chapter.line ?? '—',
              ),
            _Line('End line', story.endLine ?? '—'),
          ];
        },
      ),
    );
  }
}

class _ProblemLine extends StatelessWidget {
  const _ProblemLine(this.problem);

  final String problem;

  @override
  Widget build(BuildContext context) => Text(
    '• $problem',
    style: AppTypography.caption.copyWith(color: AppColors.accentCoral),
  );
}

/// Sky Story's pages as the film will play them (#345): from the draft's
/// `content.sky` with the memory's photos, plus why the director's own
/// pages weren't used, if they weren't.
class _SkyStoryCard extends ConsumerWidget {
  const _SkyStoryCard({required this.tripId, required this.report});

  final String tripId;
  final FilmDirectorReport? report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wrapUpControllerProvider(tripId));
    final problems = report?.skyProblems ?? const <String>[];
    return _Card(
      title: 'Sky Story',
      children: state.when(
        loading: () => const [LinearProgressIndicator()],
        error: (error, _) => [Text('Could not load the wrap-up: $error')],
        data: (data) {
          final story = data.skyStory;
          final sky = data.wrapUp.sky;
          if (story == null || sky == null) {
            return const [
              Text(
                "No Sky Story: no photos on the memory's days, or a kept "
                'film from before Sky Story. The classic film plays.',
                key: Key('film-plan-sky-none'),
              ),
            ];
          }
          final length = SkyStoryTimeline.forStory(story).total;
          return [
            Text(
              sky.isFromDirector
                  ? "director's pages"
                  : 'code-built pages (fallback)',
              key: const Key('film-plan-sky-source'),
              style: AppTypography.headlineSerif.copyWith(
                color: sky.isFromDirector
                    ? AppColors.success
                    : AppColors.accentCoral,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _Line(
              'Film',
              '${story.pages.length} page(s) · '
                  '${length.toStringAsFixed(1)}s · '
                  '${story.momentCount} moments · '
                  'signed ${story.names ?? '—'}',
            ),
            for (final problem in problems)
              Text(
                '• $problem',
                style: AppTypography.caption.copyWith(
                  color: AppColors.accentCoral,
                ),
              ),
            for (final (i, page) in story.pages.indexed)
              _SkyPageRow(
                page: page,
                layout: story.layouts[i],
                urls: data.photoUrlById,
              ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              key: const Key('film-plan-sky-preview'),
              onPressed: () => context.pushNamed(
                RouteNames.skyStoryPreview,
                queryParameters: {'trip': tripId},
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Preview this memory'),
            ),
          ];
        },
      ),
    );
  }
}

class _SkyPageRow extends StatelessWidget {
  const _SkyPageRow({
    required this.page,
    required this.layout,
    required this.urls,
  });

  final SkyPage page;
  final SkyPageLayout layout;
  final Map<String, String> urls;

  @override
  Widget build(BuildContext context) {
    final days = page.lastDay == null
        ? 'Day ${page.firstDay}'
        : 'Days ${page.firstDay}–${page.lastDay}';
    final headline =
        page.headline ??
        '(${SkyPageCopy.headlineFor(page, context.l10n)} — no headline)';
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$days · ${layout.name} · ${page.photoCount} photos',
            style: AppTypography.mono.copyWith(color: AppColors.primary),
          ),
          Text(headline, style: AppTypography.pullQuote),
          if (page.note != null)
            _Line('Note', '${page.note} — ${page.signature ?? 'unsigned'}')
          else if (page.skyLine != null)
            _Line('Sky line', page.skyLine!)
          else
            const _Line('No note', 'the caption goes on the sky'),
          SizedBox(
            height: 70,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final photo in [page.hero, ...page.extras])
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                      child: SizedBox(
                        width: photo == page.hero ? 88 : 56,
                        height: 66,
                        child: switch (urls[photo.id]) {
                          final url? => CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            memCacheWidth: 264,
                          ),
                          null => const ColoredBox(
                            color: AppColors.surfaceDisabled,
                          ),
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
