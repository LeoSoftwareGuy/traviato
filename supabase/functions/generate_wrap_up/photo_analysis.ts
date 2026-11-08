// Director call 1 (#328): what is visible in each photo, cached per photo in
// public.photo_analysis so a rebuild only analyses new or changed photos.
//
// Photos go to Anthropic as signed Storage URLs that Anthropic fetches
// itself (#332): the function never holds image bytes, so its memory and
// CPU don't grow with the number of photos. Where Storage image transforms
// work (Pro / local) the URLs point at a ~512px render; otherwise at the
// stored file, which Anthropic resizes at a higher token cost.
//
// The model only describes what it sees. It never guesses names,
// identities, ages, ethnicity or relationships — `people` is a count.

import type { TripData } from "./gather.ts";
import { sortPhotosChronologically, spreadEvenly } from "./assemble.ts";
import {
  callAnthropicTool,
  type TokenUsage,
  type ToolDefinition,
} from "./anthropic_tool.ts";
import type { FetchLike, LogLike } from "./anthropic.ts";
import { logEvent } from "./anthropic.ts";

// deno-lint-ignore no-explicit-any
type SupabaseClient = any;

export const PHOTO_BUCKET = "trip-photos";
// Cost cap (design doc open question 4): photos analysed per memory.
export const MAX_ANALYSED_PHOTOS = 120;
export const ANALYSIS_BATCH_SIZE = 20;
const ANALYSIS_CONCURRENCY = 3;
const ANALYSIS_MAX_TOKENS = 4096;
const ANALYSIS_ATTEMPTS = 2;
const IMAGE_SIZE = 512;
const SIGNED_URL_SECONDS = 300;

export const SETTINGS = [
  "indoor",
  "outdoor",
  "night-out",
  "nature",
  "city",
  "venue",
  "home",
  "other",
] as const;
export const PEOPLE = ["0", "1", "2", "small_group", "crowd"] as const;
export const ENERGIES = ["calm", "medium", "high"] as const;
export const QUALITIES = ["sharp", "soft", "blurry", "dark"] as const;
export const ORIENTATIONS = ["portrait", "landscape", "square"] as const;

export interface PhotoAnalysis {
  photo_id: string;
  summary: string;
  setting: typeof SETTINGS[number];
  people: typeof PEOPLE[number];
  energy: typeof ENERGIES[number];
  quality: typeof QUALITIES[number];
  orientation: typeof ORIENTATIONS[number];
  hero_score: number;
  dup_group: string | null;
}

// A row of public.photo_analysis.
export interface PhotoAnalysisRow extends PhotoAnalysis {
  trip_id: string;
  storage_path: string;
  model: string;
}

type Photo = TripData["photos"][number];

// Signed URLs for [storagePaths], in order; null where signing failed.
export type ImageUrlSigner = (
  storagePaths: string[],
) => Promise<(string | null)[]>;

export const photoAnalysisToolSchema: ToolDefinition = {
  name: "emit_photo_analysis",
  description:
    "Emit what is visible in each photo, one entry per photo id, as structured JSON.",
  input_schema: {
    type: "object",
    properties: {
      photos: {
        type: "array",
        items: {
          type: "object",
          properties: {
            photo_id: { type: "string" },
            summary: {
              type: "string",
              description:
                "At most 12 words, only what is visible. No names, identities, ages, ethnicity or relationships.",
            },
            setting: { type: "string", enum: [...SETTINGS] },
            people: {
              type: "string",
              enum: [...PEOPLE],
              description: "How many people are visible.",
            },
            energy: { type: "string", enum: [...ENERGIES] },
            quality: { type: "string", enum: [...QUALITIES] },
            orientation: { type: "string", enum: [...ORIENTATIONS] },
            hero_score: {
              type: "integer",
              minimum: 1,
              maximum: 5,
              description:
                "How well the photo would carry a full-screen moment: 5 = striking, 1 = filler.",
            },
            dup_group: {
              type: ["string", "null"],
              description:
                'Near-duplicates of each other share the same short tag (e.g. "a"); null when the photo has none.',
            },
          },
          required: [
            "photo_id",
            "summary",
            "setting",
            "people",
            "energy",
            "quality",
            "orientation",
            "hero_score",
            "dup_group",
          ],
        },
      },
    },
    required: ["photos"],
  },
};

