import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  describeAiFieldsProblems,
  validateAiGeneratedFields,
} from "./ai_fields.ts";
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

// #166: problems name the exact field and what was wrong with it.
Deno.test("describeAiFieldsProblems is empty for a valid response", () => {
  assertEquals(describeAiFieldsProblems(validAiFields), []);
});

Deno.test("describeAiFieldsProblems names each wrong field", () => {
  assertEquals(
    describeAiFieldsProblems({
      invitation_line2: 42,
      bridges: ["one", "two"],
      unlock_reason: null,
    }),
    [
      "invitation_line2: expected string, got number",
      "bridges: expected exactly 3 strings, got 2",
      "keepsake_closing_quote: expected string, got undefined",
    ],
  );
});

Deno.test("describeAiFieldsProblems flags non-string bridges and a non-object input", () => {
  assertEquals(
    describeAiFieldsProblems({ ...validAiFields, bridges: ["a", 1, null] }),
    ["bridges: expected strings, got [string, number, null]"],
  );
  assertEquals(describeAiFieldsProblems("oops"), [
    "input: expected an object, got string",
  ]);
});
