import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bottom_sheet_chrome.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../../../journal/presentation/providers/day_note_providers.dart';
import '../../../photo/presentation/providers/photo_providers.dart';
import '../mutations/trip_mutations.dart';

/// Delete-only sheet for a finished ("kept forever") memory — issue #115.
///
/// Long-press on a Kept-forever Home card opens this instead of the full
/// manage-memory sheet: a finished trip's name/dates/cover aren't editable
/// from Home, only removable. Mirrors the delete section of
/// `ManageMemorySheet` (copy, two-step arming) without depending on
/// `PlanController`, which a finished trip has no reason to load.
///
/// Resolves to `true` if the memory was deleted, so the caller can treat
/// its list as stale.
class DeleteMemorySheet extends ConsumerStatefulWidget {
  const DeleteMemorySheet({
    required this.tripId,
    required this.tripName,
    super.key,
  });

  final String tripId;
  final String tripName;

  static Future<bool?> show(
    BuildContext context, {
    required String tripId,
    required String tripName,
  }) {
    return showAppBottomSheet<bool>(
      context: context,
      builder: (context) =>
          DeleteMemorySheet(tripId: tripId, tripName: tripName),
    );
  }

  @override
  ConsumerState<DeleteMemorySheet> createState() => _DeleteMemorySheetState();
}

class _DeleteMemorySheetState extends ConsumerState<DeleteMemorySheet> {
  var _deleteArmed = false;
  int? _photoCount;
  int? _noteDaysCount;

  @override
  void initState() {
    super.initState();
    _loadDeleteCounts();
  }

  Future<void> _loadDeleteCounts() async {
    final photosResult = await ref
        .read(photoRepositoryProvider)
        .getPhotosForTrip(widget.tripId);
    final notesResult = await ref
        .read(dayNoteRepositoryProvider)
        .getNotesForTrip(widget.tripId);
    if (!mounted) return;
    setState(() {
      _photoCount = photosResult.fold((_) => 0, (photos) => photos.length);
      _noteDaysCount = notesResult.fold((_) => 0, (notes) => notes.length);
    });
  }

  Future<void> _tapDelete() async {
    if (!_deleteArmed) {
      setState(() => _deleteArmed = true);
      return;
    }
    try {
      await runDeleteMemory(ref: ref, tripId: widget.tripId);
    } catch (_) {
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MutationState<void>>(deleteMemoryMutation, (previous, next) {
      if (next is MutationError) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(next.error),
        );
      }
    });

    final isDeleting = ref.watch(deleteMemoryMutation) is MutationPending;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Delete this memory',
                  style: AppTypography.screenTitle.copyWith(fontSize: 21),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.tripName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.chipLabel.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isDeleting ? null : _tapDelete,
              style: ElevatedButton.styleFrom(
                backgroundColor: _deleteArmed
                    ? AppColors.accentCoral
                    : AppColors.tint(AppColors.accentCoral, .1),
                foregroundColor: _deleteArmed
                    ? AppColors.background
                    : AppColors.accentCoral,
                side: _deleteArmed
                    ? null
                    : BorderSide(
                        color: AppColors.tint(AppColors.accentCoral, .35),
                      ),
                minimumSize: const Size.fromHeight(48),
              ),
              child: isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _deleteArmed
                          ? 'Yes — delete it forever'
                          : 'Delete this memory',
                    ),
            ),
          ),
          if (_deleteArmed) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'This removes ${_photoCount ?? 0} photos and '
              '${_noteDaysCount ?? 0} days of notes. Your earned stars are '
              "kept. It can't be undone.",
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(letterSpacing: 0),
            ),
          ],
        ],
      ),
    );
  }
}
