// Calls the Anthropic API for the wrap-up film's four AI-written lines
// (#125), forcing structured output via a tool call (aiGeneratedFieldsToolSchema)
// rather than parsing free-form JSON. Retries once on malformed output before
// giving up.
//
// The prompt intentionally sends only what those four fields need — trip
// identity, day count, day notes, and the achievement (or null). No quests,
// no photo metadata, no bonus-task detail: those feed assemble.ts's plain
// deterministic assembly instead, never the model.
//
// Model is claude-sonnet-5 — wrap-up playback is the app's headline feature,
// so narrative quality wins over the lower cost of a smaller model here
// (unchanged from #93's decision; the prompt got smaller, not the model).
//
// Every failed attempt logs one `[generate_wrap_up]` JSON line (#166) — the
// status/body of an HTTP error, or the stop_reason, block types, raw tool
// input and per-field problems of an invalid response — so a failure is
// debuggable from the dashboard's function logs. The API key and the prompt
// (the user's day notes) are never logged; raw payloads are truncated.

import {
  type AiGeneratedFields,
  aiGeneratedFieldsToolSchema,
  describeAiFieldsProblems,
} from "./ai_fields.ts";
import type { TripData } from "./gather.ts";
import { inclusiveDayCount } from "./assemble.ts";

const ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages";
const ANTHROPIC_VERSION = "2023-06-01";
const MODEL = "claude-sonnet-5";
const MAX_TOKENS = 1024;
const MAX_ATTEMPTS = 2;

// Raw payloads in logs are cut to this many characters.
const MAX_LOGGED_CHARS = 4000;

export type FetchLike = typeof fetch;

// Where failure lines go — `console.error` in production, a capturing
// stub in tests.
export type LogLike = (line: string) => void;

export const LOG_PREFIX = "[generate_wrap_up]";

export function logEvent(
  log: LogLike,
  event: string,
  fields: Record<string, unknown>,
): void {
  log(`${LOG_PREFIX} ${JSON.stringify({ event, ...fields })}`);
}

export function truncate(text: string): string {
  return text.length <= MAX_LOGGED_CHARS
    ? text
    : `${text.slice(0, MAX_LOGGED_CHARS)}… [${
      text.length - MAX_LOGGED_CHARS
    } more chars]`;
}

// Why generation failed, as the 502 body's `code` (#166):
// - `ai_output_invalid`: Anthropic answered, but the tool input didn't
//   match the schema (e.g. truncated at max_tokens, a missing field).
// - `ai_upstream_error`: Anthropic returned a non-2xx status.
// - `ai_unreachable`: the request never got a response.
// When attempts fail differently, the last attempt's reason wins.
export type WrapUpGenerationErrorCode =
  | "ai_output_invalid"
  | "ai_upstream_error"
  | "ai_unreachable";

export class WrapUpGenerationError extends Error {
  constructor(
    readonly code: WrapUpGenerationErrorCode,
    readonly detail: string,
  ) {
    super(detail);
    this.name = "WrapUpGenerationError";
  }
}

function buildPrompt(tripData: TripData): string {
  const { trip, notes, latestAchievement } = tripData;
  const dayCount = inclusiveDayCount(trip.start_date, trip.end_date);

  return [
    "You are writing four short lines of copy for a travel memory wrap-up film. ",
    'Write warm, specific, second-person ("you") copy, grounded only in the ',
    "data below — never invent places, people, or events that aren't in it.\n\n",
    `Trip: ${
      JSON.stringify({
        name: trip.name,
        destination: trip.destination,
        vibes: trip.vibes,
      })
    }\n`,
    `Day count: ${dayCount ?? "unknown"}\n`,
    `Day notes, in chronological order: ${JSON.stringify(notes)}\n`,
    `Achievement earned during this trip, or null: ${
      JSON.stringify(latestAchievement)
    }\n\n`,
    "Produce: invitation_line2 (names the trip's type + destination in one ",
    'short line, e.g. "One long road."); bridges (exactly 3 short blocks, ',
    "max 2 lines each, splitting the day notes above into three roughly-even ",
    "chronological arcs — never describe a photograph, these frames never ",
    "show one); unlock_reason (one line on why the achievement was earned, or ",
    "null if no achievement was given above); keepsake_closing_quote (one ",
    "short, warm closing line).",
  ].join("");
}

interface ContentBlock {
  type: string;
  input?: unknown;
  text?: string;
}

export async function callAnthropic(
  tripData: TripData,
  apiKey: string,
  fetchImpl: FetchLike = fetch,
  log: LogLike = console.error,
): Promise<AiGeneratedFields> {
  let lastError = new WrapUpGenerationError(
    "ai_unreachable",
    "Anthropic call failed",
  );

  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
    let response: Response;
    try {
      response = await fetchImpl(ANTHROPIC_API_URL, {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "x-api-key": apiKey,
          "anthropic-version": ANTHROPIC_VERSION,
        },
        body: JSON.stringify({
          model: MODEL,
          max_tokens: MAX_TOKENS,
          messages: [{ role: "user", content: buildPrompt(tripData) }],
          tools: [aiGeneratedFieldsToolSchema],
          tool_choice: {
            type: "tool",
            name: aiGeneratedFieldsToolSchema.name,
          },
        }),
      });
    } catch (err) {
      const message = (err as Error).message;
      logEvent(log, "fetch_failed", { attempt, error: message });
      lastError = new WrapUpGenerationError(
        "ai_unreachable",
        `Anthropic request failed: ${message}`,
      );
      continue;
    }

    if (!response.ok) {
      const text = await response.text().catch(() => "");
      logEvent(log, "http_error", {
        attempt,
        status: response.status,
        body: truncate(text),
      });
      lastError = new WrapUpGenerationError(
        "ai_upstream_error",
        `Anthropic API error: ${response.status}`,
      );
      continue;
    }

    const rawText = await response.text();
    let body: { content?: ContentBlock[]; stop_reason?: string };
    try {
      body = JSON.parse(rawText);
    } catch {
      logEvent(log, "invalid_ai_output", {
        attempt,
        problems: ["response body is not JSON"],
        raw_body: truncate(rawText),
      });
      lastError = new WrapUpGenerationError(
        "ai_output_invalid",
        "Anthropic response body is not JSON",
      );
      continue;
    }

    const blocks = body.content ?? [];
    const toolUse = blocks.find((block) => block.type === "tool_use");
    const problems = toolUse
      ? describeAiFieldsProblems(toolUse.input)
      : ["no tool_use block in the response"];
    if (problems.length === 0) {
      return toolUse!.input as AiGeneratedFields;
    }

    const text = blocks
      .filter((block) => block.type === "text")
      .map((block) => block.text ?? "")
      .join("\n");
    logEvent(log, "invalid_ai_output", {
      attempt,
      stop_reason: body.stop_reason ?? null,
      block_types: blocks.map((block) => block.type),
      problems,
      raw_tool_input: toolUse
        ? truncate(JSON.stringify(toolUse.input) ?? "undefined")
        : null,
      raw_text: text ? truncate(text) : null,
    });
    lastError = new WrapUpGenerationError(
      "ai_output_invalid",
      `Anthropic response failed generated-fields validation (stop_reason: ${
        body.stop_reason ?? "unknown"
      }; ${problems.join("; ")})`,
    );
  }

  throw lastError;
}
