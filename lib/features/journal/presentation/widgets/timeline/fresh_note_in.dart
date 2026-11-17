import 'package:flutter/material.dart';

import '../../../../../core/theme/app_motion.dart';

Duration get _total =>
    AppMotion.noteSlotOpenDelay +
    AppMotion.noteDropDelay +
    AppMotion.noteDropDuration;

double _at(Duration d) => d.inMicroseconds / _total.inMicroseconds;

/// A just-saved note's entrance (#407, docs/design/journal-notes/ §7): its
/// slot opens from 0 height at +420ms (340ms), and the card drops in from
/// 18px up at 96% scale, 120ms later (700ms). Under reduced motion, a
/// 200ms crossfade. Anything not [isFresh] is shown as is.
class FreshNoteIn extends StatefulWidget {
  const FreshNoteIn({required this.isFresh, required this.child, super.key});

  final bool isFresh;
  final Widget child;

  @override
  State<FreshNoteIn> createState() => _FreshNoteInState();
}

class _FreshNoteInState extends State<FreshNoteIn>
    with SingleTickerProviderStateMixin {
  // Created up front, never lazily: a lazy controller first touched in
  // dispose() would create a ticker on a deactivated element (#412).
  late final AnimationController _c;
  var _reducedMotion = false;

  late final Animation<double> _slot = CurvedAnimation(
    parent: _c,
    curve: Interval(
      _at(AppMotion.noteSlotOpenDelay),
      _at(AppMotion.noteSlotOpenDelay + AppMotion.noteSlotOpenDuration),
      curve: AppMotion.noteCurve,
    ),
  );
  late final Animation<double> _drop = CurvedAnimation(
    parent: _c,
    curve: Interval(
      _at(AppMotion.noteSlotOpenDelay + AppMotion.noteDropDelay),
      1,
      curve: AppMotion.noteCurve,
    ),
  );

  @override
  void initState() {
    super.initState();
    // Rebuilds once it's done, to drop the animated wrapper.
    _c = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) setState(() {});
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (widget.isFresh && _c.status == AnimationStatus.dismissed) _start();
  }

  @override
  void didUpdateWidget(FreshNoteIn old) {
    super.didUpdateWidget(old);
    if (widget.isFresh && !old.isFresh) _start();
  }

  void _start() {
    _c
      ..duration = _reducedMotion ? AppMotion.noteReducedMotionFade : _total
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_c.isAnimating) return widget.child;
    if (_reducedMotion) {
      return FadeTransition(opacity: _c, child: widget.child);
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final d = _drop.value;
        return ClipRect(
          child: Align(
            key: const Key('fresh-note-slot'),
            alignment: Alignment.topCenter,
            heightFactor: _slot.value,
            child: Opacity(
              opacity: d,
              child: Transform.translate(
                offset: Offset(0, -AppMotion.noteDropOffset * (1 - d)),
                child: Transform.scale(
                  scale:
                      AppMotion.noteDropScale +
                      (1 - AppMotion.noteDropScale) * d,
                  alignment: Alignment.topCenter,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
