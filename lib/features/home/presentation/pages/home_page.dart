import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/route_constants.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/async_error_retry_scaffold.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../bonus/presentation/providers/bonus_badge_provider.dart';
import '../../../expense/presentation/providers/expense_providers.dart';
import '../../../expense/presentation/widgets/add_expense_sheet.dart';
import '../../../trip/domain/entities/trip_card_entity.dart';
import '../controllers/home_controller.dart';
import '../controllers/home_state.dart';
import '../providers/profile_stats_provider.dart';
import '../widgets/coming_up_section.dart';
import '../widgets/home_header.dart';
import '../widgets/home_stats_bar.dart';
import '../widgets/memories_grid_section.dart';
import '../widgets/upcoming_hero_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final username = ref.watch(authControllerProvider).user?.username;
    final stats = ref.watch(profileStatsProvider);
    final homeAsync = ref.watch(homeControllerProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.screenGroundRadial(
            AppGradients.groundTopHome,
          ),
        ),
        child: SafeArea(
          child: homeAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => AsyncErrorRetryScaffold(
              message: presentationFailureMessage(error),
              onRetry: () => ref.invalidate(homeControllerProvider),
            ),
            data: (state) => _HomeContent(
              username: username ?? 'traveler',
              stars: stats.stars,
              memories: stats.memories,
              places: stats.places,
              days: stats.days,
              state: state,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({
    required this.username,
    required this.stars,
    required this.memories,
    required this.places,
    required this.days,
    required this.state,
  });

  final String username;
  final int stars;
  final int memories;
  final int places;
  final int days;
  final HomeState state;

  void _openPlan(BuildContext context, TripCardEntity trip) =>
      context.pushNamed(
        RouteNames.tripPlan,
        pathParameters: {'tripId': trip.id},
      );

  void _openWrapUp(BuildContext context, TripCardEntity trip) =>
      context.pushNamed(
        RouteNames.tripWrapUp,
        pathParameters: {'tripId': trip.id},
      );

  Future<void> _addExpense(
    BuildContext context,
    WidgetRef ref,
    TripCardEntity trip,
  ) async {
    final result = await ref.read(expenseRepositoryProvider).getSummaries();
    if (!context.mounted) return;
    result.fold(
      (failure) => showErrorSnackbar(
        context,
        message: presentationFailureMessage(failure),
      ),
      (summaries) => AddExpenseSheet.show(
        context,
        trips: summaries,
        initialTripId: trip.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hero = state.heroTrip;
    final hasOpenBonusTasks = hero == null
        ? false
        : ref
              .watch(bonusOpenCountForTripProvider(hero.id))
              .maybeWhen(data: (count) => count > 0, orElse: () => false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xxl * 2,
      ),
      children: [
        HomeHeader(
          username: username,
          stars: stars,
          onAvatarTap: () => context.pushNamed(RouteNames.profile),
          hasOpenBonusTasks: hasOpenBonusTasks,
          onStarsTap: () => hero != null
              ? context.pushNamed(
                  RouteNames.tripBonusTasks,
                  pathParameters: {'tripId': hero.id},
                )
              : context.pushNamed(RouteNames.bonusTasks),
        ),
        const SizedBox(height: AppSpacing.xl),
        HomeStatsBar(
          stats: ProfileStats(
            memories: memories,
            places: places,
            days: days,
            stars: stars,
          ),
        ),
        if (state.isEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          _NoMemoriesYet(
            onCreateTap: () => context.pushNamed(RouteNames.createMemory),
          ),
        ] else ...[
          if (hero != null) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(
              'HAPPENING NOW',
              style: AppTypography.mono.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            UpcomingHeroCard(
              trip: hero,
              onPlanTap: () => _openPlan(context, hero),
              onChecklistTap: () => context.pushNamed(
                RouteNames.tripChecklist,
                pathParameters: {'tripId': hero.id},
              ),
              onJournalTap: () => context.pushNamed(
                RouteNames.tripJournal,
                pathParameters: {'tripId': hero.id},
              ),
              onAddExpenseTap: () => _addExpense(context, ref, hero),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          ComingUpSection(
            trips: state.upcomingTrips,
            onTripTap: (trip) => _openPlan(context, trip),
            onCreateMemoryTap: () => context.pushNamed(RouteNames.createMemory),
          ),
          const SizedBox(height: AppSpacing.xl),
          MemoriesGridSection(
            trips: state.finishedTrips,
            onTripTap: (trip) => _openWrapUp(context, trip),
          ),
        ],
      ],
    );
  }
}

class _NoMemoriesYet extends StatelessWidget {
  const _NoMemoriesYet({required this.onCreateTap});

  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '✦',
          style: AppTypography.bigNumber.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.base),
        Text(
          'No memories yet',
          style: AppTypography.screenTitle.copyWith(fontSize: 20),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Start your first memory and watch it become a journal you keep '
          'forever.',
          textAlign: TextAlign.center,
          style: AppTypography.chipLabel.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.lg),
        ElevatedButton(
          onPressed: onCreateTap,
          child: const Text('Create your first memory'),
        ),
      ],
    );
  }
}
