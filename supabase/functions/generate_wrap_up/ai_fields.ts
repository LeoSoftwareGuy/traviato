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

export function validateAiGeneratedFields(
  data: unknown,
): data is AiGeneratedFields {
  if (typeof data !== "object" || data === null) return false;
  const d = data as Record<string, unknown>;

  if (!isString(d.invitation_line2)) return false;
  if (
    !Array.isArray(d.bridges) || d.bridges.length !== 3 ||
    !d.bridges.every(isString)
  ) {
    return false;
  }
  if (d.unlock_reason !== null && !isString(d.unlock_reason)) return false;
  if (!isString(d.keepsake_closing_quote)) return false;

  return true;
}
