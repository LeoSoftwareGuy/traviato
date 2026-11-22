// content.neon_night (#454): code's skeleton, the words picked for its
// slots (the director's picks where they hold, else code's), fitted to
// the film's length.
//
// A Neon film may run up to the longest film (#448: 75 s, a hard max);
// past that the skeleton gives up, in order: words per moment (3 → 2), a
// chapter's two moments as one (the last chapter first), the Plan scene,
// card zooms (2 → 1), words per moment (2 → 1), short card and moment
// lines where a chapter has one, then moments without their note lines,
// the last chapter's first (#456: a moment keeps its best caption). Never a chapter, the Note scene or a chapter's line — a
// card line is never cut for length — nor a moment's last caption. The app holds the
// film to 75 s on its own timeline as well (NnFit).

import { dayTitleFor } from "./film_slots.ts";
import type { TripData } from "./gather.ts";
import { decorativePhotos } from "./decorative.ts";
import { firstNameOf } from "./sky_story.ts";
import { WRAP_UP_LIMITS } from "./wrap_up_limits.ts";
import {
  filmSecondsOf,
  nnFilmBeats,
  nnFitsWithin,
  type NnShapeChapter,
} from "./film_length.ts";
import {
  MAX_NN_PHOTOS,
  type NeonNightContent,
  type NeonNightContentExcerpt,
  NN_VERSION,
  nnPhotos,
  planRows,
  tidyEnd,
} from "./neon_night.ts";
import {
  buildNeonSkeleton,
  buildNeonSlots,
  fullShape,
  namesOf,
  type NnPicks,
  type NnShape,
  type NnSkeletonChapter,
  type NnSlot,
  type NnSlotResult,
  resolveNeonSlots,
  writtenLanguage,
  zoomedCaptions,
} from "./neon_slots.ts";

// How far under its length the estimate keeps a film (#454).
export const NN_ESTIMATE_MARGIN_SECONDS = 1;

// One slot as the Plan inspector shows it (#454): its candidates, the
// director's pick, what plays and why.
export interface NnSlotReport {
  slot: string;
  candidates: { id: string; text: string; score: number }[];
  pick: { ids: string[]; free_title: string | null } | null;
  chosen: { id: string; text: string }[];
  source: NnSlotResult["source"];
  reason: string;
}

export interface NeonNightFilm {
  content: NeonNightContent;
  chapters: NnSkeletonChapter[];
  slots: NnSlot[];
  report: NnSlotReport[];
  shape: NnShape;
}

// The skeleton for [shape], its slots and their words.
function cut(
  tripData: TripData,
  picks: NnPicks | null,
  heroScores: Readonly<Record<string, number>>,
  shape: NnShape,
) {
  const chapters = buildNeonSkeleton(tripData, heroScores, shape);
  const slots = buildNeonSlots(tripData, chapters, shape);
  const byId = new Map(tripData.photos.map((p) => [p.id, p]));
  const moments = new Map(
    chapters.flatMap((c, i) =>
      c.moments.map((m, j) => [`ch${i + 1}.m${j + 1}`, m] as const)
    ),
  );
  const resolved = resolveNeonSlots(slots, picks, {
    shownCaptions: chapters.flatMap((c) =>
      zoomedCaptions(c.card, byId, heroScores, shape.cardZooms)
    ),
    language: writtenLanguage(tripData),
    names: namesOf(tripData),
    moments,
    dayTitle: dayTitleFor(tripData, chapters),
    shortCards: shape.shortCards,
    quietMoments: new Set(
      [...moments.keys()].reverse().slice(0, shape.quietMoments),
    ),
    // Always picks first, then the best shot (#456).
    captionRank: (id) =>
      (byId.get(id)?.use_in_wrap_up === true ? 100 : 0) +
      (heroScores[id] ?? 0),
  });
  const text = (slot: string) => resolved.get(slot)?.chosen[0]?.text ?? null;
  const beats = nnFilmBeats(
    chapters.map((c, i): NnShapeChapter => ({
      photos: c.card.length || c.photos.length,
      zooms: shape.cardZooms,
      cardCaptions: c.card.map((id) => byId.get(id)?.caption?.trim() || null),
      cardHeroScores: c.card.map((id) => heroScores[id] ?? null),
      cardLine: text(`ch${i + 1}.card`),
      moments: c.moments.map((m, j) => ({
        type: m.type,
        photos: m.photo_ids.length,
        lines: (resolved.get(`ch${i + 1}.m${j + 1}`)?.chosen ?? []).map((w) =>
          w.text
        ),
      })),
    })),
    shape.showsPlan,
    text("note") ?? false,
  );
  return { chapters, slots, resolved, beats, byId };
}

// The next smaller shape, or null when nothing is left to give up.
function smaller(
  shape: NnShape,
  chapters: readonly NnSkeletonChapter[],
): NnShape | null {
  if (shape.maxWords > 2) return { ...shape, maxWords: shape.maxWords - 1 };
  if (chapters.some((c) => c.moments.length > 1)) {
    return { ...shape, merged: shape.merged + 1 };
  }
  if (shape.showsPlan) return { ...shape, showsPlan: false };
  if (shape.cardZooms > 1) return { ...shape, cardZooms: 1 };
  if (shape.maxWords > 1) return { ...shape, maxWords: 1 };
  if (!shape.shortCards) return { ...shape, shortCards: true };
  const moments = chapters.reduce((n, c) => n + c.moments.length, 0);
  if (shape.quietMoments < moments) {
    return { ...shape, quietMoments: shape.quietMoments + 1 };
  }
  return null;
}

