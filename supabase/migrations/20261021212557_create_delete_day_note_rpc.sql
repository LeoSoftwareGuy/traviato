-- delete_day_note() RPC (#276): deletes one day note and takes back the ✦1
-- it earned, in one transaction. Notes became editable in #276 — clearing
-- the text in the note page and confirming deletes the note. The ledger is
-- write-protected from clients (only select is granted), so reversing an
-- award has to live in a security-definer function, same as delete_photo()
-- (#165).
--
-- Star rule: the note's 'note' ledger row (keyed by the note id) is
-- removed. Writing a new note that day later earns ✦1 again, like a
-- deleted and re-added photo.
--
-- Idempotent: an already-deleted note is a no-op, so a retry after a
-- dropped response is safe.
--
-- set search_path = public guards against search-path hijacking in a
-- security definer function (see docs/supabase.md).
--
-- Down/revert notes: `drop function public.delete_day_note(uuid);`

create function public.delete_day_note(p_note_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner uuid;
begin
  select t.user_id into v_owner
  from public.day_notes n
  join public.trips t on t.id = n.trip_id
  where n.id = p_note_id;

  if v_owner is null then
    return;
  end if;

  if v_owner is distinct from auth.uid() then
    raise exception using
      errcode = '42501',
      message = 'note not found or not owned by caller';
  end if;

  delete from public.points_ledger
  where user_id = v_owner and source = 'note' and source_id = p_note_id;

  delete from public.day_notes where id = p_note_id;
end;
$$;

revoke execute on function public.delete_day_note(uuid) from public, anon;
grant execute on function public.delete_day_note(uuid) to authenticated;
