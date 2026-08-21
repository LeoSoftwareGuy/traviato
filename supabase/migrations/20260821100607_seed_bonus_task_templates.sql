-- Seed bonus_task_templates (docs/functionality.md §10). Part of #27.
--
-- Down/revert notes: `delete from public.bonus_task_templates;`
--
-- Shipped as a migration (not supabase/seed.sql) since this is real
-- reference data the app reads in production, not a local dev fixture.

insert into public.bonus_task_templates (title, description, points, duration_hours, trigger)
values
  (
    'Pack your bags on camera',
    'Snap a photo of your packed bags before you head out.',
    3,
    24,
    'trip_start'
  ),
  (
    'Share with a friend',
    'Tell a friend about this memory in the making.',
    2,
    12,
    'random'
  ),
  (
    'Snap your first meal there',
    'Capture a photo of the first meal you have on this trip.',
    2,
    24,
    'trip_start'
  ),
  (
    'Document your outfit',
    'Take a photo of what you''re wearing today.',
    2,
    12,
    'random'
  ),
  (
    'Capture the best view',
    'Find and photograph the best view you''ve seen today.',
    3,
    12,
    'random'
  );
