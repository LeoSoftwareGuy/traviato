// Director call 1 (#328): what is visible in each photo, cached per photo in
// public.photo_analysis so a rebuild only analyses new or changed photos.
//
// Photos are downscaled to ~512px before they're sent (Storage image
// transforms). Where transforms aren't available (hosted projects without
// them) the stored JPEG is sent as-is — Anthropic resizes it, at a higher
// token cost.
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

export interface EncodedImage {
  mediaType: string;
  base64: string;
}

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

export function encodeBase64(bytes: Uint8Array): string {
  let binary = "";
  const chunk = 0x8000;
  for (let i = 0; i < bytes.length; i += chunk) {
    binary += String.fromCharCode(...bytes.subarray(i, i + chunk));
  }
  return btoa(binary);
}

// A ~512px JPEG of the photo: Storage's image transform, or the stored file
// when transforms aren't available.
export async function fetchPhotoImage(
  client: SupabaseClient,
  storagePath: string,
  fetchImpl: FetchLike = fetch,
): Promise<EncodedImage> {
  const bucket = client.storage.from(PHOTO_BUCKET);
  const { data: signed } = await bucket.createSignedUrl(
    storagePath,
    SIGNED_URL_SECONDS,
    {
      transform: {
        width: IMAGE_SIZE,
        height: IMAGE_SIZE,
        resize: "contain",
        quality: 70,
      },
    },
  );
  if (signed?.signedUrl) {
    try {
      const response = await fetchImpl(signed.signedUrl);
      if (response.ok) {
        const type = response.headers.get("content-type") ?? "image/jpeg";
        const bytes = new Uint8Array(await response.arrayBuffer());
        if (bytes.length > 0 && type.startsWith("image/")) {
          return { mediaType: type.split(";")[0], base64: encodeBase64(bytes) };
        }
      }
    } catch {
      // Fall through to the stored file.
    }
  }
  const { data: blob, error } = await bucket.download(storagePath);
  if (error || !blob) {
    throw new Error(`photo download failed: ${error?.message ?? "no data"}`);
  }
  const bytes = new Uint8Array(await blob.arrayBuffer());
  return { mediaType: blob.type || "image/jpeg", base64: encodeBase64(bytes) };
}

export interface AnalysisDeps {
  client: SupabaseClient;
  apiKey: string;
  model: string;
  fetchImpl?: FetchLike;
  log?: LogLike;
  // Overridable in tests.
  loadImage?: (storagePath: string) => Promise<EncodedImage>;
}

export interface AnalysisRun {
  analysed: PhotoAnalysis[];
  usage: TokenUsage[];
  // Photos that couldn't be analysed (download or model failure) — left
  // out of the plan rather than failing the film.
  failedIds: string[];
}

async function analyseBatch(
  deps: AnalysisDeps,
  batch: Photo[],
  batchIndex: number,
): Promise<AnalysisRun> {
  const usage: TokenUsage[] = [];
  const content: unknown[] = [];
  const sent: string[] = [];
  const failedIds: string[] = [];
  const loadImage = deps.loadImage ??
    ((path: string) => fetchPhotoImage(deps.client, path, deps.fetchImpl));
  const images = await Promise.allSettled(
    batch.map((p) => loadImage(p.storage_path)),
  );
  images.forEach((result, i) => {
    const photo = batch[i];
    if (result.status === "rejected") {
      failedIds.push(photo.id);
      return;
    }
    content.push({ type: "text", text: `Photo id: ${photo.id}` });
    content.push({
      type: "image",
      source: {
        type: "base64",
        media_type: result.value.mediaType,
        data: result.value.base64,
      },
    });
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
  // Batch tags are unique per run, so dup groups never collide with a
  // cached row's tag from an earlier run.
  const stamp = Date.now().toString(36);
  for (let i = 0; i < batches.length; i += ANALYSIS_CONCURRENCY) {
    const results = await Promise.all(
      batches.slice(i, i + ANALYSIS_CONCURRENCY).map((batch, j) =>
        analyseBatch(deps, batch, i + j).then((r) => ({
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
