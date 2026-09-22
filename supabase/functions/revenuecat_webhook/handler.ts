// Request handling for revenuecat_webhook (#138), separated from index.ts's
// Deno.serve bootstrap so it can be exercised in tests without starting a
// server — same split as generate_wrap_up/handler.ts.
//
// RevenueCat webhooks carry no cryptographic signature; RevenueCat's own
// verification mechanism is a fixed `Authorization` header value you set in
// its dashboard, echoed back verbatim on every call. We compare that value
// with a timing-safe equality check against REVENUECAT_WEBHOOK_AUTH_HEADER.
//
// `entitlements` is the sole write target, upserted by user_id
// (== app_user_id, since the client identifies with `Purchases.logIn` using
// the Supabase user id). Event handling deliberately does NOT revoke access
// on CANCELLATION/BILLING_ISSUE — RevenueCat's own guidance is that access
// continues until the subscription's actual expiration, which EXPIRATION
// reports. See the #138 plan comment for the full mapping table.

import { timingSafeEqual } from "https://deno.land/std@0.224.0/crypto/timing_safe_equal.ts";

// deno-lint-ignore no-explicit-any
type SupabaseClient = any;

export interface Deps {
  serviceClient: SupabaseClient;
  expectedAuthHeader: string;
}

const PRO_ENTITLEMENT_ID = "pro";

// Events that mean "the user has active pro access right now."
const ACCESS_EVENT_TYPES = new Set([
  "INITIAL_PURCHASE",
  "RENEWAL",
  "PRODUCT_CHANGE",
  "UNCANCELLATION",
  "TRANSFER",
  "SUBSCRIPTION_EXTENDED",
]);

// Informational only — the subscription is set to lapse, but access
// continues until EXPIRATION actually fires. Only expires_at/customer id
// are refreshed; tier is left alone.
const INFORMATIONAL_EVENT_TYPES = new Set(["CANCELLATION", "BILLING_ISSUE"]);

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

function isAuthorized(req: Request, expected: string): boolean {
  const header = req.headers.get("Authorization");
  if (!header) return false;
  const a = new TextEncoder().encode(header);
  const b = new TextEncoder().encode(expected);
  // timingSafeEqual requires equal-length buffers; unequal length is itself
  // a safe (non-secret-dependent) rejection.
  if (a.byteLength !== b.byteLength) return false;
  return timingSafeEqual(a, b);
}

export async function handleRequest(
  req: Request,
  deps: Deps,
): Promise<Response> {
  if (req.method !== "POST") {
    return json({ error: "method not allowed" }, 405);
  }

  if (!isAuthorized(req, deps.expectedAuthHeader)) {
    return json({ error: "unauthorized" }, 401);
  }

  const body = await req.json().catch(() => null);
  const event = body?.event;
  if (
    !event ||
    typeof event.type !== "string" ||
    typeof event.app_user_id !== "string"
  ) {
    return json({ error: "malformed payload" }, 400);
  }

  const type = event.type as string;

  if (type === "TEST") {
    // RevenueCat's dashboard "Send Test Event" button — acknowledge only.
    return json({ ok: true }, 200);
  }

  const entitlementIds: unknown = event.entitlement_ids;
  const affectsProEntitlement = Array.isArray(entitlementIds) &&
    entitlementIds.includes(PRO_ENTITLEMENT_ID);
  if (!affectsProEntitlement) {
    return json({ ok: true, skipped: "not the pro entitlement" }, 200);
  }

  const expirationAtMs = event.expiration_at_ms;
  const expiresAt = typeof expirationAtMs === "number"
    ? new Date(expirationAtMs).toISOString()
    : null;

  // deno-lint-ignore no-explicit-any
  let row: Record<string, any> | null = null;
  if (ACCESS_EVENT_TYPES.has(type)) {
    row = {
      user_id: event.app_user_id,
      tier: "pro",
      expires_at: expiresAt,
      revenuecat_customer_id: event.app_user_id,
    };
  } else if (type === "EXPIRATION") {
    row = {
      user_id: event.app_user_id,
      tier: "free",
      expires_at: expiresAt,
      revenuecat_customer_id: event.app_user_id,
    };
  } else if (INFORMATIONAL_EVENT_TYPES.has(type)) {
    // tier intentionally omitted — upsert only touches the columns given,
    // so an existing pro row stays pro until EXPIRATION says otherwise.
    row = {
      user_id: event.app_user_id,
      expires_at: expiresAt,
      revenuecat_customer_id: event.app_user_id,
    };
  } else {
    return json({ ok: true, skipped: `unhandled event type: ${type}` }, 200);
  }

  const { error } = await deps.serviceClient
    .from("entitlements")
    .upsert(row, { onConflict: "user_id" });
  if (error) {
    return json({ error: `failed to update entitlements: ${error.message}` }, 500);
  }

  return json({ ok: true }, 200);
}
