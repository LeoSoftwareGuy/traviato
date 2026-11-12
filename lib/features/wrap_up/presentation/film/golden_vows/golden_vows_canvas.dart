import 'package:flutter/material.dart';

import '../sky_story/guarded_painter.dart';
import 'golden_vows_ambient.dart';
import 'golden_vows_ambient_painter.dart';
import 'golden_vows_timeline.dart';

/// The Golden Vows film (#346): one 1080×1920 composition on one looping
/// clock, like `SkyStoryCanvas`. Phase 1 paints the ambient layer only —
/// the background and light leaks under where the invitation, packing
/// card, album and ending will go, the gold frame, flare and petals over
/// them.
class GoldenVowsCanvas extends StatefulWidget {
  const GoldenVowsCanvas({required this.timeline, this.onFailure, super.key});

  final GoldenVowsTimeline timeline;

  /// Called once, after the frame, if painting throws: the film stops
  /// and goes blank, and the caller can play something else.
  final void Function(Object error, StackTrace stack)? onFailure;

  @override
  State<GoldenVowsCanvas> createState() => _GoldenVowsCanvasState();
}

class _GoldenVowsCanvasState extends State<GoldenVowsCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
  );
  late final _clock = _FilmClock(_controller);
  late GoldenVowsAmbient _ambient;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _ambient = GoldenVowsAmbient(widget.timeline);
    _clock.total = widget.timeline.total;
    _controller
      ..duration = Duration(
        milliseconds: (widget.timeline.total * 1000).round(),
      )
      ..value = 0
      ..repeat();
  }

  @override
  void didUpdateWidget(GoldenVowsCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeline != widget.timeline) _start();
  }

  void _fail(Object error, StackTrace stack) {
    if (_failed) return;
    _failed = true;
    debugPrint('Golden Vows failed; the film stops: $error\n$stack');
    _controller.stop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {});
      widget.onFailure?.call(error, stack);
    });
  }

  @override
  void dispose() {
    _clock.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const ColoredBox(color: Colors.black);
    return ColoredBox(
      color: Colors.black,
      child: FittedBox(
        child: SizedBox(
          width: GoldenVowsAmbient.width,
          height: GoldenVowsAmbient.height,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: GuardedPainter(
                GoldenVowsBackPainter(ambient: _ambient, time: _clock),
                repaint: _clock,
                onError: _fail,
              ),
              foregroundPainter: GuardedPainter(
                GoldenVowsFrontPainter(ambient: _ambient, time: _clock),
                repaint: _clock,
                onError: _fail,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The controller's 0–1 value as film seconds.
class _FilmClock extends ValueNotifier<double> {
  _FilmClock(this._controller) : super(0) {
    _controller.addListener(_tick);
  }

  final AnimationController _controller;

  /// The film's length, s.
  double total = 0;

  void _tick() => value = _controller.value * total;

  @override
  void dispose() {
    _controller.removeListener(_tick);
    super.dispose();
  }
}
