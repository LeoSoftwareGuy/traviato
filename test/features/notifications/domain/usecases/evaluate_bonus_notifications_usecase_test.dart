import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/features/bonus/domain/entities/bonus_task_assignment_entity.dart';
import 'package:traviato/features/bonus/domain/entities/bonus_task_template_entity.dart';
import 'package:traviato/features/bonus/domain/usecases/ensure_daily_tray_usecase.dart';
import 'package:traviato/features/notifications/domain/entities/notification_prefs_entity.dart';
import 'package:traviato/features/notifications/domain/usecases/evaluate_bonus_notifications_usecase.dart';
import 'package:traviato/features/trip/domain/entities/trip_card_entity.dart';

import '../../../bonus/fakes/fake_bonus_task_repository.dart';
import '../../../journal/fakes/fake_day_note_repository.dart';
import '../../../photo/fakes/fake_photo_repository.dart';
import '../../../quest/fakes/fake_quest_repository.dart';
import '../../../trip/fakes/fake_trip_repository.dart';
import '../../fakes/fake_bonus_notification_repository.dart';
import '../../fakes/fake_notification_prefs_store.dart';

List<BonusTaskTemplateEntity> _templates() => const [
  BonusTaskTemplateEntity(
    id: 1,
    code: 'r1',
    title: 'Regular one',
    points: 1,
    phase: BonusTaskPhase.anytime,
    kind: BonusTaskKind.regular,
  ),
  BonusTaskTemplateEntity(
    id: 2,
    code: 'r2',
    title: 'Regular two',
    points: 1,
    phase: BonusTaskPhase.anytime,
    kind: BonusTaskKind.regular,
  ),
];

void main() {
  final tripStart = DateTime(2026, 8, 1);
  final tripEnd = DateTime(2026, 8, 15);
  final today = DateTime(2026, 8, 10, 12); // noon — inside every window
  final yesterday = DateTime(2026, 8, 9);

  ({
    FakeTripRepository trips,
    FakeQuestRepository quests,
    FakeDayNoteRepository notes,
    FakePhotoRepository photos,
    FakeBonusTaskRepository bonus,
    FakeBonusNotificationRepository notifications,
    FakeNotificationPrefsStore prefsStore,
    EvaluateBonusNotificationsUseCase useCase,
  })
  makeHarness() {
    final trips = FakeTripRepository();
    final quests = FakeQuestRepository();
    final notes = FakeDayNoteRepository();
    final photos = FakePhotoRepository();
    final bonus = FakeBonusTaskRepository()..templates = _templates();
    final notifications = FakeBonusNotificationRepository();
    final prefsStore = FakeNotificationPrefsStore();
    final useCase = EvaluateBonusNotificationsUseCase(
      tripRepository: trips,
      questRepository: quests,
      dayNoteRepository: notes,
      photoRepository: photos,
      ensureDailyTrayUseCase: EnsureDailyTrayUseCase(repository: bonus),
      notificationRepository: notifications,
      prefsStore: prefsStore,
    );
    return (
      trips: trips,
      quests: quests,
      notes: notes,
      photos: photos,
      bonus: bonus,
      notifications: notifications,
      prefsStore: prefsStore,
      useCase: useCase,
    );
  }

  test(
    'no active trip cancels morning and evening, schedules nothing',
    () async {
      final h = makeHarness();
      h.trips.tripsResult = const Right([]);

      final result = await h.useCase(now: today);

      expect(result.isRight(), isTrue);
      expect(h.notifications.cancelMorningCallCount, 1);
      expect(h.notifications.cancelEveningCallCount, 1);
      expect(h.notifications.scheduledMorning, isEmpty);
      expect(h.notifications.scheduledEvening, isEmpty);
    },
  );

  test(
    'active trip with activity yesterday and an undone tray schedules both',
    () async {
      final h = makeHarness();
      h.trips.tripsResult = Right([
        buildTripCard(
          id: 't1',
          startDate: tripStart,
          endDate: tripEnd,
          status: TripStatus.current,
        ),
      ]);
      h.notes.notesForTripResult = Right([
        buildDayNoteEntity(tripId: 't1', dayDate: yesterday),
      ]);

      // Before 9am so the morning target hasn't already passed.
      final morningNow = DateTime(2026, 8, 10, 7, 30);
      final result = await h.useCase(now: morningNow);

      expect(result.isRight(), isTrue);
      expect(h.notifications.scheduledMorning, [DateTime(2026, 8, 10, 9)]);
      expect(h.notifications.scheduledEvening, [DateTime(2026, 8, 10, 19)]);
      expect(
        h.prefsStore.stored.lastNotificationScheduledDate,
        DateTime(2026, 8, 10),
      );
    },
  );

  test('no activity yesterday skips the morning nudge only', () async {
    final h = makeHarness();
    h.trips.tripsResult = Right([
      buildTripCard(
        id: 't1',
        startDate: tripStart,
        endDate: tripEnd,
        status: TripStatus.current,
      ),
    ]);

    final result = await h.useCase(now: today);

    expect(result.isRight(), isTrue);
    expect(h.notifications.scheduledMorning, isEmpty);
    expect(h.notifications.cancelMorningCallCount, 1);
    expect(h.notifications.scheduledEvening, [DateTime(2026, 8, 10, 19)]);
  });

  test('a fully completed tray cancels the evening nudge', () async {
    final h = makeHarness();
    h.trips.tripsResult = Right([
      buildTripCard(
        id: 't1',
        startDate: tripStart,
        endDate: tripEnd,
        status: TripStatus.current,
      ),
    ]);
    h.bonus.assignments = [
      BonusTaskAssignmentEntity(
        id: 'a1',
        tripId: 't1',
        templateId: 1,
        dayDate: today,
        completedAt: today,
        createdAt: today,
      ),
      BonusTaskAssignmentEntity(
        id: 'a2',
        tripId: 't1',
        templateId: 2,
        dayDate: today,
        completedAt: today,
        createdAt: today,
      ),
    ];

    final result = await h.useCase(now: today);

    expect(result.isRight(), isTrue);
    expect(h.notifications.scheduledEvening, isEmpty);
    expect(h.notifications.cancelEveningCallCount, 1);
  });

  test('muted cancels both regardless of activity/completion', () async {
    final h = makeHarness();
    h.prefsStore.stored = const NotificationPrefsEntity(isMuted: true);
    h.trips.tripsResult = Right([
      buildTripCard(
        id: 't1',
        startDate: tripStart,
        endDate: tripEnd,
        status: TripStatus.current,
      ),
    ]);
    h.notes.notesForTripResult = Right([
      buildDayNoteEntity(tripId: 't1', dayDate: yesterday),
    ]);

    final result = await h.useCase(now: today);

    expect(result.isRight(), isTrue);
    expect(h.notifications.scheduledMorning, isEmpty);
    expect(h.notifications.scheduledEvening, isEmpty);
    expect(h.notifications.cancelMorningCallCount, 1);
    expect(h.notifications.cancelEveningCallCount, 1);
    expect(h.prefsStore.stored.isMuted, isTrue);
  });
}
