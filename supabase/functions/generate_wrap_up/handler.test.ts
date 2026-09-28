import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { type Deps, handleRequest } from "./handler.ts";
import { LOG_PREFIX, WrapUpGenerationError } from "./anthropic.ts";
import { fakeAuthClient, fakeSupabaseClient } from "./test_fakes.ts";
import { validAiFields, validWrapUpContent } from "./test_fixtures.ts";

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
      trips: [{
        id: TRIP_ID,
        user_id: OWNER_ID,
        name: "Untitled Trip",
        cover_image_path: null,
        vibes: [],
      }],
      wrap_ups: [],
      day_notes: [],
      photos: [],
      bonus_task_assignments: [],
      points_ledger: [],
      user_achievements: [],
    }),
    authClient: fakeAuthClient({ id: OWNER_ID }),
    generateAiFields: () => Promise.resolve(validAiFields),
    ...overrides,
  };
}

Deno.test("handleRequest returns 401 without an Authorization header", async () => {
  const res = await handleRequest(
    request({ trip_id: TRIP_ID }, null),
    baseDeps(),
  );
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
  assertEquals(
    json.error,
    "trip lookup failed: permission denied for table trips",
  );
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
      { photos: { message: "permission denied for table photos" } },
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

Deno.test("handleRequest short-circuits on existing content without calling generateAiFields", async () => {
  let generateCalled = false;
  const deps = baseDeps({
    serviceClient: fakeSupabaseClient({
      trips: [{ id: TRIP_ID, user_id: OWNER_ID }],
      wrap_ups: [{
        content: validWrapUpContent,
        generated_at: "2026-06-06T00:00:00Z",
      }],
    }),
    generateAiFields: () => {
      generateCalled = true;
      return Promise.resolve(validAiFields);
    },
  });

  const res = await handleRequest(request({ trip_id: TRIP_ID }), deps);
  const json = await res.json();

  assertEquals(res.status, 200);
  assertEquals(json.content, validWrapUpContent);
  assertEquals(generateCalled, false);
});

Deno.test("handleRequest generates, assembles, saves and returns new content", async () => {
  const res = await handleRequest(request({ trip_id: TRIP_ID }), baseDeps());
  const json = await res.json();

  assertEquals(res.status, 200);
  assertEquals(json.content.invitation.line2, validAiFields.invitation_line2);
  assertEquals(json.content.bridges, validAiFields.bridges);
  assertEquals(
    json.content.keepsake.closing_quote,
    validAiFields.keepsake_closing_quote,
  );
  assertEquals(json.content.moments, []); // no photos in this fixture's trip
  assertEquals(json.content.footnote.photo_count, 0);
});

Deno.test("handleRequest returns 502 when generation fails", async () => {
  const deps = baseDeps({
    generateAiFields: () => Promise.reject(new Error("model refused")),
    log: () => {},
  });
  const res = await handleRequest(request({ trip_id: TRIP_ID }), deps);
  assertEquals(res.status, 502);
});

// #166: the 502 body says which upstream failure it was, and one summary
// line with the trip id is logged for the dashboard.
Deno.test("handleRequest's 502 carries the generation error's code and detail, and logs it", async () => {
  const lines: string[] = [];
  const deps = baseDeps({
    generateAiFields: () =>
      Promise.reject(
        new WrapUpGenerationError(
          "ai_upstream_error",
          "Anthropic API error: 529",
        ),
      ),
    log: (line) => lines.push(line),
  });
  const res = await handleRequest(request({ trip_id: TRIP_ID }), deps);
  assertEquals(res.status, 502);
  assertEquals(await res.json(), {
    error: "wrap-up generation failed: Anthropic API error: 529",
    code: "ai_upstream_error",
    detail: "Anthropic API error: 529",
  });
  assertEquals(lines.length, 1);
  const logged = JSON.parse(lines[0].slice(LOG_PREFIX.length + 1));
  assertEquals(logged, {
    event: "generation_failed",
    trip_id: TRIP_ID,
    code: "ai_upstream_error",
    detail: "Anthropic API error: 529",
  });
});
