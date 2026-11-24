// Records one real pick_sky_lines answer for an exported memory (#463),
// so tests replay what the director actually picks on the real data.
// Calls Anthropic once with exactly the input the edge function sends.
// Export the memory first (tools/export_director_input.ts), then run
// locally (never commit the key):
//
//   ANTHROPIC_API_KEY=… deno run -A tools/record_sky_picks.ts \
//     --in fixtures/<memory>.json --out fixtures/<memory>_sky_picks.json
//
// Prints the pages (their days, photos on pages, the estimated length and
// what it gave up for it), each slot's pick, whether it holds and its
// candidates, the notes on no page and why; then writes
// `{ recorded_at, model, picks, usage }`.

import { callAnthropicTool } from "../anthropic_tool.ts";
import { DIRECTOR_MODEL, localClock } from "../director.ts";
import { withFilmPhotos } from "../film_photos.ts";
import type { TripData } from "../gather.ts";
import { parseWrapUpLanguage } from "../language.ts";
import { parsePicks } from "../film_slots.ts";
import { withLocalTimes } from "../time_zones.ts";
import { skyStoryFilm } from "../sky_film.ts";
import {
  buildSkyPickInput,
  buildSkyPickSystemPrompt,
  pickSkyLinesTool,
  skyLanguage,
} from "../sky_slots.ts";

function arg(name: string): string | undefined {
  const at = Deno.args.indexOf(`--${name}`);
  return at >= 0 ? Deno.args[at + 1] : undefined;
}

const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
if (!apiKey) {
  console.error("Set ANTHROPIC_API_KEY.");
  Deno.exit(1);
}
const input = arg("in");
const out = arg("out");
if (!input || !out) {
  console.error("Pass --in <exported memory> --out <picks file>.");
  Deno.exit(1);
}
const language = parseWrapUpLanguage(arg("language") ?? "en");

const fixture = JSON.parse(await Deno.readTextFile(input)) as {
  trip_data: TripData;
  analyses: { photo_id: string; summary: string; hero_score: number }[];
};
const analyses = new Map(fixture.analyses.map((a) => [a.photo_id, a]));
const heroScores = Object.fromEntries(
  fixture.analyses.map((a) => [a.photo_id, a.hero_score]),
);
const options = {
  heroScores,
  summaries: new Map(fixture.analyses.map((a) => [a.photo_id, a.summary])),
  language,
};
// As the edge function sees it: each photo on its place's clock (#461),
// the film's photos, analysed ones only.
const memory = withFilmPhotos(withLocalTimes(fixture.trip_data), heroScores);
const seen = {
  ...memory,
  photos: memory.photos.filter((p) =>
    analyses.has(p.id) || p.use_in_wrap_up === false
  ),
};
const cut = skyStoryFilm(seen, null, options);
const result = await callAnthropicTool({
  apiKey,
  model: DIRECTOR_MODEL,
  maxTokens: 8192,
  system: buildSkyPickSystemPrompt(skyLanguage(seen, language)),
  content: `Pick the words for this film:\n${
    JSON.stringify(
      buildSkyPickInput(
        seen,
        cut.skeleton,
        cut.slots,
        analyses,
        (iso, item) => localClock(iso, seen, item),
      ),
    )
  }`,
  tool: pickSkyLinesTool,
  label: "sky_story",
});
const picks = parsePicks(result.input);
if (!picks) {
  console.error("The answer isn't a list of picks:", result.input);
  Deno.exit(1);
}
const film = skyStoryFilm(seen, picks, options);
console.log(
  `${film.content?.pages.length ?? 0} pages: ${
    film.skeleton.pages.map((p) => p.days.join("+")).join(" · ")
  }\n${film.shown.pages} / ${film.shown.photos} photos on pages · ` +
    `${film.seconds} s of ${film.limit_seconds} s\n` +
    `for length: ${film.trims.join(" · ") || "nothing"}`,
);
// Each slot: what plays and why, the director's pick, then its
// candidates — ✓ what plays, → what the director picked.
for (const r of film.report) {
  console.log(
    `\n${r.slot}  [${r.source}]  ${
      r.chosen.map((c) => c.text).join(" | ") || "—"
    }\n  ${r.reason}`,
  );
  if (r.pick?.free_title) console.log(`  free_title: ${r.pick.free_title}`);
  const chosen = new Set(r.chosen.map((c) => c.id));
  const picked = new Set(
    (r.pick?.ids ?? []).map((id) =>
      id.startsWith(`${r.slot}/`) ? id.slice(r.slot.length + 1) : id
    ),
  );
  for (const c of r.candidates) {
    const mark = `${chosen.has(c.id) ? "✓" : " "}${
      picked.has(c.id) ? "→" : " "
    }`;
    console.log(`  ${mark} ${String(c.score).padStart(4)}  ${c.text}`);
  }
}
console.log(`\nnotes on no page: ${film.unlisted.length}`);
for (const n of film.unlisted) console.log(`  ${n.reason}: ${n.text}`);
await Deno.writeTextFile(
  out,
  `${
    JSON.stringify(
      {
        recorded_at: new Date().toISOString(),
        model: DIRECTOR_MODEL,
        picks,
        usage: result.usage,
      },
      null,
      2,
    )
  }\n`,
);
console.log(`${out}: ${Object.keys(picks).length} picks`);
