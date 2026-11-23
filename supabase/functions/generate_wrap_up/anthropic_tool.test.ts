// The director's calls (#166, #463 — moved from the removed four-AI-lines
// call): every failure leaves a debuggable `[generate_wrap_up]` line, and
// the thrown error says which kind it was. The API key and the prompt
// (the user's notes) are never logged.

import {
  assert,
  assertEquals,
  assertRejects,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { LOG_PREFIX, WrapUpGenerationError } from "./anthropic.ts";
import { callAnthropicTool } from "./anthropic_tool.ts";

const NOTE = "Pastéis de nata at Manteigaria, still warm.";

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

function call(fetchImpl: () => Promise<Response>, log: (l: string) => void) {
  return callAnthropicTool({
    apiKey: "sk-secret-key",
    model: "claude-sonnet-5",
    maxTokens: 100,
    system: "Pick the words.",
    content: `Notes: ${NOTE}`,
    tool: {
      name: "pick_sky_lines",
      description: "Pick.",
      input_schema: { type: "object", properties: {} },
    },
    label: "sky_story",
    fetchImpl,
    log,
  });
}

Deno.test("a tool call returns its input, usage and stop reason", async () => {
  const { log } = captureLog();
  const result = await call(() =>
    Promise.resolve(
      new Response(
        JSON.stringify({
          stop_reason: "tool_use",
          content: [{ type: "tool_use", input: { picks: [] } }],
          usage: {
            input_tokens: 10,
            cache_read_input_tokens: 5,
            output_tokens: 3,
          },
        }),
        { status: 200 },
      ),
    ), log);
  assertEquals(result.input, { picks: [] });
  assertEquals(result.usage, { input_tokens: 15, output_tokens: 3 });
  assertEquals(result.stopReason, "tool_use");
});

Deno.test("a text-only response logs its block types and throws ai_output_invalid", async () => {
  const { log, events } = captureLog();
  const error = await assertRejects(
    () =>
      call(() =>
        Promise.resolve(
          new Response(
            JSON.stringify({
              stop_reason: "end_turn",
              content: [{ type: "text", text: "oops" }],
            }),
            { status: 200 },
          ),
        ), log),
    WrapUpGenerationError,
  );
  assertEquals(error.code, "ai_output_invalid");
  const [first] = events();
  assertEquals(first.event, "director_invalid_output");
  assertEquals(first.call, "sky_story");
  assertEquals(first.block_types, ["text"]);
  assertEquals(first.problems, ["no tool_use block in the response"]);
});

Deno.test("an Anthropic HTTP error logs status and body, then throws ai_upstream_error", async () => {
  const { log, events } = captureLog();
  const error = await assertRejects(
    () =>
      call(
        () => Promise.resolve(new Response("overloaded", { status: 529 })),
        log,
      ),
    WrapUpGenerationError,
  );
  assertEquals(error.code, "ai_upstream_error");
  const [first] = events();
  assertEquals(first.event, "director_http_error");
  assertEquals(first.status, 529);
  assertEquals(first.body, "overloaded");
});

Deno.test("a network failure logs it and throws ai_unreachable", async () => {
  const { log, events } = captureLog();
  const error = await assertRejects(
    () => call(() => Promise.reject(new TypeError("connection reset")), log),
    WrapUpGenerationError,
  );
  assertEquals(error.code, "ai_unreachable");
  assertEquals(events()[0].event, "director_fetch_failed");
  assertEquals(events()[0].error, "connection reset");
});

Deno.test("logs truncate huge payloads and never contain the API key or the prompt", async () => {
  const { log, lines } = captureLog();
  await assertRejects(() =>
    call(
      () => Promise.resolve(new Response("x".repeat(10_000), { status: 500 })),
      log,
    )
  );
  assert(lines.length > 0);
  for (const line of lines) {
    assert(line.length < 5000, `line too long: ${line.length}`);
    assertStringIncludes(line, "more chars]");
    assert(!line.includes("sk-secret-key"));
    assert(!line.includes(NOTE));
  }
});
