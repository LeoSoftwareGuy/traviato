import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'balloon_create_button.dart';
import 'shrink_to_floor_text.dart';

/// One tab in [AppBottomNavBar] (Home, Expenses, ...). The center action is
/// always the balloon "+" — see [AppBottomNavBar.onFabTap].
class AppBottomNavBarItem {
  const AppBottomNavBarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
}

/// Shared bottom nav chrome: an [AppBottomBarSurface] with a fade above it,
/// and the center [BalloonCreateButton] rising [_fabPullUp] above the bar
/// (#424; it was a square gradient FAB). `docs/design/README.md` § Shared:
/// Bottom nav.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    required this.items,
    required this.onFabTap,
    required this.fabSemanticLabel,
    super.key,
  });

  final List<AppBottomNavBarItem> items;
  final VoidCallback onFabTap;

  /// Screen-reader label of the balloon ("Create a memory").
  final String fabSemanticLabel;

  static const _fabPullUp = 22.0;

  /// Icon size of a tab (#424: was 15).
  static const double iconSize = 28;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                AppColors.background.withValues(alpha: .55),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(
            AppSpacing.base,
            0,
            AppSpacing.base,
            AppSpacing.sm,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              AppBottomBarSurface(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final item in items)
                      AppBottomBarTab(
                        icon: item.icon,
                        label: item.label,
                        color: item.selected
                            ? AppColors.primary
                            : AppColors.textTertiary,
                        onTap: item.onTap,
                      ),
                  ],
                ),
              ),
              Positioned(
                top: -_fabPullUp,
                child: BalloonCreateButton(
                  onTap: onFabTap,
                  semanticLabel: fabSemanticLabel,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One icon-over-label button of a bottom bar — a Home nav tab, or the
/// Journal's Photo / Note (#424). At least 66 × 48.
class AppBottomBarTab extends StatelessWidget {
  const AppBottomBarTab({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.semanticLabel,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  /// Read instead of [label] when given.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: AppBottomNavBar.iconSize),
        const SizedBox(height: AppSpacing.xs),
        // Spec 4t "Bottom nav": always one line, scaling down a step
        // for a long label (translator limit: 9 chars).
        ShrinkToFloorText(
          label,
          minFontSize: 8.5,
          style: AppBottomBarSurface.labelStyle(color),
        ),
      ],
    );
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.badgeRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 66, minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// The bottom bars' shared surface (#424): the Home nav and the Journal's
/// Photo · Note bar look the same — blurred surface, radius 22, hairline
/// border.
class AppBottomBarSurface extends StatelessWidget {
  const AppBottomBarSurface({required this.child, this.padding, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// A tab's / action's label under its icon.
  static TextStyle labelStyle(Color color) => AppTypography.buttonLabel
      .copyWith(fontSize: 9.5, height: 1, color: color);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.mediaRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.tint(AppColors.surface, .92),
            border: Border.all(color: AppColors.surfaceBorder),
            borderRadius: AppRadius.mediaRadius,
          ),
          child: child,
        ),
      ),
    );
  }
}
