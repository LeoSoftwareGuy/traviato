import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  buildPlanInput,
  buildPlanSystemPrompt,
  currentGoldenVows,
  currentNeonNight,
  currentPlan,
  currentSkyStory,
  DIRECTOR_VERSION,
  directorIsStale,
  type DirectorRecord,
  localClock,
  MAX_DIRECTOR_RUNS,
  photoDaysOf,
  runDirector,
} from "./director.ts";
import { fakeSupabaseClient } from "./test_fakes.ts";
import {
  analysisFor,
  DIRECTOR_PHOTO_IDS,
  directorTripData,
  emittedPlan,
  gvPicksAnswer,
  keepsakePlan,
  keepsakePlanWithFixableFaults,
  neonPicks,
  neonPicksAnswer,
  skyStoryPlan,
  toolResponse,
} from "./director_fixtures.ts";
import { buildGvPickSystemPrompt } from "./gv_slots.ts";
import type { TripData } from "./gather.ts";
import { useFilmLengthRuleForTests } from "./film_length.ts";

// These tests are about other rules: every film at its longest (#434).
useFilmLengthRuleForTests(false);

const TRIP_ID = "trip-1";

interface SentRequest {
  tool: string;
  body: Record<string, unknown>;
}

// Answers analysis calls with a valid entry per photo id in the request,
// plan calls with [plans] in turn, and each section tool (#380) with its
// own answers in turn — an Error answer is a failed call (HTTP 400).
function fakeAnthropic(
  plans: unknown[],
  sections: Record<string, unknown[]> = {},
) {
  const sent: SentRequest[] = [];
  let planCall = 0;
  const sectionCalls: Record<string, number> = {};
  const fetchImpl = (_url: string | URL | Request, init?: RequestInit) => {
    const body = JSON.parse(init!.body as string);
    const tool = body.tools[0].name as string;
    sent.push({ tool, body });
    if (tool === "emit_photo_analysis") {
      const ids =
        (body.messages[0].content as { type: string; text?: string }[])
          .filter((b) => b.type === "text" && b.text?.startsWith("Photo id: "))
          .map((b) => b.text!.slice("Photo id: ".length));
      return Promise.resolve(
        toolResponse(tool, { photos: ids.map(analysisFor) }, {
          input_tokens: 400 * ids.length,
          output_tokens: 40 * ids.length,
        }),
      );
    }
    if (tool !== "emit_film_plan") {
      const answers = sections[tool] ?? [];
      const k = sectionCalls[tool] = (sectionCalls[tool] ?? -1) + 1;
      const answer = answers[Math.min(k, answers.length - 1)];
      if (answer instanceof Error) {
        return Promise.resolve(
          new Response(JSON.stringify({ error: answer.message }), {
            status: 400,
          }),
        );
      }
      return Promise.resolve(toolResponse(tool, answer));
    }
    const plan = plans[Math.min(planCall++, plans.length - 1)];
    return Promise.resolve(toolResponse(tool, plan));
  };
  return { sent, fetchImpl: fetchImpl as typeof fetch };
}

function deps(
  fetchImpl: typeof fetch,
  tables: Record<string, Record<string, unknown>[]> = {},
) {
  const client = fakeSupabaseClient({ photo_analysis: [], ...tables });
  const logs: string[] = [];
  return {
    client,
    logs,
    deps: {
      client,
      apiKey: "key",
      fetchImpl,
      log: (line: string) => logs.push(line),
      now: () => new Date("2026-11-08T12:00:00Z"),
      signImageUrls: (paths: string[]) =>
        Promise.resolve(paths.map((p) => `https://signed.test/${p}`)),
    },
  };
}

Deno.test("runDirector analyses photos, caches them, plans and records cost", async () => {
  const anthropic = fakeAnthropic([emittedPlan()]);
  const { client, logs, deps: d } = deps(anthropic.fetchImpl);

  const record = await runDirector(d, TRIP_ID, directorTripData(), "en");

  assertEquals(record.status, "planned");
  assertEquals(record.problems, []);
  assertEquals(record.plan?.recipe, "keepsake");
  assertEquals(record.photos, {
    plannable: 12,
    analysed_now: 12,
    cached: 0,
    failed: 0,
  });
  assertEquals(Object.keys(record.photo_paths), DIRECTOR_PHOTO_IDS);
  assertEquals(anthropic.sent.map((s) => s.tool), [
    "emit_photo_analysis",
    "emit_film_plan",
  ]);
  // 12 × 400 + 1000 in, 12 × 40 + 200 out, at $2 / $10 per MTok.
  assertEquals(record.usage.input_tokens, 5800);
  assertEquals(record.usage.output_tokens, 680);
  assertEquals(record.usage.estimated_usd, 0.0184);
  const upsert = client.writes.find((w) => w.table === "photo_analysis")!;
  assertEquals((upsert.values as unknown as unknown[]).length, 12);
  assert(logs.some((l) => l.includes('"event":"director_usage"')));
});

