import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:traviato/features/notifications/data/datasources/flutter_local_notifications_data_source.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  test('resolves a canonical IANA zone name directly', () {
    final location = resolveTimezoneLocation('Europe/London');
    expect(location.name, 'Europe/London');
  });

  test('falls back to the current name for a known legacy alias', () {
    // "Europe/Kiev" is the pre-2022 IANA name; the bundled tzdata only
    // carries the renamed "Europe/Kyiv" (issue #65 fix).
    final location = resolveTimezoneLocation('Europe/Kiev');
    expect(location.name, 'Europe/Kyiv');
  });

  test('throws for a zone name with no known alias', () {
    expect(
      () => resolveTimezoneLocation('Not/AZone'),
      throwsA(isA<tz.LocationNotFoundException>()),
    );
  });
}
