import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { validateWrapUpContent } from "./content.ts";
import { validWrapUpContent } from "./test_fixtures.ts";

Deno.test("validateWrapUpContent accepts a well-formed content object", () => {
  assertEquals(validateWrapUpContent(validWrapUpContent), true);
});

Deno.test("validateWrapUpContent accepts a null unlock", () => {
  assertEquals(
    validateWrapUpContent({ ...validWrapUpContent, unlock: null }),
    true,
  );
});

Deno.test("validateWrapUpContent accepts empty moments and flurry_leftovers", () => {
  assertEquals(
    validateWrapUpContent({
      ...validWrapUpContent,
      moments: [],
      flurry_leftovers: { photos: [], total_remaining_label: null },
    }),
    true,
  );
});

Deno.test("validateWrapUpContent rejects a missing top-level field", () => {
  const { keepsake: _keepsake, ...withoutKeepsake } = validWrapUpContent;
  assertEquals(validateWrapUpContent(withoutKeepsake), false);
});

Deno.test("validateWrapUpContent rejects a wrong-typed field", () => {
  assertEquals(
    validateWrapUpContent({
      ...validWrapUpContent,
      invitation: { ...validWrapUpContent.invitation, line1: 42 },
    }),
    false,
  );
});

Deno.test("validateWrapUpContent rejects bridges without exactly 3 entries", () => {
  assertEquals(
    validateWrapUpContent({ ...validWrapUpContent, bridges: ["only one"] }),
    false,
  );
});

Deno.test("validateWrapUpContent rejects a malformed moment entry", () => {
  assertEquals(
    validateWrapUpContent({
      ...validWrapUpContent,
      moments: [{ photo_id: "p1" }],
    }),
    false,
  );
});

Deno.test("validateWrapUpContent rejects non-object input", () => {
  assertEquals(validateWrapUpContent("not an object"), false);
  assertEquals(validateWrapUpContent(null), false);
});
