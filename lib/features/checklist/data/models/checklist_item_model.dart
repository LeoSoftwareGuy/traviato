import '../../domain/entities/checklist_category.dart';
import '../../domain/entities/checklist_item_entity.dart';

class ChecklistItemModel extends ChecklistItemEntity {
  const ChecklistItemModel({
    required super.id,
    required super.tripId,
    required super.title,
    required super.category,
    required super.isEssential,
    required super.isChecked,
    required super.position,
  });

  factory ChecklistItemModel.fromJson(Map<String, dynamic> json) =>
      ChecklistItemModel(
        id: json['id'] as String,
        tripId: json['trip_id'] as String,
        title: json['title'] as String,
        category: ChecklistCategory.fromDbValue(json['category'] as String),
        isEssential: json['is_essential'] as bool,
        isChecked: json['is_checked'] as bool,
        position: (json['position'] as num).toInt(),
      );
}
