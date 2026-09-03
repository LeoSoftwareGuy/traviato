-- Adds photos_count/notes_count to profile_stats_view (docs/data-model.md).
-- Part of #96 — the Profile achievements grid needs a current value to show
-- progress against for the two achievements whose metric is 'photos'
-- (shutterbug) or 'notes' (storyteller); the view didn't carry either
-- before now. check_achievements()'s own per-metric aggregation is left
-- untouched — award-eligibility and display stay independently correct
-- (see that migration's comment).
--
-- Down/revert notes: `create or replace view` back to the #95 shape (drop
-- the two columns below).

create or replace view public.profile_stats_view
with (security_invoker = true) as
select
  p.id as user_id,
  (
    select count(*) from public.trips t
    where t.user_id = p.id
  ) as memories_count,
  (
    select count(distinct place_text)
    from (
      select q.place_text
      from public.quests q
      join public.trips t on t.id = q.trip_id
      where t.user_id = p.id and q.place_text is not null
      union
      select ph.place_text
      from public.photos ph
      join public.trips t on t.id = ph.trip_id
      where t.user_id = p.id and ph.place_text is not null
    ) places
  ) as places_count,
  (
    select count(distinct t.country_code) from public.trips t
    where t.user_id = p.id and t.country_code is not null
  ) as countries_count,
  (
    select count(distinct d.day_date)
    from (
      select trip_id, day_date from public.day_notes
      union
      select trip_id, day_date from public.photos where day_date is not null
    ) d
    join public.trips t on t.id = d.trip_id
    where t.user_id = p.id
  ) as days_logged,
  coalesce(
    (
      select sum(pl.points) from public.points_ledger pl
      where pl.user_id = p.id
    ),
    0
  ) as stars_total,
  (
    select count(*)
    from public.photos ph
    join public.trips t on t.id = ph.trip_id
    where t.user_id = p.id
  ) as photos_count,
  (
    select count(*)
    from public.day_notes dn
    join public.trips t on t.id = dn.trip_id
    where t.user_id = p.id
  ) as notes_count
from public.profiles p;

grant select on public.profile_stats_view to authenticated;
