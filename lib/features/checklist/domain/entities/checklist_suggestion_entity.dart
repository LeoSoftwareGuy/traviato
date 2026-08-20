import 'package:equatable/equatable.dart';

import 'checklist_category.dart';

/// A row from the global `checklist_suggestions` catalog, copied into a
/// memory's `checklist_items` on first open (see `populateFromSuggestions`).
class ChecklistSuggestionEntity extends Equatable {
  const ChecklistSuggestionEntity({
    required this.id,
    required this.title,
    required this.category,
    required this.isEssential,
  });

  final int id;
  final String title;
  final ChecklistCategory category;
  final bool isEssential;

  @override
  List<Object?> get props => [id, title, category, isEssential];
}
