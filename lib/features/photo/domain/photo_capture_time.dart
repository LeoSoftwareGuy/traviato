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
    // An older photo with no offset: its wall clock as read, the offset
    // left to the film (the photo's GPS, else the memory's place).
    return PhotoCaptureTime(takenAt: exifTakenAt);
  }

  /// What `taken_at` gets. A UTC instant whenever the offset is known.
  final DateTime? takenAt;

  /// The offset where it was taken; null = unknown (the film finds it
  /// from the photo's GPS or the memory's place).
  final int? utcOffsetMinutes;

  /// 'exif' or 'device'; null with no offset.
  final String? source;

  /// A photo without an EXIF offset counts as just taken — so the device's
  /// offset is right — when its time is within this of now (a camera shot,
  /// or one picked right after taking it).
  static const freshWithin = Duration(minutes: 10);
}
