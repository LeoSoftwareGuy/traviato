// Request handling for generate_wrap_up (#93), separated from index.ts's
// Deno.serve bootstrap so it can be exercised in tests without starting a
// server. Auth guard + ownership check per docs/supabase.md.
//
// Draft vs frozen (#187): a published wrap-up is returned untouched. A draft
// is rebuilt from current data on every call, and Anthropic is only called
// when the AI's inputs (ai_input_hash.ts) changed — at most
// MAX_AI_GENERATIONS times per memory, after which the last AI text is
// reused.
//
// Rebuild (#294): `rebuild: true` on a kept wrap-up re-assembles its film
// from the current photos and picks, keeping its stored AI lines (no AI
// call — the lines are written from notes, never photos) and its
// published_at. It's the user's explicit "Photos changed · Rebuild film";
// nothing else ever rewrites a kept film.
//
// Director (#328): when WRAP_UP_DIRECTOR_USER_IDS enables it for the caller,
// a draft's first build also runs the director (director.ts) and stores the
// run in wrap_ups.director; a still-valid plan is merged into the draft's
// content as `plan_version: 2` + `plan`. `director: "rerun"` runs it again
// (the dev Plan inspector). On a kept film a rerun writes only
// wrap_ups.director — a kept film's content is never touched by it.
//
// Sky Story (#345): every draft with photos gets `content.sky`, the film's
// pages — the director's when its sky_story still fits the memory, else
// built by code. The director is on for everyone unless switched off
// (director_flag.ts), and runs again on its own when the memory's photo
// days change (capped, director.ts).
//
// Golden Vows (#346): a draft also gets `content.golden_vows` when the
// director's section (a wedding, engagement, anniversary or date night)
// still fits the memory. The app plays it before Sky Story.
//
// Neon Night (#363): likewise `content.neon_night` for a party or a night
// out, from the director's section while it still fits. The app plays it
// after Golden Vows and before Sky Story. The app sends its UTC offset
// (`utc_offset_minutes`) so the director sees local photo times.

import { gatherTripData, type TripData } from "./gather.ts";
import { wrapUpMissing } from "./wrap_up_limits.ts";
import { type PlayedTemplate, playedTemplate } from "./film_template.ts";
import { withFilmPhotos } from "./film_photos.ts";
import {
  assembleWrapUpContent,
  type MomentSlots,
  parseMomentSlots,
} from "./assemble.ts";
import {
  type AiGeneratedFields,
  validateAiGeneratedFields,
} from "./ai_fields.ts";
import { computeAiInputHash } from "./ai_input_hash.ts";
import { parseWrapUpLanguage, type WrapUpLanguage } from "./language.ts";
import { logEvent, type LogLike, WrapUpGenerationError } from "./anthropic.ts";
import {
  currentGoldenVows,
  currentNeonNight,
  currentPlan,
  currentSkyStory,
  directorIsStale,
  type DirectorRecord,
  isDirectorRecord,
} from "./director.ts";
import { alwaysWithoutPage, buildSkyContent } from "./sky_story.ts";
import { buildGoldenVowsContent } from "./golden_vows.ts";
import { buildNeonNightContent } from "./neon_night.ts";

// deno-lint-ignore no-explicit-any
type SupabaseClient = any;

// 1 initial generation + 3 regenerations, same for free and Pro (#187).
export const MAX_AI_GENERATIONS = 4;

export interface Deps {
  serviceClient: SupabaseClient;
  authClient: (authHeader: string) => SupabaseClient;
  generateAiFields: (
    tripData: TripData,
    language: WrapUpLanguage,
  ) => Promise<AiGeneratedFields>;
  // Defaults to `console.error` — see anthropic.ts's `[generate_wrap_up]`
  // log lines (#166).
  log?: LogLike;
  // The film's minimum photos and notes (#432). Defaults to the shared
  // WRAP_UP_LIMITS; tests of the film-building paths pass NO_MINIMUMS.
  minimums?: { photos: number; notes: number };
  // The director (#328). Absent = off.
  director?: {
    isEnabledFor: (userId: string) => boolean;
    run: (
      tripId: string,
      tripData: TripData,
      language: WrapUpLanguage,
    ) => Promise<DirectorRecord>;
  };
}

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

