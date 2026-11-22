// The Golden Vows film (#458): code's album (gv_skeleton.ts) with the
// words picked for its slots (gv_slots.ts), as content.golden_vows — the
// shape the app has read since #346.
//
// Length: the app plays the album toward content.film_seconds by how long
// its pages lie open (GoldenVowsTimeline.forStory, 0.7–1.8×). Past the
// longest film (75 s) even at its quickest, the album gives way in this
// order (#458): a main page's note line → a shorter clause of the same
// note → no note; the carousel; the packing card; main pages down to 2
// (uncaptioned, not Always, weakest first); then the app shortens the
// chapter pages, never below their title's reading time (GvFit). A short
// album still past its target at its quickest also gives up the carousel,
// then the packing card. Never a chapter, a note (for the target), the
// title page, the heart or a caption.

import type { TripData } from "./gather.ts";
import { inclusiveDayCount } from "./assemble.ts";
import { decorativePhotos } from "./decorative.ts";
import { filmSecondsOf, readingSeconds } from "./film_length.ts";
import type { WrapUpLanguage } from "./language.ts";
import { WRAP_UP_LIMITS } from "./wrap_up_limits.ts";
import { namesOf, type SlotPicks } from "./film_slots.ts";
import {
  type GoldenVowsContent,
  GV_VERSION,
  gvPhotos,
  MAX_GV_HEART,
  MIN_GV_HEROES,
  packingOf,
} from "./golden_vows.ts";
import {
  buildGvSkeleton,
  type GvOccasionTrigger,
  type GvSkeleton,
} from "./gv_skeleton.ts";
import {
  buildGvSlots,
  gvChapterLine,
  gvDayTitle,
  gvLanguage,
  type GvSlot,
  type GvSlotResult,
  gvUnlistedNotes,
  resolveGvSlots,
} from "./gv_slots.ts";
import { sameLine } from "./neon_night.ts";

// The album's clock (golden_vows_timeline.dart): the scenes every album
// plays, and each page's dwell + turn.
const GV_TURN = 1.25;
const GV_FIXED = 5.4 + 1.0 + GV_TURN + 7.6 + 1.0 + 9.05;
const GV_PACKING = 6.5;
const GV_HERO_DWELL = 3.0;
const GV_CHAPTER_DWELL = 3.4;
const GV_CAROUSEL_DWELL = 6.0;
// How far the app shrinks the pages' dwell for a short film.
export const GV_MIN_DWELL_SCALE = 0.7;
// How far past its target a short album may run before it gives up its
// carousel, then its packing card (#458).
export const GV_TARGET_SLACK_SECONDS = 1.5;
// How far under the longest film the estimate keeps the album (#454's
// margin): the phone lays notes out with its own fonts.
export const GV_ESTIMATE_MARGIN_SECONDS = 1;

// The album's length at [scale] (golden_vows_timeline.dart): a main
// page lies open its dwell or as long as its note needs.
export function gvSecondsAt(content: GoldenVowsContent, scale: number): number {
  const hero = (note: string | null) =>
    Math.max(
      GV_HERO_DWELL * scale,
      note?.trim() ? readingSeconds(note) - GV_TURN : 0,
    ) + GV_TURN;
  return GV_FIXED + (content.packing?.items.length ? GV_PACKING : 0) +
    content.heroes.reduce((s, h) => s + hero(h.note), 0) +
    content.chapters.length * (GV_CHAPTER_DWELL * scale + GV_TURN) +
    (content.carousel ? GV_CAROUSEL_DWELL * scale + GV_TURN : 0);
}

// As short as the app can play it.
export const gvShortestSeconds = (content: GoldenVowsContent) =>
  gvSecondsAt(content, GV_MIN_DWELL_SCALE);

// One slot as the Plan inspector shows it (#458, Neon's NnSlotReport).
export interface GvSlotReport {
  slot: string;
  candidates: { id: string; text: string; score: number }[];
  pick: { ids: string[]; free_title: string | null } | null;
  chosen: { id: string; text: string }[];
  source: GvSlotResult["source"];
  reason: string;
}

export interface GoldenVowsFilm {
  content: GoldenVowsContent;
  skeleton: GvSkeleton;
  slots: GvSlot[];
  report: GvSlotReport[];
  // What the album gave up for its length, in order.
  trims: string[];
  // "N / M photos shown" on pages (the heart holds them all).
  shown: { pages: number; photos: number };
  // Notes on no main page's list, and why.
  unlisted: { note_id: string; text: string; reason: string }[];
  trigger: GvOccasionTrigger | null;
}

