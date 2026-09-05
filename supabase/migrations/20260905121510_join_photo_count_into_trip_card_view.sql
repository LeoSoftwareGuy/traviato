-- Replaces trip_card_view's hardcoded `0 as photo_count` with a real count
-- (docs/data-model.md). Part of #105 — the photos table has existed since
-- M3-1, and the stars/expense_total columns were already switched from
-- their #11 placeholder to real aggregates (#27, #M3-4), but photo_count
-- was carried forward unchanged through every later `create or replace
-- view` on this view, including #95's most recent one.
--
-- Down/revert notes: `create or replace view` back to the #95 shape
-- (`0 as photo_count`).

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
  w.published_at as wrap_up_published_at
from public.trips t
left join public.wrap_ups w on w.trip_id = t.id;

grant select on public.trip_card_view to authenticated;
