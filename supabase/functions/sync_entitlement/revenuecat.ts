// RevenueCat REST API read (#267) — the one call sync_entitlement makes to
// RevenueCat. Kept in its own module (same split as generate_wrap_up's
// anthropic.ts) so handler tests inject a fake instead of hitting the
// network.
//
// GET /v1/subscribers/{app_user_id} returns the subscriber's entitlements
// keyed by identifier, each with an ISO `expires_date` (null = lifetime) and
// an optional `grace_period_expires_date` while a billing retry is pending.

const PRO_ENTITLEMENT_ID = "pro";
const SUBSCRIBERS_URL = "https://api.revenuecat.com/v1/subscribers";

/// The subscriber's pro entitlement as RevenueCat sees it. `expiresAt` is
/// the later of `expires_date` and any grace period — the moment access
/// actually ends — or null for a non-expiring grant.
export interface ProEntitlement {
  expiresAt: string | null;
}

export type FetchFn = (
  input: string,
  init?: RequestInit,
) => Promise<Response>;

/// `null` = RevenueCat has no pro entitlement for this user (never bought,
/// or it isn't in the payload). Throws on any non-2xx so the handler can
/// report a 502 rather than mistake an outage for "free".
export async function fetchProEntitlement(
  appUserId: string,
  secretApiKey: string,
  fetchFn: FetchFn = fetch,
): Promise<ProEntitlement | null> {
  const res = await fetchFn(
    `${SUBSCRIBERS_URL}/${encodeURIComponent(appUserId)}`,
    {
      headers: {
        Authorization: `Bearer ${secretApiKey}`,
        "Content-Type": "application/json",
      },
    },
  );
  if (!res.ok) {
    throw new Error(`RevenueCat subscriber lookup failed: ${res.status}`);
  }
  const body = await res.json();
  const entitlement = body?.subscriber?.entitlements?.[PRO_ENTITLEMENT_ID];
  if (!entitlement) return null;
  return { expiresAt: latestExpiry(entitlement) };
}

// deno-lint-ignore no-explicit-any
function latestExpiry(entitlement: Record<string, any>): string | null {
  const expires = entitlement.expires_date;
  if (typeof expires !== "string") return null; // lifetime / promotional
  const grace = entitlement.grace_period_expires_date;
  if (typeof grace === "string" && Date.parse(grace) > Date.parse(expires)) {
    return new Date(grace).toISOString();
  }
  return new Date(expires).toISOString();
}
