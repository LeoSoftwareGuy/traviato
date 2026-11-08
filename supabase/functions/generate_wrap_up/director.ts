// The Director (#328, docs/design/wrap-up-film-v2-design.md, Part 1):
// photos (analysed, call 1) + notes + memory facts in, a validated film plan
// (call 2) out. Invalid plan → one retry with the problems fed back → a
// fallback record, and the film plays today's template.
//
// The result is stored as wrap_ups.director (a DirectorRecord). A plan that
// still matches the memory is merged into a draft's content as
// `plan_version: 2` + `plan`, next to everything the current player reads,
// so the current film keeps playing until the plan-driven player lands.
//
// Model: claude-sonnet-5 for both calls, same as the 4 AI lines (#93).

import type { TripData } from "./gather.ts";
import { inclusiveDayCount, sortPhotosChronologically } from "./assemble.ts";
import { type FetchLike, logEvent, type LogLike } from "./anthropic.ts";
import { callAnthropicTool, type TokenUsage } from "./anthropic_tool.ts";
import type { WrapUpLanguage } from "./language.ts";
import {
  BANNED_PHRASES,
  describeFilmPlanProblems,
  type FilmPlan,
  filmPlanToolSchema,
  MAX_BRIDGE_CHARS,
  MAX_CLOSING_CHARS,
  MAX_TEXT_CARD_CHARS,
  MAX_TOTAL_SECONDS,
  MIN_TOTAL_SECONDS,
  type PlanContext,
  RECIPE_RULES,
  RECIPES,
  repairFilmPlan,
  SCENE_PHOTO_COUNT,
} from "./film_plan.ts";
import {
  analysePhotos,
  type ImageUrlSigner,
  loadCachedAnalysis,
  type PhotoAnalysis,
  photosNeedingAnalysis,
  plannablePhotos,
  saveAnalysis,
} from "./photo_analysis.ts";

// deno-lint-ignore no-explicit-any
type SupabaseClient = any;

export const DIRECTOR_MODEL = "claude-sonnet-5";
// Claude Sonnet 5 list price, USD per million tokens — the inspector's
// cost estimate only.
const PRICE_PER_MTOK = { input: 2, output: 10 };
const PLAN_MAX_TOKENS = 8192;
const PLAN_ATTEMPTS = 2;
// Below this many analysed photos there's nothing for a director to shape.
export const MIN_PLANNABLE_PHOTOS = 6;

export type DirectorCall = TokenUsage & { call: "analysis" | "plan" };

export interface DirectorRecord {
  status: "planned" | "fallback";
  plan: FilmPlan | null;
  // Why the plan fell back (or what the first attempt got wrong).
  problems: string[];
  attempts: number;
  model: string;
  ran_at: string;
  photos: {
    plannable: number;
    analysed_now: number;
    cached: number;
    failed: number;
  };
  // Photos that couldn't be analysed this run — not required by the
  // "Always" rule when the stored plan is checked again.
  failed_ids: string[];
  // id → storage path of every photo the plan could use (inspector
  // thumbnails).
  photo_paths: Record<string, string>;
  usage: {
    calls: DirectorCall[];
    input_tokens: number;
    output_tokens: number;
    estimated_usd: number;
  };
}

export interface DirectorDeps {
  client: SupabaseClient;
  apiKey: string;
  fetchImpl?: FetchLike;
  log?: LogLike;
  now?: () => Date;
  // Overridable in tests.
  signImageUrls?: ImageUrlSigner;
}

type Photo = TripData["photos"][number];

function dayNumber(startDate: string | null, dayDate: string | null) {
  if (!startDate || !dayDate) return null;
  return inclusiveDayCount(startDate, dayDate);
}

