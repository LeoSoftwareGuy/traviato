import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { type Deps, handleRequest, parseUtcOffset } from "./handler.ts";
import { fakeAuthClient, fakeSupabaseClient } from "./test_fakes.ts";
import type { AiGeneratedFields } from "./ai_fields.ts";
import { validAiFields, validWrapUpContent } from "./test_fixtures.ts";
import { DIRECTOR_VERSION, type DirectorRecord } from "./director.ts";
import {
  directorTripData,
  gvPicks,
  neonPicks,
  skyPicks,
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
  const client = fakeSupabaseClient(
    {
      trips: [{ id: TRIP_ID, user_id: OWNER_ID }],
      wrap_ups: [{
        content: validWrapUpContent,
        generated_at: "2026-06-06T00:00:00Z",
        published_at: "2026-06-07T00:00:00Z",
        ai_fields: validAiFields,
      }],
    },
    // Gathering would fail loudly — proves a frozen wrap-up never reads it.
    { photos: { message: "must not be read" } },
  );
  const deps = baseDeps({ serviceClient: client, minimums: NO_MINIMUMS });

  const res = await handleRequest(request({ trip_id: TRIP_ID }), deps);
  const json = await res.json();

  assertEquals(res.status, 200);
  assertEquals(json.content, validWrapUpContent);
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

Deno.test("rebuild on a kept wrap-up re-assembles the film with its stored lines (#294)", async () => {
  const client = keptClient();
  const deps = baseDeps({ serviceClient: client, minimums: NO_MINIMUMS });

  const res = await handleRequest(
    request({ trip_id: TRIP_ID, rebuild: true }),
    deps,
  );
  const json = await res.json();

  assertEquals(res.status, 200);
  // Notes changed since keeping: the kept lines are reused.
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

Deno.test("handleRequest assembles, saves and returns new content", async () => {
  const res = await handleRequest(request({ trip_id: TRIP_ID }), baseDeps());
  const json = await res.json();

  assertEquals(res.status, 200);
  // No notes, no destination: the memory's name, no bridges, no quote —
  // never filler (#463).
  assertEquals(json.content.invitation.line2, "Untitled Trip");
  assertEquals(json.content.bridges, ["", "", ""]);
  assertEquals(json.content.keepsake.closing_quote, "");
  assertEquals(json.content.moments, []); // no photos in this fixture's trip
  assertEquals(json.content.footnote.photo_count, 0);
});

// ---- Drafts (#187, #463: the classic film's lines from the notes) ----------

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
  journal_notes: [{
    day_date: "2026-06-01",
    content: "Tram 28 up to the castle, the whole city below us.",
  }],
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

Deno.test("a draft is rebuilt from current photos, its lines from the notes (#463)", async () => {
  const client = draftClient({ ai_fields: OLD_FIELDS });
  const res = await handleRequest(
    request({ trip_id: TRIP_ID }),
    baseDeps({ serviceClient: client, log: () => {} }),
  );
  const json = await res.json();

  assertEquals(res.status, 200);
  assertEquals(
    json.content.moments.map((m: { photo_id: string }) => m.photo_id),
    ["p-new"],
  );
  // The AI-written draft lines are gone: the notes' words play.
  assertEquals(json.content.invitation.line2, "Lisbon");
  assertEquals(json.content.bridges.filter(Boolean), [
    "Tram 28 up to the castle, the whole city below us.",
  ]);
  const [write] = client.writes;
  assertEquals(write.op, "update");
  assertEquals(write.values.ai_fields, {
    invitation_line2: "Lisbon",
    bridges: json.content.bridges,
    unlock_reason: null,
    keepsake_closing_quote: json.content.keepsake.closing_quote,
  });
  // No AI hash or count any more.
  assertEquals("ai_input_hash" in write.values, false);
  assertEquals("ai_generation_count" in write.values, false);
  assertEquals(write.filters, [
    ["eq", "trip_id", TRIP_ID],
    ["is", "published_at", null],
  ]);
});

Deno.test("a first build inserts a row", async () => {
  const client = fakeSupabaseClient({ ...DRAFT_TABLES, wrap_ups: [] });
  await handleRequest(
    request({ trip_id: TRIP_ID }),
    baseDeps({ serviceClient: client, log: () => {} }),
  );
  const [write] = client.writes;
  assertEquals(write.op, "insert");
  assertEquals(write.values.trip_id, TRIP_ID);
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
    sky: { picks_version: 2, picks: skyPicks(directorTripData()) },
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

// A draft memory whose photos and notes fit plannedRecord()'s picks.
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

Deno.test("director off: no run, code's words, no director column written", async () => {
  const client = directorClient();
  const { runs, deps } = directorDeps(client, { enabled: false });

  const res = await handleRequest(request({ trip_id: TRIP_ID }), deps);
  const json = await res.json();

  assertEquals(res.status, 200);
  assertEquals(runs, []);
  assertEquals("plan" in json.content, false);
  assertEquals(json.content.sky.source, "code");
  assertEquals("director" in client.writes[0].values, false);
});

Deno.test("director on: the first build runs it, stores the run and plays its picks", async () => {
  const client = directorClient();
  const { runs, deps } = directorDeps(client);

  const res = await handleRequest(request({ trip_id: TRIP_ID }), deps);
  const json = await res.json();

  assertEquals(res.status, 200);
  assertEquals(runs, [TRIP_ID]);
  // No classic plan any more (#463).
  assertEquals("plan" in json.content, false);
  assertEquals(json.content.sky.source, "director");
  assertEquals(json.content.sky.pages[0].headline, "Bikes first");
  // Everything the classic player reads is still there.
  assertEquals(json.content.bridges.length, 3);
  assertEquals(json.content.moments.length > 0, true);
  assertEquals(client.writes[0].values.director, {
    ...plannedRecord(),
    run_count: 1,
  });
});

Deno.test("director on, already run: no second run, the stored picks still play", async () => {
  const client = directorClient([{
    content: validWrapUpContent,
    generated_at: "2026-11-01T00:00:00Z",
    published_at: null,
    ai_fields: validAiFields,
    director: plannedRecord(),
  }]);
  const { runs, deps } = directorDeps(client);

  const res = await handleRequest(request({ trip_id: TRIP_ID }), deps);
  const json = await res.json();

  assertEquals(runs, []);
  assertEquals(json.content.sky.pages[0].headline, "Bikes first");
  assertEquals("director" in client.writes[0].values, false);
});

Deno.test("a fallback run: code picks every word", async () => {
  const client = directorClient();
  const { deps } = directorDeps(client, {
    record: { ...plannedRecord(), status: "fallback", sky: null },
  });

  const res = await handleRequest(request({ trip_id: TRIP_ID }), deps);
  const json = await res.json();

  assertEquals(res.status, 200);
  assertEquals(json.content.sky.source, "code");
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
    director: { ...plannedRecord(), status: "fallback", sky: null },
  }]);
  const { runs, deps } = directorDeps(client);

  const res = await handleRequest(
    request({ trip_id: TRIP_ID, director: "rerun" }),
    deps,
  );
  const json = await res.json();

  assertEquals(runs, [TRIP_ID]);
  assertEquals(json.director.status, "planned");
  assertEquals(json.content.sky.source, "director");
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

Deno.test("a draft gets content.sky: code's pages, the director's words (#463)", async () => {
  const client = directorClient();
  const { deps } = directorDeps(client);

  const json = await (await handleRequest(request({ trip_id: TRIP_ID }), deps))
    .json();

  assertEquals(json.content.sky.source, "director");
  assertEquals(json.content.sky.pages.length, 3);
  assertEquals(json.content.sky.pages[0].excerpts, [
    { note_id: "n1", text: "Bikes everywhere." },
  ]);
  assertEquals(json.content.sky.moment_count, 12);
  assertEquals(client.writes[0].values.content.sky, json.content.sky);
  // The inspector's report: every slot, the photos on pages.
  const report = json.content.film_report;
  assertEquals(report.source, "director");
  assertEquals(report.shown, { pages: 12, photos: 12 });
  assert(report.slots.some((r: { slot: string }) => r.slot === "p1.headline"));
});

Deno.test("director off or without picks: code's words on content.sky", async () => {
  for (const enabled of [false, true]) {
    const client = directorClient();
    const { deps } = directorDeps(client, {
      enabled,
      record: { ...plannedRecord(), sky: null, hero_scores: { p02: 5 } },
    });
    const json = await (await handleRequest(
      request({ trip_id: TRIP_ID }),
      deps,
    )).json();
    assertEquals(json.content.sky.source, "code");
    assertEquals(json.content.sky.pages.length, 3);
    // Code names the page by its place (#463).
    assertEquals(json.content.sky.pages[0].headline, "Centraal");
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
    director: stale,
  }]);
  const { runs, deps } = directorDeps(client);

  await handleRequest(request({ trip_id: TRIP_ID }), deps);

  assertEquals(runs, [TRIP_ID]);
  assertEquals(client.writes[0].values.director.run_count, 3);
});

Deno.test("rebuilding a film kept as a Sky Story rebuilds its pages (#345, #463)", async () => {
  const data = directorTripData();
  const keptRow = (photos: typeof data.photos) =>
    fakeSupabaseClient({
      trips: [{ id: TRIP_ID, user_id: OWNER_ID, ...data.trip }],
      wrap_ups: [{
        content: { ...validWrapUpContent, sky: { sky_version: 1, pages: [] } },
        generated_at: "2026-09-05T00:00:00Z",
        published_at: "2026-09-06T00:00:00Z",
        ai_fields: validAiFields,
        director: plannedRecord(),
      }],
      journal_notes: data.notes,
      photos,
      bonus_task_assignments: [],
      points_ledger: [],
      user_achievements: [],
    });
  // A photo was deleted since: the pages are cut again, the stored picks
  // re-applied by id.
  const client = keptRow(data.photos.filter((p) => p.id !== "p05"));
  const { runs, deps } = directorDeps(client);

  const json = await (await handleRequest(
    request({ trip_id: TRIP_ID, rebuild: true }),
    deps,
  )).json();

  assertEquals(runs, []);
  assertEquals(json.content.sky.source, "director");
  assertEquals(json.content.sky.pages.length, 3);
  assertEquals(
    json.content.sky.pages.flatMap((p: { extra_photo_ids: string[] }) =>
      p.extra_photo_ids
    ).includes("p05"),
    false,
  );
  // Its kept lines stay.
  assertEquals(json.content.bridges, validAiFields.bridges);
  assertEquals(client.writes[0].values.content.sky, json.content.sky);
});

Deno.test("a kept film without stored lines rebuilds with the notes' lines (#463)", async () => {
  const data = directorTripData();
  const client = fakeSupabaseClient({
    trips: [{ id: TRIP_ID, user_id: OWNER_ID, ...data.trip }],
    wrap_ups: [{
      content: validWrapUpContent,
      generated_at: "2026-09-05T00:00:00Z",
      published_at: "2026-09-06T00:00:00Z",
      ai_fields: null,
    }],
    journal_notes: data.notes,
    photos: data.photos,
    bonus_task_assignments: [],
    points_ledger: [],
    user_achievements: [],
  });
  const json = await (await handleRequest(
    request({ trip_id: TRIP_ID, rebuild: true }),
    baseDeps({ serviceClient: client }),
  )).json();
  assertEquals(json.content.invitation.line2, "Netherlands");
});

// --- Golden Vows (#346; #458: code cuts it, the director picks) ---

function goldenVowsRecord(): DirectorRecord {
  const romantic = directorTripData();
  romantic.trip = { ...romantic.trip, vibes: ["Romantic"] };
  return {
    ...plannedRecord(),
    golden_vows: {
      picks_version: 2,
      picks: gvPicks(romantic, new Map([["p03", "bride"]])),
    },
    // A photo's summary showed a wedding when the director ran.
    gv_trigger: { word: "bride", source: "photo", id: "p03" },
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
      director: goldenVowsRecord(),
    }],
    journal_notes: data.notes,
    photos,
    bonus_task_assignments: [],
    points_ledger: [],
    user_achievements: [],
  });
}

