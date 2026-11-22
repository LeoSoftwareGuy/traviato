import 'dart:math' as math;

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../../core/l10n/context_l10n.dart';
import '../../../domain/wrap_up_limits.dart';
import '../film_music.dart';
import '../sky_story/guarded_painter.dart';
import 'neon_ambient.dart';
import 'neon_ambient_painter.dart';
import 'neon_balloon.dart';
import 'neon_beat.dart';
import 'neon_chapter_card_painter.dart';
import 'neon_finale_painter.dart';
import 'neon_grain.dart';
import 'neon_night_story.dart';
import 'neon_night_texts.dart';
import 'neon_night_timeline.dart';
import 'neon_photo_images.dart';
import 'neon_reading_time.dart';
import 'neon_scene_painter.dart';
import 'neon_tokens.dart';
import 'neon_track.dart';

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
    this.beat = const NeonBeat(),
    this.music,
    this.muted = false,
    this.onFailure,
    super.key,
  });

  final NeonNightStory story;

  /// Each photo's full-size image; the film decodes it small for the
  /// contact sheets and large for the laser zooms. Null → an empty mat.
  final ImageProvider? Function(String id) photo;

  /// The film's schedule for [story]: its chapters (each card's length
  /// follows its photos) with their moments, each long enough to read the
  /// user's words (#399). The Plan and Note scenes play only when the
  /// memory has a plan and a note that fits.
  ///
  /// With a target length (`content.film_seconds`, #434) the moments hold
  /// longer, a whole bar at a time and in turn, until the film lasts about
  /// that long; the edge function already left out what wouldn't fit.
  static NeonNightTimeline timelineFor(
    NeonNightStory story, {
    NeonBeat beat = const NeonBeat(),
  }) {
    NeonNightTimeline build(List<NnChapterShape> chapters) => NeonNightTimeline(
      chapters: chapters,
      hasPlan: story.hasPlan,
      hasNote: story.hasNote,
      noteMinBeats: NnReadingTime.noteBeats(story, beat),
      beat: beat,
    );
    final chapters = NnReadingTime.chaptersFor(story, beat);
    final base = build(chapters);
    final target = story.targetSeconds;
    if (target == null) return base;
    // To the nearest bar of the target, never past the longest film (#448:
    // 75 s is a hard max).
    final bars = math.min(
      ((beat.secToBeat(target) - base.totalBeats + 2) / 4).floor(),
      ((beat.secToBeat(WrapUpLimits.longestFilmSeconds.toDouble()) -
                  base.totalBeats) /
              4)
          .floor(),
    );
    // A moment holds longer only up to a bar per photo (#456: a 2-photo
    // split held 7.7 s); a line that needs its reading time keeps it.
    final room = [
      for (final (i, c) in chapters.indexed)
        [
          for (final (j, type) in c.moments.indexed)
            (((math.max(type.beats, 4 * _photosIn(story, i, j)) -
                            math.max(
                              type.beats,
                              j < c.momentMinBeats.length
                                  ? c.momentMinBeats[j]
                                  : 0,
                            )) /
                        4)
                    .floor())
                .clamp(0, maxExtraMomentBars),
        ],
    ];
    final moments = room.fold(0, (n, r) => n + r.fold(0, (a, b) => a + b));
    if (bars <= 0 || moments == 0) return base;
    final extra = [
      for (final c in chapters) List.filled(c.moments.length, 0),
    ];
    var left = math.min(bars, moments);
    while (left > 0) {
      for (var i = 0; i < chapters.length && left > 0; i++) {
        for (var j = 0; j < chapters[i].moments.length && left > 0; j++) {
          if (extra[i][j] >= room[i][j]) continue;
          extra[i][j]++;
          left--;
        }
      }
    }
    return build([
      for (final (i, c) in chapters.indexed)
        NnChapterShape(
          moments: c.moments,
          photos: c.photos,
          zoomHolds: c.zoomHolds,
          // The card's own zoom count (#448), not the default for its photos.
          zooms: c.zooms,
          cardMinBeats: c.cardMinBeats,
          momentMinBeats: [
            for (final (j, type) in c.moments.indexed)
              math.max(
                    type.beats,
                    j < c.momentMinBeats.length ? c.momentMinBeats[j] : 0,
                  ) +
                  4 * extra[i][j],
          ],
        ),
    ]);
  }

  /// The most bars a moment holds longer to fit the film's length (#434).
  static const maxExtraMomentBars = 3;

  static int _photosIn(NeonNightStory story, int chapter, int moment) {
    final moments = story.chapters[chapter].moments;
    return moment < moments.length ? moments[moment].photos.length : 0;
  }

  /// The §6 version: softer flicker, flares and laser punch, same timings.
  final bool reducedFlashing;

  /// The film's beat clock. With [music] it must be [NeonTrack.beat]; the
  /// spec's 126 bpm otherwise (goldens).
  final NeonBeat beat;

  /// Makes the player for the film's music from the track parts that fit
  /// this film ([NeonTrack.partsForTimeline]), or null for a silent film
  /// (tests, goldens). [NeonTrack.player] is the real one.
  final FilmMusicPlayer Function(List<NeonTrackPart> parts)? music;

  /// Silences the music without stopping its clock.
  final bool muted;

  /// Called once, after the frame, if painting throws: the film stops and
  /// goes black, and the caller can play something else.
  final void Function(Object error, StackTrace stack)? onFailure;

  @override
  State<NeonNightCanvas> createState() => _NeonNightCanvasState();
}

/// The running film, for tests (#456): how long the player loops it.
abstract interface class NeonNightPlayback {
  /// The film's length as the player runs it: its clock's loop.
  Duration get playLength;
}

class _NeonNightCanvasState extends State<NeonNightCanvas>
    with SingleTickerProviderStateMixin
    implements NeonNightPlayback {
  @override
  Duration get playLength => _controller.duration ?? Duration.zero;

  late final AnimationController _controller = AnimationController(
    vsync: this,
  );
  late final _clock = _FilmClock(_controller);
  FilmMusic? _music;
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onHide: () => _music?.pause(),
  );
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
    _clock.addListener(_syncMusic);
    _lifecycle;
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

  void _syncMusic() =>
      _music?.sync(_clock.value, running: _controller.isAnimating);

  /// A new film gets new music; switching reduced flashing keeps it.
  void _startMusic(NeonNightTimeline timeline) {
    unawaited(_music?.dispose());
    final player = widget.music?.call(NeonTrack.partsForTimeline(timeline));
    _music = player == null
        ? null
        : (FilmMusic(player, filmLength: timeline.total)..muted = widget.muted);
  }

  void _start({bool restartMusic = true}) {
    final timeline = _timeline = NeonNightCanvas.timelineFor(
      widget.story,
      beat: widget.beat,
    );
    if (restartMusic) _startMusic(timeline);
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
    // Another screen covers the film: its clock stops ticking, so the
    // music has to be stopped here. It picks up again with the clock.
    if (!TickerMode.valuesOf(context).enabled) _music?.pause();
    _layoutTexts();
  }

  @override
  void didUpdateWidget(NeonNightCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    _music?.muted = widget.muted;
    final storyChanged =
        oldWidget.story != widget.story ||
        oldWidget.photo != widget.photo ||
        oldWidget.beat.bpm != widget.beat.bpm;
    if (storyChanged || oldWidget.reducedFlashing != widget.reducedFlashing) {
      final at = _controller.value;
      _start(restartMusic: storyChanged);
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
    _music?.pause();
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
    _lifecycle.dispose();
    _clock.removeListener(_syncMusic);
    unawaited(_music?.dispose());
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
