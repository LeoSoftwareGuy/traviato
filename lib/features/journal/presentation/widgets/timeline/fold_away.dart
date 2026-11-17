import 'package:flutter/material.dart';

import '../../../../../core/theme/app_motion.dart';

/// A deleted note leaving (#407, spec §7): it fades (250ms) while its
/// height folds to 0 (340ms), so the cards below move up. Under reduced
/// motion, a 200ms fade. The page removes the note once this is done.
class FoldAway extends StatefulWidget {
  const FoldAway({required this.isLeaving, required this.child, super.key});

  final bool isLeaving;
  final Widget child;

  /// How long the page waits before removing the note.
  static Duration durationFor(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
      ? AppMotion.noteReducedMotionFade
      : AppMotion.noteDeleteFoldDuration;

  @override
  State<FoldAway> createState() => _FoldAwayState();
}

class _FoldAwayState extends State<FoldAway>
    with SingleTickerProviderStateMixin {
  // Created up front, never lazily: a lazy controller first touched in
  // dispose() would create a ticker on a deactivated element (#412).
  late final AnimationController _c;
  var _reducedMotion = false;

  late final Animation<double> _fade = CurvedAnimation(
    parent: _c,
    curve: Interval(
      0,
      AppMotion.noteDeleteFadeDuration.inMicroseconds /
          AppMotion.noteDeleteFoldDuration.inMicroseconds,
    ),
  );
  late final Animation<double> _fold = CurvedAnimation(
    parent: _c,
    curve: AppMotion.noteCurve,
  );

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (widget.isLeaving && _c.status == AnimationStatus.dismissed) _start();
  }

  @override
  void didUpdateWidget(FoldAway old) {
    super.didUpdateWidget(old);
    if (widget.isLeaving && !old.isLeaving) _start();
    if (!widget.isLeaving && old.isLeaving) _c.value = 0;
  }

  void _start() {
    _c
      ..duration = FoldAway.durationFor(context)
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLeaving) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Opacity(
        key: const Key('fold-away'),
        opacity: 1 - (_reducedMotion ? _c.value : _fade.value),
        child: _reducedMotion
            ? child
            : ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: 1 - _fold.value,
                  child: child,
                ),
              ),
      ),
      child: widget.child,
    );
  }
}
