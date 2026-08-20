-- Seed checklist_suggestions (docs/data-model.md). Closes #21.
--
-- Down/revert notes: `delete from public.checklist_suggestions;`
--
-- Shipped as a migration (not supabase/seed.sql) since this is real
-- reference data the app reads in production, not a local dev fixture.

insert into public.checklist_suggestions (title, category, is_essential)
values
  -- travel_essentials
  ('Passport', 'travel_essentials', true),
  ('Visa documents', 'travel_essentials', true),
  ('Travel insurance', 'travel_essentials', true),
  ('Boarding passes / tickets', 'travel_essentials', true),
  ('ID card', 'travel_essentials', true),
  ('Local currency cash', 'travel_essentials', false),
  ('Credit / debit cards', 'travel_essentials', false),
  ('Phone charger', 'travel_essentials', false),

  -- clothing_shoes
  ('Underwear', 'clothing_shoes', false),
  ('Comfortable walking shoes', 'clothing_shoes', false),
  ('T-shirts', 'clothing_shoes', false),
  ('Jacket', 'clothing_shoes', false),
  ('Swimsuit', 'clothing_shoes', false),
  ('Sleepwear', 'clothing_shoes', false),
  ('Sunglasses', 'clothing_shoes', false),

  -- toiletries_health
  ('Toothbrush & toothpaste', 'toiletries_health', false),
  ('Prescription medications', 'toiletries_health', true),
  ('First aid kit', 'toiletries_health', false),
  ('Sunscreen', 'toiletries_health', false),
  ('Deodorant', 'toiletries_health', false),
  ('Hand sanitizer', 'toiletries_health', false),
  ('Shampoo & conditioner', 'toiletries_health', false),
  ('Contact lenses or glasses', 'toiletries_health', false),

  -- gadgets_tech
  ('Phone', 'gadgets_tech', false),
  ('Charging cables', 'gadgets_tech', false),
  ('Power adapter', 'gadgets_tech', false),
  ('Portable battery pack', 'gadgets_tech', false),
  ('Headphones', 'gadgets_tech', false),
  ('Camera', 'gadgets_tech', false),
  ('SIM card or eSIM', 'gadgets_tech', false),

  -- nice_to_haves
  ('Travel pillow', 'nice_to_haves', false),
  ('Reusable water bottle', 'nice_to_haves', false),
  ('Snacks', 'nice_to_haves', false),
  ('Packing cubes', 'nice_to_haves', false),
  ('Earplugs & eye mask', 'nice_to_haves', false),
  ('Travel journal', 'nice_to_haves', false),
  ('Umbrella', 'nice_to_haves', false);
