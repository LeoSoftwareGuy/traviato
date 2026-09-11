import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { validateAiGeneratedFields } from "./ai_fields.ts";
import { validAiFields } from "./test_fixtures.ts";

Deno.test("validateAiGeneratedFields accepts a well-formed response", () => {
  assertEquals(validateAiGeneratedFields(validAiFields), true);
});

Deno.test("validateAiGeneratedFields accepts a null unlock_reason", () => {
  assertEquals(
    validateAiGeneratedFields({ ...validAiFields, unlock_reason: null }),
    true,
  );
});

Deno.test("validateAiGeneratedFields rejects bridges without exactly 3 entries", () => {
  assertEquals(
    validateAiGeneratedFields({ ...validAiFields, bridges: ["one", "two"] }),
    false,
  );
});

Deno.test("validateAiGeneratedFields rejects a missing field", () => {
  const { keepsake_closing_quote: _quote, ...rest } = validAiFields;
  assertEquals(validateAiGeneratedFields(rest), false);
});

Deno.test("validateAiGeneratedFields rejects non-object input", () => {
  assertEquals(validateAiGeneratedFields("nope"), false);
  assertEquals(validateAiGeneratedFields(null), false);
});
