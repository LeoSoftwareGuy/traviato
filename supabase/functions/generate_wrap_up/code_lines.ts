// The classic film's four lines, from the user's own words (#463: no AI
// call). The classic film is the app's last safety net — it plays when a
// memory has no photo on any of its days, or when Sky Story fails while
// it plays — and its lines were the last AI-written text outside the
// director's pick calls.
//
// - invitation line 2: the destination, else the memory's name;
// - bridges: the best line of each third of the notes, in time order
//   (empty when a third has none — never filler);
// - unlock reason: null, so the achievement's own description plays;
// - closing quote: the best feeling among the notes' lines, else empty.
// Kept films keep their stored lines (handler.ts).

import type { TripData } from "./gather.ts";
import type { AiGeneratedFields } from "./ai_fields.ts";
import { isNegative, linesOf } from "./film_slots.ts";
import { isGeneric, isSensitive } from "./excerpts.ts";

// A bridge shows at most two short lines.
const MAX_BRIDGE_CHARS = 70;
const MAX_QUOTE_CHARS = 90;

function noteOrder(n: TripData["notes"][number]): number {
  const t = Date.parse(n.taken_at ?? n.created_at ?? "");
  return Number.isNaN(t) ? Date.parse(`${n.day_date}T12:00:00Z`) : t;
}

export function codeAiFields(tripData: TripData): AiGeneratedFields {
  const notes = tripData.notes.filter((n) => n.content.trim())
    .sort((a, b) =>
      a.day_date.localeCompare(b.day_date) || noteOrder(a) - noteOrder(b)
    );
  const used = new Set<string>();
  const best = (
    own: typeof notes,
    max: number,
    ok: (text: string) => boolean = () => true,
  ) => {
    const lines = own.flatMap((n) => linesOf(n, null)).filter((l) =>
      [...l.text].length <= max && !isGeneric(l.text) &&
      !isSensitive(l.text) && !used.has(l.text) && ok(l.text)
    ).sort((a, b) => b.score - a.score || a.k - b.k);
    const line = lines[0]?.text ?? "";
    if (line) used.add(line);
    return line;
  };
  const thirds = [0, 1, 2].map((k) =>
    notes.slice(
      Math.floor((k * notes.length) / 3),
      Math.floor(((k + 1) * notes.length) / 3),
    )
  );
  const bridges = thirds.map((own) => best(own, MAX_BRIDGE_CHARS)) as [
    string,
    string,
    string,
  ];
  const { destination, name } = tripData.trip;
  return {
    invitation_line2: destination?.trim() || name,
    bridges,
    unlock_reason: null,
    keepsake_closing_quote: best(
      notes,
      MAX_QUOTE_CHARS,
      (t) => !isNegative(t),
    ),
  };
}