Deno.test("runDirector reuses cached analysis and only sends new photos", async () => {
  const anthropic = fakeAnthropic([emittedPlan()]);
  const cached = DIRECTOR_PHOTO_IDS.slice(0, 10).map((id) => ({
    ...analysisFor(id),
    trip_id: TRIP_ID,
    storage_path: `u/t/${id}.jpg`,
    model: "claude-sonnet-5",
  }));
  const { deps: d } = deps(anthropic.fetchImpl, { photo_analysis: cached });

  const record = await runDirector(d, TRIP_ID, directorTripData(), "en");

  assertEquals(record.status, "planned");
  assertEquals(record.photos.cached, 10);
  assertEquals(record.photos.analysed_now, 2);
  const analysisBody = anthropic.sent[0].body;
  const images = (analysisBody.messages as { content: { type: string }[] }[])[0]
    .content.filter((b) => b.type === "image");
  assertEquals(images.length, 2);
});

Deno.test("an invalid plan is retried once with its problems, then accepted", async () => {
  const broken = emittedPlan();
  broken.chapters[0].scenes[0].photo_ids = ["invented"];
  const anthropic = fakeAnthropic([broken, emittedPlan()]);
  const { deps: d } = deps(anthropic.fetchImpl);

  const record = await runDirector(d, TRIP_ID, directorTripData(), "en");

  assertEquals(record.status, "planned");
  assertEquals(record.attempts, 2);
  const retry = anthropic.sent.at(-1)!.body;
  assertStringIncludes(
    (retry.messages as { content: string }[])[0].content,
    '"invented" is not a photo id from the input',
  );
});

Deno.test("a banned phrase is removed from the AI's line, not refused (#433)", async () => {
  const banned = emittedPlan();
  banned.closing_line = "An unforgettable trip, and Lisbon kept its light.";
  const record = await runDirector(
    deps(fakeAnthropic([banned]).fetchImpl).deps,
    TRIP_ID,
    directorTripData(),
    "en",
  );
  assertEquals(record.status, "planned");
  assertEquals(record.attempts, 1);
  assertEquals(record.plan!.closing_line.includes("unforgettable"), false);
});

Deno.test("two invalid plans fall back, keeping the problems", async () => {
  const broken = emittedPlan();
  broken.closing_line = "";
  const anthropic = fakeAnthropic([broken]);
  const { deps: d } = deps(anthropic.fetchImpl);

  const record = await runDirector(d, TRIP_ID, directorTripData(), "en");

  assertEquals(record.status, "fallback");
  assertEquals(record.plan, null);
  assertEquals(record.attempts, 2);
  assertEquals(record.problems.length, 1);
  assertStringIncludes(record.problems[0], "closing_line");
});

Deno.test("an Anthropic outage falls back without throwing", async () => {
  const { deps: d } = deps(
    () => Promise.resolve(new Response("down", { status: 529 })),
  );
  const record = await runDirector(d, TRIP_ID, directorTripData(), "en");
  assertEquals(record.status, "fallback");
  assertEquals(record.photos.failed, 12);
});

Deno.test("too few photos falls back without a plan call", async () => {
  const anthropic = fakeAnthropic([emittedPlan()]);
  const { deps: d } = deps(anthropic.fetchImpl);
  const data = directorTripData();
  data.photos = data.photos.slice(0, 4);

  const record = await runDirector(d, TRIP_ID, data, "en");

  assertEquals(record.status, "fallback");
  assertEquals(anthropic.sent.map((s) => s.tool), ["emit_photo_analysis"]);
});

Deno.test("left-out photos are never analysed or offered to the plan", async () => {
  const anthropic = fakeAnthropic([emittedPlan()]);
  const { deps: d } = deps(anthropic.fetchImpl);
  const data = directorTripData();
  data.photos[11].use_in_wrap_up = false;

  const record = await runDirector(d, TRIP_ID, data, "en");

  // The fixture plan uses p11, so it's rejected — twice — and falls back.
  assertEquals(record.status, "fallback");
  assert(record.problems.some((p) => p.includes('"p11" was left out')));
  assertEquals("p11" in record.photo_paths, false);
});

