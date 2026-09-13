-- #131: two independent trip-query optimizations found during a DB audit.
--
-- 1. `trips` is the only owner-filtered table with no index backing its
--    RLS ownership column (every child table already has one). Every
--    "list my trips" read (trip_card_view, hit on every Home load) has been
--    doing a sequential scan filtered by user_id.
--
-- 2. `trip_card_view` didn't carry a quest count, so Home's "Coming up"
--    planning-state line fetched every full quest row per trip card just to
--    take its length (questCountForTripProvider). Adding `quest_count` here
--    follows the same pattern already used for `photo_count`/`stars`.
--
-- Down/revert notes: `drop index public.trips_user_id_idx;` then
-- `create or replace view` back to the #109 shape (drop the quest_count
-- column/select expression below).

create index trips_user_id_idx on public.trips (user_id);

create or replace view public.trip_card_view
with (security_invoker = true) as
select
  t.id,
  t.user_id,
  t.name,
  t.destination,
  t.country_code,
  t.start_date,
  t.end_date,
  t.vibes,
  t.cover_image_path,
  t.created_at,
  t.updated_at,
  case
    when t.start_date is null or t.end_date is null then 'undated'
    when current_date < t.start_date then 'upcoming'
    when current_date > t.end_date then 'finished'
    else 'current'
  end as status,
  case
    when t.start_date is null or t.end_date is null then null
    else (t.end_date - t.start_date) + 1
  end as duration_days,
  coalesce(
    (select count(*) from public.photos ph where ph.trip_id = t.id),
    0
  )::int as photo_count,
  coalesce(
    (select sum(pl.points) from public.points_ledger pl where pl.trip_id = t.id),
    0
  )::int as stars,
  coalesce(
    (select sum(e.amount) from public.expenses e where e.trip_id = t.id),
    0
  )::numeric(10, 2) as expense_total,
  w.published_at as wrap_up_published_at,
  coalesce(
    (select count(*) from public.quests q where q.trip_id = t.id),
    0
  )::int as quest_count
from public.trips t
left join public.wrap_ups w on w.trip_id = t.id;

grant select on public.trip_card_view to authenticated;
