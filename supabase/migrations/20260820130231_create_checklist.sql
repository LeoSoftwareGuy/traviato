-- checklist_items + checklist_suggestions tables (docs/data-model.md). Closes #21.
--
-- Down/revert notes: `drop table public.checklist_items; drop table
-- public.checklist_suggestions;`

create table public.checklist_items (
  id uuid primary key,
  trip_id uuid not null references public.trips (id) on delete cascade,
  title text not null,
  category text not null,
  is_essential boolean not null default false,
  is_checked boolean not null default false,
  position int not null,
  constraint checklist_items_category_check check (
    category in (
      'travel_essentials',
      'clothing_shoes',
      'toiletries_health',
      'gadgets_tech',
      'nice_to_haves'
    )
  )
);

alter table public.checklist_items enable row level security;

-- Child-table ownership pattern from quests (#14): access reduces to "the
-- parent trip belongs to the caller".
create policy "checklist_items_select_own" on public.checklist_items
for select to authenticated
using (
  exists (
    select 1 from public.trips t
    where t.id = trip_id and t.user_id = auth.uid()
  )
);

create policy "checklist_items_insert_own" on public.checklist_items
for insert to authenticated
with check (
  exists (
    select 1 from public.trips t
    where t.id = trip_id and t.user_id = auth.uid()
  )
);

create policy "checklist_items_update_own" on public.checklist_items
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

create policy "checklist_items_delete_own" on public.checklist_items
for delete to authenticated
using (
  exists (
    select 1 from public.trips t
    where t.id = trip_id and t.user_id = auth.uid()
  )
);

-- Project has auto-expose disabled: grants are required even with RLS.
grant select, insert, update, delete on public.checklist_items to authenticated;

-- Every read is "checklist items of trip X".
create index checklist_items_trip_id_idx on public.checklist_items (trip_id);

-- Global suggestions catalog (seeded in a follow-up migration). Read-only
-- from the client; no owner column since it is not per-trip data.
create table public.checklist_suggestions (
  id bigint generated always as identity primary key,
  title text not null,
  category text not null,
  is_essential boolean not null default false,
  constraint checklist_suggestions_category_check check (
    category in (
      'travel_essentials',
      'clothing_shoes',
      'toiletries_health',
      'gadgets_tech',
      'nice_to_haves'
    )
  )
);

alter table public.checklist_suggestions enable row level security;

-- Deny-by-default: only a select policy is defined, so inserts/updates/
-- deletes remain blocked for every role including authenticated.
create policy "checklist_suggestions_select_all" on public.checklist_suggestions
for select to authenticated
using (true);

grant select on public.checklist_suggestions to authenticated;
