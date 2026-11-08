import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  analysePhotos,
  imageTransformsWork,
  MAX_ANALYSED_PHOTOS,
  parsePhotoAnalysis,
  type PhotoAnalysisRow,
  photosNeedingAnalysis,
  plannablePhotos,
  storageImageUrlSigner,
} from "./photo_analysis.ts";
import {
  analysisFor,
  directorTripData,
  toolResponse,
} from "./director_fixtures.ts";
import { parseDirectorFlag } from "./director_flag.ts";

Deno.test("parsePhotoAnalysis keeps valid entries, prefixes dup groups, reports the rest", () => {
  const { analyses, problems } = parsePhotoAnalysis(
    {
      photos: [
        { ...analysisFor("a"), dup_group: "x" },
        { ...analysisFor("b"), setting: "space" },
        { ...analysisFor("stranger") },
        {
          ...analysisFor("c"),
          summary:
            "one two three four five six seven eight nine ten eleven twelve thirteen",
          hero_score: 4.4,
        },
      ],
    },
    ["a", "b", "c", "d"],
    "b0-",
  );

  assertEquals(analyses.map((a) => a.photo_id), ["a", "c"]);
  assertEquals(analyses[0].dup_group, "b0-x");
  assertEquals(analyses[1].summary.split(" ").length, 12);
  assertEquals(analyses[1].hero_score, 4);
  assertEquals(problems, [
    "b: malformed entry",
    'unknown photo_id "stranger"',
    "c: summary cut to 12 words",
    "b: missing",
    "d: missing",
  ]);
});

Deno.test("parsePhotoAnalysis rejects input without a photos array", () => {
  assertEquals(parsePhotoAnalysis({}, ["a"], "").analyses, []);
});

Deno.test("plannablePhotos drops Leave out photos and keeps chronological order", () => {
  const data = directorTripData();
  data.photos[3].use_in_wrap_up = false;
  data.photos.reverse();
  const ids = plannablePhotos(data).map((p) => p.id);
  assertEquals(ids.length, 11);
  assertEquals(ids[0], "p00");
  assertEquals(ids.includes("p03"), false);
});

Deno.test("plannablePhotos caps a big memory, keeping every Always photo", () => {
  const base = directorTripData().photos[0];
  const photos = Array.from({ length: 300 }, (_, i) => ({
    ...base,
    id: `x${String(i).padStart(3, "0")}`,
    taken_at: new Date(Date.UTC(2026, 8, 1, 0, i)).toISOString(),
    use_in_wrap_up: i === 7 ? true : null,
  }));
  const picked = plannablePhotos(directorTripData({ photos }));
  assertEquals(picked.length, MAX_ANALYSED_PHOTOS);
  assertEquals(picked.some((p) => p.id === "x007"), true);
});

Deno.test("photosNeedingAnalysis skips photos cached from the same file", () => {
  const photos = directorTripData().photos.slice(0, 3);
  const cached = new Map<string, PhotoAnalysisRow>([
    ["p00", {
      ...analysisFor("p00"),
      trip_id: "t",
      storage_path: "u/t/p00.jpg",
      model: "m",
    }],
    ["p01", {
      ...analysisFor("p01"),
      trip_id: "t",
      storage_path: "u/t/old.jpg",
      model: "m",
    }],
  ]);
  assertEquals(
    photosNeedingAnalysis(photos, cached).map((p) => p.id),
    ["p01", "p02"],
  );
});

// A Storage bucket stub: createSignedUrl / createSignedUrls hand back
// predictable URLs; paths in [missing] come back unsigned.
function storageClient(missing: string[] = []) {
  const calls: { method: string; args: unknown[] }[] = [];
  const bucket = {
    createSignedUrl: (path: string, seconds: number, options?: unknown) => {
      calls.push({ method: "createSignedUrl", args: [path, seconds, options] });
      return Promise.resolve({
        data: { signedUrl: `https://render.test/${path}` },
        error: null,
      });
    },
    createSignedUrls: (paths: string[], seconds: number) => {
      calls.push({ method: "createSignedUrls", args: [paths, seconds] });
      return Promise.resolve({
        data: paths.filter((p) => !missing.includes(p)).map((p) => ({
          path: p,
          signedUrl: `https://file.test/${p}`,
          error: null,
        })),
        error: null,
      });
    },
  };
  return { calls, client: { storage: { from: () => bucket } } };
}

