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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'The director has not run for this memory yet. Re-run it, or '
            'check WRAP_UP_DIRECTOR_USER_IDS for this account.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final urls =
        ref.watch(filmPlanPhotoUrlsProvider(tripId)).value ??
        const <String, String>{};
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.base),
      children: [
        _SummaryCard(report: report),
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
              '${report.ranAt?.toLocal() ?? '—'}',
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
