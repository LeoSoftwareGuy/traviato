// Entry point deployed by Supabase (`supabase functions deploy
// revenuecat_webhook`). Wires real dependencies and starts the server —
// kept separate from handler.ts so tests can exercise the request logic
// without this Deno.serve ever running (same split as generate_wrap_up).

import { createClient } from "npm:@supabase/supabase-js@2.45.4";
import { handleRequest } from "./handler.ts";

Deno.serve((req) => {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const expectedAuthHeader = Deno.env.get("REVENUECAT_WEBHOOK_AUTH_HEADER")!;

  const serviceClient = createClient(supabaseUrl, serviceRoleKey);

  return handleRequest(req, { serviceClient, expectedAuthHeader });
});
