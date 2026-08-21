-- achievement_templates + user_achievements tables (docs/data-model.md).
-- Part of #27.
--
-- Down/revert notes: `drop table public.user_achievements; drop table
-- public.achievement_templates;`

-- Global catalog (seeded in a follow-up migration). Read-only from the
-- client, same shape as checklist_suggestions (#21) / bonus_task_templates
-- (#27).
create table public.achievement_templates (
  id bigint generated always as identity primary key,
  code text not null unique,
  title text not null,
  description text not null,
  metric text not null check (
    metric in ('trips', 'countries', 'days_logged', 'stars', 'photos', 'notes')
  ),
  target int not null check (target > 0),
  position int not null
);

alter table public.achievement_templates enable row level security;

create policy "achievement_templates_select_all" on public.achievement_templates
for select to authenticated
using (true);

grant select on public.achievement_templates to authenticated;

create table public.user_achievements (
  user_id uuid not null references public.profiles (id) on delete cascade,
  template_id bigint not null references public.achievement_templates (id),
  earned_at timestamptz not null default now(),
  primary key (user_id, template_id)
);

alter table public.user_achievements enable row level security;

-- Deny-by-default beyond select: no insert/update/delete policy is defined
-- here (or granted below), so earned badges can only ever be written by the
-- security-definer check_achievements() RPC (#27), never directly by a
-- client.
create policy "user_achievements_select_own" on public.user_achievements
for select to authenticated
using (user_id = auth.uid());

-- Only select is granted — see the no-write-policy note above.
grant select on public.user_achievements to authenticated;