Deno.test("the plan input carries facts in order and the prompt the rules", () => {
  const data = directorTripData();
  data.photos[2].use_in_wrap_up = true;
  data.completedBonusTasks = [{
    completed_at: "2026-09-01T12:00:00Z",
    photo_id: "p01",
    title: "Snap a canal",
    points: 2,
  }];
  const analyses = new Map(
    DIRECTOR_PHOTO_IDS.map((id) => [id, analysisFor(id)]),
  );
  const input = buildPlanInput(data, data.photos, analyses, "ru");

  assertEquals(input.language, "ru");
  assertEquals(input.memory.day_count, 3);
  assertEquals(input.notes[0], {
    note_id: "n1",
    day: 1,
    day_date: "2026-09-01",
    text: "Bikes everywhere.",
    written_at: null,
    photo_id: null,
  });
  // A note's own time and photo reach the director (#397).
  const timed = buildPlanInput(
    {
      ...data,
      utc_offset_minutes: 120,
      notes: [{
        id: "n9",
        day_date: "2026-09-01",
        content: "Ribs at the bar.",
        created_at: "2026-09-01T08:00:00Z",
        taken_at: "2026-09-01T19:16:00Z",
        photo_id: "p02",
      }],
    },
    data.photos,
    analyses,
    "en",
  );
  assertEquals(timed.notes[0].written_at, "21:16");
  assertEquals(timed.notes[0].photo_id, "p02");
  assertEquals(input.photos[0].place, "Centraal");
  assertEquals(input.photos[1].bonus_task, "Snap a canal");
  assertEquals(input.photos[2].must_include, true);
  assertEquals(input.photos[11].day, 3);

  const system = buildPlanSystemPrompt("ru");
  assertStringIncludes(system, "keepsake: fits everything else");
  // Nights out play Neon Night (#363): no rave recipe any more.
  assertEquals(system.includes("rave:"), false);
  assertStringIncludes(system, '"wanderlust"');
  assertStringIncludes(system, "Russian");
});

function plannedRecord(): DirectorRecord {
  return {
    status: "planned",
    plan: keepsakePlan(),
    problems: [],
    attempts: 1,
    model: "claude-sonnet-5",
    ran_at: "2026-11-08T12:00:00Z",
    photos: { plannable: 12, analysed_now: 12, cached: 0, failed: 0 },
    failed_ids: [],
    photo_paths: {},
    usage: { calls: [], input_tokens: 0, output_tokens: 0, estimated_usd: 0 },
  };
}

Deno.test("currentPlan keeps a plan that still fits the memory", () => {
  assertEquals(
    currentPlan(plannedRecord(), directorTripData(), "en"),
    keepsakePlan(),
  );
});

Deno.test("currentPlan drops a plan once its photos or picks changed", () => {
  const deleted: TripData = directorTripData();
  deleted.photos = deleted.photos.filter((p) => p.id !== "p04");
  assertEquals(currentPlan(plannedRecord(), deleted, "en"), null);

  const leftOut = directorTripData();
  leftOut.photos[4].use_in_wrap_up = false;
  assertEquals(currentPlan(plannedRecord(), leftOut, "en"), null);

  // A new Always photo the plan doesn't have — p00..p11 are all used, so
  // add a 13th.
  const always = directorTripData();
  always.photos.push({ ...always.photos[11], id: "p12", use_in_wrap_up: true });
  assertEquals(currentPlan(plannedRecord(), always, "en"), null);

  assertEquals(currentPlan(plannedRecord(), directorTripData(), "ru"), null);
  assertEquals(
    currentPlan({ status: "fallback", problems: [] }, directorTripData(), "en"),
    null,
  );
  assertEquals(currentPlan(null, directorTripData(), "en"), null);
});

Deno.test("runDirector repairs fixable plan faults instead of retrying", async () => {
  const anthropic = fakeAnthropic([keepsakePlanWithFixableFaults()]);
  const { deps: d } = deps(anthropic.fetchImpl);

  const record = await runDirector(d, TRIP_ID, directorTripData(), "en");

  assertEquals(record.status, "planned");
  assertEquals(record.attempts, 1);
  assertEquals(record.plan?.plan_version, 2);
  assertEquals(
    anthropic.sent.filter((s) => s.tool === "emit_film_plan").length,
    1,
  );
});

