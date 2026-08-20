-- day_notes + photos tables (docs/data-model.md). Closes #25.
--
-- Down/revert notes: `drop table public.photos; drop trigger
-- day_notes_set_updated_at on public.day_notes; drop table public.day_notes;`

create table public.day_notes (
  id uuid primary key,
  trip_id uuid not null references public.trips (id) on delete cascade,
  day_date date not null,
  content text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- One note per day, edited in place rather than appended.
  unique (trip_id, day_date)
);

alter table public.day_notes enable row level security;

-- Child-table ownership pattern from quests (#14) / checklist_items (#21).
create policy "day_notes_select_own" on public.day_notes
for select to authenticated
using (
  exists (
    select 1 from public.trips t
    where t.id = trip_id and t.user_id = auth.uid()
  )
);

create policy "day_notes_insert_own" on public.day_notes
for insert to authenticated
with check (
  exists (
    select 1 from public.trips t
    where t.id = trip_id and t.user_id = auth.uid()
  )
);

create policy "day_notes_update_own" on public.day_notes
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
);

create policy "day_notes_delete_own" on public.day_notes
for delete to authenticated
using (
  exists (
    select 1 from public.trips t
    where t.id = trip_id and t.user_id = auth.uid()
  )
);

-- Project has auto-expose disabled: grants are required even with RLS.
grant select, insert, update, delete on public.day_notes to authenticated;

-- Every read is "the note for day X of trip Y".
create index day_notes_trip_id_day_date_idx on public.day_notes (trip_id, day_date);

-- public.set_updated_at() already exists from the trips migration (#11).
create trigger day_notes_set_updated_at
before update on public.day_notes
for each row execute function public.set_updated_at();

create table public.photos (
  -- Client-generated so the upload flow can name the storage object before
  -- the row exists (path convention: {user_id}/{trip_id}/{photo_id}.{ext}).
  id uuid primary key,
  trip_id uuid not null references public.trips (id) on delete cascade,
  day_date date,
  storage_path text not null,
  caption text,
  lat double precision,
  lng double precision,
  place_text text,
  people_tags text[] not null default '{}',
  taken_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.photos enable row level security;

create policy "photos_select_own" on public.photos
for select to authenticated
using (
  exists (
    select 1 from public.trips t
    where t.id = trip_id and t.user_id = auth.uid()
  )
);

create policy "photos_insert_own" on public.photos
for insert to authenticated
with check (
  exists (
    select 1 from public.trips t
    where t.id = trip_id and t.user_id = auth.uid()
  )
);

create policy "photos_update_own" on public.photos
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
);

create policy "photos_delete_own" on public.photos
for delete to authenticated
using (
  exists (
    select 1 from public.trips t
    where t.id = trip_id and t.user_id = auth.uid()
  )
);

grant select, insert, update, delete on public.photos to authenticated;

-- Every read is "the photos for day X of trip Y" (or all photos of trip Y
-- when day_date is null, e.g. the wrap-up gathering step).
create index photos_trip_id_day_date_idx on public.photos (trip_id, day_date);
