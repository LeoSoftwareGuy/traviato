import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/checklist/domain/entities/checklist_category.dart';
import 'package:traviato/features/checklist/domain/entities/checklist_item_entity.dart';
import 'package:traviato/features/checklist/domain/entities/checklist_suggestion_entity.dart';
import 'package:traviato/features/checklist/domain/repositories/checklist_repository.dart';

/// Test double for [ChecklistRepository]. Configure the `*Result` fields to
/// force a failure; otherwise each method fabricates a plausible success.
class FakeChecklistRepository implements ChecklistRepository {
  Either<Failure, List<ChecklistItemEntity>>? itemsResult;
  Either<Failure, List<ChecklistSuggestionEntity>>? suggestionsResult;
  Either<Failure, ChecklistItemEntity>? addCustomItemResult;
  Either<Failure, ChecklistItemEntity>? toggleResult;
  Either<Failure, void>? deleteResult;
  Either<Failure, List<ChecklistItemEntity>>? populateResult;

  var getItemsCallCount = 0;
  var getSuggestionsCallCount = 0;
  var addCustomItemCallCount = 0;
  var toggleCallCount = 0;
  var deleteCallCount = 0;
  var populateCallCount = 0;
  int? lastAddPosition;
  String? lastDeletedId;

  @override
  Future<Either<Failure, List<ChecklistItemEntity>>> getItems(
    String tripId,
  ) async {
    getItemsCallCount++;
    return itemsResult ?? const Right([]);
  }

  @override
  Future<Either<Failure, List<ChecklistSuggestionEntity>>>
  getSuggestions() async {
    getSuggestionsCallCount++;
    return suggestionsResult ?? const Right([]);
  }

  @override
  Future<Either<Failure, ChecklistItemEntity>> addCustomItem({
    required String tripId,
    required ChecklistCategory category,
    required String title,
    required int position,
  }) async {
    addCustomItemCallCount++;
    lastAddPosition = position;
    return addCustomItemResult ??
        Right(
          buildChecklistItemEntity(
            tripId: tripId,
            category: category,
            title: title,
            position: position,
          ),
        );
  }

  @override
  Future<Either<Failure, ChecklistItemEntity>> toggleChecked({
    required String id,
    required bool checked,
  }) async {
    toggleCallCount++;
    return toggleResult ??
        Right(buildChecklistItemEntity(id: id, isChecked: checked));
  }

  @override
  Future<Either<Failure, void>> deleteItem(String id) async {
    deleteCallCount++;
    lastDeletedId = id;
    return deleteResult ?? const Right(null);
  }

  @override
  Future<Either<Failure, List<ChecklistItemEntity>>> populateFromSuggestions(
    String tripId,
  ) async {
    populateCallCount++;
    return populateResult ?? const Right([]);
  }
}

ChecklistItemEntity buildChecklistItemEntity({
  String id = 'i1',
  String tripId = 't1',
  String title = 'Passport',
  ChecklistCategory category = ChecklistCategory.travelEssentials,
  bool isEssential = false,
  bool isChecked = false,
  int position = 0,
}) {
  return ChecklistItemEntity(
    id: id,
    tripId: tripId,
    title: title,
    category: category,
    isEssential: isEssential,
    isChecked: isChecked,
    position: position,
  );
}
