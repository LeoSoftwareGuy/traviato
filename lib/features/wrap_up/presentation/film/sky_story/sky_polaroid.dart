import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'sky_story_tokens.dart';

/// A polaroid's proportions (spec §4): paper, the photo's inset on the
/// sides and top, and the deeper caption strip below.
class SkyPolaroidFrame {
  const SkyPolaroidFrame({
    required this.size,
    required this.side,
    required this.strip,
  });

  /// The hero (≈780×885, 40 px inset, 150 px strip).
  static const hero = SkyPolaroidFrame(
    size: Size(780, 885),
    side: 40,
    strip: 150,
  );

  /// Photos dealt behind the hero on a fan page: hero-sized.
  static const stack = hero;

  /// The taped page's grid photos and the fly-out's circling ones.
  static const small = SkyPolaroidFrame(
    size: Size(420, 470),
    side: 20,
    strip: 70,
  );

  final Size size;
  final double side;
  final double strip;

  Rect get paper => Rect.fromCenter(
    center: Offset.zero,
    width: size.width,
    height: size.height,
  );

  Rect get photo => Rect.fromLTRB(
    paper.left + side,
    paper.top + side,
    paper.right - side,
    paper.bottom - strip,
  );

  /// The caption's centre: high in the strip, as in the reference.
  Offset get captionCenter => Offset(0, photo.bottom + strip * 0.21);
}

/// Paints one polaroid centred on the canvas origin (callers translate,
/// rotate and scale first): a soft shadow, the paper, the photo filling
/// its window ([zoom] ≥ 1 for a slow Ken Burns), and the caption.
void paintSkyPolaroid(
  Canvas canvas,
  SkyPolaroidFrame frame, {
  required ui.Image? image,
  TextPainter? caption,
  double zoom = 1,
  bool shadow = true,
}) {
  final paper = frame.paper;
  if (shadow) {
    canvas.drawRect(
      paper.translate(0, 14),
      Paint()
        ..color = SkyStoryColors.pageShadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
  }
  canvas.drawRect(paper, Paint()..color = SkyStoryColors.polaroidPaper);
  paintSkyPhoto(canvas, frame.photo, image, zoom: zoom);
  if (caption != null) {
    caption.paint(
      canvas,
      frame.captionCenter - Offset(caption.width / 2, caption.height / 2),
    );
  }
}

/// [image] covering [rect] (centre-cropped, then zoomed by [zoom]); a warm
/// gradient while it loads or if it never does.
void paintSkyPhoto(
  Canvas canvas,
  Rect rect,
  ui.Image? image, {
  double zoom = 1,
}) {
  if (image == null) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, const [
          SkyStoryColors.photoPlaceholderTop,
          SkyStoryColors.photoPlaceholderBottom,
        ]),
    );
    return;
  }
  final iw = image.width.toDouble();
  final ih = image.height.toDouble();
  final scale =
      (rect.width / iw > rect.height / ih
          ? rect.width / iw
          : rect.height / ih) *
      zoom;
  final src = Rect.fromCenter(
    center: Offset(iw / 2, ih / 2),
    width: rect.width / scale,
    height: rect.height / scale,
  );
  canvas.drawImageRect(
    image,
    src,
    rect,
    Paint()..filterQuality = FilterQuality.medium,
  );
}