// What call 2 sees — facts only, chronological, ids it may use.
export function buildPlanInput(
  tripData: TripData,
  photos: Photo[],
  analyses: ReadonlyMap<string, PhotoAnalysis>,
  language: WrapUpLanguage,
) {
  const { trip } = tripData;
  const bonusByPhoto = new Map(
    tripData.completedBonusTasks
      .filter((b) => b.photo_id)
      .map((b) => [b.photo_id!, b.title]),
  );
  return {
    language,
    memory: {
      name: trip.name,
      destination: trip.destination,
      start_date: trip.start_date,
      end_date: trip.end_date,
      day_count: inclusiveDayCount(trip.start_date, trip.end_date),
      vibes: trip.vibes,
    },
    achievement: tripData.latestAchievement?.title ?? null,
    notes: tripData.notes
      .filter((n) => n.id)
      .map((n) => ({
        note_id: n.id,
        day: dayNumber(trip.start_date, n.day_date),
        day_date: n.day_date,
        text: n.content,
      })),
    // Already in chronological order (day, then time).
    photos: photos.map((p) => {
      const a = analyses.get(p.id)!;
      return {
        photo_id: p.id,
        day: dayNumber(trip.start_date, p.day_date),
        day_date: p.day_date,
        summary: a.summary,
        setting: a.setting,
        people: a.people,
        energy: a.energy,
        quality: a.quality,
        orientation: a.orientation,
        hero_score: a.hero_score,
        dup_group: a.dup_group,
        place: p.place_text ?? null,
        tagged_people: p.people_tags ?? [],
        caption: p.caption,
        bonus_task: bonusByPhoto.get(p.id) ?? null,
        must_include: p.use_in_wrap_up === true,
      };
    }),
  };
}

function recipeLines(): string {
  return RECIPES.map((recipe) => {
    const r = RECIPE_RULES[recipe];
    return `- ${recipe}: fits ${r.fits}. Scenes: ${
      r.scenes.join(", ")
    }. Each scene ${r.minDuration}–${r.maxDuration}s, so at least ${
      Math.ceil(MIN_TOTAL_SECONDS / r.maxDuration)
    } scenes.${
      r.minBursts > 0 ? ` At least ${r.minBursts} bursts.` : ""
    } Tone: ${r.tone}.`;
  }).join("\n");
}

function sceneLines(): string {
  return Object.entries(SCENE_PHOTO_COUNT).map(([type, [min, max]]) =>
    `- ${type}: ${min === max ? min : `${min}–${max}`} photo${
      max === 1 ? "" : "s"
    }`
  ).join("\n");
}

function languageRule(language: WrapUpLanguage): string {
  return language === "ru"
    ? 'Write every line in natural Russian, addressing the reader as "вы". Keep names of the memory, places and people exactly as given. Set "language" to "ru".'
    : 'Write every line in English. Set "language" to "en".';
}

export function buildPlanSystemPrompt(language: WrapUpLanguage): string {
  return [
    "You are the director of a short film made from one person's memory ",
    "(a trip, a night out, a wedding…). You choose how the film is told: ",
    "the occasion, a recipe, and the scenes in order, using the person's ",
    "own photos and notes. Emit the plan with the emit_film_plan tool.\n\n",
    "Recipes:\n",
    recipeLines(),
    "\n\nPhotos per scene type:\n",
    sceneLines(),
    "\n- text_card: shows its `text` line instead of photos.\n",
    "- A collage takes exactly its number of photos. Two photos left over ",
    "make two card_flip scenes, never a collage.\n\n",
    "Rules:\n",
    "- Use only photo_ids and note_ids from the input. Never invent people, ",
    "places or events.\n",
    "- Chronological: photos appear in the order they are listed (day, then ",
    "time), across scenes and chapters. Each photo at most once.\n",
    "- Prefer sharp photos with hero_score ≥ 3 for full-screen scenes ",
    '(card_flip, emphasis "hero"). Skip blurry or dark photos, and all but ',
    "one photo of each dup_group.\n",
    "- Every photo with must_include true must be in the plan.\n",
    `- The scenes add up to ${MIN_TOTAL_SECONDS}–${MAX_TOTAL_SECONDS} seconds.\n`,
    "- 2–3 chapters, each opening with a bridge_line.\n",
    "- Lines are second person, specific — real details from notes, places ",
    "and photos — never generic. Keepsake: quiet, wry. Rave: playful, a bit ",
    "cheeky.\n",
    `- bridge_line ≤ ${MAX_BRIDGE_CHARS} characters; text_card text ≤ ${MAX_TEXT_CARD_CHARS}; `,
    `footnote.line and closing_line ≤ ${MAX_CLOSING_CHARS}.\n`,
    `- Never use: ${BANNED_PHRASES.map((p) => `"${p}"`).join(", ")}.\n`,
    "- caption_note_id may point a scene at the note it illustrates, or null.\n",
    "- When unsure which recipe fits, choose keepsake.\n",
    "- reasoning: 2–3 sentences on why this occasion, recipe and shape.\n",
    `- ${languageRule(language)}`,
  ].join("");
}

