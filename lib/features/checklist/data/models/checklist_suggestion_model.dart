import '../../domain/entities/checklist_category.dart';
import '../../domain/entities/checklist_suggestion_entity.dart';

class ChecklistSuggestionModel extends ChecklistSuggestionEntity {
  const ChecklistSuggestionModel({
    required super.id,
    required super.title,
    required super.category,
    required super.isEssential,
  });

  factory ChecklistSuggestionModel.fromJson(Map<String, dynamic> json) =>
      ChecklistSuggestionModel(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String,
        category: ChecklistCategory.fromDbValue(json['category'] as String),
        isEssential: json['is_essential'] as bool,
      );
}