Deno.test("runDirector sends strict tools: closed objects, no unsupported keywords", async () => {
  // The plan call, and each section call (#380).
  const sent: SentRequest[] = [];
  for (
    const [anthropic, data] of [
      [fakeAnthropic([emittedPlan()]), directorTripData()],
      [golden(gvPicksAnswer(romantic())), romantic()],
      [neon(neonPicksAnswer(nightlife())), nightlife()],
    ] as const
  ) {
    await runDirector(
      deps(anthropic.fetchImpl).deps,
      TRIP_ID,
      data,
      "en",
    );
    sent.push(...anthropic.sent);
  }
  assertEquals(
    [...new Set(sent.map((s) => s.tool))].sort(),
    [
      "emit_film_plan",
      "emit_photo_analysis",
      "pick_golden_vows_lines",
      "pick_neon_lines",
    ],
  );
  const anthropic = { sent };

  const unsupported = [
    "minimum",
    "maximum",
    "minItems",
    "maxItems",
    "minLength",
    "maxLength",
  ];
  for (const { body } of anthropic.sent) {
    const tool = (body.tools as Record<string, unknown>[])[0];
    assertEquals(tool.strict, true);
    const walk = (node: unknown, path: string): void => {
      if (Array.isArray(node)) {
        return node.forEach((n, i) => walk(n, `${path}[${i}]`));
      }
      if (typeof node !== "object" || node === null) return;
      const o = node as Record<string, unknown>;
      for (const key of unsupported) {
        assert(!(key in o), `${path}.${key} sent to a strict tool`);
      }
      const type = o.type;
      if (
        type === "object" || (Array.isArray(type) && type.includes("object"))
      ) {
        assertEquals(o.additionalProperties, false, `${path} is not closed`);
      }
      for (const [k, v] of Object.entries(o)) {
        if (k !== "enum" && k !== "required") walk(v, `${path}.${k}`);
      }
    };
    walk(tool.input_schema, tool.name as string);
  }
});

// --- Sky Story (#345) ---

Deno.test("runDirector keeps the Sky Story pages and every photo's hero score", async () => {
  const anthropic = fakeAnthropic([emittedPlan()]);
  const { deps: d } = deps(anthropic.fetchImpl);

  const record = await runDirector(d, TRIP_ID, directorTripData(), "en");

  assertEquals(record.status, "planned");
  assertEquals(record.sky_story, skyStoryPlan());
  assertEquals(record.sky_problems, []);
  assertEquals("sky_story" in record.plan!, false);
  assertEquals(Object.keys(record.hero_scores!), DIRECTOR_PHOTO_IDS);
  assertEquals(record.photo_days, ["2026-09-01", "2026-09-02", "2026-09-03"]);
  const tool = (anthropic.sent[1].body.tools as Record<string, unknown>[])[0];
  const schema = tool.input_schema as {
    properties: Record<string, unknown>;
    required: string[];
  };
  assert("sky_story" in schema.properties);
  assert(schema.required.includes("sky_story"));
});

Deno.test("an invalid sky_story is retried; the valid classic plan is kept", async () => {
  const broken = emittedPlan();
  broken.sky_story.pages[0].hero_photo_id = "invented";
  // The retry breaks the classic plan instead: each half keeps its
  // first valid attempt.
  const second = emittedPlan();
  second.closing_line = "An unforgettable trip.";
  const anthropic = fakeAnthropic([broken, second]);
  const { deps: d } = deps(anthropic.fetchImpl);

  const record = await runDirector(d, TRIP_ID, directorTripData(), "en");

  assertEquals(record.attempts, 2);
  assertEquals(record.status, "planned");
  assertEquals(record.problems, []);
  assertEquals(record.sky_story, skyStoryPlan());
  const retry = anthropic.sent.at(-1)!.body;
  assertStringIncludes(
    (retry.messages as { content: string }[])[0].content,
    'sky_story.pages[0].hero_photo_id: "invented"',
  );
});

Deno.test("a sky_story still invalid after the retry leaves code-built pages", async () => {
  const broken = emittedPlan();
  broken.sky_story.pages[0].days = [0, 9];
  const anthropic = fakeAnthropic([broken]);
  const { deps: d } = deps(anthropic.fetchImpl);

  const record = await runDirector(d, TRIP_ID, directorTripData(), "en");

  assertEquals(record.status, "planned");
  assertEquals(record.sky_story, null);
  assert(record.sky_problems!.some((p) => p.startsWith("sky_story.pages[0]")));
});