export function buildPlanUserPrompt(
  input: ReturnType<typeof buildPlanInput>,
  previousProblems: string[] = [],
): string {
  const base = `Plan the film for this memory:\n${JSON.stringify(input)}`;
  if (previousProblems.length === 0) return base;
  return `${base}\n\nYour previous plan broke these rules — emit a corrected plan:\n${
    previousProblems.map((p) => `- ${p}`).join("\n")
  }`;
}

// Fills the optional fields the model may leave out, so a stored plan
// always has the full shape.
function normalisePlan(input: unknown): FilmPlan {
  const plan = structuredClone(input) as FilmPlan;
  for (const chapter of plan.chapters) {
    for (const scene of chapter.scenes) {
      scene.caption_note_id = scene.caption_note_id ?? null;
      scene.text = scene.type === "text_card" ? scene.text : null;
    }
  }
  return plan;
}

export function planContextFor(
  tripData: TripData,
  plannable: Photo[],
  language: WrapUpLanguage,
  notRequiredIds: ReadonlySet<string> = new Set(),
): PlanContext {
  return {
    language,
    photoOrder: plannable.map((p) => p.id),
    excludedIds: new Set(
      tripData.photos.filter((p) => p.use_in_wrap_up === false).map((p) =>
        p.id
      ),
    ),
    mustIncludeIds: new Set(
      plannable
        .filter((p) => p.use_in_wrap_up === true && !notRequiredIds.has(p.id))
        .map((p) => p.id),
    ),
    noteIds: new Set(
      tripData.notes.map((n) => n.id).filter((id): id is string => !!id),
    ),
  };
}

function summariseUsage(calls: DirectorCall[]): DirectorRecord["usage"] {
  const input = calls.reduce((s, c) => s + c.input_tokens, 0);
  const output = calls.reduce((s, c) => s + c.output_tokens, 0);
  const usd = (input * PRICE_PER_MTOK.input + output * PRICE_PER_MTOK.output) /
    1_000_000;
  return {
    calls,
    input_tokens: input,
    output_tokens: output,
    estimated_usd: Math.round(usd * 10000) / 10000,
  };
}

