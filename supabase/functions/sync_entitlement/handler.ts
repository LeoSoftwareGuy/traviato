// Request handling for sync_entitlement (#267), separated from index.ts's
// Deno.serve bootstrap so it can be exercised in tests without starting a
// server — same split as generate_wrap_up/handler.ts.
//
// Why this exists: `entitlements` is otherwise written only by the
// RevenueCat webhook, which fires on store events. When the row and
// RevenueCat disagree — the hosted DB was reset, a webhook delivery failed,
// or the purchase happened under an anonymous RevenueCat id before
// `Purchases.logIn` — nothing ever re-sends the event, so a paying user
// stays "free" server-side and hits the 3-memory trigger. This function
// pulls the caller's live state from RevenueCat's REST API and repairs the
// row on demand (after purchase/restore, and when a limit error looks
// wrong to the app).
//
// It only ever UPGRADES: an active pro entitlement in RevenueCat is written
// as tier 'pro' + expires_at; anything else leaves the row untouched.
// Downgrades stay the webhook's job (EXPIRATION), and is_pro() already
// treats a past expires_at as free, so a missed downgrade can't grant
// access. The caller is identified only by their JWT — there is no user id
// in the request body to spoof.

import type { ProEntitlement } from "./revenuecat.ts";

// deno-lint-ignore no-explicit-any
type SupabaseClient = any;

export interface Deps {
  serviceClient: SupabaseClient;
  authClient: (authHeader: string) => SupabaseClient;
  getProEntitlement: (appUserId: string) => Promise<ProEntitlement | null>;
  now?: () => Date;
}

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

function isActive(pro: ProEntitlement, now: Date): boolean {
  return pro.expiresAt === null || Date.parse(pro.expiresAt) > now.getTime();
}

export async function handleRequest(
  req: Request,
  deps: Deps,
): Promise<Response> {
  if (req.method !== "POST") {
    return json({ error: "method not allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return json({ error: "missing authorization" }, 401);
  }

  const { data: userData, error: userError } = await deps.authClient(authHeader)
    .auth.getUser();
  if (userError || !userData?.user) {
    return json({ error: "invalid session" }, 401);
  }
  const userId: string = userData.user.id;

  let pro: ProEntitlement | null;
  try {
    pro = await deps.getProEntitlement(userId);
  } catch (e) {
    return json({ error: `revenuecat lookup failed: ${String(e)}` }, 502);
  }

  const now = deps.now?.() ?? new Date();
  if (pro && isActive(pro, now)) {
    const { error } = await deps.serviceClient
      .from("entitlements")
      .upsert({
        user_id: userId,
        tier: "pro",
        expires_at: pro.expiresAt,
        revenuecat_customer_id: userId,
      }, { onConflict: "user_id" });
    if (error) {
      return json(
        { error: `failed to update entitlements: ${error.message}` },
        500,
      );
    }
  }

  const { data: row, error: readError } = await deps.serviceClient
    .from("entitlements")
    .select("tier, revenuecat_customer_id, expires_at")
    .eq("user_id", userId)
    .maybeSingle();
  if (readError) {
    return json(
      { error: `entitlements lookup failed: ${readError.message}` },
      500,
    );
  }

  return json(row ?? { tier: "free" }, 200);
}