Deno.test("analysePhotos sends photos as URL image blocks, never base64", async () => {
  const photos = directorTripData().photos.slice(0, 3);
  const { client } = storageClient();
  const bodies: Record<string, unknown>[] = [];
  const fetchImpl = ((url: string | URL | Request, init?: RequestInit) => {
    if (String(url).startsWith("https://render.test/")) {
      // No image transforms on this project.
      return Promise.resolve(new Response("not found", { status: 400 }));
    }
    const body = JSON.parse(init!.body as string);
    bodies.push(body);
    return Promise.resolve(
      toolResponse("emit_photo_analysis", {
        photos: photos.map((p) => analysisFor(p.id)),
      }),
    );
  }) as typeof fetch;

  const run = await analysePhotos({
    client,
    apiKey: "key",
    model: "m",
    fetchImpl,
    log: () => {},
  }, photos);

  assertEquals(run.failedIds, []);
  assertEquals(run.analysed.length, 3);
  const content = (bodies[0].messages as { content: unknown[] }[])[0]
    .content as { type: string; source?: Record<string, unknown> }[];
  const images = content.filter((b) => b.type === "image");
  assertEquals(
    images.map((b) => b.source),
    photos.map((p) => ({
      type: "url",
      url: `https://file.test/${p.storage_path}`,
    })),
  );
  assertEquals(JSON.stringify(bodies[0]).includes("base64"), false);
});

Deno.test("analysePhotos uses 512px render URLs when transforms work", async () => {
  const photos = directorTripData().photos.slice(0, 2);
  const { client, calls } = storageClient();
  const bodies: Record<string, unknown>[] = [];
  const fetchImpl = ((url: string | URL | Request, init?: RequestInit) => {
    if (String(url).startsWith("https://render.test/")) {
      return Promise.resolve(
        new Response("img", { headers: { "content-type": "image/jpeg" } }),
      );
    }
    bodies.push(JSON.parse(init!.body as string));
    return Promise.resolve(
      toolResponse("emit_photo_analysis", {
        photos: photos.map((p) => analysisFor(p.id)),
      }),
    );
  }) as typeof fetch;

  await analysePhotos({ client, apiKey: "k", model: "m", fetchImpl }, photos);

  const content = (bodies[0].messages as { content: unknown[] }[])[0]
    .content as { type: string; source?: { url: string } }[];
  assertEquals(
    content.filter((b) => b.type === "image").map((b) => b.source!.url),
    photos.map((p) => `https://render.test/${p.storage_path}`),
  );
  assertEquals(calls.some((c) => c.method === "createSignedUrls"), false);
});

Deno.test("storageImageUrlSigner marks photos it couldn't sign as null", async () => {
  const { client } = storageClient(["u/t/b.jpg"]);
  const urls = await storageImageUrlSigner(client, false)([
    "u/t/a.jpg",
    "u/t/b.jpg",
  ]);
  assertEquals(urls, ["https://file.test/u/t/a.jpg", null]);
});

Deno.test("imageTransformsWork is false when the render isn't an image", async () => {
  const { client } = storageClient();
  const html = (() =>
    Promise.resolve(
      new Response("<html>", { headers: { "content-type": "text/html" } }),
    )) as typeof fetch;
  const failing = (() => Promise.reject(new Error("offline"))) as typeof fetch;
  assertEquals(await imageTransformsWork(client, "u/t/a.jpg", html), false);
  assertEquals(await imageTransformsWork(client, "u/t/a.jpg", failing), false);
});

Deno.test("parseDirectorFlag: listed ids, * for everyone, unset is off", () => {
  const some = parseDirectorFlag(" leo , other ");
  assertEquals(some("leo"), true);
  assertEquals(some("other"), true);
  assertEquals(some("stranger"), false);
  assertEquals(parseDirectorFlag("*")("anyone"), true);
  assertEquals(parseDirectorFlag(undefined)("leo"), false);
  assertEquals(parseDirectorFlag("")("leo"), false);
});
