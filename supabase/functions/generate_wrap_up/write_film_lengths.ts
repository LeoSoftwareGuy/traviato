// Regenerates film_lengths.json (#434); see test_film_lengths.ts.
//   deno run --allow-write write_film_lengths.ts
import { filmLengthFixtures } from "./test_film_lengths.ts";

await Deno.writeTextFile(
  new URL("./film_lengths.json", import.meta.url),
  JSON.stringify(filmLengthFixtures(), null, 1) + "\n",
);