export const ANALYSIS_SYSTEM_PROMPT = [
  "You look at photos from one person's memory (a trip, a party, a wedding…) ",
  "and describe each one for a film editor. Describe only what is visible. ",
  "Never guess or state names, identities, ages, ethnicity or relationships ",
  "— count people, nothing more. Summaries are at most 12 plain words. ",
  "Give near-duplicates (same scene, moments apart) the same dup_group tag; ",
  "every other photo gets null. Return exactly one entry per photo id given.",
].join("");

function isOneOf<T extends string>(list: readonly T[], v: unknown): v is T {
  return typeof v === "string" && (list as readonly string[]).includes(v);
}

function countWords(text: string): number {
  return text.trim().split(/\s+/).filter(Boolean).length;
}

// Parses the tool input into one analysis per expected id. Entries that are
// malformed or for ids not asked about are dropped; [problems] says why.
export function parsePhotoAnalysis(
  input: unknown,
  expectedIds: string[],
  dupPrefix: string,
): { analyses: PhotoAnalysis[]; problems: string[] } {
  const problems: string[] = [];
  const list = (input as Record<string, unknown> | null)?.photos;
  if (!Array.isArray(list)) {
    return { analyses: [], problems: ["photos: expected an array"] };
  }
  const expected = new Set(expectedIds);
  const seen = new Map<string, PhotoAnalysis>();
  for (const raw of list) {
    const p = raw as Record<string, unknown>;
    const id = p?.photo_id;
    if (typeof id !== "string" || !expected.has(id)) {
      problems.push(`unknown photo_id ${JSON.stringify(id)}`);
      continue;
    }
    const heroScore = typeof p.hero_score === "number"
      ? Math.round(p.hero_score)
      : NaN;
    if (
      typeof p.summary !== "string" ||
      !isOneOf(SETTINGS, p.setting) ||
      !isOneOf(PEOPLE, p.people) ||
      !isOneOf(ENERGIES, p.energy) ||
      !isOneOf(QUALITIES, p.quality) ||
      !isOneOf(ORIENTATIONS, p.orientation) ||
      !(heroScore >= 1 && heroScore <= 5) ||
      (p.dup_group !== null && p.dup_group !== undefined &&
        typeof p.dup_group !== "string")
    ) {
      problems.push(`${id}: malformed entry`);
      continue;
    }
    const words = p.summary.trim().split(/\s+/).filter(Boolean);
    seen.set(id, {
      photo_id: id,
      // Over-long summaries are cut rather than rejected.
      summary: words.slice(0, 12).join(" ").slice(0, 200),
      setting: p.setting,
      people: p.people,
      energy: p.energy,
      quality: p.quality,
      orientation: p.orientation,
      hero_score: heroScore,
      // Tags are only meaningful within one batch.
      dup_group: typeof p.dup_group === "string" && p.dup_group.length > 0
        ? `${dupPrefix}${p.dup_group}`.slice(0, 40)
        : null,
    });
    if (countWords(p.summary) > 12) {
      problems.push(`${id}: summary cut to 12 words`);
    }
  }
  for (const id of expectedIds) {
    if (!seen.has(id)) problems.push(`${id}: missing`);
  }
  return { analyses: [...seen.values()], problems };
}

// The photos the director may plan with: every photo not left out (#294),
// capped at MAX_ANALYSED_PHOTOS — Always photos first, the rest spread
// evenly over the memory — in chronological order.
export function plannablePhotos(tripData: TripData): Photo[] {
  const sorted = sortPhotosChronologically(
    tripData.photos.filter((p) => p.use_in_wrap_up !== false),
  );
  if (sorted.length <= MAX_ANALYSED_PHOTOS) return sorted;
  const always = sorted.filter((p) => p.use_in_wrap_up === true)
    .slice(0, MAX_ANALYSED_PHOTOS);
  const rest = sorted.filter((p) => p.use_in_wrap_up !== true);
  const picked = new Set([
    ...always,
    ...spreadEvenly(rest, MAX_ANALYSED_PHOTOS - always.length),
  ]);
  return sorted.filter((p) => picked.has(p));
}

