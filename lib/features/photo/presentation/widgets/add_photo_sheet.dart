import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bottom_sheet_chrome.dart';
import '../../../../core/widgets/show_failure_snackbar.dart';
import '../../../../core/widgets/star_award_toast.dart';
import '../../../trip/presentation/widgets/create_memory_field.dart';
import '../../domain/entities/photo_entity.dart';
import '../mutations/photo_mutations.dart';
import 'batch_add_photo_sheet.dart';
import 'location_permission_prompt.dart';

/// Entry point for issue #30 — the Journal "Add ✦2" tile and any future
/// day-tab-context add affordance both call this. [dayDate] is whichever
/// day the caller currently has selected in Journal. [onSaved], when given,
/// runs instead of the default "+2 stars · photo logged" toast — used by
/// the bonus-task popup sheet (#64) to complete its own assignment with the
/// new photo before showing its own toast.
class AddPhotoSheet {
  const AddPhotoSheet._();

  static Future<void> show(
    BuildContext context, {
    required String tripId,
    required DateTime dayDate,
    Future<void> Function(PhotoEntity photo)? onSaved,
  }) {
    return showAppBottomSheet<void>(
      context: context,
      builder: (context) => _SourcePicker(
        tripId: tripId,
        dayDate: dayDate,
        onSaved: onSaved,
      ),
    );
  }
}

class _SourcePicker extends StatelessWidget {
  const _SourcePicker({
    required this.tripId,
    required this.dayDate,
    this.onSaved,
  });

  final String tripId;
  final DateTime dayDate;
  final Future<void> Function(PhotoEntity photo)? onSaved;

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final file = await ImagePicker().pickImage(source: source);
    if (file == null || !context.mounted) return;
    final bytes = await file.readAsBytes();
    if (!context.mounted) return;
    Navigator.of(context).pop();
    await AddPhotoDetailsSheet.show(
      context,
      tripId: tripId,
      dayDate: dayDate,
      bytes: bytes,
      onSaved: onSaved,
    );
  }

  /// Gallery-only multi-select (#116) — camera naturally stays single-shot.
  /// A caller that supplies [onSaved] (the bonus-task completion flow, #64)
  /// needs exactly one resulting photo, so it keeps the single-pick path
  /// unchanged rather than gaining a batch it has no way to consume.
  Future<void> _pickGallery(BuildContext context) async {
    if (onSaved != null) return _pick(context, ImageSource.gallery);

    final files = await ImagePicker().pickMultiImage();
    if (files.isEmpty || !context.mounted) return;

    if (files.length == 1) {
      final bytes = await files.single.readAsBytes();
      if (!context.mounted) return;
      Navigator.of(context).pop();
      await AddPhotoDetailsSheet.show(
        context,
        tripId: tripId,
        dayDate: dayDate,
        bytes: bytes,
      );
      return;
    }

    final images = await Future.wait(files.map((f) => f.readAsBytes()));
    if (!context.mounted) return;
    Navigator.of(context).pop();
    await BatchAddPhotoSheet.show(
      context,
      tripId: tripId,
      dayDate: dayDate,
      images: images,
    );
  }

  @override
  Widget build(BuildContext context) {
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
          Text(
            'Add a photo',
            style: AppTypography.screenTitle.copyWith(fontSize: 21),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SourceTile(
            icon: Icons.photo_camera_outlined,
            label: 'Take a photo',
            onTap: () => _pick(context, ImageSource.camera),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SourceTile(
            icon: Icons.photo_library_outlined,
            label: 'Choose from gallery',
            onTap: () => _pickGallery(context),
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('add-photo-source-${label.toLowerCase().replaceAll(' ', '-')}'),
      onTap: onTap,
      borderRadius: AppRadius.cardRadius,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.surfaceBorder),
          borderRadius: AppRadius.cardRadius,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: AppTypography.bodyInput.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Caption/place-text step, shown after a source is picked. Public (rather
/// than the `_SourcePicker` convention) so it's directly widget-testable
/// without going through the real `image_picker` platform channel.
class AddPhotoDetailsSheet extends ConsumerStatefulWidget {
  const AddPhotoDetailsSheet({
    required this.tripId,
    required this.dayDate,
    required this.bytes,
    this.onSaved,
    super.key,
  });

  final String tripId;
  final DateTime dayDate;
  final Uint8List bytes;
  final Future<void> Function(PhotoEntity photo)? onSaved;

  static Future<void> show(
    BuildContext context, {
    required String tripId,
    required DateTime dayDate,
    required Uint8List bytes,
    Future<void> Function(PhotoEntity photo)? onSaved,
  }) {
    return showAppBottomSheet<void>(
      context: context,
      builder: (context) => AddPhotoDetailsSheet(
        tripId: tripId,
        dayDate: dayDate,
        bytes: bytes,
        onSaved: onSaved,
      ),
    );
  }

  @override
  ConsumerState<AddPhotoDetailsSheet> createState() =>
      _AddPhotoDetailsSheetState();
}

class _AddPhotoDetailsSheetState extends ConsumerState<AddPhotoDetailsSheet> {
  final _caption = TextEditingController();
  final _place = TextEditingController();

  @override
  void dispose() {
    _caption.dispose();
    _place.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final locationGranted = await resolveLocationPermission(context);
    if (!mounted) return;

    final PhotoEntity photo;
    try {
      photo = await runAddPhoto(
        ref: ref,
        tripId: widget.tripId,
        dayDate: widget.dayDate,
        rawBytes: widget.bytes,
        locationPermissionGranted: locationGranted,
        caption: _caption.text.trim().isEmpty ? null : _caption.text.trim(),
        placeText: _place.text.trim().isEmpty ? null : _place.text.trim(),
      );
    } catch (_) {
      return;
    }
    if (!mounted) return;

    final onSaved = widget.onSaved;
    if (onSaved != null) {
      await onSaved(photo);
    } else {
      showStarToast(context, '✦ +2 stars · photo logged');
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MutationState<dynamic>>(addPhotoMutation, (previous, next) {
      if (next is MutationError) {
        showFailureSnackbar(context, next.error);
      }
    });
    final isSaving = ref.watch(addPhotoMutation) is MutationPending;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Padding(
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
            Text(
              'Add photo',
              style: AppTypography.screenTitle.copyWith(fontSize: 21),
            ),
            const SizedBox(height: AppSpacing.lg),
            ClipRRect(
              borderRadius: AppRadius.cardRadius,
              child: Image.memory(
                widget.bytes,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            CreateMemoryField(
              label: 'Caption (optional)',
              controller: _caption,
              hintText: 'e.g. Sunset at the harbor',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.lg),
            CreateMemoryField(
              label: 'Place (optional)',
              controller: _place,
              hintText: 'e.g. Old Town',
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
