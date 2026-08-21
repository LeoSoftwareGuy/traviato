-- profile_stats_view (docs/data-model.md). Part of #27.
--
-- Down/revert notes: `drop view public.profile_stats_view;`
--
-- Feeds the Home stats bar and the profile screen (#M4-4). Achievement
-- progress for photos/notes metrics is computed independently inside
-- check_achievements() (#27), not from this view — see that migration's
-- comment.

create view public.profile_stats_view
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
  ) as stars_total
from public.profiles p;

grant select on public.profile_stats_view to authenticated;
