import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { chosenTemplate, playedTemplate } from "./film_template.ts";

Deno.test("each vibe maps to its template (#433)", () => {
  assertEquals(playedTemplate(["Nightlife"]), "neon_night");
  assertEquals(playedTemplate(["Romantic"]), "golden_vows");
  for (const vibe of ["Adventure", "Road trip", "Wildlife"]) {
    assertEquals(chosenTemplate([vibe]), "field_notes");
    // Until Field Notes ships.
    assertEquals(playedTemplate([vibe]), "sky_story");
  }
  for (
    const vibe of ["Cultural", "Chill", "Foodie", "Wellness", "Photography"]
  ) {
    assertEquals(playedTemplate([vibe]), "sky_story");
  }
  assertEquals(playedTemplate([]), "sky_story");
});

Deno.test("several vibes: Romantic > Nightlife > outdoors > the rest", () => {
  assertEquals(playedTemplate(["Nightlife", "Romantic"]), "golden_vows");
  assertEquals(
    playedTemplate(["Foodie", "Adventure", "Nightlife"]),
    "neon_night",
  );
  assertEquals(chosenTemplate(["Chill", "Wildlife"]), "field_notes");
  // More than 3 vibes (older memories) still follow the priority.
  assertEquals(
    playedTemplate(["Chill", "Foodie", "Cultural", "Wellness", "Nightlife"]),
    "neon_night",
  );
  assertEquals(playedTemplate([" nightlife "]), "neon_night");
});
