// Shared by every Anthropic call (anthropic_tool.ts): the log lines and the
// error a failed call throws (#166). The four AI-written lines this module
// once fetched come from the notes since #463 (code_lines.ts).

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
