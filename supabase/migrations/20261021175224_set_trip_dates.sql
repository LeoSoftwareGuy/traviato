-- set_trip_dates() RPC (#271): change a memory's start/end to any valid
-- range in one step, replacing the ±1-day shift_trip_dates() (dropped
-- below — its only caller, the Manage sheet's tap/long-press, is gone).
--
-- What moves and what stays (agreed on #271):
--   - quests (the plan) move with the start date: day_date += new start −
--     old start, so "Day 2: museum" stays Day 2 when a guessed trip moves.
--   - day_notes, photos and bonus_task_assignments keep their calendar
--     date: they record what happened on a real day.
-- Anything that ends up outside [p_start, p_end] is deleted. The app shows
-- a two-step warning first, using p_dry_run = true, which runs the exact
-- same counting and changes nothing — so what the user confirms is what
-- gets deleted. Photos with no day_date aren't tied to a day and are left
-- alone. Expenses (spent_on) aren't part of the day model and are untouched.
--
-- Stars, consistent with delete_photo() (#165):
--   - a deleted plain journal photo takes back its 'photo' ✦2;
--   - a photo that completed a bonus task keeps all its stars;
--   - a deleted note takes back its 'note' ✦1;
--   - deleted quests and bonus assignments keep theirs (earned for real;
--     the ledger has no FK to them, so nothing cascades).
--
-- Returns {trip, quests, notes, photos, bonus_tasks, photo_paths}: the
-- updated trips row (null on a dry run), per-type counts of what is (or
-- would be) deleted, and the deleted photos' storage paths so the client
-- can remove the files — Postgres can't delete storage objects.
--
-- set search_path = public guards against search-path hijacking in a
-- security definer function (see docs/supabase.md).
--
-- Down/revert notes: `drop function public.set_trip_dates(uuid, date, date,
-- boolean);` and recreate shift_trip_dates from
-- 20260824174535_shift_trip_dates_rpc.sql.

create function public.set_trip_dates(
  p_trip_id uuid,
  p_start date,
  p_end date,
  p_dry_run boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_trip public.trips;
  v_delta int;
  v_quests int;
  v_notes int;
  v_photos int;
  v_bonus int;
  v_photo_paths text[];
begin
  if p_start is null or p_end is null or p_end < p_start then
    raise exception using
      errcode = '22023',
      message = 'a memory needs a start date on or before its end date';
  end if;

  select * into v_trip from public.trips
  where id = p_trip_id and user_id = auth.uid();
  if not found then
    raise exception using
      errcode = '42501',
      message = 'trip not found or not owned by caller';
  end if;

  v_delta := p_start - v_trip.start_date;

  select count(*) into v_quests from public.quests
  where trip_id = p_trip_id
    and (day_date + v_delta < p_start or day_date + v_delta > p_end);

  select count(*) into v_notes from public.day_notes
  where trip_id = p_trip_id and (day_date < p_start or day_date > p_end);

  select count(*), coalesce(array_agg(storage_path), '{}')
  into v_photos, v_photo_paths
  from public.photos
  where trip_id = p_trip_id
    and day_date is not null
    and (day_date < p_start or day_date > p_end);

  select count(*) into v_bonus from public.bonus_task_assignments
  where trip_id = p_trip_id and (day_date < p_start or day_date > p_end);

  if p_dry_run then
    return jsonb_build_object(
      'trip', null,
      'quests', v_quests,
      'notes', v_notes,
      'photos', v_photos,
      'bonus_tasks', v_bonus,
      'photo_paths', '[]'::jsonb
    );
  end if;

  -- Stars first: the rows they're keyed by are deleted below, and a
  -- bonus-completing photo is recognised through its assignment's photo_id.
  delete from public.points_ledger l
  using public.day_notes n
  where l.user_id = v_trip.user_id
    and l.source = 'note'
    and l.source_id = n.id
    and n.trip_id = p_trip_id
    and (n.day_date < p_start or n.day_date > p_end);

  delete from public.points_ledger l
  using public.photos p
  where l.user_id = v_trip.user_id
    and l.source = 'photo'
    and l.source_id = p.id
    and p.trip_id = p_trip_id
    and p.day_date is not null
    and (p.day_date < p_start or p.day_date > p_end)
    and not exists (
      select 1 from public.bonus_task_assignments a
      where a.photo_id = p.id and a.completed_at is not null
    );

  delete from public.day_notes
  where trip_id = p_trip_id and (day_date < p_start or day_date > p_end);

  delete from public.photos
  where trip_id = p_trip_id
    and day_date is not null
    and (day_date < p_start or day_date > p_end);

  delete from public.bonus_task_assignments
  where trip_id = p_trip_id and (day_date < p_start or day_date > p_end);

  delete from public.quests
  where trip_id = p_trip_id
    and (day_date + v_delta < p_start or day_date + v_delta > p_end);

  update public.quests
  set day_date = day_date + v_delta
  where trip_id = p_trip_id;

  update public.trips
  set start_date = p_start, end_date = p_end
  where id = p_trip_id
  returning * into v_trip;

  return jsonb_build_object(
    'trip', to_jsonb(v_trip),
    'quests', v_quests,
    'notes', v_notes,
    'photos', v_photos,
    'bonus_tasks', v_bonus,
    'photo_paths', to_jsonb(v_photo_paths)
  );
end;
$$;

revoke execute on function public.set_trip_dates(uuid, date, date, boolean)
  from public, anon;
grant execute on function public.set_trip_dates(uuid, date, date, boolean)
  to authenticated;

drop function public.shift_trip_dates(uuid, int);
