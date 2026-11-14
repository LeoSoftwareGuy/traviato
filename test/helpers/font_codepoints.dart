import 'dart:io';
import 'dart:typed_data';

/// The characters a TrueType font maps (its `cmap` table, formats 4 and
/// 12), so a test can prove the film never falls back to a system font.
Set<int> fontCodepoints(String path) {
  final data = ByteData.sublistView(File(path).readAsBytesSync());
  final tables = data.getUint16(4);
  var cmap = -1;
  for (var i = 0; i < tables; i++) {
    final record = 12 + 16 * i;
    final tag = String.fromCharCodes([
      for (var b = 0; b < 4; b++) data.getUint8(record + b),
    ]);
    if (tag == 'cmap') cmap = data.getUint32(record + 8);
  }
  final points = <int>{};
  final subtables = data.getUint16(cmap + 2);
  for (var i = 0; i < subtables; i++) {
    final at = cmap + data.getUint32(cmap + 4 + 8 * i + 4);
    switch (data.getUint16(at)) {
      case 4:
        final segments = data.getUint16(at + 6) ~/ 2;
        for (var s = 0; s < segments; s++) {
          final end = data.getUint16(at + 14 + 2 * s);
          final start = data.getUint16(at + 16 + 2 * segments + 2 * s);
          if (start != 0xFFFF) {
            for (var c = start; c <= end; c++) {
              points.add(c);
            }
          }
        }
      case 12:
        final groups = data.getUint32(at + 12);
        for (var g = 0; g < groups; g++) {
          final start = data.getUint32(at + 16 + 12 * g);
          final end = data.getUint32(at + 20 + 12 * g);
          for (var c = start; c <= end; c++) {
            points.add(c);
          }
        }
    }
  }
  return points;
}

Set<int> missingCodepoints(Set<int> font, Iterable<String> texts) => {
  for (final text in texts)
    for (final rune in text.runes)
      if (rune > 0x20 && !font.contains(rune)) rune,
};
