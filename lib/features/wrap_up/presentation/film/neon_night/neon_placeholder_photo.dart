import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'neon_random.dart';
import 'neon_tokens.dart';

/// A stand-in photo for the debug preview and the goldens (#363), like the
/// reference MP4's: a dark tile with two or three soft neon blobs, seeded
/// `rng(i × 977 + 13)`. Never shown for a real memory.
@immutable
class NeonPlaceholderPhoto extends ImageProvider<NeonPlaceholderPhoto> {
  const NeonPlaceholderPhoto(this.index, {this.size = 512});

  /// The photo's place in the night, from 0: picks its blobs.
  final int index;

  /// Width and height, px.
  final int size;

  static const _blobColors = [
    NeonColors.pink,
    NeonColors.cyan,
    NeonColors.green,
    NeonColors.orange,
    NeonColors.violet,
  ];

  /// Every photo id in order → its placeholder.
  static ImageProvider? Function(String id) forIds(Iterable<String> ids) {
    final index = {for (final (i, id) in ids.indexed) id: i};
    return (id) {
      final i = index[id];
      return i == null ? null : NeonPlaceholderPhoto(i);
    };
  }

  /// Paints the placeholder into a [size] square.
  static void paintInto(Canvas canvas, int index, double size) {
    final r = NeonRandom(NeonSeeds.placeholderPhoto(index));
    final rect = Rect.fromLTWH(0, 0, size, size);
    canvas.drawRect(rect, Paint()..color = const Color(0xFF0B0614));
    final blobs = 2 + (r.next() * 2).floor();
    for (var b = 0; b < blobs; b++) {
      final colour = _blobColors[(r.next() * _blobColors.length).floor()];
      final centre = Offset(
        size * (0.2 + 0.6 * r.next()),
        size * (0.2 + 0.6 * r.next()),
      );
      final radius = size * (0.22 + 0.25 * r.next());
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..shader = ui.Gradient.radial(
            centre,
            radius,
            [
              colour.withValues(alpha: 0.85),
              colour.withValues(alpha: 0.35),
              colour.withValues(alpha: 0),
            ],
            const [0, 0.45, 1],
          ),
      );
    }
  }

  @override
  Future<NeonPlaceholderPhoto> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    NeonPlaceholderPhoto key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(_render(key));

  static Future<ImageInfo> _render(NeonPlaceholderPhoto key) async {
    final recorder = ui.PictureRecorder();
    paintInto(Canvas(recorder), key.index, key.size.toDouble());
    final picture = recorder.endRecording();
    final image = await picture.toImage(key.size, key.size);
    picture.dispose();
    return ImageInfo(image: image);
  }

  @override
  bool operator ==(Object other) =>
      other is NeonPlaceholderPhoto &&
      other.index == index &&
      other.size == size;

  @override
  int get hashCode => Object.hash(index, size);
}
