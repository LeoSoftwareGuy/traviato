// Amsterdam (#433): a Nightlife memory of 28 photos and 14 notes switched
// to Sky Story twice — over a title 1 character too long and a headline 2
// too long. Through the handler and the real director, it plays Neon
// Night whatever the director sends.

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { type Deps, handleRequest } from "./handler.ts";
import type { TripData } from "./gather.ts";
import type { WrapUpLanguage } from "./language.ts";
import { runDirector } from "./director.ts";
import { analysisFor, toolResponse } from "./director_fixtures.ts";
import { fakeAuthClient, fakeSupabaseClient } from "./test_fakes.ts";
import { validAiFields } from "./test_fixtures.ts";
import { MAX_NN_HEADLINE_CHARS, MAX_NN_TITLE_CHARS } from "./neon_night.ts";

const TRIP_ID = "amsterdam";
const OWNER_ID = "user-1";
const OFFSET = 120; // Tallinn

function local(day: string, hour: number, minute = 0): string {
  return new Date(
    Date.UTC(
      Number(day.slice(0, 4)),
      Number(day.slice(5, 7)) - 1,
      Number(day.slice(8, 10)),
      hour,
      minute,
    ) - OFFSET * 60_000,
  ).toISOString();
}

// Night one 21:00–04:00 (after midnight is still day one), a day of
// sights, night two 22:00–03:00: 28 photos, 14 notes.
function tables() {
  const photos: Record<string, unknown>[] = [];
  const add = (day: string, hour: number, minute: number) => {
    const id = `p${String(photos.length).padStart(2, "0")}`;
    photos.push({
      id,
      trip_id: TRIP_ID,
      day_date: day,
      taken_at: local(day, hour, minute),
      created_at: local(day, hour, minute),
      storage_path: `u/a/${id}.jpg`,
      caption: null,
      use_in_wrap_up: photos.length % 9 === 0 ? true : null,
      place_text: hour >= 23 || hour < 5 ? "Shelter" : null,
      people_tags: [],
    });
  };
  for (let k = 0; k < 10; k++) {
    add(k < 6 ? "2026-09-04" : "2026-09-05", (21 + k) % 24, 10);
  }
  for (let k = 0; k < 8; k++) add("2026-09-05", 12 + k, 30);
  for (let k = 0; k < 10; k++) {
    add(k < 2 ? "2026-09-05" : "2026-09-06", (22 + k) % 24, 5);
  }
  const lines = [
    "The bass at Shelter shook my chest, I felt so alive.",
    "Danced until 4am, first time since 2019!",
    "It was fun.",
    "Все устали.",
    "Ribs at Café de Klos, 3 plates between us.",
    "The DJ dropped our song and the whole crowd sang.",
    "Rented bikes and rode 12 km to Zaandam.",
    "Rain, then stroopwafels at Albert Cuyp.",
    "I almost cried when the lights came up.",
    "Lost my jacket somewhere in the second room.",
    "The ferry to NDSM took 15 minutes.",
    "Мы впервые увидели рассвет над каналом.",
    "We went home.",
    "Best night of the year, hands down.",
  ];
  const notes = lines.map((content, k) => ({
    id: `n${k}`,
    trip_id: TRIP_ID,
    day_date: k < 5 ? "2026-09-04" : k < 9 ? "2026-09-05" : "2026-09-06",
    content,
    taken_at: local(
      k < 5 ? "2026-09-04" : k < 9 ? "2026-09-05" : "2026-09-06",
      k < 5 ? 22 + k % 2 : k < 9 ? 14 : 23,
    ),
    created_at: null,
    photo_id: null,
    dictated: false,
    legacy: false,
  }));
  return {
    trips: [{
      id: TRIP_ID,
      user_id: OWNER_ID,
      name: "Amsterdam",
      destination: "Amsterdam",
      country_code: "NL",
      start_date: "2026-09-04",
      end_date: "2026-09-06",
      vibes: ["Nightlife", "Foodie"],
      cover_image_path: null,
    }],
    wrap_ups: [],
    journal_notes: notes,
    photos,
    bonus_task_assignments: [],
    points_ledger: [],
    user_achievements: [],
    photo_analysis: [],
  };
}

