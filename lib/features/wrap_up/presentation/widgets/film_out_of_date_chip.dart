import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_message.dart';
import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../mutations/wrap_up_mutations.dart';

/// "Photos changed · Rebuild film" (#294): shown wherever a kept film is
/// offered once its photos or picks changed. Tapping rebuilds the film with
/// the new picks — never automatically, never an AI call.
class FilmOutOfDateChip extends ConsumerWidget {
  const FilmOutOfDateChip({required this.tripId, super.key});

  final String tripId;

  static const _radius = BorderRadius.all(Radius.circular(999));

  Future<void> _rebuild(BuildContext context, WidgetRef ref) async {
    try {
      await runRebuildKeptFilm(ref: ref, tripId: tripId);
    } catch (error) {
      if (!context.mounted) return;
      showErrorSnackbar(
        context,
        message: presentationFailureMessage(error, context.l10n),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRebuilding = ref.watch(rebuildKeptFilmMutation) is MutationPending;
    return Material(
      color: AppColors.tint(AppColors.filmBackground, .7),
      shape: RoundedRectangleBorder(
        borderRadius: _radius,
        side: BorderSide(color: AppColors.tint(AppColors.primary, .45)),
      ),
      child: InkWell(
        key: const Key('film-out-of-date-chip'),
        borderRadius: _radius,
        onTap: isRebuilding ? null : () => _rebuild(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isRebuilding)
                const SizedBox.square(
                  dimension: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColors.primaryLight,
                  ),
                )
              else
                const Icon(
                  Icons.refresh,
                  size: 14,
                  color: AppColors.primaryLight,
                ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  context.l10n.film_outOfDate,
                  style: AppTypography.caption.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
