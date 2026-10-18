import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bottom_sheet_chrome.dart';
import '../../../photo/data/services/photo_compressor.dart';

/// Camera/gallery cover upload (issue #81), shared by [CoverUploadTile]
/// and the Create memory cover slot (#194): opens the source sheet, then
/// runs the M3-6 pick + compress pipeline. [isPickingCover] stays true
/// until the caller's `onPicked` finishes, so it covers their upload too.
mixin CoverPhotoPicker<T extends StatefulWidget> on State<T> {
  var isPickingCover = false;

  Future<void> pickCover(
    Future<void> Function(Uint8List bytes) onPicked,
  ) async {
    final source = await showAppBottomSheet<ImageSource>(
      context: context,
      builder: (context) => _CoverSourcePicker(),
    );
    if (source == null || !mounted) return;

    final file = await ImagePicker().pickImage(source: source);
    if (file == null || !mounted) return;

    setState(() => isPickingCover = true);
    try {
      final rawBytes = await file.readAsBytes();
      final compressed = await const PhotoCompressor().compress(rawBytes);
      await onPicked(compressed);
    } finally {
      if (mounted) setState(() => isPickingCover = false);
    }
  }
}

/// The manage sheet's "Upload photo" strip entry (issue #81) — same 60×46
/// slot as a bundled thumbnail. [onPicked] receives the compressed JPEG
/// bytes and is awaited for the tile's own loading state.
class CoverUploadTile extends StatefulWidget {
  const CoverUploadTile({required this.onPicked, super.key});

  final Future<void> Function(Uint8List bytes) onPicked;

  @override
  State<CoverUploadTile> createState() => _CoverUploadTileState();
}

class _CoverUploadTileState extends State<CoverUploadTile>
    with CoverPhotoPicker {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('cover-upload-tile'),
      onTap: isPickingCover ? null : () => pickCover(widget.onPicked),
      borderRadius: AppRadius.badgeRadius,
      child: Container(
        width: 60,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.tint(AppColors.primary, .1),
          borderRadius: AppRadius.badgeRadius,
          border: Border.all(color: AppColors.tint(AppColors.primary, .35)),
        ),
        child: isPickingCover
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(
                Icons.add_photo_alternate_outlined,
                color: AppColors.primary,
                size: 20,
              ),
      ),
    );
  }
}

class _CoverSourcePicker extends StatelessWidget {
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
            context.l10n.trip_coverUploadTitle,
            style: AppTypography.screenTitle.copyWith(fontSize: 21),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SourceTile(
            icon: Icons.photo_camera_outlined,
            label: context.l10n.trip_takePhoto,
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SourceTile(
            icon: Icons.photo_library_outlined,
            label: context.l10n.trip_chooseFromGallery,
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
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
      key: Key('cover-source-${label.toLowerCase().replaceAll(' ', '-')}'),
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
