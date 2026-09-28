// The four genuinely-AI-generated fields of wrap_ups.content (#125). Kept
// separate from content.ts's full WrapUpContent so the Anthropic prompt only
// ever sees (and only ever has to produce) this small slice — everything
// else is assembled deterministically in assemble.ts.

export interface AiGeneratedFields {
  invitation_line2: string;
  bridges: [string, string, string];
  unlock_reason: string | null;
  keepsake_closing_quote: string;
}

export const aiGeneratedFieldsToolSchema = {
  name: "emit_wrap_up_copy",
  description:
    "Emit the four AI-written lines for this trip's wrap-up film as structured JSON.",
  input_schema: {
    type: "object",
    properties: {
      invitation_line2: {
        type: "string",
        description:
          'One short line naming the trip\'s type + destination, e.g. "One long road." Fraunces italic, reads under a computed "Five days." line — keep it terse.',
      },
      bridges: {
        type: "array",
        items: { type: "string" },
        minItems: 3,
        maxItems: 3,
        description:
          "Exactly 3 short text blocks (max 2 lines each, \\n-separated), one per arc of the trip's day notes in chronological order. Never describe a photograph — these frames never show one.",
      },
      unlock_reason: {
        type: ["string", "null"],
        description:
          "One line saying why this trip earned the given achievement. Null if no achievement was provided.",
      },
      keepsake_closing_quote: {
        type: "string",
        description:
          "One short, warm closing line for the trip's final keepsake card.",
      },
    },
    required: [
      "invitation_line2",
      "bridges",
      "unlock_reason",
      "keepsake_closing_quote",
    ],
  },
} as const;

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
