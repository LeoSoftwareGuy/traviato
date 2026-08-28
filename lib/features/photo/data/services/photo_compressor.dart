import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Long-edge cap for uploaded photos — plenty for the Journal strip and
/// photo-detail full-bleed view, far smaller than a raw camera capture.
const _maxDimension = 2048;
const _quality = 80;

/// Wraps `flutter_image_compress` so the mutation layer doesn't import a
/// platform package directly. Output is always JPEG.
class PhotoCompressor {
  const PhotoCompressor();

  Future<Uint8List> compress(Uint8List bytes) {
    return FlutterImageCompress.compressWithList(
      bytes,
      minWidth: _maxDimension,
      minHeight: _maxDimension,
      quality: _quality,
      format: CompressFormat.jpeg,
    );
  }
}
