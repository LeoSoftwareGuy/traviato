import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/l10n/context_l10n.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_bottom_nav_bar.dart';

/// The Journal day's floating Photo · Note bar — the Journal's only bottom
/// control (#410). Since #424 it wears the Home nav's surface, icon size and
/// label style ([AppBottomBarSurface], [AppBottomBarTab]) with two equal
/// halves; the balloon moved to the Home nav's "+" (it was #414's orange
/// bar with a balloon cut out of its centre).
class JournalCaptureBar extends StatelessWidget {
  const JournalCaptureBar({
    required this.onPhotoTap,
    required this.onNoteTap,
    super.key,
  });

  final VoidCallback onPhotoTap;
  final VoidCallback onNoteTap;

  /// Roughly the bar's height, for the list's bottom padding.
  static const double height = 76;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppBottomBarSurface(
      key: const Key('capture-capsule'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Material(
        type: MaterialType.transparency,
        child: Row(
          children: [
            Expanded(
              child: AppBottomBarTab(
                key: const Key('capture-photo'),
                icon: Icons.photo_camera_outlined,
                label: l10n.timeline_capturePhoto,
                semanticLabel: l10n.timeline_addPhotoSemantics,
                color: AppColors.primary,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onPhotoTap();
                },
              ),
            ),
            const SizedBox(
              width: 1,
              height: 32,
              child: ColoredBox(color: AppColors.surfaceBorder),
            ),
            Expanded(
              child: AppBottomBarTab(
                key: const Key('capture-note'),
                icon: Icons.edit_note_rounded,
                label: l10n.timeline_captureNote,
                semanticLabel: l10n.timeline_addNoteSemantics,
                color: AppColors.primary,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onNoteTap();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
