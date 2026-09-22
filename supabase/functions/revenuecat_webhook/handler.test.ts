import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { type Deps, handleRequest } from "./handler.ts";
import { fakeSupabaseClient } from "./test_fakes.ts";
import { APP_USER_ID, buildEvent } from "./test_fixtures.ts";

const AUTH_HEADER = "shared-secret-configured-in-revenuecat-dashboard";

function request(
  body: unknown,
  authHeader: string | null = AUTH_HEADER,
): Request {
  const headers = new Headers();
  if (authHeader) headers.set("Authorization", authHeader);
  return new Request("https://example.com/revenuecat_webhook", {
    method: "POST",
    headers,
    body: JSON.stringify(body),
  });
}

function baseDeps(overrides: Partial<Deps> = {}): Deps {
  return {
    serviceClient: fakeSupabaseClient(),
    expectedAuthHeader: AUTH_HEADER,
    ...overrides,
  };
}

Deno.test("handleRequest rejects a non-POST method", async () => {
  const req = new Request("https://example.com/revenuecat_webhook", {
    method: "GET",
  });
  const res = await handleRequest(req, baseDeps());
  assertEquals(res.status, 405);
});

Deno.test("handleRequest rejects a missing Authorization header", async () => {
  const res = await handleRequest(request(buildEvent(), null), baseDeps());
  assertEquals(res.status, 401);
});

Deno.test("handleRequest rejects a tampered Authorization header", async () => {
  const res = await handleRequest(
    request(buildEvent(), "not-the-right-secret"),
    baseDeps(),
  );
  assertEquals(res.status, 401);
});

Deno.test("handleRequest rejects a malformed payload", async () => {
  const res = await handleRequest(request({ not: "an event" }), baseDeps());
  assertEquals(res.status, 400);
});

Deno.test("TEST events are acknowledged without touching entitlements", async () => {
  const client = fakeSupabaseClient();
  const res = await handleRequest(
    request(buildEvent({ type: "TEST", entitlement_ids: [] })),
    baseDeps({ serviceClient: client }),
  );
  assertEquals(res.status, 200);
  assertEquals(client.upserts.length, 0);
});

Deno.test("an event for a different entitlement is skipped", async () => {
  const client = fakeSupabaseClient();
  const res = await handleRequest(
    request(buildEvent({ entitlement_ids: ["some_other_entitlement"] })),
    baseDeps({ serviceClient: client }),
  );
  assertEquals(res.status, 200);
  assertEquals(client.upserts.length, 0);
});

const accessEventTypes = [
  "INITIAL_PURCHASE",
  "RENEWAL",
  "PRODUCT_CHANGE",
  "UNCANCELLATION",
  "TRANSFER",
  "SUBSCRIPTION_EXTENDED",
];

for (const type of accessEventTypes) {
  Deno.test(`${type} upserts tier=pro with the reported expiration`, async () => {
    const client = fakeSupabaseClient();
    const res = await handleRequest(
      request(buildEvent({ type, expiration_at_ms: 1_731_536_000_000 })),
      baseDeps({ serviceClient: client }),
    );
    assertEquals(res.status, 200);
    assertEquals(client.upserts.length, 1);
    const [{ table, row, onConflict }] = client.upserts;
    assertEquals(table, "entitlements");
    assertEquals(onConflict, "user_id");
    assertEquals(row.user_id, APP_USER_ID);
    assertEquals(row.tier, "pro");
    assertEquals(row.expires_at, new Date(1_731_536_000_000).toISOString());
    assertEquals(row.revenuecat_customer_id, APP_USER_ID);
  });
}

for (const type of ["CANCELLATION", "BILLING_ISSUE"]) {
  Deno.test(
    `${type} refreshes expires_at but does NOT set tier (access continues until expiration)`,
    async () => {
      const client = fakeSupabaseClient();
      const res = await handleRequest(
        request(buildEvent({ type, expiration_at_ms: 1_731_536_000_000 })),
        baseDeps({ serviceClient: client }),
      );
      assertEquals(res.status, 200);
      const [{ row }] = client.upserts;
      assertEquals(row.user_id, APP_USER_ID);
      assertEquals("tier" in row, false);
      assertEquals(row.expires_at, new Date(1_731_536_000_000).toISOString());
    },
  );
}

Deno.test("EXPIRATION upserts tier=free", async () => {
  const client = fakeSupabaseClient();
  const res = await handleRequest(
    request(
      buildEvent({ type: "EXPIRATION", expiration_at_ms: 1_731_536_000_000 }),
    ),
    baseDeps({ serviceClient: client }),
  );
  assertEquals(res.status, 200);
  const [{ row }] = client.upserts;
  assertEquals(row.tier, "free");
  assertEquals(row.expires_at, new Date(1_731_536_000_000).toISOString());
});

Deno.test("an unrecognized event type is a no-op 200 (no retry storm)", async () => {
  const client = fakeSupabaseClient();
  const res = await handleRequest(
    request(buildEvent({ type: "SOMETHING_FUTURE_REVENUECAT_ADDS" })),
    baseDeps({ serviceClient: client }),
  );
  assertEquals(res.status, 200);
  assertEquals(client.upserts.length, 0);
});

Deno.test("a null expiration_at_ms (lifetime) upserts a null expires_at", async () => {
  const client = fakeSupabaseClient();
  const res = await handleRequest(
    request(buildEvent({ expiration_at_ms: null })),
    baseDeps({ serviceClient: client }),
  );
  assertEquals(res.status, 200);
  const [{ row }] = client.upserts;
  assertEquals(row.expires_at, null);
});

Deno.test("a database error on upsert surfaces as a 500", async () => {
  const client = fakeSupabaseClient({
    upsertError: { message: "permission denied for table entitlements" },
  });
  const res = await handleRequest(
    request(buildEvent()),
    baseDeps({ serviceClient: client }),
  );
  assertEquals(res.status, 500);
});
