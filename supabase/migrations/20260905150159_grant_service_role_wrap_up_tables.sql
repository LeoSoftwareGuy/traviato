-- Grants generate_wrap_up's service-role client the privileges it needs
-- (docs/data-model.md, #109). `service_role` bypasses RLS, but that's a
-- separate mechanism from Postgres's own GRANT system — every migration so
-- far granted privileges to `authenticated` only (per docs/supabase.md's
-- "auto-expose disabled: explicit grants required" convention), so
-- service_role has had zero access to any of these tables since they were
-- created. Confirmed directly: `service_role` had no SELECT on `trips`
-- (or any table this function reads), which silently produced "trip not
-- found" for a real trip instead of the actual permission error.
--
-- Down/revert notes: `revoke select on public.trips, public.quests,
-- public.day_notes, public.photos, public.user_achievements,
-- public.achievement_templates from service_role; revoke select, insert,
-- update on public.wrap_ups from service_role;`

grant select on public.trips to service_role;
grant select on public.quests to service_role;
grant select on public.day_notes to service_role;
grant select on public.photos to service_role;
grant select on public.user_achievements to service_role;
grant select on public.achievement_templates to service_role;

-- wrap_ups: the function both checks for an existing row (select) and
-- upserts a newly-generated one (insert + update on conflict).
grant select, insert, update on public.wrap_ups to service_role;
