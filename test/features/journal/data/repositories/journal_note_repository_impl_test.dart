import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/errors/exceptions.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/journal/data/datasources/journal_note_remote_data_source.dart';
import 'package:traviato/features/journal/data/models/journal_note_model.dart';
import 'package:traviato/features/journal/data/repositories/journal_note_repository_impl.dart';

JournalNoteModel _note({
  String id = 'n1',
  String content = 'Great day.',
  DateTime? takenAt,
}) => JournalNoteModel(
  id: id,
  tripId: 't1',
  dayDate: DateTime(2026, 8, 18),
  takenAt: takenAt ?? DateTime(2026, 8, 18, 21, 16),
  editedAt: takenAt ?? DateTime(2026, 8, 18, 21, 16),
  content: content,
);

class _FakeJournalNoteRemoteDataSource implements JournalNoteRemoteDataSource {
  _FakeJournalNoteRemoteDataSource({this.exception, this.notes = const []});

  Exception? exception;
  List<JournalNoteModel> notes;
  String? lastCreatedId;
  DateTime? lastTakenAt;
  String? lastPhotoId;
  bool? lastDictated;
  String? lastUpdatedId;
  String? lastDeletedId;

  @override
  Future<List<JournalNoteModel>> getNotesForDay({
    required String tripId,
    required DateTime dayDate,
  }) async {
    if (exception != null) throw exception!;
    return notes;
  }

  @override
  Future<List<JournalNoteModel>> getNotesForTrip(String tripId) async {
    if (exception != null) throw exception!;
    return notes;
  }

  @override
  Future<JournalNoteModel> createNote({
    required String id,
    required String tripId,
    required DateTime dayDate,
    required DateTime takenAt,
    required String content,
    required bool dictated,
    String? photoId,
  }) async {
    if (exception != null) throw exception!;
    lastCreatedId = id;
    lastTakenAt = takenAt;
    lastPhotoId = photoId;
    lastDictated = dictated;
    return _note(id: id, content: content, takenAt: takenAt);
  }

  @override
  Future<JournalNoteModel> updateNote({
    required String id,
    required String content,
    required bool dictated,
  }) async {
    if (exception != null) throw exception!;
    lastUpdatedId = id;
    return _note(id: id, content: content);
  }

  @override
  Future<void> deleteNote(String id) async {
    if (exception != null) throw exception!;
    lastDeletedId = id;
  }
}

void main() {
  group('JournalNoteRepositoryImpl.getNotesForDay', () {
    test("returns the day's notes", () async {
      final repo = JournalNoteRepositoryImpl(
        remote: _FakeJournalNoteRemoteDataSource(
          notes: [
            _note(),
            _note(id: 'n2', content: 'Later.'),
          ],
        ),
      );
      final result = await repo.getNotesForDay(
        tripId: 't1',
        dayDate: DateTime(2026, 8, 18),
      );
      expect(result.getRight().toNullable()!.map((n) => n.id), ['n1', 'n2']);
    });

    test('maps NetworkException to NetworkFailure', () async {
      final repo = JournalNoteRepositoryImpl(
        remote: _FakeJournalNoteRemoteDataSource(
          exception: const NetworkException(),
        ),
      );
      final result = await repo.getNotesForDay(
        tripId: 't1',
        dayDate: DateTime(2026, 8, 18),
      );
      expect(result.getLeft().toNullable(), const NetworkFailure());
    });
  });

  group('JournalNoteRepositoryImpl.createNote', () {
    test('generates a client-side id and passes the note through', () async {
      final remote = _FakeJournalNoteRemoteDataSource();
      final repo = JournalNoteRepositoryImpl(remote: remote);
      final takenAt = DateTime(2026, 8, 18, 21, 16);
      final result = await repo.createNote(
        tripId: 't1',
        dayDate: DateTime(2026, 8, 18),
        takenAt: takenAt,
        content: 'Ribs at the bar.',
        dictated: true,
        photoId: 'p1',
      );
      expect(result.isRight(), isTrue);
      expect(remote.lastCreatedId, isNotEmpty);
      expect(remote.lastTakenAt, takenAt);
      expect(remote.lastPhotoId, 'p1');
      expect(remote.lastDictated, isTrue);
    });

    test('two creates get two different ids', () async {
      final remote = _FakeJournalNoteRemoteDataSource();
      final repo = JournalNoteRepositoryImpl(remote: remote);
      Future<String?> create() async {
        await repo.createNote(
          tripId: 't1',
          dayDate: DateTime(2026, 8, 18),
          takenAt: DateTime(2026, 8, 18, 9),
          content: 'x',
        );
        return remote.lastCreatedId;
      }

      expect(await create(), isNot(await create()));
    });

    test('maps AuthenticationException to AuthenticationFailure', () async {
      final repo = JournalNoteRepositoryImpl(
        remote: _FakeJournalNoteRemoteDataSource(
          exception: const AuthenticationException(message: 'no session'),
        ),
      );
      final result = await repo.createNote(
        tripId: 't1',
        dayDate: DateTime(2026, 8, 18),
        takenAt: DateTime(2026, 8, 18, 9),
        content: 'Great day.',
      );
      expect(
        result.getLeft().toNullable(),
        const AuthenticationFailure(message: 'no session'),
      );
    });
  });

  group('JournalNoteRepositoryImpl.updateNote', () {
    test('updates by note id', () async {
      final remote = _FakeJournalNoteRemoteDataSource();
      final repo = JournalNoteRepositoryImpl(remote: remote);
      final result = await repo.updateNote(
        noteId: 'n1',
        content: 'New text.',
        dictated: false,
      );
      expect(result.getRight().toNullable()?.content, 'New text.');
      expect(remote.lastUpdatedId, 'n1');
    });
  });

  group('JournalNoteRepositoryImpl.deleteNote', () {
    test('deletes by note id', () async {
      final remote = _FakeJournalNoteRemoteDataSource();
      final repo = JournalNoteRepositoryImpl(remote: remote);
      final result = await repo.deleteNote('n1');
      expect(result.isRight(), isTrue);
      expect(remote.lastDeletedId, 'n1');
    });

    test('maps a permission error to PermissionFailure', () async {
      final repo = JournalNoteRepositoryImpl(
        remote: _FakeJournalNoteRemoteDataSource(
          exception: const PermissionException(message: 'nope'),
        ),
      );
      final result = await repo.deleteNote('n1');
      expect(result.getLeft().toNullable(), isA<PermissionFailure>());
    });
  });
}
