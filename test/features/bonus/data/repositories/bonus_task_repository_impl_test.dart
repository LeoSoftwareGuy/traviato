import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/errors/exceptions.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/bonus/data/datasources/bonus_task_remote_data_source.dart';
import 'package:traviato/features/bonus/data/models/bonus_task_assignment_model.dart';
import 'package:traviato/features/bonus/data/models/bonus_task_template_model.dart';
import 'package:traviato/features/bonus/data/repositories/bonus_task_repository_impl.dart';
import 'package:traviato/features/bonus/domain/entities/bonus_task_template_entity.dart';

class _FakeBonusTaskRemoteDataSource implements BonusTaskRemoteDataSource {
  _FakeBonusTaskRemoteDataSource({this.exception});

  Exception? exception;
  List<(String id, int templateId)>? lastAssignments;

  BonusTaskTemplateModel _template({int id = 1}) => BonusTaskTemplateModel(
    id: id,
    code: 'code_$id',
    title: 'Title $id',
    points: 1,
    phase: BonusTaskPhase.anytime,
    kind: BonusTaskKind.regular,
  );

  BonusTaskAssignmentModel _assignment({String id = 'a1'}) =>
      BonusTaskAssignmentModel(
        id: id,
        tripId: 't1',
        templateId: 1,
        dayDate: DateTime(2026, 8, 18),
        createdAt: DateTime(2026, 1, 1),
      );

  @override
  Future<List<BonusTaskTemplateModel>> getTemplates() async {
    if (exception != null) throw exception!;
    return [_template()];
  }

  @override
  Future<List<BonusTaskAssignmentModel>> getAssignmentsForTrip(
    String tripId,
  ) async {
    if (exception != null) throw exception!;
    return [_assignment()];
  }

  @override
  Future<List<BonusTaskAssignmentModel>> assignForDay({
    required String tripId,
    required DateTime dayDate,
    required List<(String id, int templateId)> assignments,
  }) async {
    if (exception != null) throw exception!;
    lastAssignments = assignments;
    return [for (final a in assignments) _assignment(id: a.$1)];
  }

  @override
  Future<BonusTaskAssignmentModel> completeAssignment({
    required String id,
    required String tripId,
    required String photoId,
  }) async {
    if (exception != null) throw exception!;
    return _assignment(id: id);
  }
}

void main() {
  group('BonusTaskRepositoryImpl.getTemplates', () {
    test('returns Right(templates) on success', () async {
      final repo = BonusTaskRepositoryImpl(
        remote: _FakeBonusTaskRemoteDataSource(),
      );
      final result = await repo.getTemplates();
      result.fold(
        (failure) => fail('expected Right, got Left($failure)'),
        (templates) => expect(templates, hasLength(1)),
      );
    });

    test('maps NetworkException to NetworkFailure', () async {
      final repo = BonusTaskRepositoryImpl(
        remote: _FakeBonusTaskRemoteDataSource(
          exception: const NetworkException(),
        ),
      );
      final result = await repo.getTemplates();
      result.fold(
        (failure) => expect(failure, const NetworkFailure()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('BonusTaskRepositoryImpl.assignForDay', () {
    test('generates a client-side id per template', () async {
      final remote = _FakeBonusTaskRemoteDataSource();
      final repo = BonusTaskRepositoryImpl(remote: remote);
      final result = await repo.assignForDay(
        tripId: 't1',
        dayDate: DateTime(2026, 8, 18),
        templateIds: [1, 2, 3],
      );
      expect(result.isRight(), isTrue);
      expect(remote.lastAssignments, hasLength(3));
      final ids = remote.lastAssignments!.map((a) => a.$1).toSet();
      expect(ids, hasLength(3)); // all distinct
      expect(
        remote.lastAssignments!.map((a) => a.$2).toList(),
        [1, 2, 3],
      );
    });

    test('maps AuthenticationException to AuthenticationFailure', () async {
      final repo = BonusTaskRepositoryImpl(
        remote: _FakeBonusTaskRemoteDataSource(
          exception: const AuthenticationException(message: 'no session'),
        ),
      );
      final result = await repo.assignForDay(
        tripId: 't1',
        dayDate: DateTime(2026, 8, 18),
        templateIds: [1],
      );
      result.fold(
        (failure) =>
            expect(failure, const AuthenticationFailure(message: 'no session')),
        (_) => fail('expected Left'),
      );
    });
  });

  group('BonusTaskRepositoryImpl.completeAssignment', () {
    test('returns Right(assignment) on success', () async {
      final repo = BonusTaskRepositoryImpl(
        remote: _FakeBonusTaskRemoteDataSource(),
      );
      final result = await repo.completeAssignment(
        id: 'a1',
        tripId: 't1',
        photoId: 'p1',
      );
      expect(result.isRight(), isTrue);
    });

    test('maps other AppExceptions to UnknownFailure', () async {
      final repo = BonusTaskRepositoryImpl(
        remote: _FakeBonusTaskRemoteDataSource(
          exception: const UnknownException(message: 'boom'),
        ),
      );
      final result = await repo.completeAssignment(
        id: 'a1',
        tripId: 't1',
        photoId: 'p1',
      );
      result.fold(
        (failure) => expect(failure, const UnknownFailure(message: 'boom')),
        (_) => fail('expected Left'),
      );
    });
  });
}
