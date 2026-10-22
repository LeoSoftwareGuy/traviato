import '../../bonus/domain/entities/bonus_task_assignment_entity.dart';
import '../../bonus/domain/entities/bonus_task_template_entity.dart';
import '../../journal/domain/entities/day_note_entity.dart';
import '../../photo/domain/entities/photo_entity.dart';
import '../../quest/domain/entities/quest_entity.dart';
import '../../trip/domain/entities/trip_card_entity.dart';
import 'entities/kept_memory.dart';
import 'entities/kept_memory_day.dart';
import 'entities/kept_memory_photo.dart';
import 'entities/kept_memory_plan_item.dart';

/// Groups a kept memory's photos and notes into day chapters (#279,
/// KEPT_MEMORY_PAGE_SPEC.md § Phase 2).
///
/// A photo's day is its `day_date` (what the Journal filed it under), or —
/// without one — the local date it was taken (or added). Anything before
/// day 1 goes into day 1, anything after the last day into the last day.
/// Within a day, photos run in time order.
KeptMemory buildKeptMemory({
  required TripCardEntity trip,
  required List<PhotoEntity> photos,
  required List<DayNoteEntity> notes,
  required List<QuestEntity> quests,
  List<BonusTaskAssignmentEntity> bonusAssignments = const [],
  List<BonusTaskTemplateEntity> bonusTemplates = const [],
}) {
  final start = _dateOnly(trip.startDate ?? _earliest(photos, notes));
  final lastDay = trip.durationDays ?? _spanDays(start, photos, notes);

  int dayIndexOf(DateTime date) {
    final index = _dateOnly(date).difference(start).inDays + 1;
    return index.clamp(1, lastDay);
  }

  final templatesById = {for (final t in bonusTemplates) t.id: t};
  final bonusByPhotoId = <String, BonusTaskTemplateEntity>{
    for (final a in bonusAssignments)
      if (a.isCompleted &&
          a.photoId != null &&
          templatesById[a.templateId] != null)
        a.photoId!: templatesById[a.templateId]!,
  };

  final photosByDay = <int, List<KeptMemoryPhoto>>{};
  for (final photo in photos) {
    final dayIndex = dayIndexOf(
      photo.dayDate ?? (photo.takenAt ?? photo.createdAt).toLocal(),
    );
    (photosByDay[dayIndex] ??= []).add(
      KeptMemoryPhoto(
        photo: photo,
        dayIndex: dayIndex,
        bonusTask: bonusByPhotoId[photo.id],
      ),
    );
  }

  final notesByDay = <int, List<DayNoteEntity>>{};
  for (final note in notes) {
    (notesByDay[dayIndexOf(note.dayDate)] ??= []).add(note);
  }

  final dayIndexes = {...photosByDay.keys, ...notesByDay.keys}.toList()..sort();
  final days = <KeptMemoryDay>[];
  final allPhotos = <KeptMemoryPhoto>[];
  for (final dayIndex in dayIndexes) {
    final dayPhotos = (photosByDay[dayIndex] ?? [])..sort(_byTime);
    final dayNotes = (notesByDay[dayIndex] ?? [])
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    days.add(
      KeptMemoryDay(
        dayIndex: dayIndex,
        date: start.add(Duration(days: dayIndex - 1)),
        photos: List.unmodifiable(dayPhotos),
        notes: List.unmodifiable(dayNotes),
        firstPhotoIndex: allPhotos.length,
      ),
    );
    allPhotos.addAll(dayPhotos);
  }

  final plan = [
    for (final quest in quests)
      KeptMemoryPlanItem(quest: quest, dayIndex: dayIndexOf(quest.dayDate)),
  ]..sort(_planOrder);

  return KeptMemory(
    trip: trip,
    days: List.unmodifiable(days),
    photos: List.unmodifiable(allPhotos),
    plan: List.unmodifiable(plan),
  );
}

int _byTime(KeptMemoryPhoto a, KeptMemoryPhoto b) {
  final byTime = a.sortTime.compareTo(b.sortTime);
  return byTime != 0 ? byTime : a.photo.id.compareTo(b.photo.id);
}

int _planOrder(KeptMemoryPlanItem a, KeptMemoryPlanItem b) {
  final byDay = a.dayIndex.compareTo(b.dayIndex);
  return byDay != 0 ? byDay : a.quest.position.compareTo(b.quest.position);
}

/// The calendar date as UTC midnight, so day differences stay whole across
/// a DST change (a local-midnight span over one is 23 or 25 hours).
DateTime _dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

// Undated trips are unreachable since #270; these only keep the grouping
// total if one ever shows up.
DateTime _earliest(List<PhotoEntity> photos, List<DayNoteEntity> notes) {
  final dates = [
    for (final p in photos) p.dayDate ?? (p.takenAt ?? p.createdAt).toLocal(),
    for (final n in notes) n.dayDate,
  ];
  if (dates.isEmpty) return DateTime.now();
  return dates.reduce((a, b) => a.isBefore(b) ? a : b);
}

int _spanDays(
  DateTime start,
  List<PhotoEntity> photos,
  List<DayNoteEntity> notes,
) {
  var last = 1;
  for (final date in [
    for (final p in photos) p.dayDate ?? (p.takenAt ?? p.createdAt).toLocal(),
    for (final n in notes) n.dayDate,
  ]) {
    final index = _dateOnly(date).difference(start).inDays + 1;
    if (index > last) last = index;
  }
  return last;
}
