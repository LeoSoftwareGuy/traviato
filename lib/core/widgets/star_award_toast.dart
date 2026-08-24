import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// The only success affordance for star awards — no snackbars, no dialogs.
/// `✦ +2 stars · photo logged`, `✦ Packed — nice`, etc.
///
/// Shows a stadium toast 104px from the top, centered, non-interactive,
/// riding the `awardPop` motion and auto-dismissing at ~1650ms. Calling this
/// again before a pending toast finishes replaces it immediately — a
/// generation key stops the pre-empted toast's own dismiss timer from
/// tearing down the new one.
void showStarToast(BuildContext context, String text) {
  final overlay = Overlay.of(context, rootOverlay: true);
  _StarToastHost.dismissCurrent();

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) =>
        _StarToast(text: text, onFinished: () => _StarToastHost.clear(entry)),
  );
  _StarToastHost.current = entry;
  overlay.insert(entry);
}

/// Holds the single currently-showing toast entry so a new award can remove
/// a pending one before its own timer fires.
abstract class _StarToastHost {
  static OverlayEntry? current;

  static void dismissCurrent() {
    current?.remove();
    current = null;
  }

  static void clear(OverlayEntry entry) {
    if (identical(current, entry)) {
      entry.remove();
      current = null;
    }
  }
}

class _StarToast extends StatefulWidget {
  const _StarToast({required this.text, required this.onFinished});

  final String text;
  final VoidCallback onFinished;

  @override
  State<_StarToast> createState() => _StarToastState();
}

class _StarToastState extends State<_StarToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _translateY;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.awardPopDuration,
    )..addStatusListener(_onStatusChanged);

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 15),
    ]).animate(_controller);

    _translateY =
        Tween<double>(
          begin: -6,
          end: -22,
        ).animate(
          CurvedAnimation(parent: _controller, curve: AppMotion.awardPopCurve),
        );

    _scale =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.04), weight: 20),
          TweenSequenceItem(tween: Tween(begin: 1.04, end: 1.0), weight: 15),
          TweenSequenceItem(tween: ConstantTween(1.0), weight: 65),
        ]).animate(
          CurvedAnimation(parent: _controller, curve: AppMotion.awardPopCurve),
        );

    _controller.forward();
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onFinished();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 104,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Opacity(
            opacity: _opacity.value,
            child: Transform.translate(
              offset: Offset(0, _translateY.value),
              child: Transform.scale(scale: _scale.value, child: child),
            ),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.tint(AppColors.primary, .94),
                borderRadius: AppRadius.pillRadius,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.tint(AppColors.primary, .35),
                    blurRadius: 34,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Text(
                widget.text,
                style: AppTypography.buttonLabel.copyWith(
                  fontSize: 13,
                  color: AppColors.background,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
