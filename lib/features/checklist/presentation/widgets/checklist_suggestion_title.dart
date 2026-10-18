import '../../../../core/l10n/context_l10n.dart';
import '../../domain/entities/checklist_suggestion_entity.dart';

// Generated from the seeded `checklist_suggestions` (#243). An unknown code
// falls back to the DB text.

/// A suggestion's title in the UI language, used once when a memory's
/// checklist is first created — the item is the user's own from then on.
String checklistSuggestionTitle(
  AppLocalizations l10n,
  ChecklistSuggestionEntity suggestion,
) => switch (suggestion.code) {
  'passport' => l10n.content_checklist_passport,
  'visa_documents' => l10n.content_checklist_visa_documents,
  'travel_insurance' => l10n.content_checklist_travel_insurance,
  'boarding_passes_tickets' => l10n.content_checklist_boarding_passes_tickets,
  'id_card' => l10n.content_checklist_id_card,
  'local_currency_cash' => l10n.content_checklist_local_currency_cash,
  'credit_debit_cards' => l10n.content_checklist_credit_debit_cards,
  'phone_charger' => l10n.content_checklist_phone_charger,
  'underwear' => l10n.content_checklist_underwear,
  'comfortable_walking_shoes' =>
    l10n.content_checklist_comfortable_walking_shoes,
  't_shirts' => l10n.content_checklist_t_shirts,
  'jacket' => l10n.content_checklist_jacket,
  'swimsuit' => l10n.content_checklist_swimsuit,
  'sleepwear' => l10n.content_checklist_sleepwear,
  'sunglasses' => l10n.content_checklist_sunglasses,
  'toothbrush_toothpaste' => l10n.content_checklist_toothbrush_toothpaste,
  'prescription_medications' => l10n.content_checklist_prescription_medications,
  'first_aid_kit' => l10n.content_checklist_first_aid_kit,
  'sunscreen' => l10n.content_checklist_sunscreen,
  'deodorant' => l10n.content_checklist_deodorant,
  'hand_sanitizer' => l10n.content_checklist_hand_sanitizer,
  'shampoo_conditioner' => l10n.content_checklist_shampoo_conditioner,
  'contact_lenses_or_glasses' =>
    l10n.content_checklist_contact_lenses_or_glasses,
  'phone' => l10n.content_checklist_phone,
  'charging_cables' => l10n.content_checklist_charging_cables,
  'power_adapter' => l10n.content_checklist_power_adapter,
  'portable_battery_pack' => l10n.content_checklist_portable_battery_pack,
  'headphones' => l10n.content_checklist_headphones,
  'camera' => l10n.content_checklist_camera,
  'sim_card_or_esim' => l10n.content_checklist_sim_card_or_esim,
  'travel_pillow' => l10n.content_checklist_travel_pillow,
  'reusable_water_bottle' => l10n.content_checklist_reusable_water_bottle,
  'snacks' => l10n.content_checklist_snacks,
  'packing_cubes' => l10n.content_checklist_packing_cubes,
  'earplugs_eye_mask' => l10n.content_checklist_earplugs_eye_mask,
  'travel_journal' => l10n.content_checklist_travel_journal,
  'umbrella' => l10n.content_checklist_umbrella,
  _ => suggestion.title,
};
