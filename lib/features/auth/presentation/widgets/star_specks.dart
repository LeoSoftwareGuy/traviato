import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';

/// Four twinkling dots scattered over the guest landing nav/hero area.
/// `docs/design/README.md` § 1.
class StarSpecks extends StatelessWidget {
  const StarSpecks({super.key});

  static const _specks = [
    _Speck(top: 4, left: 210, size: 3, color: AppColors.primary, delayMs: 0),
    _Speck(
      top: 46,
      left: 30,
      size: 2,
      color: Color(0xFFF6C77A),
      delayMs: 900,
    ),
    _Speck(top: 18, left: 130, size: 2, color: Colors.white, delayMs: 1700),
    _Speck(
      top: 60,
      left: 270,
      size: 3,
      color: AppColors.primary,
      delayMs: 2500,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          for (final speck in _specks)
            Positioned(
              top: speck.top,
              left: speck.left,
              child: _Twinkle(
                size: speck.size,
                color: speck.color,
                delayMs: speck.delayMs,
              ),
            ),
        ],
      ),
    );
  }
}

class _Speck {
  const _Speck({
    required this.top,
    required this.left,
    required this.size,
    required this.color,
    required this.delayMs,
  });

  final double top;
  final double left;
  final double size;
  final Color color;
  final int delayMs;
}

class _Twinkle extends StatefulWidget {
  const _Twinkle({
    required this.size,
    required this.color,
    required this.delayMs,
  });

  final double size;
  final Color color;
  final int delayMs;

  @override
  State<_Twinkle> createState() => _TwinkleState();
}

class _TwinkleState extends State<_Twinkle>
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

  @override
  void initState() {
    super.initState();
    _startTimer = Timer(
      Duration(milliseconds: widget.delayMs),
      () => _controller.repeat(reverse: true),
    );
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
