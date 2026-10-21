-- Every memory has a start and end date (#270). An undated trip has no
-- place on Home (it's neither current, upcoming nor finished) and no days
-- for Plan/Journal/bonus tasks, so it was created but invisible. The app
-- now requires both dates; this makes the database enforce it too.
--
-- Deliberately no data change: if any undated trip still exists, `set not
-- null` fails and so does this migration. Undated rows are removed by hand
-- before it runs (agreed on #270) rather than silently deleted here.
--
-- trips_end_date_after_start_date keeps its `is null` branches — now
-- unreachable, but harmless and not worth recreating the constraint for.
--
-- Down/revert notes: `alter table public.trips
--   alter column start_date drop not null,
--   alter column end_date drop not null;`

alter table public.trips
  alter column start_date set not null,
  alter column end_date set not null;