export interface GvFilmOptions {
  heroScores?: Readonly<Record<string, number>>;
  orientations?: Readonly<Record<string, string>>;
  // Photo summaries (photo_analysis): what can show a wedding.
  summaries?: ReadonlyMap<string, string>;
  language?: WrapUpLanguage;
}

// The Golden Vows film of [tripData] with [picks] (null: code picks every
// slot).
export function goldenVowsFilm(
  tripData: TripData,
  picks: SlotPicks | null,
  options: GvFilmOptions = {},
): GoldenVowsFilm {
  const heroScores = options.heroScores ?? {};
  const skeleton = buildGvSkeleton(
    tripData,
    heroScores,
    options.orientations ?? {},
    options.summaries ?? new Map(),
  );
  const appLanguage = options.language ?? "en";
  const language = gvLanguage(tripData, appLanguage);
  const slots = buildGvSlots(tripData, skeleton, appLanguage);
  const utcOffset = tripData.utc_offset_minutes ?? 0;
  const resolved = resolveGvSlots(slots, picks, {
    language,
    names: namesOf(tripData),
    dayTitle: (i) => gvDayTitle(tripData, skeleton, i, language),
    shown: [tripData.trip.name, tripData.trip.destination ?? ""],
  });
  const text = (slot: string) => resolved.get(slot)?.chosen[0]?.text ?? null;
  const byId = new Map(tripData.photos.map((p) => [p.id, p]));

  const heroes = skeleton.mains.map((m, k) => {
    const photo = byId.get(m.photo_id)!;
    const captioned = !!photo.caption?.trim();
    return {
      photo_id: photo.id,
      label: text(`main${k + 1}.label`) ?? "",
      // A captioned page shows its caption, never the time (#458).
      taken_at: captioned ? null : photo.taken_at,
      note: text(`main${k + 1}.note`),
    };
  });
  const chapters = skeleton.chapters.map((c, i) => ({
    title: text(`ch${i + 1}.title`) ??
      gvDayTitle(tripData, skeleton, i, language),
    line: gvChapterLine(c.photos, i, language, utcOffset),
    photo_ids: [...c.prints],
    layout: c.layout,
  }));
  const carouselTitle = text("carousel.title");
  const { start_date, end_date } = tripData.trip;
  const photos = gvPhotos(tripData);
  let content: GoldenVowsContent = {
    gv_version: GV_VERSION,
    occasion: skeleton.occasion,
    occasion_line: text("occasion") ?? "",
    names: tripData.trip.name,
    start_date,
    end_date,
    day_count: inclusiveDayCount(start_date, end_date) ?? 1,
    place: tripData.trip.destination?.trim() || null,
    packing: packingOf(tripData),
    heroes,
    chapters,
    carousel: skeleton.carousel.length > 0 && carouselTitle
      ? {
        title: carouselTitle,
        line: carouselLine(carouselTitle, language),
        photo_ids: [...skeleton.carousel],
      }
      : null,
    // Every photo of the film forms the heart, shown ones too (#434).
    heart_photo_ids: decorativePhotos(photos, new Set(), MAX_GV_HEART)
      .map((p) => p.id),
    moment_count: photos.length,
    end_line: text("finale") ?? "",
  };

  const fitted = fitToLongest(content, skeleton, slots, tripData, heroScores);
  content = fitted.content;
  const shownIds = new Set([
    ...content.heroes.map((h) => h.photo_id),
    ...content.chapters.flatMap((c) => c.photo_ids),
    ...(content.carousel?.photo_ids ?? []),
  ]);
  return {
    content,
    skeleton,
    slots,
    report: slots.map((s) => {
      const r = resolved.get(s.slot)!;
      const pick = s.fixed ? undefined : picks?.[s.slot];
      // A trimmed note shows what plays now.
      const played = fitted.notes.get(s.slot);
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
        chosen: played === undefined
          ? r.chosen.map((c) => ({ id: c.id, text: c.text }))
          : played
          ? [{ id: played.id, text: played.text }]
          : [],
        source: r.source,
        reason: played === undefined
          ? r.reason
          : `${r.reason}; for length: ${
            played ? "a shorter clause" : "no note"
          }`,
      };
    }),
    trims: fitted.trims,
    shown: { pages: shownIds.size, photos: photos.length },
    unlisted: gvUnlistedNotes(tripData, skeleton, slots),
    trigger: skeleton.trigger,
  };
}

// The carousel's eyebrow: a neutral line, never its title.
function carouselLine(title: string, language: "ru" | "en"): string {
  const lines = language === "ru"
    ? ["Каждый момент", "Ещё немного нас"]
    : ["Every little moment", "A little more of us"];
  return lines.find((l) => !sameLine(l, title)) ?? lines[1];
}

