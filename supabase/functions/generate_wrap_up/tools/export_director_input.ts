// Exports one memory's real director input as a test fixture (#454):
// everything the Neon Night director step reads — the memory through the
// production gatherTripData, the cached photo analyses and the stored
// director record (the last real run) — so tests run on the real data,
// never a rebuilt copy.
//
// Read-only: it only selects. Run it locally with the service-role key in
// the environment (never commit the key):
//
//   SUPABASE_URL=… SUPABASE_SERVICE_ROLE_KEY=… \
//   deno run -A tools/export_director_input.ts \
//     --trip <trip id> --offset 120 --out fixtures/ade_amsterdam.json
//
// --name "<memory name>" finds the trip by its name instead of its id
// (it must match exactly one memory). --offset is the phone's offset from
// UTC in minutes when the film was made (Amsterdam in late October: 120).
//
// Storage paths become `p/<photo id>.jpg` and user ids are left out; notes,
// captions, places and names stay as they are (private repo).

import { createClient } from "npm:@supabase/supabase-js@2.45.4";
import { gatherTripData } from "../gather.ts";
import { loadCachedAnalysis } from "../photo_analysis.ts";

function arg(name: string): string | undefined {
  const at = Deno.args.indexOf(`--${name}`);
  return at >= 0 ? Deno.args[at + 1] : undefined;
}

const url = Deno.env.get("SUPABASE_URL");
const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
if (!url || !key) {
  console.error("Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.");
  Deno.exit(1);
}
const out = arg("out") ?? "fixtures/ade_amsterdam.json";
const offset = Number(arg("offset") ?? "0");
const client = createClient(url, key);

let tripId = arg("trip");
if (!tripId) {
  const name = arg("name");
  if (!name) {
    console.error("Pass --trip <id> or --name <memory name>.");
    Deno.exit(1);
  }
  const { data, error } = await client.from("trips").select("id").eq(
    "name",
    name,
  );
  if (error) throw new Error(error.message);
  if ((data ?? []).length !== 1) {
    console.error(`${(data ?? []).length} memories are named "${name}".`);
    Deno.exit(1);
  }
  tripId = data![0].id as string;
}

const tripData = await gatherTripData(client, tripId);
tripData.utc_offset_minutes = offset;
const analyses = await loadCachedAnalysis(client, tripId);
const { data: wrapUp, error: wrapUpError } = await client
  .from("wrap_ups")
  .select("director")
  .eq("trip_id", tripId)
  .maybeSingle();
if (wrapUpError) throw new Error(wrapUpError.message);

const path = (id: string) => `p/${id}.jpg`;
const paths = new Map(tripData.photos.map((p) => [p.storage_path, p.id]));
for (const p of tripData.photos) p.storage_path = path(p.id);
tripData.trip.cover_image_path = tripData.trip.cover_image_path &&
    paths.has(tripData.trip.cover_image_path)
  ? path(paths.get(tripData.trip.cover_image_path)!)
  : tripData.trip.cover_image_path;

const director = wrapUp?.director ?? null;
if (director && typeof director === "object") {
  const photoPaths = (director as Record<string, unknown>).photo_paths;
  if (photoPaths && typeof photoPaths === "object") {
    (director as Record<string, unknown>).photo_paths = Object.fromEntries(
      Object.keys(photoPaths).map((id) => [id, path(id)]),
    );
  }
}

const fixture = {
  exported_at: new Date().toISOString(),
  trip_data: tripData,
  analyses: [...analyses.values()].map((a) => ({
    ...a,
    trip_id: "t",
    storage_path: path(a.photo_id),
  })),
  recorded_director: director,
};
await Deno.writeTextFile(out, `${JSON.stringify(fixture, null, 2)}\n`);
console.log(
  `${out}: ${tripData.photos.length} photos, ${tripData.notes.length} notes, ${analyses.size} analyses${
    director ? ", director record" : ""
  }`,
);
