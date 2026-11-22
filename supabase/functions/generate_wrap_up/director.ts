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
// The film's template comes from the memory's vibes, in code, before the
// director runs (#433) — the director only fills that template's plan and
// can never change it. One call after the photo analysis: a Sky Story
// memory's emit_film_plan (classic plan + Sky Story), or a Golden Vows /
// Neon Night memory's section on its own (one retry with the problems fed
// back). A section is repaired in code, and when that isn't enough code
// builds the same film's plan — the chosen film always plays.
//
// Neon Night (#454) is cut by code — chapters, scenes, length — and its
// one call (pick_neon_lines) only picks the words from code's candidates;
// a pick that isn't in its slot's list takes code's top candidate.
//
// Model: claude-sonnet-5 for every call, same as the 4 AI lines (#93).

import type { TripData } from "./gather.ts";
import { inclusiveDayCount, sortPhotosChronologically } from "./assemble.ts";
import { type FetchLike, logEvent, type LogLike } from "./anthropic.ts";
import {
  callAnthropicTool,
  type TokenUsage,
  type ToolDefinition,
} from "./anthropic_tool.ts";
import type { WrapUpLanguage } from "./language.ts";
import { WRAP_UP_LIMITS } from "./wrap_up_limits.ts";
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
  describeSkyStoryProblems,
  repairSkyStory,
  SKY_STORY_PROMPT_RULES,
  skyCheckContext,
  skyMaxPages,
  skyPhotos,
  type SkyStoryPlan,
  skyStoryToolProperty,
} from "./sky_story.ts";
import {
  describeGoldenVowsProblems,
  ensureGoldenVows,
  GOLDEN_VOWS_PROMPT_RULES,
  type GoldenVowsPlan,
  goldenVowsToolProperty,
  gvCheckContext,
  healGoldenVows,
} from "./golden_vows.ts";
import {
  type EnsuredSection,
  nnChapterStarts,
  nnCheckContext,
  nnLogicalDays,
} from "./neon_night.ts";
import {
  buildNeonPickInput,
  buildNeonPickSystemPrompt,
  isPicksRecord,
  type NeonNightPicksRecord,
  type NnPicks,
  parseNeonPicks,
  pickNeonLinesTool,
} from "./neon_slots.ts";
import { neonNightFilm, type NnSlotReport } from "./neon_film.ts";
import { type PlayedTemplate, playedTemplate } from "./film_template.ts";
import { withFilmPhotos } from "./film_photos.ts";
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
// The director runs again on its own when a memory's photo days change
// (#345), at most this many runs per memory in all. A manual rerun from
// the Plan inspector is never capped.
export const MAX_DIRECTOR_RUNS = 4;
// The director's rules (#398: logical days, excerpts, chronology; #433:
// the template from vibes). A record made under older rules runs again
// once, within MAX_DIRECTOR_RUNS.
export const DIRECTOR_VERSION = 5;

// The films with a section of their own (#346, #363).
type SectionFilm = "golden_vows";

// emit_film_plan with the Sky Story section (#345). Composed here so the
// films' modules don't import each other. No occasion choice since #433:
// the template comes from the vibes.
export const directorToolSchema = {
  ...filmPlanToolSchema,
  input_schema: {
    ...filmPlanToolSchema.input_schema,
    properties: {
      ...filmPlanToolSchema.input_schema.properties,
      sky_story: skyStoryToolProperty,
    },
    required: [
      ...filmPlanToolSchema.input_schema.required,
      "sky_story",
    ],
  },
};

// The second call's tool: one film's section, or null when the memory
// turns out not to be that occasion (#380).
function sectionTool(
  name: string,
  description: string,
  key: SectionFilm,
  property: unknown,
): ToolDefinition {
  return {
    name,
    description,
    input_schema: {
      type: "object",
      properties: { [key]: property },
      required: [key],
    },
  } as ToolDefinition;
}

