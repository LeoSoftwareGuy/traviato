import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../marks/balloon_mark.dart';
import '../sky_story/sky_photo_images.dart';
import 'golden_vows_album.dart';
import 'golden_vows_scene_spec.dart';
import 'golden_vows_story.dart';
import 'golden_vows_texts.dart';
import 'golden_vows_tokens.dart';

/// The album (#346, spec §5.3, §5.5): it rises, its cover and pages turn
/// on the spine, and it closes and leaves. Only the top leaf and, while it
/// turns, the one under it are painted.
class GoldenVowsAlbumPainter extends CustomPainter {
  GoldenVowsAlbumPainter({
    required this.album,
    required this.story,
    required this.texts,
    required this.images,
    required this.time,
  }) : super(repaint: Listenable.merge([time, images]));

  final GoldenVowsAlbum album;
  final GoldenVowsStory story;
  final GvAlbumTexts texts;
  final SkyPhotoImages images;
  final ValueListenable<double> time;

  static const _coverBalloon = BalloonMark(style: GoldenVowsColors.balloon);

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    if (!album.visibleAt(t)) return;
    final body = album.bodyAt(t);
    if (body.opacity <= 0.002) return;

    final centre = GoldenVowsAlbum.pageRect.center;
    canvas.save();
    if (body.opacity < 0.999) {
      canvas.saveLayer(
        null,
        Paint()..color = Color.fromRGBO(0, 0, 0, body.opacity),
      );
    }
    canvas
      ..translate(centre.dx, centre.dy + body.dy)
      ..rotate(body.angleDeg * math.pi / 180)
      ..scale(body.scale)
      ..translate(-centre.dx, -centre.dy);

    canvas
      ..drawRect(
        GoldenVowsAlbum.boardRect.shift(const Offset(0, 30)),
        _boardShadow,
      )
      ..drawRect(
        GoldenVowsAlbum.boardRect,
        Paint()..color = GoldenVowsColors.goldLight,
      )
      ..drawRect(
        GoldenVowsAlbum.edgeRect,
        Paint()..color = GoldenVowsColors.paper,
      );

    final top = album.topAt(t);
    final turn = album.turnAt(top, t);
    final turning = turn.angleDeg != 0;
    // The leaf under the top one shows the moment the top one moves; at
    // the close the cover swings back over the heart page.
    final under = t >= album.closeAt ? album.leaves.length - 1 : top + 1;
    if (turning && under < album.leaves.length) {
      _paintLeaf(canvas, under, t);
    }
    if (turn.opacity > 0.002) {
      canvas.save();
      if (turning) {
        canvas.transform(GoldenVowsAlbum.hinge(turn.angleDeg).storage);
      }
      if (turn.opacity < 0.999) {
        canvas.saveLayer(
          GoldenVowsAlbum.pageRect.inflate(40),
          Paint()..color = Color.fromRGBO(0, 0, 0, turn.opacity),
        );
      }
      _paintLeaf(canvas, top, t);
      if (turn.shade > 0.001) {
        canvas.drawRRect(
          _pageRRect,
          Paint()..color = GoldenVowsColors.ink.withValues(alpha: turn.shade),
        );
      }
      if (turn.opacity < 0.999) canvas.restore();
      canvas.restore();
    }

