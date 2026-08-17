import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/guest_hero_card.dart';
import '../widgets/how_it_works_section.dart';
import '../widgets/moments_grid.dart';
import '../widgets/testimonial_card.dart';

/// The unauthenticated entry point (Figma "Guest mode screen"): static
/// marketing content ending in "Start now" (→ Register) with a "Log in"
/// shortcut in the header.
class GuestLandingPage extends StatelessWidget {
  const GuestLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    void goToRegister() => context.goNamed(RouteNames.signup);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                96,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GuestLandingHeader(
                    onLogin: () => context.goNamed(RouteNames.login),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  GuestHeroCard(onStartNow: goToRegister),
                  const SizedBox(height: AppSpacing.xxl),
                  const HowItWorksSection(),
                  const SizedBox(height: AppSpacing.xxl),
                  const MomentsGrid(),
                  const SizedBox(height: AppSpacing.xxl),
                  const TestimonialCard(),
                ],
              ),
            ),
            _StickyStartNowBar(onStartNow: goToRegister),
          ],
        ),
      ),
    );
  }
}

class _GuestLandingHeader extends StatelessWidget {
  const _GuestLandingHeader({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: AppRadius.badgeRadius,
              ),
              child: const Icon(
                Icons.explore_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Trevy',
              style: AppTypography.headlineSerif.copyWith(fontSize: 18),
            ),
          ],
        ),
        OutlinedButton(onPressed: onLogin, child: const Text('Log in')),
      ],
    );
  }
}

class _StickyStartNowBar extends StatelessWidget {
  const _StickyStartNowBar({required this.onStartNow});

  final VoidCallback onStartNow;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.base,
          AppSpacing.lg,
          AppSpacing.base,
        ),
        decoration: const BoxDecoration(color: AppColors.background),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onStartNow,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Start capturing your memories'),
          ),
        ),
      ),
    );
  }
}
