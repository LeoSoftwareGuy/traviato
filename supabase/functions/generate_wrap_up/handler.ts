// Request handling for generate_wrap_up (#93), separated from index.ts's
// Deno.serve bootstrap so it can be exercised in tests without starting a
// server. Auth guard + ownership check per docs/supabase.md.
//
// Draft vs frozen (#187): a published wrap-up is returned untouched. A draft
// is rebuilt from current data on every call. The classic film's four
// lines come from the notes (code_lines.ts, #463: no AI call); a kept
// film keeps the lines it was kept with.
//
// Rebuild (#294): `rebuild: true` on a kept wrap-up re-assembles its film
// from the current photos and picks, keeping its stored lines (no AI
// call) and its published_at. It's the user's explicit "Photos changed ·
// Rebuild film"; nothing else ever rewrites a kept film.
//
// Director (#328): when WRAP_UP_DIRECTOR_USER_IDS enables it for the caller,
// a draft's first build also runs the director (director.ts) and stores the
// run in wrap_ups.director. `director: "rerun"` runs it again (the dev
// Plan inspector). On a kept film a rerun writes only wrap_ups.director —
// a kept film's content is never touched by it.
//
// Sky Story (#345, #463): every draft with photos gets `content.sky`, the
// film's pages cut by code, with the director's stored picks for a Sky
// Story memory's words. The director is on for everyone unless switched
// off (director_flag.ts), and runs again on its own when the memory's
// photo days change (capped, director.ts).
//
// Golden Vows (#346): a draft also gets `content.golden_vows` when the
// director's section (a wedding, engagement, anniversary or date night)
// still fits the memory. The app plays it before Sky Story.
//
// Neon Night (#363): likewise `content.neon_night` for a party or a night
// out, from the director's section while it still fits. The app plays it
// after Golden Vows and before Sky Story. The app sends its UTC offset
// (`utc_offset_minutes`) so the director sees local photo times.

import { filmSecondsOf } from "./film_length.ts";
import { loadCachedAnalysis } from "./photo_analysis.ts";
import { gatherTripData, type TripData } from "./gather.ts";
import { localTimesOf, withLocalTimes } from "./time_zones.ts";
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
import { codeAiFields } from "./code_lines.ts";
import { parseWrapUpLanguage, type WrapUpLanguage } from "./language.ts";
import { logEvent, type LogLike } from "./anthropic.ts";
import {
  currentGoldenVows,
  currentNeonNight,
  currentSkyStory,
  directorIsStale,
  type DirectorRecord,
  isDirectorRecord,
} from "./director.ts";
import { alwaysWithoutPage } from "./sky_story.ts";
import { type SkyFilm, skyStoryFilm } from "./sky_film.ts";
import { type GoldenVowsFilm, goldenVowsFilm } from "./gv_film.ts";
import { neonNightFilm } from "./neon_film.ts";

// deno-lint-ignore no-explicit-any
type SupabaseClient = any;

