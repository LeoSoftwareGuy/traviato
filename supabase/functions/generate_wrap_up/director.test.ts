import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  currentGoldenVows,
  currentNeonNight,
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
  gvPicksAnswer,
  neonPicks,
  neonPicksAnswer,
  skyPicks,
  skyPicksAnswer,
  toolResponse,
} from "./director_fixtures.ts";
import { buildSkyPickSystemPrompt } from "./sky_slots.ts";
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
// Sky Story's pick calls with [skies] in turn (#463), and each other pick
// tool with its own answers in turn — an Error answer is a failed call
// (HTTP 400).
function fakeAnthropic(
  skies: unknown[],
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
    if (tool !== "pick_sky_lines" || skies.length === 0) {
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
    const answer = skies[Math.min(planCall++, skies.length - 1)];
    if (answer instanceof Error) {
      return Promise.resolve(
        new Response(JSON.stringify({ error: answer.message }), {
          status: 400,
        }),
      );
    }
    return Promise.resolve(toolResponse(tool, answer));
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

const skyAnswer = () => skyPicksAnswer(directorTripData());

Deno.test("runDirector analyses photos, caches them, picks and records cost", async () => {
  const anthropic = fakeAnthropic([skyAnswer()]);
  const { client, logs, deps: d } = deps(anthropic.fetchImpl);

  const record = await runDirector(d, TRIP_ID, directorTripData(), "en");

  assertEquals(record.status, "planned");
  assertEquals(record.problems, []);
  assertEquals(record.photos, {
    plannable: 12,
    analysed_now: 12,
    cached: 0,
    failed: 0,
  });
  assertEquals(Object.keys(record.photo_paths), DIRECTOR_PHOTO_IDS);
  // One call per film (#463): no classic plan, no four AI lines.
  assertEquals(anthropic.sent.map((s) => s.tool), [
    "emit_photo_analysis",
    "pick_sky_lines",
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
  const anthropic = fakeAnthropic([skyAnswer()]);
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

Deno.test("an Anthropic outage falls back without throwing", async () => {
  const { deps: d } = deps(
    () => Promise.resolve(new Response("down", { status: 529 })),
  );
  const record = await runDirector(d, TRIP_ID, directorTripData(), "en");
  assertEquals(record.status, "fallback");
  assertEquals(record.photos.failed, 12);
});

Deno.test("too few photos: no pick call, the reason recorded", async () => {
  const anthropic = fakeAnthropic([skyAnswer()]);
  const { deps: d } = deps(anthropic.fetchImpl);
  const data = directorTripData();
  data.photos = data.photos.slice(0, 4);

  const record = await runDirector(d, TRIP_ID, data, "en");

  assertEquals(record.status, "fallback");
  assertEquals(record.sky, null);
  assertEquals(record.sky_problems!.length, 1);
  assertEquals(anthropic.sent.map((s) => s.tool), ["emit_photo_analysis"]);
});

Deno.test("left-out photos are never analysed or offered to the picks", async () => {
  const anthropic = fakeAnthropic([skyAnswer()]);
  const { deps: d } = deps(anthropic.fetchImpl);
  const data = directorTripData();
  data.photos[11].use_in_wrap_up = false;

  const record = await runDirector(d, TRIP_ID, data, "en");

  assertEquals("p11" in record.photo_paths, false);
  const pick = anthropic.sent.find((s) => s.tool === "pick_sky_lines")!;
  const text = (pick.body.messages as { content: string }[])[0].content;
  assertEquals(text.includes('"p11"'), false);
});

Deno.test("runDirector sends strict tools: closed objects, no unsupported keywords", async () => {
  // Each film's pick call (#454, #458, #463).
  const sent: SentRequest[] = [];
  for (
    const [anthropic, data] of [
      [fakeAnthropic([skyAnswer()]), directorTripData()],
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
      "emit_photo_analysis",
      "pick_golden_vows_lines",
      "pick_neon_lines",
      "pick_sky_lines",
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

// --- Sky Story: code cuts, the director picks (#463) ---

Deno.test("a Sky Story memory: one pick_sky_lines call, its picks and slots kept", async () => {
  const anthropic = fakeAnthropic([skyAnswer()]);
  const record = await runDirector(
    deps(anthropic.fetchImpl).deps,
    TRIP_ID,
    directorTripData(),
    "en",
  );
  assertEquals(record.template, "sky_story");
  assertEquals(record.sky, {
    picks_version: 2,
    picks: skyPicks(directorTripData()),
  });
  assertEquals(record.golden_vows, null);
  assertEquals(record.neon_night, null);
  assertEquals(Object.keys(record.hero_scores!), DIRECTOR_PHOTO_IDS);
  assertEquals(record.photo_days, ["2026-09-01", "2026-09-02", "2026-09-03"]);
  // The director's own headline plays (it holds: the user's words).
  const head = record.sky_slots!.find((r) => r.slot === "p1.headline")!;
  assertEquals(head.source, "director");
  assertEquals(head.chosen.map((c) => c.text), ["Bikes first"]);
  assertEquals(record.sky_shown, { pages: 12, photos: 12 });
  assertEquals(record.sky_trims, []);
  assertEquals(record.sky_unlisted, []);
});

Deno.test("Sky Story: a pick from another slot's list takes code's top candidate", async () => {
  const answer = skyAnswer();
  const line = answer.picks.find((p) => p.slot === "p1.line1")!;
  const other = answer.picks.find((p) => p.slot === "p3.line1")!;
  line.ids = [other.ids[0].replace("p3.line1/", "p1.line1/")];
  const record = await runDirector(
    deps(fakeAnthropic([answer]).fetchImpl).deps,
    TRIP_ID,
    directorTripData(),
    "en",
  );
  const r = record.sky_slots!.find((x) => x.slot === "p1.line1")!;
  assertEquals(r.source, "code");
  assertEquals(r.chosen.map((c) => c.text), ["Bikes everywhere."]);
  assert(record.sky_problems!.some((p) => p.startsWith("p1.line1:")));
});

Deno.test("Sky Story: a headline the user never wrote takes code's choice", async () => {
  const answer = skyAnswer();
  // "Gondolas" is in no note, caption or place of this memory.
  answer.picks.find((p) => p.slot === "p1.headline")!.free_title =
    "Gondolas at dawn";
  const record = await runDirector(
    deps(fakeAnthropic([answer]).fetchImpl).deps,
    TRIP_ID,
    directorTripData(),
    "en",
  );
  const head = record.sky_slots!.find((r) => r.slot === "p1.headline")!;
  assertEquals(head.chosen.some((c) => c.text === "Gondolas at dawn"), false);
});

Deno.test("Sky Story: a failed call is retried once, then code picks every slot", async () => {
  const anthropic = fakeAnthropic([
    new Error("overloaded"),
    new Error("overloaded"),
  ]);
  const record = await runDirector(
    deps(anthropic.fetchImpl).deps,
    TRIP_ID,
    directorTripData(),
    "en",
  );
  assertEquals(calledTools(anthropic), ["pick_sky_lines", "pick_sky_lines"]);
  assertEquals(record.status, "fallback");
  assertEquals(record.sky, null);
  assertEquals(record.attempts, 2);
  assert(record.sky_slots!.every((r) => r.source !== "director"));
  assertEquals(record.sky_problems!.at(-1), "code picked every slot");
});

Deno.test("Sky Story: the pick call sees the cut pages, the slots and the rules", async () => {
  const anthropic = fakeAnthropic([skyAnswer()]);
  await runDirector(
    deps(anthropic.fetchImpl).deps,
    TRIP_ID,
    directorTripData({ utc_offset_minutes: 120 }),
    "en",
  );
  const pick = anthropic.sent.find((s) => s.tool === "pick_sky_lines")!;
  const text = (pick.body.messages as { content: string }[])[0].content;
  const input = JSON.parse(text.slice(text.indexOf("{")));
  assertEquals(input.pages.length, 3);
  assertEquals(input.pages[0].hero.time, "12:00");
  assert(
    input.slots.every((s: { slot: string; candidates: { id: string }[] }) =>
      s.candidates.every((c) => c.id.startsWith(`${s.slot}/`))
    ),
  );
  const system = pick.body.system as string;
  assertStringIncludes(system, "feelings first");
  assertStringIncludes(system, "never invent facts");
  assertStringIncludes(buildSkyPickSystemPrompt("ru"), "Russian");
});

function skyRecord(overrides: Partial<DirectorRecord> = {}): DirectorRecord {
  return {
    director_version: DIRECTOR_VERSION,
    status: "planned",
    problems: [],
    attempts: 1,
    model: "claude-sonnet-5",
    ran_at: "2026-11-08T12:00:00Z",
    photos: { plannable: 12, analysed_now: 12, cached: 0, failed: 0 },
    failed_ids: [],
    photo_paths: {},
    sky: { picks_version: 2, picks: skyPicks(directorTripData()) },
    photo_days: ["2026-09-01", "2026-09-02", "2026-09-03"],
    run_count: 1,
    usage: { calls: [], input_tokens: 0, output_tokens: 0, estimated_usd: 0 },
    ...overrides,
  };
}

Deno.test("currentSkyStory: the stored picks, else none; older pages aren't read", () => {
  assertEquals(currentSkyStory(skyRecord()), {
    picks: skyPicks(directorTripData()),
    source: "director",
  });
  assertEquals(currentSkyStory(null).source, "code");
  assertEquals(currentSkyStory(skyRecord({ sky: null })).picks, null);
  // Pages stored before #463.
  const old = skyRecord({ sky: undefined, sky_story: { pages: [] } });
  assertEquals(currentSkyStory(old), { picks: null, source: "code" });
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

Deno.test("the prompts: Golden Vows picks, no wedding words", () => {
  const romance = buildGvPickSystemPrompt("en", "romance");
  assertStringIncludes(romance, "pick_golden_vows_lines");
  assertStringIncludes(romance, "never use vows, wedding");
  assertStringIncludes(
    buildGvPickSystemPrompt("ru", "wedding"),
    "wedding words are fine",
  );
});

Deno.test("the tools: each film's picks on their own", async () => {
  const schemaOf = (a: ReturnType<typeof fakeAnthropic>, tool: string) =>
    (a.sent.find((s) => s.tool === tool)!.body.tools as {
      input_schema: { required: string[]; properties: Record<string, unknown> };
    }[])[0].input_schema;
  const sky = fakeAnthropic([skyAnswer()]);
  await runDirector(
    deps(sky.fetchImpl).deps,
    TRIP_ID,
    directorTripData(),
    "en",
  );
  assertEquals(schemaOf(sky, "pick_sky_lines").required, ["picks"]);

  const gv = golden(gvPicksAnswer(romantic()));
  await runDirector(deps(gv.fetchImpl).deps, TRIP_ID, romantic(), "en");
  assertEquals(schemaOf(gv, "pick_golden_vows_lines").required, ["picks"]);
});

Deno.test("currentGoldenVows: the stored picks, else none; older sections aren't read", () => {
  const picks = { finale: { ids: ["e:1"], free_title: null } };
  const record = {
    status: "planned",
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

Deno.test("an older record runs again once (#468: DIRECTOR_VERSION 10)", () => {
  assertEquals(DIRECTOR_VERSION, 10);
  const record = {
    status: "fallback",
    plan: null,
    problems: [],
    failed_ids: [],
    director_version: 9,
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
