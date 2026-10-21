import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { type Deps, handleRequest } from "./handler.ts";
import { fakeAuthClient, fakeServiceClient } from "./test_fakes.ts";

const USER_ID = "u1";
const NOW = new Date("2026-10-21T12:00:00Z");
const FUTURE = "2026-10-21T12:05:00.000Z"; // sandbox-short, still active
const PAST = "2026-10-21T11:55:00.000Z";

function request(authHeader: string | null = "Bearer jwt"): Request {
  const headers = new Headers();
  if (authHeader) headers.set("Authorization", authHeader);
  return new Request("https://example.com/sync_entitlement", {
    method: "POST",
    headers,
  });
}

function baseDeps(overrides: Partial<Deps> = {}): Deps {
  return {
    serviceClient: fakeServiceClient({
      rows: [{ user_id: USER_ID, tier: "free", expires_at: null }],
    }),
    authClient: fakeAuthClient(USER_ID),
    getProEntitlement: () => Promise.resolve(null),
    now: () => NOW,
    ...overrides,
  };
}

Deno.test("handleRequest rejects a non-POST method", async () => {
  const req = new Request("https://example.com/sync_entitlement", {
    method: "GET",
  });
  const res = await handleRequest(req, baseDeps());
  assertEquals(res.status, 405);
});

Deno.test("handleRequest rejects a missing Authorization header", async () => {
  const res = await handleRequest(request(null), baseDeps());
  assertEquals(res.status, 401);
});

Deno.test("handleRequest rejects an invalid session", async () => {
  const res = await handleRequest(
    request(),
    baseDeps({ authClient: fakeAuthClient(null) }),
  );
  assertEquals(res.status, 401);
});

Deno.test(
  "an active RevenueCat pro entitlement repairs a stale free row",
  async () => {
    const serviceClient = fakeServiceClient({
      rows: [{ user_id: USER_ID, tier: "free", expires_at: null }],
    });
    const lookedUp: string[] = [];
    const res = await handleRequest(
      request(),
      baseDeps({
        serviceClient,
        getProEntitlement: (id) => {
          lookedUp.push(id);
          return Promise.resolve({ expiresAt: FUTURE });
        },
      }),
    );

    assertEquals(res.status, 200);
    assertEquals(lookedUp, [USER_ID]); // keyed off the JWT, nothing else
    assertEquals(serviceClient.upserts, [{
      table: "entitlements",
      row: {
        user_id: USER_ID,
        tier: "pro",
        expires_at: FUTURE,
        revenuecat_customer_id: USER_ID,
      },
      onConflict: "user_id",
    }]);
    assertEquals(await res.json(), {
      tier: "pro",
      revenuecat_customer_id: USER_ID,
      expires_at: FUTURE,
    });
  },
);

Deno.test("a non-expiring pro grant is written with a null expiry", async () => {
  const serviceClient = fakeServiceClient();
  const res = await handleRequest(
    request(),
    baseDeps({
      serviceClient,
      getProEntitlement: () => Promise.resolve({ expiresAt: null }),
    }),
  );
  assertEquals(res.status, 200);
  assertEquals(serviceClient.upserts[0].row.expires_at, null);
  assertEquals((await res.json()).tier, "pro");
});

Deno.test("no pro entitlement in RevenueCat never writes", async () => {
  const serviceClient = fakeServiceClient({
    rows: [{ user_id: USER_ID, tier: "free", expires_at: null }],
  });
  const res = await handleRequest(request(), baseDeps({ serviceClient }));

  assertEquals(res.status, 200);
  assertEquals(serviceClient.upserts, []);
  assertEquals((await res.json()).tier, "free");
});

Deno.test(
  "an expired RevenueCat entitlement never writes (no downgrade either)",
  async () => {
    const serviceClient = fakeServiceClient({
      rows: [{ user_id: USER_ID, tier: "pro", expires_at: FUTURE }],
    });
    const res = await handleRequest(
      request(),
      baseDeps({
        serviceClient,
        getProEntitlement: () => Promise.resolve({ expiresAt: PAST }),
      }),
    );

    assertEquals(res.status, 200);
    assertEquals(serviceClient.upserts, []);
    assertEquals((await res.json()).tier, "pro"); // left to the webhook
  },
);

Deno.test("a missing row reads back as free", async () => {
  const res = await handleRequest(
    request(),
    baseDeps({ serviceClient: fakeServiceClient() }),
  );
  assertEquals(res.status, 200);
  assertEquals(await res.json(), { tier: "free" });
});

Deno.test("a RevenueCat outage is a 502, not a silent free", async () => {
  const serviceClient = fakeServiceClient();
  const res = await handleRequest(
    request(),
    baseDeps({
      serviceClient,
      getProEntitlement: () => Promise.reject(new Error("503")),
    }),
  );
  assertEquals(res.status, 502);
  assertEquals(serviceClient.upserts, []);
});

Deno.test("an upsert failure is a 500", async () => {
  const res = await handleRequest(
    request(),
    baseDeps({
      serviceClient: fakeServiceClient({ upsertError: { message: "boom" } }),
      getProEntitlement: () => Promise.resolve({ expiresAt: FUTURE }),
    }),
  );
  assertEquals(res.status, 500);
});

Deno.test("a read-back failure is a 500", async () => {
  const res = await handleRequest(
    request(),
    baseDeps({
      serviceClient: fakeServiceClient({ readError: { message: "boom" } }),
    }),
  );
  assertEquals(res.status, 500);
});
