import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/photo/data/services/photo_exif_reader.dart';

/// A minimal, valid little-endian TIFF/EXIF byte stream carrying:
///  - DateTimeOriginal in the EXIF IFD ('2026:03:05 14:30:00')
///  - GPSLatitude/GPSLatitudeRef + GPSLongitude/GPSLongitudeRef in the GPS
///    IFD (41°54'10" N, 12°29'32" E — central Rome, chosen for a clean
///    round-trip through the DMS→decimal conversion under test).
///
/// Built by hand from the TIFF spec (rather than shipping a binary fixture)
/// so the test file stays self-contained and diff-able.
List<int> _buildExifBytes() {
  final b = BytesBuilder();

  void u16(int v) => b.add([v & 0xFF, (v >> 8) & 0xFF]);
  void u32(int v) => b.add([
    v & 0xFF,
    (v >> 8) & 0xFF,
    (v >> 16) & 0xFF,
    (v >> 24) & 0xFF,
  ]);
  void ascii(String s) => b.add(s.codeUnits);

  // -- TIFF header --
  ascii('II'); // little-endian
  u16(42); // TIFF magic
  u32(8); // offset of IFD0

  // -- IFD0: 2 entries (GPS IFD pointer, EXIF IFD pointer) --
  const ifd0Offset = 8;
  const ifd0EntryCount = 2;
  const ifd0Size = 2 + ifd0EntryCount * 12 + 4;
  final gpsIfdOffset = ifd0Offset + ifd0Size;

  u16(ifd0EntryCount);
  // Tag 0x8825 GPSInfo, type LONG(4), count 1, value = gpsIfdOffset (filled after EXIF IFD size is known)
  // Tag 0x8769 ExifIFD, type LONG(4), count 1, value = exifIfdOffset
  // We need exifIfdOffset before writing, so compute GPS IFD size first.

  const gpsEntryCount = 4; // LatRef, Lat, LngRef, Lng
  const gpsIfdSize = 2 + gpsEntryCount * 12 + 4;
  final exifIfdOffset = gpsIfdOffset + gpsIfdSize;

  u16(0x8825);
  u16(4); // LONG
  u32(1);
  u32(gpsIfdOffset);

  u16(0x8769);
  u16(4); // LONG
  u32(1);
  u32(exifIfdOffset);

  u32(0); // next IFD offset (none)

  // -- GPS IFD --
  // Rational data for lat (3 rationals) + lng (3 rationals) = 6 * 8 bytes,
  // stored right after the EXIF IFD's own data block. Compute EXIF IFD
  // layout first so we know where to place it.
  const exifEntryCount = 1; // DateTimeOriginal
  const exifIfdSize = 2 + exifEntryCount * 12 + 4;
  final dateStringOffset = exifIfdOffset + exifIfdSize;
  const dateString = '2026:03:05 14:30:00\x00'; // 20 bytes incl. NUL
  final gpsRationalsOffset = dateStringOffset + dateString.length;

  u16(gpsEntryCount);
  // GPSLatitudeRef: ASCII, count 2 ('N\0'), fits inline (4 bytes)
  u16(0x0001);
  u16(2); // ASCII
  u32(2);
  b.add([0x4E, 0x00, 0x00, 0x00]); // 'N\0' + pad

  // GPSLatitude: RATIONAL, count 3, offset -> gpsRationalsOffset
  u16(0x0002);
  u16(5); // RATIONAL
  u32(3);
  u32(gpsRationalsOffset);

  // GPSLongitudeRef: ASCII, count 2 ('E\0')
  u16(0x0003);
  u16(2);
  u32(2);
  b.add([0x45, 0x00, 0x00, 0x00]);

  // GPSLongitude: RATIONAL, count 3, offset -> gpsRationalsOffset + 24
  u16(0x0004);
  u16(5);
  u32(3);
  u32(gpsRationalsOffset + 24);

  u32(0); // next IFD offset

  // -- EXIF IFD --
  u16(exifEntryCount);
  // DateTimeOriginal: ASCII, count 20, offset -> dateStringOffset
  u16(0x9003);
  u16(2); // ASCII
  u32(dateString.length);
  u32(dateStringOffset);
  u32(0); // next IFD offset

  // -- date string data --
  ascii(dateString);

  // -- GPS rational data: lat (41,54,10) then lng (12,29,32), den=1 --
  for (final v in [41, 54, 10, 12, 29, 32]) {
    u32(v);
    u32(1);
  }

  return b.toBytes();
}

void main() {
  group('PhotoExifReader.read', () {
    test('extracts DateTimeOriginal and GPS as decimal degrees', () async {
      final result = await const PhotoExifReader().read(_buildExifBytes());

      expect(result.takenAt, DateTime(2026, 3, 5, 14, 30));
      expect(result.hasGps, isTrue);
      expect(result.lat, closeTo(41.9027, 0.0001));
      expect(result.lng, closeTo(12.4922, 0.0001));
    });

    test('returns an empty result for bytes with no EXIF data', () async {
      final result = await const PhotoExifReader().read([1, 2, 3, 4]);

      expect(result.takenAt, isNull);
      expect(result.hasGps, isFalse);
    });
  });
}
