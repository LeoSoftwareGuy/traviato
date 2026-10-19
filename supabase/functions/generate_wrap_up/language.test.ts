import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { languageInstruction, parseWrapUpLanguage } from "./language.ts";

Deno.test("parseWrapUpLanguage accepts ru and falls back to en", () => {
  assertEquals(parseWrapUpLanguage("ru"), "ru");
  assertEquals(parseWrapUpLanguage("en"), "en");
  for (const other of [undefined, null, "et", "RU", 7, ""]) {
    assertEquals(parseWrapUpLanguage(other), "en");
  }
});

Deno.test("only a non-English language adds an instruction", () => {
  assertEquals(languageInstruction("en"), "");
  assert(languageInstruction("ru").includes("Russian"));
});
