import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/route_constants.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../mutations/wrap_up_mutations.dart';
import '../widgets/film_out_of_date_chip.dart';

/// The film itself is an ambient, non-interactive loop (docs/design/
/// WRAP_UP_FILM_FLUTTER_SPEC.md has no CTAs at all) — this is a persistent overlay
/// outside the 1080×1920 canvas carrying the two things the app still needs
/// reachable: leaving the film, and "Keep forever" (`published_at`, M4-3).
/// Same copy/behaviour as the pre-#126 close section, repositioned.
///
/// Once kept, the "Keep forever" slot becomes the way into the Kept Memory
/// page (#279): "Open memory" replaces the film with it, or "Back to memory"
/// when the film was opened from there. A kept film whose photos changed
/// also offers "Photos changed · Rebuild film" (#294) beside close.
class WrapUpFilmHud extends ConsumerWidget {
  const WrapUpFilmHud({
    required this.tripId,
    required this.isPublished,
    this.openedFromMemory = false,
    this.isOutOfDate = false,
    super.key,
  });

  final String tripId;
  final bool isPublished;
  final bool openedFromMemory;
  final bool isOutOfDate;

  /// Back to wherever the film was opened from (#279) — Home when there's
  /// nothing to pop (e.g. a deep link).
  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(RouteNames.home);
    }
  }

  void _toMemory(BuildContext context) {
    if (openedFromMemory) {
      _close(context);
    } else {
      context.pushReplacementNamed(
        RouteNames.keptMemory,
        pathParameters: {'tripId': tripId},
      );
    }
  }

  Future<void> _tapKeepForever(BuildContext context, WidgetRef ref) async {
    try {
      await runPublishWrapUp(ref: ref, tripId: tripId);
    } catch (_) {
      // Surfaced to the user via the mutation's MutationError state below.
      return;
    }
    if (!context.mounted) return;
    context.goNamed(RouteNames.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<MutationState<void>>(publishWrapUpMutation, (previous, next) {
      if (next is MutationError) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(next.error, context.l10n),
        );
      }
    });
    final isPublishing = ref.watch(publishWrapUpMutation) is MutationPending;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                _HudScrim(
                  child: IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textOnPhoto),
                    onPressed: () => _close(context),
                  ),
                ),
                const Spacer(),
                if (isPublished && isOutOfDate)
                  Flexible(
                    flex: 6,
                    child: FilmOutOfDateChip(tripId: tripId),
                  ),
              ],
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
                    child: Text(context.l10n.wrapUp_openJournal),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: isPublished
                      ? ElevatedButton(
                          key: const Key('wrap-up-hud-memory'),
                          onPressed: () => _toMemory(context),
                          child: Text(
                            openedFromMemory
                                ? context.l10n.wrapUp_backToMemory
                                : context.l10n.wrapUp_openMemory,
                          ),
                        )
                      : ElevatedButton(
                          onPressed: isPublishing
                              ? null
                              : () => _tapKeepForever(context, ref),
                          child: isPublishing
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(context.l10n.wrapUp_keepForever),
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
