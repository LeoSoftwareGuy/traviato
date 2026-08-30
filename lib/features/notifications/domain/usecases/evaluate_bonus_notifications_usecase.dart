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
import '../rules/bonus_notification_rules.dart';
import '../rules/notification_mute_rules.dart';

/// Orchestrates the whole bonus-notification decision for "now": which trip
/// (if any) is active, whether it had activity yesterday, whether today's
/// tray is fully done, the mute-streak transition, and the resulting
/// schedule/cancel calls. Run from app lifecycle events (resume/pause) —
/// see guidelines doc 05, this is exactly the "orchestrates multiple
/// repositories" case a use case is for. Reuses [EnsureDailyTrayUseCase]
/// (#64) so today's tray exists even if the user never opened the Bonus
/// screen — the same guarantee Home's badge-dot provider relies on.
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
      var prefs = NotificationMuteRules.updateIgnoreStreak(
        prefs: await _prefsStore.load(),
        today: today,
      );

      final trips = await _require(_tripRepo.getTripCards());
      final currentTrips = trips.where((t) => t.status == TripStatus.current);
      final activeTrip = currentTrips.isEmpty ? null : currentTrips.first;

      if (activeTrip == null) {
        await _require(_notificationRepo.cancelMorning());
        await _require(_notificationRepo.cancelEvening());
        await _prefsStore.save(prefs);
        return const Right(null);
      }

      final activityDates = await _activityDatesForTrip(activeTrip.id);
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayHadActivity = activityDates.contains(yesterday);

      final tray = await _require(
        _ensureDailyTray(
          trip: activeTrip,
          today: today,
          activityDates: activityDates,
        ),
      );
      final taskUndone = !_dailiesDoneToday(
        templates: tray.templates,
        assignments: tray.assignments,
        today: today,
      );

      final morningTarget = BonusNotificationRules.morningFireTime(
        now: now,
        yesterdayHadActivity: yesterdayHadActivity,
        isMuted: prefs.isMuted,
      );
      final eveningTarget = BonusNotificationRules.eveningFireTime(
        now: now,
        taskUndone: taskUndone,
        isMuted: prefs.isMuted,
      );

      if (morningTarget != null) {
        await _require(
          _notificationRepo.scheduleMorning(
            fireAt: morningTarget,
            tripId: activeTrip.id,
          ),
        );
      } else {
        await _require(_notificationRepo.cancelMorning());
      }

      if (eveningTarget != null) {
        await _require(
          _notificationRepo.scheduleEvening(
            fireAt: eveningTarget,
            tripId: activeTrip.id,
          ),
        );
      } else {
        await _require(_notificationRepo.cancelEvening());
      }

      if (morningTarget != null || eveningTarget != null) {
        prefs = prefs.copyWith(lastNotificationScheduledDate: () => today);
      }

      await _prefsStore.save(prefs);
      return const Right(null);
    } on _FailureSignal catch (e) {
      return Left(e.failure);
    }
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
