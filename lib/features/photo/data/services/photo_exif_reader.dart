import 'package:exif/exif.dart';

/// EXIF fields relevant to a photo row — `taken_at` plus GPS, when present.
/// GPS is extracted whenever the file carries it; whether it's kept is a
/// permission decision made by the caller (see `photo_mutations.dart`).
class PhotoExif {
  const PhotoExif({this.takenAt, this.lat, this.lng, this.utcOffsetMinutes});

  /// With [utcOffsetMinutes] (#461): the real instant, in UTC. Without it:
  /// the wall-clock time the file holds, as a local [DateTime].
  final DateTime? takenAt;
  final double? lat;
  final double? lng;

  /// The UTC offset where the photo was taken, from EXIF
  /// `OffsetTimeOriginal` (else `OffsetTime`), when the file carries one.
  final int? utcOffsetMinutes;

  bool get hasGps => lat != null && lng != null;
}

/// Wraps the `exif` package. Parsing runs on the raw picked bytes — image
/// compression strips EXIF, so this must run before `PhotoCompressor`.
class PhotoExifReader {
  const PhotoExifReader();

  Future<PhotoExif> read(List<int> bytes) async {
    Map<String, IfdTag> tags;
    try {
      tags = await readExifFromBytes(bytes);
    } catch (_) {
      return const PhotoExif();
    }
    if (tags.isEmpty) return const PhotoExif();

    final offset = readExifOffset(
      tags['EXIF OffsetTimeOriginal']?.printable ??
          tags['EXIF OffsetTime']?.printable,
    );
    final wallClock = _readTakenAt(tags);
    return PhotoExif(
      takenAt: wallClock == null || offset == null
          ? wallClock
          : instantOf(wallClock, offset),
      utcOffsetMinutes: wallClock == null ? null : offset,
      lat: _readCoordinate(
        tags['GPS GPSLatitude'],
        tags['GPS GPSLatitudeRef']?.printable,
      ),
      lng: _readCoordinate(
        tags['GPS GPSLongitude'],
        tags['GPS GPSLongitudeRef']?.printable,
      ),
    );
  }
}

DateTime? _readTakenAt(Map<String, IfdTag> tags) {
  final raw =
      tags['EXIF DateTimeOriginal']?.printable ??
      tags['Image DateTime']?.printable;
  if (raw == null) return null;
  // EXIF format: 'YYYY:MM:DD HH:MM:SS'.
  final match = RegExp(
    r'^(\d{4}):(\d{2}):(\d{2}) (\d{2}):(\d{2}):(\d{2})$',
  ).firstMatch(raw.trim());
  if (match == null) return null;
  return DateTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
    int.parse(match.group(4)!),
    int.parse(match.group(5)!),
    int.parse(match.group(6)!),
  );
}

/// An EXIF offset ('+01:00', '-05:30') in minutes, or null.
int? readExifOffset(String? raw) {
  final match = RegExp(r'^([+-])(\d{2}):(\d{2})$').firstMatch(
    raw?.trim() ?? '',
  );
  if (match == null) return null;
  final minutes = int.parse(match.group(2)!) * 60 + int.parse(match.group(3)!);
  if (minutes > 18 * 60) return null;
  return match.group(1) == '-' ? -minutes : minutes;
}

/// The UTC instant of [wallClock] (its fields as read) at [offsetMinutes].
DateTime instantOf(DateTime wallClock, int offsetMinutes) => DateTime.utc(
  wallClock.year,
  wallClock.month,
  wallClock.day,
  wallClock.hour,
  wallClock.minute,
  wallClock.second,
).subtract(Duration(minutes: offsetMinutes));

/// GPS coordinate tags hold [degrees, minutes, seconds] as `Ratio`s; the
/// matching `*Ref` tag ('S' or 'W') gives the sign.
double? _readCoordinate(IfdTag? tag, String? ref) {
  if (tag == null) return null;
  final parts = tag.values.toList();
  if (parts.length != 3) return null;
  final degrees = _asDouble(parts[0]);
  final minutes = _asDouble(parts[1]);
  final seconds = _asDouble(parts[2]);
  if (degrees == null || minutes == null || seconds == null) return null;

  var decimal = degrees + minutes / 60 + seconds / 3600;
  if (ref == 'S' || ref == 'W') decimal = -decimal;
  return decimal;
}

double? _asDouble(dynamic value) {
  if (value is Ratio) return value.toDouble();
  if (value is num) return value.toDouble();
  return null;
}
