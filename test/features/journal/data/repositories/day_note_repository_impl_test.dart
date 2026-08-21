import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/errors/exceptions.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/journal/data/datasources/day_note_remote_data_source.dart';
import 'package:traviato/features/journal/data/models/day_note_model.dart';
import 'package:traviato/features/journal/data/repositories/day_note_repository_impl.dart';

class _FakeDayNoteRemoteDataSource implements DayNoteRemoteDataSource {
  _FakeDayNoteRemoteDataSource({this.exception, this.existingNote});

  Exception? exception;
  DayNoteModel? existingNote;
  String? lastUpsertId;

  @override
  Future<DayNoteModel?> getNote({
    required String tripId,
    required DateTime dayDate,
  }) async {
    if (exception != null) throw exception!;
    return existingNote;
  }

  @override
  Future<DayNoteModel> upsertNote({
    required String id,
    required String tripId,
    required DateTime dayDate,
    required String content,
  }) async {
    if (exception != null) throw exception!;
    lastUpsertId = id;
    return DayNoteModel(
      id: id,
      tripId: tripId,
      dayDate: dayDate,
      content: content,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }
}

void main() {
  group('DayNoteRepositoryImpl.getNote', () {
    test('returns Right(null) when the day has no note', () async {
      final repo = DayNoteRepositoryImpl(
        remote: _FakeDayNoteRemoteDataSource(),
      );
      final result = await repo.getNote(
        tripId: 't1',
        dayDate: DateTime(2026, 8, 18),
      );
      result.fold(
        (failure) => fail('expected Right, got Left($failure)'),
        (note) => expect(note, isNull),
      );
    });

    test('returns Right(note) when one exists', () async {
      final existing = DayNoteModel(
        id: 'n1',
        tripId: 't1',
        dayDate: DateTime(2026, 8, 18),
        content: 'Great day.',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final repo = DayNoteRepositoryImpl(
        remote: _FakeDayNoteRemoteDataSource(existingNote: existing),
      );
      final result = await repo.getNote(
        tripId: 't1',
        dayDate: DateTime(2026, 8, 18),
      );
      result.fold(
        (failure) => fail('expected Right, got Left($failure)'),
        (note) => expect(note?.content, 'Great day.'),
      );
    });

    test('maps NetworkException to NetworkFailure', () async {
      final repo = DayNoteRepositoryImpl(
        remote: _FakeDayNoteRemoteDataSource(
          exception: const NetworkException(),
        ),
      );
      final result = await repo.getNote(
        tripId: 't1',
        dayDate: DateTime(2026, 8, 18),
      );
      result.fold(
        (failure) => expect(failure, const NetworkFailure()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('DayNoteRepositoryImpl.upsertNote', () {
    test('returns Right(note) and generates a client-side id', () async {
      final remote = _FakeDayNoteRemoteDataSource();
      final repo = DayNoteRepositoryImpl(remote: remote);
      final result = await repo.upsertNote(
        tripId: 't1',
        dayDate: DateTime(2026, 8, 18),
        content: 'Great day.',
      );
      expect(result.isRight(), isTrue);
      expect(remote.lastUpsertId, isNotNull);
      expect(remote.lastUpsertId, isNotEmpty);
    });

    test('maps AuthenticationException to AuthenticationFailure', () async {
      final repo = DayNoteRepositoryImpl(
        remote: _FakeDayNoteRemoteDataSource(
          exception: const AuthenticationException(message: 'no session'),
        ),
      );
      final result = await repo.upsertNote(
        tripId: 't1',
        dayDate: DateTime(2026, 8, 18),
        content: 'Great day.',
      );
      result.fold(
        (failure) =>
            expect(failure, const AuthenticationFailure(message: 'no session')),
        (_) => fail('expected Left'),
      );
    });
  });
}