Deno.test("Sky Story pages survive a classic plan that falls back", async () => {
  const broken = emittedPlan();
  broken.closing_line = "";
  const anthropic = fakeAnthropic([broken]);
  const { deps: d } = deps(anthropic.fetchImpl);

  const record = await runDirector(d, TRIP_ID, directorTripData(), "en");

  assertEquals(record.status, "fallback");
  assertEquals(record.sky_story, skyStoryPlan());
});

Deno.test("too few photos: no Sky Story plan, the reason recorded", async () => {
  const anthropic = fakeAnthropic([emittedPlan()]);
  const { deps: d } = deps(anthropic.fetchImpl);
  const data = directorTripData();
  data.photos = data.photos.slice(0, 4);

  const record = await runDirector(d, TRIP_ID, data, "en");

  assertEquals(record.sky_story, null);
  assertEquals(record.sky_problems!.length, 1);
});

Deno.test("the system prompt carries the Sky Story rules", () => {
  const prompt = buildPlanSystemPrompt("en");
  assertStringIncludes(prompt, "sky_story");
  assertStringIncludes(prompt, "hero_photo_id");
});

function skyRecord(overrides: Partial<DirectorRecord> = {}): DirectorRecord {
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
    sky_story: skyStoryPlan(),
    photo_days: ["2026-09-01", "2026-09-02", "2026-09-03"],
    run_count: 1,
    usage: { calls: [], input_tokens: 0, output_tokens: 0, estimated_usd: 0 },
    ...overrides,
  };
}

Deno.test("currentSkyStory: the stored pages while they fit the memory", () => {
  assertEquals(
    currentSkyStory(skyRecord(), directorTripData()),
    skyStoryPlan(),
  );
  assertEquals(currentSkyStory(null, directorTripData()), null);
  assertEquals(
    currentSkyStory(skyRecord({ sky_story: null }), directorTripData()),
    null,
  );

  const deleted = directorTripData();
  deleted.photos = deleted.photos.filter((p) => p.id !== "p05");
  assertEquals(currentSkyStory(skyRecord(), deleted), null);

  const leftOut = directorTripData();
  leftOut.photos[9].use_in_wrap_up = false;
  assertEquals(currentSkyStory(skyRecord(), leftOut), null);

  const noteGone = directorTripData();
  noteGone.notes = noteGone.notes.slice(1);
  assertEquals(currentSkyStory(skyRecord(), noteGone), null);
});

Deno.test("directorIsStale when photo days change, until the run cap", () => {
  const data = directorTripData();
  assertEquals(photoDaysOf(data), ["2026-09-01", "2026-09-02", "2026-09-03"]);
  assertEquals(directorIsStale(skyRecord(), data), false);

  const fewer = directorTripData();
  fewer.photos = fewer.photos.slice(0, 8);
  assertEquals(directorIsStale(skyRecord(), fewer), true);
  assertEquals(
    directorIsStale(skyRecord({ run_count: MAX_DIRECTOR_RUNS }), fewer),
    false,
  );
  // A record made under older rules runs again once (#398), within the cap.
  assertEquals(
    directorIsStale(skyRecord({ director_version: undefined }), data),
    true,
  );
  assertEquals(
    directorIsStale(
      skyRecord({ director_version: undefined, run_count: MAX_DIRECTOR_RUNS }),
      data,
    ),
    false,
  );
  // A film photo the director never saw (#444): it runs again.
  const seenAll = Object.fromEntries(data.photos.map((p) => [p.id, "x"]));
  assertEquals(
    directorIsStale(skyRecord({ photo_paths: seenAll }), data),
    false,
  );
  const missed = { ...seenAll };
  delete missed[data.photos[0].id];
  assertEquals(
    directorIsStale(skyRecord({ photo_paths: missed }), data),
    true,
  );
  assertEquals(
    directorIsStale(
      skyRecord({ photo_paths: missed, failed_ids: [data.photos[0].id] }),
      data,
    ),
    false,
  );
  // Records from before #345 have no photo days: never stale.
  assertEquals(
    directorIsStale(skyRecord({ photo_days: undefined }), fewer),
    false,
  );
});

// --- Golden Vows and Neon Night: chosen by the vibes (#433) ---

const romantic = () =>
  directorTripData({
    trip: { ...directorTripData().trip, vibes: ["Romantic"] },
  });
const nightlife = (overrides: Partial<TripData> = {}) =>
  directorTripData({
    trip: { ...directorTripData().trip, vibes: ["Nightlife"] },
    ...overrides,
  });

