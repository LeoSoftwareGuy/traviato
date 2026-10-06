// Fingerprint of exactly what the AI writes from (#187): trip name,
// destination, vibes, day notes and the earned achievement. Photos, dates,
// stats and the cut are deliberately absent — those are rebuilt for free
// from current data, so changing them must never cost an Anthropic call.

import type { TripData } from "./gather.ts";

export async function computeAiInputHash(tripData: TripData): Promise<string> {
  const { trip, notes, latestAchievement } = tripData;
  const canonical = JSON.stringify({
    name: trip.name,
    destination: trip.destination,
    vibes: trip.vibes,
    notes: notes.map((n) => [n.day_date, n.content]),
    achievement: latestAchievement?.code ?? null,
  });
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(canonical),
  );
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}
