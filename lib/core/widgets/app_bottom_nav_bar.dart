import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// One tab in [AppBottomNavBar] (Home, Expenses, ...). The center action is
/// always the FAB — see [AppBottomNavBar.onFabTap].
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

/// Shared bottom nav chrome: blurred surface bar, radius 22, a fade above it,
/// and a center primary→coral gradient FAB pulled up 16px above the bar.
/// `docs/design/README.md` § Shared: Bottom nav.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    required this.items,
    required this.onFabTap,
    super.key,
  });

  final List<AppBottomNavBarItem> items;
  final VoidCallback onFabTap;

  static const _fabPullUp = 16.0;
  static const _fabSize = 52.0;

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
              ClipRRect(
                borderRadius: AppRadius.mediaRadius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tint(AppColors.surface, .92),
                      border: Border.all(color: AppColors.surfaceBorder),
                      borderRadius: AppRadius.mediaRadius,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (final item in items) _NavTab(item: item),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -_fabPullUp,
                child: _NavFab(size: _fabSize, onTap: onFabTap),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({required this.item});

  final AppBottomNavBarItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.selected ? AppColors.primary : AppColors.textTertiary;
    return InkWell(
      onTap: item.onTap,
      borderRadius: AppRadius.badgeRadius,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 66),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, color: color, size: 15),
              const SizedBox(height: AppSpacing.xs),
              Text(
                item.label,
                style: AppTypography.buttonLabel.copyWith(
                  fontSize: 9.5,
                  height: 1,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavFab extends StatelessWidget {
  const _NavFab({required this.size, required this.onTap});

  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: AppGradients.primaryCta,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.tint(AppColors.primary, .34),
              blurRadius: 26,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: AppColors.background, size: 22),
      ),
    );
  }
}
