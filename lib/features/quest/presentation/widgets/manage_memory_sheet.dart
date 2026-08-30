import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/failure_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bottom_sheet_chrome.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../../../journal/presentation/providers/day_note_providers.dart';
import '../../../photo/presentation/providers/photo_providers.dart';
import '../../../trip/domain/entities/trip_card_entity.dart';
import '../../../trip/presentation/mutations/trip_mutations.dart';
import '../../../trip/presentation/widgets/cover_options.dart';
import '../../../trip/presentation/widgets/cover_picker.dart';
import '../../../trip/presentation/widgets/create_memory_field.dart';
import '../controllers/plan_controller.dart';
import '../mutations/manage_memory_mutations.dart';

final _dateFormat = DateFormat('d MMM y');

/// Rename, date-shift, cover-change, and two-step delete for a memory.
/// `docs/design/README.md` § Shared: Manage memory sheet.
///
/// Resolves to `true` if the memory was deleted, so the caller can navigate
/// away — the sheet's own [BuildContext] isn't valid anymore once it pops.
class ManageMemorySheet extends ConsumerStatefulWidget {
  const ManageMemorySheet({required this.tripId, super.key});

  final String tripId;

  static Future<bool?> show(BuildContext context, {required String tripId}) {
    return showAppBottomSheet<bool>(
      context: context,
      builder: (context) => ManageMemorySheet(tripId: tripId),
    );
  }

  @override
  ConsumerState<ManageMemorySheet> createState() => _ManageMemorySheetState();
}

class _ManageMemorySheetState extends ConsumerState<ManageMemorySheet> {
  late final TextEditingController _name;
  var _deleteArmed = false;
  int? _photoCount;
  int? _noteDaysCount;

  TripCardEntity? get _trip =>
      ref.read(planControllerProvider(widget.tripId)).value?.trip;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: _trip?.name ?? '');
    _loadDeleteCounts();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
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

  Future<void> _rename() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    try {
      await runRenameMemory(ref: ref, tripId: widget.tripId, name: name);
    } catch (_) {
      // Surfaced via the mutation error listener below.
    }
  }

  Future<void> _shiftDates(int deltaDays) async {
    try {
      await runShiftMemoryDates(
        ref: ref,
        tripId: widget.tripId,
        deltaDays: deltaDays,
      );
    } catch (_) {
      // Surfaced via the mutation error listener below.
    }
  }

  Future<void> _changeCover(String coverId) async {
    try {
      await runChangeCover(
        ref: ref,
        tripId: widget.tripId,
        coverImagePath: assetCoverImagePath(coverId),
      );
    } catch (_) {
      // Surfaced via the mutation error listener below.
    }
  }

  Future<void> _uploadCover(Uint8List bytes) async {
    try {
      await runUploadCover(ref: ref, tripId: widget.tripId, bytes: bytes);
    } catch (_) {
      // Surfaced via the mutation error listener below.
    }
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
    for (final mutation in [
      renameMemoryMutation,
      changeCoverMutation,
      shiftMemoryDatesMutation,
      deleteMemoryMutation,
    ]) {
      ref.listen<MutationState<dynamic>>(mutation, (previous, next) {
        if (next is MutationError) {
          showErrorSnackbar(
            context,
            message: presentationFailureMessage(next.error),
          );
        }
      });
    }

    final trip = ref.watch(planControllerProvider(widget.tripId)).value?.trip;
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
                  'Edit this memory',
                  style: AppTypography.screenTitle.copyWith(fontSize: 21),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          CreateMemoryField(
            label: 'Name',
            controller: _name,
            trailing: TextButton(
              onPressed: _rename,
              child: const Text('Rename'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _ShiftDateCard(
                  label: 'Starts',
                  date: trip?.startDate,
                  onShiftForward: () => _shiftDates(1),
                  onShiftBack: () => _shiftDates(-1),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ShiftDateCard(
                  label: 'Ends',
                  date: trip?.endDate,
                  onShiftForward: () => _shiftDates(1),
                  onShiftBack: () => _shiftDates(-1),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tap a date to shift it a day forward, hold to shift it back — '
            "quests move with it.",
            style: AppTypography.chipLabel.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'COVER',
            style: AppTypography.mono.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          CoverThumbnailStrip(
            selectedCoverId: coverIdFromPath(trip?.coverImagePath),
            onSelect: _changeCover,
            onUploadCustom: _uploadCover,
          ),
          const SizedBox(height: AppSpacing.xl),
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

class _ShiftDateCard extends StatelessWidget {
  const _ShiftDateCard({
    required this.label,
    required this.date,
    required this.onShiftForward,
    required this.onShiftBack,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onShiftForward;
  final VoidCallback onShiftBack;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: date == null ? null : onShiftForward,
      onLongPress: date == null ? null : onShiftBack,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.surfaceBorder),
          borderRadius: AppRadius.cardRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: AppTypography.mono.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              date == null ? 'Not set' : _dateFormat.format(date!),
              style: AppTypography.bodyInput.copyWith(
                color: date == null
                    ? AppColors.textTertiary
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
