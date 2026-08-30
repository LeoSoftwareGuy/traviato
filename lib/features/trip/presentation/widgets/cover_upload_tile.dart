import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bottom_sheet_chrome.dart';
import '../../../photo/data/services/photo_compressor.dart';

/// The cover strip's "Upload photo" entry (issue #81) — same 60×46 slot as
/// a bundled [_Thumbnail], reusing the M3-6 pick + compress pipeline
/// (camera or gallery). [onPicked] receives the compressed JPEG bytes and
/// is awaited for the tile's own loading state, so it covers the caller's
/// upload too (not just the local pick/compress step).
class CoverUploadTile extends StatefulWidget {
  const CoverUploadTile({required this.onPicked, super.key});

  final Future<void> Function(Uint8List bytes) onPicked;

  @override
  State<CoverUploadTile> createState() => _CoverUploadTileState();
}

class _CoverUploadTileState extends State<CoverUploadTile> {
  var _isBusy = false;

  Future<void> _pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(source: source);
    if (file == null || !mounted) return;

    setState(() => _isBusy = true);
    try {
      final rawBytes = await file.readAsBytes();
      final compressed = await const PhotoCompressor().compress(rawBytes);
      await widget.onPicked(compressed);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _openSourcePicker() async {
    final source = await showAppBottomSheet<ImageSource>(
      context: context,
      builder: (context) => _CoverSourcePicker(),
    );
    if (source == null || !mounted) return;
    await _pick(source);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('cover-upload-tile'),
      onTap: _isBusy ? null : _openSourcePicker,
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
        child: _isBusy
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
            'Upload a cover photo',
            style: AppTypography.screenTitle.copyWith(fontSize: 21),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SourceTile(
            icon: Icons.photo_camera_outlined,
            label: 'Take a photo',
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SourceTile(
            icon: Icons.photo_library_outlined,
            label: 'Choose from gallery',
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
