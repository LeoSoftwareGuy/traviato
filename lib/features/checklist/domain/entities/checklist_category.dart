/// The 5 fixed packing-list categories (docs/data-model.md,
/// `checklist_items_category_check`). Order matches the Figma tab order
/// ("current trip - checklist").
enum ChecklistCategory {
  travelEssentials('travel_essentials', 'Travel essentials'),
  clothingShoes('clothing_shoes', 'Clothing & shoes'),
  gadgetsTech('gadgets_tech', 'Gadgets & tech'),
  toiletriesHealth('toiletries_health', 'Toiletries & health'),
  niceToHaves('nice_to_haves', 'Nice-to-haves');

  const ChecklistCategory(this.dbValue, this.displayName);

  final String dbValue;
  final String displayName;

  static ChecklistCategory fromDbValue(String value) =>
      values.firstWhere((c) => c.dbValue == value);
}
