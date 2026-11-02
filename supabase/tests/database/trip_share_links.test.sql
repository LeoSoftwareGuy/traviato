-- #309: share links + the public preview RPC. Run with `supabase test db`.
begin;
create extension if not exists pgtap with schema extensions;
select plan(24);

-- Two users, each with a memory. The signup trigger makes their profiles.
insert into auth.users (id, email, raw_user_meta_data) values
  ('11111111-1111-1111-1111-111111111111', 'owner@test.dev',
   '{"username":"leo"}'),
  ('22222222-2222-2222-2222-222222222222', 'other@test.dev',
   '{"username":"mia"}');

insert into public.trips (id, user_id, name, destination, start_date, end_date)
values
  ('aaaaaaaa-0000-0000-0000-000000000001',
   '11111111-1111-1111-1111-111111111111', 'One long road', 'Highlands',
   '2026-08-12', '2026-08-16'),
  ('aaaaaaaa-0000-0000-0000-000000000002',
   '22222222-2222-2222-2222-222222222222', 'Mia''s trip', 'Rome',
   '2026-08-01', '2026-08-03');

insert into public.photos (id, trip_id, day_date, storage_path, lat, lng)
values
  ('bbbbbbbb-0000-0000-0000-000000000001',
   'aaaaaaaa-0000-0000-0000-000000000001', '2026-08-12',
   '11111111-1111-1111-1111-111111111111/aaaaaaaa-0000-0000-0000-000000000001/p1.jpg',
   57.1, -4.6);

create function pg_temp.act_as(p_user uuid) returns void
language sql as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', p_user, 'role', 'authenticated')::text, true);
  set local role authenticated;
$$;

-- Owner creates a link.
select pg_temp.act_as('11111111-1111-1111-1111-111111111111');
create temp table link1 on commit drop as
  select * from public.create_share_link('aaaaaaaa-0000-0000-0000-000000000001');
grant select on link1 to anon, authenticated;

select matches(
  (select slug from link1), '^[A-Za-z0-9]{10}$', 'slug is 10 base62 chars');
select is(
  (select id from public.create_share_link('aaaaaaaa-0000-0000-0000-000000000001')),
  (select id from link1),
  'create_share_link is idempotent');

select throws_ok(
  $$ select public.create_share_link('aaaaaaaa-0000-0000-0000-000000000002') $$,
  '42501', null, 'cannot make a link for someone else''s memory');

select throws_ok(
  $$ update public.trip_share_links set slug = 'AAAAAAAAAA' $$,
  '42501', null, 'clients cannot change the slug');

select lives_ok(
  format('select public.mark_share_preview_built(%L, 2)', (select id from link1)),
  'owner marks the preview built');

-- Another user sees, inserts and updates nothing of the owner's.
select pg_temp.act_as('22222222-2222-2222-2222-222222222222');
select is((select count(*)::int from public.trip_share_links), 0,
  'another user selects no links');
select throws_ok(
  $$ insert into public.trip_share_links (trip_id)
     values ('aaaaaaaa-0000-0000-0000-000000000001') $$,
  '42501', null, 'another user cannot insert a link for the owner''s memory');
update public.trip_share_links set revoked_at = now();
select throws_ok(
  format('select public.mark_share_preview_built(%L, 1)', (select id from link1)),
  '42501', null, 'another user cannot mark the preview built');
select is(
  (select id from public.create_share_link('aaaaaaaa-0000-0000-0000-000000000002')) is not null,
  true, 'the other user can share their own memory');

-- Anon: no table, but the preview.
reset role;
set local role anon;
select throws_ok(
  $$ select * from public.trip_share_links $$,
  '42501', null, 'anon cannot read the table');
select isnt(
  public.get_shared_memory_preview((select slug from link1)), null,
  'anon reads an active link''s preview (and the other user''s update was a no-op)');

create temp table payload on commit drop as
  select public.get_shared_memory_preview((select slug from link1)) as p;

select is(
  (select array_agg(k order by k) from payload, jsonb_object_keys(p) k),
  array['cover_path', 'day_count', 'destination', 'end_date', 'has_film',
        'og_image_path', 'owner', 'photo_count', 'photos', 'preview_ready',
        'slug', 'start_date', 'title'],
  'payload keys are exactly the allowlist');
select is(
  (select array_agg(k order by k) from payload, jsonb_object_keys(p -> 'owner') k),
  array['avatar_url', 'display_name', 'handle'],
  'owner keys are exactly the allowlist');
select is(
  (select count(*)::int from payload
   where p::text ~* '(lat|lng|coord|note|expense|quest|trip_id|user_id)'
      or p::text ~ '57\.1|aaaaaaaa|11111111'),
  0, 'no location, private content or ids anywhere in the payload');
select is((select p ->> 'day_count' from payload), '5', 'day count');
select is((select p ->> 'photo_count' from payload), '1', 'photo count');
select is((select (p ->> 'has_film')::boolean from payload), false, 'no kept film');
select is((select p -> 'owner' ->> 'handle' from payload), 'leo', 'owner handle');
select is(
  (select p -> 'photos' from payload),
  jsonb_build_array((select slug from link1) || '/0.jpg', (select slug from link1) || '/1.jpg'),
  'photo paths follow the built count');

select is(public.get_shared_memory_preview('ZZZZZZZZZZ'), null, 'unknown slug → null');
select is(public.get_shared_memory_preview('bad slug!'), null, 'malformed slug → null');

-- Revoke → null, and a new call makes a new slug.
reset role;
select pg_temp.act_as('11111111-1111-1111-1111-111111111111');
select public.revoke_share_link('aaaaaaaa-0000-0000-0000-000000000001');
select is(public.get_shared_memory_preview((select slug from link1)), null,
  'revoked link → null');
select isnt(
  (select slug from public.create_share_link('aaaaaaaa-0000-0000-0000-000000000001')),
  (select slug from link1),
  'after revoke, a new link has a new slug');

-- Deleted memory → null.
create temp table link2 on commit drop as
  select * from public.trip_share_links where revoked_at is null;
delete from public.trips where id = 'aaaaaaaa-0000-0000-0000-000000000001';
reset role;
select is(public.get_shared_memory_preview((select slug from link2)), null,
  'deleted memory → null');

select * from finish();
rollback;
