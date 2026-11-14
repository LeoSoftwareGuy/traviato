import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'neon_ambient.dart';
import 'neon_random.dart';

/// Neon Night's grain tile (#363, NEON_NIGHT_SPEC.md §4 layer 8): a
/// 240 px seamless noise tile at α 0.6, made once from a fixed seed. It
/// stands in for the prototype's SVG fractal noise (baseFrequency 0.9, 2
/// octaves), which is noise at about one pixel: two per-pixel octaves
/// mixed 2:1, so neighbouring pixels differ like the original's. At
/// overlay 0.08 the two can't be told apart.
///
/// The tile is made once per app run; [load] must finish before the
/// film's first frame (export-ready rule 3), and [cached] is it after.
abstract final class NeonGrain {
  static const seed = 240;

  static ui.Image? _cached;
  static Future<ui.Image>? _loading;

  /// The tile, once [load] has finished.
  static ui.Image? get cached => _cached;

  static Future<ui.Image> load() => _loading ??= _make().then((image) {
    _cached = image;
    return image;
  });

  /// The tile's pixels, RGBA: the same bytes on every run.
  static Uint8List pixels() {
    const size = NeonAmbient.grainTile;
    final fine = NeonRandom(seed);
    final finer = NeonRandom(seed + 1);
    final pixels = Uint8List(size * size * 4);
    for (var i = 0; i < pixels.length; i += 4) {
      final v = (fine.next() * 2 + finer.next()) / 3;
      final grey = (v * 255).round();
      pixels[i] = grey;
      pixels[i + 1] = grey;
      pixels[i + 2] = grey;
      pixels[i + 3] = 153; // α 0.6
    }
    return pixels;
  }

  static Future<ui.Image> _make() {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels(),
      NeonAmbient.grainTile,
      NeonAmbient.grainTile,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }
}
