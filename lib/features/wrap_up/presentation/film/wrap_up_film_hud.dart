import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../mutations/wrap_up_mutations.dart';

/// The film itself is an ambient, non-interactive loop (docs/design/
/// wrap-film-spec.md has no CTAs at all) — this is a persistent overlay
/// outside the 1080×1920 canvas carrying the two things the app still needs
/// reachable: leaving the film, and "Keep forever" (`published_at`, M4-3).
/// Same copy/behaviour as the pre-#126 close section, repositioned.
class WrapUpFilmHud extends ConsumerWidget {
  const WrapUpFilmHud({
    required this.tripId,
    required this.isPublished,
    super.key,
  });

  final String tripId;
  final bool isPublished;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPublishing = ref.watch(publishWrapUpMutation) is MutationPending;

    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _HudScrim(
                child: IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textOnPhoto),
                  onPressed: () => context.goNamed(RouteNames.home),
                ),
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pushNamed(
                      RouteNames.tripJournal,
                      pathParameters: {'tripId': tripId},
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: AppColors.textOnPhoto,
                      side: const BorderSide(color: AppColors.textOnPhotoMuted),
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
                              : () =>
                                    runPublishWrapUp(ref: ref, tripId: tripId),
                          child: isPublishing
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Keep forever'),
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

/// A soft dark backdrop so HUD controls stay legible over any part of the
/// film, without a hard bar cutting across the frame.
class _HudScrim extends StatelessWidget {
  const _HudScrim({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.scrim,
        shape: BoxShape.circle,
      ),
      child: child,
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
