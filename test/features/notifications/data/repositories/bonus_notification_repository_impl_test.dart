import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/notifications/data/datasources/bonus_notification_local_data_source.dart';
import 'package:traviato/features/notifications/data/repositories/bonus_notification_repository_impl.dart';
import 'package:traviato/features/notifications/domain/entities/planned_reminder_entity.dart';

class _FakeLocalDataSource implements BonusNotificationLocalDataSource {
  _FakeLocalDataSource({this.exception});

  Exception? exception;
  final replaced = <List<PlannedReminderEntity>>[];

  @override
  Future<void> init({required void Function(String? payload) onTap}) async {
    if (exception != null) throw exception!;
  }

  @override
  Future<bool> hasPermission() async {
    if (exception != null) throw exception!;
    return true;
  }

  @override
  Future<bool> requestPermission() async {
    if (exception != null) throw exception!;
    return true;
  }

  @override
  Future<void> replaceReminders(List<PlannedReminderEntity> reminders) async {
    if (exception != null) throw exception!;
    replaced.add(reminders);
  }

  @override
  Future<void> scheduleArrival({
    required DateTime fireAt,
    required String tripId,
  }) async {
    if (exception != null) throw exception!;
  }

  @override
  Future<void> cancelArrival(String tripId) async {
    if (exception != null) throw exception!;
  }
}

void main() {
  final reminder = PlannedReminderEntity(
    kind: ReminderKind.dayMorning,
    fireAt: DateTime(2026, 8, 10, 9),
    tripId: 't1',
    tripName: 'Lisbon',
    dayNumber: 3,
  );

  test('replaceReminders delegates to the local data source', () async {
    final local = _FakeLocalDataSource();
    final repo = BonusNotificationRepositoryImpl(local: local);
    final result = await repo.replaceReminders([reminder]);
    expect(result.isRight(), isTrue);
    expect(local.replaced, [
      [reminder],
    ]);
  });

  test('maps a plugin failure to UnknownFailure', () async {
    final local = _FakeLocalDataSource(exception: Exception('platform boom'));
    final repo = BonusNotificationRepositoryImpl(local: local);
    final result = await repo.replaceReminders(const []);
    result.fold(
      (failure) => expect(failure, isA<UnknownFailure>()),
      (_) => fail('expected Left'),
    );
  });
}
