import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// A single twinkling dot — the star-speck animation shared by guest
/// landing's [StarSpecks]-style scatters and the paywall's background
/// specks. Fades/scales up from a resting state after [delayMs], then loops.
/// With reduce motion on it holds still at the loop's midpoint (#198) — the
/// value-0 rest is close to invisible, and a still sky should still read as
/// starry. `docs/design/README.md` § Motion (`twinkle`).
class TwinkleDot extends StatefulWidget {
  const TwinkleDot({
    required this.size,
    required this.color,
    required this.delayMs,
    super.key,
  });

  final double size;
  final Color color;
  final int delayMs;

  @override
  State<TwinkleDot> createState() => _TwinkleDotState();
}

class _TwinkleDotState extends State<TwinkleDot>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.delayMs.isEven
        ? AppMotion.twinkleMinDuration
        : AppMotion.twinkleMaxDuration,
  );
  late final _opacity =
      Tween<double>(
        begin: .12,
        end: .85,
      ).animate(
        CurvedAnimation(parent: _controller, curve: AppMotion.twinkleCurve),
      );
  late final _scale =
      Tween<double>(
        begin: .7,
        end: 1.15,
      ).animate(
        CurvedAnimation(parent: _controller, curve: AppMotion.twinkleCurve),
      );

  Timer? _startTimer;

  static const _reducedMotionValue = .5;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _startTimer?.cancel();
      _startTimer = null;
      _controller
        ..stop()
        ..value = _reducedMotionValue;
    } else if (!_controller.isAnimating && _startTimer == null) {
      _controller.value = 0;
      _startTimer = Timer(
        Duration(milliseconds: widget.delayMs),
        () => _controller.repeat(reverse: true),
      );
    }
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.scale(scale: _scale.value, child: child),
      ),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
