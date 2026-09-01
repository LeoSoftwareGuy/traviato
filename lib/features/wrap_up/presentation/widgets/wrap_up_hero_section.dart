import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/photo_scrim.dart';
import '../../domain/entities/wrap_up_hero.dart';
import 'ken_burns_image.dart';
import 'wrap_up_photo_image.dart';

/// The opening block: full-bleed ken-burns cover, staggered `riseIn` text
/// reveal (docs/design/README.md § 12).
class WrapUpHeroSection extends StatelessWidget {
  const WrapUpHeroSection({
    required this.hero,
    required this.coverImageUrl,
    required this.tripStartDate,
    required this.onClose,
    super.key,
  });

  final WrapUpHero hero;
  final String? coverImageUrl;
  final DateTime? tripStartDate;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final eyebrow = tripStartDate == null
        ? 'THE WRAP-UP'
        : 'THE WRAP-UP · ${DateFormat('MMM yyyy').format(tripStartDate!).toUpperCase()}';

    return SizedBox(
      height: 640,
      child: PhotoScrim(
        image: KenBurnsImage(
          child: WrapUpPhotoImage(imageUrl: coverImageUrl),
        ),
        child: Stack(
          children: [
            Positioned(
              top: AppSpacing.lg,
              left: AppSpacing.lg,
              child: _CloseButton(onTap: onClose),
            ),
            Positioned(
              top: AppSpacing.lg,
              right: AppSpacing.xl,
              child: Text(
                'SCROLL TO RELIVE ↓',
                style: AppTypography.mono.copyWith(
                  color: AppColors.textOnPhotoMuted,
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              bottom: AppSpacing.xxl,
              child: _StaggeredHeroText(eyebrow: eyebrow, hero: hero),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: AppColors.tint(AppColors.background, .55),
          child: InkWell(
            onTap: onTap,
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: Icon(
                Icons.close,
                color: AppColors.textOnPhoto,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StaggeredHeroText extends StatefulWidget {
  const _StaggeredHeroText({required this.eyebrow, required this.hero});

  final String eyebrow;
  final WrapUpHero hero;

  @override
  State<_StaggeredHeroText> createState() => _StaggeredHeroTextState();
}

class _StaggeredHeroTextState extends State<_StaggeredHeroText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final lineCount = widget.hero.subtitle == null ? 2 : 3;
    final totalMs =
        AppMotion.riseInStagger.inMilliseconds * (lineCount - 1) +
        AppMotion.riseInDuration.inMilliseconds;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _lineAnimation(int index) {
    final startMs = AppMotion.riseInStagger.inMilliseconds * index;
    final endMs = startMs + AppMotion.riseInDuration.inMilliseconds;
    final totalMs = _controller.duration!.inMilliseconds;
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(
        startMs / totalMs,
        (endMs / totalMs).clamp(0.0, 1.0),
        curve: AppMotion.riseInCurve,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.hero.subtitle;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _RiseInLine(
            animation: _lineAnimation(0),
            child: Text(
              widget.eyebrow,
              style: AppTypography.mono.copyWith(color: AppColors.primaryLight),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _RiseInLine(
            animation: _lineAnimation(1),
            child: Text(
              widget.hero.title,
              style: AppTypography.heroHeadline.copyWith(
                color: AppColors.textOnPhoto,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _RiseInLine(
              animation: _lineAnimation(2),
              child: Text(subtitle, style: AppTypography.pullQuote),
            ),
          ],
        ],
      ),
    );
  }
}

class _RiseInLine extends StatelessWidget {
  const _RiseInLine({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: animation.value.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, AppMotion.riseInOffset * (1 - animation.value)),
        child: child,
      ),
    );
  }
}
