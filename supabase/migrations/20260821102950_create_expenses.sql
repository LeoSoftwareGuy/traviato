-- expenses table (docs/data-model.md). Closes #28.
--
-- Down/revert notes: `drop table public.expenses;`

create table public.expenses (
  id uuid primary key,
  trip_id uuid not null references public.trips (id) on delete cascade,
  title text not null,
  -- EUR-only MVP: no currency column, per data-model.md.
  amount numeric(10, 2) not null check (amount > 0),
  category text not null check (
    category in (
      'food_drinks',
      'transport',
      'accommodation',
      'activities',
      'shopping',
      'other'
    )
  ),
  spent_on date not null,
  created_at timestamptz not null default now()
);

alter table public.expenses enable row level security;

-- Child-table ownership pattern from quests (#14) / checklist_items (#21) /
-- day_notes (#25).
create policy "expenses_select_own" on public.expenses
for select to authenticated
using (
  exists (
    select 1 from public.trips t
    where t.id = trip_id and t.user_id = auth.uid()
  )
);

create policy "expenses_insert_own" on public.expenses
for insert to authenticated
with check (
  exists (
    select 1 from public.trips t
    where t.id = trip_id and t.user_id = auth.uid()
  )
);

create policy "expenses_update_own" on public.expenses
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

create policy "expenses_delete_own" on public.expenses
for delete to authenticated
using (
  exists (
    select 1 from public.trips t
    where t.id = trip_id and t.user_id = auth.uid()
  )
);

-- Project has auto-expose disabled: grants are required even with RLS.
grant select, insert, update, delete on public.expenses to authenticated;

-- Every read is "the expenses for trip X".
create index expenses_trip_id_idx on public.expenses (trip_id);
