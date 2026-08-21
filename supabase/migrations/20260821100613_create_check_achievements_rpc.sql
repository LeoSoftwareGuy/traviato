-- check_achievements() RPC (docs/data-model.md). Part of #27.
--
-- Down/revert notes: `drop function public.check_achievements();`

-- set search_path = public guards against search-path hijacking in a
-- security definer function (see docs/supabase.md).
--
-- Computes each metric directly rather than reading profile_stats_view
-- (#27) — keeps the view (a display concern) and this RPC (an award
-- concern) independently correct if either changes shape later, at the
-- cost of a little duplicated aggregation.
create function public.check_achievements()
returns text[]
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_newly_earned text[] := '{}';
  v_template record;
  v_metric_value numeric;
begin
  for v_template in select * from public.achievement_templates loop
    if exists (
      select 1 from public.user_achievements ua
      where ua.user_id = v_user and ua.template_id = v_template.id
    ) then
      continue;
    end if;

    v_metric_value := case v_template.metric
      when 'trips' then (
        select count(*) from public.trips
        where user_id = v_user
      )
      when 'countries' then (
        select count(distinct country_code) from public.trips
        where user_id = v_user and country_code is not null
      )
      when 'days_logged' then (
        select count(distinct d.day_date)
        from (
          select trip_id, day_date from public.day_notes
          union
          select trip_id, day_date from public.photos where day_date is not null
        ) d
        join public.trips t on t.id = d.trip_id
        where t.user_id = v_user
      )
      when 'stars' then (
        select coalesce(sum(points), 0) from public.points_ledger
        where user_id = v_user
      )
      when 'photos' then (
        select count(*)
        from public.photos ph
        join public.trips t on t.id = ph.trip_id
        where t.user_id = v_user
      )
      when 'notes' then (
        select count(*)
        from public.day_notes dn
        join public.trips t on t.id = dn.trip_id
        where t.user_id = v_user
      )
    end;

    if v_metric_value >= v_template.target then
      insert into public.user_achievements (user_id, template_id)
      values (v_user, v_template.id)
      on conflict do nothing;
      v_newly_earned := array_append(v_newly_earned, v_template.code);
    end if;
  end loop;

  return v_newly_earned;
end;
$$;

grant execute on function public.check_achievements() to authenticated;
