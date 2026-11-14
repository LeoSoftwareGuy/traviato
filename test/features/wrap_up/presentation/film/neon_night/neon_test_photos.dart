import 'dart:ui' as ui;

import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_chapter_card_painter.dart';

/// No photo has loaded: every tile paints its empty mat.
class NoPhotos implements NeonPhotoSource {
  const NoPhotos();

  @override
  ui.Image? thumb(String id) => null;

  @override
  ui.Image? large(String id) => null;

  @override
  ui.Image? tile(String id) => null;
}
