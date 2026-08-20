import 'package:equatable/equatable.dart';

import '../../domain/entities/checklist_category.dart';
import '../../domain/entities/checklist_item_entity.dart';

class ChecklistState extends Equatable {
  const ChecklistState({required this.items, required this.selectedCategory});

  final List<ChecklistItemEntity> items;
  final ChecklistCategory selectedCategory;

  int get totalCount => items.length;

  int get checkedCount => items.where((i) => i.isChecked).length;

  int get progressPercent =>
      totalCount == 0 ? 0 : ((checkedCount / totalCount) * 100).round();

  List<ChecklistItemEntity> itemsFor(ChecklistCategory category) {
    final forCategory = items.where((i) => i.category == category).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    return forCategory;
  }

  int countFor(ChecklistCategory category) =>
      items.where((i) => i.category == category).length;

  int checkedCountFor(ChecklistCategory category) =>
      items.where((i) => i.category == category && i.isChecked).length;

  List<ChecklistItemEntity> get itemsForSelectedCategory =>
      itemsFor(selectedCategory);

  ChecklistState copyWith({
    List<ChecklistItemEntity>? items,
    ChecklistCategory? selectedCategory,
  }) => ChecklistState(
    items: items ?? this.items,
    selectedCategory: selectedCategory ?? this.selectedCategory,
  );

  @override
  List<Object?> get props => [items, selectedCategory];
}
