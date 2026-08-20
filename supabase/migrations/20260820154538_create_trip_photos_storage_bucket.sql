-- trip-photos storage bucket (docs/data-model.md). Closes #25.
--
-- Path convention: {user_id}/{trip_id}/{photo_id}.{ext} — the first path
-- segment is the uploader's own auth.uid(), which is the ownership
-- boundary these policies enforce (no dependency on public.trips, so a
-- photo upload never races the trip row).
--
-- Down/revert notes: `drop policy "trip_photos_delete_own" on
-- storage.objects; drop policy "trip_photos_insert_own" on
-- storage.objects; drop policy "trip_photos_select_own" on
-- storage.objects; delete from storage.buckets where id = 'trip-photos';`

insert into storage.buckets (id, name, public)
values ('trip-photos', 'trip-photos', false);

-- storage.objects ships with RLS already enabled by the platform.

create policy "trip_photos_select_own" on storage.objects
for select to authenticated
using (
  bucket_id = 'trip-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "trip_photos_insert_own" on storage.objects
for insert to authenticated
with check (
  bucket_id = 'trip-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- No update policy: a photo's file is replaced by delete + re-upload, not
-- mutated in place — there is no photo-edit feature.
create policy "trip_photos_delete_own" on storage.objects
for delete to authenticated
using (
  bucket_id = 'trip-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);
