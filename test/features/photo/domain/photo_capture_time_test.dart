import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/photo/domain/photo_capture_time.dart';

void main() {
  final now = DateTime(2026, 11, 23, 18);

  test('an EXIF offset: the instant in UTC and its offset (#461)', () {
    final t = PhotoCaptureTime.of(
      exifTakenAt: DateTime.utc(2026, 2, 26, 20, 57, 40),
      exifOffsetMinutes: 60,
      now: now,
    );
    expect(t.takenAt, DateTime.utc(2026, 2, 26, 20, 57, 40));
    expect(t.takenAt!.isUtc, isTrue);
    expect(t.utcOffsetMinutes, 60);
    expect(t.source, 'exif');
  });

  test("just taken, no offset: the device's offset", () {
    final shot = now.subtract(const Duration(minutes: 2));
    final t = PhotoCaptureTime.of(
      exifTakenAt: shot,
      exifOffsetMinutes: null,
      now: now,
    );
    expect(t.takenAt, shot.toUtc());
    expect(t.utcOffsetMinutes, now.timeZoneOffset.inMinutes);
    expect(t.source, 'device');
  });

  test("no EXIF time at all: added now, the device's offset", () {
    final t = PhotoCaptureTime.of(
      exifTakenAt: null,
      exifOffsetMinutes: null,
      now: now,
    );
    expect(t.takenAt, isNull);
    expect(t.utcOffsetMinutes, now.timeZoneOffset.inMinutes);
    expect(t.source, 'device');
  });

  test('an older gallery photo, no offset: left to the film', () {
    final old = DateTime(2026, 2, 26, 21, 57);
    final t = PhotoCaptureTime.of(
      exifTakenAt: old,
      exifOffsetMinutes: null,
      now: now,
    );
    expect(t.takenAt, old);
    expect(t.utcOffsetMinutes, isNull);
    expect(t.source, isNull);
  });
}
