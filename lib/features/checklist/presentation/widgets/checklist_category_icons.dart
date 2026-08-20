import 'package:flutter/material.dart';

import '../../domain/entities/checklist_category.dart';

/// Maps each fixed category to the icon shown next to its name — in the
/// category tab pill and the section header (Figma "current trip -
/// checklist"). Kept out of the domain entity since `IconData` is a
/// Flutter type (docs/05-domain-layer.md).
IconData checklistCategoryIcon(ChecklistCategory category) {
  switch (category) {
    case ChecklistCategory.travelEssentials:
      return Icons.badge_outlined;
    case ChecklistCategory.clothingShoes:
      return Icons.checkroom_outlined;
    case ChecklistCategory.gadgetsTech:
      return Icons.devices_other_outlined;
    case ChecklistCategory.toiletriesHealth:
      return Icons.health_and_safety_outlined;
    case ChecklistCategory.niceToHaves:
      return Icons.auto_awesome_outlined;
  }
}
