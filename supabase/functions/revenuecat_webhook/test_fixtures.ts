// Sample RevenueCat webhook payloads (https://www.revenuecat.com/docs/webhooks),
// trimmed to the fields handler.ts actually reads. `app_user_id` matches our
// Supabase user id since the client identifies with `Purchases.logIn`.

const APP_USER_ID = "u1";

// deno-lint-ignore no-explicit-any
export function buildEvent(overrides: Record<string, any> = {}) {
  return {
    api_version: "1.0",
    event: {
      id: "evt_1",
      type: "INITIAL_PURCHASE",
      app_user_id: APP_USER_ID,
      original_app_user_id: APP_USER_ID,
      product_id: "traviato_pro_annual",
      entitlement_ids: ["pro"],
      period_type: "TRIAL",
      purchased_at_ms: 1_700_000_000_000,
      expiration_at_ms: 1_731_536_000_000,
      environment: "SANDBOX",
      store: "APP_STORE",
      ...overrides,
    },
  };
}

export { APP_USER_ID };
