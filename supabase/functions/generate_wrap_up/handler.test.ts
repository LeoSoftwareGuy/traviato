import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  type Deps,
  handleRequest,
  MAX_AI_GENERATIONS,
  parseUtcOffset,
} from "./handler.ts";
import { LOG_PREFIX, WrapUpGenerationError } from "./anthropic.ts";
import { fakeAuthClient, fakeSupabaseClient } from "./test_fakes.ts";
import { gatherTripData } from "./gather.ts";
import { computeAiInputHash } from "./ai_input_hash.ts";
import type { AiGeneratedFields } from "./ai_fields.ts";
import { validAiFields, validWrapUpContent } from "./test_fixtures.ts";
import { DIRECTOR_VERSION, type DirectorRecord } from "./director.ts";
import {
  directorTripData,
  goldenVowsPlan,
  keepsakePlan,
  neonNightPlan,
  skyStoryPlan,
} from "./director_fixtures.ts";
import { useFilmLengthRuleForTests } from "./film_length.ts";

// These tests are about other rules: every film at its longest (#434).
useFilmLengthRuleForTests(false);

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

// The film-building tests use small memories; the minimum has tests of
// its own (#432).
const NO_MINIMUMS = { photos: 0, notes: 0 };

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
      journal_notes: [],
      photos: [],
      bonus_task_assignments: [],
      points_ledger: [],
      user_achievements: [],
    }),
    authClient: fakeAuthClient({ id: OWNER_ID }),
    minimums: NO_MINIMUMS,
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
    minimums: NO_MINIMUMS,
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

function keptClient() {
  return fakeSupabaseClient({
    trips: [{
      id: TRIP_ID,
      user_id: OWNER_ID,
      name: "Lisbon",
      start_date: "2026-06-01",
      end_date: "2026-06-03",
      cover_image_path: null,
      vibes: [],
    }],
    wrap_ups: [{
      content: validWrapUpContent,
      generated_at: "2026-06-06T00:00:00Z",
      published_at: "2026-06-07T00:00:00Z",
      ai_fields: validAiFields,
      ai_input_hash: "old",
      ai_generation_count: 1,
    }],
    journal_notes: [{
      day_date: "2026-06-01",
      content: "Changed after keeping.",
    }],
    photos: [
      {
        id: "kept",
        day_date: "2026-06-01",
        taken_at: null,
        created_at: "2026-06-01T10:00:00Z",
        storage_path: "u/t/kept.jpg",
        caption: null,
        use_in_wrap_up: true,
      },
      {
        id: "left-out",
        day_date: "2026-06-02",
        taken_at: null,
        created_at: "2026-06-02T10:00:00Z",
        storage_path: "u/t/left-out.jpg",
        caption: null,
        use_in_wrap_up: false,
      },
    ],
    bonus_task_assignments: [],
    points_ledger: [],
    user_achievements: [],
  });
}

Deno.test("rebuild on a kept wrap-up re-assembles the film with its stored AI lines (#294)", async () => {
  let generateCalled = false;
  const client = keptClient();
  const deps = baseDeps({
    serviceClient: client,
    minimums: NO_MINIMUMS,
    generateAiFields: () => {
      generateCalled = true;
      return Promise.resolve(validAiFields);
    },
  });

  const res = await handleRequest(
    request({ trip_id: TRIP_ID, rebuild: true }),
    deps,
  );
  const json = await res.json();

  assertEquals(res.status, 200);
  // Notes changed since keeping, yet no AI call: kept lines are reused.
  assertEquals(generateCalled, false);
  assertEquals(json.content.bridges, validAiFields.bridges);
  assertEquals(
    json.content.moments.map((m: { photo_id: string }) => m.photo_id),
    ["kept"],
  );
  assertEquals(client.writes.length, 1);
  const write = client.writes[0];
  assertEquals(write.op, "update");
  assertEquals(Object.keys(write.values).sort(), ["content", "generated_at"]);
  assertEquals(write.filters, [
    ["eq", "trip_id", TRIP_ID],
    ["not", "published_at", null],
  ]);
});

