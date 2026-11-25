-- #468: the Journal is the truth for a memory filled in after the trip.
--
-- 1. photos.utc_offset_source gains 'wall': taken_at holds the EXIF wall
--    clock (as UTC fields) of a photo whose file has no offset, its zone
--    unknown at upload. generate_wrap_up resolves it once — the photo's
--    GPS zone, else the memory's, else the phone's — and writes back the
--    real instant with its offset and where that came from ('gps',
--    'place', 'phone'), so no naive local time is ever stored as UTC.
-- 2. "Edit time" on a note: set_journal_note_time sets when it happened,
--    on its own Journal day (or that night, before 08:00). Ordinary edits
--    still never move a note: the update trigger keeps taken_at and the
--    offset unless this function is the one updating.
--
-- Revert: restore the check to ('exif', 'device') once no row holds the
-- new values, revoke the service-role column grant, drop
-- set_journal_note_time and restore journal_notes_on_update from
-- 20261123175044.

alter table public.photos
  drop constraint photos_utc_offset_source_check,
  add constraint photos_utc_offset_source_check
    check (utc_offset_source in ('exif', 'device', 'wall', 'gps', 'place', 'phone'));

-- generate_wrap_up resolves a wall-clock photo's time with the service role.
grant update (taken_at, utc_offset_minutes, utc_offset_source)
  on public.photos to service_role;

create or replace function public.journal_notes_on_update()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.trip_id := old.trip_id;
  new.legacy := old.legacy;
  new.created_at := old.created_at;
  -- Only "Edit time" (set_journal_note_time) moves a note in its day.
  if coalesce(current_setting('traviato.note_time', true), '') <> 'on' then
    new.taken_at := old.taken_at;
    new.utc_offset_minutes := old.utc_offset_minutes;
  end if;
  new.edited_at := now();
  return new;
end;
$$;

-- When the note happened, on its own Journal day: [p_taken_at] at the
-- place's offset [p_utc_offset_minutes] must fall on the note's day_date,
-- or the night after it before 08:00 (the logical-day rule). RLS decides
-- whose notes can be changed (security invoker).
create function public.set_journal_note_time(
  p_note_id uuid,
  p_taken_at timestamptz,
  p_utc_offset_minutes smallint
)
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_day date;
  v_local timestamp;
begin
  if p_utc_offset_minutes is null
    or p_utc_offset_minutes not between -1080 and 1080 then
    raise exception 'invalid offset' using errcode = '22023';
  end if;
  select day_date into v_day from public.journal_notes where id = p_note_id;
  if not found then
    raise exception 'note not found' using errcode = 'P0002';
  end if;
  v_local := (p_taken_at at time zone 'UTC')
    + make_interval(mins => p_utc_offset_minutes);
  if not (
    v_local::date = v_day
    or (v_local::date = v_day + 1 and extract(hour from v_local) < 8)
  ) then
    raise exception 'the time is not on the note''s day' using errcode = '22023';
  end if;
  perform set_config('traviato.note_time', 'on', true);
  update public.journal_notes
    set taken_at = p_taken_at,
        utc_offset_minutes = p_utc_offset_minutes
    where id = p_note_id;
  perform set_config('traviato.note_time', '', true);
end;
$$;

revoke all on function public.set_journal_note_time(uuid, timestamptz, smallint)
  from public, anon;
grant execute on function public.set_journal_note_time(uuid, timestamptz, smallint)
  to authenticated;
