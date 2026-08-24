import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/guest_hero.dart';
import '../widgets/how_it_works_section.dart';
import '../widgets/sample_memories_scroller.dart';
import '../widgets/star_specks.dart';
import '../widgets/testimonial_card.dart';

class GuestLandingPage extends StatelessWidget {
  const GuestLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    void goToRegister() => context.goNamed(RouteNames.signup);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.screenGroundRadial(
            AppGradients.groundTopLandingAuth,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  110,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _GuestLandingNavBar(
                              onLogin: () => context.goNamed(RouteNames.login),
                            ),
                            const SizedBox(height: AppSpacing.base),
                            const GuestHero(),
                          ],
                        ),
                        const Positioned.fill(child: StarSpecks()),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl + AppSpacing.md),
                    const _ValueBlock(),
                    const SizedBox(height: AppSpacing.xxl),
                    const HowItWorksSection(),
                    const SizedBox(height: AppSpacing.xxl),
                    const SampleMemoriesScroller(),
                    const SizedBox(height: AppSpacing.xxl),
                    const TestimonialCard(),
                  ],
                ),
              ),
              _StickyStartNowBar(onStartNow: goToRegister),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestLandingNavBar extends StatelessWidget {
  const _GuestLandingNavBar({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                gradient: AppGradients.primaryCta,
                borderRadius: BorderRadius.all(Radius.circular(9)),
              ),
              child: Text(
                '✦',
                style: AppTypography.chipLabel.copyWith(
                  color: AppColors.background,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('Trevy', style: AppTypography.headlineSerif),
          ],
        ),
        InkWell(
          onTap: onLogin,
          borderRadius: AppRadius.badgeRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              'Log in',
              style: AppTypography.chipLabel.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

const _occasions = ['Weddings', 'Trips', 'Birthdays', 'Milestones'];

class _ValueBlock extends StatelessWidget {
  const _ValueBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR MEMORY COMPANION',
          style: AppTypography.mono.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('Every memory,', style: AppTypography.heroHeadline),
        Text(
          'beautifully captured',
          style: AppTypography.heroHeadline.copyWith(
            fontStyle: FontStyle.italic,
            color: AppColors.primaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'No more messy folders. Weddings, trips, birthday weekends — '
          'your moments deserve more than a desktop dump.',
          style: AppTypography.chipLabel.copyWith(
            fontSize: 13.5,
            height: 1.65,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final occasion in _occasions) _OccasionChip(label: occasion),
          ],
        ),
      ],
    );
  }
}

class _OccasionChip extends StatelessWidget {
  const _OccasionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.surfaceBorder),
        borderRadius: AppRadius.pillRadius,
      ),
      child: Text(
        label,
        style: AppTypography.chipLabel.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _StickyStartNowBar extends StatefulWidget {
  const _StickyStartNowBar({required this.onStartNow});

  final VoidCallback onStartNow;

  @override
  State<_StickyStartNowBar> createState() => _StickyStartNowBarState();
}

class _StickyStartNowBarState extends State<_StickyStartNowBar>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: AppMotion.pulseGlowDuration,
  )..repeat(reverse: true);
  late final _glow = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.pulseGlowCurve,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xxl,
          AppSpacing.lg,
          AppSpacing.base,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, AppColors.background],
            stops: [0, .42],
          ),
        ),
        child: AnimatedBuilder(
          animation: _glow,
          builder: (context, child) => DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.cardRadius,
              boxShadow: [
                BoxShadow(
                  color: AppColors.tint(AppColors.primary, .32 * _glow.value),
                  blurRadius: 14 * _glow.value,
                  spreadRadius: 2 * _glow.value,
                ),
              ],
            ),
            child: child,
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onStartNow,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Start capturing your moments'),
            ),
          ),
        ),
      ),
    );
  }
}
