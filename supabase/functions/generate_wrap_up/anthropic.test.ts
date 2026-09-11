import {
  assertEquals,
  assertRejects,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { callAnthropic } from "./anthropic.ts";
import { validAiFields, validTripData } from "./test_fixtures.ts";

function toolResponse(input: unknown) {
  return new Response(
    JSON.stringify({
      content: [{ type: "tool_use", name: "emit_wrap_up_copy", input }],
    }),
    { status: 200 },
  );
}

Deno.test("callAnthropic returns the validated fields on a valid response", async () => {
  let calls = 0;
  const fetchImpl = () => {
    calls++;
    return Promise.resolve(toolResponse(validAiFields));
  };
  const result = await callAnthropic(validTripData, "test-key", fetchImpl);
  assertEquals(result, validAiFields);
  assertEquals(calls, 1);
});

Deno.test("callAnthropic retries once on malformed output then succeeds", async () => {
  let calls = 0;
  const fetchImpl = () => {
    calls++;
    return Promise.resolve(
      calls === 1 ? toolResponse({ bad: true }) : toolResponse(validAiFields),
    );
  };
  const result = await callAnthropic(validTripData, "test-key", fetchImpl);
  assertEquals(result, validAiFields);
  assertEquals(calls, 2);
});

Deno.test("callAnthropic throws after malformed output on every attempt", async () => {
  const fetchImpl = () => Promise.resolve(toolResponse({ bad: true }));
  await assertRejects(() =>
    callAnthropic(validTripData, "test-key", fetchImpl)
  );
});

Deno.test("callAnthropic throws when the Anthropic API errors", async () => {
  const fetchImpl = () =>
    Promise.resolve(new Response("rate limited", { status: 429 }));
  await assertRejects(() =>
    callAnthropic(validTripData, "test-key", fetchImpl)
  );
});

// #125: the AI's job is only the four generated fields — the request body
// must not re-send photos, bonus tasks, or star totals, which are assembled
// deterministically elsewhere and never need model input.
Deno.test("callAnthropic's request payload excludes photos, bonus tasks and star totals", async () => {
  let sentBody: Record<string, unknown> | undefined;
  const fetchImpl = (_url: string | URL | Request, init?: RequestInit) => {
    sentBody = JSON.parse(init!.body as string);
    return Promise.resolve(toolResponse(validAiFields));
  };
  await callAnthropic(validTripData, "test-key", fetchImpl as typeof fetch);

  const promptText =
    (sentBody!.messages as Array<{ content: string }>)[0].content;
  for (const photo of validTripData.photos) {
    assertEquals(promptText.includes(photo.storage_path), false);
  }
  for (const task of validTripData.completedBonusTasks) {
    assertEquals(promptText.includes(task.title), false);
  }
  assertEquals(promptText.includes(String(validTripData.starsEarned)), false);
});
