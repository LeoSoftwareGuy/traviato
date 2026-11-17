import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  buildPlanInput,
  buildPlanSystemPrompt,
  buildSectionSystemPrompt,
  currentGoldenVows,
  currentNeonNight,
  currentPlan,
  currentSkyStory,
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
  goldenVowsPlan,
  keepsakePlan,
  keepsakePlanWithFixableFaults,
  neonNightPlan,
  skyStoryPlan,
  toolResponse,
} from "./director_fixtures.ts";
import type { TripData } from "./gather.ts";
import type { NeonNightPlan } from "./neon_night.ts";

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

Deno.test("two invalid plans fall back, keeping the problems", async () => {
  const broken = emittedPlan();
  broken.closing_line = "An unforgettable trip.";
  const anthropic = fakeAnthropic([broken]);
  const { deps: d } = deps(anthropic.fetchImpl);

  const record = await runDirector(d, TRIP_ID, directorTripData(), "en");

  assertEquals(record.status, "fallback");
  assertEquals(record.plan, null);
  assertEquals(record.attempts, 2);
  assertEquals(record.problems, [
    'closing_line: banned phrase "unforgettable"',
  ]);
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
    const anthropic of [
      fakeAnthropic([emittedPlan()]),
      golden(goldenVowsPlan()),
      neon(neonNightPlan()),
    ]
  ) {
    await runDirector(
      deps(anthropic.fetchImpl).deps,
      TRIP_ID,
      directorTripData(),
      "en",
    );
    sent.push(...anthropic.sent);
  }
  assertEquals(
    [...new Set(sent.map((s) => s.tool))].sort(),
    [
      "emit_film_plan",
      "emit_golden_vows",
      "emit_neon_night",
      "emit_photo_analysis",
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
  broken.closing_line = "An unforgettable trip.";
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
  // Records from before #345 have no photo days: never stale.
  assertEquals(
    directorIsStale(skyRecord({ photo_days: undefined }), fewer),
    false,
  );
});

// --- Golden Vows (#346), its own call since #380 ---

function choosing(special_film: string) {
  return { ...emittedPlan(), special_film };
}

function golden(...answers: unknown[]) {
  return fakeAnthropic([choosing("golden_vows")], {
    emit_golden_vows: answers.map((a) =>
      a instanceof Error ? a : { golden_vows: a }
    ),
  });
}

Deno.test("runDirector keeps a valid Golden Vows section and the photos' shapes", async () => {
  const anthropic = golden(goldenVowsPlan());
  const { deps: d } = deps(anthropic.fetchImpl);

  const record = await runDirector(d, TRIP_ID, directorTripData(), "en");

  assertEquals(record.attempts, 1);
  assertEquals(record.special_film, "golden_vows");
  assertEquals(record.section_attempts, 1);
  assertEquals(record.golden_vows, goldenVowsPlan());
  assertEquals(record.golden_vows_problems, []);
  assertEquals(record.neon_night, null);
  assertEquals(record.orientations!.p00, "portrait");
  // Stored on its own, never inside the classic plan.
  assertEquals("golden_vows" in record.plan!, false);
  assertEquals("special_film" in record.plan!, false);
  // Its call is counted.
  assertEquals(
    record.usage.calls.map((c) => c.call).filter((c) => c !== "analysis"),
    ["plan", "section"],
  );
});

Deno.test("a null section is an answer: no Golden Vows, no retry", async () => {
  const anthropic = golden(null);
  const { deps: d } = deps(anthropic.fetchImpl);

  const record = await runDirector(d, TRIP_ID, directorTripData(), "en");

  assertEquals(record.section_attempts, 1);
  assertEquals(record.golden_vows, null);
  assertEquals(record.golden_vows_problems, []);
});

Deno.test("special_film none: no section call at all (#380)", async () => {
  const anthropic = fakeAnthropic([choosing("none")]);
  const { deps: d } = deps(anthropic.fetchImpl);

  const record = await runDirector(d, TRIP_ID, directorTripData(), "en");

  assertEquals(record.special_film, "none");
  assertEquals(record.section_attempts, undefined);
  assertEquals(
    anthropic.sent.filter((s) => s.tool !== "emit_photo_analysis").map((s) =>
      s.tool
    ),
    ["emit_film_plan"],
  );
  assertEquals(record.golden_vows_problems, []);
  assertEquals(record.neon_night_problems, []);
});

Deno.test("an invalid section is retried in its own call; the plan isn't redone", async () => {
  const broken = goldenVowsPlan();
  broken.chapters[0].photo_ids = ["invented", "p02", "p03"];
  const anthropic = golden(broken, goldenVowsPlan());
  const { deps: d } = deps(anthropic.fetchImpl);

  const record = await runDirector(d, TRIP_ID, directorTripData(), "en");

  assertEquals(record.attempts, 1);
  assertEquals(record.section_attempts, 2);
  assertEquals(record.status, "planned");
  assertEquals(record.sky_story, skyStoryPlan());
  assertEquals(record.golden_vows, goldenVowsPlan());
  const retry = anthropic.sent.at(-1)!;
  assertEquals(retry.tool, "emit_golden_vows");
  assertStringIncludes(
    (retry.body.messages as { content: string }[])[0].content,
    'golden_vows.chapters[0].photo_ids[2]: "invented"',
  );
});

Deno.test("a section still invalid after the retry: Sky Story, problems kept", async () => {
  const broken = goldenVowsPlan();
  broken.heroes = broken.heroes.slice(0, 1);
  const anthropic = golden(broken);
  const { deps: d } = deps(anthropic.fetchImpl);

  const record = await runDirector(d, TRIP_ID, directorTripData(), "en");

  assertEquals(record.section_attempts, 2);
  assertEquals(record.status, "planned");
  assertEquals(record.golden_vows, null);
  assert(
    record.golden_vows_problems!.some((p) =>
      p.startsWith("golden_vows.heroes: 1")
    ),
  );
});

Deno.test("a failing section call never costs the plan or Sky Story", async () => {
  const anthropic = golden(new Error("grammar too large"));
  const { deps: d } = deps(anthropic.fetchImpl);

  const record = await runDirector(d, TRIP_ID, directorTripData(), "en");

  assertEquals(record.status, "planned");
  assertEquals(record.sky_story, skyStoryPlan());
  assertEquals(record.golden_vows, null);
  assertEquals(record.section_attempts, 2);
  assertStringIncludes(
    record.golden_vows_problems![0],
    "golden_vows call failed",
  );
});

Deno.test("too few photos: no Golden Vows, the reason recorded", async () => {
  const anthropic = golden(goldenVowsPlan());
  const { deps: d } = deps(anthropic.fetchImpl);
  const data = directorTripData();
  data.photos = data.photos.slice(0, 4);

  const record = await runDirector(d, TRIP_ID, data, "en");

  assertEquals(record.golden_vows, null);
  assertEquals(record.golden_vows_problems!.length, 1);
});

Deno.test("the plan call chooses the film; the section call carries its rules", async () => {
  const plan = buildPlanSystemPrompt("en");
  assertStringIncludes(plan, "special_film");
  assertEquals(plan.includes("copy a short phrase from it exactly"), false);
  const section = buildSectionSystemPrompt("golden_vows", "en");
  assertStringIncludes(section, "copy a short phrase from it exactly");
  assertStringIncludes(section, "emit_golden_vows");

  const anthropic = golden(goldenVowsPlan());
  await runDirector(
    deps(anthropic.fetchImpl).deps,
    TRIP_ID,
    directorTripData(),
    "en",
  );
  const schemaOf = (tool: string) =>
    (anthropic.sent.find((s) => s.tool === tool)!.body.tools as {
      input_schema: { required: string[]; properties: Record<string, unknown> };
    }[])[0].input_schema;
  const main = schemaOf("emit_film_plan");
  assert(main.required.includes("special_film"));
  assertEquals("golden_vows" in main.properties, false);
  assertEquals("neon_night" in main.properties, false);
  assertEquals(schemaOf("emit_golden_vows").required, ["golden_vows"]);
});

Deno.test("currentGoldenVows: the stored section while it fits the memory", () => {
  const record = {
    status: "planned",
    plan: keepsakePlan(),
    problems: [],
    failed_ids: [],
    golden_vows: goldenVowsPlan(),
  } as unknown as DirectorRecord;
  assertEquals(
    currentGoldenVows(record, directorTripData()),
    goldenVowsPlan(),
  );
  assertEquals(
    currentGoldenVows({ ...record, golden_vows: null }, directorTripData()),
    null,
  );
});

const without = (...gone: string[]) => {
  const data = directorTripData();
  data.photos = data.photos.filter((p) => !gone.includes(p.id));
  return data;
};

Deno.test("currentGoldenVows heals a section the memory has outgrown (#393)", () => {
  const ids = DIRECTOR_PHOTO_IDS;
  const record = {
    status: "planned",
    plan: keepsakePlan(),
    problems: [],
    failed_ids: [],
    golden_vows: goldenVowsPlan(),
  } as unknown as DirectorRecord;

  // A chapter photo with no unused photo in its gap: the chapter goes.
  const dropped = currentGoldenVows(record, without(ids[5]))!;
  assertEquals(dropped.chapters.map((c) => c.title), [
    "Getting ready",
    "Just married",
  ]);
  // One with an unused photo in its gap is refilled, in time order.
  const refilled = currentGoldenVows(record, without(ids[10]))!;
  assertEquals(refilled.chapters[2].photo_ids, [ids[7], ids[8], ids[11]]);
  // Left out counts as gone.
  const leftOut = directorTripData();
  leftOut.photos[10].use_in_wrap_up = false;
  assertEquals(
    currentGoldenVows(record, leftOut)!.chapters[2].photo_ids,
    [ids[7], ids[8], ids[11]],
  );
  // A hero whose photo is gone goes; the album needs 2 heroes, so a third
  // is needed to keep it.
  assertEquals(currentGoldenVows(record, without(ids[9])), null);
  const threeHeroes = {
    ...record,
    golden_vows: {
      ...goldenVowsPlan(),
      heroes: [
        ...goldenVowsPlan().heroes,
        { photo_id: ids[11], label: "Cake", note_id: null, note_excerpt: null },
      ],
    },
  } as unknown as DirectorRecord;
  assertEquals(
    currentGoldenVows(threeHeroes, without(ids[9]))!.heroes.map((h) =>
      h.photo_id
    ),
    [ids[1], ids[11]],
  );
  // A reworded note loses its card, the album stays.
  const reworded = directorTripData();
  reworded.notes[0].content = "Bicycles all over the place.";
  const healed = currentGoldenVows(record, reworded)!;
  assertEquals(healed.heroes[0].note_id, null);
  assertEquals(healed.heroes[0].note_excerpt, null);
  // The stored record itself is never changed.
  assertEquals(record.golden_vows, goldenVowsPlan());
});

// --- Neon Night (#363), its own call since #380 ---

function neon(...answers: unknown[]) {
  return fakeAnthropic([choosing("neon_night")], {
    emit_neon_night: answers.map((a) => ({ neon_night: a })),
  });
}

Deno.test("runDirector keeps a valid Neon Night section on its own", async () => {
  const anthropic = neon(neonNightPlan());
  const { deps: d } = deps(anthropic.fetchImpl);

  const record = await runDirector(d, TRIP_ID, directorTripData(), "en");

  assertEquals(record.special_film, "neon_night");
  assertEquals(record.neon_night, neonNightPlan());
  assertEquals(record.neon_night_problems, []);
  assertEquals(record.golden_vows, null);
  assertEquals("neon_night" in record.plan!, false);
  // Only Neon Night's tool was called.
  assertEquals(
    anthropic.sent.some((s) => s.tool === "emit_golden_vows"),
    false,
  );
});

Deno.test("no Neon Night section is an answer: no retry", async () => {
  // null from the section call, or the plan call choosing none.
  for (const anthropic of [neon(null), fakeAnthropic([emittedPlan()])]) {
    const record = await runDirector(
      deps(anthropic.fetchImpl).deps,
      TRIP_ID,
      directorTripData(),
      "en",
    );
    assertEquals(record.attempts, 1);
    assertEquals(record.neon_night, null);
    assertEquals(record.neon_night_problems, []);
  }
});

Deno.test("an invalid Neon Night section is retried with its problems", async () => {
  // A fault code can't repair (a 2-photo peak it can, #382).
  const broken = neonNightPlan();
  broken.chapters[2].title = "A title far too long for the card";
  const anthropic = neon(broken, neonNightPlan());

  const record = await runDirector(
    deps(anthropic.fetchImpl).deps,
    TRIP_ID,
    directorTripData(),
    "en",
  );

  assertEquals(record.section_attempts, 2);
  assertEquals(record.neon_night, neonNightPlan());
  const retry = anthropic.sent.at(-1)!;
  assertEquals(retry.tool, "emit_neon_night");
  assertStringIncludes(
    (retry.body.messages as { content: string }[])[0].content,
    "neon_night.chapters[2].title: 33 characters, at most 22",
  );

  const stillBroken = neon(broken);
  const failed = await runDirector(
    deps(stillBroken.fetchImpl).deps,
    TRIP_ID,
    directorTripData(),
    "en",
  );
  assertEquals(failed.status, "planned");
  assertEquals(failed.neon_night, null);
  assert(failed.neon_night_problems!.length > 0);
});

Deno.test("the section call carries Neon Night's rules and the local times", async () => {
  const prompt = buildSectionSystemPrompt("neon_night", "en");
  assertStringIncludes(prompt, "neon_night");
  assertStringIncludes(prompt, "emit_neon_night");
  const anthropic = neon(neonNightPlan());
  const data = directorTripData({ utc_offset_minutes: 120 });
  data.notes[0].created_at = "2026-09-01T21:59:00Z";
  await runDirector(deps(anthropic.fetchImpl).deps, TRIP_ID, data, "en");
  const section = anthropic.sent.find((s) => s.tool === "emit_neon_night")!;
  const schema = (section.body.tools as {
    input_schema: { required: string[]; properties: Record<string, unknown> };
  }[])[0].input_schema;
  assertEquals(schema.required, ["neon_night"]);
  // Photo and note times on the app's clock, in both calls.
  for (const tool of ["emit_film_plan", "emit_neon_night"]) {
    const sent = anthropic.sent.find((s) => s.tool === tool)!;
    const content = (sent.body.messages as { content: string }[])[0].content;
    const input = JSON.parse(content.slice(content.indexOf("{")));
    assertEquals(input.photos[0].time, "12:00");
    assertEquals(input.notes[0].written_at, "23:59");
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

Deno.test("currentNeonNight: the stored section while it fits the memory", () => {
  const record = {
    status: "planned",
    plan: keepsakePlan(),
    problems: [],
    failed_ids: [],
    neon_night: neonNightPlan(),
  } as unknown as DirectorRecord;
  assertEquals(currentNeonNight(record, directorTripData()), neonNightPlan());
  assertEquals(
    currentNeonNight({ ...record, neon_night: null }, directorTripData()),
    null,
  );
});

Deno.test("currentNeonNight heals a section the memory has outgrown (#393)", () => {
  const ids = DIRECTOR_PHOTO_IDS;
  const record = {
    status: "planned",
    plan: keepsakePlan(),
    problems: [],
    failed_ids: [],
    neon_night: neonNightPlan(),
  } as unknown as DirectorRecord;
  const momentsOf = (plan: NeonNightPlan | null) =>
    plan!.chapters.map((c) => c.moments.map((m) => [m.type, ...m.photo_ids]));

  // A moment photo: the moment keeps the rest, in a type that fits.
  assertEquals(momentsOf(currentNeonNight(record, without(ids[9])))[2], [
    ["timeline", ids[8], ids[10]],
  ]);
  // A chapter's first photo: it starts at its earliest remaining one.
  const lateStart = currentNeonNight(record, without(ids[4]))!;
  assertEquals(lateStart.chapters[1].first_photo_id, ids[5]);
  assertEquals(momentsOf(lateStart)[1], [
    ["timeline", ids[5], ids[6], ids[7]],
  ]);
  // The first chapter's first photo: it starts at the night's first photo.
  const first = currentNeonNight(record, without(ids[0]))!;
  assertEquals(first.chapters[0].first_photo_id, ids[1]);
  // A whole chapter: it folds into the one before.
  const folded = currentNeonNight(
    record,
    without(ids[4], ids[5], ids[6], ids[7]),
  )!;
  assertEquals(folded.chapters.map((c) => c.title), [
    "Doors open",
    "Peak time",
  ]);
  // The note scene's photo: the note stays, without it.
  const noPhoto = currentNeonNight(record, without(ids[10]))!;
  assertEquals(noPhoto.note_moment?.excerpt, "Rain, then stroopwafels.");
  assertEquals(noPhoto.note_moment?.photo_id, null);
  // Left out counts as gone.
  const leftOut = directorTripData();
  leftOut.photos[9].use_in_wrap_up = false;
  assertEquals(momentsOf(currentNeonNight(record, leftOut))[2], [
    ["timeline", ids[8], ids[10]],
  ]);
  // A reworded note: no Note scene, the film stays.
  const reworded = directorTripData();
  reworded.notes[1].content = "Sun, then pancakes.";
  assertEquals(currentNeonNight(record, reworded)!.note_moment, null);
  // Nothing left to make a moment from: the next film plays.
  assertEquals(currentNeonNight(record, without(...ids.slice(1))), null);
  // The stored record itself is never changed.
  assertEquals(record.neon_night, neonNightPlan());
});
