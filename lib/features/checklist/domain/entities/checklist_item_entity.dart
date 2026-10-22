import 'package:equatable/equatable.dart';

import 'checklist_category.dart';

/// One packing-list row for a memory, either seeded from
/// [ChecklistSuggestionEntity] or added by the user.
class ChecklistItemEntity extends Equatable {
  const ChecklistItemEntity({
    required this.id,
    required this.tripId,
    required this.title,
    required this.category,
    required this.isEssential,
    required this.isChecked,
    required this.position,
    this.suggestionCode,
  });

  final String id;
  final String tripId;
  final String title;
  final ChecklistCategory category;
  final bool isEssential;
  final bool isChecked;
  final int position;

  /// The suggestion this item was seeded from (#285) — its title follows
  /// the UI language. Null for the user's own items, which keep [title].
  final String? suggestionCode;

  @override
  List<Object?> get props => [
    id,
    tripId,
    title,
    category,
    isEssential,
    isChecked,
    position,
    suggestionCode,
  ];
}
