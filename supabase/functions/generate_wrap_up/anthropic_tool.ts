// One forced-tool Anthropic request for the director (#328): photo analysis
// and the film plan. Unlike anthropic.ts's callAnthropic (the 4 AI lines),
// this does a single attempt and hands back the raw tool input plus token
// usage — the callers validate the input themselves and decide whether to
// retry, because a retry of the plan carries the validation problems back
// to the model.
//
// Same logging rules as anthropic.ts (#166): one `[generate_wrap_up]` line
// per failure, never the API key, never the prompt (notes, photos).

import {
  type FetchLike,
  logEvent,
  type LogLike,
  truncate,
  WrapUpGenerationError,
} from "./anthropic.ts";

const ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages";
const ANTHROPIC_VERSION = "2023-06-01";

export interface TokenUsage {
  input_tokens: number;
  output_tokens: number;
}

export interface ToolDefinition {
  name: string;
  description: string;
  input_schema: Record<string, unknown>;
}

export interface ToolCallRequest {
  apiKey: string;
  model: string;
  maxTokens: number;
  system: string;
  // A plain prompt, or content blocks (text + images).
  content: string | unknown[];
  tool: ToolDefinition;
  // What the log lines call this request (`analysis`, `plan`).
  label: string;
  fetchImpl?: FetchLike;
  log?: LogLike;
}

export interface ToolCallResult {
  input: unknown;
  usage: TokenUsage;
  stopReason: string | null;
}

interface ContentBlock {
  type: string;
  input?: unknown;
}

function readUsage(body: Record<string, unknown>): TokenUsage {
  const usage = (body.usage ?? {}) as Record<string, unknown>;
  const n = (v: unknown) => (typeof v === "number" ? v : 0);
  return {
    // Cached prompt tokens are billed too; count them as input.
    input_tokens: n(usage.input_tokens) +
      n(usage.cache_creation_input_tokens) + n(usage.cache_read_input_tokens),
    output_tokens: n(usage.output_tokens),
  };
}

export async function callAnthropicTool(
  request: ToolCallRequest,
): Promise<ToolCallResult> {
  const fetchImpl = request.fetchImpl ?? fetch;
  const log = request.log ?? console.error;

  let response: Response;
  try {
    response = await fetchImpl(ANTHROPIC_API_URL, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-api-key": request.apiKey,
        "anthropic-version": ANTHROPIC_VERSION,
      },
      body: JSON.stringify({
        model: request.model,
        max_tokens: request.maxTokens,
        system: request.system,
        messages: [{ role: "user", content: request.content }],
        tools: [request.tool],
        tool_choice: { type: "tool", name: request.tool.name },
      }),
    });
  } catch (err) {
    const message = (err as Error).message;
    logEvent(log, "director_fetch_failed", {
      call: request.label,
      error: message,
    });
    throw new WrapUpGenerationError(
      "ai_unreachable",
      `Anthropic request failed: ${message}`,
    );
  }

  if (!response.ok) {
    const text = await response.text().catch(() => "");
    logEvent(log, "director_http_error", {
      call: request.label,
      status: response.status,
      body: truncate(text),
    });
    throw new WrapUpGenerationError(
      "ai_upstream_error",
      `Anthropic API error: ${response.status}`,
    );
  }

  const rawText = await response.text();
  let body: Record<string, unknown>;
  try {
    body = JSON.parse(rawText);
  } catch {
    logEvent(log, "director_invalid_output", {
      call: request.label,
      problems: ["response body is not JSON"],
      raw_body: truncate(rawText),
    });
    throw new WrapUpGenerationError(
      "ai_output_invalid",
      "Anthropic response body is not JSON",
    );
  }

  const usage = readUsage(body);
  const stopReason = typeof body.stop_reason === "string"
    ? body.stop_reason
    : null;
  const blocks = (body.content ?? []) as ContentBlock[];
  const toolUse = blocks.find((block) => block.type === "tool_use");
  if (!toolUse) {
    logEvent(log, "director_invalid_output", {
      call: request.label,
      stop_reason: stopReason,
      block_types: blocks.map((block) => block.type),
      problems: ["no tool_use block in the response"],
    });
    throw new WrapUpGenerationError(
      "ai_output_invalid",
      `no tool_use block (stop_reason: ${stopReason ?? "unknown"})`,
    );
  }
  return { input: toolUse.input, usage, stopReason };
}
