-- expense_summary_view + trip_card_view.expense_total (docs/data-model.md).
-- Closes #28.
--
-- Down/revert notes: `drop view public.expense_summary_view;`
-- trip_card_view's expense_total column reverts to `0::numeric(10, 2) as
-- expense_total` (see #11).

-- Feeds the Expenses tab's per-memory totals list.
create view public.expense_summary_view
with (security_invoker = true) as
select
  t.id as trip_id,
  coalesce(sum(e.amount), 0)::numeric(10, 2) as total_amount,
  count(e.id) as item_count
from public.trips t
left join public.expenses e on e.trip_id = t.id
group by t.id;

grant select on public.expense_summary_view to authenticated;

-- Replaces trip_card_view (#11, stars added in #27) with a real
-- expense_total. photo_count stays hardcoded 0 until its issue lands.
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
  0 as photo_count,
  coalesce(
    (select sum(pl.points) from public.points_ledger pl where pl.trip_id = t.id),
    0
  )::int as stars,
  coalesce(
    (select sum(e.amount) from public.expenses e where e.trip_id = t.id),
    0
  )::numeric(10, 2) as expense_total
from public.trips t;

grant select on public.trip_card_view to authenticated;