function golden(...answers: unknown[]) {
  return fakeAnthropic([], { pick_golden_vows_lines: answers });
}

function neon(...answers: unknown[]) {
  return fakeAnthropic([], { pick_neon_lines: answers });
}

const calledTools = (anthropic: ReturnType<typeof fakeAnthropic>) =>
  anthropic.sent.filter((s) => s.tool !== "emit_photo_analysis").map((s) =>
    s.tool
  );

Deno.test("a Romantic memory: one pick_golden_vows_lines call, its picks kept (#458)", async () => {
  const data = romantic();
  const answer = gvPicksAnswer(data);
  const anthropic = golden(answer);
  const record = await runDirector(
    deps(anthropic.fetchImpl).deps,
    TRIP_ID,
    data,
    "en",
  );
  assertEquals(record.template, "golden_vows");
  assertEquals(record.section_attempts, 1);
  assertEquals(record.director_version, DIRECTOR_VERSION);
  const stored = record.golden_vows as {
    picks_version: number;
    picks: Record<string, { ids: string[]; free_title: string | null }>;
  };
  assertEquals(stored.picks_version, 2);
  assertEquals(stored.picks["ch1.title"].free_title, "Slow morning");
  assertEquals(record.golden_vows_source, "director");
  assertEquals(record.golden_vows_repairs, []);
  assertEquals(record.neon_night, null);
  assertEquals(record.orientations!.p00, "portrait");
  // The inspector's record: every slot, what plays and why.
  const title = record.gv_slots!.find((s) => s.slot === "ch1.title")!;
  assertEquals(title.chosen, [{ id: "free", text: "Slow morning" }]);
  assertEquals(title.source, "director");
  assertEquals(record.gv_shown!.photos, 12);
  assertEquals(record.gv_trigger, null);
  // One call after the analysis: no plan call, no Sky Story call.
  assertEquals(calledTools(anthropic), ["pick_golden_vows_lines"]);
  // It sees the cut album and every slot's list, scoped to its slot.
  const sent = JSON.parse(
    (anthropic.sent.at(-1)!.body.messages as { content: string }[])[0]
      .content.replace("Pick the words for this film:\n", ""),
  );
  assertEquals(sent.memory.occasion, "romance");
  assert(
    sent.slots.every((s: { slot: string; candidates: { id: string }[] }) =>
      s.candidates.every((c) => c.id.startsWith(`${s.slot}/`))
    ),
  );
});

Deno.test("a Sky Story memory makes only the plan call (#433)", async () => {
  const anthropic = fakeAnthropic([emittedPlan()]);
  const record = await runDirector(
    deps(anthropic.fetchImpl).deps,
    TRIP_ID,
    directorTripData(),
    "en",
  );
  assertEquals(record.template, "sky_story");
  assertEquals(calledTools(anthropic), ["emit_film_plan"]);
  assertEquals(record.golden_vows, null);
  assertEquals(record.neon_night, null);
});

Deno.test("no picks: code picks every slot, the film stays Golden Vows", async () => {
  for (const answer of [{ nothing: true }, new Error("overloaded")]) {
    const anthropic = golden(answer, answer);
    const record = await runDirector(
      deps(anthropic.fetchImpl).deps,
      TRIP_ID,
      romantic(),
      "en",
    );
    assertEquals(record.template, "golden_vows");
    assertEquals(record.section_attempts, 2);
    assertEquals(record.golden_vows, null);
    assertEquals(record.golden_vows_source, "code");
    assertStringIncludes(
      record.golden_vows_repairs!.at(-1)!,
      "code picked every slot",
    );
    assert(record.gv_slots!.every((s) => s.source !== "director"));
  }
});

Deno.test("a pick from another slot's list takes code's top candidate", async () => {
  const data = romantic();
  const answer = gvPicksAnswer(data);
  const label = answer.picks.find((p) => p.slot === "main1.label")!;
  label.ids = ["ch2.title/p:000"];
  const record = await runDirector(
    deps(golden(answer).fetchImpl).deps,
    TRIP_ID,
    data,
    "en",
  );
  const r = record.gv_slots!.find((s) => s.slot === "main1.label")!;
  assertEquals(r.source, "code");
  assert(
    record.golden_vows_repairs!.some((x) => x.startsWith("main1.label")),
  );
});

