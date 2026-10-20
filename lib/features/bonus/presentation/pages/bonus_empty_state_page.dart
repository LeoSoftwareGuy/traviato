import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/router/route_constants.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/async_error_retry_scaffold.dart';
import '../../../trip/domain/entities/trip_card_entity.dart';
import '../../domain/entities/star_summary.dart';
import '../controllers/bonus_empty_state.dart';
import '../providers/bonus_empty_state_providers.dart';
import '../widgets/bonus_empty_hero.dart';
import '../widgets/bonus_page_top_bar.dart';
import '../widgets/star_earning_guide.dart';
import '../widgets/star_summary_block.dart';
import '../widgets/stars_footer_note.dart';
import '../widgets/tray_teaser_card.dart';
import '../widgets/upcoming_memory_card.dart';
import 'bonus_tasks_page.dart';

/// The Bonus page opened without a memory — Home's stars badge when nothing
/// is under way, or a notification without one (#219). Shows today's tray
/// if a memory turns out to be under way; otherwise when the next tray
/// opens (or how to get one) and where the user's stars came from.
class BonusEmptyStatePage extends ConsumerStatefulWidget {
  const BonusEmptyStatePage({super.key});

  @override
  ConsumerState<BonusEmptyStatePage> createState() =>
      _BonusEmptyStatePageState();
}

class _BonusEmptyStatePageState extends ConsumerState<BonusEmptyStatePage> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Back from the background the day may have turned, or stars moved on
    // another device — refetch (the state chain hangs off the trips).
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(bonusTripCardsProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(bonusEmptyStateProvider);
    if (stateAsync.value case BonusTrayActive(:final tripId)) {
      return BonusTasksPage(tripId: tripId);
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.screenGroundRadial(
            AppGradients.groundTopBonusProfile,
          ),
        ),
        child: SafeArea(
          child: stateAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => AsyncErrorRetryScaffold(
              message: presentationFailureMessage(error, context.l10n),
              onRetry: () => ref.invalidate(bonusTripCardsProvider),
            ),
            data: (state) => _NoTrayContent(state: state),
          ),
        ),
      ),
    );
  }
}

class _NoTrayContent extends StatelessWidget {
  const _NoTrayContent({required this.state});

  final BonusEmptyState state;

  @override
  Widget build(BuildContext context) {
    final summary = switch (state) {
      BonusUpcoming(:final summary) => summary,
      BonusNothingUpcoming(:final summary) => summary,
      BonusBrandNew() || BonusTrayActive() => const StarSummary.empty(),
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 34),
      children: [
        BonusPageTopBar(
          eyebrow: context.l10n.bonus_eyebrow,
          stars: summary.totalStars,
          onBack: () => context.pop(),
        ),
        const SizedBox(height: 20),
        switch (state) {
          final BonusUpcoming upcoming => _UpcomingIntro(state: upcoming),
          _ => _NothingUpcomingIntro(isFirstMemory: !summary.hasStars),
        },
        const SizedBox(height: 26),
        const Divider(height: 1, thickness: 1, color: AppColors.hairline),
        const SizedBox(height: 22),
        if (summary.hasStars)
          StarSummaryBlock(
            summary: summary,
            onMemoryTap: (trip) => context.pushNamed(
              RouteNames.tripJournal,
              pathParameters: {'tripId': trip.id},
            ),
            onAllMemoriesTap: () =>
                context.pushNamed(RouteNames.bonusStarsByMemory),
          )
        else
          const StarEarningGuide(),
        const SizedBox(height: 18),
        const StarsFooterNote(),
      ],
    );
  }
}

/// Frame 1a's top: when the next tray opens, the memory, a tray preview.
class _UpcomingIntro extends StatelessWidget {
  const _UpcomingIntro({required this.state});

  static const _weekdays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

  final BonusUpcoming state;

  void _openPlan(BuildContext context, TripCardEntity trip) =>
      context.pushNamed(
        RouteNames.tripPlan,
        pathParameters: {'tripId': trip.id},
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final trip = state.trip;
    final start = trip.startDate!;
    final date = DateFormat('d MMMM', l10n.localeName).format(start);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BonusEmptyHero(
          eyebrow: l10n.bonus_nextMemory,
          lead: l10n.bonus_upcomingLead,
          emphasis: l10n.bonus_upcomingEmphasis(
            _weekdays[start.weekday - 1],
            date,
          ),
          body: state.daysUntil == 1
              ? l10n.bonus_upcomingBodyTomorrow(trip.name)
              : l10n.bonus_upcomingBody(state.daysUntil, trip.name),
        ),
        const SizedBox(height: 16),
        UpcomingMemoryCard(trip: trip, onTap: () => _openPlan(context, trip)),
        const SizedBox(height: 22),
        Text(l10n.bonus_trayPreview.toUpperCase(), style: AppTypography.mono),
        const SizedBox(height: 10),
        for (final (i, template) in state.teasers.indexed) ...[
          if (i > 0) const SizedBox(height: 8),
          TrayTeaserCard(
            template: template,
            accent: i.isEven ? AppColors.primary : AppColors.accentBlue,
            icon: i.isEven
                ? Icons.photo_camera_outlined
                : Icons.explore_outlined,
          ),
        ],
        const SizedBox(height: 10),
        Text(
          l10n.bonus_trayCaption,
          style: bonusBodyStyle.copyWith(
            fontSize: 11.5,
            height: 1.55,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

/// Frames 1b/1c's top: no memory on the way → create one.
class _NothingUpcomingIntro extends StatelessWidget {
  const _NothingUpcomingIntro({required this.isFirstMemory});

  final bool isFirstMemory;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BonusEmptyHero(
          eyebrow: l10n.bonus_nothingEyebrow,
          lead: l10n.bonus_nothingLead,
          emphasis: isFirstMemory
              ? l10n.bonus_nothingEmphasisFirst
              : l10n.bonus_nothingEmphasisNext,
          body: isFirstMemory
              ? l10n.bonus_brandNewBody
              : l10n.bonus_nothingBody,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => context.pushNamed(RouteNames.createMemory),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(15),
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.cardRadius,
            ),
          ),
          child: Text(
            l10n.bonus_createMemory,
            style: AppTypography.buttonLabel.copyWith(
              fontSize: 14,
              color: AppColors.background,
            ),
          ),
        ),
      ],
    );
  }
}
