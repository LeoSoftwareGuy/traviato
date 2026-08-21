-- award_points() RPC + trip_card_view.stars (docs/data-model.md). Part of #27.
--
-- Down/revert notes: `drop function public.award_points(text, uuid, uuid);`
-- trip_card_view's stars column reverts to `0 as stars` (see #11).

-- set search_path = public guards against search-path hijacking in a
-- security definer function (see docs/supabase.md).
--
-- Points are derived server-side, never trusted from the client: note 1,
-- photo 2, quest 1, bonus_task per its template. The unique (user_id,
-- source, source_id) constraint on points_ledger makes the insert
-- idempotent, so the app can safely call this after every note/photo/quest/
-- bonus-task action without double-counting on retry.
create function public.award_points(
  p_source text,
  p_source_id uuid,
  p_trip_id uuid
)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_points int;
begin
  if not exists (
    select 1 from public.trips t
    where t.id = p_trip_id and t.user_id = auth.uid()
  ) then
    raise exception 'trip % not found or not owned by caller', p_trip_id;
  end if;

  if p_source = 'note' then
    if not exists (
      select 1 from public.day_notes
      where id = p_source_id and trip_id = p_trip_id
    ) then
      raise exception 'note % not found on trip %', p_source_id, p_trip_id;
    end if;
    v_points := 1;
  elsif p_source = 'photo' then
    if not exists (
      select 1 from public.photos
      where id = p_source_id and trip_id = p_trip_id
    ) then
      raise exception 'photo % not found on trip %', p_source_id, p_trip_id;
    end if;
    v_points := 2;
  elsif p_source = 'quest' then
    if not exists (
      select 1 from public.quests
      where id = p_source_id and trip_id = p_trip_id
    ) then
      raise exception 'quest % not found on trip %', p_source_id, p_trip_id;
    end if;
    v_points := 1;
  elsif p_source = 'bonus_task' then
    select bt.points into v_points
    from public.bonus_task_assignments a
    join public.bonus_task_templates bt on bt.id = a.template_id
    where a.id = p_source_id and a.trip_id = p_trip_id;

    if v_points is null then
      raise exception 'bonus task % not found on trip %', p_source_id, p_trip_id;
    end if;
  else
    raise exception 'invalid source: %', p_source;
  end if;

  insert into public.points_ledger (user_id, trip_id, source, source_id, points)
  values (auth.uid(), p_trip_id, p_source, p_source_id, v_points)
  on conflict (user_id, source, source_id) do nothing;

  return coalesce(
    (
      select sum(points) from public.points_ledger
      where trip_id = p_trip_id and user_id = auth.uid()
    ),
    0
  );
end;
$$;

grant execute on function public.award_points(text, uuid, uuid) to authenticated;

-- Replaces trip_card_view (#11) with a real stars column. photo_count and
-- expense_total stay hardcoded 0 until the issues that back them land.
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
  0::numeric(10, 2) as expense_total
from public.trips t;

grant select on public.trip_card_view to authenticated;
