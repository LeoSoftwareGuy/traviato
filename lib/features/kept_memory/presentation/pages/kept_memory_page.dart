import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/route_constants.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/async_error_retry_scaffold.dart';
import '../../../trip/presentation/widgets/delete_memory_sheet.dart';
import '../../../wrap_up/presentation/controllers/wrap_up_controller.dart';
import '../../../wrap_up/presentation/film/wrap_up_film_scenes.dart';
import '../../../wrap_up/presentation/widgets/film_out_of_date_chip.dart';
import '../../domain/entities/kept_memory.dart';
import '../kept_memory_labels.dart';
import '../providers/kept_memory_provider.dart';
import '../widgets/kept_memory_actions.dart';
import '../widgets/kept_memory_day_chapter.dart';
import '../widgets/kept_memory_hero.dart';
import '../widgets/kept_memory_plan_card.dart';
import 'kept_memory_viewer_page.dart';

const _sidePadding = 22.0;

/// Every photo and note from a kept memory, day by day, with the film on
/// top (#279, docs/design/kept-memory/KEPT_MEMORY_PAGE_SPEC.md option 1b).
/// Read-only: nothing here edits the memory — except offering to rebuild
/// the film once its photos changed (#294).
class KeptMemoryPage extends ConsumerWidget {
  const KeptMemoryPage({required this.tripId, super.key});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoryAsync = ref.watch(keptMemoryProvider(tripId));
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.screenGroundRadial(
            AppGradients.groundTopLandingAuth,
          ),
        ),
        child: memoryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncErrorRetryScaffold(
            message: presentationFailureMessage(error, context.l10n),
            onRetry: () => ref.invalidate(keptMemoryProvider(tripId)),
          ),
          data: (memory) => _KeptMemoryScroll(memory: memory),
        ),
      ),
    );
  }
}

class _KeptMemoryScroll extends ConsumerWidget {
  const _KeptMemoryScroll({required this.memory});

  final KeptMemory memory;

  String get _tripId => memory.trip.id;

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(RouteNames.home);
    }
  }

  Future<void> _more(BuildContext context) async {
    final deleted = await DeleteMemorySheet.show(
      context,
      tripId: _tripId,
      tripName: memory.trip.name,
    );
    if (deleted == true && context.mounted) context.goNamed(RouteNames.home);
  }

  void _playFilm(BuildContext context) => context.pushNamed(
    RouteNames.tripWrapUp,
    pathParameters: {'tripId': _tripId},
    queryParameters: {RouteQuery.from: RouteQuery.fromMemory},
  );

  void _openViewer(BuildContext context, int index, {bool autoplay = false}) =>
      KeptMemoryViewerPage.show(
        context,
        memory: memory,
        initialIndex: index,
        autoplay: autoplay,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching the film here also keeps it loaded, so "Play the film"
    // opens without a second wait. A kept film is frozen — no AI call.
    final film = ref.watch(wrapUpControllerProvider(_tripId)).value;
    final filmDuration = film == null
        ? null
        : Duration(
            milliseconds: (WrapUpFilmScenes.forWrapUp(film.wrapUp).total * 1000)
                .round(),
          );
    final keptAt = memory.trip.wrapUpPublishedAt;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: KeptMemoryHero(
            memory: memory,
            onBack: () => _back(context),
            onMore: () => _more(context),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(_sidePadding, 14, _sidePadding, 0),
          sliver: SliverToBoxAdapter(
            child: KeptMemoryActions(
              filmDuration: filmDuration,
              onPlayFilm: () => _playFilm(context),
              onSlideshow: memory.photos.isEmpty
                  ? null
                  : () => _openViewer(context, 0, autoplay: true),
            ),
          ),
        ),
        if (film?.isOutOfDate ?? false)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              _sidePadding,
              12,
              _sidePadding,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Center(child: FilmOutOfDateChip(tripId: _tripId)),
            ),
          ),
        SliverList.builder(
          itemCount: memory.days.length,
          itemBuilder: (context, index) => Padding(
            padding: EdgeInsets.only(top: index == 0 ? 30 : 34),
            child: KeptMemoryDayChapter(
              day: memory.days[index],
              onOpenPhoto: (photoIndex) => _openViewer(context, photoIndex),
            ),
          ),
        ),
        if (memory.plan.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              _sidePadding,
              34,
              _sidePadding,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: KeptMemoryPlanCard(plan: memory.plan),
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            _sidePadding,
            26,
            _sidePadding,
            48 + bottomInset,
          ),
          sliver: SliverToBoxAdapter(
            child: Text(
              (keptAt == null
                      ? context.l10n.home_keptForever
                      : context.l10n.keptMemory_since(
                          KeptMemoryLabels.keptDate(
                            keptAt,
                            context.l10n.localeName,
                          ),
                        ))
                  .toUpperCase(),
              textAlign: TextAlign.center,
              style: AppTypography.mono,
            ),
          ),
        ),
      ],
    );
  }
}