    if (body.opacity < 0.999) canvas.restore();
    canvas.restore();
  }

  static final _pageRRect = RRect.fromRectAndRadius(
    GoldenVowsAlbum.pageRect,
    const Radius.circular(6),
  );

  static final _boardShadow = Paint()
    ..color = const Color(0x40423222)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);

  static final _printShadow = Paint()
    ..color = const Color(0x2E423222)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

  void _paintLeaf(Canvas canvas, int index, double t) {
    final page = album.leaves[index].page;
    if (page == null) {
      _paintCover(canvas);
      return;
    }
    canvas.drawRRect(_pageRRect, Paint()..color = GoldenVowsColors.ivory);
    canvas.drawRect(
      GoldenVowsAlbum.pageRect.deflate(18),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = GoldenVowsColors.gold.withAlpha(170),
    );
    final zoom = album.zoomAt(index, t);
    switch (page.kind) {
      case GvPageKind.hero:
        _paintHero(canvas, page.index, zoom);
      case GvPageKind.chapter:
        _paintChapter(canvas, page.index, zoom);
      case GvPageKind.carousel:
        _paintCarousel(canvas, zoom, album.slideAt(index, t));
      case GvPageKind.heart:
        _paintHeading(canvas, texts.heart);
    }
  }

  void _paintCover(Canvas canvas) {
    canvas
      ..drawRRect(_pageRRect, Paint()..color = GoldenVowsColors.paper)
      ..drawRect(
        GoldenVowsAlbum.pageRect.deflate(30 + 1.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = GoldenVowsColors.gold,
      );
    _coverBalloon.paint(canvas, topLeft: const Offset(440, 814), scale: 1.1);
  }

  // ---- Photo with note -------------------------------------------------

  static const _heroTilts = [-2.0, 1.8, -1.2, 2.2];
  static const _frame = Rect.fromLTWH(150, 300, 780, 960);
  static const _photo = Rect.fromLTWH(34, 34, 712, 800);

  void _paintHero(Canvas canvas, int index, double zoom) {
    final hero = story.heroes[index];
    final words = texts.heroes[index];

    canvas.save();
    _rotateAbout(canvas, _frame.center, _heroTilts[index % 4]);
    canvas.translate(_frame.left, _frame.top);
    final frame = Offset.zero & _frame.size;
    canvas
      ..drawRect(frame.shift(const Offset(0, 12)), _printShadow)
      ..drawRect(frame, Paint()..color = GoldenVowsColors.paper);
    _paintPhoto(canvas, _photo, hero.photoId, zoom);
    canvas.drawRect(
      _photo.inflate(12),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = GoldenVowsColors.gold,
    );
    final caption = words.caption;
    if (caption != null) {
      caption.paint(canvas, Offset((frame.width - caption.width) / 2, 876));
    }
    canvas.restore();

    final note = words.note;
    if (note == null) return;
    final card = Rect.fromLTWH(index.isEven ? 310 : 130, 1300, 640, 190);
    canvas.save();
    _rotateAbout(canvas, card.center, index.isEven ? 3 : -3);
    canvas
      ..drawRect(card.shift(const Offset(0, 10)), _printShadow)
      ..drawRect(card, Paint()..color = GoldenVowsColors.paper);
    note.paint(
      canvas,
      card.center - Offset(note.width / 2, note.height / 2),
    );
    final tape = Rect.fromLTWH(card.left + 290, card.top - 14, 60, 28);
    _rotateAbout(canvas, tape.center, -4);
    canvas.drawRect(
      tape,
      Paint()..color = GoldenVowsColors.goldLight.withValues(alpha: 0.85),
    );
    canvas.restore();
  }

  // ---- Chapter -----------------------------------------------------------

  void _paintChapter(Canvas canvas, int index, double zoom) {
    _paintHeading(canvas, texts.chapters[index]);
    final chapter = story.chapters[index];
    final photos = chapter.photoIds;
    final spots = GvChapterLayouts.forChapter(index, chapter.layout);
    for (var i = 0; i < spots.length; i++) {
      final (x, y, w, h, tilt) = spots[i];
      _paintPrint(
        canvas,
        Rect.fromLTWH(x, y, w, h),
        tilt,
        border: 14,
        photoId: i < photos.length ? photos[i] : null,
        zoom: zoom,
      );
    }
  }

  // ---- Carousel ----------------------------------------------------------

  void _paintCarousel(Canvas canvas, double zoom, double slide) {
    final carousel = texts.carousel;
    if (carousel != null) _paintHeading(canvas, carousel);
    final photos = story.carousel!.photoIds
        .take(GoldenVowsStory.maxCarouselPhotos)
        .toList();
    const window = GvCarouselLayout.window;
    canvas
      ..save()
      ..clipRect(window)
      ..translate(window.left, window.top);
    final rows = GvCarouselLayout.rows(photos);
    var n = 0;
    for (var row = 0; row < rows.length; row++) {
      final widths = [
        for (final id in rows[row]) GvCarouselLayout.printWidth(_aspect(id)),
      ];
      var x = GvCarouselLayout.rowX(
        row,
        GvCarouselLayout.rowWidth(widths),
        slide,
      );
      for (var i = 0; i < widths.length; i++, n++) {
        final rect = Rect.fromLTWH(
          x,
          GvCarouselLayout.rowTops[row],
          widths[i],
          GvCarouselLayout.printHeight,
        );
        x += widths[i] + GvCarouselLayout.gap;
        if (rect.right < -60 || rect.left > window.width + 60) continue;
        _paintPrint(
          canvas,
          rect,
          n.isEven ? -GvCarouselLayout.tiltDeg : GvCarouselLayout.tiltDeg,
          border: GvCarouselLayout.border,
          photoId: rows[row][i],
          zoom: zoom,
        );
      }
    }
    canvas.restore();
  }

  double _aspect(String id) {
    final image = images[id];
    if (image == null || image.height == 0) return 1;
    return image.width / image.height;
  }

  // ---- Shared ------------------------------------------------------------

  static void _paintHeading(Canvas canvas, GvHeadingTexts heading) {
    heading.title.paint(canvas, Offset(540 - heading.title.width / 2, 268));
    final line = heading.line;
    if (line != null) line.paint(canvas, Offset(540 - line.width / 2, 398));
  }

  /// A paper print: [rect] with a [border] mat, tilted [tiltDeg] about its
  /// centre, over a soft shadow.
  void _paintPrint(
    Canvas canvas,
    Rect rect,
    double tiltDeg, {
    required double border,
    required String? photoId,
    required double zoom,
  }) {
    canvas.save();
    _rotateAbout(canvas, rect.center, tiltDeg);
    canvas
      ..drawRect(rect.shift(const Offset(0, 10)), _printShadow)
      ..drawRect(rect, Paint()..color = GoldenVowsColors.paper);
    _paintPhoto(canvas, rect.deflate(border), photoId, zoom);
    canvas.restore();
  }

  /// The photo cover-cropped into [dst], zoomed [zoom] about its centre;
  /// an empty ivory mat until it has loaded (or if it failed).
  void _paintPhoto(Canvas canvas, Rect dst, String? photoId, double zoom) {
    final image = photoId == null ? null : images[photoId];
    if (image == null) {
      canvas.drawRect(dst, Paint()..color = GoldenVowsColors.ivoryDeep);
      return;
    }
    canvas.drawImageRect(
      image,
      gvCoverCrop(
        Size(image.width.toDouble(), image.height.toDouble()),
        dst.size,
        zoom,
      ),
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  static void _rotateAbout(Canvas canvas, Offset centre, double degrees) {
    canvas
      ..translate(centre.dx, centre.dy)
      ..rotate(degrees * math.pi / 180)
      ..translate(-centre.dx, -centre.dy);
  }

  @override
  bool shouldRepaint(GoldenVowsAlbumPainter oldDelegate) =>
      oldDelegate.album != album ||
      oldDelegate.story != story ||
      oldDelegate.texts != texts ||
      oldDelegate.images != images ||
      oldDelegate.time != time;
}
