-- generate_wrap_up reads a memory's checklist for Golden Vows' packing card
-- (#346): its checked items, in the user's own words. The service-role
-- client needs its own grant (auto-expose disabled; see
-- 20260905150159_grant_service_role_wrap_up_tables.sql). Read-only.
--
-- Down/revert notes: `revoke select on public.checklist_items from
-- service_role;`

grant select on public.checklist_items to service_role;
