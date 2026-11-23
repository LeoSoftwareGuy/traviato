-- #461: films read each photo and note on the clock of the place it was
-- taken or written, not the phone's current time zone.
--
-- photos.utc_offset_minutes: the UTC offset where the photo was taken,
--   from its own metadata (EXIF OffsetTimeOriginal) or the device's at an
--   in-app capture; null = unknown (the film resolves it: the photo's GPS,
--   else the memory's zone).
-- photos.utc_offset_source: where that offset came from.
-- journal_notes.utc_offset_minutes: the device's offset when the note was
--   written; null for notes written before (the memory's zone resolves).
-- trips.time_zone: the memory's IANA zone ("Europe/Budapest"), resolved
--   once by generate_wrap_up from GPS, the country or the destination.
--
-- No backfill: SQL can't turn a place into a zone; generate_wrap_up
-- resolves it when a film opens. Rows are never rewritten.
--
-- Revert: recreate trip_card_view without time_zone, then drop the four
-- columns.

alter table public.photos
  add column utc_offset_minutes smallint
    check (utc_offset_minutes between -1080 and 1080),
  add column utc_offset_source text
    check (utc_offset_source in ('exif', 'device'));

alter table public.journal_notes
  add column utc_offset_minutes smallint
    check (utc_offset_minutes between -1080 and 1080);

alter table public.trips
  add column time_zone text
    check (time_zone is null or time_zone ~ '^[A-Za-z_]+(/[A-Za-z0-9_+-]+)*$');

-- generate_wrap_up writes the resolved zone with the service role.
grant update (time_zone) on public.trips to service_role;

-- An edit never moves a note: its offset stays as written too.
create or replace function public.journal_notes_on_update()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.trip_id := old.trip_id;
  new.taken_at := old.taken_at;
  new.legacy := old.legacy;
  new.created_at := old.created_at;
  new.utc_offset_minutes := old.utc_offset_minutes;
  new.edited_at := now();
  return new;
end;
$$;

-- The Journal and the Kept Memory page show times on the memory's clock
-- too: trip_card_view gains time_zone, appended (create or replace keeps
-- every column before it).
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
  w.published_at as wrap_up_published_at,
  coalesce(
    (select count(*) from public.quests q where q.trip_id = t.id),
    0
  )::int as quest_count,
  t.time_zone
from public.trips t
left join public.wrap_ups w on w.trip_id = t.id;

grant select on public.trip_card_view to authenticated;
