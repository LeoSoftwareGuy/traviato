import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../domain/entities/checklist_category.dart';
import '../../domain/entities/checklist_item_entity.dart';
import '../providers/checklist_providers.dart';
import 'checklist_state.dart';

part 'checklist_controller.g.dart';

@riverpod
class ChecklistController extends _$ChecklistController {
  @override
  Future<ChecklistState> build(String tripId) async {
    final repo = ref.watch(checklistRepositoryProvider);

    final itemsResult = await repo.getItems(tripId);
    var items = itemsResult.fold(
      (failure) => throw PresentationFailureException(failure),
      (i) => i,
    );

    // First open of an empty checklist: seed it from the suggestions catalog.
    if (items.isEmpty) {
      final populateResult = await repo.populateFromSuggestions(tripId);
      items = populateResult.fold(
        (failure) => throw PresentationFailureException(failure),
        (i) => i,
      );
    }

    ref.invalidate(checklistProgressForTripProvider(tripId));

    return ChecklistState(
      items: items,
      selectedCategory: ChecklistCategory.values.first,
    );
  }

  void selectCategory(ChecklistCategory category) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(selectedCategory: category));
  }

  /// Called by the checklist mutations after a successful toggle/add.
  void applyItemUpserted(ChecklistItemEntity item) {
    final current = state.value;
    if (current == null) return;
    final exists = current.items.any((i) => i.id == item.id);
    final updated = exists
        ? [
            for (final i in current.items)
              if (i.id == item.id) item else i,
          ]
        : [...current.items, item];
    state = AsyncData(current.copyWith(items: updated));
    ref.invalidate(checklistProgressForTripProvider(tripId));
  }

  /// Called by the delete mutation after a successful delete.
  void applyItemRemoved(String itemId) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        items: current.items.where((i) => i.id != itemId).toList(),
      ),
    );
    ref.invalidate(checklistProgressForTripProvider(tripId));
  }
}
