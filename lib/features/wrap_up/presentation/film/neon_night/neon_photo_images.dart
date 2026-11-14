import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../sky_story/sky_photo_images.dart';
import 'neon_chapter_card.dart';
import 'neon_chapter_card_painter.dart';
import 'neon_night_scene_spec.dart';
import 'neon_night_story.dart';
import 'neon_night_timeline.dart';

/// The film's photos, decoded at two sizes (#363): every contact-sheet
/// tile small; only the laser zooms' picks and the moments' photos, which
/// fill big frames, large. So a 200-photo night stays light.
class NeonPhotoImages implements NeonPhotoSource {
  NeonPhotoImages(
    ImageProvider? Function(String id) photo, {
    required NeonNightStory story,
    required NeonNightTimeline timeline,
  }) : _thumbs = SkyPhotoImages((id) => thumbProvider(photo, id)),
       _large = SkyPhotoImages((id) => largeProvider(photo, id)) {
    final (:thumbs, :large) = idsFor(story, timeline);
    _thumbs.load(thumbs);
    _large.load(large);
  }

  static const thumbWidth = 256;
  static const largeWidth = 960;

  final SkyPhotoImages _thumbs;
  final SkyPhotoImages _large;

  static ImageProvider? thumbProvider(
    ImageProvider? Function(String id) photo,
    String id,
  ) {
    final full = photo(id);
    return full == null ? null : ResizeImage(full, width: thumbWidth);
  }

  static ImageProvider? largeProvider(
    ImageProvider? Function(String id) photo,
    String id,
  ) {
    final full = photo(id);
    return full == null ? null : ResizeImage(full, width: largeWidth);
  }

  /// Which photos the film shows: every sheet tile small; the zoom picks
  /// and the moments' photos large.
  static ({List<String> thumbs, List<String> large}) idsFor(
    NeonNightStory story,
    NeonNightTimeline timeline,
  ) {
    final thumbs = <String>[];
    final large = <String>[];
    for (final scene in timeline.scenes) {
      if (scene.spec case final NnChapterCardSpec spec) {
        final chapter = story.chapters[spec.chapter];
        final sheet = NnContactSheet.forPhotos(chapter.photos.length);
        thumbs.addAll([
          for (var k = 0; k < sheet.tiles.length; k++) chapter.photos[k].id,
        ]);
        final timing = NnCardTiming(
          chapterNumber: spec.chapter + 1,
          beats: spec.beats,
          zooms: spec.zooms,
          tiles: sheet.tiles.length,
          beat: timeline.beat,
        );
        large.addAll([
          for (final k in timing.zoomTiles) chapter.photos[k].id,
          for (final moment in chapter.moments)
            for (final photo in moment.photos) photo.id,
        ]);
      }
    }
    // The Note's background is blurred: the small decode is plenty.
    if (story.note?.photo case final photo?) thumbs.add(photo.id);
    return (thumbs: thumbs.toSet().toList(), large: large.toSet().toList());
  }

  @override
  ui.Image? thumb(String id) => _thumbs[id];

  @override
  ui.Image? large(String id) => _large[id];

  /// Completes once every photo has loaded or failed, or after [cap]: a
  /// photo that never answers paints its empty mat instead of holding the
  /// film forever.
  Future<void> ready({Duration cap = const Duration(seconds: 5)}) =>
      Future.wait([
        _thumbs.ready,
        _large.ready,
      ]).timeout(cap, onTimeout: () => []);

  void addListener(VoidCallback listener) {
    _thumbs.addListener(listener);
    _large.addListener(listener);
  }

  void dispose() {
    _thumbs.dispose();
    _large.dispose();
  }
}
