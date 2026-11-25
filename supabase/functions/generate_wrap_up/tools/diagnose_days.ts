// Prints where an exported memory's notes and photos land in Sky Story:
// each note's Journal day (day_date), its time and offset, the logical
// day the film computed and the page it plays on; each Journal day's
// photos and the days their EXIF times put them on; and every page's
// days, headline and lines with where each word came from. Read-only,
// no network:
//
//   deno run -A tools/diagnose_days.ts --in fixtures/<memory>.json
//
// Export the memory first (tools/export_director_input.ts).

import type { TripData } from "../gather.ts";
import { withLocalTimes } from "../time_zones.ts";
import { withFilmPhotos } from "../film_photos.ts";
import { tripLogicalDays } from "../logical_day.ts";
import { skyStoryFilm } from "../sky_film.ts";
import { skyNoteDay, skyNoteHomes } from "../sky_slots.ts";

const at = Deno.args.indexOf("--in");
const file = at >= 0 ? Deno.args[at + 1] : undefined;
if (!file) {
  console.error("Pass --in fixtures/<memory>.json");
  Deno.exit(1);
}
const fixture = JSON.parse(await Deno.readTextFile(file));
const heroScores: Record<string, number> = Object.fromEntries(
  (fixture.analyses ?? []).map((
    a: { photo_id: string; hero_score: number },
  ) => [a.photo_id, a.hero_score]),
);
const summaries = new Map<string, string>(
  (fixture.analyses ?? []).map((
    a: { photo_id: string; summary: string },
  ) => [a.photo_id, a.summary]),
);
const raw = structuredClone(fixture.trip_data) as TripData;
// As the handler does (#468): each photo's summary, for content matching.
for (const p of raw.photos) p.summary = summaries.get(p.id) ?? null;
const memory = withFilmPhotos(withLocalTimes(raw), heroScores);
const days = tripLogicalDays(memory);
const film = skyStoryFilm(
  memory,
  fixture.recorded_director?.sky?.picks ?? null,
  {
    heroScores,
    summaries,
  },
);
const pages = film.skeleton.pages;
const homes = skyNoteHomes(memory, film.skeleton);
const short = (id: string) => id.slice(0, 8);
const clip = (t: string, n = 60) =>
  t.replace(/\s+/g, " ").slice(0, n) + (t.length > n ? "…" : "");

const { trip } = memory;
console.log(
  `${trip.name}: ${trip.start_date} → ${trip.end_date}, ${memory.photos.length} photos (${film.skeleton.photos.length} in film), ${memory.notes.length} notes\n`,
);

console.log("PHOTOS per Journal day (day_date) → logical day from taken_at");
const byJournal = new Map<string, Map<string, number>>();
for (const p of memory.photos) {
  const j = p.day_date ?? "none";
  const l = days.get(p.id) ?? "none";
  const m = byJournal.get(j) ?? new Map<string, number>();
  m.set(l, (m.get(l) ?? 0) + 1);
  byJournal.set(j, m);
}
for (const [j, m] of [...byJournal].sort()) {
  console.log(
    `  ${j}: ${
      [...m].map(([l, c]) => `${l === j ? "same" : l} ×${c}`).join(", ")
    }`,
  );
}

console.log("\nNOTES");
for (
  const n of [...memory.notes].sort((a, b) =>
    (a.day_date ?? "").localeCompare(b.day_date ?? "")
  )
) {
  const logical = days.get(`note:${n.id}`) ?? "none";
  const used = skyNoteDay(memory, days, n);
  const home = homes.get(n.id!);
  const page = home == null
    ? "no page"
    : `p${home} [${pages[home].days.join(",")}]`;
  const flag = used !== n.day_date ||
      (home != null && !pages[home].days.includes(n.day_date!))
    ? "  ⚠ OFF ITS JOURNAL DAY"
    : "";
  console.log(
    `  ${
      short(n.id!)
    } day_date ${n.day_date} taken_at ${n.taken_at} offset ${n.utc_offset_minutes} legacy ${n.legacy} photo ${
      n.photo_id ? short(n.photo_id) : "-"
    }\n    logical ${logical} · film day ${used} · ${page}${flag}\n    "${
      clip(n.content)
    }"`,
  );
}

console.log("\nPAGES");
film.content?.pages.forEach((p, k) => {
  const sk = pages[k];
  const journal = [...new Set(sk.photos.map((x) => x.day_date))].sort();
  console.log(
    `  p${k} days ${sk.days.join(",")} (Journal days of its photos: ${
      journal.join(",")
    }) · ${sk.photos.length} photos${sk.is_part ? " · part" : ""}`,
  );
  console.log(`    headline: ${p.headline ?? "(Day N)"}`);
  for (const e of p.excerpts) {
    console.log(`    line [${short(e.note_id)}]: ${clip(e.text, 80)}`);
  }
  if (p.sky_line) console.log(`    sky line: ${p.sky_line}`);
  const hero = sk.hero;
  console.log(
    `    hero ${short(hero.id)} "${hero.caption ?? ""}" · ${
      summaries.get(hero.id) ?? ""
    }`,
  );
});

console.log("\nHEADLINE SLOTS");
for (const r of film.report.filter((x) => x.slot.endsWith(".headline"))) {
  console.log(
    `  ${r.slot}: plays "${
      r.chosen.map((c) => c.text).join(" / ")
    }" (${r.source}: ${r.reason})`,
  );
  for (const c of r.candidates) {
    console.log(`    - ${c.id} (${c.score}): ${c.text}`);
  }
}
const recorded = fixture.recorded_director?.sky_slots;
if (recorded) {
  console.log("\nRECORDED RUN headline slots (what the phone got):");
  console.log(JSON.stringify(
    (recorded as { slot: string }[]).filter((x) =>
      x.slot.endsWith(".headline")
    ),
    null,
    1,
  ));
}