Deno.test("too few analysed photos: code's plan, the reason recorded", async () => {
  const data = romantic();
  const anthropic = golden(gvPicksAnswer(data));
  data.photos = data.photos.slice(0, 4);
  const record = await runDirector(
    deps(anthropic.fetchImpl).deps,
    TRIP_ID,
    data,
    "en",
  );
  assertEquals(record.golden_vows, null);
  assertEquals(record.golden_vows_source, "code");
  assertEquals(calledTools(anthropic), []);
});

Deno.test("the prompts: no occasion choice; Golden Vows picks, no wedding words", () => {
  const plan = buildPlanSystemPrompt("en");
  assertEquals(plan.includes("special_film"), false);
  assertEquals(plan.includes("copy a short phrase from it exactly"), false);
  const romance = buildGvPickSystemPrompt("en", "romance");
  assertStringIncludes(romance, "pick_golden_vows_lines");
  assertStringIncludes(romance, "never use vows, wedding");
  assertStringIncludes(
    buildGvPickSystemPrompt("ru", "wedding"),
    "wedding words are fine",
  );
});

Deno.test("the tools: no special_film on the plan, picks on their own", async () => {
  const sky = fakeAnthropic([emittedPlan()]);
  await runDirector(
    deps(sky.fetchImpl).deps,
    TRIP_ID,
    directorTripData(),
    "en",
  );
  const schemaOf = (a: ReturnType<typeof fakeAnthropic>, tool: string) =>
    (a.sent.find((s) => s.tool === tool)!.body.tools as {
      input_schema: { required: string[]; properties: Record<string, unknown> };
    }[])[0].input_schema;
  const main = schemaOf(sky, "emit_film_plan");
  assertEquals("special_film" in main.properties, false);
  assertEquals(main.required.includes("special_film"), false);
  assertEquals("golden_vows" in main.properties, false);

  const gv = golden(gvPicksAnswer(romantic()));
  await runDirector(deps(gv.fetchImpl).deps, TRIP_ID, romantic(), "en");
  assertEquals(schemaOf(gv, "pick_golden_vows_lines").required, ["picks"]);
});

Deno.test("currentGoldenVows: the stored picks, else none; older sections aren't read", () => {
  const picks = { finale: { ids: ["e:1"], free_title: null } };
  const record = {
    status: "planned",
    plan: keepsakePlan(),
    problems: [],
    failed_ids: [],
    golden_vows: { picks_version: 2, picks },
    gv_trigger: { word: "bride", source: "photo", id: "p03" },
  } as unknown as DirectorRecord;
  const current = currentGoldenVows(record);
  assertEquals(current.picks, picks);
  assertEquals(current.source, "director");
  // A photo's summary set the occasion: it is known again on open.
  assertEquals([...current.summaries], [["p03", "bride"]]);
  // A section from before #458.
  const old = currentGoldenVows({
    ...record,
    golden_vows: { occasion: "wedding", heroes: [] },
  });
  assertEquals(old.picks, null);
  assertEquals(old.source, "code");
  assertEquals(currentGoldenVows(null).source, "code");
});

Deno.test("an older record runs again once (#460: DIRECTOR_VERSION 7)", () => {
  assertEquals(DIRECTOR_VERSION, 7);
  const record = {
    status: "fallback",
    plan: null,
    problems: [],
    failed_ids: [],
    director_version: 6,
    run_count: 1,
  } as unknown as DirectorRecord;
  assertEquals(directorIsStale(record, romantic()), true);
});

Deno.test("a Nightlife memory: one pick_neon_lines call, its picks kept (#454)", async () => {
  const data = nightlife();
  const anthropic = neon(neonPicksAnswer(data));
  const record = await runDirector(
    deps(anthropic.fetchImpl).deps,
    TRIP_ID,
    data,
    "en",
  );
  assertEquals(record.template, "neon_night");
  assertEquals(record.neon_night, {
    picks_version: 2,
    picks: neonPicks(data),
  });
  assertEquals(record.neon_night_source, "director");
  assertEquals(record.neon_night_repairs, []);
  assertEquals(record.golden_vows, null);
  assertEquals(calledTools(anthropic), ["pick_neon_lines"]);
  // Every slot in the inspector: its candidates, the pick, its source.
  const title = record.neon_slots!.find((r) => r.slot === "ch1.title")!;
  assertEquals(title.source, "director");
  assertEquals(title.chosen.map((c) => c.text), ["Doors open"]);
  assert(record.neon_slots!.every((r) => r.source !== "code"));
});

