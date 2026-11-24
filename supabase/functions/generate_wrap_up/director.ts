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
// director runs (#433) — the director can never change it. Every film is
// cut by code — Neon Night (#454), Golden Vows (#458), Sky Story (#463):
// pages or chapters, scenes, length — and one call after the photo
// analysis only picks its words from code's candidates (pick_neon_lines,
// pick_golden_vows_lines, pick_sky_lines); a pick that isn't in its
// slot's list takes code's top candidate. One AI call per film. Since
// #463 there is no classic plan call (emit_film_plan) and no call for the
// classic film's four lines: those come from the notes (code_lines.ts).
//
// Model: claude-sonnet-5 for every call.

import { localMs } from "./time_zones.ts";
import type { TripData } from "./gather.ts";
import { sortPhotosChronologically } from "./assemble.ts";
import { type FetchLike, logEvent, type LogLike } from "./anthropic.ts";
import {
  callAnthropicTool,
  type TokenUsage,
  type ToolDefinition,
} from "./anthropic_tool.ts";
import type { WrapUpLanguage } from "./language.ts";
import { WRAP_UP_LIMITS } from "./wrap_up_limits.ts";
import { skyPhotos } from "./sky_story.ts";
import { type SkySlotReport, skyStoryFilm } from "./sky_film.ts";
import {
  buildSkyPickInput,
  buildSkyPickSystemPrompt,
  pickSkyLinesTool,
  skyLanguage,
} from "./sky_slots.ts";
import { goldenVowsFilm, type GvSlotReport } from "./gv_film.ts";
import {
  buildGvPickInput,
  buildGvPickSystemPrompt,
  gvLanguage,
  pickGoldenVowsLinesTool,
} from "./gv_slots.ts";
import type { GvOccasionTrigger } from "./gv_skeleton.ts";
import { parsePicks, type SlotPicks } from "./film_slots.ts";
import {
  buildNeonPickInput,
  buildNeonPickSystemPrompt,
  isPicksRecord,
  type NeonNightPicksRecord,
  type NnPicks,
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
// the template from vibes; #454 / #458: Neon Night and Golden Vows pick
// from code's lists; #460: Golden Vows' new pages and slot lists;
// #461: photo and note times on their own place's clock; #463: Sky Story
// picks from code's lists, no classic plan call). A record made under
// older rules runs again once, within MAX_DIRECTOR_RUNS.
export const DIRECTOR_VERSION = 9;

export type DirectorCall = TokenUsage & {
  call: "analysis" | "plan" | "section";
};

export interface DirectorRecord {
  // DIRECTOR_VERSION when it ran; absent = before #398.
  director_version?: number;
  // "planned": the director's picks came back (#463: Sky Story; Golden
  // Vows and Neon Night keep "fallback", as before — the word was the
  // classic plan's).
  status: "planned" | "fallback";
  // Before #463: the classic plan (emit_film_plan). No longer written or
  // read.
  plan?: unknown;
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
  // Before #463: the director's own Sky Story pages. No longer read.
  sky_story?: unknown;
  // Sky Story's words (#463): the director's picks by slot, or null (code
  // picks every slot); every slot when it ran, what the film gave up for
  // its length, its photos on pages and the notes on no page (Plan
  // inspector).
  sky?: { picks_version: 2; picks: SlotPicks } | null;
  sky_slots?: SkySlotReport[];
  sky_trims?: string[];
  sky_shown?: { pages: number; photos: number };
  sky_unlisted?: { note_id: string; text: string; reason: string }[];
  sky_problems?: string[];
  // Golden Vows' words (#458): the director's picks by slot, or null
  // (code picks every slot). Records before #458 hold a whole section
  // here; it is no longer read (DIRECTOR_VERSION 6 re-runs them).
  golden_vows?: { picks_version: 2; picks: SlotPicks } | unknown | null;
  golden_vows_problems?: string[];
  // Every Golden Vows slot when it ran (#458, Plan inspector), what the
  // album gave up for its length, its photos on pages, the notes on no
  // page and why, and the word that made it a wedding (or null).
  gv_slots?: GvSlotReport[];
  gv_trims?: string[];
  gv_shown?: { pages: number; photos: number };
  gv_unlisted?: { note_id: string; text: string; reason: string }[];
  gv_trigger?: GvOccasionTrigger | null;
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

// A film's words (#454, #458): one call over code's cut film and its
// slots; a retry only when the call itself fails. Null = no picks (code
// picks every slot).
async function pickLines(
  deps: DirectorDeps,
  calls: DirectorCall[],
  tripId: string,
  film: "neon_night" | "golden_vows" | "sky_story",
  call: { system: string; input: unknown; tool: ToolDefinition },
): Promise<{ picks: SlotPicks | null; problems: string[]; attempts: number }> {
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
        system: call.system,
        content: `Pick the words for this film:\n${JSON.stringify(call.input)}`,
        tool: call.tool,
        label: film,
        fetchImpl: deps.fetchImpl,
        log,
      });
      calls.push({ ...result.usage, call: "section" });
      const picks = parsePicks(result.input);
      if (picks) return { picks, problems: [], attempts };
      problems.push(`${call.tool.name}: not a list of picks`);
    } catch (err) {
      problems.push(`${film} call failed: ${(err as Error).message}`);
    }
    logEvent(log, "director_section_invalid", {
      trip_id: tripId,
      film,
      attempt,
      problems: problems.slice(-1),
    });
  }
  return { picks: null, problems, attempts };
}

