-- #281: kept memories now open the Kept Memory page straight from Home, so
-- the film-first rule from #279 — and trips.film_seen_at, which tracked it —
-- is gone. Nothing reads or writes the column any more.
--
-- `create or replace view` can't remove a column, so trip_card_view is
-- dropped and recreated in its pre-#279 shape (20260913092519) before the
-- column goes. Nothing depends on the view (no other view, function or
-- policy selects from it), so no cascade. Both statements run in the
-- migration's transaction: readers never see the view missing.
--
-- Down/revert notes: re-run 20261022153917_add_trips_film_seen_at.sql's
-- body (add column, backfill, `create or replace view` with film_seen_at
-- appended, grant).

drop view public.trip_card_view;

alter table public.trips drop column film_seen_at;

create view public.trip_card_view
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