// [content] held to the longest film at its quickest (#458's order).
function fitToLongest(
  start: GoldenVowsContent,
  skeleton: GvSkeleton,
  slots: readonly GvSlot[],
  tripData: TripData,
  heroScores: Readonly<Record<string, number>>,
): {
  content: GoldenVowsContent;
  trims: string[];
  // main slot → the note now played (null: none), for trimmed notes.
  notes: Map<string, { id: string; text: string } | null>;
} {
  const limit = Math.max(
    filmSecondsOf(tripData),
    WRAP_UP_LIMITS.longestFilmSeconds,
  ) - GV_ESTIMATE_MARGIN_SECONDS;
  const content = structuredClone(start);
  const trims: string[] = [];
  const notes = new Map<string, { id: string; text: string } | null>();
  const fits = () => gvShortestSeconds(content) <= limit;
  const byId = new Map(tripData.photos.map((p) => [p.id, p]));
  const captioned = (id: string) => !!byId.get(id)?.caption?.trim();
  const slotOf = new Map(slots.map((s) => [s.slot, s]));
  const mainSlot = (photoId: string) =>
    `main${skeleton.mains.findIndex((m) => m.photo_id === photoId) + 1}.note`;
  // Uncaptioned notes, longest first.
  const trimmable = () =>
    content.heroes.filter((h) => h.note && !captioned(h.photo_id))
      .sort((a, b) => [...b.note!].length - [...a.note!].length);

  // 1. Note lines → a shorter clause of the same note.
  for (const hero of trimmable()) {
    if (fits()) break;
    const slot = slotOf.get(mainSlot(hero.photo_id));
    const now = slot?.candidates.find((c) => c.text === hero.note);
    // Never words the album already shows (#454: no words twice).
    const shown = [
      content.occasion_line,
      content.end_line,
      ...content.heroes.flatMap((h) => [h.label, h.note ?? ""]),
      ...content.chapters.map((c) => c.title),
    ];
    const shorter = slot?.candidates.filter((c) =>
      c.note_id === now?.note_id &&
      [...c.text].length < [...hero.note!].length &&
      !shown.some((t) => sameLine(t, c.text))
    ).sort((a, b) => b.score - a.score)[0];
    if (!slot || !shorter) continue;
    trims.push(`${slot.slot}: a shorter clause of its note`);
    hero.note = shorter.text;
    notes.set(slot.slot, { id: shorter.id, text: shorter.text });
  }
  // 2. … then no note.
  for (const hero of trimmable()) {
    if (fits()) break;
    const slot = mainSlot(hero.photo_id);
    trims.push(`${slot}: no note`);
    hero.note = null;
    notes.set(slot, null);
  }
  // 3. The carousel; 4. the packing card.
  if (!fits() && content.carousel) {
    content.carousel = null;
    trims.push("no carousel");
  }
  if (!fits() && content.packing) {
    content.packing = null;
    trims.push("no packing card");
  }
  // 5. Main pages down to 2: uncaptioned, not Always, weakest first.
  const droppable = content.heroes.filter((h) => !captioned(h.photo_id))
    .sort((a, b) =>
      Number(byId.get(a.photo_id)?.use_in_wrap_up === true) -
        Number(byId.get(b.photo_id)?.use_in_wrap_up === true) ||
      (heroScores[a.photo_id] ?? 0) - (heroScores[b.photo_id] ?? 0)
    );
  for (const hero of droppable) {
    if (fits() || content.heroes.length <= MIN_GV_HEROES) break;
    content.heroes = content.heroes.filter((h) => h !== hero);
    trims.push(`${mainSlot(hero.photo_id).replace(".note", "")}: left out`);
  }
  // 6. The app shortens the chapter pages (GvFit).
  if (!fits()) trims.push("chapter pages shortened in the app");
  // A short album (#458): still past its target at its quickest, it
  // gives up the carousel, then the packing card — the heart still shows
  // every photo. Never a chapter, a note, a caption, the title page or
  // the heart; a long album (target 75 s) never gets here.
  const target = filmSecondsOf(tripData);
  const over = () =>
    gvShortestSeconds(content) > target + GV_TARGET_SLACK_SECONDS;
  if (over() && content.carousel) {
    content.carousel = null;
    trims.push("no carousel (for the target)");
  }
  if (over() && content.packing) {
    content.packing = null;
    trims.push("no packing card (for the target)");
  }
  return { content, trims, notes };
}
