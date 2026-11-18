import '../../../core/utils/logical_day.dart';
import '../../photo/domain/entities/photo_entity.dart';
import '../../photo/domain/photo_order.dart';
import 'entities/journal_note_entity.dart';

/// Photos this close together, with no note between them, share a row
/// (docs/design/journal-notes/JOURNAL_NOTES_OPTION_B_SPEC.md §4).
const photoRowGap = Duration(minutes: 20);

/// A day's first notes earn ✦1 each; later ones none (#397 — the server's
/// `award_points` enforces it).
const maxStarredNotesPerDay = 3;

/// One row of a day's "One timeline" view (#401).
sealed class TimelineEntry {
  const TimelineEntry();
}

/// Consecutive photos that share a row; the rail shows the first's time.
class TimelinePhotoRow extends TimelineEntry {
  const TimelinePhotoRow(this.photos, {this.isLater = false});

  final List<PhotoEntity> photos;

  /// Taken (or added) after the day's night was over — see [TimelineLater].
  final bool isLater;

  DateTime get time => photoTimeOf(photos.first);
}

class TimelineNoteRow extends TimelineEntry {
  const TimelineNoteRow(this.note, {this.isLater = false});

  final JournalNoteEntity note;

  /// Written after the day was over: on a later date, or the next morning
  /// from 08:00. Shown at the end with its date instead of a time.
  final bool isLater;
}

/// "AFTER MIDNIGHT · FRI 24 OCT": before the first item past midnight.
class TimelineAfterMidnight extends TimelineEntry {
  const TimelineAfterMidnight(this.date);

  final DateTime date;
}

/// Starts the rows added after the day was over.
class TimelineLater extends TimelineEntry {
  const TimelineLater();
}

/// When a photo happened, in local time: taken, else added.
DateTime photoTimeOf(PhotoEntity photo) =>
    (photo.takenAt ?? photo.createdAt).toLocal();

/// Whether [at] (local) is past the night of [day]: a later date, or the
/// next morning from [logicalDayCutoffHour].
bool isAfterDayOver(DateTime at, DateTime day) {
  final next = DateTime(day.year, day.month, day.day + 1);
  final date = DateTime(at.year, at.month, at.day);
  if (date.isAfter(next)) return true;
  return date == next && at.hour >= logicalDayCutoffHour;
}

/// The day's rows, oldest first (spec §2): photos and notes by time — a
/// photo first on a tie — photos grouped while ≤ [photoRowGap] apart with
/// no note between, a divider before the first item after midnight, and
/// anything from after the day was over at the end, after [TimelineLater].
List<TimelineEntry> buildDayTimeline({
  required DateTime day,
  required List<PhotoEntity> photos,
  required List<JournalNoteEntity> notes,
}) {
  final items = <_Item>[];
  for (final p in photos) {
    final at = photoTimeOf(p);
    items.add(_Item(at, photo: p, isLater: isAfterDayOver(at, day)));
  }
  for (final n in notes) {
    final at = n.takenAt.toLocal();
    items.add(_Item(at, note: n, isLater: isAfterDayOver(at, day)));
  }
  items.sort((a, b) {
    if (a.isLater != b.isLater) return a.isLater ? 1 : -1;
    final byTime = a.at.compareTo(b.at);
    if (byTime != 0) return byTime;
    if ((a.photo == null) != (b.photo == null)) return a.photo != null ? -1 : 1;
    if (a.photo != null) return comparePhotosByTime(a.photo!, b.photo!);
    return a.note!.id.compareTo(b.note!.id);
  });

  final rows = <TimelineEntry>[];
  var dividerShown = false;
  var laterShown = false;
  List<PhotoEntity>? group;
  DateTime? groupLast;
  var groupIsLater = false;

  void closeGroup() {
    if (group != null) {
      rows.add(
        TimelinePhotoRow(List.unmodifiable(group!), isLater: groupIsLater),
      );
    }
    group = null;
    groupLast = null;
  }

  for (final item in items) {
    final startsLater = item.isLater && !laterShown;
    final startsNight =
        !item.isLater && !dividerShown && isAfterMidnightOf(item.at, day);
    if (startsLater || startsNight) closeGroup();
    if (startsLater) {
      rows.add(const TimelineLater());
      laterShown = true;
    }
    if (startsNight) {
      rows.add(
        TimelineAfterMidnight(
          DateTime(item.at.year, item.at.month, item.at.day),
        ),
      );
      dividerShown = true;
    }

    final photo = item.photo;
    if (photo != null) {
      final fits =
          group != null &&
          groupIsLater == item.isLater &&
          item.at.difference(groupLast!) <= photoRowGap;
      if (!fits) {
        closeGroup();
        group = [];
        groupIsLater = item.isLater;
      }
      group!.add(photo);
      groupLast = item.at;
    } else {
      closeGroup();
      rows.add(TimelineNoteRow(item.note!, isLater: item.isLater));
    }
  }
  closeGroup();
  return rows;
}

/// The day a note or photo saved now goes on (#397): the logical day from
/// [now] and the trip's latest item, when [selectedDay] is that day or
/// today's calendar date; otherwise — writing on an earlier day's tab —
/// [selectedDay] itself.
DateTime dayForNewItem({
  required DateTime selectedDay,
  required DateTime now,
  DateTime? previousAt,
  DateTime? previousDay,
}) {
  final logical = logicalDayOf(
    now,
    previousAt: previousAt,
    previousDay: previousDay,
  );
  final selected = DateTime(
    selectedDay.year,
    selectedDay.month,
    selectedDay.day,
  );
  final today = DateTime(now.year, now.month, now.day);
  return selected == logical || selected == today ? logical : selected;
}

class _Item {
  _Item(this.at, {this.photo, this.note, required this.isLater});

  final DateTime at;
  final PhotoEntity? photo;
  final JournalNoteEntity? note;
  final bool isLater;
}
