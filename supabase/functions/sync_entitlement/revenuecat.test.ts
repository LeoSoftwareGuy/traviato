import {
  assertEquals,
  assertRejects,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { type FetchFn, fetchProEntitlement } from "./revenuecat.ts";

function fakeFetch(
  status: number,
  body: unknown,
  calls: { url: string; init?: RequestInit }[] = [],
): FetchFn {
  return (url, init) => {
    calls.push({ url, init });
    return Promise.resolve(new Response(JSON.stringify(body), { status }));
  };
}

Deno.test("reads the pro entitlement's expiry with the secret key", async () => {
  const calls: { url: string; init?: RequestInit }[] = [];
  const result = await fetchProEntitlement(
    "u1",
    "sk_test",
    fakeFetch(200, {
      subscriber: {
        entitlements: {
          pro: { expires_date: "2026-10-21T12:05:00Z" },
        },
      },
    }, calls),
  );

  assertEquals(result, { expiresAt: "2026-10-21T12:05:00.000Z" });
  assertEquals(calls[0].url, "https://api.revenuecat.com/v1/subscribers/u1");
  assertEquals(
    (calls[0].init?.headers as Record<string, string>).Authorization,
    "Bearer sk_test",
  );
});

Deno.test("a later grace period extends the expiry", async () => {
  const result = await fetchProEntitlement(
    "u1",
    "sk_test",
    fakeFetch(200, {
      subscriber: {
        entitlements: {
          pro: {
            expires_date: "2026-10-21T12:05:00Z",
            grace_period_expires_date: "2026-10-28T12:05:00Z",
          },
        },
      },
    }),
  );
  assertEquals(result, { expiresAt: "2026-10-28T12:05:00.000Z" });
});

Deno.test("a lifetime / promotional grant has no expiry", async () => {
  const result = await fetchProEntitlement(
    "u1",
    "sk_test",
    fakeFetch(200, {
      subscriber: { entitlements: { pro: { expires_date: null } } },
    }),
  );
  assertEquals(result, { expiresAt: null });
});

Deno.test("no pro entitlement returns null", async () => {
  const result = await fetchProEntitlement(
    "u1",
    "sk_test",
    fakeFetch(200, { subscriber: { entitlements: {} } }),
  );
  assertEquals(result, null);
});

Deno.test("a non-2xx response throws", async () => {
  await assertRejects(() =>
    fetchProEntitlement("u1", "sk_test", fakeFetch(500, {}))
  );
});
