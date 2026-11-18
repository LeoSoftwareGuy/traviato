import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_motion.dart';

/// One orange ring around a just-saved note (#407, spec §7): from +800ms
/// its shadow grows to 14px while it fades, over 1.4s. None under reduced
/// motion.
class FreshGlow extends StatefulWidget {
  const FreshGlow({
    required this.isFresh,
    required this.borderRadius,
    required this.child,
    super.key,
  });

  final bool isFresh;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  State<FreshGlow> createState() => _FreshGlowState();
}

class _FreshGlowState extends State<FreshGlow>
    with SingleTickerProviderStateMixin {
  // Created up front, never lazily: a lazy controller first touched in
  // dispose() would create a ticker on a deactivated element (#412).
  late final AnimationController _c;
  late final Animation<double> _ring = CurvedAnimation(
    parent: _c,
    curve: Interval(
      AppMotion.noteGlowDelay.inMicroseconds / _c.duration!.inMicroseconds,
      1,
      curve: Curves.easeOut,
    ),
  );

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: AppMotion.noteGlowDelay + AppMotion.noteGlowDuration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.isFresh && _c.status == AnimationStatus.dismissed) _start();
  }

  @override
  void didUpdateWidget(FreshGlow old) {
    super.didUpdateWidget(old);
    if (widget.isFresh && !old.isFresh) _start();
  }

  void _start() {
    if (MediaQuery.disableAnimationsOf(context)) return;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _ring.value;
        if (!_c.isAnimating || t == 0) return child!;
        return DecoratedBox(
          key: const Key('fresh-note-glow'),
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            boxShadow: [
              BoxShadow(
                color: AppColors.tint(AppColors.primary, .55 * (1 - t)),
                blurRadius: AppMotion.noteGlowSpread * t,
                spreadRadius: AppMotion.noteGlowSpread * t * .5,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
