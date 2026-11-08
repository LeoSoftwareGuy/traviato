import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  encodeBase64,
  MAX_ANALYSED_PHOTOS,
  parsePhotoAnalysis,
  type PhotoAnalysisRow,
  photosNeedingAnalysis,
  plannablePhotos,
} from "./photo_analysis.ts";
import { analysisFor, directorTripData } from "./director_fixtures.ts";
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

Deno.test("encodeBase64 matches btoa", () => {
  const bytes = new TextEncoder().encode("Storyni ✦");
  assertEquals(
    encodeBase64(bytes),
    btoa(String.fromCharCode(...bytes)),
  );
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
