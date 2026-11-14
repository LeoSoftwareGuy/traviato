import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../../core/l10n/context_l10n.dart';
import '../sky_story/guarded_painter.dart';
import 'neon_ambient.dart';
import 'neon_ambient_painter.dart';
import 'neon_balloon.dart';
import 'neon_chapter_card_painter.dart';
import 'neon_finale_painter.dart';
import 'neon_grain.dart';
import 'neon_night_story.dart';
import 'neon_night_texts.dart';
import 'neon_night_timeline.dart';
import 'neon_photo_images.dart';
import 'neon_scene_painter.dart';
import 'neon_tokens.dart';

/// The Neon Night film (#363): one 1080 × 1920 composition on one looping
/// clock, like `GoldenVowsCanvas`, painted in the spec's layer order
/// (NEON_NIGHT_SPEC.md §4). Built up phase by phase: so far the ambient
/// layers and the neon balloon sign, and every scene from Ignition to the
/// Ending.
/// Its fixed words follow the surrounding locale.
class NeonNightCanvas extends StatefulWidget {
  const NeonNightCanvas({
    required this.story,
    required this.photo,
    this.reducedFlashing = false,
    this.onFailure,
    super.key,
  });

  final NeonNightStory story;

  /// Each photo's full-size image; the film decodes it small for the
  /// contact sheets and large for the laser zooms. Null → an empty mat.
  final ImageProvider? Function(String id) photo;

  /// The film's schedule for [story]: its chapters (each card's length
  /// follows its photos) with their moments. The Plan and Note scenes
  /// play only when the memory has a plan and a note. The Plan scene plays only
  /// when the memory has a plan.
  static NeonNightTimeline timelineFor(NeonNightStory story) =>
      NeonNightTimeline(
        chapters: [
          for (final chapter in story.chapters)
            NnChapterShape(
              moments: [for (final moment in chapter.moments) moment.type],
              photos: chapter.photos.length,
            ),
        ],
        hasPlan: story.hasPlan,
        hasNote: story.hasNote,
      );

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
  late NeonNightTimeline _timeline;
  late NeonAmbient _ambient;
  late NeonBalloon _balloon;
  NeonNightTexts? _texts;
  Locale? _textsLocale;
  ui.Image? _grain = NeonGrain.cached;
  NeonPhotoImages? _photos;
  bool _photosReady = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _start();
    if (_grain == null) unawaited(_loadGrain());
  }

  /// No frame is drawn before the photos are decoded (or have had 5 s).
  void _loadPhotos(NeonNightTimeline timeline) {
    _photos?.dispose();
    _photosReady = false;
    final photos = _photos = NeonPhotoImages(
      widget.photo,
      story: widget.story,
      timeline: timeline,
    );
    unawaited(
      photos.ready().then((_) {
        if (!mounted || _photos != photos) return;
        setState(() => _photosReady = true);
        _play();
      }),
    );
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
    final timeline = _timeline = NeonNightCanvas.timelineFor(widget.story);
    _ambient = NeonAmbient(
      timeline,
      reducedFlashing: widget.reducedFlashing,
    );
    _balloon = NeonBalloon(
      timeline,
      reducedFlashing: widget.reducedFlashing,
    );
    _clock.total = timeline.total;
    _loadPhotos(timeline);
    _controller
      ..stop()
      ..duration = Duration(milliseconds: (timeline.total * 1000).round())
      ..value = 0;
    _play();
  }

  void _play() {
    if (_grain == null || !_photosReady || _failed || !mounted) return;
    unawaited(_controller.repeat());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _layoutTexts();
  }

  @override
  void didUpdateWidget(NeonNightCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    final storyChanged =
        oldWidget.story != widget.story || oldWidget.photo != widget.photo;
    if (storyChanged || oldWidget.reducedFlashing != widget.reducedFlashing) {
      final at = _controller.value;
      _start();
      // Switching reduced flashing keeps the film where it was.
      if (!storyChanged) _controller.value = at;
      _play();
    }
    if (storyChanged) {
      _textsLocale = null;
      _layoutTexts();
    }
  }

  void _layoutTexts() {
    if (_failed) return;
    final locale = Localizations.maybeLocaleOf(context);
    if (_texts != null && locale == _textsLocale) return;
    try {
      final texts = NeonNightTexts(widget.story, context.l10n);
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
    _texts?.dispose();
    _photos?.dispose();
    _clock.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grain = _grain;
    final texts = _texts;
    final photos = _photos;
    if (_failed || grain == null || texts == null || photos == null) {
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
                    NeonScenePainter(
                      timeline: _timeline,
                      story: widget.story,
                      texts: texts,
                      photos: photos,
                      time: _clock,
                      reducedFlashing: widget.reducedFlashing,
                    ),
                    NeonLaserPainter(ambient: _ambient, time: _clock),
                    NeonBalloonPainter(balloon: _balloon, time: _clock),
                    NeonTopPainter(
                      timeline: _timeline,
                      texts: texts,
                      time: _clock,
                      reducedFlashing: widget.reducedFlashing,
                    ),
                    NeonFlashPainter(
                      timeline: _timeline,
                      time: _clock,
                      reducedFlashing: widget.reducedFlashing,
                    ),
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
