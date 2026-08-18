-- quests table (docs/data-model.md). Closes #14.
--
-- Down/revert notes: `drop table public.quests;`

create table public.quests (
  id uuid primary key,
  trip_id uuid not null references public.trips (id) on delete cascade,
  day_date date not null,
  time time,
  title text not null,
  place_text text,
  position int not null,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.quests enable row level security;

-- Child-table ownership pattern: access reduces to "the parent trip belongs
-- to the caller". Every later child table (day_notes, photos,
-- checklist_items, ...) reuses this same shape.
create policy "quests_select_own" on public.quests
for select to authenticated
using (
  exists (
    select 1 from public.trips t
    where t.id = trip_id and t.user_id = auth.uid()
  )
);

create policy "quests_insert_own" on public.quests
for insert to authenticated
with check (
  exists (
    select 1 from public.trips t
    where t.id = trip_id and t.user_id = auth.uid()
  )
);

create policy "quests_update_own" on public.quests
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

create policy "quests_delete_own" on public.quests
for delete to authenticated
using (
  exists (
    select 1 from public.trips t
    where t.id = trip_id and t.user_id = auth.uid()
  )
);

-- Project has auto-expose disabled: grants are required even with RLS.
grant select, insert, update, delete on public.quests to authenticated;

-- Every read is "quests of day X of trip Y".
create index quests_trip_id_day_date_idx on public.quests (trip_id, day_date);
