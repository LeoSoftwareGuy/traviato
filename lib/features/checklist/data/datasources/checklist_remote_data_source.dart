import '../../domain/entities/checklist_category.dart';
import '../models/checklist_item_model.dart';
import '../models/checklist_suggestion_model.dart';

/// A pre-built row for the batch insert behind `populateFromSuggestions` —
/// the repository generates one per suggestion (with a fresh id and its
/// per-category position) and hands the whole batch to the datasource.
class ChecklistItemDraft {
  const ChecklistItemDraft({
    required this.id,
    required this.tripId,
    required this.title,
    required this.category,
    required this.isEssential,
    required this.position,
  });

  final String id;
  final String tripId;
  final String title;
  final ChecklistCategory category;
  final bool isEssential;
  final int position;
}

abstract interface class ChecklistRemoteDataSource {
  Future<List<ChecklistItemModel>> getItems(String tripId);

  Future<List<ChecklistSuggestionModel>> getSuggestions();

  Future<ChecklistItemModel> addItem({
    required String id,
    required String tripId,
    required ChecklistCategory category,
    required String title,
    required int position,
  });

  Future<ChecklistItemModel> toggleChecked({
    required String id,
    required bool checked,
  });

  Future<List<ChecklistItemModel>> insertItems(List<ChecklistItemDraft> items);
}
