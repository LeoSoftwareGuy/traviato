import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../bonus/domain/entities/bonus_task_assignment_entity.dart';
import '../../../bonus/domain/entities/bonus_task_template_entity.dart';
import '../../../bonus/domain/usecases/ensure_daily_tray_usecase.dart';
import '../../../journal/domain/repositories/day_note_repository.dart';
import '../../../photo/domain/repositories/photo_repository.dart';
import '../../../quest/domain/repositories/quest_repository.dart';
import '../../../trip/domain/entities/trip_card_entity.dart';
import '../../../trip/domain/repositories/trip_repository.dart';
import '../repositories/bonus_notification_repository.dart';
import '../repositories/notification_prefs_store.dart';
import '../rules/memory_reminder_plan.dart';

/// Orchestrates the memory-reminder decision for "now" (#65, reworked in
/// #307): which memory (if any) is underway or ended yesterday, what was
/// logged today, whether today's tray is done, and the resulting
/// [MemoryReminderPlan] — which replaces every pending reminder. Run from
/// app lifecycle events (resume/pause) and memory changes — see guidelines
/// doc 05, this is exactly the "orchestrates multiple repositories" case a
/// use case is for. Reuses [EnsureDailyTrayUseCase] (#64) so today's tray
/// exists even if the user never opened the Bonus screen — the same
/// guarantee Home's badge-dot provider relies on.
class EvaluateBonusNotificationsUseCase {
  EvaluateBonusNotificationsUseCase({
    required TripRepository tripRepository,
    required QuestRepository questRepository,
    required DayNoteRepository dayNoteRepository,
    required PhotoRepository photoRepository,
    required EnsureDailyTrayUseCase ensureDailyTrayUseCase,
    required BonusNotificationRepository notificationRepository,
    required NotificationPrefsStore prefsStore,
  }) : _tripRepo = tripRepository,
       _questRepo = questRepository,
       _noteRepo = dayNoteRepository,
       _photoRepo = photoRepository,
       _ensureDailyTray = ensureDailyTrayUseCase,
       _notificationRepo = notificationRepository,
       _prefsStore = prefsStore;

  final TripRepository _tripRepo;
  final QuestRepository _questRepo;
  final DayNoteRepository _noteRepo;
  final PhotoRepository _photoRepo;
  final EnsureDailyTrayUseCase _ensureDailyTray;
  final BonusNotificationRepository _notificationRepo;
  final NotificationPrefsStore _prefsStore;

  Future<Either<Failure, void>> call({required DateTime now}) async {
    try {
      final today = _dateOnly(now);
      final prefs = await _prefsStore.load();
      if (!prefs.remindersEnabled) {
        await _require(_notificationRepo.replaceReminders(const []));
        return const Right(null);
      }

      final trip = _memoryToPlan(
        await _require(_tripRepo.getTripCards()),
        today,
      );
      if (trip == null) {
        await _require(_notificationRepo.replaceReminders(const []));
        return const Right(null);
      }

      var loggedToday = false;
      var trayDoneToday = false;
      // On the day after the end there's no tray and only the after-end
      // reminder, which doesn't depend on either.
      if (trip.isUnderwayOn(today)) {
        final activityDates = await _activityDatesForTrip(trip.id);
        loggedToday = activityDates.contains(today);
        final tray = await _require(
          _ensureDailyTray(
            trip: trip,
            today: today,
            activityDates: activityDates,
          ),
        );
        trayDoneToday = _dailiesDoneToday(
          templates: tray.templates,
          assignments: tray.assignments,
          today: today,
        );
      }

      final plan = MemoryReminderPlan.build(
        now: now,
        tripId: trip.id,
        tripName: trip.name,
        startDate: trip.startDate!,
        endDate: trip.endDate!,
        isKeptForever: trip.isKeptForever,
        loggedToday: loggedToday,
        trayDoneToday: trayDoneToday,
      );
      await _require(_notificationRepo.replaceReminders(plan));
      return const Right(null);
    } on _FailureSignal catch (e) {
      return Left(e.failure);
    }
  }

  /// The memory underway on the local [today] (the first one, if several
  /// overlap), else one that ended yesterday and isn't kept yet. Uses the
  /// local date rather than [TripCardEntity.status], which the view derives
  /// from the server's UTC date (#219).
  TripCardEntity? _memoryToPlan(List<TripCardEntity> trips, DateTime today) {
    final dated = trips.where((t) => t.startDate != null && t.endDate != null);
    for (final t in dated) {
      if (t.isUnderwayOn(today)) return t;
    }
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    for (final t in dated) {
      if (_sameDate(t.endDate!, yesterday) && !t.isKeptForever) return t;
    }
    return null;
  }

  bool _dailiesDoneToday({
    required List<BonusTaskTemplateEntity> templates,
    required List<BonusTaskAssignmentEntity> assignments,
    required DateTime today,
  }) {
    final templatesById = {for (final t in templates) t.id: t};
    final dailies = assignments.where((a) {
      if (!_sameDate(a.dayDate, today)) return false;
      final kind = templatesById[a.templateId]?.kind;
      return kind != BonusTaskKind.streakSaver && kind != BonusTaskKind.stretch;
    });
    return dailies.isNotEmpty && dailies.every((a) => a.isCompleted);
  }

  Future<Set<DateTime>> _activityDatesForTrip(String tripId) async {
    final quests = await _require(_questRepo.getQuestsForTrip(tripId));
    final notes = await _require(_noteRepo.getNotesForTrip(tripId));
    final photos = await _require(_photoRepo.getPhotosForTrip(tripId));

    return {
      for (final q in quests)
        if (q.completedAt != null) _dateOnly(q.completedAt!),
      for (final n in notes) _dateOnly(n.dayDate),
      for (final p in photos)
        if ((p.dayDate ?? p.takenAt) != null)
          _dateOnly((p.dayDate ?? p.takenAt)!),
    };
  }

  Future<T> _require<T>(Future<Either<Failure, T>> future) async {
    final either = await future;
    return either.fold((f) => throw _FailureSignal(f), (r) => r);
  }
}

class _FailureSignal implements Exception {
  _FailureSignal(this.failure);
  final Failure failure;
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
