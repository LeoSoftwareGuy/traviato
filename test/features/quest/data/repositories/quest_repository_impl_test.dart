import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/errors/exceptions.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/quest/data/datasources/quest_remote_data_source.dart';
import 'package:traviato/features/quest/data/models/quest_model.dart';
import 'package:traviato/features/quest/data/repositories/quest_repository_impl.dart';

class _FakeQuestRemoteDataSource implements QuestRemoteDataSource {
  _FakeQuestRemoteDataSource({this.exception});

  Exception? exception;
  String? lastAddQuestId;
  bool? lastToggleCompleted;
  var deleteCallCount = 0;

  QuestModel _quest({String id = 'q1', bool completed = false}) => QuestModel(
    id: id,
    tripId: 't1',
    dayDate: DateTime(2026, 8, 18),
    time: const Duration(hours: 8),
    title: 'Pack the car',
    placeText: 'Cooler, blankets, hiking boots',
    position: 0,
    completedAt: completed ? DateTime(2026, 8, 18, 9) : null,
    createdAt: DateTime(2026, 1, 1),
  );

  @override
  Future<List<QuestModel>> getQuestsForTrip(String tripId) async {
    if (exception != null) throw exception!;
    return [_quest()];
  }

  @override
  Future<QuestModel> addQuest({
    required String id,
    required String tripId,
    required DateTime dayDate,
    required String title,
    Duration? time,
    String? placeText,
    required int position,
  }) async {
    if (exception != null) throw exception!;
    lastAddQuestId = id;
    return _quest(id: id);
  }

  @override
  Future<QuestModel> updateQuest({
    required String id,
    required String title,
    Duration? time,
    String? placeText,
  }) async {
    if (exception != null) throw exception!;
    return _quest(id: id);
  }

  @override
  Future<void> deleteQuest(String id) async {
    if (exception != null) throw exception!;
    deleteCallCount++;
  }

  @override
  Future<QuestModel> toggleCompleted({
    required String id,
    required bool completed,
  }) async {
    if (exception != null) throw exception!;
    lastToggleCompleted = completed;
    return _quest(id: id, completed: completed);
  }
}

void main() {
  group('QuestRepositoryImpl.getQuestsForTrip', () {
    test('returns Right(quests) on success', () async {
      final repo = QuestRepositoryImpl(remote: _FakeQuestRemoteDataSource());
      final result = await repo.getQuestsForTrip('t1');
      result.fold(
        (failure) => fail('expected Right, got Left($failure)'),
        (quests) => expect(quests, hasLength(1)),
      );
    });

    test('maps NetworkException to NetworkFailure', () async {
      final repo = QuestRepositoryImpl(
        remote: _FakeQuestRemoteDataSource(exception: const NetworkException()),
      );
      final result = await repo.getQuestsForTrip('t1');
      result.fold(
        (failure) => expect(failure, const NetworkFailure()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('QuestRepositoryImpl.addQuest', () {
    test('returns Right(quest) and generates a client-side id', () async {
      final remote = _FakeQuestRemoteDataSource();
      final repo = QuestRepositoryImpl(remote: remote);
      final result = await repo.addQuest(
        tripId: 't1',
        dayDate: DateTime(2026, 8, 18),
        title: 'Pack the car',
        position: 0,
      );
      expect(result.isRight(), isTrue);
      expect(remote.lastAddQuestId, isNotNull);
      expect(remote.lastAddQuestId, isNotEmpty);
    });

    test('maps AuthenticationException to AuthenticationFailure', () async {
      final repo = QuestRepositoryImpl(
        remote: _FakeQuestRemoteDataSource(
          exception: const AuthenticationException(message: 'no session'),
        ),
      );
      final result = await repo.addQuest(
        tripId: 't1',
        dayDate: DateTime(2026, 8, 18),
        title: 'Pack the car',
        position: 0,
      );
      result.fold(
        (failure) =>
            expect(failure, const AuthenticationFailure(message: 'no session')),
        (_) => fail('expected Left'),
      );
    });
  });

  group('QuestRepositoryImpl.updateQuest', () {
    test('returns Right(quest) on success', () async {
      final repo = QuestRepositoryImpl(remote: _FakeQuestRemoteDataSource());
      final result = await repo.updateQuest(id: 'q1', title: 'Hit the road');
      expect(result.isRight(), isTrue);
    });
  });

  group('QuestRepositoryImpl.deleteQuest', () {
    test('returns Right(null) on success', () async {
      final remote = _FakeQuestRemoteDataSource();
      final repo = QuestRepositoryImpl(remote: remote);
      final result = await repo.deleteQuest('q1');
      expect(result.isRight(), isTrue);
      expect(remote.deleteCallCount, 1);
    });

    test('maps other AppExceptions to UnknownFailure', () async {
      final repo = QuestRepositoryImpl(
        remote: _FakeQuestRemoteDataSource(
          exception: const UnknownException(message: 'boom'),
        ),
      );
      final result = await repo.deleteQuest('q1');
      result.fold(
        (failure) => expect(failure, const UnknownFailure(message: 'boom')),
        (_) => fail('expected Left'),
      );
    });
  });

  group('QuestRepositoryImpl.toggleCompleted', () {
    test('passes the requested completed value through', () async {
      final remote = _FakeQuestRemoteDataSource();
      final repo = QuestRepositoryImpl(remote: remote);
      final result = await repo.toggleCompleted(id: 'q1', completed: true);
      expect(remote.lastToggleCompleted, isTrue);
      result.fold(
        (failure) => fail('expected Right, got Left($failure)'),
        (quest) => expect(quest.isCompleted, isTrue),
      );
    });
  });
}
