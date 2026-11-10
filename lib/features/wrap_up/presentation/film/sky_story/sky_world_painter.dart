import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'sky_balloon.dart';
import 'sky_story_tokens.dart';
import 'sky_world.dart';

/// Paints Sky Story's world at one instant (#345), back to front: sky,
/// stars, clouds, embers and the small far balloons. The pages and the big
/// balloon go over it (`SkyPagesPainter`). One painter for the whole
/// layer, so a frame is one paint pass with no widget rebuilds.
class SkyWorldPainter extends CustomPainter {
  SkyWorldPainter({required this.world, required this.time})
    : super(repaint: time);

  final SkyWorld world;

  /// The film clock, in seconds.
  final ValueListenable<double> time;

  static const _rows = 13;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    canvas
      ..save()
      ..scale(size.width / SkyWorld.width, size.height / SkyWorld.height);
    _paintSky(canvas, t);
    _paintStars(canvas, t);
    _paintClouds(canvas, t);
    _paintEmbers(canvas, t);
    _paintSmallBalloons(canvas, t);
    canvas.restore();
  }

  void _paintSky(Canvas canvas, double t) {
    // The sky's stops are linear in altitude, so sampling a row every
    // 160 px reproduces it closely.
    final colors = <Color>[];
    final stops = <double>[];
    for (var i = 0; i < _rows; i++) {
      final f = i / (_rows - 1);
      stops.add(f);
      colors.add(world.skyColor(f * SkyWorld.height, t));
    }
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, SkyWorld.width, SkyWorld.height),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          const Offset(0, SkyWorld.height),
          colors,
          stops,
        ),
    );
  }

  void _paintStars(Canvas canvas, double t) {
    final paint = Paint();
    for (final star in SkyWorld.stars) {
      final y = world.screenYOf(star.altitude, t);
      if (y < -4 || y > SkyWorld.height + 4) continue;
      final twinkle = 0.65 + 0.35 * math.sin(t * 1.7 + star.phase);
      final alpha =
          star.brightness * twinkle * SkyWorld.starVisibility(star.altitude);
      if (alpha <= 0.01) continue;
      paint.color = SkyStoryColors.star.withValues(alpha: alpha);
      canvas.drawCircle(Offset(star.x, y), star.radius, paint);
    }
  }

  void _paintClouds(Canvas canvas, double t) {
    final visibility = world.cloudVisibility(t);
    if (visibility <= 0.01) return;
    final images = _CloudImages.instance;
    final paint = Paint()
      ..color = Color.fromRGBO(255, 255, 255, visibility)
      ..filterQuality = FilterQuality.low;
    for (final cloud in SkyWorld.clouds) {
      final y = world.screenYOf(cloud.altitude, t);
      final h = cloud.width * _CloudImages.aspect;
      if (y + h < 0 || y - h > SkyWorld.height) continue;
      final image = images.variant(cloud.variant);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(cloud.x + cloud.drift * t, y - h / 2, cloud.width, h),
        paint,
      );
    }
  }

  void _paintEmbers(Canvas canvas, double t) {
    final glow = Paint();
    final core = Paint();
    for (final ember in SkyWorld.embers) {
      final y = world.screenYOf(ember.altitude + SkyEmber.rise * t, t);
      if (y < -30 || y > SkyWorld.height + 30) continue;
      final x = ember.x + math.sin(t * 0.6 + ember.phase) * 6;
      final pulse = 0.8 + 0.2 * math.sin(t * 2.1 + ember.phase);
      final center = Offset(x, y);
      glow.shader = ui.Gradient.radial(
        center,
        ember.radius * 3.6,
        [
          SkyStoryColors.ember.withValues(alpha: 0.6 * pulse),
          SkyStoryColors.ember.withValues(alpha: 0.18 * pulse),
          SkyStoryColors.ember.withValues(alpha: 0),
        ],
        const [0, 0.45, 1],
      );
      canvas.drawCircle(center, ember.radius * 3.6, glow);
      core.color = SkyStoryColors.ember.withValues(alpha: pulse);
      canvas.drawCircle(center, ember.radius, core);
    }
  }

  void _paintSmallBalloons(Canvas canvas, double t) {
    for (final balloon in SkyWorld.smallBalloons) {
      final y = world.screenYOf(balloon.altitude + SkySmallBalloon.rise * t, t);
      final h = skyBalloonHeight(balloon.width);
      if (y < -h || y > SkyWorld.height + h) continue;
      paintSkyBalloon(
        canvas,
        center: Offset(balloon.x, y + SkyWorld.bob(t, balloon.phase)),
        width: balloon.width,
      );
    }
  }

  @override
  bool shouldRepaint(SkyWorldPainter oldDelegate) =>
      oldDelegate.world != world || oldDelegate.time != time;
}

/// The clouds' soft shapes, rasterized once: a blur per cloud per frame
/// would be the most expensive thing in the film.
class _CloudImages {
  _CloudImages._();

  static final instance = _CloudImages._();

  /// Height over width of every cloud image.
  static const double aspect = 0.42;
  static const double _imageWidth = 640;

  /// Each variant's blobs in unit space (width 1, height [aspect]):
  /// a long base with two or three puffs on top, as in the reference.
  static const _variants = <List<Rect>>[
    [
      Rect.fromLTWH(0.06, 0.2, 0.88, 0.16),
      Rect.fromLTWH(0.18, 0.1, 0.4, 0.2),
      Rect.fromLTWH(0.44, 0.07, 0.38, 0.23),
    ],
    [
      Rect.fromLTWH(0.04, 0.21, 0.92, 0.15),
      Rect.fromLTWH(0.24, 0.08, 0.5, 0.22),
    ],
    [
      Rect.fromLTWH(0.08, 0.22, 0.84, 0.14),
      Rect.fromLTWH(0.12, 0.13, 0.3, 0.16),
      Rect.fromLTWH(0.34, 0.06, 0.34, 0.22),
      Rect.fromLTWH(0.6, 0.12, 0.3, 0.16),
    ],
  ];

  final List<ui.Image?> _images = List.filled(_variants.length, null);

  ui.Image variant(int index) =>
      _images[index] ??= _render(_variants[index % _variants.length]);

  static ui.Image _render(List<Rect> blobs) {
    const w = _imageWidth;
    const h = _imageWidth * aspect;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = SkyStoryColors.cloud.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    for (final blob in blobs) {
      canvas.drawOval(
        Rect.fromLTWH(
          blob.left * w,
          blob.top * w,
          blob.width * w,
          blob.height * w,
        ),
        paint,
      );
    }
    return recorder.endRecording().toImageSync(w.round(), h.round());
  }
}
