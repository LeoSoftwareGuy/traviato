import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Shared `riseIn` entrance — opacity 0→1 + translateY [AppMotion.riseInOffset]→0.
/// `docs/design/README.md` § Motion. Used by [BottomSheetChrome] and the
/// Compare screen's financial-comparison table.
class RiseIn extends StatelessWidget {
  const RiseIn({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.riseInDuration,
      curve: AppMotion.riseInCurve,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, AppMotion.riseInOffset * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
