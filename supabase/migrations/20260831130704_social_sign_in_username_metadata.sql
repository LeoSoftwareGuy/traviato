-- Widens handle_new_user()'s username/avatar sourcing to cover OAuth
-- signups (Apple/Google, #84) alongside the existing email/password path.
--
-- Email/password only ever populates raw_user_meta_data->>'username'.
-- Google's native ID-token sign-in populates 'full_name' and 'picture'.
-- Apple only populates 'full_name' (never 'picture'), and only on the
-- user's very first authorization ever — an Apple platform quirk, not a
-- bug: later logins simply have no name in the metadata, so the coalesce
-- falls through to leaving username null rather than overwriting a name
-- set on first login (this trigger only fires on insert, never update).
--
-- Down/revert: restore the previous body,
-- `insert into public.profiles (id, username) values (new.id, new.raw_user_meta_data ->> 'username');`

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, username, avatar_url)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data ->> 'username',
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'name'
    ),
    new.raw_user_meta_data ->> 'picture'
  );
  return new;
end;
$$;
