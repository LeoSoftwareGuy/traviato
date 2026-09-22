-- The revenuecat_webhook edge function (#138) is the one writer to
-- entitlements #137 deliberately left ungranted: "writes come only from the
-- RevenueCat webhook handler (service role) in M6-2" — that's now. Same
-- root cause as #109/#125's grant migrations: service_role bypasses RLS but
-- not Postgres's own GRANT system, so the webhook's service-role client
-- would get a real "permission denied" on its first upsert otherwise.
--
-- Down/revert notes: `revoke insert, update on public.entitlements from
-- service_role;`

grant insert, update on public.entitlements to service_role;
