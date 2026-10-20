import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/route_constants.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/widgets/async_error_retry_scaffold.dart';
import '../providers/bonus_empty_state_providers.dart';
import '../widgets/bonus_page_top_bar.dart';
import '../widgets/star_memory_row.dart';

/// "All memories ›" from the Bonus page's star summary (#219): every
/// memory's stars, most first, in the same row style.
class StarsByMemoryPage extends ConsumerWidget {
  const StarsByMemoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(starSummaryProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.screenGroundRadial(
            AppGradients.groundTopBonusProfile,
          ),
        ),
        child: SafeArea(
          child: summaryAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => AsyncErrorRetryScaffold(
              message: presentationFailureMessage(error, context.l10n),
              onRetry: () => ref.invalidate(bonusTripCardsProvider),
            ),
            data: (summary) => ListView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 34),
              children: [
                BonusPageTopBar(
                  eyebrow: context.l10n.stars_allMemoriesTitle,
                  stars: summary.totalStars,
                  onBack: () => context.pop(),
                ),
                const SizedBox(height: 20),
                for (final m in summary.byMemory) ...[
                  StarMemoryRow(
                    total: m,
                    onTap: m.trip == null
                        ? null
                        : () => context.pushNamed(
                            RouteNames.tripJournal,
                            pathParameters: {'tripId': m.trip!.id},
                          ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
