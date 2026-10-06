import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { type Deps, handleRequest, MAX_AI_GENERATIONS } from "./handler.ts";
import { LOG_PREFIX, WrapUpGenerationError } from "./anthropic.ts";
import { fakeAuthClient, fakeSupabaseClient } from "./test_fakes.ts";
import { gatherTripData } from "./gather.ts";
import { computeAiInputHash } from "./ai_input_hash.ts";
import type { AiGeneratedFields } from "./ai_fields.ts";
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

Deno.test("a published wrap-up is frozen: returned as stored, nothing read or generated", async () => {
  let generateCalled = false;
  const client = fakeSupabaseClient(
    {
      trips: [{ id: TRIP_ID, user_id: OWNER_ID }],
      wrap_ups: [{
        content: validWrapUpContent,
        generated_at: "2026-06-06T00:00:00Z",
        published_at: "2026-06-07T00:00:00Z",
        ai_fields: validAiFields,
        ai_input_hash: "old",
        ai_generation_count: 1,
      }],
    },
    // Gathering would fail loudly — proves a frozen wrap-up never reads it.
    { photos: { message: "must not be read" } },
  );
  const deps = baseDeps({
    serviceClient: client,
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
  assertEquals(client.writes, []);
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

// ---- Drafts (#187) ---------------------------------------------------------

const DRAFT_TABLES = {
  trips: [{
    id: TRIP_ID,
    user_id: OWNER_ID,
    name: "Lisbon",
    destination: "Lisbon",
    start_date: "2026-06-01",
    end_date: "2026-06-03",
    cover_image_path: null,
    vibes: ["Foodie"],
  }],
  day_notes: [{ day_date: "2026-06-01", content: "Tram 28." }],
  photos: [
    {
      id: "p-new",
      day_date: "2026-06-02",
      created_at: "2026-06-02T10:00:00Z",
      storage_path: "u/t/p-new.jpg",
      caption: null,
    },
  ],
  bonus_task_assignments: [],
  points_ledger: [],
  user_achievements: [],
};

const OLD_FIELDS: AiGeneratedFields = {
  ...validAiFields,
  invitation_line2: "The old line.",
};

// The hash of DRAFT_TABLES' AI inputs, as the handler will compute it.
async function currentHash(): Promise<string> {
  return computeAiInputHash(
    await gatherTripData(fakeSupabaseClient(DRAFT_TABLES), TRIP_ID),
  );
}

function draftClient(row: Record<string, unknown>) {
  return fakeSupabaseClient({
    ...DRAFT_TABLES,
    wrap_ups: [{
      content: validWrapUpContent, // stale: references photos since deleted
      generated_at: "2026-06-06T00:00:00Z",
      published_at: null,
      ...row,
    }],
  });
}

function countingDeps(
  client: ReturnType<typeof fakeSupabaseClient>,
  result: () => Promise<AiGeneratedFields> = () =>
    Promise.resolve(validAiFields),
) {
  const calls = { n: 0 };
  const deps = baseDeps({
    serviceClient: client,
    generateAiFields: () => {
      calls.n++;
      return result();
    },
    log: () => {},
  });
  return { deps, calls };
}

Deno.test("draft with unchanged AI inputs: rebuilt from current photos, no AI call", async () => {
  const client = draftClient({
    ai_fields: OLD_FIELDS,
    ai_input_hash: await currentHash(),
    ai_generation_count: 1,
  });
  const { deps, calls } = countingDeps(client);

  const res = await handleRequest(request({ trip_id: TRIP_ID }), deps);
  const json = await res.json();

  assertEquals(res.status, 200);
  assertEquals(calls.n, 0);
  assertEquals(
    json.content.moments.map((m: { photo_id: string }) => m.photo_id),
    ["p-new"],
  );
  assertEquals(json.content.invitation.line2, "The old line.");
  const [write] = client.writes;
  assertEquals(write.op, "update");
  assertEquals(write.values.ai_generation_count, 1);
  assertEquals(write.filters, [
    ["eq", "trip_id", TRIP_ID],
    ["is", "published_at", null],
  ]);
});

Deno.test("draft whose notes changed: regenerates and counts the call", async () => {
  const client = draftClient({
    ai_fields: OLD_FIELDS,
    ai_input_hash: "hash-of-older-notes",
    ai_generation_count: 2,
  });
  const { deps, calls } = countingDeps(client);

  const res = await handleRequest(request({ trip_id: TRIP_ID }), deps);
  const json = await res.json();

  assertEquals(calls.n, 1);
  assertEquals(json.content.invitation.line2, validAiFields.invitation_line2);
  assertEquals(client.writes[0].values.ai_generation_count, 3);
  assertEquals(client.writes[0].values.ai_input_hash, await currentHash());
  assertEquals(client.writes[0].values.ai_fields, validAiFields);
});

Deno.test("draft at the AI cap: no call, last AI text reused, film still rebuilt", async () => {
  const client = draftClient({
    ai_fields: OLD_FIELDS,
    ai_input_hash: "hash-of-older-notes",
    ai_generation_count: MAX_AI_GENERATIONS,
  });
  const { deps, calls } = countingDeps(client);

  const res = await handleRequest(request({ trip_id: TRIP_ID }), deps);
  const json = await res.json();

  assertEquals(res.status, 200);
  assertEquals(calls.n, 0);
  assertEquals(json.content.invitation.line2, "The old line.");
  assertEquals(json.content.moments.length, 1);
  assertEquals(
    client.writes[0].values.ai_generation_count,
    MAX_AI_GENERATIONS,
  );
});

Deno.test("backfilled draft (NULL hash): adopts the current hash without an AI call", async () => {
  const client = draftClient({
    ai_fields: OLD_FIELDS,
    ai_input_hash: null,
    ai_generation_count: 1,
  });
  const { deps, calls } = countingDeps(client);

  await handleRequest(request({ trip_id: TRIP_ID }), deps);

  assertEquals(calls.n, 0);
  assertEquals(client.writes[0].values.ai_input_hash, await currentHash());
  assertEquals(client.writes[0].values.ai_generation_count, 1);
});

Deno.test("a failed regeneration reuses the last text, keeps the old hash, still counts", async () => {
  const client = draftClient({
    ai_fields: OLD_FIELDS,
    ai_input_hash: "hash-of-older-notes",
    ai_generation_count: 1,
  });
  const { deps, calls } = countingDeps(
    client,
    () => Promise.reject(new Error("overloaded")),
  );

  const res = await handleRequest(request({ trip_id: TRIP_ID }), deps);
  const json = await res.json();

  assertEquals(res.status, 200);
  assertEquals(calls.n, 1);
  assertEquals(json.content.invitation.line2, "The old line.");
  assertEquals(client.writes[0].values.ai_input_hash, "hash-of-older-notes");
  assertEquals(client.writes[0].values.ai_generation_count, 2);
});

Deno.test("first generation inserts a row counting one call", async () => {
  const client = fakeSupabaseClient({ ...DRAFT_TABLES, wrap_ups: [] });
  const { deps } = countingDeps(client);

  await handleRequest(request({ trip_id: TRIP_ID }), deps);

  const [write] = client.writes;
  assertEquals(write.op, "insert");
  assertEquals(write.values.trip_id, TRIP_ID);
  assertEquals(write.values.ai_generation_count, 1);
  assertEquals(write.values.ai_input_hash, await currentHash());
});

Deno.test("a failed first generation returns 502 and saves nothing", async () => {
  const client = fakeSupabaseClient({ ...DRAFT_TABLES, wrap_ups: [] });
  const { deps } = countingDeps(
    client,
    () => Promise.reject(new Error("overloaded")),
  );

  const res = await handleRequest(request({ trip_id: TRIP_ID }), deps);

  assertEquals(res.status, 502);
  assertEquals(client.writes, []);
});
