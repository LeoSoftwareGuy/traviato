// The film-length fixtures (#434): a 15-, 25- and 40-photo memory of each
// film, as the edge function builds its content. `film_lengths.json`
// holds them for the app's test (film_length_fixtures_test.dart), which
// plays each through the real parsers and timelines and checks its
// length. Regenerate after a change to how content is built:
//   deno run --allow-write write_film_lengths.ts

import { directorTripData } from "./director_fixtures.ts";
import { currentNeonNight } from "./director.ts";
import { goldenVowsFilm } from "./gv_film.ts";
import { buildNeonNightContent } from "./neon_film.ts";
import { buildSkyContent } from "./sky_story.ts";
import { withFilmPhotos } from "./film_photos.ts";
import { filmSecondsOf } from "./film_length.ts";
import type { PlayedTemplate } from "./film_template.ts";
import type { TripData } from "./gather.ts";
import { adeFilmMemory, adePicks } from "./ade_amsterdam.ts";

export const FIXTURE_PHOTO_COUNTS = [15, 25, 40];
export const FIXTURE_FILMS: PlayedTemplate[] = [
  "sky_story",
  "golden_vows",
  "neon_night",
];

const VIBES: Record<PlayedTemplate, string[]> = {
  sky_story: ["Cultural"],
  golden_vows: ["Romantic"],
  neon_night: ["Nightlife"],
};

const DAYS = ["2026-09-01", "2026-09-02", "2026-09-03"];

// A three-day memory of [photos] photos, a note a day, a packed checklist
// and a timed plan.
export function lengthMemory(film: PlayedTemplate, photos: number): TripData {
  const base = directorTripData().photos[0];
  return directorTripData({
    trip: {
      ...directorTripData().trip,
      name: "Lisbon",
      start_date: DAYS[0],
      end_date: DAYS[2],
      vibes: VIBES[film],
    },
    photos: Array.from({ length: photos }, (_, i) => {
      const day = DAYS[Math.floor((i * DAYS.length) / photos)];
      const minute = 9 * 60 + 37 * (i % Math.ceil(photos / DAYS.length));
      const at = `${day}T${String(Math.floor(minute / 60)).padStart(2, "0")}:${
        String(minute % 60).padStart(2, "0")
      }:00Z`;
      return {
        ...base,
        id: `p${String(i).padStart(2, "0")}`,
        day_date: day,
        taken_at: at,
        created_at: at,
        storage_path: `u/t/p${i}.jpg`,
        caption: null,
        use_in_wrap_up: null,
        place_text: null,
      };
    }),
    notes: DAYS.map((day, i) => ({
      id: `n${i}`,
      day_date: day,
      content: [
        "Tram 28 up to the castle, the whole city below us.",
        "Pastéis de nata at Manteigaria, still warm, three each.",
        "Our last sunset at Miradouro da Senhora do Monte.",
      ][i],
      created_at: `${day}T20:00:00Z`,
      taken_at: `${day}T20:00:00Z`,
      photo_id: null,
      legacy: false,
    })),
    checklist: ["Passports", "Sunscreen", "Camera", "Sandals"].map((
      title,
    ) => ({ title, suggestion_code: null, is_checked: true })),
    quests: ["10:00:00", "13:30:00", "18:00:00", "21:00:00"].map((
      time,
      i,
    ) => ({
      title: ["Castle", "Lunch in Alfama", "Sunset", "Fado"][i],
      day_date: DAYS[0],
      time,
      completed_at: null,
    })),
  });
}

// What the edge function builds for [film] with [photos] photos, the
// director off (code's plan).
export function lengthContent(
  film: PlayedTemplate,
  photos: number,
): Record<string, unknown> {
  const memory = withFilmPhotos(lengthMemory(film, photos), {});
  const content: Record<string, unknown> = {
    film_style: film,
    film_seconds: filmSecondsOf(memory),
    sky: buildSkyContent(memory, null, {}),
  };
  if (film === "golden_vows") {
    content.golden_vows = goldenVowsFilm(memory, null).content;
  }
  if (film === "neon_night") {
    content.neon_night = buildNeonNightContent(
      memory,
      currentNeonNight(null).picks,
    );
  }
  return content;
}

// ADE-Amsterdam's content from its real data (#454): the exported memory
// with the director's recorded picks.
export function adeContent(): Record<string, unknown> {
  const { memory, heroScores } = adeFilmMemory();
  return {
    film_style: "neon_night",
    film_seconds: filmSecondsOf(memory),
    sky: buildSkyContent(memory, null, heroScores),
    neon_night: buildNeonNightContent(memory, adePicks(), heroScores),
  };
}

type LengthFixture = {
  film: PlayedTemplate;
  photos: number;
  photo_ids: string[];
  start_date: string;
  end_date: string;
  content: Record<string, unknown>;
  case?: string;
};

// Every fixture, as film_lengths.json holds them.
export function filmLengthFixtures(): {
  film: PlayedTemplate;
  photos: number;
  photo_ids: string[];
  start_date: string;
  end_date: string;
  content: Record<string, unknown>;
  case?: string;
}[] {
  return FIXTURE_FILMS.flatMap((film) =>
    FIXTURE_PHOTO_COUNTS.map((photos): LengthFixture => ({
      film,
      photos,
      photo_ids: lengthMemory(film, photos).photos.map((p) => p.id),
      start_date: DAYS[0],
      end_date: DAYS[2],
      content: lengthContent(film, photos),
    }))
  ).concat([{
    film: "neon_night",
    photos: adeFilmMemory().memory.photos.length,
    photo_ids: adeFilmMemory().memory.photos.map((p) => p.id),
    start_date: adeFilmMemory().memory.trip.start_date!,
    end_date: adeFilmMemory().memory.trip.end_date!,
    content: adeContent(),
    // ADE-Amsterdam's real data (#448, #454).
    case: "ade",
  }]);
}
