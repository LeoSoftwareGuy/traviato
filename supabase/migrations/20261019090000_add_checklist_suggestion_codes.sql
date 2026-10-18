-- #243 (localization epic #220, L-3): a stable code per checklist
-- suggestion, so the app can write a new checklist in the user's UI
-- language instead of the seeded English title. Backfilled from the titles
-- seeded in 20260820130248_seed_checklist_suggestions.sql.
--
-- Read-only reference data: existing RLS/grants (select for clients) are
-- unchanged. checklist_items keep the text they were created with.
--
-- Revert: alter table public.checklist_suggestions drop column code;

alter table public.checklist_suggestions add column code text;

update public.checklist_suggestions as s
set code = v.code
from (values
  ('Passport', 'passport'),
  ('Visa documents', 'visa_documents'),
  ('Travel insurance', 'travel_insurance'),
  ('Boarding passes / tickets', 'boarding_passes_tickets'),
  ('ID card', 'id_card'),
  ('Local currency cash', 'local_currency_cash'),
  ('Credit / debit cards', 'credit_debit_cards'),
  ('Phone charger', 'phone_charger'),
  ('Underwear', 'underwear'),
  ('Comfortable walking shoes', 'comfortable_walking_shoes'),
  ('T-shirts', 't_shirts'),
  ('Jacket', 'jacket'),
  ('Swimsuit', 'swimsuit'),
  ('Sleepwear', 'sleepwear'),
  ('Sunglasses', 'sunglasses'),
  ('Toothbrush & toothpaste', 'toothbrush_toothpaste'),
  ('Prescription medications', 'prescription_medications'),
  ('First aid kit', 'first_aid_kit'),
  ('Sunscreen', 'sunscreen'),
  ('Deodorant', 'deodorant'),
  ('Hand sanitizer', 'hand_sanitizer'),
  ('Shampoo & conditioner', 'shampoo_conditioner'),
  ('Contact lenses or glasses', 'contact_lenses_or_glasses'),
  ('Phone', 'phone'),
  ('Charging cables', 'charging_cables'),
  ('Power adapter', 'power_adapter'),
  ('Portable battery pack', 'portable_battery_pack'),
  ('Headphones', 'headphones'),
  ('Camera', 'camera'),
  ('SIM card or eSIM', 'sim_card_or_esim'),
  ('Travel pillow', 'travel_pillow'),
  ('Reusable water bottle', 'reusable_water_bottle'),
  ('Snacks', 'snacks'),
  ('Packing cubes', 'packing_cubes'),
  ('Earplugs & eye mask', 'earplugs_eye_mask'),
  ('Travel journal', 'travel_journal'),
  ('Umbrella', 'umbrella')
) as v (title, code)
where s.title = v.title;

-- Any row a later change added under another title still gets a code.
update public.checklist_suggestions
set code = 'suggestion_' || id
where code is null;

alter table public.checklist_suggestions
  alter column code set not null,
  add constraint checklist_suggestions_code_key unique (code);
