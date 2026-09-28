-- delete_photo() RPC (#165): deletes one journal photo's row and takes back
-- the ✦2 it earned, in one transaction. The ledger is write-protected from
-- clients (only select is granted — see the points_ledger migration), so
-- reversing an award has to live in a security-definer function, same as
-- award_points().
--
-- Star rules:
--   - A plain journal photo loses its ✦2 (source 'photo').
--   - A photo that completed a bonus task keeps ALL its stars — both the
--     photo ✦2 and the task's own award (source 'bonus_task', keyed by the
--     assignment, never touched here). The assignment itself stays completed;
--     its photo_id goes null via the existing `on delete set null`.
--   - Deleting a whole memory is unchanged: the photos cascade without this
--     function, so their stars stay (ledger trip_id set null, #11/#27).
--
-- The storage file is removed by the client afterwards via the Storage API —
-- Postgres can't delete storage objects directly.
--
-- Idempotent: an already-deleted photo is a no-op, so a retry after a
-- dropped response is safe.
--
-- set search_path = public guards against search-path hijacking in a
-- security definer function (see docs/supabase.md).
--
-- Down/revert notes: `drop function public.delete_photo(uuid);`

create function public.delete_photo(p_photo_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner uuid;
  v_completed_bonus boolean;
begin
  select t.user_id into v_owner
  from public.photos p
  join public.trips t on t.id = p.trip_id
  where p.id = p_photo_id;

  if v_owner is null then
    return;
  end if;

  if v_owner is distinct from auth.uid() then
    raise exception using
      errcode = '42501',
      message = 'photo not found or not owned by caller';
  end if;

  -- Checked before the delete: the FK's `set null` would erase the link.
  select exists (
    select 1 from public.bonus_task_assignments
    where photo_id = p_photo_id and completed_at is not null
  ) into v_completed_bonus;

  delete from public.photos where id = p_photo_id;

  if not v_completed_bonus then
    delete from public.points_ledger
    where user_id = v_owner and source = 'photo' and source_id = p_photo_id;
  end if;
end;
$$;

revoke execute on function public.delete_photo(uuid) from public, anon;
grant execute on function public.delete_photo(uuid) to authenticated;
