import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import 'sky_mosaic.dart';
import 'sky_photo_images.dart';
import 'sky_polaroid.dart';
import 'sky_story_texts.dart';
import 'sky_story_tokens.dart';

/// The film's ending (#345, phase 4): the photo tiles swirling up into the
/// balloon mosaic, its burner glow, then `187 moments`, the tagline and
/// the app icon with the brand line.
///
/// Owned by the canvas's state so the locked mosaic, recorded once into a
/// picture, lasts across frames: the hold replays it instead of drawing
/// ~260 clipped photos a frame. The recording is redone if a tile's photo
/// arrives after the lock.
class SkyOutroLayer {
  SkyOutroLayer({
    required this.mosaic,
    required this.photoIds,
    required this.tiles,
    required this.icon,
  });

  final SkyMosaic mosaic;

  /// The story's mosaic photos; a tile's `photo` indexes this.
  final List<String> photoIds;

  /// The tiles' photos (small decodes) and the app icon.
  final SkyPhotoImages tiles;
  final SkyPhotoImages icon;

  static const iconId = 'storyni_icon';
  static const iconAsset = 'assets/images/brand/storyni_icon.png';

  ui.Picture? _locked;
  int _lockedWith = -1;

  void paint(Canvas canvas, double t, SkyOutroTexts texts) {
    final g = mosaic.gatherStart;
    if (t < g + SkyMosaic.firstStart) return;
    _paintGlow(canvas, mosaic.glowAt(t));
    if (t >= mosaic.lockedAt) {
      canvas.drawPicture(_lockedPicture());
    } else {
      for (final tile in mosaic.tiles) {
        final pose = tile.at(t);
        if (pose == null) continue;
        _paintTile(
          canvas,
          tile,
          pose.center,
          angle: pose.angle,
          scale: pose.scale,
          opacity: pose.opacity,
        );
      }
    }
    paintSkyTextFadeRise(
      canvas,
      t,
      g + SkyMosaic.momentsAt,
      texts.moments,
      texts.momentsAt,
    );
    paintSkyTextFadeRise(
      canvas,
      t,
      g + SkyMosaic.taglineAt,
      texts.tagline,
      texts.taglineAt,
    );
    final brand = skyFadeRise(t, g + SkyMosaic.brandAt);
    if (brand > 0) {
      final lift = 40 * (1 - brand);
      _paintIcon(canvas, texts.icon.translate(0, lift), brand);
      paintSkyText(
        canvas,
        texts.brand,
        texts.brandAt.translate(0, lift),
        brand,
      );
    }
  }

  ui.Picture _lockedPicture() {
    final loaded = tiles.loadedCount;
    if (_locked == null || _lockedWith != loaded) {
      _locked?.dispose();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      for (final tile in mosaic.tiles) {
        _paintTile(canvas, tile, tile.home);
      }
      _locked = recorder.endRecording();
      _lockedWith = loaded;
    }
    return _locked!;
  }

  void _paintGlow(Canvas canvas, double strength) {
    if (strength <= 0) return;
    canvas.drawCircle(
      SkyMosaic.glowCenter,
      SkyMosaic.glowRadius,
      Paint()
        ..shader = ui.Gradient.radial(
          SkyMosaic.glowCenter,
          SkyMosaic.glowRadius,
          [
            SkyStoryColors.burnerGlow.withValues(alpha: 0.55 * strength),
            SkyStoryColors.burnerGlow.withValues(alpha: 0.22 * strength),
            SkyStoryColors.burnerGlow.withValues(alpha: 0),
          ],
          const [0, 0.5, 1],
        ),
    );
  }

  void _paintTile(
    Canvas canvas,
    SkyMosaicTile tile,
    Offset center, {
    double angle = 0,
    double scale = 1,
    double opacity = 1,
  }) {
    final half = tile.size / 2;
    final rect = Rect.fromLTRB(-half, -half, half, half);
    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(SkyMosaic.tileRadius),
    );
    canvas
      ..save()
      ..translate(center.dx, center.dy);
    if (angle != 0) canvas.rotate(angle);
    if (scale != 1) canvas.scale(scale);
    canvas.clipRRect(rrect);
    final image = tile.photo < 0 ? null : tiles[photoIds[tile.photo]];
    paintSkyPhoto(canvas, rect, image, opacity: opacity);
    canvas.drawRect(
      rect,
      Paint()
        ..color = switch (tile.tint) {
          SkyTileTint.red => SkyStoryColors.mosaicRed,
          SkyTileTint.cream => SkyStoryColors.mosaicCream,
          SkyTileTint.basket => SkyStoryColors.mosaicBasket,
        }.withValues(alpha: _tintAlpha(tile.tint) * opacity),
    );
    canvas.restore();
  }

  static double _tintAlpha(SkyTileTint tint) => switch (tint) {
    SkyTileTint.red => 0.55,
    SkyTileTint.cream => 0.55,
    SkyTileTint.basket => 0.45,
  };

  void _paintIcon(Canvas canvas, Rect rect, double opacity) {
    final image = icon[iconId];
    if (image == null) return;
    canvas
      ..save()
      ..clipRRect(RRect.fromRectAndRadius(rect, const Radius.circular(22)));
    paintSkyPhoto(canvas, rect, image, opacity: opacity);
    canvas.restore();
  }

  void dispose() {
    _locked?.dispose();
    _locked = null;
  }
}

/// A fade-and-rise's progress at [t] for one that starts at [start]:
/// 0 before, eased to 1 over 0.6 s (spec §6: headlines fade and rise).
double skyFadeRise(double t, double start) => Curves.easeOutCubic.transform(
  ((t - start) / 0.6).clamp(0.0, 1.0),
);

/// [painter] fading in and rising 40 px into [at], from [start].
void paintSkyTextFadeRise(
  Canvas canvas,
  double t,
  double start,
  TextPainter painter,
  Offset at,
) {
  final e = skyFadeRise(t, start);
  if (e <= 0) return;
  paintSkyText(canvas, painter, at.translate(0, 40 * (1 - e)), e);
}

/// [painter] at [at] with [alpha], through a layer only while it fades.
void paintSkyText(Canvas canvas, TextPainter painter, Offset at, double alpha) {
  if (alpha >= 0.999) {
    painter.paint(canvas, at);
    return;
  }
  canvas.saveLayer(
    (at & painter.size).inflate(24),
    Paint()..color = Color.fromRGBO(0, 0, 0, math.max(0, alpha)),
  );
  painter.paint(canvas, at);
  canvas.restore();
}
