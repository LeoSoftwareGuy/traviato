import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/utils/place_time.dart';

void main() {
  group('placeTime (#461)', () {
    test('reads the instant on the clock the offset gives', () {
      // Budapest in February (UTC+1), whatever the phone's zone.
      final at = placeTime(DateTime.utc(2026, 2, 26, 20, 57, 40), 60);
      expect((at.hour, at.minute), (21, 57));
      expect(placeTime(DateTime.utc(2026, 2, 26, 23, 30), 330).day, 27);
    });

    test("without an offset, the phone's clock", () {
      final instant = DateTime.utc(2026, 2, 26, 20, 57);
      expect(placeTime(instant, null), instant.toLocal());
    });
  });

  group('zoneOffsetAt (#461)', () {
    test('follows daylight saving time', () {
      expect(zoneOffsetAt('Europe/Budapest', DateTime.utc(2026, 2, 26)), 60);
      expect(zoneOffsetAt('Europe/Budapest', DateTime.utc(2026, 7, 10)), 120);
      // Paris on the night the clocks change (01:00 UTC, 29 March 2026).
      expect(
        zoneOffsetAt('Europe/Paris', DateTime.utc(2026, 3, 29, 0, 59)),
        60,
      );
      expect(zoneOffsetAt('Europe/Paris', DateTime.utc(2026, 3, 29, 1)), 120);
    });

    test('null for no zone or an unknown one', () {
      expect(zoneOffsetAt(null, DateTime.utc(2026)), isNull);
      expect(zoneOffsetAt('Not/AZone', DateTime.utc(2026)), isNull);
    });
  });
}