// What the director sent: titles a character too long, a headline two
// too long, a banned phrase, an invented photo.
function brokenSection(photoIds: string[]) {
  return {
    chapters: [{
      title: "A".repeat(MAX_NN_TITLE_CHARS - 6) + " night",
      first_photo_id: photoIds[0],
      note_id: null,
      note_excerpt: null,
      moments: [
        { type: "burst", photo_ids: [photoIds[1], photoIds[2], "invented"] },
        { type: "timeline", photo_ids: photoIds.slice(3, 9) },
      ],
      excerpts: [],
    }, {
      title: "Epic Sunday at the canals",
      first_photo_id: photoIds[10],
      note_id: null,
      note_excerpt: null,
      moments: [{ type: "timeline", photo_ids: photoIds.slice(11, 17) }],
      excerpts: [],
    }],
    note_moment: null,
    headline: "N".repeat(MAX_NN_HEADLINE_CHARS + 2),
  };
}

function director(answer: (ids: string[]) => unknown) {
  const client = fakeSupabaseClient(tables());
  const fetchImpl = ((_url: string, init?: RequestInit) => {
    const body = JSON.parse(init!.body as string);
    const tool = body.tools[0].name as string;
    if (tool === "emit_photo_analysis") {
      const ids =
        (body.messages[0].content as { type: string; text?: string }[])
          .filter((b) => b.type === "text" && b.text?.startsWith("Photo id: "))
          .map((b) => b.text!.slice("Photo id: ".length));
      return Promise.resolve(
        toolResponse(tool, { photos: ids.map(analysisFor) }),
      );
    }
    const content = body.messages[0].content as string;
    const input = JSON.parse(content.slice(content.indexOf("{")));
    const ids = (input.photos as { photo_id: string }[]).map((p) => p.photo_id);
    const value = answer(ids);
    if (value instanceof Error) {
      return Promise.resolve(new Response("{}", { status: 500 }));
    }
    return Promise.resolve(toolResponse(tool, { neon_night: value }));
  }) as typeof fetch;
  const tools: string[] = [];
  const deps: Deps = {
    serviceClient: client,
    authClient: fakeAuthClient({ id: OWNER_ID }),
    generateAiFields: () => Promise.resolve(validAiFields),
    log: () => {},
    director: {
      isEnabledFor: () => true,
      run: (tripId: string, tripData: TripData, language: WrapUpLanguage) =>
        runDirector(
          {
            client,
            apiKey: "key",
            fetchImpl: ((url: string, init?: RequestInit) => {
              tools.push(JSON.parse(init!.body as string).tools[0].name);
              return fetchImpl(url, init);
            }) as typeof fetch,
            log: () => {},
            signImageUrls: (paths: string[]) =>
              Promise.resolve(paths.map((p) => `https://signed.test/${p}`)),
          },
          tripId,
          tripData,
          language,
        ),
    },
  };
  return { client, tools, deps };
}

async function open(answer: (ids: string[]) => unknown) {
  const d = director(answer);
  const res = await handleRequest(
    new Request("http://localhost", {
      method: "POST",
      headers: { authorization: "Bearer token" },
      body: JSON.stringify({ trip_id: TRIP_ID, utc_offset_minutes: OFFSET }),
    }),
    d.deps,
  );
  assertEquals(res.status, 200);
  return { json: await res.json(), tools: d.tools };
}

Deno.test("Amsterdam plays Neon Night: the director's faults are repaired (#433)", async () => {
  const { json, tools } = await open(brokenSection);
  assertEquals(json.content.film_style, "neon_night");
  const nn = json.content.neon_night;
  assert(nn.chapters.length >= 2);
  assertEquals(json.content.film_report.source, "director");
  for (const chapter of nn.chapters) {
    assert([...chapter.title].length <= MAX_NN_TITLE_CHARS, chapter.title);
    assertEquals(/epic/i.test(chapter.title), false);
  }
  assert(
    nn.headline === null || [...nn.headline].length <= MAX_NN_HEADLINE_CHARS,
  );
  assertEquals(JSON.stringify(nn).includes("invented"), false);
  // One call after the analysis: the Neon section.
  assertEquals(tools.filter((t) => t !== "emit_photo_analysis"), [
    "emit_neon_night",
  ]);
  // At most 12 lines; the feelings come first.
  const lines = nn.chapters.flatMap((c: { excerpts: { text: string }[] }) =>
    c.excerpts.map((e) => e.text)
  );
  assert(lines.length <= 12);
  assertEquals(lines.includes("It was fun."), false);
});

Deno.test("Amsterdam plays Neon Night when the director fails or sends junk", async () => {
  for (const answer of [() => new Error("down"), () => "junk", () => null]) {
    const { json } = await open(answer);
    assertEquals(json.content.film_style, "neon_night");
    assertEquals(json.content.film_report.source, "code");
    assert(json.content.neon_night.chapters.length >= 2);
    assertEquals("golden_vows" in json.content, false);
  }
});