// Photos whose cached analysis is missing or was made from another file.
export function photosNeedingAnalysis(
  photos: Photo[],
  cached: ReadonlyMap<string, PhotoAnalysisRow>,
): Photo[] {
  return photos.filter((p) =>
    cached.get(p.id)?.storage_path !== p.storage_path
  );
}

export async function loadCachedAnalysis(
  client: SupabaseClient,
  tripId: string,
): Promise<Map<string, PhotoAnalysisRow>> {
  const { data, error } = await client
    .from("photo_analysis")
    .select(
      "photo_id, trip_id, storage_path, summary, setting, people, energy, quality, orientation, hero_score, dup_group, model",
    )
    .eq("trip_id", tripId);
  if (error) throw new Error(`failed to load photo_analysis: ${error.message}`);
  return new Map(
    (data ?? []).map((row: PhotoAnalysisRow) => [row.photo_id, row]),
  );
}

const TRANSFORM = {
  width: IMAGE_SIZE,
  height: IMAGE_SIZE,
  resize: "contain",
  quality: 70,
} as const;

// Whether Storage serves ~512px renders on this project: one small fetch of
// [samplePath]'s render. Off on hosted projects without image transforms.
export async function imageTransformsWork(
  client: SupabaseClient,
  samplePath: string,
  fetchImpl: FetchLike = fetch,
): Promise<boolean> {
  try {
    const { data } = await client.storage.from(PHOTO_BUCKET).createSignedUrl(
      samplePath,
      SIGNED_URL_SECONDS,
      { transform: TRANSFORM },
    );
    if (!data?.signedUrl) return false;
    const response = await fetchImpl(data.signedUrl);
    const type = response.headers.get("content-type") ?? "";
    await response.body?.cancel();
    return response.ok && type.startsWith("image/");
  } catch {
    return false;
  }
}

// Signs URLs Anthropic can fetch for a few minutes — the ~512px render
// when [useTransform], else the stored file.
export function storageImageUrlSigner(
  client: SupabaseClient,
  useTransform: boolean,
): ImageUrlSigner {
  const bucket = client.storage.from(PHOTO_BUCKET);
  if (useTransform) {
    return (paths) =>
      Promise.all(paths.map(async (path) => {
        const { data } = await bucket.createSignedUrl(
          path,
          SIGNED_URL_SECONDS,
          { transform: TRANSFORM },
        );
        return data?.signedUrl ?? null;
      }));
  }
  return async (paths) => {
    const { data, error } = await bucket.createSignedUrls(
      paths,
      SIGNED_URL_SECONDS,
    );
    if (error || !data) return paths.map(() => null);
    const byPath = new Map<string, string | null>(
      (data as { path: string | null; signedUrl: string | null }[]).map(
        (row) => [row.path ?? "", row.signedUrl ?? null],
      ),
    );
    return paths.map((path) => byPath.get(path) ?? null);
  };
}

export interface AnalysisDeps {
  client: SupabaseClient;
  apiKey: string;
  model: string;
  fetchImpl?: FetchLike;
  log?: LogLike;
  // Overridable in tests; by default Storage signed URLs, 512px renders
  // when the project supports them.
  signImageUrls?: ImageUrlSigner;
}

export interface AnalysisRun {
  analysed: PhotoAnalysis[];
  usage: TokenUsage[];
  // Photos that couldn't be analysed (signing or model failure) — left
  // out of the plan rather than failing the film.
  failedIds: string[];
}