export interface Deps {
  serviceClient: SupabaseClient;
  authClient: (authHeader: string) => SupabaseClient;
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
      "content, generated_at, published_at, ai_fields, director",
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
    if (rebuild) {
      return await rebuildKept(
        deps,
        tripId,
        validateAiGeneratedFields(existing.ai_fields)
          ? existing.ai_fields
          : null,
        slots,
        existing,
        language,
        utcOffset,
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
    tripData = await gatherLocal(deps, tripId, utcOffset);
  } catch (err) {
    return json({
      error: `failed to gather trip data: ${(err as Error).message}`,
    }, 500);
  }

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

  // The classic film's lines, from the notes (#463).
  const aiFields = codeAiFields(tripData);

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
  // Every memory with photos gets Sky Story pages: a Sky Story memory's
  // film (with the director's picks), and the app's safety net if another
  // film fails while it plays (code's words).
  const skyPicks = directorOn && isSkyMemory
    ? currentSkyStory(director)
    : { picks: null, source: "code" as const };
  const skyFilm = skyStoryFilm(film, skyPicks.picks, { heroScores, language });
  const sky = skyFilm.content;
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
  const section = isSkyMemory
    ? { content: {}, report: skyReport(skyFilm, skyPicks.source) }
    : sectionContentFor(played, directorOn ? director : null, film, language);
  const content = {
    ...template,
    film_style: played,
    // How long the film plays (#434): the app fits its scenes to it.
    film_seconds: filmSecondsOf(film),
    // Each photo's and note's place clock (#461).
    local_times: localTimesOf(tripData),
    ...(sky ? { sky } : {}),
    ...section.content,
    ...(section.report ? { film_report: section.report } : {}),
  };
  const generatedAt = new Date().toISOString();
  const row = {
    content,
    generated_at: generatedAt,
    // The lines a film kept from this draft keeps.
    ai_fields: aiFields,
    ...(directorRan ? { director } : {}),
  };

  // Never delete-and-recreate, and never write over a wrap-up that was kept forever while this request ran.
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
    tripData = await gatherLocal(deps, tripId, utcOffset);
  } catch (err) {
    return json({
      error: `failed to gather trip data: ${(err as Error).message}`,
    }, 500);
  }
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

// Re-assembles a kept film with its stored lines (#294; none stored: the
// notes' lines, #463). Only ever
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
  storedFields: AiGeneratedFields | null,
  slots: MomentSlots,
  existing: { content: unknown; director?: unknown },
  language: WrapUpLanguage,
  utcOffset: number | undefined,
): Promise<Response> {
  let tripData: TripData;
  try {
    tripData = await gatherLocal(deps, tripId, utcOffset);
  } catch (err) {
    return json({
      error: `failed to gather trip data: ${(err as Error).message}`,
    }, 500);
  }
  const aiFields = storedFields ?? codeAiFields(tripData);
  const template = assembleWrapUpContent(tripData, aiFields, slots);
  const heroScores = isDirectorRecord(existing.director)
    ? existing.director.hero_scores ?? {}
    : {};
  const film = withFilmPhotos(tripData, heroScores);
  const kept = typeof existing.content === "object" && existing.content !== null
    ? existing.content as Record<string, unknown>
    : {};
  const keptAsSky = "sky" in kept;
  const keptPicks = currentSkyStory(existing.director);
  const skyFilm = keptAsSky
    ? skyStoryFilm(film, keptPicks.picks, { heroScores, language })
    : null;
  const sky = skyFilm?.content ?? null;
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
    : skyFilm
    ? { content: {}, report: skyReport(skyFilm, keptPicks.source) }
    : { content: {}, report: null };
  const content = {
    ...template,
    ...("film_style" in kept ? { film_style: kept.film_style } : {}),
    // Rebuilt on the user's tap: its length follows its photos now (#434).
    film_seconds: filmSecondsOf(film),
    // And its times follow each photo's place (#461).
    local_times: localTimesOf(tripData),
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

// Sky Story's report for the inspector (#463): every slot, what the film
// gave up for its length, its photos on pages and the notes on no page.
function skyReport(sky: SkyFilm, source: "director" | "code") {
  return {
    source,
    repairs: sky.report.filter((r) => r.pick && r.source === "code")
      .map((r) => `${r.slot}: ${r.reason}`),
    slots: sky.report,
    trims: sky.trims,
    shown: sky.shown,
    unlisted: sky.unlisted,
    seconds: sky.seconds,
    limit_seconds: sky.limit_seconds,
  };
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
  report: {
    source: "director" | "code";
    repairs: string[];
    // Neon Night (#454), Golden Vows (#458): every slot, its candidates
    // and what plays.
    slots?:
      | ReturnType<typeof neonNightFilm>["report"]
      | GoldenVowsFilm["report"];
    // Golden Vows (#458): what it gave up for its length, its photos on
    // pages, notes on no page, the word that made it a wedding.
    trims?: string[];
    shown?: GoldenVowsFilm["shown"];
    unlisted?: GoldenVowsFilm["unlisted"];
    trigger?: GoldenVowsFilm["trigger"];
  } | null;
} {
  if (played === "golden_vows") {
    // Code cuts the album; the director's stored picks choose its words
    // (#458).
    const current = currentGoldenVows(director);
    const record = isDirectorRecord(director) ? director : null;
    const gv = goldenVowsFilm(film, current.picks, {
      heroScores: record?.hero_scores ?? {},
      orientations: record?.orientations ?? {},
      summaries: current.summaries,
      language,
    });
    return {
      content: { golden_vows: gv.content },
      report: {
        source: current.source,
        repairs: gv.report.filter((r) => r.pick && r.source === "code")
          .map((r) => `${r.slot}: ${r.reason}`),
        slots: gv.report,
        trims: gv.trims,
        shown: gv.shown,
        unlisted: gv.unlisted,
        trigger: gv.trigger,
      },
    };
  }
  if (played === "neon_night") {
    const current = currentNeonNight(director);
    const neon = neonNightFilm(
      film,
      current.picks,
      isDirectorRecord(director) ? director.hero_scores ?? {} : {},
    );
    return {
      content: { neon_night: neon.content },
      report: {
        source: current.source,
        repairs: neon.report.filter((r) => r.pick && r.source === "code")
          .map((r) => `${r.slot}: ${r.reason}`),
        slots: neon.report,
      },
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

// Each photo's cached analysis summary (#468: a backfilled note goes to
// the photos that show what it says), for the file it was made from. A
// failed read only costs that matching.
async function attachSummaries(
  deps: Deps,
  tripId: string,
  tripData: TripData,
): Promise<void> {
  try {
    const cached = await loadCachedAnalysis(deps.serviceClient, tripId);
    for (const p of tripData.photos) {
      const a = cached.get(p.id);
      if (a && a.storage_path === p.storage_path) p.summary = a.summary;
    }
  } catch (err) {
    console.warn(`photo summaries not read: ${(err as Error).message}`);
  }
}

// The memory's data with every photo and note on its own place's clock
// (#461). A zone found for the first time is kept on the trip, so later
// opens don't depend on what the lookup finds then; a failed write only
// costs that.
async function gatherLocal(
  deps: Deps,
  tripId: string,
  utcOffset: number | undefined,
): Promise<TripData> {
  const gathered = await gatherTripData(deps.serviceClient, tripId);
  if (utcOffset !== undefined) gathered.utc_offset_minutes = utcOffset;
  await attachSummaries(deps, tripId, gathered);
  const tripData = withLocalTimes(gathered);
  const zone = tripData.zone;
  if (zone?.zone && zone.source !== "stored") {
    try {
      const { error } = await deps.serviceClient.from("trips")
        .update({ time_zone: zone.zone }).eq("id", tripId);
      if (error) console.warn(`trip zone not saved: ${error.message}`);
    } catch (err) {
      console.warn(`trip zone not saved: ${(err as Error).message}`);
    }
  }
  return tripData;
}