const chapterTitles = (gv: { chapters: { title: string }[] }) =>
  gv.chapters.map((c) => c.title);

Deno.test("a draft gets content.golden_vows: code's album, the director's picks", async () => {
  const client = directorClient([], ["Romantic"]);
  const { deps } = directorDeps(client, { record: goldenVowsRecord() });

  const json = await (await handleRequest(request({ trip_id: TRIP_ID }), deps))
    .json();

  const gv = json.content.golden_vows;
  assertEquals(gv.gv_version, 1);
  // The occasion the director's photo summary showed, known again.
  assertEquals(gv.occasion, "wedding");
  assertEquals(gv.names, "Amsterdam");
  assertEquals(chapterTitles(gv)[0], "Slow morning");
  assertEquals(gv.chapters.length, 3);
  assertEquals(gv.heart_photo_ids.length, 12);
  assertEquals(json.content.film_style, "golden_vows");
  const report = json.content.film_report;
  assertEquals(report.source, "director");
  assertEquals(report.repairs, []);
  assert(report.slots.some((s: { slot: string }) => s.slot === "finale"));
  assertEquals(report.shown.photos, 12);
  assertEquals(report.trigger, { word: "bride", source: "photo", id: "p03" });
  // Code-built Sky pages are there too: the app's safety net.
  assertEquals(json.content.sky.source, "code");
  assertEquals(client.writes[0].values.content.golden_vows, gv);
});