export const sectionToolSchemas: Record<SectionFilm, ToolDefinition> = {
  golden_vows: sectionTool(
    "emit_golden_vows",
    "Emit this memory's Golden Vows album. The film is fixed: always emit it.",
    "golden_vows",
    goldenVowsToolProperty,
  ),
};

export type DirectorCall = TokenUsage & {
  call: "analysis" | "plan" | "section";
};

export interface DirectorRecord {
  // DIRECTOR_VERSION when it ran; absent = before #398.
  director_version?: number;
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
  // The Sky Story pages (#345), kept on their own: valid even when the
  // classic plan fell back. null = code-built pages; sky_problems says why.
  sky_story?: SkyStoryPlan | null;
  sky_problems?: string[];
  // The Golden Vows section (#346): null when the director chose another
  // occasion, or its section stayed invalid (golden_vows_problems says
  // why) — then Sky Story plays.
  golden_vows?: GoldenVowsPlan | null;
  golden_vows_problems?: string[];
  // Neon Night's words (#454): the director's picks by slot, or null
  // (code picks every slot). Records before #454 hold a whole plan here;
  // it is no longer read (DIRECTOR_VERSION 5 re-runs them).
  neon_night?: NeonNightPicksRecord | unknown | null;
  // Every Neon slot when it ran (#454, Plan inspector): its candidates,
  // the director's pick, what plays and why.
  neon_slots?: NnSlotReport[];
  neon_night_problems?: string[];
  // Before #433: which occasion film the plan call chose. Kept so older
  // records still read.
  special_film?: string | null;
  // The film this memory plays, from its vibes (#433).
  template?: PlayedTemplate;
  // The section call's attempts, when one ran.
  section_attempts?: number;
  // Where the played section came from (#433): the director's, repaired,
  // or built by code — and every repair with its reason (Plan inspector).
  golden_vows_source?: "director" | "code";
  golden_vows_repairs?: string[];
  neon_night_source?: "director" | "code";
  neon_night_repairs?: string[];
  // id → orientation of every analysed photo: Golden Vows' chapter
  // layouts.
  orientations?: Record<string, string>;
  // id → hero_score of every analysed photo, so code-built pages can still
  // pick strong heroes.
  hero_scores?: Record<string, number>;
  // The days with photos when it ran, and how many times it has run for
  // this memory (set by the handler).
  photo_days?: string[];
  run_count?: number;
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
  // Logical days (#398 R1): the night until about 08:00 is the evening's.
  const logical = nnLogicalDays(tripData);
  const dayOf = (id: string, fallback: string | null) =>
    logical.get(id) ?? fallback;
  // Where Neon Night's chapters must start (#426): each day and each part
  // of a day after a long break.
  // The same photos the check sees: the listed ones (and those left out).
  const listed = new Set(photos.map((p) => p.id));
  const nnContext = nnCheckContext({
    ...tripData,
    photos: tripData.photos.filter((p) =>
      listed.has(p.id) || p.use_in_wrap_up === false
    ),
  });
  const nnOrdered = [...nnContext.photoOrder.entries()].sort((a, b) =>
    a[1] - b[1]
  ).map(([id]) => id);
  const chapterStarts = new Set(
    nnChapterStarts(nnContext).map((at) => nnOrdered[at]),
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
    // The film's length decides how many Sky Story pages it holds (#434).
    sky_max_pages: skyMaxPages(tripData),
    achievement: tripData.latestAchievement?.title ?? null,
    notes: tripData.notes
      .filter((n) => n.id)
      .map((n) => ({
        note_id: n.id,
        day: dayNumber(trip.start_date, dayOf(`note:${n.id}`, n.day_date)),
        day_date: dayOf(`note:${n.id}`, n.day_date),
        text: n.content,
        // The note's own time and photo (#397); legacy notes have no photo.
        written_at: localClock(n.taken_at ?? n.created_at ?? null, tripData),
        photo_id: n.photo_id ?? null,
      })),
    // Already in chronological order (day, then time).
    photos: photos.map((p) => {
      const a = analyses.get(p.id)!;
      return {
        photo_id: p.id,
        day: dayNumber(trip.start_date, dayOf(p.id, p.day_date)),
        day_date: dayOf(p.id, p.day_date),
        time: localClock(p.taken_at ?? p.created_at, tripData),
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
        chapter_start: chapterStarts.has(p.id),
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
    } scenes. Tone: ${r.tone}.`;
  }).join("\n");
}

function sceneLines(): string {
  return Object.entries(SCENE_PHOTO_COUNT).map(([type, [min, max]]) =>
    `- ${type}: ${min === max ? min : `${min}–${max}`} photo${
      max === 1 ? "" : "s"
    }`
  ).join("\n");
}

function sectionLanguageRule(language: WrapUpLanguage): string {
  return language === "ru"
    ? 'Write every line in natural Russian, addressing the reader as "вы". Keep names of the memory, places and people exactly as given.'
    : "Write every line in English.";
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
    "and photos — never generic: quiet, wry.\n",
    `- bridge_line ≤ ${MAX_BRIDGE_CHARS} characters; text_card text ≤ ${MAX_TEXT_CARD_CHARS}; `,
    `footnote.line and closing_line ≤ ${MAX_CLOSING_CHARS}.\n`,
    `- Never use: ${BANNED_PHRASES.map((p) => `"${p}"`).join(", ")}.\n`,
    "- caption_note_id may point a scene at the note it illustrates, or null.\n",
    "- When unsure which recipe fits, choose keepsake.\n",
    "- reasoning: 2–3 sentences on why this occasion, recipe and shape.\n",
    `- ${languageRule(language)}`,
    SKY_STORY_PROMPT_RULES,
  ].join("");
}

// The second call's system prompt (#380): the shared rules and just that
// film's.
export function buildSectionSystemPrompt(
  film: SectionFilm,
  language: WrapUpLanguage,
): string {
  const name = "Golden Vows, an elegant ivory-and-gold album";
  return [
    "You are the director of a short film made from one person's memory. ",
    `It will be told as ${name}. Emit it with the `,
    `${sectionToolSchemas[film].name} tool. The film is chosen: always `,
    "emit it, never null.\n\n",
    "Rules:\n",
    "- Use only photo_ids and note_ids from the input. Never invent people, ",
    "places or events.\n",
    "- Photos are listed in order (day, then time); each at most once.\n",
    "- Prefer sharp photos with hero_score ≥ 3. Skip blurry or dark photos, ",
    "and all but one photo of each dup_group.\n",
    "- Lines are specific — real details from notes, places and photos — ",
    "never generic.\n",
    `- Never use: ${BANNED_PHRASES.map((p) => `"${p}"`).join(", ")}.\n`,
    NOTE_LINE_RULES,
    GOLDEN_VOWS_OCCASION_RULES,
    `- ${sectionLanguageRule(language)}`,
    GOLDEN_VOWS_PROMPT_RULES,
  ].join("");
}

// Which of the user's lines the film plays (#433), in priority order.
const NOTE_LINE_RULES = [
  `- At most ${WRAP_UP_LIMITS.maxNoteLines} of the user's lines in the `,
  "whole film, 2–3 per chapter. Choose them in this order: (1) emotions ",
  "and feelings; (2) lines that match the vibe (Nightlife: the music, the ",
  "crowd, the night; Romantic: the two of them, special moments; outdoors: ",
  "nature, the route, the effort); (3) specific details (numbers, names, ",
  'places, food); (4) generic summaries ("it was fun", "было весело", ',
  '"все устали") last. Exact words only.\n',
].join("");

// Golden Vows is chosen for every Romantic memory (#433), not only
// weddings.
const GOLDEN_VOWS_OCCASION_RULES = [
  "- occasion: wedding, engagement or anniversary only when the photos or ",
  "notes show one; date_night for a night out of two; otherwise romance. ",
  "Vows, wedding or marriage words only for a wedding. For romance, write ",
  'neutral romantic lines in the same style ("Just us", "Our Paris").\n',
].join("");

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
  // Stored on its own (DirectorRecord.sky_story).
  delete (plan as unknown as Record<string, unknown>).sky_story;
  delete (plan as unknown as Record<string, unknown>).golden_vows;
  delete (plan as unknown as Record<string, unknown>).neon_night;
  delete (plan as unknown as Record<string, unknown>).special_film;
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

// The occasion film's section in a call of its own (#380): its tool, its
// rules, one retry with the problems fed back. A null section is an
// answer (not that occasion after all). Never throws.
async function planSection(
  deps: DirectorDeps,
  calls: DirectorCall[],
  tripId: string,
  film: SectionFilm,
  input: ReturnType<typeof buildPlanInput>,
  language: WrapUpLanguage,
  check: (raw: unknown) => { value: unknown; problems: string[] },
): Promise<{ value: unknown | null; problems: string[]; attempts: number }> {
  const log = deps.log ?? console.error;
  const system = buildSectionSystemPrompt(film, language);
  let problems: string[] = [];
  let attempts = 0;
  for (let attempt = 1; attempt <= PLAN_ATTEMPTS; attempt++) {
    attempts = attempt;
    let toolInput: unknown;
    try {
      const result = await callAnthropicTool({
        apiKey: deps.apiKey,
        model: DIRECTOR_MODEL,
        maxTokens: PLAN_MAX_TOKENS,
        system,
        content: buildPlanUserPrompt(input, problems),
        tool: sectionToolSchemas[film],
        label: film,
        fetchImpl: deps.fetchImpl,
        log,
      });
      calls.push({ ...result.usage, call: "section" });
      toolInput = result.input;
    } catch (err) {
      problems = [`${film} call failed: ${(err as Error).message}`];
      continue;
    }
    const raw = typeof toolInput === "object" && toolInput !== null
      ? (toolInput as Record<string, unknown>)[film]
      : undefined;
    if (raw === null || raw === undefined) {
      return { value: null, problems: [], attempts };
    }
    const checked = check(raw);
    if (checked.problems.length === 0) {
      return { value: checked.value, problems: [], attempts };
    }
    problems = checked.problems;
    logEvent(log, "director_section_invalid", {
      trip_id: tripId,
      film,
      attempt,
      problems: problems.slice(0, 30),
    });
  }
  return { value: null, problems, attempts };
}

// Neon Night's words (#454): one pick_neon_lines call over code's cut
// film and its slots; a retry only when the call itself fails. Null =
// no picks (code picks every slot).
async function pickNeonLines(
  deps: DirectorDeps,
  calls: DirectorCall[],
  tripId: string,
  input: ReturnType<typeof buildNeonPickInput>,
  language: WrapUpLanguage,
): Promise<{ picks: NnPicks | null; problems: string[]; attempts: number }> {
  const log = deps.log ?? console.error;
  const problems: string[] = [];
  let attempts = 0;
  for (let attempt = 1; attempt <= PLAN_ATTEMPTS; attempt++) {
    attempts = attempt;
    try {
      const result = await callAnthropicTool({
        apiKey: deps.apiKey,
        model: DIRECTOR_MODEL,
        maxTokens: PLAN_MAX_TOKENS,
        system: buildNeonPickSystemPrompt(language),
        content: `Pick the words for this film:\n${JSON.stringify(input)}`,
        tool: pickNeonLinesTool,
        label: "neon_night",
        fetchImpl: deps.fetchImpl,
        log,
      });
      calls.push({ ...result.usage, call: "section" });
      const picks = parseNeonPicks(result.input);
      if (picks) return { picks, problems: [], attempts };
      problems.push("pick_neon_lines: not a list of picks");
    } catch (err) {
      problems.push(`neon_night call failed: ${(err as Error).message}`);
    }
    logEvent(log, "director_section_invalid", {
      trip_id: tripId,
      film: "neon_night",
      attempt,
      problems: problems.slice(-1),
    });
  }
  return { picks: null, problems, attempts };
}

// What the inspector lists as put right (#454): each slot where the
// director's pick didn't hold.
function neonRepairs(report: readonly NnSlotReport[]): string[] {
  return report.filter((r) => r.pick && r.source === "code").map((r) =>
    `${r.slot}: ${r.reason}`
  );
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
  // Decided in code, before anything runs (#433); never changed below.
  const template = playedTemplate(tripData.trip.vibes);
  const record: DirectorRecord = {
    director_version: DIRECTOR_VERSION,
    template,
    status: "fallback",
    plan: null,
    problems: [],
    attempts: 0,
    model: DIRECTOR_MODEL,
    ran_at: (deps.now?.() ?? new Date()).toISOString(),
    photos: { plannable: 0, analysed_now: 0, cached: 0, failed: 0 },
    failed_ids: [],
    photo_paths: {},
    sky_story: null,
    sky_problems: [],
    golden_vows: null,
    golden_vows_problems: [],
    neon_night: null,
    neon_night_problems: [],
    orientations: {},
    hero_scores: {},
    photo_days: photoDaysOf(tripData),
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

    // Every analysed photo's score: they pick the film's photos, here and
    // again when the content is built (code-built Sky pages use them too).
    record.hero_scores = Object.fromEntries(
      [...analyses].map(([id, a]) => [id, a.hero_score]),
    );
    // Only the film's photos (#433): Always picks, else the best up to 60.
    const film = withFilmPhotos(tripData, record.hero_scores);
    const inFilm = new Set(
      film.photos.filter((p) => p.use_in_wrap_up !== false).map((p) => p.id),
    );
    const usable = sortPhotosChronologically(
      candidates.filter((p) => analyses.has(p.id) && inFilm.has(p.id)),
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
    record.orientations = Object.fromEntries(
      usable.map((p) => [p.id, analyses.get(p.id)!.orientation]),
    );

    // The sections may use only analysed photos, so the director never
    // picks one it hasn't seen (unanalysed Always picks aren't required).
    const seen = {
      ...film,
      photos: film.photos.filter((p) =>
        analyses.has(p.id) || p.use_in_wrap_up === false
      ),
    };
    if (usable.length < MIN_PLANNABLE_PHOTOS) {
      record.problems = [
        `only ${usable.length} analysed photos, a plan needs at least ${MIN_PLANNABLE_PHOTOS}`,
      ];
      record.sky_problems = record.problems;
      if (template === "golden_vows") {
        record.golden_vows_source = "code";
        record.golden_vows_repairs = [
          ...record.problems,
          "the film plays code's plan",
        ];
      } else if (template === "neon_night") {
        record.neon_night_source = "code";
        record.neon_night_repairs = [
          ...record.problems,
          "the film plays code's plan",
        ];
      }
      return record;
    }

    const input = buildPlanInput(film, usable, analyses, language);

    if (template === "neon_night") {
      // Code cuts the film; one call picks its words (#454).
      const cut = neonNightFilm(seen, null, record.hero_scores);
      const outcome = await pickNeonLines(
        deps,
        calls,
        tripId,
        buildNeonPickInput(
          seen,
          cut.chapters,
          cut.slots,
          analyses,
          (iso) => localClock(iso, seen),
        ),
        language,
      );
      record.section_attempts = outcome.attempts;
      const played = neonNightFilm(seen, outcome.picks, record.hero_scores);
      record.neon_night = outcome.picks
        ? { picks_version: 2, picks: outcome.picks }
        : null;
      record.neon_slots = played.report;
      record.neon_night_source = outcome.picks ? "director" : "code";
      record.neon_night_repairs = outcome.picks
        ? neonRepairs(played.report)
        : [...outcome.problems, "code picked every slot"];
      record.problems = [`${template} memory: no classic plan call`];
      record.sky_problems = [`${template} memory: code-built pages`];
      return record;
    }

    if (template === "golden_vows") {
      // One call: the chosen film's section (#433).
      const ensure = (raw: unknown) =>
        ensureGoldenVows(raw, gvCheckContext(seen), language);
      const outcome = await planSection(
        deps,
        calls,
        tripId,
        template,
        input,
        language,
        (raw) => {
          const ensured = ensure(raw);
          return {
            value: ensured,
            problems: ensured.source === "director"
              ? []
              : ensured.repairs.filter((r) => r.startsWith("couldn't")),
          };
        },
      );
      record.section_attempts = outcome.attempts;
      const ensured = (outcome.value ?? ensure(null)) as ReturnType<
        typeof ensure
      >;
      const repairs = outcome.problems.length > 0
        ? [
          ...outcome.problems.map((p) =>
            `after ${outcome.attempts} tries: ${p}`
          ),
          "code built the plan",
        ]
        : ensured.repairs;
      record.golden_vows = ensured.plan as GoldenVowsPlan;
      record.golden_vows_source = ensured.source;
      record.golden_vows_repairs = repairs;
      // The classic plan and Sky Story pages are code's (no call): the
      // app's safety net if the chosen film fails while it plays.
      record.problems = [`${template} memory: no classic plan call`];
      record.sky_problems = [`${template} memory: code-built pages`];
      return record;
    }

    // A Sky Story memory: one call, the classic plan and Sky Story.
    const context = planContextFor(film, usable, language);
    const skyContext = skyCheckContext(seen);
    const system = buildPlanSystemPrompt(language);
    let problems: string[] = [];
    let skyProblems: string[] = [];
    for (let attempt = 1; attempt <= PLAN_ATTEMPTS; attempt++) {
      record.attempts = attempt;
      let toolInput: unknown;
      try {
        const result = await callAnthropicTool({
          apiKey: deps.apiKey,
          model: DIRECTOR_MODEL,
          maxTokens: PLAN_MAX_TOKENS,
          system,
          content: buildPlanUserPrompt(input, [...problems, ...skyProblems]),
          tool: directorToolSchema,
          label: "plan",
          fetchImpl: deps.fetchImpl,
          log,
        });
        calls.push({ ...result.usage, call: "plan" });
        toolInput = result.input;
      } catch (err) {
        // Keeps what an earlier attempt got right.
        const failed = `plan call failed: ${(err as Error).message}`;
        if (record.status !== "planned") problems = [failed];
        if (!record.sky_story) skyProblems = [failed];
        continue;
      }
      toolInput = repairFilmPlan(toolInput, context);
      const sky = repairSkyStory(
        typeof toolInput === "object" && toolInput !== null
          ? (toolInput as Record<string, unknown>).sky_story
          : undefined,
        skyContext,
      );
      // Each half keeps the first attempt that got it right; only what's
      // still wrong is fed back on the retry.
      if (record.status !== "planned") {
        problems = describeFilmPlanProblems(toolInput, context);
        if (problems.length === 0) {
          record.status = "planned";
          record.plan = normalisePlan(toolInput);
        }
      }
      if (!record.sky_story) {
        skyProblems = describeSkyStoryProblems(sky, skyContext);
        if (skyProblems.length === 0) {
          record.sky_story = sky as SkyStoryPlan;
        }
      }
      if (record.status === "planned" && record.sky_story) break;
      logEvent(log, "director_plan_invalid", {
        trip_id: tripId,
        attempt,
        problems: [...problems, ...skyProblems].slice(0, 30),
      });
    }
    record.problems = problems;
    record.sky_problems = skyProblems;
  } catch (err) {
    record.problems = [`director failed: ${(err as Error).message}`];
    record.sky_problems = record.problems;
    record.golden_vows_problems = record.problems;
    record.neon_night_problems = record.problems;
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

// The days with a photo the film could show, sorted. When they change, the
// director's pages no longer tell the whole memory (#345).
export function photoDaysOf(tripData: TripData): string[] {
  return [...new Set(skyPhotos(tripData).map((p) => p.day_date!))].sort();
}

// Whether the director should run again on its own: the memory's photo
// days changed since its last run, and it has runs left (#345).
export function directorIsStale(record: unknown, tripData: TripData): boolean {
  if (!isDirectorRecord(record)) return false;
  if ((record.run_count ?? 1) >= MAX_DIRECTOR_RUNS) return false;
  if ((record.director_version ?? 1) < DIRECTOR_VERSION) return true;
  // A film photo the director never saw (#444: it planned 21 of 27):
  // it runs again, unless the film was capped at its photo limit.
  const seen = record.photo_paths;
  if (seen) {
    const failed = new Set(record.failed_ids ?? []);
    const known = Object.keys(seen).length;
    const unseen = tripData.photos.some((p) =>
      p.use_in_wrap_up !== false && !(p.id in seen) && !failed.has(p.id)
    );
    if (unseen && known > 0 && known < WRAP_UP_LIMITS.maxFilmPhotos) {
      return true;
    }
  }
  const before = record.photo_days;
  if (!before) return false;
  const now = photoDaysOf(tripData);
  return before.length !== now.length || before.some((d, i) => d !== now[i]);
}

// The director's Sky Story pages if they still fit the memory as it is now
// (no deleted, moved or left-out photos, notes still there, every new
// Always pick shown) — otherwise null, and the film uses code-built pages.
export function currentSkyStory(
  record: unknown,
  tripData: TripData,
): SkyStoryPlan | null {
  if (!isDirectorRecord(record) || !record.sky_story) return null;
  const context = skyCheckContext(tripData, new Set(record.failed_ids ?? []));
  return describeSkyStoryProblems(record.sky_story, context).length === 0
    ? record.sky_story
    : null;
}

// The Golden Vows a Golden Vows memory plays now (#433): the director's
// section as stored while it fits, else healed to the memory as it is now
// (photos deleted or left out since, notes reworded — #393) and repaired,
// else code's plan for the same film. Never null.
export function currentGoldenVows(
  record: unknown,
  tripData: TripData,
  language: WrapUpLanguage = "en",
): EnsuredSection<GoldenVowsPlan> {
  const stored = isDirectorRecord(record) ? record.golden_vows ?? null : null;
  const context = gvCheckContext(
    tripData,
    new Set(isDirectorRecord(record) ? record.failed_ids ?? [] : []),
  );
  if (stored && describeGoldenVowsProblems(stored, context).length === 0) {
    return {
      plan: stored,
      source: (record as DirectorRecord).golden_vows_source ?? "director",
      repairs: (record as DirectorRecord).golden_vows_repairs ?? [],
    };
  }
  const ensured = ensureGoldenVows(
    stored ? healGoldenVows(stored, context) : null,
    context,
    language,
  );
  return stored
    ? { ...ensured, repairs: ["healed to the memory now", ...ensured.repairs] }
    : ensured;
}

// The Neon Night words a Neon Night memory plays now (#454): the
// director's stored picks — re-applied by id to the film code cuts from
// the memory as it is now, so a gone or reworded line takes code's top
// candidate — else none (code picks every slot). Records before #454
// held a whole plan: not read.
export function currentNeonNight(
  record: unknown,
): { picks: NnPicks | null; source: "director" | "code" } {
  const stored = isDirectorRecord(record) ? record.neon_night ?? null : null;
  return isPicksRecord(stored)
    ? { picks: stored.picks, source: "director" }
    : { picks: null, source: "code" };
}

// [iso] as 'HH:MM' on the app's clock (TripData.utc_offset_minutes, #363),
// or null.
export function localClock(
  iso: string | null,
  tripData: TripData,
): string | null {
  if (!iso) return null;
  const ms = Date.parse(iso);
  if (Number.isNaN(ms)) return null;
  const local = new Date(ms + (tripData.utc_offset_minutes ?? 0) * 60_000);
  const two = (v: number) => String(v).padStart(2, "0");
  return `${two(local.getUTCHours())}:${two(local.getUTCMinutes())}`;
}
