-- wrap_ups table (docs/data-model.md). Part of #93.
--
-- Down/revert notes: `drop table public.wrap_ups;`

create table public.wrap_ups (
  -- One wrap-up per trip; also the FK, so no separate id column.
  trip_id uuid primary key references public.trips (id) on delete cascade,
  content jsonb,
  generated_at timestamptz,
  published_at timestamptz
);

alter table public.wrap_ups enable row level security;

create policy "wrap_ups_select_own" on public.wrap_ups
for select to authenticated
using (
  exists (
    select 1 from public.trips t
    where t.id = trip_id and t.user_id = auth.uid()
  )
);

-- No insert policy/grant: the row is created only by generate_wrap_up (#93)
-- via the service-role key, which bypasses RLS/grants entirely.
grant select on public.wrap_ups to authenticated;

-- Update policy exists only to let the owner flip `published_at` (Keep
-- forever, M4-3) directly from the client. The grant below is
-- column-scoped to `published_at` alone, so `content`/`generated_at` stay
-- writable only by the edge function's service-role client, never by a
-- client-issued update.
create policy "wrap_ups_update_own" on public.wrap_ups
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

grant update (published_at) on public.wrap_ups to authenticated;
