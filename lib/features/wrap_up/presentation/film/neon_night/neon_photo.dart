import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Paints [image] cover-cropped into [rrect] (#363): centred, zoomed in by
/// [kenBurns] (≥ 1), with its brightness multiplied by [brightness]. No
/// image yet (it failed, or there is no provider) → a dark empty mat, so a
/// frame never shows a white or half-drawn photo.
void neonPaintPhoto(
  Canvas canvas,
  ui.Image? image,
  RRect rrect, {
  double brightness = 1,
  double kenBurns = 1,
  double alpha = 1,
}) {
  if (alpha <= 0.002) return;
  canvas
    ..save()
    ..clipRRect(rrect);
  final dst = rrect.outerRect;
  if (image == null) {
    canvas.drawRect(dst, Paint()..color = emptyMat.withValues(alpha: alpha));
    canvas.restore();
    return;
  }
  final iw = image.width.toDouble();
  final ih = image.height.toDouble();
  final scale =
      (dst.width / iw > dst.height / ih ? dst.width / iw : dst.height / ih) *
      kenBurns;
  final src = Rect.fromCenter(
    center: Offset(iw / 2, ih / 2),
    width: dst.width / scale,
    height: dst.height / scale,
  );
  final b = brightness;
  canvas
    ..drawImageRect(
      image,
      src,
      dst,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..color = Color.fromRGBO(0, 0, 0, alpha.clamp(0, 1))
        ..colorFilter = b == 1
            ? null
            : ColorFilter.matrix([
                b, 0, 0, 0, 0, //
                0, b, 0, 0, 0,
                0, 0, b, 0, 0,
                0, 0, 0, 1, 0,
              ]),
    )
    ..restore();
}

/// A photo that isn't there (yet): a dark violet mat.
const emptyMat = Color(0xFF140C22);

/// The §3.1 neon frame around [rrect] in [color]: a [border] px tube with
/// two outer glows and an inner one, all growing with the flare [f]
/// (0–1). CSS `box-shadow 0 0 (8+18f)px c, 0 0 (26+44f)px c@60%, inset 0
/// 0 (10+16f)px c@67%`, as Gaussian σ = blur ÷ 2.
void neonPaintFrame(
  Canvas canvas,
  RRect rrect,
  Color color, {
  required double border,
  double f = 0,
  double alpha = 1,
}) {
  if (alpha <= 0.002) return;
  Paint stroke(double opacity, double sigma) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = border
    ..color = color.withValues(alpha: (opacity * alpha).clamp(0, 1))
    ..maskFilter = sigma > 0 ? MaskFilter.blur(BlurStyle.normal, sigma) : null;
  canvas
    ..drawRRect(rrect, stroke(0.6, (26 + 44 * f) / 2))
    ..drawRRect(rrect, stroke(1, (8 + 18 * f) / 2))
    ..save()
    ..clipRRect(rrect)
    ..drawRRect(rrect, stroke(0.67, (10 + 16 * f) / 2))
    ..restore()
    ..drawRRect(rrect, stroke(1, 0));
}
