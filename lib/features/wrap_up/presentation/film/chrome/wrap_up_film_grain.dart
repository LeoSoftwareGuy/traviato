import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Subtle film grain drifting over the whole canvas (docs/design/wrap-film-
/// spec.md §6). [generate] builds the 180×180 tiling noise tile **once**,
/// via a seeded LCG (matching `docs/design/wrap-film.jsx`'s generator) — call
/// it during asset prep, before playback starts, and pass the resulting
/// [ui.Image] in here; this widget never regenerates it per-frame, only
/// shifts the paint offset.
class WrapUpFilmGrain extends StatelessWidget {
  const WrapUpFilmGrain({required this.t, required this.image, super.key});

  final double t;
  final ui.Image? image;

  static const double _tileSize = 180;
  static const double _opacity = 0.07;

  static Future<ui.Image> generate() {
    const size = 180;
    final pixels = Uint8List(size * size * 4);
    var seed = 1337;
    for (var i = 0; i < pixels.length; i += 4) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      final v = 96 + ((seed >> 16) & 127);
      pixels[i] = v;
      pixels[i + 1] = v;
      pixels[i + 2] = v;
      pixels[i + 3] = 255;
    }
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      size,
      size,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final grainImage = image;
    if (grainImage == null) return const SizedBox.shrink();
    final dx = (t * 61) % _tileSize;
    final dy = (t * 83) % _tileSize;
    return IgnorePointer(
      child: Opacity(
        opacity: _opacity,
        child: CustomPaint(
          size: Size.infinite,
          painter: _GrainPainter(image: grainImage, dx: dx, dy: dy),
        ),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter({required this.image, required this.dx, required this.dy});

  final ui.Image image;
  final double dx;
  final double dy;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..blendMode = BlendMode.overlay
      ..shader = ImageShader(
        image,
        TileMode.repeated,
        TileMode.repeated,
        Matrix4.translationValues(-dx, -dy, 0).storage,
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _GrainPainter oldDelegate) =>
      oldDelegate.dx != dx ||
      oldDelegate.dy != dy ||
      oldDelegate.image != image;
}
