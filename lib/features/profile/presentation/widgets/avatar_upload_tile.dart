import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bottom_sheet_chrome.dart';
import '../../../photo/data/services/photo_compressor.dart';
import 'profile_avatar.dart';

/// The edit sheet's avatar tile — tap to pick (camera/gallery), pick +
/// compress (M3-6's pipeline), then [onPicked] uploads. Circular version of
/// `CoverUploadTile`'s pattern.
class AvatarUploadTile extends StatefulWidget {
  const AvatarUploadTile({
    required this.avatarUrl,
    required this.username,
    required this.onPicked,
    super.key,
  });

  final String? avatarUrl;
  final String? username;
  final Future<void> Function(Uint8List bytes) onPicked;

  @override
  State<AvatarUploadTile> createState() => _AvatarUploadTileState();
}

class _AvatarUploadTileState extends State<AvatarUploadTile> {
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
      builder: (context) => const _AvatarSourcePicker(),
    );
    if (source == null || !mounted) return;
    await _pick(source);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('avatar-upload-tile'),
      onTap: _isBusy ? null : _openSourcePicker,
      customBorder: const CircleBorder(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ProfileAvatar(
            avatarUrl: widget.avatarUrl,
            username: widget.username,
            size: 72,
          ),
          if (_isBusy)
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.scrim,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 14,
                  color: AppColors.background,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarSourcePicker extends StatelessWidget {
  const _AvatarSourcePicker();

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
            'Update your photo',
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
      key: Key('avatar-source-${label.toLowerCase().replaceAll(' ', '-')}'),
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
