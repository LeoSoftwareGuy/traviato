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

import {
  type AiGeneratedFields,
  aiGeneratedFieldsToolSchema,
  validateAiGeneratedFields,
} from "./ai_fields.ts";
import type { TripData } from "./gather.ts";
import { inclusiveDayCount } from "./assemble.ts";

const ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages";
const ANTHROPIC_VERSION = "2023-06-01";
const MODEL = "claude-sonnet-5";
const MAX_TOKENS = 1024;
const MAX_ATTEMPTS = 2;

export type FetchLike = typeof fetch;

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

export async function callAnthropic(
  tripData: TripData,
  apiKey: string,
  fetchImpl: FetchLike = fetch,
): Promise<AiGeneratedFields> {
  let lastError = "Anthropic call failed";

  for (let attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
    const response = await fetchImpl(ANTHROPIC_API_URL, {
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
        tool_choice: { type: "tool", name: aiGeneratedFieldsToolSchema.name },
      }),
    });

    if (!response.ok) {
      lastError = `Anthropic API error: ${response.status} ${await response
        .text()}`;
      continue;
    }

    const body = await response.json();
    const toolUse = (body.content ?? []).find(
      (block: { type: string }) => block.type === "tool_use",
    );
    if (toolUse && validateAiGeneratedFields(toolUse.input)) {
      return toolUse.input;
    }
    lastError = "Anthropic response failed generated-fields validation";
  }

  throw new Error(lastError);
}
