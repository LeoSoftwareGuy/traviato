import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../sky_story/guarded_painter.dart';
import 'neon_ambient.dart';
import 'neon_ambient_painter.dart';
import 'neon_balloon.dart';
import 'neon_grain.dart';
import 'neon_night_timeline.dart';
import 'neon_tokens.dart';

/// The Neon Night film (#363): one 1080 × 1920 composition on one looping
/// clock, like `GoldenVowsCanvas`, painted in the spec's layer order
/// (NEON_NIGHT_SPEC.md §4). Built up phase by phase: so far the black,
/// haze, lasers, the neon balloon sign, grain, vignette and the fade to
/// black.
class NeonNightCanvas extends StatefulWidget {
  const NeonNightCanvas({
    required this.timeline,
    this.reducedFlashing = false,
    this.onFailure,
    super.key,
  });

  final NeonNightTimeline timeline;

  /// The §6 version: softer flicker, flares and laser punch, same timings.
  final bool reducedFlashing;

  /// Called once, after the frame, if painting throws: the film stops and
  /// goes black, and the caller can play something else.
  final void Function(Object error, StackTrace stack)? onFailure;

  @override
  State<NeonNightCanvas> createState() => _NeonNightCanvasState();
}

class _NeonNightCanvasState extends State<NeonNightCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
  );
  late final _clock = _FilmClock(_controller);
  late NeonAmbient _ambient;
  late NeonBalloon _balloon;
  ui.Image? _grain = NeonGrain.cached;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _start();
    if (_grain == null) unawaited(_loadGrain());
  }

  /// No frame is drawn without the grain: the clock starts once it's made.
  Future<void> _loadGrain() async {
    try {
      final grain = await NeonGrain.load();
      if (!mounted) return;
      setState(() => _grain = grain);
      _play();
    } catch (error, stack) {
      _fail(error, stack);
    }
  }

  void _start() {
    final timeline = widget.timeline;
    _ambient = NeonAmbient(
      timeline,
      reducedFlashing: widget.reducedFlashing,
    );
    _balloon = NeonBalloon(
      timeline,
      reducedFlashing: widget.reducedFlashing,
    );
    _clock.total = timeline.total;
    _controller
      ..stop()
      ..duration = Duration(milliseconds: (timeline.total * 1000).round())
      ..value = 0;
    _play();
  }

  void _play() {
    if (_grain == null || _failed || !mounted) return;
    unawaited(_controller.repeat());
  }

  @override
  void didUpdateWidget(NeonNightCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeline != widget.timeline ||
        oldWidget.reducedFlashing != widget.reducedFlashing) {
      final at = _controller.value;
      _start();
      // Switching reduced flashing keeps the film where it was.
      if (oldWidget.timeline == widget.timeline) _controller.value = at;
      _play();
    }
  }

  void _fail(Object error, StackTrace stack) {
    if (_failed) return;
    _failed = true;
    debugPrint('Neon Night failed; the film stops: $error\n$stack');
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
    final grain = _grain;
    if (_failed || grain == null) {
      return const ColoredBox(color: NeonColors.black);
    }
    return ColoredBox(
      color: NeonColors.black,
      child: FittedBox(
        child: SizedBox(
          width: NeonAmbient.width,
          height: NeonAmbient.height,
          child: ClipRect(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: GuardedPainter(
                  _Layers([
                    NeonBackPainter(ambient: _ambient, time: _clock),
                    NeonLaserPainter(ambient: _ambient, time: _clock),
                    NeonBalloonPainter(balloon: _balloon, time: _clock),
                    NeonFrontPainter(
                      ambient: _ambient,
                      grain: grain,
                      time: _clock,
                    ),
                  ]),
                  repaint: _clock,
                  onError: _fail,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The film's layers, painted bottom to top.
class _Layers extends CustomPainter {
  _Layers(this.layers);

  final List<CustomPainter> layers;

  @override
  void paint(Canvas canvas, Size size) {
    for (final layer in layers) {
      layer.paint(canvas, size);
    }
  }

  @override
  bool shouldRepaint(_Layers oldDelegate) =>
      layers.length != oldDelegate.layers.length ||
      [
        for (var i = 0; i < layers.length; i++)
          layers[i].shouldRepaint(oldDelegate.layers[i]),
      ].any((repaint) => repaint);
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