Deno.test("a Romantic memory always plays Golden Vows: no picks, director off (#433)", async () => {
  const romantic = () => directorClient([], ["Romantic"]);
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

Deno.test("deleted photos: the album is cut again, no chapter lost (#458)", async () => {
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
    photos: data.photos.filter((p) => p.id !== "p05" && p.id !== "p01"),
    bonus_task_assignments: [],
    points_ledger: [],
    user_achievements: [],
  });
  const json = await (await handleRequest(
    request({ trip_id: TRIP_ID }),
    directorDeps(client, { record: goldenVowsRecord() }).deps,
  )).json();
  assertEquals(json.content.golden_vows.chapters.length, 3);
  assertEquals(JSON.stringify(json.content).includes('"p05"'), false);
  assertEquals(
    JSON.stringify(json.content.golden_vows).includes('"p01"'),
    false,
  );
  // The picks that still hold play.
  assertEquals(chapterTitles(json.content.golden_vows)[0], "Slow morning");
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
  assertEquals(changed.content.golden_vows.chapters.length, 3);
  assertEquals(JSON.stringify(changed.content).includes('"p05"'), false);
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
    neon_night: { picks_version: 2, picks: neonPicks(directorTripData()) },
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
      director: neonNightRecord(),
    }],
    journal_notes: data.notes,
    photos,
    bonus_task_assignments: [],
    points_ledger: [],
    user_achievements: [],
  });
}