// The Neon Night film of [tripData] with [picks] (null: code picks every
// slot).
export function neonNightFilm(
  tripData: TripData,
  picks: NnPicks | null,
  heroScores: Readonly<Record<string, number>> = {},
): NeonNightFilm {
  const plan = planRows(tripData);
  // A second under the longest film: the estimate can run a little short
  // of what the player lays out (#454: the real ADE estimated at 75 s
  // played 75.5 s).
  const limit = Math.max(
    filmSecondsOf(tripData),
    WRAP_UP_LIMITS.longestFilmSeconds,
  ) - NN_ESTIMATE_MARGIN_SECONDS;
  let shape = fullShape(plan.length > 0);
  let film = cut(tripData, picks, heroScores, shape);
  while (!nnFitsWithin(film.beats, limit)) {
    const next = smaller(shape, film.chapters);
    if (!next) break;
    shape = next;
    film = cut(tripData, picks, heroScores, shape);
  }
  const { chapters, slots, resolved, byId } = film;
  const result = (slot: string) => resolved.get(slot);
  const all = nnPhotos(tripData);
  const notes = [...tripData.notes].sort((a, b) =>
    a.day_date < b.day_date ? -1 : a.day_date > b.day_date ? 1 : 0
  );

  const content: NeonNightContent["chapters"] = chapters.map((c, i) => {
    const ch = `ch${i + 1}`;
    const card = result(`${ch}.card`);
    const momentWords = c.moments.map((_, j) =>
      result(`${ch}.m${j + 1}`)?.chosen ?? []
    );
    const excerpts: NeonNightContentExcerpt[] = [
      ...(card?.chosen ?? []).map((w) => ({ w, source: card!.source })),
      ...momentWords.flatMap((ws, j) =>
        ws.map((w) => ({ w, source: result(`${ch}.m${j + 1}`)!.source }))
      ),
    ].filter(({ w }) => w.note_id !== null).map(({ w, source }) => ({
      text: w.text,
      note_id: w.note_id!,
      photo_id: w.photo_id,
      source: source === "director" ? "director" : "code",
      score: w.score,
    }));
    const shown = new Set(excerpts.map((e) => e.text));
    const slot = slots.find((s) => s.slot === `${ch}.card`);
    return {
      title: result(`${ch}.title`)?.chosen[0]?.text ?? "",
      photos: c.photos.map((p) => ({
        id: p.id,
        taken_at: p.taken_at ?? p.created_at,
        // The user's own words on the photo (#387).
        caption: p.caption?.trim() || null,
        // How good a shot it is (#446, 1–5; null = not analysed).
        hero_score: heroScores[p.id] ?? null,
      })),
      card_photo_ids: c.card,
      note: tidyEnd(card?.chosen[0]?.text ?? null),
      card_zooms: shape.cardZooms,
      excerpts,
      days: c.days,
      rejected_excerpts: (slot?.candidates ?? []).filter((x) =>
        !shown.has(x.text)
      ).slice(0, 5).map((x) => ({ text: x.text, score: x.score })),
      moments: c.moments.map((m, j) => ({
        type: m.type,
        photo_ids: m.photo_ids,
        // The words it shows (#448), each on its photo, in its order.
        words: [...momentWords[j]].sort((a, b) =>
          m.photo_ids.indexOf(a.photo_id!) - m.photo_ids.indexOf(b.photo_id!)
        ).map((w) => ({ photo_id: w.photo_id!, text: tidyEnd(w.text)! })),
        place: m.type === "split"
          ? m.photo_ids.map((id) => byId.get(id)?.place_text?.trim())
            .find((place) => place) || null
          : null,
      })),
    };
  });

  const note = result("note")?.chosen[0] ?? null;
  const noteIndex = note ? notes.findIndex((n) => n.id === note.note_id) : -1;
  const film_ = chapters.flatMap((c) => c.photos);
  const neon: NeonNightContent = {
    nn_version: NN_VERSION,
    title: tripData.trip.name,
    start_date: tripData.trip.start_date,
    place: tripData.trip.destination?.trim() || null,
    plan: shape.showsPlan ? plan : [],
    chapters: content,
    note: note && noteIndex >= 0
      ? {
        text: tidyEnd(note.text)!,
        number: noteIndex + 1,
        written_at: notes[noteIndex].created_at ?? null,
        photo_id: note.photo_id,
      }
      : null,
    headline: result("headline")?.chosen[0]?.text ?? null,
    first_name: firstNameOf(tripData.username),
    totals: {
      photos: all.length,
      notes: notes.filter((n) => n.content.trim()).length,
      ticks: plan.filter((r) => r.done).length,
      moments: all.length,
    },
    // The heart is decoration: the photos without a scene of their own
    // (#378), Always picks only to top it up.
    heart_photo_ids: decorativePhotos(
      film_,
      new Set([
        ...chapters.flatMap((c) => [
          ...c.card,
          ...c.moments.flatMap((m) => m.photo_ids),
        ]),
        ...(note?.photo_id ? [note.photo_id] : []),
      ]),
      MAX_NN_PHOTOS,
    ).map((p) => p.id),
  };

  const report: NnSlotReport[] = slots.map((s) => {
    const r = resolved.get(s.slot)!;
    const pick = picks?.[s.slot];
    return {
      slot: s.slot,
      candidates: s.candidates.map((c) => ({
        id: c.id,
        text: c.text,
        score: c.score,
      })),
      pick: pick
        ? { ids: pick.ids, free_title: pick.free_title ?? null }
        : null,
      chosen: r.chosen.map((c) => ({ id: c.id, text: c.text })),
      source: r.source,
      reason: r.reason,
    };
  });
  return { content: neon, chapters, slots, report, shape };
}

export function buildNeonNightContent(
  tripData: TripData,
  picks: NnPicks | null = null,
  heroScores: Readonly<Record<string, number>> = {},
): NeonNightContent {
  return neonNightFilm(tripData, picks, heroScores).content;
}
