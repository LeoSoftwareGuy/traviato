-- avatars storage bucket (docs/data-model.md). Part of #96.
--
-- Path convention: {user_id}/avatar.jpg — a single stable object per user,
-- same shape as the trip cover's {user_id}/{trip_id}/cover.jpg (#81): a
-- re-upload replaces it (delete-then-insert, since there's no update
-- policy below) rather than accumulating objects.
--
-- Down/revert notes: `drop policy "avatars_delete_own" on storage.objects;
-- drop policy "avatars_insert_own" on storage.objects; drop policy
-- "avatars_select_own" on storage.objects; delete from storage.buckets
-- where id = 'avatars';`

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', false);

-- storage.objects ships with RLS already enabled by the platform.

create policy "avatars_select_own" on storage.objects
for select to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "avatars_insert_own" on storage.objects
for insert to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- No update policy: a replace is delete + re-upload, matching trip-photos.
create policy "avatars_delete_own" on storage.objects
for delete to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);
