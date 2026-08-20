import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/errors/exceptions.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/checklist/data/datasources/checklist_remote_data_source.dart';
import 'package:traviato/features/checklist/data/models/checklist_item_model.dart';
import 'package:traviato/features/checklist/data/models/checklist_suggestion_model.dart';
import 'package:traviato/features/checklist/data/repositories/checklist_repository_impl.dart';
import 'package:traviato/features/checklist/domain/entities/checklist_category.dart';

class _FakeChecklistRemoteDataSource implements ChecklistRemoteDataSource {
  _FakeChecklistRemoteDataSource({this.exception, this.suggestions});

  Exception? exception;
  List<ChecklistSuggestionModel>? suggestions;
  String? lastAddItemId;
  String? lastDeletedId;
  List<ChecklistItemDraft>? lastInsertedItems;

  ChecklistItemModel _item({
    String id = 'i1',
    ChecklistCategory category = ChecklistCategory.travelEssentials,
    bool isChecked = false,
  }) => ChecklistItemModel(
    id: id,
    tripId: 't1',
    title: 'Passport',
    category: category,
    isEssential: true,
    isChecked: isChecked,
    position: 0,
  );

  @override
  Future<List<ChecklistItemModel>> getItems(String tripId) async {
    if (exception != null) throw exception!;
    return [_item()];
  }

  @override
  Future<List<ChecklistSuggestionModel>> getSuggestions() async {
    if (exception != null) throw exception!;
    return suggestions ?? const [];
  }

  @override
  Future<ChecklistItemModel> addItem({
    required String id,
    required String tripId,
    required ChecklistCategory category,
    required String title,
    required int position,
  }) async {
    if (exception != null) throw exception!;
    lastAddItemId = id;
    return _item(id: id, category: category);
  }

  @override
  Future<ChecklistItemModel> toggleChecked({
    required String id,
    required bool checked,
  }) async {
    if (exception != null) throw exception!;
    return _item(id: id, isChecked: checked);
  }

  @override
  Future<void> deleteItem(String id) async {
    if (exception != null) throw exception!;
    lastDeletedId = id;
  }

  @override
  Future<List<ChecklistItemModel>> insertItems(
    List<ChecklistItemDraft> items,
  ) async {
    if (exception != null) throw exception!;
    lastInsertedItems = items;
    return [
      for (final item in items)
        ChecklistItemModel(
          id: item.id,
          tripId: item.tripId,
          title: item.title,
          category: item.category,
          isEssential: item.isEssential,
          isChecked: false,
          position: item.position,
        ),
    ];
  }
}

