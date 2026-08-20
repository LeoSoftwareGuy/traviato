import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Ambient purple/orange/coral glow behind the Plan header, matching the
/// blurred radial-gradient decoration in the Figma frame.
class PlanBackgroundGlow extends StatelessWidget {
  const PlanBackgroundGlow({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: ClipRect(
        child: SizedBox(
          height: 180,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -90,
                left: -60,
                child: _Glow(
                  color: AppColors.accentPurple,
                  opacity: 0.35,
                  size: 240,
                ),
              ),
              Positioned(
                top: -110,
                right: -50,
                child: _Glow(color: AppColors.primary, opacity: 0.3, size: 210),
              ),
              Positioned(
                top: -20,
                left: 40,
                child: _Glow(
                  color: AppColors.accentCoral,
                  opacity: 0.3,
                  size: 190,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.opacity, required this.size});

  final Color color;
  final double opacity;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity),
        ),
      ),
    );
  }
}
