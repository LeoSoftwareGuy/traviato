import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Generated stand-ins for the fixture wedding's photos (#346 phase 3),
/// for tests only — nothing like this ships in the app. Each is a
/// gradient tile with its label ("HERO 1 · portrait 3:4"), a border and a
/// centre cross, so a golden shows how it was cropped and zoomed.
///
/// The aspects are picked to exercise the layouts: heroes both sides of
/// the 712×800 crop, each chapter layout with matching and mismatched
/// photos, and carousel widths past both clamp ends (0.68, 1.45).
abstract final class GvPlaceholderPhotos {
  static const aspects = <String, double>{
    'hero-1': 3 / 4,
    'hero-2': 3 / 2,
    'hero-3': 1,
    'hero-4': 2 / 3,
    // Layout A: wide, then two tall. The third is square (mismatch).
    'chapter-1-1': 3 / 2,
    'chapter-1-2': 3 / 4,
    'chapter-1-3': 1,
    // Layout B: one very tall, two tall. The second is wide (mismatch).
    'chapter-2-1': 0.6,
    'chapter-2-2': 3 / 2,
    'chapter-2-3': 3 / 4,
    // Layout C: two tall, then wide. The last is a panorama.
    'chapter-3-1': 1,
    'chapter-3-2': 4 / 5,
    'chapter-3-3': 2,
    'carousel-1': 0.5,
    'carousel-2': 3 / 4,
    'carousel-3': 1,
    'carousel-4': 4 / 3,
    'carousel-5': 3 / 2,
    'carousel-6': 2,
    'carousel-7': 2 / 3,
    'carousel-8': 1,
    'carousel-9': 16 / 9,
    'carousel-10': 4 / 5,
    'carousel-11': 5 / 4,
    'carousel-12': 0.6,
  };

  static const _tints = [
    (Color(0xFFD9B58C), Color(0xFF8C6A4A)),
    (Color(0xFFE8C7B8), Color(0xFF9A6B5E)),
    (Color(0xFFBFC9B0), Color(0xFF5E6B4E)),
    (Color(0xFFB8C4D6), Color(0xFF4E5E7A)),
    (Color(0xFFE6D3A3), Color(0xFF8A7440)),
  ];

  /// "HERO 1", "CH 2 · 3", "CAROUSEL 7".
  static String label(String id) {
    final parts = id.split('-');
    return switch (parts.first) {
      'hero' => 'HERO ${parts[1]}',
      'chapter' => 'CH ${parts[1]} · ${parts[2]}',
      'heart' => parts[1],
      _ => 'CAROUSEL ${parts[1]}',
    };
  }

  static String shape(double aspect) {
    final kind = aspect < 0.95
        ? 'portrait'
        : aspect > 1.05
        ? 'landscape'
        : 'square';
    return '$kind ${aspect.toStringAsFixed(2)}';
  }

  /// The heart's photos cycle through these aspects, so its square tiles
  /// crop every shape.
  static const heartAspects = [3 / 4, 3 / 2, 1.0, 2 / 3, 4 / 3];

  /// Every placeholder as PNG bytes, plus `heart-1`…`heart-[hearts]`
  /// (small, numbered). Call inside `tester.runAsync`, with the film's
  /// fonts loaded.
  static Future<Map<String, MemoryImage>> generate({int hearts = 0}) async {
    final out = <String, MemoryImage>{};
    var n = 0;
    for (final MapEntry(key: id, value: aspect) in aspects.entries) {
      out[id] = MemoryImage(
        await _png(id, aspect, _tints[n++ % _tints.length]),
      );
    }
    for (var i = 1; i <= hearts; i++) {
      out['heart-$i'] = MemoryImage(
        await _png(
          'heart-$i',
          heartAspects[i % heartAspects.length],
          _tints[i % _tints.length],
          long: 200,
        ),
      );
    }
    return out;
  }

  static Future<Uint8List> _png(
    String id,
    double aspect,
    (Color, Color) tint, {
    double long = 720,
  }) async {
    final small = long < 400;
    final size = aspect >= 1
        ? Size(long, (long / aspect).roundToDouble())
        : Size((long * aspect).roundToDouble(), long);
    final rect = Offset.zero & size;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight, [
            tint.$1,
            tint.$2,
          ]),
      );
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = const Color(0xCCFFFFFF);
    canvas
      ..drawRect(rect.deflate(3), line)
      ..drawLine(rect.topCenter, rect.bottomCenter, line..strokeWidth = 2)
      ..drawLine(rect.centerLeft, rect.centerRight, line);
    for (final (text, dy, fontSize) in [
      if (small)
        (label(id), 0.0, 64.0)
      else ...[
        (label(id), -34.0, 54.0),
        (shape(aspect), 34.0, 36.0),
      ],
    ]) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'CormorantGaramond',
            fontSize: fontSize,
            color: const Color(0xFFFFFFFF),
            backgroundColor: const Color(0x66000000),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter
        ..paint(
          canvas,
          rect.center + Offset(-painter.width / 2, dy - painter.height / 2),
        )
        ..dispose();
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    return bytes!.buffer.asUint8List();
  }
}
