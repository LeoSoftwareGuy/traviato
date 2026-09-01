import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { validateScreenplay } from "./screenplay.ts";
import { validScreenplay } from "./test_fixtures.ts";

Deno.test("validateScreenplay accepts a well-formed screenplay", () => {
  assertEquals(validateScreenplay(validScreenplay), true);
});

Deno.test("validateScreenplay accepts a null achievement_moment", () => {
  assertEquals(validateScreenplay({ ...validScreenplay, achievement_moment: null }), true);
});

Deno.test("validateScreenplay rejects a missing top-level field", () => {
  const { close: _close, ...withoutClose } = validScreenplay;
  assertEquals(validateScreenplay(withoutClose), false);
});

Deno.test("validateScreenplay rejects a wrong-typed field", () => {
  assertEquals(
    validateScreenplay({ ...validScreenplay, hero: { ...validScreenplay.hero, title: 42 } }),
    false,
  );
});

Deno.test("validateScreenplay rejects a malformed photo_beats entry", () => {
  assertEquals(
    validateScreenplay({
      ...validScreenplay,
      photo_beats: [{ photo_id: "p1" }],
    }),
    false,
  );
});

Deno.test("validateScreenplay rejects non-object input", () => {
  assertEquals(validateScreenplay("not an object"), false);
  assertEquals(validateScreenplay(null), false);
});
