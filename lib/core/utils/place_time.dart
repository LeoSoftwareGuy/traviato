// latest_all: alias names too (Asia/Muscat, #468).
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Times on the clock of where something happened (#461), not the phone's
/// current zone: a photo taken in Budapest at 21:57 reads 21:57 in Tallinn.

/// [instant] as the wall-clock time [offsetMinutes] from UTC: a [DateTime]
/// whose fields read that clock (format it, read its hour; compare
/// instants, never these). The phone's clock without an offset.
DateTime placeTime(DateTime instant, int? offsetMinutes) =>
    offsetMinutes == null
    ? instant.toLocal()
    : instant.toUtc().add(Duration(minutes: offsetMinutes));

bool _zonesLoaded = false;

/// [zone]'s (an IANA name) offset at [instant] in minutes, daylight saving
/// time included; null for a null or unknown zone.
int? zoneOffsetAt(String? zone, DateTime instant) {
  if (zone == null || zone.isEmpty) return null;
  if (!_zonesLoaded) {
    tz_data.initializeTimeZones();
    _zonesLoaded = true;
  }
  try {
    final location = tz.getLocation(zone);
    return location.timeZone(instant.millisecondsSinceEpoch).offset.inMinutes;
  } on Object {
    return null;
  }
}
