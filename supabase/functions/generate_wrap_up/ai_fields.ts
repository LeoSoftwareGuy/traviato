// The classic film's four lines (#125), stored as wrap_ups.ai_fields. AI-
// written until #463; since then a draft's come from the notes
// (code_lines.ts) and a kept film keeps the ones it was kept with.

export interface AiGeneratedFields {
  invitation_line2: string;
  bridges: [string, string, string];
  unlock_reason: string | null;
  keepsake_closing_quote: string;
}

function isString(v: unknown): v is string {
  return typeof v === "string";
}

function describeType(v: unknown): string {
  if (v === null) return "null";
  if (Array.isArray(v)) return `array(${v.length})`;
  return typeof v;
}

// Every way [data] misses the tool schema, one readable line per field —
// empty when it's valid. Logged on a failed generation (#166) so the
// dashboard says *which* field was wrong, not just that one was.
export function describeAiFieldsProblems(data: unknown): string[] {
  if (typeof data !== "object" || data === null || Array.isArray(data)) {
    return [`input: expected an object, got ${describeType(data)}`];
  }
  const d = data as Record<string, unknown>;
  const problems: string[] = [];

  if (!isString(d.invitation_line2)) {
    problems.push(
      `invitation_line2: expected string, got ${
        describeType(d.invitation_line2)
      }`,
    );
  }
  if (!Array.isArray(d.bridges)) {
    problems.push(
      `bridges: expected exactly 3 strings, got ${describeType(d.bridges)}`,
    );
  } else if (d.bridges.length !== 3) {
    problems.push(
      `bridges: expected exactly 3 strings, got ${d.bridges.length}`,
    );
  } else if (!d.bridges.every(isString)) {
    problems.push(
      `bridges: expected strings, got [${
        d.bridges.map(describeType).join(", ")
      }]`,
    );
  }
  if (d.unlock_reason !== null && !isString(d.unlock_reason)) {
    problems.push(
      `unlock_reason: expected string or null, got ${
        describeType(d.unlock_reason)
      }`,
    );
  }
  if (!isString(d.keepsake_closing_quote)) {
    problems.push(
      `keepsake_closing_quote: expected string, got ${
        describeType(d.keepsake_closing_quote)
      }`,
    );
  }
  return problems;
}

export function validateAiGeneratedFields(
  data: unknown,
): data is AiGeneratedFields {
  return describeAiFieldsProblems(data).length === 0;
}
