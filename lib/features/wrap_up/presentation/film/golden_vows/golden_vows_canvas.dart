import 'package:flutter/material.dart';

import '../../../../../core/l10n/context_l10n.dart';
import '../sky_story/guarded_painter.dart';
import 'golden_vows_ambient.dart';
import 'golden_vows_ambient_painter.dart';
import 'golden_vows_intro_painter.dart';
import 'golden_vows_story.dart';
import 'golden_vows_texts.dart';
import 'golden_vows_timeline.dart';

/// The Golden Vows film (#346): one 1080×1920 composition on one looping
/// clock, like `SkyStoryCanvas`, painted in the spec's layer order:
/// background and light leaks; the invitation and packing card; (the
/// album, heart and ending in later phases); the gold frame, flare and
/// petals on top. Its fixed words follow the surrounding locale.
class GoldenVowsCanvas extends StatefulWidget {
  const GoldenVowsCanvas({required this.story, this.onFailure, super.key});

  final GoldenVowsStory story;

  /// Called once, after the frame, if laying out the words or painting
  /// throws: the film stops and goes blank, and the caller can play
  /// something else.
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
  late GoldenVowsTimeline _timeline;
  late GoldenVowsAmbient _ambient;
  GoldenVowsTexts? _texts;
  Locale? _textsLocale;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  /// The film's scenes for the story: no packed items, no packing card.
  static GoldenVowsTimeline timelineFor(GoldenVowsStory story) =>
      GoldenVowsTimeline(hasPackingCard: story.hasPackingCard);

  void _start() {
    _timeline = timelineFor(widget.story);
    _ambient = GoldenVowsAmbient(_timeline);
    _clock.total = _timeline.total;
    _controller
      ..duration = Duration(milliseconds: (_timeline.total * 1000).round())
      ..value = 0
      ..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _layoutTexts();
  }

  @override
  void didUpdateWidget(GoldenVowsCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.story == widget.story) return;
    _start();
    _textsLocale = null;
    _layoutTexts();
  }

  void _layoutTexts() {
    if (_failed) return;
    final locale = Localizations.maybeLocaleOf(context);
    if (_texts != null && locale == _textsLocale) return;
    try {
      final texts = GoldenVowsTexts(widget.story, context.l10n);
      _texts?.dispose();
      _texts = texts;
      _textsLocale = locale;
    } catch (error, stack) {
      _fail(error, stack);
    }
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
    _texts?.dispose();
    _clock.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final texts = _texts;
    if (_failed || texts == null) {
      return const ColoredBox(color: Colors.black);
    }
    return ColoredBox(
      color: Colors.black,
      child: FittedBox(
        child: SizedBox(
          width: GoldenVowsAmbient.width,
          height: GoldenVowsAmbient.height,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: GuardedPainter(
                _Layers([
                  GoldenVowsBackPainter(ambient: _ambient, time: _clock),
                  GoldenVowsIntroPainter(
                    timeline: _timeline,
                    texts: texts,
                    time: _clock,
                  ),
                  GoldenVowsFrontPainter(ambient: _ambient, time: _clock),
                ]),
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
