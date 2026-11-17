-- journal_notes (#400, part a of #397): a day holds many short notes, each
-- with its own time, instead of one appended text (docs/design/journal-notes/
-- JOURNAL_NOTES_OPTION_B_SPEC.md).
--
-- - day_date is the note's logical day, decided by the app when the note is
--   saved (logicalDayOf: 00:00–08:00 stays on the previous day unless there
--   was a gap of 4 h or more). Stats, achievements and the film read it.
-- - taken_at is the time shown (when Done was first tapped) and never
--   changes; edited_at follows every edit (trigger below).
-- - photo_id attaches a note to a photo of the same trip; deleting the
--   photo keeps the note.
-- - Every non-empty day_notes row is copied as one legacy note with the
--   SAME id, so ledger rows, director plans and kept films that name the
--   note keep working. day_notes becomes read-only; a later migration
--   drops it.
-- - Stars: ✦1 per new note, at most 3 note-stars per day; points_ledger
--   gains day_date to count them. Deleting a note keeps its star (spec §8,
--   replacing #276's take-back), so notes are deleted with a plain RLS
--   delete and delete_day_note() is dropped.
-- - Storyteller and profile_stats_view.notes_count count days with a note.
--
-- Down/revert notes: restore award_points, check_achievements,
-- profile_stats_view and set_trip_dates from their earlier migrations,
-- recreate delete_day_note from 20261021212557, re-grant writes on
-- day_notes, `alter table public.points_ledger drop column day_date;` and
-- `drop table public.journal_notes;`.

create table public.journal_notes (
  id uuid primary key,
  trip_id uuid not null references public.trips (id) on delete cascade,
  day_date date not null,
  taken_at timestamptz not null default now(),
  edited_at timestamptz not null default now(),
  content text not null check (content ~ '\S'),
  dictated boolean not null default false,
  photo_id uuid references public.photos (id) on delete set null,
  legacy boolean not null default false,
  created_at timestamptz not null default now()
);

create index journal_notes_trip_id_taken_at_idx
  on public.journal_notes (trip_id, taken_at);
create index journal_notes_photo_id_idx on public.journal_notes (photo_id);

alter table public.journal_notes enable row level security;

-- Owner-only via the parent trip (the day_notes pattern). A note's photo
-- must be one of the same trip's photos.
create policy "journal_notes_select_own" on public.journal_notes
for select to authenticated
using (
  exists (
    select 1 from public.trips t
    where t.id = trip_id and t.user_id = auth.uid()
  )
);

create policy "journal_notes_insert_own" on public.journal_notes
for insert to authenticated
with check (
  exists (
    select 1 from public.trips t
    where t.id = trip_id and t.user_id = auth.uid()
  )
  and (
    photo_id is null or exists (
      select 1 from public.photos p
      where p.id = photo_id and p.trip_id = journal_notes.trip_id
    )
  )
);

create policy "journal_notes_update_own" on public.journal_notes
for update to authenticated
using (
  exists (
    select 1 from public.trips t
    where t.id = trip_id and t.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.trips t
    where t.id = trip_id and t.user_id = auth.uid()
  )
  and (
    photo_id is null or exists (
      select 1 from public.photos p
      where p.id = photo_id and p.trip_id = journal_notes.trip_id
    )
  )
);

create policy "journal_notes_delete_own" on public.journal_notes
for delete to authenticated
using (
  exists (
    select 1 from public.trips t
    where t.id = trip_id and t.user_id = auth.uid()
  )
);

-- Project has auto-expose disabled: grants are required even with RLS.
grant select, insert, update, delete on public.journal_notes to authenticated;
-- generate_wrap_up reads notes with the service role.
grant select on public.journal_notes to service_role;

-- Edits never move a note: its trip, time and legacy flag stay; edited_at
-- follows the edit.
create function public.journal_notes_on_update()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.trip_id := old.trip_id;
  new.taken_at := old.taken_at;
  new.legacy := old.legacy;
  new.created_at := old.created_at;
  new.edited_at := now();
  return new;
end;
$$;

create trigger journal_notes_on_update
before update on public.journal_notes
for each row execute function public.journal_notes_on_update();

-- Legacy copy: one note per non-empty old day note, same id, text unchanged,
-- shown at its last-edited time.
insert into public.journal_notes
  (id, trip_id, day_date, taken_at, edited_at, content, dictated, legacy,
   created_at)
select id, trip_id, day_date, updated_at, updated_at, content, false, true,
  created_at
from public.day_notes
where content ~ '\S';

-- The ledger's note rows learn their day, for the 3-per-day cap.
alter table public.points_ledger add column day_date date;

update public.points_ledger l
set day_date = n.day_date
from public.day_notes n
where l.source = 'note' and l.source_id = n.id;

-- day_notes is read-only for one release, then dropped.
revoke insert, update, delete on public.day_notes from authenticated;
drop function public.delete_day_note(uuid);

create or replace function public.award_points(
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
  v_day date;
begin
  if not exists (
    select 1 from public.trips t
    where t.id = p_trip_id and t.user_id = auth.uid()
  ) then
    raise exception 'trip % not found or not owned by caller', p_trip_id;
  end if;

  if p_source = 'note' then
    select n.day_date into v_day from public.journal_notes n
    where n.id = p_source_id and n.trip_id = p_trip_id;
    if not found then
      raise exception 'note % not found on trip %', p_source_id, p_trip_id;
    end if;
    v_points := 1;
    -- At most 3 note-stars per day. A deleted note's row stays in the
    -- ledger, so deleting and rewriting can't farm stars. A note that
    -- already has its star falls through to the no-op insert below.
    if not exists (
      select 1 from public.points_ledger
      where user_id = auth.uid() and source = 'note'
        and source_id = p_source_id
    ) and (
      select count(*) from public.points_ledger
      where user_id = auth.uid() and trip_id = p_trip_id
        and source = 'note' and day_date = v_day
    ) >= 3 then
      v_points := null;
    end if;
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

  if v_points is not null then
    insert into public.points_ledger
      (user_id, trip_id, source, source_id, points, day_date)
    values (auth.uid(), p_trip_id, p_source, p_source_id, v_points, v_day)
    on conflict (user_id, source, source_id) do nothing;
  end if;

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

create or replace function public.check_achievements()
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
          select trip_id, day_date from public.journal_notes
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
        -- Days with at least one note, not notes (#397): many short
        -- notes on one day count once.
        select count(*)
        from (
          select distinct jn.trip_id, jn.day_date
          from public.journal_notes jn
          join public.trips t on t.id = jn.trip_id
          where t.user_id = v_user
        ) note_days
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
      select trip_id, day_date from public.journal_notes
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
    from (
      select distinct jn.trip_id, jn.day_date
      from public.journal_notes jn
      join public.trips t on t.id = jn.trip_id
      where t.user_id = p.id
    ) note_days
  ) as notes_count
from public.profiles p;

grant select on public.profile_stats_view to authenticated;

create or replace function public.set_trip_dates(
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

  select count(*) into v_notes from public.journal_notes
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
  -- By the ledger's own day, so the stars of notes deleted earlier on an
  -- out-of-range day go too.
  delete from public.points_ledger l
  where l.user_id = v_trip.user_id
    and l.trip_id = p_trip_id
    and l.source = 'note'
    and (l.day_date < p_start or l.day_date > p_end);

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

  delete from public.journal_notes
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
