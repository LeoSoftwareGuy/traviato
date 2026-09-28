import {
  assert,
  assertEquals,
  assertRejects,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  callAnthropic,
  LOG_PREFIX,
  WrapUpGenerationError,
} from "./anthropic.ts";
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

// #166: every failed attempt leaves a debuggable `[generate_wrap_up]` line,
// and the thrown error says which kind of failure it was.

function captureLog() {
  const lines: string[] = [];
  const log = (line: string) => lines.push(line);
  const events = () =>
    lines.map((line) => {
      assert(line.startsWith(`${LOG_PREFIX} `), line);
      return JSON.parse(line.slice(LOG_PREFIX.length + 1));
    });
  return { log, lines, events };
}

Deno.test("a truncated tool call logs stop_reason, raw input and problems, then throws ai_output_invalid", async () => {
  const { log, events } = captureLog();
  const truncated = {
    invitation_line2: "One long road.",
    bridges: ["The first stretch."],
  };
  const fetchImpl = () =>
    Promise.resolve(
      new Response(
        JSON.stringify({
          stop_reason: "max_tokens",
          content: [{
            type: "tool_use",
            name: "emit_wrap_up_copy",
            input: truncated,
          }],
        }),
        { status: 200 },
      ),
    );

  const error = await assertRejects(
    () => callAnthropic(validTripData, "test-key", fetchImpl, log),
    WrapUpGenerationError,
  );
  assertEquals(error.code, "ai_output_invalid");
  assertStringIncludes(error.detail, "max_tokens");
  assertStringIncludes(
    error.detail,
    "bridges: expected exactly 3 strings, got 1",
  );

  const logged = events();
  assertEquals(logged.length, 2); // one line per attempt
  assertEquals(logged[0].event, "invalid_ai_output");
  assertEquals(logged[0].attempt, 1);
  assertEquals(logged[1].attempt, 2);
  assertEquals(logged[0].stop_reason, "max_tokens");
  assertEquals(logged[0].block_types, ["tool_use"]);
  assertEquals(logged[0].raw_tool_input, JSON.stringify(truncated));
  assertEquals(logged[0].problems, [
    "bridges: expected exactly 3 strings, got 1",
    "unlock_reason: expected string or null, got undefined",
    "keepsake_closing_quote: expected string, got undefined",
  ]);
});

Deno.test("a text-only response logs its text and says no tool_use block came back", async () => {
  const { log, events } = captureLog();
  const fetchImpl = () =>
    Promise.resolve(
      new Response(
        JSON.stringify({
          stop_reason: "end_turn",
          content: [{ type: "text", text: '```json\n{"oops": true}\n```' }],
        }),
        { status: 200 },
      ),
    );

  await assertRejects(() =>
    callAnthropic(validTripData, "test-key", fetchImpl, log)
  );
  const [first] = events();
  assertEquals(first.problems, ["no tool_use block in the response"]);
  assertEquals(first.raw_tool_input, null);
  assertStringIncludes(first.raw_text, "oops");
});

Deno.test("an Anthropic HTTP error logs status and body, then throws ai_upstream_error", async () => {
  const { log, events } = captureLog();
  const fetchImpl = () =>
    Promise.resolve(new Response("overloaded", { status: 529 }));

  const error = await assertRejects(
    () => callAnthropic(validTripData, "test-key", fetchImpl, log),
    WrapUpGenerationError,
  );
  assertEquals(error.code, "ai_upstream_error");
  const [first] = events();
  assertEquals(first.event, "http_error");
  assertEquals(first.status, 529);
  assertEquals(first.body, "overloaded");
});

Deno.test("a network failure logs it and throws ai_unreachable", async () => {
  const { log, events } = captureLog();
  const fetchImpl = () => Promise.reject(new TypeError("connection reset"));

  const error = await assertRejects(
    () => callAnthropic(validTripData, "test-key", fetchImpl, log),
    WrapUpGenerationError,
  );
  assertEquals(error.code, "ai_unreachable");
  assertEquals(events()[0].event, "fetch_failed");
  assertEquals(events()[0].error, "connection reset");
});

Deno.test("logs truncate huge payloads and never contain the API key or the prompt", async () => {
  const { log, lines } = captureLog();
  const fetchImpl = () =>
    Promise.resolve(new Response("x".repeat(10_000), { status: 500 }));

  await assertRejects(() =>
    callAnthropic(validTripData, "sk-secret-key", fetchImpl, log)
  );
  for (const line of lines) {
    assert(line.length < 5000, `line too long: ${line.length}`);
    assertStringIncludes(line, "more chars]");
    assert(!line.includes("sk-secret-key"));
    assert(!line.includes(validTripData.notes[0].content));
  }
});