async function analyseBatch(
  deps: AnalysisDeps,
  signImageUrls: ImageUrlSigner,
  batch: Photo[],
  batchIndex: number,
): Promise<AnalysisRun> {
  const usage: TokenUsage[] = [];
  const content: unknown[] = [];
  const sent: string[] = [];
  const failedIds: string[] = [];
  const urls = await signImageUrls(batch.map((p) => p.storage_path)).catch(
    () => batch.map(() => null),
  );
  batch.forEach((photo, i) => {
    const url = urls[i];
    if (!url) {
      failedIds.push(photo.id);
      return;
    }
    content.push({ type: "text", text: `Photo id: ${photo.id}` });
    content.push({ type: "image", source: { type: "url", url } });
    sent.push(photo.id);
  });
  if (sent.length === 0) return { analysed: [], usage, failedIds };
  content.push({
    type: "text",
    text: `Describe each of the ${sent.length} photos above.`,
  });

  for (let attempt = 1; attempt <= ANALYSIS_ATTEMPTS; attempt++) {
    try {
      const result = await callAnthropicTool({
        apiKey: deps.apiKey,
        model: deps.model,
        maxTokens: ANALYSIS_MAX_TOKENS,
        system: ANALYSIS_SYSTEM_PROMPT,
        content,
        tool: photoAnalysisToolSchema,
        label: "analysis",
        fetchImpl: deps.fetchImpl,
        log: deps.log,
      });
      usage.push(result.usage);
      const { analyses, problems } = parsePhotoAnalysis(
        result.input,
        sent,
        `b${batchIndex}-`,
      );
      // Partial answers are kept; only an empty one is retried.
      if (analyses.length > 0 || attempt === ANALYSIS_ATTEMPTS) {
        if (problems.length > 0) {
          logEvent(deps.log ?? console.error, "director_analysis_problems", {
            batch: batchIndex,
            problems: problems.slice(0, 20),
          });
        }
        const got = new Set(analyses.map((a) => a.photo_id));
        return {
          analysed: analyses,
          usage,
          failedIds: [...failedIds, ...sent.filter((id) => !got.has(id))],
        };
      }
    } catch {
      // Logged by callAnthropicTool; retried below.
    }
  }
  return { analysed: [], usage, failedIds: [...failedIds, ...sent] };
}

// Analyses [photos] in batches, a few at a time.
export async function analysePhotos(
  deps: AnalysisDeps,
  photos: Photo[],
): Promise<AnalysisRun> {
  const batches: Photo[][] = [];
  for (let i = 0; i < photos.length; i += ANALYSIS_BATCH_SIZE) {
    batches.push(photos.slice(i, i + ANALYSIS_BATCH_SIZE));
  }
  const run: AnalysisRun = { analysed: [], usage: [], failedIds: [] };
  if (photos.length === 0) return run;
  const signImageUrls = deps.signImageUrls ??
    storageImageUrlSigner(
      deps.client,
      await imageTransformsWork(
        deps.client,
        photos[0].storage_path,
        deps.fetchImpl,
      ),
    );
  // Batch tags are unique per run, so dup groups never collide with a
  // cached row's tag from an earlier run.
  const stamp = Date.now().toString(36);
  for (let i = 0; i < batches.length; i += ANALYSIS_CONCURRENCY) {
    const results = await Promise.all(
      batches.slice(i, i + ANALYSIS_CONCURRENCY).map((batch, j) =>
        analyseBatch(deps, signImageUrls, batch, i + j).then((r) => ({
          ...r,
          analysed: r.analysed.map((a) => ({
            ...a,
            dup_group: a.dup_group ? `${stamp}-${a.dup_group}` : null,
          })),
        }))
      ),
    );
    for (const r of results) {
      run.analysed.push(...r.analysed);
      run.usage.push(...r.usage);
      run.failedIds.push(...r.failedIds);
    }
  }
  return run;
}

export async function saveAnalysis(
  client: SupabaseClient,
  tripId: string,
  photos: Photo[],
  analysed: PhotoAnalysis[],
  model: string,
): Promise<void> {
  if (analysed.length === 0) return;
  const paths = new Map(photos.map((p) => [p.id, p.storage_path]));
  const rows = analysed.map((a) => ({
    ...a,
    trip_id: tripId,
    storage_path: paths.get(a.photo_id)!,
    model,
    analysed_at: new Date().toISOString(),
  }));
  const { error } = await client
    .from("photo_analysis")
    .upsert(rows, { onConflict: "photo_id" });
  if (error) throw new Error(`failed to save photo_analysis: ${error.message}`);
}
