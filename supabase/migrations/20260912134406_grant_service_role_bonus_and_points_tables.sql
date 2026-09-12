-- Grants generate_wrap_up's service-role client SELECT on the tables #125
-- added to gather.ts (bonus_task_assignments joined with
-- bonus_task_templates, and points_ledger) — #109's grant migration
-- predates #125 and only covered the tables gather.ts queried at that time
-- (trips, quests, day_notes, photos, user_achievements,
-- achievement_templates, wrap_ups). Same root cause as #109: service_role
-- bypasses RLS but not Postgres's own GRANT system, so the function's
-- service-role client got a real "permission denied" on the first
-- ungranted table it queried. Confirmed directly against the local DB:
-- service_role had no SELECT on any of the three tables below.
--
-- bonus_task_templates needs SELECT too — PostgREST's embedded join
-- (`bonus_task_assignments.select(..., bonus_task_templates(title, points))`)
-- requires it on both sides of the join, same as any other embedded read.
--
-- Down/revert notes: `revoke select on public.bonus_task_assignments,
-- public.bonus_task_templates, public.points_ledger from service_role;`

grant select on public.bonus_task_assignments to service_role;
grant select on public.bonus_task_templates to service_role;
grant select on public.points_ledger to service_role;
