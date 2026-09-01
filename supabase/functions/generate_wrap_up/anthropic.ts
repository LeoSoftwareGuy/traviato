// Calls the Anthropic API for wrap-up creative direction, forcing structured
// output via a tool call (screenplayToolSchema) rather than parsing free-form
// JSON. Retries once on malformed output before giving up.
//
// Model is claude-sonnet-5 — wrap-up playback is the app's headline feature,
// so narrative quality wins over the lower cost of a smaller model here.

import { screenplayToolSchema, validateScreenplay, type Screenplay } from "./screenplay.ts";
import type { TripData } from "./gather.ts";

const ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages";
const ANTHROPIC_VERSION = "2023-06-01";
const MODEL = "claude-sonnet-5";
const MAX_TOKENS = 4096;
const MAX_ATTEMPTS = 2;

export type FetchLike = typeof fetch;

function buildPrompt(tripData: TripData): string {
  return [
    "You are writing the screenplay for a travel memory wrap-up video. ",
    'Write a warm, specific, second-person ("you") narrative about this trip, ',
    "grounded only in the data below — never invent places, people, or events ",
    "that aren't in it. Keep each photo_beats narrative to 1-2 sentences.\n\n",
    `Trip: ${JSON.stringify(tripData.trip)}\n`,
    `Quests: ${JSON.stringify(tripData.quests)}\n`,
    `Day notes: ${JSON.stringify(tripData.notes)}\n`,
    `Photos (metadata only, no images): ${JSON.stringify(tripData.photos)}\n`,
    `Most recently earned achievement, or null: ${JSON.stringify(tripData.latestAchievement)}\n`,
  ].join("");
}

export async function callAnthropic(
  tripData: TripData,
  apiKey: string,
  fetchImpl: FetchLike = fetch,
): Promise<Screenplay> {
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
        tools: [screenplayToolSchema],
        tool_choice: { type: "tool", name: screenplayToolSchema.name },
      }),
    });

    if (!response.ok) {
      lastError = `Anthropic API error: ${response.status} ${await response.text()}`;
      continue;
    }

    const body = await response.json();
    const toolUse = (body.content ?? []).find(
      (block: { type: string }) => block.type === "tool_use",
    );
    if (toolUse && validateScreenplay(toolUse.input)) {
      return toolUse.input;
    }
    lastError = "Anthropic response failed screenplay validation";
  }

  throw new Error(lastError);
}
