import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/photo/data/services/photo_exif_reader.dart';

void main() {
  test('reads EXIF offsets in minutes (#461)', () {
    expect(readExifOffset('+01:00'), 60);
    expect(readExifOffset(' -05:30 '), -330);
    expect(readExifOffset('+00:00'), 0);
    expect(readExifOffset('+19:00'), isNull);
    expect(readExifOffset('1:00'), isNull);
    expect(readExifOffset(null), isNull);
  });

  test("a wall clock at an offset is that place's instant", () {
    final wall = DateTime(2026, 2, 26, 21, 57, 40);
    expect(instantOf(wall, 60), DateTime.utc(2026, 2, 26, 20, 57, 40));
    expect(instantOf(wall, -300), DateTime.utc(2026, 2, 27, 2, 57, 40));
  });
}
