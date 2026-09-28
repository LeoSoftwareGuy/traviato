-- Block quest planning on memories logged after their trip had ended (#164).
-- Such a memory never had a planning phase, so new quests would only be
-- fabricated post-hoc "plans". The app never offers it (the Journal's
-- "To Do" and Plan's add row are hidden via TripCardEntity.isPastCreated);
-- this trigger is the defense-in-depth guard against direct API calls, the
-- same pattern as the #139 limit triggers.
--
-- Custom SQLSTATE so the client branches on PostgrestException.code, never
-- on message text (guidelines doc 04):
--   TRV04 — quest insert on a past-created trip
--
-- One day of grace: the client's rule compares end_date to created_at's
-- LOCAL date, but the server only knows created_at in UTC. Without the
-- grace, a memory created on the last evening of a trip in a UTC−x zone
-- (already "tomorrow" in UTC) would be wrongly blocked. With it, the server
-- is always at least as permissive as the client.
--
-- Insert only: updates (check-off, edit, shift_trip_dates re-dating) and
-- deletes on existing quests are untouched, so quests that already exist on
-- a past-created trip keep working.
--
-- set search_path = public guards against search-path hijacking in a
-- security definer function (see docs/supabase.md).
--
-- Down/revert notes: `drop trigger quests_block_past_created_trips on
-- public.quests; drop function public.block_quests_on_past_created_trips();`

create function public.block_quests_on_past_created_trips()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_end_date date;
  v_created_at timestamptz;
begin
  select end_date, created_at into v_end_date, v_created_at
  from public.trips
  where id = new.trip_id;

  if v_end_date is not null
     and v_end_date < (v_created_at at time zone 'utc')::date - 1 then
    raise exception using
      errcode = 'TRV04',
      message = 'This memory was logged after the trip ended, so quests can''t be added.';
  end if;

  return new;
end;
$$;

create trigger quests_block_past_created_trips
before insert on public.quests
for each row execute function public.block_quests_on_past_created_trips();