void main() {
  group('ChecklistRepositoryImpl.getItems', () {
    test('returns Right(items) on success', () async {
      final repo = ChecklistRepositoryImpl(
        remote: _FakeChecklistRemoteDataSource(),
      );
      final result = await repo.getItems('t1');
      result.fold(
        (failure) => fail('expected Right, got Left($failure)'),
        (items) => expect(items, hasLength(1)),
      );
    });

    test('maps NetworkException to NetworkFailure', () async {
      final repo = ChecklistRepositoryImpl(
        remote: _FakeChecklistRemoteDataSource(
          exception: const NetworkException(),
        ),
      );
      final result = await repo.getItems('t1');
      result.fold(
        (failure) => expect(failure, const NetworkFailure()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('ChecklistRepositoryImpl.addCustomItem', () {
    test('returns Right(item) and generates a client-side id', () async {
      final remote = _FakeChecklistRemoteDataSource();
      final repo = ChecklistRepositoryImpl(remote: remote);
      final result = await repo.addCustomItem(
        tripId: 't1',
        category: ChecklistCategory.clothingShoes,
        title: 'Hiking boots',
        position: 0,
      );
      expect(result.isRight(), isTrue);
      expect(remote.lastAddItemId, isNotNull);
      expect(remote.lastAddItemId, isNotEmpty);
    });

    test('maps AuthenticationException to AuthenticationFailure', () async {
      final repo = ChecklistRepositoryImpl(
        remote: _FakeChecklistRemoteDataSource(
          exception: const AuthenticationException(message: 'no session'),
        ),
      );
      final result = await repo.addCustomItem(
        tripId: 't1',
        category: ChecklistCategory.clothingShoes,
        title: 'Hiking boots',
        position: 0,
      );
      result.fold(
        (failure) =>
            expect(failure, const AuthenticationFailure(message: 'no session')),
        (_) => fail('expected Left'),
      );
    });
  });

  group('ChecklistRepositoryImpl.toggleChecked', () {
    test('passes the requested checked value through', () async {
      final repo = ChecklistRepositoryImpl(
        remote: _FakeChecklistRemoteDataSource(),
      );
      final result = await repo.toggleChecked(id: 'i1', checked: true);
      result.fold(
        (failure) => fail('expected Right, got Left($failure)'),
        (item) => expect(item.isChecked, isTrue),
      );
    });
  });

  group('ChecklistRepositoryImpl.deleteItem', () {
    test('returns Right(null) on success', () async {
      final remote = _FakeChecklistRemoteDataSource();
      final repo = ChecklistRepositoryImpl(remote: remote);
      final result = await repo.deleteItem('i1');
      expect(result.isRight(), isTrue);
      expect(remote.lastDeletedId, 'i1');
    });

    test('maps other AppExceptions to UnknownFailure', () async {
      final repo = ChecklistRepositoryImpl(
        remote: _FakeChecklistRemoteDataSource(
          exception: const UnknownException(message: 'boom'),
        ),
      );
      final result = await repo.deleteItem('i1');
      result.fold(
        (failure) => expect(failure, const UnknownFailure(message: 'boom')),
        (_) => fail('expected Left'),
      );
    });
  });

  group('ChecklistRepositoryImpl.populateFromSuggestions', () {
    test(
      'assigns a fresh id and a sequential per-category position to each '
      'suggestion',
      () async {
        final suggestions = [
          const ChecklistSuggestionModel(
            id: 1,
            title: 'Passport',
            category: ChecklistCategory.travelEssentials,
            isEssential: true,
          ),
          const ChecklistSuggestionModel(
            id: 2,
            title: 'Visa',
            category: ChecklistCategory.travelEssentials,
            isEssential: true,
          ),
          const ChecklistSuggestionModel(
            id: 3,
            title: 'Socks',
            category: ChecklistCategory.clothingShoes,
            isEssential: false,
          ),
        ];
        final remote = _FakeChecklistRemoteDataSource(
          suggestions: suggestions,
        );
        final repo = ChecklistRepositoryImpl(remote: remote);

        final result = await repo.populateFromSuggestions('t1');

        result.fold((failure) => fail('expected Right, got Left($failure)'), (
          items,
        ) {
          expect(items, hasLength(3));
          expect(items.map((i) => i.tripId), everyElement('t1'));
        });

        final drafts = remote.lastInsertedItems!;
        expect(drafts.map((d) => d.id).toSet(), hasLength(3));
        final travelPositions = drafts
            .where((d) => d.category == ChecklistCategory.travelEssentials)
            .map((d) => d.position)
            .toList();
        expect(travelPositions, [0, 1]);
        final clothingPositions = drafts
            .where((d) => d.category == ChecklistCategory.clothingShoes)
            .map((d) => d.position)
            .toList();
        expect(clothingPositions, [0]);
      },
    );

    test('maps NetworkException to NetworkFailure', () async {
      final repo = ChecklistRepositoryImpl(
        remote: _FakeChecklistRemoteDataSource(
          exception: const NetworkException(),
        ),
      );
      final result = await repo.populateFromSuggestions('t1');
      result.fold(
        (failure) => expect(failure, const NetworkFailure()),
        (_) => fail('expected Left'),
      );
    });
  });
}
