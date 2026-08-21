-- Seed achievement_templates (docs/functionality.md §3). Part of #27.
--
-- Down/revert notes: `delete from public.achievement_templates;`
--
-- Shipped as a migration (not supabase/seed.sql) since this is real
-- reference data the app reads in production, not a local dev fixture.
--
-- 6 of the 8 badges are named in the docs; globetrotter and century have
-- docs-pinned targets. star_collector/shutterbug/storyteller targets and
-- the 2 unnamed badges (jetsetter, legend) were proposed in the #27 plan
-- comment and confirmed there.

insert into public.achievement_templates (code, title, description, metric, target, position)
values
  (
    'first_adventure',
    'First Adventure',
    'Log your first memory.',
    'trips',
    1,
    1
  ),
  (
    'globetrotter',
    'Globetrotter',
    'Visit 10 countries.',
    'countries',
    10,
    2
  ),
  (
    'century',
    'Century',
    'Capture 100 days of travel.',
    'days_logged',
    100,
    3
  ),
  (
    'star_collector',
    'Star Collector',
    'Earn 250 stars.',
    'stars',
    250,
    4
  ),
  (
    'shutterbug',
    'Shutterbug',
    'Add 50 photos to your memories.',
    'photos',
    50,
    5
  ),
  (
    'storyteller',
    'Storyteller',
    'Write 20 journal notes.',
    'notes',
    20,
    6
  ),
  (
    'jetsetter',
    'Jetsetter',
    'Log 5 memories.',
    'trips',
    5,
    7
  ),
  (
    'legend',
    'Legend',
    'Earn 1000 stars.',
    'stars',
    1000,
    8
  );