Deno.test("Romantic + Nightlife plays Golden Vows; vibes decide, never the director", async () => {
  const both = directorTripData({
    trip: { ...directorTripData().trip, vibes: ["Nightlife", "Romantic"] },
  });
  const anthropic = golden(gvPicksAnswer(both));
  const record = await runDirector(
    deps(anthropic.fetchImpl).deps,
    TRIP_ID,
    both,
    "en",
  );
  assertEquals(record.template, "golden_vows");
  assertEquals(calledTools(anthropic), ["pick_golden_vows_lines"]);
});

Deno.test("Neon Night: a pick off its list takes code's top candidate (#454)", async () => {
  const data = nightlife();
  const answer = neonPicksAnswer(data);
  answer.picks.find((p) => p.slot === "note")!.ids = ["n:made-up"];
  const record = await runDirector(
    deps(neon(answer).fetchImpl).deps,
    TRIP_ID,
    data,
    "en",
  );
  const note = record.neon_slots!.find((r) => r.slot === "note")!;
  assertEquals(note.source, "code");
  assertStringIncludes(note.reason, "n:made-up: not in this slot's list");
  assertEquals(record.neon_night_source, "director");
  assert(record.neon_night_repairs!.some((r) => r.startsWith("note: ")));
});

Deno.test("Neon Night: a failed call is retried once, then code picks every slot", async () => {
  const data = nightlife();
  const retried = neon(new Error("overloaded"), neonPicksAnswer(data));
  const record = await runDirector(
    deps(retried.fetchImpl).deps,
    TRIP_ID,
    data,
    "en",
  );
  assertEquals(record.section_attempts, 2);
  assertEquals(record.neon_night_source, "director");

  const failed = await runDirector(
    deps(neon(new Error("a"), new Error("b")).fetchImpl).deps,
    TRIP_ID,
    data,
    "en",
  );
  assertEquals(failed.neon_night, null);
  assertEquals(failed.neon_night_source, "code");
  assert(failed.neon_slots!.length > 0);
  assert(failed.neon_slots!.every((r) => r.source !== "director"));
});

Deno.test("the pick call sees the cut film, its slots and the local times (#454)", async () => {
  const data = nightlife({ utc_offset_minutes: 120 });
  data.notes[0].created_at = "2026-09-01T21:59:00Z";
  data.notes[0].taken_at = "2026-09-01T21:59:00Z";
  const anthropic = neon(neonPicksAnswer(data));
  await runDirector(deps(anthropic.fetchImpl).deps, TRIP_ID, data, "en");
  const call = anthropic.sent.find((s) => s.tool === "pick_neon_lines")!;
  const system = call.body.system as string;
  assertStringIncludes(system, "Each id is used once in the whole film");
  assertStringIncludes(system, "free_title");
  const content = (call.body.messages as { content: string }[])[0].content;
  const input = JSON.parse(content.slice(content.indexOf("{")));
  assertEquals(input.photos[0].time, "12:00");
  assertEquals(input.notes[0].written_at, "23:59");
  assert(input.slots.some((s: { slot: string }) => s.slot === "ch1.card"));
  for (const slot of input.slots) {
    assert(slot.candidates.length <= 8 + 4, slot.slot);
  }
});

Deno.test("localClock: ISO instants as HH:MM on the app's clock", () => {
  const utc = directorTripData();
  assertEquals(localClock("2026-09-01T23:30:00Z", utc), "23:30");
  const tallinn = directorTripData({ utc_offset_minutes: 120 });
  assertEquals(localClock("2026-09-01T23:30:00Z", tallinn), "01:30");
  const behind = directorTripData({ utc_offset_minutes: -300 });
  assertEquals(localClock("2026-09-01T02:15:00Z", behind), "21:15");
  assertEquals(localClock(null, utc), null);
  assertEquals(localClock("not a date", utc), null);
});

Deno.test("currentNeonNight: stored picks, never a plan from before #454", () => {
  const data = nightlife();
  const record = {
    status: "planned",
    plan: keepsakePlan(),
    problems: [],
    failed_ids: [],
    neon_night: { picks_version: 2, picks: neonPicks(data) },
  } as unknown as DirectorRecord;
  assertEquals(currentNeonNight(record), {
    picks: neonPicks(data),
    source: "director",
  });
  // A whole plan stored before #454 isn't read: code picks.
  assertEquals(
    currentNeonNight({ ...record, neon_night: { chapters: [] } }).source,
    "code",
  );
  assertEquals(currentNeonNight({ ...record, neon_night: null }).picks, null);
});
