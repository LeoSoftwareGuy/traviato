-- trips table + trip_card_view (docs/data-model.md). Closes #11.
--
-- Down/revert notes: `drop view public.trip_card_view; drop trigger
-- trips_set_updated_at on public.trips; drop function
-- public.set_updated_at(); drop table public.trips;`

create table public.trips (
  id uuid primary key,
  user_id uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  destination text,
  country_code text,
  start_date date,
  end_date date,
  vibes text[] not null default '{}',
  cover_image_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint trips_end_date_after_start_date check (
    end_date is null or start_date is null or end_date >= start_date
  )
);

-- No count check on `vibes` — open question in data-model.md; app enforces UX.

alter table public.trips enable row level security;

create policy "trips_select_own" on public.trips
for select to authenticated
using (user_id = auth.uid());

create policy "trips_insert_own" on public.trips
for insert to authenticated
with check (user_id = auth.uid());

create policy "trips_update_own" on public.trips
for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "trips_delete_own" on public.trips
for delete to authenticated
using (user_id = auth.uid());

-- Project has auto-expose disabled: grants are required even with RLS.
grant select, insert, update, delete on public.trips to authenticated;

-- set search_path = public guards against search-path hijacking in a
-- security definer function (see docs/supabase.md).
create function public.set_updated_at()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger trips_set_updated_at
before update on public.trips
for each row execute function public.set_updated_at();

-- trip_card_view feeds Home. `photo_count`, `stars` and `expense_total` are
-- hardcoded 0 until the photos (#M3-1), points_ledger (#M3-3) and expenses
-- (#M3-4) tables exist — those migrations replace this view (create or
-- replace view) to join the real aggregates in, leaving every other column
-- unchanged.
create view public.trip_card_view
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
  0 as photo_count,
  0 as stars,
  0::numeric(10, 2) as expense_total
from public.trips t;

grant select on public.trip_card_view to authenticated;
