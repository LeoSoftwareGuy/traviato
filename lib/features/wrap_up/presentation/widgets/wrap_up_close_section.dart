import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/wrap_up_close.dart';
import '../mutations/wrap_up_mutations.dart';

/// The closing line + "Open journal" / "Keep forever" CTAs
/// (docs/design/README.md § 12). "Keep forever" sets `published_at`;
/// reordering/editing the screenplay itself is a separate, undesigned
/// feature (M4-3).
class WrapUpCloseSection extends ConsumerWidget {
  const WrapUpCloseSection({
    required this.close,
    required this.tripId,
    required this.isPublished,
    super.key,
  });

  final WrapUpClose close;
  final String tripId;
  final bool isPublished;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPublishing = ref.watch(publishWrapUpMutation) is MutationPending;

    return Column(
      children: [
        Text(
          close.line,
          textAlign: TextAlign.center,
          style: AppTypography.pullQuote.copyWith(fontSize: 17, height: 1.65),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.pushNamed(
                  RouteNames.tripJournal,
                  pathParameters: {'tripId': tripId},
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.surfaceBorder),
                ),
                child: const Text('Open journal'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: isPublished
                  ? const _KeptForeverBadge()
                  : ElevatedButton(
                      onPressed: isPublishing
                          ? null
                          : () => runPublishWrapUp(ref: ref, tripId: tripId),
                      child: isPublishing
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Keep forever'),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeptForeverBadge extends StatelessWidget {
  const _KeptForeverBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.tint(AppColors.primary, .16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.tint(AppColors.primary, .35)),
      ),
      child: Text(
        '✦ Kept forever',
        style: AppTypography.chipLabel.copyWith(color: AppColors.primary),
      ),
    );
  }
}
