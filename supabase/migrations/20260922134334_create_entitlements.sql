-- Entitlements: server-side subscription tier tracking (#137, M6-1).
--
-- Source of truth for Pro/free status — never trust the client's own "am I
-- Pro" flag. Rows are written only by security-definer functions here and,
-- from M6-2 on, by the RevenueCat webhook handler running as service role;
-- clients get read-only access to their own row. is_pro() is the single
-- tier-check helper every limit-enforcing RPC (M6-3) will call.
--
-- Down/revert notes: `drop function public.is_pro(uuid);
-- drop trigger on_profile_created_entitlement on public.profiles;
-- drop function public.handle_new_profile_entitlement();
-- drop trigger entitlements_set_updated_at on public.entitlements;
-- drop table public.entitlements;`

create table public.entitlements (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  tier text not null default 'free' check (tier in ('free', 'pro')),
  revenuecat_customer_id text,
  expires_at timestamptz,
  updated_at timestamptz not null default now()
);

alter table public.entitlements enable row level security;

-- A user may read only their own row. No insert/update/delete policy: rows
-- are created by handle_new_profile_entitlement() below and (from M6-2)
-- updated by the RevenueCat webhook running as service role — both bypass
-- RLS, so clients can never write their own tier.
create policy "entitlements_select_own" on public.entitlements
for select to authenticated
using (user_id = auth.uid());

-- Project has auto-expose disabled: grants are required even with RLS.
grant select on public.entitlements to authenticated;

-- public.set_updated_at() already exists from the trips migration (#11).
create trigger entitlements_set_updated_at
before update on public.entitlements
for each row execute function public.set_updated_at();

-- Backfill: every existing profile gets a free entitlements row.
insert into public.entitlements (user_id)
select id from public.profiles
on conflict (user_id) do nothing;

-- Going forward: give every new profile a free entitlements row the moment
-- it's created. Triggers off profiles (not auth.users) so the existing
-- handle_new_user/on_auth_user_created migration stays untouched, and runs
-- after that trigger's insert since it fires on the profiles row it creates.
--
-- set search_path = public guards against search-path hijacking in a
-- security definer function (see docs/supabase.md).
create function public.handle_new_profile_entitlement()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.entitlements (user_id) values (new.id);
  return new;
end;
$$;

create trigger on_profile_created_entitlement
after insert on public.profiles
for each row execute function public.handle_new_profile_entitlement();

-- is_pro(): the single tier-check helper every limit-enforcing RPC (M6-3)
-- calls. Parameter is named check_user_id rather than user_id (as sketched
-- in the issue) because a same-named parameter would collide with the
-- entitlements.user_id column and compare it to itself instead of the
-- argument. security definer so it works when called from inside another
-- security-definer RPC, regardless of the caller's own RLS context.
create function public.is_pro(check_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.entitlements
    where user_id = check_user_id
      and tier = 'pro'
      and (expires_at is null or expires_at > now())
  );
$$;

grant execute on function public.is_pro(uuid) to authenticated;
