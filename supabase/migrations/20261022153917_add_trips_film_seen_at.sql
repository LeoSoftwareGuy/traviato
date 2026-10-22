-- #279: the Kept Memory page. A kept memory's first open plays its wrap-up
-- film; every open after that goes straight to /memory/:tripId. This column
-- records when the film was first watched through (the first full pass, or
-- leaving after more than half of it), so Home knows which way a tap goes.
--
-- "Kept" stays derived from wrap_ups.published_at — no new flag. Memories
-- already kept when this lands are backfilled as seen: their owners watched
-- the film to keep it.
--
-- Written by the owner with a plain update (trips_update_own + the existing
-- update grant); the client only ever sets it once (`where film_seen_at is
-- null`).
--
-- trip_card_view gains film_seen_at as its LAST column — `create or replace
-- view` can only append columns.
--
-- Down/revert notes: `create or replace view` can't drop a column, so drop
-- and recreate trip_card_view in the 20260913092519 shape (re-granting
-- select to authenticated), then
-- `alter table public.trips drop column film_seen_at;`.

alter table public.trips add column film_seen_at timestamptz;

update public.trips t
set film_seen_at = now()
from public.wrap_ups w
where w.trip_id = t.id
  and w.published_at is not null;

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
  )::int as quest_count,
  t.film_seen_at
from public.trips t
left join public.wrap_ups w on w.trip_id = t.id;

grant select on public.trip_card_view to authenticated;
