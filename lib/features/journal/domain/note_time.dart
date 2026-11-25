import '../../../core/utils/place_time.dart';
import '../../photo/domain/entities/photo_entity.dart';

/// "Edit time" (#468): the offset a note set on [day] is read at — the
/// one most of that day's photos were taken at, else [zone]'s (the
/// memory's) at noon that day, else [fallbackMinutes] (the phone's).
int noteOffsetForDay({
  required DateTime day,
  required List<PhotoEntity> photos,
  required String? zone,
  required int fallbackMinutes,
}) {
  final counts = <int, int>{};
  for (final p in photos) {
    final d = p.dayDate;
    final offset = p.utcOffsetMinutes;
    if (d == null || offset == null) continue;
    if (d.year != day.year || d.month != day.month || d.day != day.day) {
      continue;
    }
    counts[offset] = (counts[offset] ?? 0) + 1;
  }
  if (counts.isNotEmpty) {
    return counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }
  return zoneOffsetAt(zone, DateTime.utc(day.year, day.month, day.day, 12)) ??
      fallbackMinutes;
}

/// The instant of [hour]:[minute] on [day] at [offsetMinutes] (#468).
DateTime noteInstantOn({
  required DateTime day,
  required int hour,
  required int minute,
  required int offsetMinutes,
}) => DateTime.utc(
  day.year,
  day.month,
  day.day,
  hour,
  minute,
).subtract(Duration(minutes: offsetMinutes));
