import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { handleRequest, type Deps } from "./handler.ts";
import { fakeAuthClient, fakeSupabaseClient } from "./test_fakes.ts";
import { validScreenplay } from "./test_fixtures.ts";

const TRIP_ID = "trip-1";
const OWNER_ID = "user-1";

function request(body: unknown, authHeader: string | null = "Bearer token") {
  const headers = new Headers();
  if (authHeader) headers.set("Authorization", authHeader);
  return new Request("https://example.com/generate_wrap_up", {
    method: "POST",
    headers,
    body: JSON.stringify(body),
  });
}

function baseDeps(overrides: Partial<Deps> = {}): Deps {
  return {
    serviceClient: fakeSupabaseClient({
      trips: [{ id: TRIP_ID, user_id: OWNER_ID }],
      wrap_ups: [],
      quests: [],
      day_notes: [],
      photos: [],
      user_achievements: [],
    }),
    authClient: fakeAuthClient({ id: OWNER_ID }),
    generateScreenplay: () => Promise.resolve(validScreenplay),
    ...overrides,
  };
}

Deno.test("handleRequest returns 401 without an Authorization header", async () => {
  const res = await handleRequest(request({ trip_id: TRIP_ID }, null), baseDeps());
  assertEquals(res.status, 401);
});

Deno.test("handleRequest returns 401 when the session is invalid", async () => {
  const res = await handleRequest(
    request({ trip_id: TRIP_ID }),
    baseDeps({ authClient: fakeAuthClient(null) }),
  );
  assertEquals(res.status, 401);
});

Deno.test("handleRequest returns 400 without a trip_id", async () => {
  const res = await handleRequest(request({}), baseDeps());
  assertEquals(res.status, 400);
});

Deno.test("handleRequest returns 404 when the trip doesn't exist", async () => {
  const deps = baseDeps({ serviceClient: fakeSupabaseClient({ trips: [] }) });
  const res = await handleRequest(request({ trip_id: TRIP_ID }), deps);
  assertEquals(res.status, 404);
});

// #109: a permission-denied error on the trip lookup must surface as a
// distinct 500, never collapse into the same "not found" 404 a genuinely
// missing trip returns — this exact confusion hid the service_role grants
// bug in production/local testing.
Deno.test("handleRequest returns 500 (not 404) when the trip lookup errors", async () => {
  const deps = baseDeps({
    serviceClient: fakeSupabaseClient(
      { trips: [{ id: TRIP_ID, user_id: OWNER_ID }] },
      { trips: { message: "permission denied for table trips" } },
    ),
  });
  const res = await handleRequest(request({ trip_id: TRIP_ID }), deps);
  const json = await res.json();
  assertEquals(res.status, 500);
  assertEquals(json.error, "trip lookup failed: permission denied for table trips");
});

Deno.test("handleRequest returns 500 when the existing wrap_ups lookup errors", async () => {
  const deps = baseDeps({
    serviceClient: fakeSupabaseClient(
      { trips: [{ id: TRIP_ID, user_id: OWNER_ID }] },
      { wrap_ups: { message: "permission denied for table wrap_ups" } },
    ),
  });
  const res = await handleRequest(request({ trip_id: TRIP_ID }), deps);
  assertEquals(res.status, 500);
});

Deno.test("handleRequest returns 500 when gathering trip data fails", async () => {
  const deps = baseDeps({
    serviceClient: fakeSupabaseClient(
      { trips: [{ id: TRIP_ID, user_id: OWNER_ID }], wrap_ups: [] },
      { quests: { message: "permission denied for table quests" } },
    ),
  });
  const res = await handleRequest(request({ trip_id: TRIP_ID }), deps);
  assertEquals(res.status, 500);
});

Deno.test("handleRequest returns 403 when the caller doesn't own the trip", async () => {
  const deps = baseDeps({ authClient: fakeAuthClient({ id: "someone-else" }) });
  const res = await handleRequest(request({ trip_id: TRIP_ID }), deps);
  assertEquals(res.status, 403);
});

Deno.test("handleRequest short-circuits on existing content without calling generateScreenplay", async () => {
  let generateCalled = false;
  const deps = baseDeps({
    serviceClient: fakeSupabaseClient({
      trips: [{ id: TRIP_ID, user_id: OWNER_ID }],
      wrap_ups: [{ content: validScreenplay, generated_at: "2026-06-06T00:00:00Z" }],
    }),
    generateScreenplay: () => {
      generateCalled = true;
      return Promise.resolve(validScreenplay);
    },
  });

  const res = await handleRequest(request({ trip_id: TRIP_ID }), deps);
  const json = await res.json();

  assertEquals(res.status, 200);
  assertEquals(json.content, validScreenplay);
  assertEquals(generateCalled, false);
});

Deno.test("handleRequest generates, saves and returns a new screenplay", async () => {
  const res = await handleRequest(request({ trip_id: TRIP_ID }), baseDeps());
  const json = await res.json();

  assertEquals(res.status, 200);
  assertEquals(json.content, validScreenplay);
});

Deno.test("handleRequest returns 502 when generation fails", async () => {
  const deps = baseDeps({
    generateScreenplay: () => Promise.reject(new Error("model refused")),
  });
  const res = await handleRequest(request({ trip_id: TRIP_ID }), deps);
  assertEquals(res.status, 502);
});
