-- profiles table + signup trigger (docs/data-model.md).
--
-- Down/revert notes: `drop trigger on_auth_user_created on auth.users;
-- drop function public.handle_new_user(); drop table public.profiles;`

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text,
  bio text,
  avatar_url text,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- A user may read and update only their own profile row. No insert/delete
-- policy: rows are created exclusively by handle_new_user() below, running
-- as security definer, so clients can never create or remove a profile row.
create policy "profiles_select_own" on public.profiles
for select to authenticated
using (id = auth.uid());

create policy "profiles_update_own" on public.profiles
for update to authenticated
using (id = auth.uid())
with check (id = auth.uid());

-- Project has auto-expose disabled: grants are required even with RLS.
grant select, update on public.profiles to authenticated;

-- set search_path = public guards against search-path hijacking in a
-- security definer function (see docs/supabase.md).
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, username)
  values (new.id, new.raw_user_meta_data ->> 'username');
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();