export async function handleRequest(
  req: Request,
  deps: Deps,
): Promise<Response> {
  if (req.method !== "POST") {
    return json({ error: "method not allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return json({ error: "missing authorization" }, 401);
  }

  const body = await req.json().catch(() => ({}));
  const tripId = (body as Record<string, unknown>).trip_id;
  if (typeof tripId !== "string" || tripId.length === 0) {
    return json({ error: "trip_id is required" }, 400);
  }
  // The app's UI language (#250); older app versions send none → English.
  const language = parseWrapUpLanguage(
    (body as Record<string, unknown>).language,
  );
  const rebuild = (body as Record<string, unknown>).rebuild === true;
  // App builds that play 16 moments say so (#304); older ones get 8.
  const slots = parseMomentSlots(
    (body as Record<string, unknown>).moment_slots,
  );
  // The app's clock (#363); older app versions send none → UTC.
  const utcOffset = parseUtcOffset(
    (body as Record<string, unknown>).utc_offset_minutes,
  );
  // The dev Plan inspector's "Re-run director" (#328).
  const directorRerun = (body as Record<string, unknown>).director === "rerun";

  const { data: userData, error: userError } = await deps.authClient(authHeader)
    .auth.getUser();
  if (userError || !userData?.user) {
    return json({ error: "invalid session" }, 401);
  }

  const { data: trip, error: tripError } = await deps.serviceClient
    .from("trips")
    .select("id, user_id")
    .eq("id", tripId)
    .maybeSingle();
  if (tripError) {
    return json({ error: `trip lookup failed: ${tripError.message}` }, 500);
  }
  if (!trip) {
    return json({ error: "trip not found" }, 404);
  }
  if (trip.user_id !== userData.user.id) {
    return json({ error: "forbidden" }, 403);
  }
  const directorOn = deps.director?.isEnabledFor(userData.user.id) ?? false;
  if (directorRerun && !directorOn) {
    return json({
      error: "the director is not enabled for this account",
      code: "director_disabled",
    }, 403);
  }

  const { data: existing, error: existingError } = await deps.serviceClient
    .from("wrap_ups")
    .select(
      "content, generated_at, published_at, ai_fields, ai_input_hash, ai_generation_count, director",
    )
    .eq("trip_id", tripId)
    .maybeSingle();
  if (existingError) {
    return json(
      { error: `wrap-up lookup failed: ${existingError.message}` },
      500,
    );
  }
  // Kept forever → frozen: never regenerated (#187), only rebuilt on the
  // user's explicit request (#294).
  if (existing?.published_at && existing.content) {
    if (directorRerun) {
      return await rerunKeptDirector(
        deps,
        tripId,
        language,
        utcOffset,
        existing,
      );
    }
    if (rebuild && validateAiGeneratedFields(existing.ai_fields)) {
      return await rebuildKept(
        deps,
        tripId,
        existing.ai_fields,
        slots,
        existing,
        language,
      );
    }
    return json({
      content: existing.content,
      generated_at: existing.generated_at,
    }, 200);
  }

  // Everything below is a draft (or a first generation): the film is always
  // rebuilt from current data, so photo edits never leave it stale.
  let tripData: TripData;
  try {
    tripData = await gatherTripData(deps.serviceClient, tripId);
  } catch (err) {
    return json({
      error: `failed to gather trip data: ${(err as Error).message}`,
    }, 500);
  }
  if (utcOffset !== undefined) tripData.utc_offset_minutes = utcOffset;

  // Below the minimum (#432) there's no film to make — the Journal shows
  // what's missing instead. Checked before any AI call; kept films above
  // are never affected.
  const missing = wrapUpMissing(
    tripData.photos.length,
    tripData.notes.length,
    deps.minimums,
  );
  if (missing) {
    return json({
      error: "this memory doesn't have enough for a film yet",
      code: "not_eligible",
      missing,
    }, 422);
  }

  const inputHash = await computeAiInputHash(tripData, language);
  const storedFields = validateAiGeneratedFields(existing?.ai_fields)
    ? existing!.ai_fields as AiGeneratedFields
    : null;
  const generationCount: number = existing?.ai_generation_count ?? 0;
  const storedHash: string | null = existing?.ai_input_hash ?? null;

  let aiFields: AiGeneratedFields;
  let newCount = generationCount;
  // Whether [aiFields] were written from the current inputs — decides which
  // hash is saved. A failed regeneration (or the cap) keeps the old hash so
  // the row never claims text is fresher than it is.
  let fieldsMatchInputs = true;
  if (
    storedFields &&
    (storedHash === null || storedHash === inputHash ||
      generationCount >= MAX_AI_GENERATIONS)
  ) {
    // Unchanged inputs, a backfilled row adopting its hash, or the cap
    // reached — reuse the last AI-written text, no Anthropic call.
    aiFields = storedFields;
    fieldsMatchInputs = storedHash === null || storedHash === inputHash;
  } else if (storedFields) {
    // A regeneration. Counted whether or not it succeeds — every call costs
    // — and a failure falls back to the last text rather than breaking.
    newCount = generationCount + 1;
    try {
      aiFields = await deps.generateAiFields(tripData, language);
    } catch (err) {
      logGenerationFailure(deps, tripId, err, "regeneration_failed");
      aiFields = storedFields;
      fieldsMatchInputs = false;
    }
  } else {
    // First generation: only counted on success, so a failed first attempt
    // can't burn the cap before the user ever has a wrap-up.
    try {
      aiFields = await deps.generateAiFields(tripData, language);
    } catch (err) {
      // `error` keeps its old shape (the Dart client reads it as the
      // message); `code` + `detail` say which of the three upstream
      // failures this was (#166) — all 502, distinct from 401/403/404/500.
      const { code, detail } = logGenerationFailure(
        deps,
        tripId,
        err,
        "generation_failed",
      );
      return json({
        error: `wrap-up generation failed: ${detail}`,
        code,
        detail,
      }, 502);
    }
    newCount = generationCount + 1;
  }

  // The director runs once per memory on its own, again when its photo days
  // changed (capped), and on a rerun.
  let director: unknown = existing?.director ?? null;
  let directorRan = false;
  if (
    directorOn &&
    (directorRerun || !isDirectorRecord(director) ||
      directorIsStale(director, tripData))
  ) {
    director = await runCounted(deps, tripId, tripData, language, director);
    directorRan = true;
  }

  const template = assembleWrapUpContent(tripData, aiFields, slots);
  // The film this memory plays, from its vibes (#433) — never changed by
  // the director — and the film's photos (at most 60).
  const played = playedTemplate(tripData.trip.vibes);
  const heroScores = isDirectorRecord(director)
    ? director.hero_scores ?? {}
    : {};
  const film = withFilmPhotos(tripData, heroScores);
  const isSkyMemory = played === "sky_story";
  // Next to everything the current player reads, so it keeps playing.
  const plan = directorOn && isSkyMemory
    ? currentPlan(director, film, language)
    : null;
  // Every memory with photos gets Sky Story pages: a Sky Story memory's
  // film, and the app's safety net if another film fails while it plays.
  const sky = buildSkyContent(
    film,
    directorOn && isSkyMemory ? currentSkyStory(director, film) : null,
    heroScores,
  );
  if (sky) {
    // More Always picks than Sky Story's pages hold: they're in the
    // mosaic instead (#378's known limit).
    const withoutPage = alwaysWithoutPage(film, sky);
    if (withoutPage.length > 0) {
      logEvent(deps.log ?? console.error, "sky_always_without_page", {
        trip_id: tripId,
        count: withoutPage.length,
      });
    }
  }
  // The chosen film always plays (#433): the director's section, repaired,
  // else code's plan for the same film — also with the director off.
  const section = sectionContentFor(
    played,
    directorOn ? director : null,
    film,
    language,
  );
  const content = {
    ...template,
    film_style: played,
    ...(plan ? { plan_version: 2 as const, plan } : {}),
    ...(sky ? { sky } : {}),
    ...section.content,
    ...(section.report ? { film_report: section.report } : {}),
  };
  const generatedAt = new Date().toISOString();
  const row = {
    content,
    generated_at: generatedAt,
    ai_fields: aiFields,
    // After a failed regeneration the old hash stays, so the next open
    // retries — counted again, so still bounded by the cap.
    ai_input_hash: fieldsMatchInputs ? inputHash : storedHash,
    ai_generation_count: newCount,
    ...(directorRan ? { director } : {}),
  };

  // Never delete-and-recreate (that would reset the counter), and never
  // write over a wrap-up that was kept forever while this request ran.
  const { error: saveError } = existing
    ? await deps.serviceClient
      .from("wrap_ups")
      .update(row)
      .eq("trip_id", tripId)
      .is("published_at", null)
    : await deps.serviceClient
      .from("wrap_ups")
      .insert({ trip_id: tripId, ...row });
  if (saveError) {
    return json(
      { error: `failed to save wrap-up: ${saveError.message}` },
      500,
    );
  }

  return json({
    content,
    generated_at: generatedAt,
    ...(directorRan ? { director } : {}),
  }, 200);
}

// Runs the director again for a kept film (#328): only wrap_ups.director is
// written, the kept content stays exactly as it was.
async function rerunKeptDirector(
  deps: Deps,
  tripId: string,
  language: WrapUpLanguage,
  utcOffset: number | undefined,
  existing: {
    content: unknown;
    generated_at: string | null;
    director?: unknown;
  },
): Promise<Response> {
  let tripData: TripData;
  try {
    tripData = await gatherTripData(deps.serviceClient, tripId);
  } catch (err) {
    return json({
      error: `failed to gather trip data: ${(err as Error).message}`,
    }, 500);
  }
  if (utcOffset !== undefined) tripData.utc_offset_minutes = utcOffset;
  const director = await runCounted(
    deps,
    tripId,
    tripData,
    language,
    existing.director,
  );
  const { error } = await deps.serviceClient
    .from("wrap_ups")
    .update({ director })
    .eq("trip_id", tripId)
    .not("published_at", "is", null);
  if (error) {
    return json({ error: `failed to save wrap-up: ${error.message}` }, 500);
  }
  return json({
    content: existing.content,
    generated_at: existing.generated_at,
    director,
  }, 200);
}

// Re-assembles a kept film with its stored AI lines (#294). Only ever
// writes over a row that is still kept. A film kept as a Sky Story (#345)
// rebuilds its pages too — the director's stored pages while they still
// fit, else code-built; no AI call — so it stays a Sky Story. A film kept
// before Sky Story never gains one. A film kept as Golden Vows (#346)
// rebuilds from the director's stored section while it still fits; once
// it doesn't, the film plays its Sky Story. No kept film gains Golden Vows.
// Neon Night (#363) follows the same rules.
async function rebuildKept(
  deps: Deps,
  tripId: string,
  aiFields: AiGeneratedFields,
  slots: MomentSlots,
  existing: { content: unknown; director?: unknown },
  language: WrapUpLanguage,
): Promise<Response> {
  let tripData: TripData;
  try {
    tripData = await gatherTripData(deps.serviceClient, tripId);
  } catch (err) {
    return json({
      error: `failed to gather trip data: ${(err as Error).message}`,
    }, 500);
  }
  const template = assembleWrapUpContent(tripData, aiFields, slots);
  const heroScores = isDirectorRecord(existing.director)
    ? existing.director.hero_scores ?? {}
    : {};
  const film = withFilmPhotos(tripData, heroScores);
  const kept = typeof existing.content === "object" && existing.content !== null
    ? existing.content as Record<string, unknown>
    : {};
  const keptAsSky = "sky" in kept;
  const sky = keptAsSky
    ? buildSkyContent(
      film,
      currentSkyStory(existing.director, film),
      heroScores,
    )
    : null;
  // A kept film keeps its film (#433: never another one — a section that
  // no longer fits is healed, else code builds the same film). No kept
  // film gains Golden Vows or Neon Night.
  const keptAs: PlayedTemplate | null = !keptAsSky
    ? null
    : "golden_vows" in kept
    ? "golden_vows"
    : "neon_night" in kept
    ? "neon_night"
    : null;
  const section = keptAs
    ? sectionContentFor(keptAs, existing.director, film, language)
    : { content: {}, report: null };
  const content = {
    ...template,
    ...("film_style" in kept ? { film_style: kept.film_style } : {}),
    ...(sky ? { sky } : {}),
    ...section.content,
    ...(section.report ? { film_report: section.report } : {}),
  };
  const generatedAt = new Date().toISOString();
  const { error } = await deps.serviceClient
    .from("wrap_ups")
    .update({ content, generated_at: generatedAt })
    .eq("trip_id", tripId)
    .not("published_at", "is", null);
  if (error) {
    return json({ error: `failed to save wrap-up: ${error.message}` }, 500);
  }
  return json({ content, generated_at: generatedAt }, 200);
}

// The chosen film's section content (#433): Golden Vows or Neon Night,
// from the director's section (as stored, healed or repaired) or code's
// plan — never missing. A Sky Story memory has none (its pages are
// content.sky). The report says where it came from, for the inspector.
function sectionContentFor(
  played: PlayedTemplate,
  director: unknown,
  film: TripData,
  language: WrapUpLanguage,
): {
  content: Record<string, unknown>;
  report: { source: "director" | "code"; repairs: string[] } | null;
} {
  if (played === "golden_vows") {
    const ensured = currentGoldenVows(director, film, language);
    return {
      content: {
        golden_vows: buildGoldenVowsContent(
          film,
          ensured.plan,
          isDirectorRecord(director) ? director.orientations ?? {} : {},
        ),
      },
      report: { source: ensured.source, repairs: ensured.repairs },
    };
  }
  if (played === "neon_night") {
    const ensured = currentNeonNight(director, film, language);
    return {
      content: { neon_night: buildNeonNightContent(film, ensured.plan) },
      report: { source: ensured.source, repairs: ensured.repairs },
    };
  }
  return { content: {}, report: null };
}

// The app's offset from UTC in minutes, when it is a whole number within
// ±14 h; anything else → undefined (UTC).
export function parseUtcOffset(value: unknown): number | undefined {
  return typeof value === "number" && Number.isInteger(value) &&
      Math.abs(value) <= 14 * 60
    ? value
    : undefined;
}

// Runs the director and counts the run against [previous]'s, so automatic
// re-runs stay capped (director.ts, MAX_DIRECTOR_RUNS).
async function runCounted(
  deps: Deps,
  tripId: string,
  tripData: TripData,
  language: WrapUpLanguage,
  previous: unknown,
): Promise<DirectorRecord> {
  const runs = isDirectorRecord(previous) ? previous.run_count ?? 1 : 0;
  const record = await deps.director!.run(tripId, tripData, language);
  return { ...record, run_count: runs + 1 };
}

function logGenerationFailure(
  deps: Deps,
  tripId: string,
  err: unknown,
  event: string,
): { code: string; detail: string } {
  const code = err instanceof WrapUpGenerationError
    ? err.code
    : "ai_output_invalid";
  const detail = (err as Error).message;
  logEvent(deps.log ?? console.error, event, {
    trip_id: tripId,
    code,
    detail,
  });
  return { code, detail };
}
