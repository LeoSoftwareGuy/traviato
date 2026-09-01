import { assertEquals, assertRejects } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { callAnthropic } from "./anthropic.ts";
import { validScreenplay } from "./test_fixtures.ts";

const tripData = {
  trip: {
    name: "Lisbon",
    destination: "Portugal",
    country_code: "PT",
    start_date: "2026-06-01",
    end_date: "2026-06-05",
    vibes: ["Foodie"],
  },
  quests: [],
  notes: [],
  photos: [],
  latestAchievement: null,
};

function toolResponse(input: unknown) {
  return new Response(
    JSON.stringify({ content: [{ type: "tool_use", name: "emit_screenplay", input }] }),
    { status: 200 },
  );
}

Deno.test("callAnthropic returns the validated screenplay on a valid response", async () => {
  let calls = 0;
  const fetchImpl = () => {
    calls++;
    return Promise.resolve(toolResponse(validScreenplay));
  };
  const result = await callAnthropic(tripData, "test-key", fetchImpl);
  assertEquals(result, validScreenplay);
  assertEquals(calls, 1);
});

Deno.test("callAnthropic retries once on malformed output then succeeds", async () => {
  let calls = 0;
  const fetchImpl = () => {
    calls++;
    return Promise.resolve(calls === 1 ? toolResponse({ bad: true }) : toolResponse(validScreenplay));
  };
  const result = await callAnthropic(tripData, "test-key", fetchImpl);
  assertEquals(result, validScreenplay);
  assertEquals(calls, 2);
});

Deno.test("callAnthropic throws after malformed output on every attempt", async () => {
  const fetchImpl = () => Promise.resolve(toolResponse({ bad: true }));
  await assertRejects(() => callAnthropic(tripData, "test-key", fetchImpl));
});

Deno.test("callAnthropic throws when the Anthropic API errors", async () => {
  const fetchImpl = () =>
    Promise.resolve(new Response("rate limited", { status: 429 }));
  await assertRejects(() => callAnthropic(tripData, "test-key", fetchImpl));
});