// What the inspector lists as put right (#454): each slot where the
// director's pick didn't hold.
function pickRepairs(
  report: readonly (NnSlotReport | GvSlotReport | SkySlotReport)[],
): string[] {
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
    problems: [],
    attempts: 0,
    model: DIRECTOR_MODEL,
    ran_at: (deps.now?.() ?? new Date()).toISOString(),
    photos: { plannable: 0, analysed_now: 0, cached: 0, failed: 0 },
    failed_ids: [],
    photo_paths: {},
    sky: null,
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

    if (template === "neon_night") {
      // Code cuts the film; one call picks its words (#454).
      const cut = neonNightFilm(seen, null, record.hero_scores);
      const outcome = await pickLines(deps, calls, tripId, "neon_night", {
        system: buildNeonPickSystemPrompt(language),
        input: buildNeonPickInput(
          seen,
          cut.chapters,
          cut.slots,
          analyses,
          (iso, item) => localClock(iso, seen, item),
        ),
        tool: pickNeonLinesTool,
      });
      record.section_attempts = outcome.attempts;
      const played = neonNightFilm(seen, outcome.picks, record.hero_scores);
      record.neon_night = outcome.picks
        ? { picks_version: 2, picks: outcome.picks }
        : null;
      record.neon_slots = played.report;
      record.neon_night_source = outcome.picks ? "director" : "code";
      record.neon_night_repairs = outcome.picks
        ? pickRepairs(played.report)
        : [...outcome.problems, "code picked every slot"];
      record.sky_problems = [`${template} memory: code-picked words`];
      return record;
    }

    if (template === "golden_vows") {
      // Code cuts the album; one call picks its words (#458).
      const options = {
        heroScores: record.hero_scores,
        orientations: record.orientations,
        summaries: new Map([...analyses].map(([id, a]) => [id, a.summary])),
        language,
      };
      const cut = goldenVowsFilm(seen, null, options);
      const outcome = await pickLines(deps, calls, tripId, "golden_vows", {
        system: buildGvPickSystemPrompt(
          gvLanguage(seen, language),
          cut.skeleton.occasion,
        ),
        input: buildGvPickInput(
          seen,
          cut.skeleton,
          cut.slots,
          analyses,
          (iso, item) => localClock(iso, seen, item),
        ),
        tool: pickGoldenVowsLinesTool,
      });
      record.section_attempts = outcome.attempts;
      const played = goldenVowsFilm(seen, outcome.picks, options);
      record.golden_vows = outcome.picks
        ? { picks_version: 2, picks: outcome.picks }
        : null;
      record.gv_slots = played.report;
      record.gv_trims = played.trims;
      record.gv_shown = played.shown;
      record.gv_unlisted = played.unlisted;
      record.gv_trigger = played.trigger;
      record.golden_vows_source = outcome.picks ? "director" : "code";
      record.golden_vows_repairs = outcome.picks
        ? pickRepairs(played.report)
        : [...outcome.problems, "code picked every slot"];
      // Sky Story's words are code's (no call): the app's safety net if
      // the chosen film fails while it plays.
      record.sky_problems = [`${template} memory: code-picked words`];
      return record;
    }

    // A Sky Story memory: code cuts the pages; one call picks their
    // words (#463).
    const options = {
      heroScores: record.hero_scores,
      summaries: new Map([...analyses].map(([id, a]) => [id, a.summary])),
      language,
    };
    const cut = skyStoryFilm(seen, null, options);
    const outcome = await pickLines(deps, calls, tripId, "sky_story", {
      system: buildSkyPickSystemPrompt(skyLanguage(seen, language)),
      input: buildSkyPickInput(
        seen,
        cut.skeleton,
        cut.slots,
        analyses,
        (iso, item) => localClock(iso, seen, item),
      ),
      tool: pickSkyLinesTool,
    });
    record.attempts = outcome.attempts;
    const played = skyStoryFilm(seen, outcome.picks, options);
    record.status = outcome.picks ? "planned" : "fallback";
    record.sky = outcome.picks
      ? { picks_version: 2, picks: outcome.picks }
      : null;
    record.sky_slots = played.report;
    record.sky_trims = played.trims;
    record.sky_shown = played.shown;
    record.sky_unlisted = played.unlisted;
    record.problems = outcome.problems;
    record.sky_problems = outcome.picks
      ? pickRepairs(played.report)
      : [...outcome.problems, "code picked every slot"];
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

// The Sky Story words a memory plays now (#463): the director's stored
// picks, re-applied by id to the pages code cuts from the memory as it is
// now (a gone or reworded line takes code's top candidate), else none.
// Records before #463 held whole pages: not read. A Golden Vows or Neon
// Night memory's Sky Story (the safety net) is always code's.
export function currentSkyStory(
  record: unknown,
): { picks: SlotPicks | null; source: "director" | "code" } {
  const stored = isDirectorRecord(record) ? record.sky ?? null : null;
  return isPicksRecord(stored)
    ? { picks: stored.picks, source: "director" }
    : { picks: null, source: "code" };
}

// The Golden Vows words a Golden Vows memory plays now (#458): the
// director's stored picks, re-applied by id to the album code cuts from
// the memory as it is now (a gone or reworded line takes code's top
// candidate), else none. Records before #458 held a whole section: not
// read. The summaries carry the photo that made it a wedding when it ran
// (a photo's summary is only known then).
export function currentGoldenVows(
  record: unknown,
): {
  picks: SlotPicks | null;
  source: "director" | "code";
  summaries: Map<string, string>;
} {
  const stored = isDirectorRecord(record) ? record.golden_vows ?? null : null;
  const trigger = isDirectorRecord(record) ? record.gv_trigger : null;
  const summaries = new Map(
    trigger?.source === "photo" ? [[trigger.id, trigger.word]] : [],
  );
  return isPicksRecord(stored)
    ? { picks: stored.picks, source: "director", summaries }
    : { picks: null, source: "code", summaries };
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

// [iso] as 'HH:MM' on the clock of [item]'s place (#461: its resolved
// offset), else the app's (TripData.utc_offset_minutes, #363); or null.
export function localClock(
  iso: string | null,
  tripData: TripData,
  item?: { utc_offset_minutes?: number | null },
): string | null {
  if (!iso) return null;
  const ms = Date.parse(iso);
  if (Number.isNaN(ms)) return null;
  const local = new Date(localMs(tripData, item ?? {}, iso));
  const two = (v: number) => String(v).padStart(2, "0");
  return `${two(local.getUTCHours())}:${two(local.getUTCMinutes())}`;
}