Deno.test("a draft gets content.neon_night from the director's picks (#454)", async () => {
  const client = directorClient([], ["Nightlife"]);
  const { deps } = directorDeps(client, { record: neonNightRecord() });

  const json = await (await handleRequest(request({ trip_id: TRIP_ID }), deps))
    .json();

  const nn = json.content.neon_night;
  assertEquals(nn.nn_version, 1);
  // The fixture's 3 days keep a chapter each (#398 R1): no merging across
  // days.
  assertEquals(nn.chapters.length, 3);
  // The director's own title holds; every slot is in the report.
  assertEquals(nn.chapters[0].title, "Doors open");
  assertEquals(json.content.film_style, "neon_night");
  assertEquals(json.content.film_report.source, "director");
  assertEquals(json.content.film_report.repairs, []);
  assert(
    json.content.film_report.slots.some((r: { slot: string }) =>
      r.slot === "ch1.title"
    ),
  );
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
  // A deleted photo: the film is cut again, the picks re-applied by id.
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
    const client = eligibilityClient(photos, notes);
    const res = await handleRequest(
      request({ trip_id: TRIP_ID }),
      baseDeps({ serviceClient: client, minimums: undefined }),
    );
    const body = await res.json();
    assertEquals(res.status, 422);
    assertEquals(body.code, "not_eligible");
    assertEquals(body.missing, missing);
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
