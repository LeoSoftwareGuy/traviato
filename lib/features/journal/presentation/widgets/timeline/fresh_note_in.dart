import 'package:flutter/material.dart';

import '../../../../../core/theme/app_motion.dart';

const _freshSlide = Duration(milliseconds: 420);

/// The freshly saved note's entrance: up 14px and in, or a plain fade
/// under reduced motion (spec §7).
class FreshNoteIn extends StatelessWidget {
  const FreshNoteIn({required this.isFresh, required this.child, super.key});

  final bool isFresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isFresh) return child;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reducedMotion
          ? AppMotion.pageTurnReducedMotionFade
          : _freshSlide,
      curve: AppMotion.progressCurve,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, reducedMotion ? 0 : (1 - t) * 14),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
