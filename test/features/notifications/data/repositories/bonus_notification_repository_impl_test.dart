import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/notifications/data/datasources/bonus_notification_local_data_source.dart';
import 'package:traviato/features/notifications/data/repositories/bonus_notification_repository_impl.dart';

class _FakeLocalDataSource implements BonusNotificationLocalDataSource {
  _FakeLocalDataSource({this.exception});

  Exception? exception;
  final scheduledMorning = <DateTime>[];
  var cancelMorningCallCount = 0;

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
  Future<void> scheduleMorning({
    required DateTime fireAt,
    required String tripId,
  }) async {
    if (exception != null) throw exception!;
    scheduledMorning.add(fireAt);
  }

  @override
  Future<void> scheduleEvening({
    required DateTime fireAt,
    required String tripId,
  }) async {
    if (exception != null) throw exception!;
  }

  @override
  Future<void> scheduleArrival({
    required DateTime fireAt,
    required String tripId,
  }) async {
    if (exception != null) throw exception!;
  }

  @override
  Future<void> cancelMorning() async {
    if (exception != null) throw exception!;
    cancelMorningCallCount++;
  }

  @override
  Future<void> cancelEvening() async {
    if (exception != null) throw exception!;
  }

  @override
  Future<void> cancelArrival(String tripId) async {
    if (exception != null) throw exception!;
  }
}

void main() {
  test('scheduleMorning delegates to the local data source', () async {
    final local = _FakeLocalDataSource();
    final repo = BonusNotificationRepositoryImpl(local: local);
    final result = await repo.scheduleMorning(
      fireAt: DateTime(2026, 8, 10, 9),
      tripId: 't1',
    );
    expect(result.isRight(), isTrue);
    expect(local.scheduledMorning, [DateTime(2026, 8, 10, 9)]);
  });

  test('cancelMorning delegates and returns Right', () async {
    final local = _FakeLocalDataSource();
    final repo = BonusNotificationRepositoryImpl(local: local);
    final result = await repo.cancelMorning();
    expect(result.isRight(), isTrue);
    expect(local.cancelMorningCallCount, 1);
  });

  test('maps a plugin failure to UnknownFailure', () async {
    final local = _FakeLocalDataSource(exception: Exception('platform boom'));
    final repo = BonusNotificationRepositoryImpl(local: local);
    final result = await repo.cancelMorning();
    result.fold(
      (failure) => expect(failure, isA<UnknownFailure>()),
      (_) => fail('expected Left'),
    );
  });
}
