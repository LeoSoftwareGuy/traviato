-- shift_trip_dates() RPC (docs/design/README.md Shared: Manage memory
-- sheet). Atomically shifts a trip's start/end dates and every one of its
-- quests' day_date by the same delta, so "tap a date to shift it a day"
-- always keeps quests aligned to their day. day_notes/photos already exist
-- as tables (#25) but re-dating them isn't in this issue's acceptance
-- criteria — noted seam for whenever that's scoped.
--
-- Down/revert notes: `drop function public.shift_trip_dates(uuid, int);`

-- set search_path = public guards against search-path hijacking in a
-- security definer function (see docs/supabase.md).
create function public.shift_trip_dates(
  p_trip_id uuid,
  p_delta_days int
)
returns public.trips
language plpgsql
security definer
set search_path = public
as $$
declare
  v_trip public.trips;
begin
  select * into v_trip from public.trips
  where id = p_trip_id and user_id = auth.uid();

  if not found then
    raise exception 'trip % not found or not owned by caller', p_trip_id;
  end if;
  if v_trip.start_date is null or v_trip.end_date is null then
    raise exception 'trip % has no date range to shift', p_trip_id;
  end if;

  update public.quests
  set day_date = day_date + p_delta_days
  where trip_id = p_trip_id;

  update public.trips
  set start_date = start_date + p_delta_days,
      end_date = end_date + p_delta_days
  where id = p_trip_id
  returning * into v_trip;

  return v_trip;
end;
$$;

grant execute on function public.shift_trip_dates(uuid, int) to authenticated;
