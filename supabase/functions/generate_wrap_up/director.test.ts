import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  buildPlanInput,
  buildPlanSystemPrompt,
  currentPlan,
  type DirectorRecord,
  runDirector,
} from "./director.ts";
import { fakeSupabaseClient } from "./test_fakes.ts";
import {
  analysisFor,
  DIRECTOR_PHOTO_IDS,
  directorTripData,
  keepsakePlan,
  keepsakePlanWithFixableFaults,
  toolResponse,
} from "./director_fixtures.ts";
import type { TripData } from "./gather.ts";

const TRIP_ID = "trip-1";

interface SentRequest {
  tool: string;
  body: Record<string, unknown>;
}

// Answers analysis calls with a valid entry per photo id in the request,
// and plan calls with [plans] in turn.
function fakeAnthropic(plans: unknown[]) {
  const sent: SentRequest[] = [];
  let planCall = 0;
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
  const anthropic = fakeAnthropic([keepsakePlan()]);
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
  const anthropic = fakeAnthropic([keepsakePlan()]);
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
  const broken = keepsakePlan();
  broken.chapters[0].scenes[0].photo_ids = ["invented"];
  const anthropic = fakeAnthropic([broken, keepsakePlan()]);
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
  const broken = keepsakePlan();
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
  const anthropic = fakeAnthropic([keepsakePlan()]);
  const { deps: d } = deps(anthropic.fetchImpl);
  const data = directorTripData();
  data.photos = data.photos.slice(0, 4);

  const record = await runDirector(d, TRIP_ID, data, "en");

  assertEquals(record.status, "fallback");
  assertEquals(anthropic.sent.map((s) => s.tool), ["emit_photo_analysis"]);
});

Deno.test("left-out photos are never analysed or offered to the plan", async () => {
  const anthropic = fakeAnthropic([keepsakePlan()]);
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
  });
  assertEquals(input.photos[0].place, "Centraal");
  assertEquals(input.photos[1].bonus_task, "Snap a canal");
  assertEquals(input.photos[2].must_include, true);
  assertEquals(input.photos[11].day, 3);

  const system = buildPlanSystemPrompt("ru");
  assertStringIncludes(system, "rave: fits nights out");
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
  const anthropic = fakeAnthropic([keepsakePlan()]);
  const { deps: d } = deps(anthropic.fetchImpl);

  await runDirector(d, TRIP_ID, directorTripData(), "en");

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
