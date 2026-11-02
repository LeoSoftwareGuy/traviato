-- #309 (M7-1): memory share links + the public preview RPC.
--
-- An owner makes one link per memory: storyni.app/m/{slug}. Anyone with it
-- — signed in or not — sees a teaser through get_shared_memory_preview():
-- title, place, dates, counts and up to 6 photos. Never the film, notes,
-- coordinates, expenses, quests or ids.
--
-- Teaser photos are downscaled, re-encoded (so no EXIF / GPS) copies in the
-- public `share-previews` bucket under {slug}/: 0.jpg … 5.jpg (0 = cover)
-- and og.jpg (1200×630 link-preview card). The slug is unguessable, so the
-- paths are; originals in trip-photos stay private. The APP builds and
-- uploads the copies (issue #309's plan comment: edge functions' CPU limit)
-- and then calls mark_share_preview_built(). Revoking: revoke_share_link(),
-- then the app removes the {slug}/ files (Postgres can't delete Storage
-- objects).
--
-- Down/revert notes: drop the share-previews policies on storage.objects;
-- `delete from storage.buckets where id = 'share-previews';` (after
-- emptying it); `drop function public.get_shared_memory_preview(text),
-- public.mark_share_preview_built(uuid, int), public.revoke_share_link(uuid),
-- public.create_share_link(uuid); drop table public.trip_share_links; drop
-- function public.guard_trip_share_link_update(),
-- public.generate_share_slug();`

create extension if not exists pgcrypto with schema extensions;

-- 10 base62 characters from the CSPRNG (~59.5 bits). Bytes >= 248 are
-- rejected so every character is equally likely (248 = 4 × 62). Security
-- definer so the collision check sees every link, not just the caller's.
create function public.generate_share_slug()
returns text
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_alphabet constant text :=
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  v_bytes bytea;
  v_byte int;
  v_slug text;
begin
  loop
    v_slug := '';
    while length(v_slug) < 10 loop
      v_bytes := extensions.gen_random_bytes(16);
      for i in 0..15 loop
        v_byte := get_byte(v_bytes, i);
        if v_byte < 248 and length(v_slug) < 10 then
          v_slug := v_slug || substr(v_alphabet, (v_byte % 62) + 1, 1);
        end if;
      end loop;
    end loop;
    exit when not exists (
      select 1 from public.trip_share_links where slug = v_slug
    );
  end loop;
  return v_slug;
end;
$$;

-- Authenticated runs it as the slug column default. Calling it directly
-- just returns a random string.
revoke execute on function public.generate_share_slug() from public, anon;
grant execute on function public.generate_share_slug() to authenticated;

create table public.trip_share_links (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips (id) on delete cascade,
  slug text not null unique default public.generate_share_slug()
    check (slug ~ '^[A-Za-z0-9]{10}$'),
  created_by uuid not null references auth.users (id) default auth.uid(),
  created_at timestamptz not null default now(),
  revoked_at timestamptz,
  -- Set by mark_share_preview_built() once the app uploaded the copies.
  preview_built_at timestamptz,
  -- How many teaser photos ({slug}/0.jpg …) the last build uploaded.
  preview_photo_count int not null default 0
    check (preview_photo_count between 0 and 6)
);

-- At most one active link per memory.
create unique index trip_share_links_one_active
on public.trip_share_links (trip_id) where revoked_at is null;

alter table public.trip_share_links enable row level security;

-- Authenticated only; anon gets nothing (it reads previews through the
-- security-definer RPC). No delete policy: rows stay for audit, and the
-- trip cascade cleans them up.
create policy "trip_share_links_select_own" on public.trip_share_links
for select to authenticated
using (
  created_by = auth.uid()
  and exists (
    select 1 from public.trips t
    where t.id = trip_id and t.user_id = auth.uid()
  )
);

create policy "trip_share_links_insert_own" on public.trip_share_links
for insert to authenticated
with check (
  created_by = auth.uid()
  and exists (
    select 1 from public.trips t
    where t.id = trip_id and t.user_id = auth.uid()
  )
);

create policy "trip_share_links_update_own" on public.trip_share_links
for update to authenticated
using (
  created_by = auth.uid()
  and exists (
    select 1 from public.trips t
    where t.id = trip_id and t.user_id = auth.uid()
  )
)
with check (
  created_by = auth.uid()
  and exists (
    select 1 from public.trips t
    where t.id = trip_id and t.user_id = auth.uid()
  )
);

revoke all on public.trip_share_links from anon, authenticated;
grant select on public.trip_share_links to authenticated;
-- Clients choose only the memory; slug / created_by come from defaults.
grant insert (trip_id) on public.trip_share_links to authenticated;
-- Clients may only revoke; the preview columns go through
-- mark_share_preview_built().
grant update (revoked_at) on public.trip_share_links to authenticated;

-- Identity columns never change, and a revoked link stays revoked.
create function public.guard_trip_share_link_update()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.id is distinct from old.id
    or new.trip_id is distinct from old.trip_id
    or new.slug is distinct from old.slug
    or new.created_by is distinct from old.created_by
    or new.created_at is distinct from old.created_at then
    raise exception using
      errcode = '42501',
      message = 'only revoked_at may change on a share link';
  end if;
  if old.revoked_at is not null
    and new.revoked_at is distinct from old.revoked_at then
    raise exception using
      errcode = '42501',
      message = 'a revoked share link stays revoked';
  end if;
  return new;
end;
$$;

create trigger trip_share_links_guard_update
before update on public.trip_share_links
for each row
execute function public.guard_trip_share_link_update();

-- Returns the memory's active link, making one if there is none. Two calls
-- racing for the same memory both get the one row (the loser of the
-- partial unique index re-reads it).
create function public.create_share_link(p_trip_id uuid)
returns public.trip_share_links
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_link public.trip_share_links;
begin
  perform 1 from public.trips
  where id = p_trip_id and user_id = auth.uid();
  if not found then
    raise exception using
      errcode = '42501',
      message = 'trip not found or not owned by caller';
  end if;

  select * into v_link from public.trip_share_links
  where trip_id = p_trip_id and revoked_at is null;
  if found then
    return v_link;
  end if;

  begin
    insert into public.trip_share_links (trip_id)
    values (p_trip_id)
    returning * into v_link;
  exception when unique_violation then
    select * into v_link from public.trip_share_links
    where trip_id = p_trip_id and revoked_at is null;
  end;
  return v_link;
end;
$$;

revoke execute on function public.create_share_link(uuid) from public, anon;
grant execute on function public.create_share_link(uuid) to authenticated;

-- Turns the memory's active link off; a no-op when there is none. The app
-- then removes the link's share-previews/{slug}/ files.
create function public.revoke_share_link(p_trip_id uuid)
returns void
language plpgsql
security invoker
set search_path = public
as $$
begin
  update public.trip_share_links
  set revoked_at = now()
  where trip_id = p_trip_id and revoked_at is null;
end;
$$;

revoke execute on function public.revoke_share_link(uuid) from public, anon;
grant execute on function public.revoke_share_link(uuid) to authenticated;

-- The app calls this after uploading a link's teaser copies + og.jpg.
create function public.mark_share_preview_built(
  p_link_id uuid,
  p_photo_count int
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_photo_count is null or p_photo_count not between 0 and 6 then
    raise exception using
      errcode = '22023',
      message = 'a share preview has 0 to 6 photos';
  end if;

  update public.trip_share_links l
  set preview_built_at = now(), preview_photo_count = p_photo_count
  where l.id = p_link_id
    and l.created_by = auth.uid()
    and l.revoked_at is null
    and exists (
      select 1 from public.trips t
      where t.id = l.trip_id and t.user_id = auth.uid()
    );
  if not found then
    raise exception using
      errcode = '42501',
      message = 'share link not found, revoked or not owned by caller';
  end if;
end;
$$;

revoke execute on function public.mark_share_preview_built(uuid, int)
from public, anon;
grant execute on function public.mark_share_preview_built(uuid, int)
to authenticated;

-- The public teaser. An unknown slug, a revoked link and a deleted memory
-- all return the same null. Keys are a fixed allowlist (pgTAP-tested);
-- image values are paths inside the public share-previews bucket — the web
-- page and the app prefix them with the project's public storage URL,
-- which SQL doesn't know.
create function public.get_shared_memory_preview(p_slug text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_link public.trip_share_links;
  v_trip public.trips;
  v_profile public.profiles;
  v_ready boolean;
  v_photos jsonb;
begin
  if p_slug is null or p_slug !~ '^[A-Za-z0-9]{10}$' then
    return null;
  end if;

  select * into v_link from public.trip_share_links
  where slug = p_slug and revoked_at is null;
  if not found then
    return null;
  end if;

  select * into v_trip from public.trips where id = v_link.trip_id;
  if not found then
    return null;
  end if;

  select * into v_profile from public.profiles where id = v_trip.user_id;

  v_ready := v_link.preview_built_at is not null;
  v_photos := case
    when v_ready and v_link.preview_photo_count > 0 then (
      select jsonb_agg(p_slug || '/' || n || '.jpg' order by n)
      from generate_series(0, v_link.preview_photo_count - 1) n
    )
    else '[]'::jsonb
  end;

  return jsonb_build_object(
    'slug', p_slug,
    'title', v_trip.name,
    'destination', v_trip.destination,
    'start_date', v_trip.start_date,
    'end_date', v_trip.end_date,
    'day_count', v_trip.end_date - v_trip.start_date + 1,
    'photo_count', (
      select count(*) from public.photos where trip_id = v_trip.id
    ),
    'has_film', exists (
      select 1 from public.wrap_ups
      where trip_id = v_trip.id and published_at is not null
    ),
    'cover_path', case
      when v_ready and v_link.preview_photo_count > 0
        then p_slug || '/0.jpg'
    end,
    'og_image_path', case when v_ready then p_slug || '/og.jpg' end,
    'photos', v_photos,
    'owner', jsonb_build_object(
      'display_name', v_profile.username,
      'handle', v_profile.username,
      -- Only an external (OAuth) picture is public; an uploaded avatar is a
      -- private avatars-bucket path.
      'avatar_url', case
        when v_profile.avatar_url ~ '^https?://' then v_profile.avatar_url
      end
    ),
    'preview_ready', v_ready
  );
end;
$$;

revoke execute on function public.get_shared_memory_preview(text) from public;
grant execute on function public.get_shared_memory_preview(text)
to anon, authenticated;

-- share-previews: public reads by URL (no listing for anon — there is no
-- anon policy). The owner writes, reads and removes only under the slugs
-- of their own links; writes need the link to be active.
insert into storage.buckets (
  id, name, public, file_size_limit, allowed_mime_types
)
values (
  'share-previews', 'share-previews', true, 2097152, '{image/jpeg}'
);

create policy "share_previews_select_own" on storage.objects
for select to authenticated
using (
  bucket_id = 'share-previews'
  and exists (
    select 1 from public.trip_share_links l
    where l.slug = (storage.foldername(name))[1]
      and l.created_by = auth.uid()
  )
);

create policy "share_previews_insert_own_active" on storage.objects
for insert to authenticated
with check (
  bucket_id = 'share-previews'
  and exists (
    select 1 from public.trip_share_links l
    where l.slug = (storage.foldername(name))[1]
      and l.created_by = auth.uid()
      and l.revoked_at is null
  )
);

-- Rebuilds overwrite (upsert) the same file names.
create policy "share_previews_update_own_active" on storage.objects
for update to authenticated
using (
  bucket_id = 'share-previews'
  and exists (
    select 1 from public.trip_share_links l
    where l.slug = (storage.foldername(name))[1]
      and l.created_by = auth.uid()
      and l.revoked_at is null
  )
)
with check (
  bucket_id = 'share-previews'
  and exists (
    select 1 from public.trip_share_links l
    where l.slug = (storage.foldername(name))[1]
      and l.created_by = auth.uid()
      and l.revoked_at is null
  )
);

-- Revoked links included: removing their files is what revoking does.
create policy "share_previews_delete_own" on storage.objects
for delete to authenticated
using (
  bucket_id = 'share-previews'
  and exists (
    select 1 from public.trip_share_links l
    where l.slug = (storage.foldername(name))[1]
      and l.created_by = auth.uid()
  )
);
