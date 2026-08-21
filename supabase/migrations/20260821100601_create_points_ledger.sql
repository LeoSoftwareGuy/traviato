-- points_ledger table (docs/data-model.md). Part of #27.
--
-- Down/revert notes: `drop table public.points_ledger;`

create table public.points_ledger (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles (id) on delete cascade,
  trip_id uuid references public.trips (id) on delete set null,
  source text not null check (source in ('note', 'photo', 'quest', 'bonus_task')),
  source_id uuid not null,
  points int not null check (points > 0),
  created_at timestamptz not null default now(),
  -- Idempotency guard: the same source row can never be awarded twice.
  unique (user_id, source, source_id)
);

alter table public.points_ledger enable row level security;

-- Deny-by-default beyond select: no insert/update/delete policy is defined
-- here (or granted below), so the ledger can only ever be written by the
-- security-definer award_points() RPC (#27), never directly by a client.
create policy "points_ledger_select_own" on public.points_ledger
for select to authenticated
using (user_id = auth.uid());

-- Only select is granted — see the no-write-policy note above.
grant select on public.points_ledger to authenticated;

-- Every read is "this trip's stars" or "this user's total stars".
create index points_ledger_trip_id_idx on public.points_ledger (trip_id);
create index points_ledger_user_id_idx on public.points_ledger (user_id);
