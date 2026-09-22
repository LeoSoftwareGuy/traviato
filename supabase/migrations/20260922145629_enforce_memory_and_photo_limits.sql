-- Server-side free-tier limit enforcement (#139, M6-3). The app-side checks
-- (trip_mutations.dart's memory-count check, and the new mirror for photos)
-- are only the first line of defense for instant UX feedback — a determined
-- user can bypass them via direct API calls, so these triggers are the real
-- guard, keyed off is_pro() (#137).
--
-- Custom SQLSTATEs (not the default P0001) so the client can branch on
-- PostgrestException.code the same way it already does for 42501/PGRST116
-- (guidelines doc 04) — never by parsing message text:
--   TRV01 — free-tier memory cap (trips insert, count >= 3, not pro)
--   TRV02 — free-tier photo cap (photos insert, count >= 40, not pro)
--   TRV03 — 2,000/memory hard technical ceiling, both tiers (abuse/
--           performance guard — deliberately generic copy, never framed as
--           an upsell, since paying doesn't raise this one)
--
-- set search_path = public guards against search-path hijacking in a
-- security definer function (see docs/supabase.md).
--
-- Down/revert notes: `drop trigger photos_enforce_limits on public.photos;
-- drop function public.enforce_photo_limits();
-- drop trigger trips_enforce_free_tier_limit on public.trips;
-- drop function public.enforce_trip_free_tier_limit();`

create function public.enforce_trip_free_tier_limit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  existing_count integer;
begin
  if public.is_pro(new.user_id) then
    return new;
  end if;

  select count(*) into existing_count
  from public.trips
  where user_id = new.user_id;

  if existing_count >= 3 then
    raise exception using
      errcode = 'TRV01',
      message = 'Free plan is limited to 3 memories. Upgrade to Pro for unlimited memories.';
  end if;

  return new;
end;
$$;

create trigger trips_enforce_free_tier_limit
before insert on public.trips
for each row execute function public.enforce_trip_free_tier_limit();

create function public.enforce_photo_limits()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  owner_id uuid;
  existing_count integer;
begin
  select user_id into owner_id from public.trips where id = new.trip_id;

  select count(*) into existing_count
  from public.photos
  where trip_id = new.trip_id;

  -- Checked first, unconditionally: a lapsed-Pro free user who already has
  -- (say) 150 photos on a memory from their Pro days must still see the
  -- free-tier upsell at 40+, not the generic ceiling message — only an
  -- actual 2,000 gets the generic one, regardless of tier.
  if existing_count >= 2000 then
    raise exception using
      errcode = 'TRV03',
      message = 'This memory has reached its photo limit. Start a new memory to keep going.';
  end if;

  if not public.is_pro(owner_id) and existing_count >= 40 then
    raise exception using
      errcode = 'TRV02',
      message = 'Free plan is limited to 40 photos per memory. Upgrade to Pro for unlimited photos.';
  end if;

  return new;
end;
$$;

create trigger photos_enforce_limits
before insert on public.photos
for each row execute function public.enforce_photo_limits();
