import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/l10n/context_l10n.dart';
import 'guarded_painter.dart';
import 'sky_mosaic.dart';
import 'sky_outro_painter.dart';
import 'sky_pages_painter.dart';
import 'sky_photo_images.dart';
import 'sky_scene_spec.dart';
import 'sky_story.dart';
import 'sky_story_copy.dart';
import 'sky_story_music.dart';
import 'sky_story_texts.dart';
import 'sky_story_timeline.dart';
import 'sky_world.dart';
import 'sky_world_painter.dart';

/// The Sky Story film (#345): one 1080×1920 composition on one looping
/// clock, like `WrapUpFilmCanvas`. The world (sky, clouds, embers, stars,
/// far balloons) underneath; the title, the chapter pages and the big
/// balloon over it. Its words follow the surrounding locale.
class SkyStoryCanvas extends StatefulWidget {
  const SkyStoryCanvas({
    required this.story,
    required this.photo,
    this.music,
    this.muted = false,
    this.onFailure,
    super.key,
  });

  final SkyStory story;

  /// Where each photo's pixels come from, by photo id. Null (or a failed
  /// load) paints a warm placeholder.
  final ImageProvider? Function(String photoId) photo;

  /// Makes the player for the film's music, or null for a silent film
  /// (tests, goldens).
  final SkyMusicPlayer Function()? music;

  /// Silences the music without stopping its clock.
  final bool muted;

  /// Called once, after the frame, if laying out the words or painting
  /// the film throws (#345): the film stops and goes black, and the caller
  /// can play something else instead.
  final void Function(Object error, StackTrace stack)? onFailure;

  @override
  State<SkyStoryCanvas> createState() => _SkyStoryCanvasState();
}

class _SkyStoryCanvasState extends State<SkyStoryCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
  );
  late final _FilmClock _clock = _FilmClock(_controller);
  late SkyWorld _world;
  late SkyPhotoImages _images;
  late SkyOutroLayer _outro;
  SkyStoryMusic? _music;
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onHide: () => _music?.pause(),
  );
  SkyStoryCopy? _copy;
  SkyStoryTexts? _texts;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _clock.addListener(_syncMusic);
    _lifecycle;
    _start();
  }

  void _syncMusic() =>
      _music?.sync(_clock.value, running: _controller.isAnimating);

  /// (Re)starts the film for the widget's story, from the top.
  void _start() {
    final timeline = SkyStoryTimeline.forStory(widget.story);
    _world = SkyWorld(timeline);
    _clock.total = timeline.total;
    _controller
      ..duration = Duration(milliseconds: (timeline.total * 1000).round())
      ..value = 0
      ..repeat();
    _images = SkyPhotoImages(widget.photo)..load(widget.story.photoIds);
    final player = widget.music?.call();
    _music = player == null
        ? null
        : (SkyStoryMusic(player, filmLength: timeline.total)
            ..muted = widget.muted);
    final mosaicIds = widget.story.mosaicPhotoIds
        .take(SkyStory.maxMosaicPhotos)
        .toList();
    _outro = SkyOutroLayer(
      mosaic: SkyMosaic(
        gatherStart: timeline.first<SkyGatherSpec>()!.start,
        photoCount: mosaicIds.length,
      ),
      photoIds: mosaicIds,
      tiles: SkyPhotoImages(_tilePhoto)..load(mosaicIds),
      icon: SkyPhotoImages((_) => const AssetImage(SkyOutroLayer.iconAsset))
        ..load(const [SkyOutroLayer.iconId]),
    );
  }

  /// A mosaic tile's photo, decoded small: tiles are 36 px.
  ImageProvider? _tilePhoto(String id) {
    final full = widget.photo(id);
    return full == null ? null : ResizeImage(full, width: 96);
  }

  void _disposeOutro() {
    _outro
      ..dispose()
      ..tiles.dispose()
      ..icon.dispose();
  }

  @override
  void didUpdateWidget(SkyStoryCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    _music?.muted = widget.muted;
    if (oldWidget.story == widget.story && oldWidget.photo == widget.photo) {
      return;
    }
    _images.dispose();
    _disposeOutro();
    unawaited(_music?.dispose());
    _start();
    _resolveCopy();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Another screen covers the film: its clock stops ticking, so the
    // music has to be stopped here. It picks up again with the clock.
    if (!TickerMode.valuesOf(context).enabled) _music?.pause();
    _resolveCopy();
  }

  void _resolveCopy() {
    if (_failed) return;
    try {
      final copy = SkyStoryCopy.resolve(
        widget.story,
        context.l10n,
        Localizations.localeOf(context).toLanguageTag(),
      );
      if (copy == _copy) return;
      _copy = copy;
      _texts?.dispose();
      _texts = SkyStoryTexts(copy);
    } catch (error, stack) {
      _fail(error, stack);
    }
  }

  /// Stops the film for good after its first failure and tells the caller,
  /// once, after the frame (this can run mid-paint).
  void _fail(Object error, StackTrace stack) {
    if (_failed) return;
    _failed = true;
    debugPrint('Sky Story failed; the film stops: $error\n$stack');
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
    _images.dispose();
    _disposeOutro();
    _lifecycle.dispose();
    _clock.removeListener(_syncMusic);
    unawaited(_music?.dispose());
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
          width: SkyWorld.width,
          height: SkyWorld.height,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: GuardedPainter(
                SkyWorldPainter(world: _world, time: _clock),
                repaint: _clock,
                onError: _fail,
              ),
              foregroundPainter: GuardedPainter(
                SkyPagesPainter(
                  world: _world,
                  story: widget.story,
                  texts: texts,
                  images: _images,
                  outro: _outro,
                  time: _clock,
                ),
                repaint: Listenable.merge([
                  _clock,
                  _images,
                  _outro.tiles,
                  _outro.icon,
                ]),
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
