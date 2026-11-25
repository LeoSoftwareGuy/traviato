/// When and where (as a UTC offset) a photo was taken (#461), for its row.
class PhotoCaptureTime {
  const PhotoCaptureTime({this.takenAt, this.utcOffsetMinutes, this.source});

  /// The photo's time from its EXIF: [exifTakenAt] (a UTC instant when
  /// [exifOffsetMinutes] is set, else the file's wall clock as a local
  /// time) at [now] on the device.
  factory PhotoCaptureTime.of({
    required DateTime? exifTakenAt,
    required int? exifOffsetMinutes,
    required DateTime now,
  }) {
    if (exifTakenAt != null && exifOffsetMinutes != null) {
      return PhotoCaptureTime(
        takenAt: exifTakenAt.toUtc(),
        utcOffsetMinutes: exifOffsetMinutes,
        source: 'exif',
      );
    }
    final fresh =
        exifTakenAt == null || exifTakenAt.difference(now).abs() <= freshWithin;
    if (fresh) {
      return PhotoCaptureTime(
        takenAt: exifTakenAt?.toUtc(),
        utcOffsetMinutes: now.timeZoneOffset.inMinutes,
        source: 'device',
      );
    }
    // An older photo with no offset (#468): its wall clock as read, sent
    // as UTC fields and marked 'wall' — never a naive local time the
    // database would read as UTC. generate_wrap_up resolves the zone (the
    // photo's GPS, else the memory's place) and stores the real instant.
    return PhotoCaptureTime(
      takenAt: DateTime.utc(
        exifTakenAt.year,
        exifTakenAt.month,
        exifTakenAt.day,
        exifTakenAt.hour,
        exifTakenAt.minute,
        exifTakenAt.second,
      ),
      source: wallClockSource,
    );
  }

  /// What `taken_at` gets. A UTC instant whenever the offset is known.
  final DateTime? takenAt;

  /// The offset where it was taken; null = unknown (the film finds it
  /// from the photo's GPS or the memory's place).
  final int? utcOffsetMinutes;

  /// 'exif', 'device' or [wallClockSource] (#468: [takenAt] is the wall
  /// clock, its zone not known yet).
  final String? source;

  /// `utc_offset_source` of a photo whose [takenAt] is its wall clock.
  static const wallClockSource = 'wall';

  /// A photo without an EXIF offset counts as just taken — so the device's
  /// offset is right — when its time is within this of now (a camera shot,
  /// or one picked right after taking it).
  static const freshWithin = Duration(minutes: 10);
}
