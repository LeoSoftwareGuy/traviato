import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../domain/entities/checklist_category.dart';
import '../../domain/entities/checklist_item_entity.dart';
import '../controllers/checklist_controller.dart';
import '../providers/checklist_providers.dart';

final toggleChecklistItemMutation = Mutation<ChecklistItemEntity>();
final addChecklistItemMutation = Mutation<ChecklistItemEntity>();
final deleteChecklistItemMutation = Mutation<void>();

int _nextPosition(List<ChecklistItemEntity> itemsInCategory) {
  if (itemsInCategory.isEmpty) return 0;
  return itemsInCategory
          .map((i) => i.position)
          .reduce((a, b) => a > b ? a : b) +
      1;
}

Future<ChecklistItemEntity> runToggleChecklistItem({
  required WidgetRef ref,
  required String tripId,
  required ChecklistItemEntity item,
}) {
  return toggleChecklistItemMutation(item.id).run(ref, (tsx) async {
    final repo = tsx.get(checklistRepositoryProvider);
    final controller = tsx.get(checklistControllerProvider(tripId).notifier);
    final result = await repo.toggleChecked(
      id: item.id,
      checked: !item.isChecked,
    );
    return result.fold(
      (failure) => throw PresentationFailureException(failure),
      (
        updated,
      ) {
        controller.applyItemUpserted(updated);
        return updated;
      },
    );
  });
}

Future<void> runDeleteChecklistItem({
  required WidgetRef ref,
  required String tripId,
  required String itemId,
}) {
  return deleteChecklistItemMutation.run(ref, (tsx) async {
    final repo = tsx.get(checklistRepositoryProvider);
    final controller = tsx.get(checklistControllerProvider(tripId).notifier);
    (await repo.deleteItem(itemId)).fold(
      (failure) => throw PresentationFailureException(failure),
      (_) => controller.applyItemRemoved(itemId),
    );
  });
}

Future<ChecklistItemEntity> runAddChecklistItem({
  required WidgetRef ref,
  required String tripId,
  required ChecklistCategory category,
  required String title,
}) {
  return addChecklistItemMutation.run(ref, (tsx) async {
    final repo = tsx.get(checklistRepositoryProvider);
    final controller = tsx.get(checklistControllerProvider(tripId).notifier);
    final currentState = tsx.get(checklistControllerProvider(tripId)).value;
    final itemsInCategory = currentState?.itemsFor(category) ?? const [];

    final result = await repo.addCustomItem(
      tripId: tripId,
      category: category,
      title: title,
      position: _nextPosition(itemsInCategory),
    );
    return result.fold(
      (failure) => throw PresentationFailureException(failure),
      (
        item,
      ) {
        controller.applyItemUpserted(item);
        return item;
      },
    );
  });
}
