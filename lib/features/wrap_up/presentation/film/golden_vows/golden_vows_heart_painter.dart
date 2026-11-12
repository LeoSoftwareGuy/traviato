import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../sky_story/sky_photo_images.dart';
import 'golden_vows_album.dart';
import 'golden_vows_heart.dart';
import 'golden_vows_texts.dart';
import 'golden_vows_tokens.dart';

/// The heart layer (#346, spec §5.4), over the album: the photo tiles
/// flying into a heart, its beat, the confetti, the ropes and basket, the
/// line under it, and the whole balloon lifting away.
class GoldenVowsHeartPainter extends CustomPainter {
  GoldenVowsHeartPainter({
    required this.heart,
    required this.photoIds,
    required this.images,
    required this.texts,
    required this.time,
  }) : super(repaint: Listenable.merge([time, images]));

  final GoldenVowsHeart heart;

  /// The heart's photos, in tile order (tile i shows photo i % N).
  final List<String> photoIds;

  /// The heart's photos, decoded small.
  final SkyPhotoImages images;
  final GvAlbumTexts texts;
  final ValueListenable<double> time;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    if (!heart.visibleAt(t)) return;

    _paintLine(canvas, t);

    // The balloon: tiles, ropes and basket beat and rise together.
    const centre = GoldenVowsHeart.centre;
    final rise = heart.riseAt(t);
    final beat = heart.beatScaleAt(t);
    canvas
      ..save()
      ..translate(centre.dx, centre.dy + rise.dy)
      ..rotate(rise.angleDeg * math.pi / 180)
      ..scale(beat)
      ..translate(-centre.dx, -centre.dy);
    _paintRopesAndBasket(canvas, t);
    for (var i = 0; i < heart.tiles.length; i++) {
      _paintTile(canvas, i, t);
    }
    canvas.restore();

    for (var i = 0; i < heart.confetti.length; i++) {
      _paintConfetti(canvas, i, t);
    }
  }

  void _paintTile(Canvas canvas, int i, double t) {
    final at = heart.tileAt(i, t);
    final s = heart.tileSize;
    // Far off canvas until it flies in.
    if (at.centre.dx < -s ||
        at.centre.dx > 1080 + s ||
        at.centre.dy < -s - 2200 ||
        at.centre.dy > 1920 + s) {
      return;
    }
    final turned = at.angleDeg.abs() > 0.01;
    if (turned) {
      canvas
        ..save()
        ..translate(at.centre.dx, at.centre.dy)
        ..rotate(at.angleDeg * math.pi / 180)
        ..translate(-at.centre.dx, -at.centre.dy);
    }
    final rect = Rect.fromCenter(center: at.centre, width: s, height: s);
    canvas
      ..drawRect(rect.shift(const Offset(1.5, 3)), _tileShadow)
      ..drawRect(rect, _paper);
    final inner = rect.deflate(heart.border);
    final image = images[photoIds[heart.tiles[i].photo]];
    if (image == null) {
      canvas.drawRect(inner, _empty);
    } else {
      canvas.drawImageRect(
        image,
        gvCoverCrop(
          Size(image.width.toDouble(), image.height.toDouble()),
          inner.size,
        ),
        inner,
        _photo,
      );
    }
    if (turned) canvas.restore();
  }

  void _paintRopesAndBasket(Canvas canvas, double t) {
    for (var i = 0; i < GoldenVowsHeart.ropes.length; i++) {
      final drawn = heart.ropeAt(i, t);
      if (drawn <= 0) continue;
      final (from, to) = GoldenVowsHeart.ropes[i];
      canvas.drawLine(from, Offset.lerp(from, to, drawn)!, _rope);
    }
    final basket = heart.basketAt(t);
    if (basket.opacity <= 0) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        GoldenVowsHeart.basket.shift(Offset(0, basket.dy)),
        const Radius.circular(8),
      ),
      Paint()
        ..color = GoldenVowsColors.goldDeep.withValues(alpha: basket.opacity),
    );
  }

  void _paintLine(Canvas canvas, double t) {
    final line = heart.lineAt(t);
    if (line.opacity <= 0.002) return;
    final painter = texts.endLine;
    final offset = Offset(540 - painter.width / 2, line.top);
    if (line.opacity >= 0.999) {
      painter.paint(canvas, offset);
      return;
    }
    canvas.saveLayer(
      (offset & painter.size).inflate(2),
      Paint()..color = Color.fromRGBO(0, 0, 0, line.opacity),
    );
    painter.paint(canvas, offset);
    canvas.restore();
  }

  void _paintConfetti(Canvas canvas, int i, double t) {
    final at = heart.confettiAt(i, t);
    if (at.opacity <= 0.002) return;
    final piece = heart.confetti[i];
    final paint = Paint()
      ..color = piece.color.withValues(alpha: piece.color.a * at.opacity);
    if (piece.round) {
      canvas.drawCircle(at.centre, piece.width / 2, paint);
      return;
    }
    canvas
      ..save()
      ..translate(at.centre.dx, at.centre.dy)
      ..rotate(at.angleDeg * math.pi / 180)
      ..drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: piece.width,
          height: piece.height,
        ),
        paint,
      )
      ..restore();
  }

  static final _paper = Paint()..color = GoldenVowsColors.paper;
  static final _empty = Paint()..color = GoldenVowsColors.ivoryDeep;
  static final _photo = Paint()..filterQuality = FilterQuality.medium;
  static final _tileShadow = Paint()..color = const Color(0x22423222);
  static final _rope = Paint()
    ..color = GoldenVowsColors.goldDeep
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;

  @override
  bool shouldRepaint(GoldenVowsHeartPainter oldDelegate) =>
      oldDelegate.heart != heart ||
      oldDelegate.photoIds != photoIds ||
      oldDelegate.images != images ||
      oldDelegate.texts != texts ||
      oldDelegate.time != time;
}