Deno.test("a kept wrap-up without rebuild stays frozen even when picks changed", async () => {
  const client = keptClient();
  const res = await handleRequest(
    request({ trip_id: TRIP_ID }),
    baseDeps({ serviceClient: client }),
  );
  const json = await res.json();

  assertEquals(res.status, 200);
  assertEquals(json.content, validWrapUpContent);
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
    minimums: NO_MINIMUMS,
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
    minimums: NO_MINIMUMS,
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
  journal_notes: [{ day_date: "2026-06-01", content: "Tram 28." }],
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
    minimums: NO_MINIMUMS,
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

Deno.test("the requested language reaches the AI and its hash (#250)", async () => {
  const client = draftClient({
    ai_fields: OLD_FIELDS,
    ai_input_hash: await currentHash(), // English, unchanged inputs
    ai_generation_count: 1,
  });
  const languages: string[] = [];
  const deps = baseDeps({
    serviceClient: client,
    minimums: NO_MINIMUMS,
    generateAiFields: (_tripData, language) => {
      languages.push(language);
      return Promise.resolve(validAiFields);
    },
    log: () => {},
  });

  const res = await handleRequest(
    request({ trip_id: TRIP_ID, language: "ru" }),
    deps,
  );

  assertEquals(res.status, 200);
  assertEquals(languages, ["ru"]);
  assertEquals(client.writes[0].values.ai_generation_count, 2);
  assertEquals(
    client.writes[0].values.ai_input_hash,
    await computeAiInputHash(
      await gatherTripData(fakeSupabaseClient(DRAFT_TABLES), TRIP_ID),
      "ru",
    ),
  );
});

Deno.test("no or unknown language is English: an English draft stays put", async () => {
  for (const language of [undefined, "et"]) {
    const client = draftClient({
      ai_fields: OLD_FIELDS,
      ai_input_hash: await currentHash(),
      ai_generation_count: 1,
    });
    const { deps, calls } = countingDeps(client);

    await handleRequest(request({ trip_id: TRIP_ID, language }), deps);

    assertEquals(calls.n, 0, `language: ${language}`);
  }
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

// ---- 16 moments (#304) -------------------------------------------------

Deno.test("moment_slots: 16 builds the 16-moment film; without it the 8-moment one, unmarked", async () => {
  const photos = Array.from({ length: 20 }, (_, i) => ({
    id: `p${i}`,
    day_date: "2026-06-01",
    created_at: `2026-06-01T10:${String(i).padStart(2, "0")}:00Z`,
    storage_path: `u/t/p${i}.jpg`,
    caption: null,
  }));
  const deps = () =>
    baseDeps({
      serviceClient: fakeSupabaseClient({
        ...DRAFT_TABLES,
        photos,
        wrap_ups: [],
      }),
    });

  const sixteen = await (await handleRequest(
    request({ trip_id: TRIP_ID, moment_slots: 16 }),
    deps(),
  )).json();
  assertEquals(sixteen.content.moment_slots, 16);
  assertEquals(sixteen.content.moments.length, 16);

  const eight = await (await handleRequest(
    request({ trip_id: TRIP_ID }),
    deps(),
  )).json();
  assertEquals("moment_slots" in eight.content, false);
  assertEquals(eight.content.moments.length, 8);
});

// --- Director (#328) ---

function plannedRecord(): DirectorRecord {
  return {
    director_version: DIRECTOR_VERSION,
    status: "planned",
    plan: keepsakePlan(),
    problems: [],
    attempts: 1,
    model: "claude-sonnet-5",
    ran_at: "2026-11-08T12:00:00Z",
    photos: { plannable: 12, analysed_now: 12, cached: 0, failed: 0 },
    failed_ids: [],
    photo_paths: {},
    usage: { calls: [], input_tokens: 10, output_tokens: 5, estimated_usd: 0 },
  };
}

// A draft memory whose photos and notes fit keepsakePlan().
function directorClient(
  wrapUps: Record<string, unknown>[] = [],
  vibes = directorTripData().trip.vibes,
) {
  const data = directorTripData();
  return fakeSupabaseClient({
    trips: [{ id: TRIP_ID, user_id: OWNER_ID, ...data.trip, vibes }],
    wrap_ups: wrapUps,
    journal_notes: data.notes,
    photos: data.photos,
    bonus_task_assignments: [],
    points_ledger: [],
    user_achievements: [],
  });
}

function directorDeps(
  client: ReturnType<typeof fakeSupabaseClient>,
  { enabled = true, record = plannedRecord() } = {},
) {
  const runs: string[] = [];
  return {
    runs,
    deps: baseDeps({
      serviceClient: client,
      director: {
        isEnabledFor: (userId) => enabled && userId === OWNER_ID,
        run: (tripId) => {
          runs.push(tripId);
          return Promise.resolve(record);
        },
      },
    }),
  };
}

Deno.test("director off: no run, no plan in the film, no director column written", async () => {
  const client = directorClient();
  const { runs, deps } = directorDeps(client, { enabled: false });

  const res = await handleRequest(request({ trip_id: TRIP_ID }), deps);
  const json = await res.json();

  assertEquals(res.status, 200);
  assertEquals(runs, []);
  assertEquals("plan" in json.content, false);
  assertEquals("director" in client.writes[0].values, false);
});

Deno.test("director on: the first build runs it, stores the run and merges the plan", async () => {
  const client = directorClient();
  const { runs, deps } = directorDeps(client);

  const res = await handleRequest(request({ trip_id: TRIP_ID }), deps);
  const json = await res.json();

  assertEquals(res.status, 200);
  assertEquals(runs, [TRIP_ID]);
  assertEquals(json.content.plan_version, 2);
  assertEquals(json.content.plan, keepsakePlan());
  // Everything the current player reads is still there.
  assertEquals(json.content.bridges, validAiFields.bridges);
  assertEquals(json.content.moments.length > 0, true);
  assertEquals(client.writes[0].values.director, {
    ...plannedRecord(),
    run_count: 1,
  });
});

Deno.test("director on, already run: no second run, the stored plan is still merged", async () => {
  const client = directorClient([{
    content: validWrapUpContent,
    generated_at: "2026-11-01T00:00:00Z",
    published_at: null,
    ai_fields: validAiFields,
    ai_input_hash: null,
    ai_generation_count: 1,
    director: plannedRecord(),
  }]);
  const { runs, deps } = directorDeps(client);

  const res = await handleRequest(request({ trip_id: TRIP_ID }), deps);
  const json = await res.json();

  assertEquals(runs, []);
  assertEquals(json.content.plan, keepsakePlan());
  assertEquals("director" in client.writes[0].values, false);
});

Deno.test("a fallback run leaves today's template film", async () => {
  const client = directorClient();
  const { deps } = directorDeps(client, {
    record: { ...plannedRecord(), status: "fallback", plan: null },
  });

  const res = await handleRequest(request({ trip_id: TRIP_ID }), deps);
  const json = await res.json();

  assertEquals(res.status, 200);
  assertEquals("plan" in json.content, false);
  assertEquals(client.writes[0].values.director.status, "fallback");
});

Deno.test("rerun is refused when the director isn't enabled for the caller", async () => {
  const client = directorClient();
  const { runs, deps } = directorDeps(client, { enabled: false });

  const res = await handleRequest(
    request({ trip_id: TRIP_ID, director: "rerun" }),
    deps,
  );
  const json = await res.json();

  assertEquals(res.status, 403);
  assertEquals(json.code, "director_disabled");
  assertEquals(runs, []);
  assertEquals(client.writes, []);
});

Deno.test("rerun on a draft runs again even with a stored run", async () => {
  const client = directorClient([{
    content: validWrapUpContent,
    generated_at: "2026-11-01T00:00:00Z",
    published_at: null,
    ai_fields: validAiFields,
    ai_input_hash: null,
    ai_generation_count: 1,
    director: { ...plannedRecord(), status: "fallback", plan: null },
  }]);
  const { runs, deps } = directorDeps(client);

  const res = await handleRequest(
    request({ trip_id: TRIP_ID, director: "rerun" }),
    deps,
  );
  const json = await res.json();

  assertEquals(runs, [TRIP_ID]);
  assertEquals(json.director.status, "planned");
  assertEquals(json.content.plan_version, 2);
});

Deno.test("rerun on a kept film writes only wrap_ups.director, content untouched", async () => {
  const client = keptClient();
  const { runs, deps } = directorDeps(client);

  const res = await handleRequest(
    request({ trip_id: TRIP_ID, director: "rerun" }),
    deps,
  );
  const json = await res.json();

  assertEquals(res.status, 200);
  assertEquals(runs, [TRIP_ID]);
  assertEquals(json.content, validWrapUpContent);
  assertEquals(json.director, { ...plannedRecord(), run_count: 1 });
  assertEquals(client.writes.length, 1);
  assertEquals(Object.keys(client.writes[0].values), ["director"]);
  assertEquals(client.writes[0].filters, [
    ["eq", "trip_id", TRIP_ID],
    ["not", "published_at", null],
  ]);
});

Deno.test("a kept film is never planned by an ordinary open", async () => {
  const client = keptClient();
  const { runs, deps } = directorDeps(client);

  const res = await handleRequest(request({ trip_id: TRIP_ID }), deps);
  const json = await res.json();

  assertEquals(runs, []);
  assertEquals(json.content, validWrapUpContent);
  assertEquals(client.writes, []);
});

// --- Sky Story (#345) ---

Deno.test("a draft gets content.sky from the director's pages", async () => {
  const client = directorClient();
  const { deps } = directorDeps(client, {
    record: { ...plannedRecord(), sky_story: skyStoryPlan() },
  });

  const json = await (await handleRequest(request({ trip_id: TRIP_ID }), deps))
    .json();

  assertEquals(json.content.sky.source, "director");
  assertEquals(
    json.content.sky.pages.map((p: { headline: string }) => p.headline),
    skyStoryPlan().pages.map((p) => p.headline),
  );
  assertEquals(json.content.sky.moment_count, 12);
  assertEquals(client.writes[0].values.content.sky, json.content.sky);
});

Deno.test("director off or without pages: code-built content.sky", async () => {
  for (const enabled of [false, true]) {
    const client = directorClient();
    const { deps } = directorDeps(client, {
      enabled,
      record: { ...plannedRecord(), sky_story: null, hero_scores: { p02: 5 } },
    });
    const json = await (await handleRequest(
      request({ trip_id: TRIP_ID }),
      deps,
    )).json();
    assertEquals(json.content.sky.source, "code");
    assertEquals(json.content.sky.pages.length, 3);
    assertEquals(json.content.sky.pages[0].headline, null);
    if (enabled) {
      // Code-built pages still use the director's hero scores.
      assertEquals(json.content.sky.pages[0].hero_photo_id, "p02");
    }
  }
});

Deno.test("content.sky signs with the profile's first name", async () => {
  const data = directorTripData();
  const client = fakeSupabaseClient({
    trips: [{ id: TRIP_ID, user_id: OWNER_ID, ...data.trip }],
    wrap_ups: [],
    journal_notes: data.notes,
    photos: data.photos,
    bonus_task_assignments: [],
    points_ledger: [],
    user_achievements: [],
    profiles: [{ username: "Mari Tamm" }],
  });
  const { deps } = directorDeps(client, { enabled: false });

  const json = await (await handleRequest(request({ trip_id: TRIP_ID }), deps))
    .json();

  assertEquals(json.content.sky.first_name, "Mari");
});

Deno.test("a memory without photos gets no content.sky", async () => {
  const data = directorTripData();
  const client = fakeSupabaseClient({
    trips: [{ id: TRIP_ID, user_id: OWNER_ID, ...data.trip }],
    wrap_ups: [],
    journal_notes: data.notes,
    photos: [],
    bonus_task_assignments: [],
    points_ledger: [],
    user_achievements: [],
  });
  const { deps } = directorDeps(client, { enabled: false });

  const json = await (await handleRequest(request({ trip_id: TRIP_ID }), deps))
    .json();

  assertEquals("sky" in json.content, false);
});

Deno.test("kept films never gain content.sky, rebuilt or not", async () => {
  const client = keptClient();
  const { deps } = directorDeps(client);
  const opened = await (await handleRequest(
    request({ trip_id: TRIP_ID }),
    deps,
  )).json();
  assertEquals("sky" in opened.content, false);

  const rebuilt = await (await handleRequest(
    request({ trip_id: TRIP_ID, rebuild: true }),
    directorDeps(keptClient()).deps,
  )).json();
  assertEquals("sky" in rebuilt.content, false);
});

Deno.test("the director runs again when photo days changed, and counts the run", async () => {
  const stale = {
    ...plannedRecord(),
    photo_days: ["2026-09-01"],
    run_count: 2,
  };
  const client = directorClient([{
    content: validWrapUpContent,
    generated_at: "2026-11-01T00:00:00Z",
    published_at: null,
    ai_fields: validAiFields,
    ai_input_hash: null,
    ai_generation_count: 1,
    director: stale,
  }]);
  const { runs, deps } = directorDeps(client);

  await handleRequest(request({ trip_id: TRIP_ID }), deps);

  assertEquals(runs, [TRIP_ID]);
  assertEquals(client.writes[0].values.director.run_count, 3);
});

Deno.test("rebuilding a film kept as a Sky Story rebuilds its pages (#345)", async () => {
  const data = directorTripData();
  const client = fakeSupabaseClient({
    trips: [{ id: TRIP_ID, user_id: OWNER_ID, ...data.trip }],
    wrap_ups: [{
      content: { ...validWrapUpContent, sky: { sky_version: 1, pages: [] } },
      generated_at: "2026-09-05T00:00:00Z",
      published_at: "2026-09-06T00:00:00Z",
      ai_fields: validAiFields,
      ai_input_hash: "old",
      ai_generation_count: 1,
      director: { ...plannedRecord(), sky_story: skyStoryPlan() },
    }],
    journal_notes: data.notes,
    // A photo of day 2's page was deleted since: the director's pages no
    // longer fit, so they're rebuilt by code.
    photos: data.photos.filter((p) => p.id !== "p05"),
    bonus_task_assignments: [],
    points_ledger: [],
    user_achievements: [],
  });
  const { runs, deps } = directorDeps(client);

  const json = await (await handleRequest(
    request({ trip_id: TRIP_ID, rebuild: true }),
    deps,
  )).json();

  assertEquals(runs, []);
  assertEquals(json.content.sky.source, "code");
  assertEquals(json.content.sky.pages.length, 3);
  assertEquals(client.writes[0].values.content.sky, json.content.sky);

  // While they still fit, the director's pages are kept.
  const fits = fakeSupabaseClient({
    trips: [{ id: TRIP_ID, user_id: OWNER_ID, ...data.trip }],
    wrap_ups: [{
      content: { ...validWrapUpContent, sky: { sky_version: 1, pages: [] } },
      generated_at: "2026-09-05T00:00:00Z",
      published_at: "2026-09-06T00:00:00Z",
      ai_fields: validAiFields,
      ai_input_hash: "old",
      ai_generation_count: 1,
      director: { ...plannedRecord(), sky_story: skyStoryPlan() },
    }],
    journal_notes: data.notes,
    photos: data.photos,
    bonus_task_assignments: [],
    points_ledger: [],
    user_achievements: [],
  });
  const kept = await (await handleRequest(
    request({ trip_id: TRIP_ID, rebuild: true }),
    directorDeps(fits).deps,
  )).json();
  assertEquals(kept.content.sky.source, "director");
});

// --- Golden Vows (#346) ---

function goldenVowsRecord(): DirectorRecord {
  return {
    ...plannedRecord(),
    sky_story: skyStoryPlan(),
    golden_vows: goldenVowsPlan(),
    orientations: {},
  };
}

function keptGoldenVowsClient(photos = directorTripData().photos) {
  const data = directorTripData();
  return fakeSupabaseClient({
    trips: [{ id: TRIP_ID, user_id: OWNER_ID, ...data.trip }],
    wrap_ups: [{
      content: {
        ...validWrapUpContent,
        sky: { sky_version: 1, pages: [] },
        golden_vows: { gv_version: 1 },
      },
      generated_at: "2026-09-05T00:00:00Z",
      published_at: "2026-09-06T00:00:00Z",
      ai_fields: validAiFields,
      ai_input_hash: "old",
      ai_generation_count: 1,
      director: goldenVowsRecord(),
    }],
    journal_notes: data.notes,
    photos,
    bonus_task_assignments: [],
    points_ledger: [],
    user_achievements: [],
  });
}

Deno.test("a draft gets content.golden_vows from the director's section", async () => {
  const client = directorClient([], ["Romantic"]);
  const { deps } = directorDeps(client, { record: goldenVowsRecord() });

  const json = await (await handleRequest(request({ trip_id: TRIP_ID }), deps))
    .json();

  const gv = json.content.golden_vows;
  assertEquals(gv.occasion, "wedding");
  assertEquals(gv.names, "Amsterdam");
  assertEquals(gv.heroes.map((h: { note: string | null }) => h.note), [
    "Bikes everywhere",
    null,
  ]);
  assertEquals(gv.heart_photo_ids.length, 12);
  assertEquals(json.content.film_style, "golden_vows");
  assertEquals(json.content.film_report.source, "director");
  // Code-built Sky pages are there too: the app's safety net.
  assertEquals(json.content.sky.source, "code");
  assertEquals(client.writes[0].values.content.golden_vows, gv);
});

Deno.test("a Romantic memory always plays Golden Vows: no section, director off, unhealable (#433)", async () => {
  const romantic = (wrapUps: Record<string, unknown>[] = []) =>
    directorClient(wrapUps, ["Romantic"]);
  const none = await (await handleRequest(
    request({ trip_id: TRIP_ID }),
    directorDeps(romantic()).deps,
  )).json();
  assertEquals(none.content.golden_vows.occasion, "romance");
  assertEquals(none.content.film_report.source, "code");

  const off = await (await handleRequest(
    request({ trip_id: TRIP_ID }),
    directorDeps(romantic(), {
      enabled: false,
      record: goldenVowsRecord(),
    }).deps,
  )).json();
  assertEquals(off.content.film_style, "golden_vows");
  assertEquals(off.content.golden_vows.heroes.length >= 2, true);

  const data = directorTripData();
  const deleted = fakeSupabaseClient({
    trips: [{
      id: TRIP_ID,
      user_id: OWNER_ID,
      ...data.trip,
      vibes: ["Romantic"],
    }],
    wrap_ups: [],
    journal_notes: data.notes,
    // Both heroes' photos: too few heroes left to heal (#393).
    photos: data.photos.filter((p) => p.id !== "p01" && p.id !== "p09"),
    bonus_task_assignments: [],
    points_ledger: [],
    user_achievements: [],
  });
  const gone = await (await handleRequest(
    request({ trip_id: TRIP_ID }),
    directorDeps(deleted, { record: goldenVowsRecord() }).deps,
  )).json();
  assertEquals(gone.content.golden_vows.occasion, "romance");
  assertEquals(gone.content.film_report.source, "code");
  assertEquals(
    JSON.stringify(gone.content.golden_vows).includes('"p01"'),
    false,
  );
});

Deno.test("a Sky Story memory never gets Golden Vows or Neon Night (#433)", async () => {
  for (const record of [goldenVowsRecord(), neonNightRecord()]) {
    const json = await (await handleRequest(
      request({ trip_id: TRIP_ID }),
      directorDeps(directorClient(), { record }).deps,
    )).json();
    assertEquals(json.content.film_style, "sky_story");
    assertEquals("golden_vows" in json.content, false);
    assertEquals("neon_night" in json.content, false);
    assertEquals(json.content.sky.source, "director");
  }
});

Deno.test("a deleted photo heals Golden Vows instead of dropping it (#393)", async () => {
  const data = directorTripData();
  const client = fakeSupabaseClient({
    trips: [{
      id: TRIP_ID,
      user_id: OWNER_ID,
      ...data.trip,
      vibes: ["Romantic"],
    }],
    wrap_ups: [],
    journal_notes: data.notes,
    photos: data.photos.filter((p) => p.id !== "p05"),
    bonus_task_assignments: [],
    points_ledger: [],
    user_achievements: [],
  });
  const json = await (await handleRequest(
    request({ trip_id: TRIP_ID }),
    directorDeps(client, { record: goldenVowsRecord() }).deps,
  )).json();
  assertEquals(json.content.golden_vows.chapters.length, 2);
  assertEquals(JSON.stringify(json.content).includes('"p05"'), false);
});

Deno.test("rebuilding a film kept as Golden Vows keeps Golden Vows (#433)", async () => {
  const client = keptGoldenVowsClient();
  const { runs, deps } = directorDeps(client);
  const kept = await (await handleRequest(
    request({ trip_id: TRIP_ID, rebuild: true }),
    deps,
  )).json();
  assertEquals(runs, []);
  assertEquals(kept.content.golden_vows.occasion, "wedding");
  assertEquals(kept.content.golden_vows.chapters.length, 3);
  assertEquals(client.writes[0].values.content.golden_vows.gv_version, 1);

  const changed = await (await handleRequest(
    request({ trip_id: TRIP_ID, rebuild: true }),
    directorDeps(
      keptGoldenVowsClient(
        directorTripData().photos.filter((p) => p.id !== "p05"),
      ),
    ).deps,
  )).json();
  assertEquals(changed.content.golden_vows.chapters.length, 2);

  const unhealable = await (await handleRequest(
    request({ trip_id: TRIP_ID, rebuild: true }),
    directorDeps(
      keptGoldenVowsClient(
        directorTripData().photos.filter((p) =>
          p.id !== "p01" && p.id !== "p09"
        ),
      ),
    ).deps,
  )).json();
  // Too little left of the director's: code builds the album — the kept
  // film stays Golden Vows.
  assertEquals(unhealable.content.golden_vows.occasion, "romance");
  assertEquals(unhealable.content.film_report.source, "code");
});

Deno.test("a film kept as a Sky Story never gains Golden Vows", async () => {
  const data = directorTripData();
  const client = fakeSupabaseClient({
    trips: [{ id: TRIP_ID, user_id: OWNER_ID, ...data.trip }],
    wrap_ups: [{
      content: { ...validWrapUpContent, sky: { sky_version: 1, pages: [] } },
      generated_at: "2026-09-05T00:00:00Z",
      published_at: "2026-09-06T00:00:00Z",
      ai_fields: validAiFields,
      ai_input_hash: "old",
      ai_generation_count: 1,
      director: goldenVowsRecord(),
    }],
    journal_notes: data.notes,
    photos: data.photos,
    bonus_task_assignments: [],
    points_ledger: [],
    user_achievements: [],
  });
  const json = await (await handleRequest(
    request({ trip_id: TRIP_ID, rebuild: true }),
    directorDeps(client).deps,
  )).json();
  assertEquals(json.content.sky.source, "director");
  assertEquals("golden_vows" in json.content, false);
});

// --- Neon Night (#363) ---

function neonNightRecord(): DirectorRecord {
  return {
    ...plannedRecord(),
    sky_story: skyStoryPlan(),
    neon_night: neonNightPlan(),
  };
}

function keptNeonClient(
  content: Record<string, unknown>,
  photos = directorTripData().photos,
) {
  const data = directorTripData();
  return fakeSupabaseClient({
    trips: [{ id: TRIP_ID, user_id: OWNER_ID, ...data.trip }],
    wrap_ups: [{
      content: { ...validWrapUpContent, ...content },
      generated_at: "2026-09-05T00:00:00Z",
      published_at: "2026-09-06T00:00:00Z",
      ai_fields: validAiFields,
      ai_input_hash: "old",
      ai_generation_count: 1,
      director: neonNightRecord(),
    }],
    journal_notes: data.notes,
    photos,
    bonus_task_assignments: [],
    points_ledger: [],
    user_achievements: [],
  });
}

Deno.test("a draft gets content.neon_night from the director's section", async () => {
  const client = directorClient([], ["Nightlife"]);
  const { deps } = directorDeps(client, { record: neonNightRecord() });

  const json = await (await handleRequest(request({ trip_id: TRIP_ID }), deps))
    .json();

  const nn = json.content.neon_night;
  assertEquals(nn.nn_version, 1);
  // The fixture's 3 days keep a chapter each (#398 R1): no merging across
  // days.
  assertEquals(nn.chapters.length, 3);
  assertEquals(nn.chapters[0].note, "Bikes everywhere");
  assertEquals(nn.note.text, "Rain, then stroopwafels.");
  assertEquals(json.content.film_style, "neon_night");
  // Code-built Sky pages are there too: the app's safety net.
  assertEquals(json.content.sky.source, "code");
  assertEquals(client.writes[0].values.content.neon_night, nn);
});

Deno.test("a Nightlife memory always plays Neon Night: no section, director off, healed (#433)", async () => {
  const none = await (await handleRequest(
    request({ trip_id: TRIP_ID }),
    directorDeps(directorClient([], ["Nightlife"])).deps,
  )).json();
  assertEquals(none.content.film_style, "neon_night");
  assertEquals(none.content.neon_night.chapters.length, 3);
  assertEquals(none.content.film_report.source, "code");

  const off = await (await handleRequest(
    request({ trip_id: TRIP_ID }),
    directorDeps(directorClient([], ["Nightlife"]), {
      enabled: false,
      record: neonNightRecord(),
    }).deps,
  )).json();
  assertEquals(off.content.neon_night.chapters.length > 0, true);

  const data = directorTripData();
  const deleted = fakeSupabaseClient({
    trips: [{
      id: TRIP_ID,
      user_id: OWNER_ID,
      ...data.trip,
      vibes: ["Nightlife"],
    }],
    wrap_ups: [],
    journal_notes: data.notes,
    photos: data.photos.filter((p) => p.id !== "p09"),
    bonus_task_assignments: [],
    points_ledger: [],
    user_achievements: [],
  });
  const healed = await (await handleRequest(
    request({ trip_id: TRIP_ID }),
    directorDeps(deleted, { record: neonNightRecord() }).deps,
  )).json();
  // A deleted photo heals the section instead of dropping it (#393).
  assertEquals(healed.content.neon_night.chapters.length > 0, true);
  assertEquals(JSON.stringify(healed.content).includes('"p09"'), false);
});

Deno.test("the app's UTC offset reaches the director", async () => {
  const seen: (number | undefined)[] = [];
  const deps = baseDeps({
    serviceClient: directorClient(),
    director: {
      isEnabledFor: () => true,
      run: (_tripId, tripData) => {
        seen.push(tripData.utc_offset_minutes);
        return Promise.resolve(neonNightRecord());
      },
    },
  });
  await handleRequest(
    request({ trip_id: TRIP_ID, utc_offset_minutes: 120 }),
    deps,
  );
  assertEquals(seen, [120]);
});

Deno.test("parseUtcOffset: whole minutes within ±14 h, else none", () => {
  assertEquals(parseUtcOffset(120), 120);
  assertEquals(parseUtcOffset(-300), -300);
  assertEquals(parseUtcOffset(0), 0);
  assertEquals(parseUtcOffset(14 * 60 + 1), undefined);
  assertEquals(parseUtcOffset(90.5), undefined);
  assertEquals(parseUtcOffset("120"), undefined);
  assertEquals(parseUtcOffset(undefined), undefined);
});

Deno.test("rebuilding a film kept as Neon Night keeps Neon Night (#433)", async () => {
  const content = {
    sky: { sky_version: 1, pages: [] },
    neon_night: { nn_version: 1 },
  };
  const client = keptNeonClient(content);
  const { runs, deps } = directorDeps(client);
  const kept = await (await handleRequest(
    request({ trip_id: TRIP_ID, rebuild: true }),
    deps,
  )).json();
  assertEquals(runs, []);
  assertEquals(kept.content.neon_night.chapters.length, 3);
  assertEquals(client.writes[0].values.content.neon_night.nn_version, 1);

  const changed = await (await handleRequest(
    request({ trip_id: TRIP_ID, rebuild: true }),
    directorDeps(
      keptNeonClient(
        content,
        directorTripData().photos.filter((p) => p.id !== "p09"),
      ),
    ).deps,
  )).json();
  assertEquals(changed.content.neon_night.nn_version, 1);

  const unhealable = await (await handleRequest(
    request({ trip_id: TRIP_ID, rebuild: true }),
    directorDeps(
      keptNeonClient(content, directorTripData().photos.slice(0, 3)),
    ).deps,
  )).json();
  // Never another film for a kept one.
  assertEquals(unhealable.content.neon_night.nn_version, 1);
});

Deno.test("a film kept as a Sky Story never gains Neon Night", async () => {
  const json = await (await handleRequest(
    request({ trip_id: TRIP_ID, rebuild: true }),
    directorDeps(keptNeonClient({ sky: { sky_version: 1, pages: [] } })).deps,
  )).json();
  assertEquals(json.content.sky.source, "director");
  assertEquals("neon_night" in json.content, false);
});

// #432: a draft needs WRAP_UP_LIMITS' photos and notes; a kept film never.
function eligibilityClient(photoCount: number, noteCount: number) {
  return fakeSupabaseClient({
    trips: [{
      id: TRIP_ID,
      user_id: OWNER_ID,
      name: "Lisbon",
      start_date: "2026-06-01",
      end_date: "2026-06-03",
      cover_image_path: null,
      vibes: [],
    }],
    wrap_ups: [],
    journal_notes: Array.from({ length: noteCount }, (_, i) => ({
      id: `n${i}`,
      day_date: "2026-06-01",
      content: `Note ${i}.`,
    })),
    photos: Array.from({ length: photoCount }, (_, i) => ({
      id: `p${i}`,
      day_date: "2026-06-01",
      taken_at: null,
      created_at: `2026-06-01T10:${String(i).padStart(2, "0")}:00Z`,
      storage_path: `u/t/p${i}.jpg`,
      caption: null,
      use_in_wrap_up: null,
    })),
    bonus_task_assignments: [],
    points_ledger: [],
    user_achievements: [],
  });
}

Deno.test("a draft below the minimum gets 422 not_eligible and no AI call (#432)", async () => {
  for (
    const [photos, notes, missing] of [
      [14, 1, { photos: 1, notes: 0 }],
      [15, 0, { photos: 0, notes: 1 }],
      [3, 0, { photos: 12, notes: 1 }],
    ] as const
  ) {
    let generateCalled = false;
    const client = eligibilityClient(photos, notes);
    const res = await handleRequest(
      request({ trip_id: TRIP_ID }),
      baseDeps({
        serviceClient: client,
        minimums: undefined,
        generateAiFields: () => {
          generateCalled = true;
          return Promise.resolve(validAiFields);
        },
      }),
    );
    const body = await res.json();
    assertEquals(res.status, 422);
    assertEquals(body.code, "not_eligible");
    assertEquals(body.missing, missing);
    assertEquals(generateCalled, false);
    assertEquals(client.writes, []);
  }
});

Deno.test("15 photos and 1 note make a draft (#432)", async () => {
  const res = await handleRequest(
    request({ trip_id: TRIP_ID }),
    baseDeps({ serviceClient: eligibilityClient(15, 1), minimums: undefined }),
  );
  assertEquals(res.status, 200);
});

Deno.test("a kept film under the minimum is still returned as stored (#432)", async () => {
  const res = await handleRequest(
    request({ trip_id: TRIP_ID }),
    baseDeps({ serviceClient: keptClient(), minimums: undefined }),
  );
  assertEquals(res.status, 200);
  assertEquals((await res.json()).content, validWrapUpContent);
});
