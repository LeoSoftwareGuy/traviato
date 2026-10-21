// Entry point deployed by Supabase (`supabase functions deploy
// sync_entitlement`). Wires real dependencies and starts the server — kept
// separate from handler.ts so tests can exercise the request logic without
// this Deno.serve ever running (same split as generate_wrap_up).

import { createClient } from "npm:@supabase/supabase-js@2.45.4";
import { handleRequest } from "./handler.ts";
import { fetchProEntitlement } from "./revenuecat.ts";

Deno.serve((req) => {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const revenueCatSecretKey = Deno.env.get("REVENUECAT_SECRET_API_KEY")!;

  const serviceClient = createClient(supabaseUrl, serviceRoleKey);
  const authClient = (authHeader: string) =>
    createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });

  return handleRequest(req, {
    serviceClient,
    authClient,
    getProEntitlement: (appUserId) =>
      fetchProEntitlement(appUserId, revenueCatSecretKey),
  });
});
