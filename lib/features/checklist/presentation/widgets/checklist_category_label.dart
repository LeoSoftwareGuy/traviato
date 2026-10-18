import '../../../../core/l10n/context_l10n.dart';
import '../../domain/entities/checklist_category.dart';

/// The UI label for a packing category (#220). The domain enum keeps its
/// DB value and an English [ChecklistCategory.displayName] for logs; the
/// screen always shows this translated label.
String checklistCategoryLabel(
  AppLocalizations l10n,
  ChecklistCategory category,
) => switch (category) {
  ChecklistCategory.travelEssentials => l10n.checklist_catTravelEssentials,
  ChecklistCategory.clothingShoes => l10n.checklist_catClothingShoes,
  ChecklistCategory.gadgetsTech => l10n.checklist_catGadgetsTech,
  ChecklistCategory.toiletriesHealth => l10n.checklist_catToiletriesHealth,
  ChecklistCategory.niceToHaves => l10n.checklist_catNiceToHaves,
};
