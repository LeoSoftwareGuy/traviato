-- Wrap-Up Film v2, part 1: the Director (#328,
-- docs/design/wrap-up-film-v2-design.md).
--
-- photo_analysis caches what the vision call saw in each photo, so a
-- rebuild only analyses new photos. One row per photo; storage_path is the
-- path that was analysed — a different path on the photo means re-analyse.
-- Only what is visible is stored: never names, identities, ages, ethnicity
-- or relationships (people is a count bucket, nothing more).
--
-- wrap_ups.director holds the last director run for the memory: the plan
-- (plan_version 2) or why it fell back, token usage and estimated cost.
-- generate_wrap_up merges a valid plan into a draft's content; the dev Plan
-- inspector reads it.
--
-- Both are written only by generate_wrap_up's service-role client. The
-- owner can read them (RLS via the parent trip), never write them.
--
-- Down/revert notes: `drop table public.photo_analysis; alter table
-- public.wrap_ups drop column director;`

create table public.photo_analysis (
  photo_id uuid primary key references public.photos (id) on delete cascade,
  trip_id uuid not null references public.trips (id) on delete cascade,
  storage_path text not null,
  summary text not null check (char_length(summary) <= 200),
  setting text not null check (
    setting in (
      'indoor', 'outdoor', 'night-out', 'nature', 'city', 'venue', 'home',
      'other'
    )
  ),
  people text not null check (
    people in ('0', '1', '2', 'small_group', 'crowd')
  ),
  energy text not null check (energy in ('calm', 'medium', 'high')),
  quality text not null check (quality in ('sharp', 'soft', 'blurry', 'dark')),
  orientation text not null check (
    orientation in ('portrait', 'landscape', 'square')
  ),
  hero_score smallint not null check (hero_score between 1 and 5),
  dup_group text,
  model text not null,
  analysed_at timestamptz not null default now()
);

create index photo_analysis_trip_id_idx on public.photo_analysis (trip_id);

alter table public.photo_analysis enable row level security;

create policy "photo_analysis_select_own" on public.photo_analysis
for select to authenticated
using (
  exists (
    select 1 from public.trips t
    where t.id = trip_id and t.user_id = auth.uid()
  )
);

-- No insert/update/delete policy or grant for authenticated: rows come only
-- from generate_wrap_up. Auto-expose is disabled, so grants are explicit.
grant select on public.photo_analysis to authenticated;
grant select, insert, update, delete on public.photo_analysis to service_role;

-- Readable by the owner through the existing table-level select grant on
-- wrap_ups; the client's update grant stays published_at only.
alter table public.wrap_ups add column director jsonb;
