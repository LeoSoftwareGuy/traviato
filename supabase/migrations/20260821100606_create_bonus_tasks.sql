-- bonus_task_templates + bonus_task_assignments tables (docs/data-model.md).
-- Part of #27.
--
-- Down/revert notes: `drop table public.bonus_task_assignments; drop table
-- public.bonus_task_templates;`

-- Global catalog (seeded in a follow-up migration). Read-only from the
-- client, same shape as checklist_suggestions (#21).
--
-- `trigger` has no fixed taxonomy in data-model.md yet — issuing logic is
-- M3-7's job, this migration only stores the field. Proposed values:
-- 'trip_start' (issued at the start of the trip) and 'random' (issued at a
-- random point during the trip).
create table public.bonus_task_templates (
  id bigint generated always as identity primary key,
  title text not null,
  description text not null,
  points int not null check (points > 0),
  duration_hours int not null check (duration_hours > 0),
  trigger text not null check (trigger in ('trip_start', 'random'))
);

alter table public.bonus_task_templates enable row level security;

create policy "bonus_task_templates_select_all" on public.bonus_task_templates
for select to authenticated
using (true);

grant select on public.bonus_task_templates to authenticated;

create table public.bonus_task_assignments (
  id uuid primary key,
  trip_id uuid not null references public.trips (id) on delete cascade,
  template_id bigint not null references public.bonus_task_templates (id),
  status text not null default 'pending' check (
    status in ('pending', 'completed', 'dismissed', 'expired')
  ),
  expires_at timestamptz not null,
  -- Proof photo for completion; the assignment survives its proof photo
  -- being deleted (photo detail/tagging isn't in MVP scope yet).
  photo_id uuid references public.photos (id) on delete set null,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.bonus_task_assignments enable row level security;

-- Child-table ownership pattern from quests (#14). Completion awards stars
-- via award_points('bonus_task', assignment.id, trip_id) (#27) — no DB
-- trigger, the app calls the RPC explicitly like it does for notes/photos/
-- quests.
create policy "bonus_task_assignments_select_own" on public.bonus_task_assignments
for select to authenticated
using (
  exists (
    select 1 from public.trips t
    where t.id = trip_id and t.user_id = auth.uid()
  )
);

create policy "bonus_task_assignments_insert_own" on public.bonus_task_assignments
for insert to authenticated
with check (
  exists (
    select 1 from public.trips t
    where t.id = trip_id and t.user_id = auth.uid()
  )
);

create policy "bonus_task_assignments_update_own" on public.bonus_task_assignments
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

create policy "bonus_task_assignments_delete_own" on public.bonus_task_assignments
for delete to authenticated
using (
  exists (
    select 1 from public.trips t
    where t.id = trip_id and t.user_id = auth.uid()
  )
);

grant select, insert, update, delete on public.bonus_task_assignments to authenticated;

-- Every read is "the bonus tasks for trip X".
create index bonus_task_assignments_trip_id_idx on public.bonus_task_assignments (trip_id);
