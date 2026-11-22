// Records one real pick_neon_lines answer for an exported memory (#454),
// so tests replay what the director actually picks on the real data.
// Calls Anthropic once with exactly the input the edge function sends.
// Run locally (never commit the key):
//
//   ANTHROPIC_API_KEY=… deno run -A tools/record_neon_picks.ts \
//     --in fixtures/ade_amsterdam.json --out fixtures/ade_amsterdam_picks.json
//
// Prints each slot's pick, whether it holds and its candidates, then
// writes
// `{ recorded_at, model, picks, usage }`.

import { callAnthropicTool } from "../anthropic_tool.ts";
import { DIRECTOR_MODEL, localClock } from "../director.ts";
import { withFilmPhotos } from "../film_photos.ts";
import type { TripData } from "../gather.ts";
import { parseWrapUpLanguage } from "../language.ts";
import { neonNightFilm } from "../neon_film.ts";
import {
  buildNeonPickInput,
  buildNeonPickSystemPrompt,
  parseNeonPicks,
  pickNeonLinesTool,
  unlistedNotes,
} from "../neon_slots.ts";

function arg(name: string): string | undefined {
  const at = Deno.args.indexOf(`--${name}`);
  return at >= 0 ? Deno.args[at + 1] : undefined;
}

const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
if (!apiKey) {
  console.error("Set ANTHROPIC_API_KEY.");
  Deno.exit(1);
}
const input = arg("in") ?? "fixtures/ade_amsterdam.json";
const out = arg("out") ?? "fixtures/ade_amsterdam_picks.json";
const language = parseWrapUpLanguage(arg("language") ?? "ru");

const fixture = JSON.parse(await Deno.readTextFile(input)) as {
  trip_data: TripData;
  analyses: { photo_id: string; summary: string; hero_score: number }[];
};
const analyses = new Map(fixture.analyses.map((a) => [a.photo_id, a]));
const heroScores = Object.fromEntries(
  fixture.analyses.map((a) => [a.photo_id, a.hero_score]),
);
const memory = withFilmPhotos(fixture.trip_data, heroScores);
const seen = {
  ...memory,
  photos: memory.photos.filter((p) =>
    analyses.has(p.id) || p.use_in_wrap_up === false
  ),
};
const cut = neonNightFilm(seen, null, heroScores);
const result = await callAnthropicTool({
  apiKey,
  model: DIRECTOR_MODEL,
  maxTokens: 8192,
  system: buildNeonPickSystemPrompt(language),
  content: `Pick the words for this film:\n${
    JSON.stringify(
      buildNeonPickInput(
        seen,
        cut.chapters,
        cut.slots,
        analyses,
        (iso) => localClock(iso, seen),
      ),
    )
  }`,
  tool: pickNeonLinesTool,
  label: "neon_night",
});
const picks = parseNeonPicks(result.input);
if (!picks) {
  console.error("The answer isn't a list of picks:", result.input);
  Deno.exit(1);
}
// Each slot: what plays and why, the director's pick, then its
// candidates (top 8) — ✓ what plays, → what the director picked.
for (const r of neonNightFilm(seen, picks, heroScores).report) {
  console.log(
    `\n${r.slot}  [${r.source}]  ${
      r.chosen.map((c) => c.text).join(" | ") || "—"
    }\n  ${r.reason}`,
  );
  if (r.pick?.free_title) console.log(`  free_title: ${r.pick.free_title}`);
  const chosen = new Set(r.chosen.map((c) => c.id));
  // The director's ids carry their slot's name (#454).
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
// Notes no slot lists, with the reason: each should be on one (#454).
const unlisted = unlistedNotes(seen, cut.chapters, cut.slots);
console.log(`\nnotes not on any list: ${unlisted.length}`);
for (const n of unlisted) console.log(`  ${n.reason}: ${n.text}`);
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