// Runs the director for one memory. Never throws: anything that goes wrong
// becomes a fallback record, so the film always plays.
export async function runDirector(
  deps: DirectorDeps,
  tripId: string,
  tripData: TripData,
  language: WrapUpLanguage,
): Promise<DirectorRecord> {
  const log = deps.log ?? console.error;
  const calls: DirectorCall[] = [];
  const record: DirectorRecord = {
    status: "fallback",
    plan: null,
    problems: [],
    attempts: 0,
    model: DIRECTOR_MODEL,
    ran_at: (deps.now?.() ?? new Date()).toISOString(),
    photos: { plannable: 0, analysed_now: 0, cached: 0, failed: 0 },
    failed_ids: [],
    photo_paths: {},
    usage: summariseUsage(calls),
  };

  try {
    const candidates = plannablePhotos(tripData);
    const cached = await loadCachedAnalysis(deps.client, tripId);
    const toAnalyse = photosNeedingAnalysis(candidates, cached);
    const run = await analysePhotos({
      client: deps.client,
      apiKey: deps.apiKey,
      model: DIRECTOR_MODEL,
      fetchImpl: deps.fetchImpl,
      log,
      signImageUrls: deps.signImageUrls,
    }, toAnalyse);
    calls.push(...run.usage.map((u) => ({ ...u, call: "analysis" as const })));
    try {
      await saveAnalysis(
        deps.client,
        tripId,
        toAnalyse,
        run.analysed,
        DIRECTOR_MODEL,
      );
    } catch (err) {
      // The plan can still be made from this run's results.
      logEvent(log, "director_cache_save_failed", {
        trip_id: tripId,
        detail: (err as Error).message,
      });
    }

    const analyses = new Map<string, PhotoAnalysis>();
    for (const photo of candidates) {
      const row = cached.get(photo.id);
      if (row && row.storage_path === photo.storage_path) {
        analyses.set(photo.id, row);
      }
    }
    for (const a of run.analysed) analyses.set(a.photo_id, a);

    const usable = sortPhotosChronologically(
      candidates.filter((p) => analyses.has(p.id)),
    );
    record.failed_ids = run.failedIds;
    record.photos = {
      plannable: usable.length,
      analysed_now: run.analysed.length,
      cached: candidates.length - toAnalyse.length,
      failed: run.failedIds.length,
    };
    record.photo_paths = Object.fromEntries(
      usable.map((p) => [p.id, p.storage_path]),
    );

    if (usable.length < MIN_PLANNABLE_PHOTOS) {
      record.problems = [
        `only ${usable.length} analysed photos, a plan needs at least ${MIN_PLANNABLE_PHOTOS}`,
      ];
      return record;
    }

    const context = planContextFor(tripData, usable, language);
    const input = buildPlanInput(tripData, usable, analyses, language);
    const system = buildPlanSystemPrompt(language);
    let problems: string[] = [];
    for (let attempt = 1; attempt <= PLAN_ATTEMPTS; attempt++) {
      record.attempts = attempt;
      let toolInput: unknown;
      try {
        const result = await callAnthropicTool({
          apiKey: deps.apiKey,
          model: DIRECTOR_MODEL,
          maxTokens: PLAN_MAX_TOKENS,
          system,
          content: buildPlanUserPrompt(input, problems),
          tool: filmPlanToolSchema,
          label: "plan",
          fetchImpl: deps.fetchImpl,
          log,
        });
        calls.push({ ...result.usage, call: "plan" });
        toolInput = result.input;
      } catch (err) {
        problems = [`plan call failed: ${(err as Error).message}`];
        continue;
      }
      toolInput = repairFilmPlan(toolInput);
      problems = describeFilmPlanProblems(toolInput, context);
      if (problems.length === 0) {
        record.status = "planned";
        record.plan = normalisePlan(toolInput);
        break;
      }
      logEvent(log, "director_plan_invalid", {
        trip_id: tripId,
        attempt,
        problems: problems.slice(0, 30),
      });
    }
    record.problems = problems;
  } catch (err) {
    record.problems = [`director failed: ${(err as Error).message}`];
  } finally {
    record.usage = summariseUsage(calls);
    logEvent(log, "director_usage", {
      trip_id: tripId,
      status: record.status,
      attempts: record.attempts,
      ...record.photos,
      input_tokens: record.usage.input_tokens,
      output_tokens: record.usage.output_tokens,
      estimated_usd: record.usage.estimated_usd,
    });
  }
  return record;
}

export function isDirectorRecord(value: unknown): value is DirectorRecord {
  if (typeof value !== "object" || value === null) return false;
  const r = value as Record<string, unknown>;
  return (r.status === "planned" || r.status === "fallback") &&
    Array.isArray(r.problems) && Array.isArray(r.failed_ids ?? []);
}

// The plan from [record] if it still fits the memory as it is now (no
// deleted or left-out photos, every new "Always" pick in, same language) —
// otherwise null and the film plays today's template.
export function currentPlan(
  record: unknown,
  tripData: TripData,
  language: WrapUpLanguage,
): FilmPlan | null {
  if (
    !isDirectorRecord(record) || record.status !== "planned" || !record.plan
  ) {
    return null;
  }
  const photos = sortPhotosChronologically(
    tripData.photos.filter((p) => p.use_in_wrap_up !== false),
  );
  const context = planContextFor(
    tripData,
    photos,
    language,
    new Set(record.failed_ids ?? []),
  );
  return describeFilmPlanProblems(record.plan, context).length === 0
    ? record.plan
    : null;
}
