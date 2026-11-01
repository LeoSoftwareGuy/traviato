import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/features/bonus/domain/entities/bonus_task_assignment_entity.dart';
import 'package:traviato/features/bonus/domain/entities/bonus_task_template_entity.dart';
import 'package:traviato/features/bonus/domain/usecases/ensure_daily_tray_usecase.dart';
import 'package:traviato/features/notifications/domain/entities/notification_prefs_entity.dart';
import 'package:traviato/features/notifications/domain/entities/planned_reminder_entity.dart';
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

  List<(ReminderKind, DateTime)> pending(
    FakeBonusNotificationRepository notifications,
  ) => [
    for (final r in notifications.replacedReminders.last) (r.kind, r.fireAt),
  ];

  TripCardEntity underway({DateTime? wrapUpPublishedAt}) => buildTripCard(
    id: 't1',
    name: 'Lisbon',
    startDate: tripStart,
    endDate: tripEnd,
    status: TripStatus.current,
    wrapUpPublishedAt: wrapUpPublishedAt,
  );

  test('no memory underway clears every pending reminder', () async {
    final h = makeHarness();
    h.trips.tripsResult = const Right([]);

    final result = await h.useCase(now: today);

    expect(result.isRight(), isTrue);
    expect(h.notifications.replacedReminders, [isEmpty]);
  });

  test('reminders switched off clear everything (#307)', () async {
    final h = makeHarness();
    h.prefsStore.stored = const NotificationPrefsEntity(
      remindersEnabled: false,
    );
    h.trips.tripsResult = Right([underway()]);

    final result = await h.useCase(now: today);

    expect(result.isRight(), isTrue);
    expect(h.notifications.replacedReminders, [isEmpty]);
  });

  test('an underway memory is planned ahead, not just for today', () async {
    final h = makeHarness();
    h.trips.tripsResult = Right([underway()]);

    final result = await h.useCase(now: today);

    expect(result.isRight(), isTrue);
    final slots = pending(h.notifications);
    expect(slots.first, (
      ReminderKind.eveningNothingLogged,
      DateTime(2026, 8, 10, 19),
    ));
    expect(
      slots,
      contains((ReminderKind.dayMorning, DateTime(2026, 8, 11, 9))),
    );
    expect(
      slots,
      contains((ReminderKind.lastDayEvening, DateTime(2026, 8, 15, 18))),
    );
    expect(slots.last, (ReminderKind.afterEnd, DateTime(2026, 8, 16, 10)));
    expect(h.notifications.replacedReminders.last.first.tripName, 'Lisbon');
  });

  test('something logged today with a task open asks for a dare', () async {
    final h = makeHarness();
    h.trips.tripsResult = Right([underway()]);
    h.notes.notesForTripResult = Right([
      buildDayNoteEntity(tripId: 't1', dayDate: DateTime(2026, 8, 10)),
    ]);

    await h.useCase(now: today);

    expect(pending(h.notifications).first, (
      ReminderKind.eveningDareOpen,
      DateTime(2026, 8, 10, 19),
    ));
  });

  test('a logged day with the tray done has no evening reminder', () async {
    final h = makeHarness();
    h.trips.tripsResult = Right([underway()]);
    h.notes.notesForTripResult = Right([
      buildDayNoteEntity(tripId: 't1', dayDate: DateTime(2026, 8, 10)),
    ]);
    h.bonus.assignments = [
      for (final (id, templateId) in [('a1', 1), ('a2', 2)])
        BonusTaskAssignmentEntity(
          id: id,
          tripId: 't1',
          templateId: templateId,
          dayDate: today,
          completedAt: today,
          createdAt: today,
        ),
    ];

    await h.useCase(now: today);

    expect(pending(h.notifications).first.$2, DateTime(2026, 8, 11, 9));
  });

  test(
    'a memory that ended yesterday gets the keep-forever reminder',
    () async {
      final h = makeHarness();
      h.trips.tripsResult = Right([underway()]);

      await h.useCase(now: DateTime(2026, 8, 16, 8));

      expect(pending(h.notifications), [
        (ReminderKind.afterEnd, DateTime(2026, 8, 16, 10)),
      ]);
    },
  );

  test('a kept memory that ended yesterday gets nothing', () async {
    final h = makeHarness();
    h.trips.tripsResult = Right([
      underway(wrapUpPublishedAt: DateTime(2026, 8, 15, 20)),
    ]);

    await h.useCase(now: DateTime(2026, 8, 16, 8));

    expect(h.notifications.replacedReminders, [isEmpty]);
  });

  test('uses the local date, not the server-derived status', () async {
    final h = makeHarness();
    // The view's UTC date can still say "upcoming" on a local first day.
    h.trips.tripsResult = Right([
      buildTripCard(
        id: 't1',
        startDate: DateTime(2026, 8, 10),
        endDate: tripEnd,
        status: TripStatus.upcoming,
      ),
    ]);

    await h.useCase(now: today);

    expect(h.notifications.replacedReminders.last, isNotEmpty);
  });
}
