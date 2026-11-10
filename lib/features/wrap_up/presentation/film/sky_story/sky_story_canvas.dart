import 'package:flutter/material.dart';

import '../timeline/film_timeline.dart';
import 'sky_scene_spec.dart';
import 'sky_world.dart';
import 'sky_world_painter.dart';

/// The Sky Story film (#345): one 1080×1920 composition on one looping
/// clock, like `WrapUpFilmCanvas`. Phase 1 plays the world only (sky,
/// clouds, embers, stars and balloons); the title, pages and mosaic are
/// laid over it in later phases.
class SkyStoryCanvas extends StatefulWidget {
  const SkyStoryCanvas({required this.timeline, super.key});

  final FilmTimeline<SkySceneSpec> timeline;

  @override
  State<SkyStoryCanvas> createState() => _SkyStoryCanvasState();
}

class _SkyStoryCanvasState extends State<SkyStoryCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final SkyWorld _world;
  late final _FilmClock _clock;

  @override
  void initState() {
    super.initState();
    _world = SkyWorld(widget.timeline);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (widget.timeline.total * 1000).round()),
    )..repeat();
    _clock = _FilmClock(_controller, widget.timeline.total);
  }

  @override
  void dispose() {
    _clock.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: FittedBox(
        child: SizedBox(
          width: SkyWorld.width,
          height: SkyWorld.height,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: SkyWorldPainter(world: _world, time: _clock),
            ),
          ),
        ),
      ),
    );
  }
}

/// The controller's 0–1 value as film seconds.
class _FilmClock extends ValueNotifier<double> {
  _FilmClock(this._controller, this._total)
    : super(_controller.value * _total) {
    _controller.addListener(_tick);
  }

  final AnimationController _controller;
  final double _total;

  void _tick() => value = _controller.value * _total;

  @override
  void dispose() {
    _controller.removeListener(_tick);
    super.dispose();
  }
}
