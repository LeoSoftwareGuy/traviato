import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { bannedPhraseIn, withoutBannedPhrases } from "./film_plan.ts";

Deno.test("banned phrases are removed from AI lines (#433)", () => {
  const cases: [string, string][] = [
    ["An epic night", "An night"],
    ["Unforgettable Amsterdam", "Amsterdam"],
    ["Epic!", ""],
    ["the epicentre", "the epicentre"],
    ["Wanderlust, again", "again"],
    ["Adventure   awaits here", "here"],
    ["Memories to last a lifetime.", ""],
  ];
  for (const [line, want] of cases) {
    const out = withoutBannedPhrases(line);
    assertEquals(out, want, line);
    assertEquals(bannedPhraseIn(out), null, line);
  }
});
