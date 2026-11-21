// How each film sizes its scenes to the film's length (#434). The length
// comes from the film's photos (`filmSeconds`); the app fits its timeline
// to `content.film_seconds`, stretching or shrinking within each scene's
// range, and the shapes here keep what the edge function builds within
// reach of it. The scene lengths mirror the app's timelines
// (sky_story_timeline.dart, golden_vows_timeline.dart, neon_night_*).

import {
  filmSeconds as limitSeconds,
  WRAP_UP_LIMITS,
} from "./wrap_up_limits.ts";

let lengthRuleOn = true;

// Tests of other rules turn the length rule off for their module (each
// test module runs on its own): every film then plays at its longest, as
// before #434.
export function useFilmLengthRuleForTests(on: boolean): void {
  lengthRuleOn = on;
}

// Whether films size themselves to their length (false only in tests of
// other rules).
export function isFilmLengthRuleOn(): boolean {
  return lengthRuleOn;
}

// How long a film of [photos] film photos plays, s (`filmSeconds`).
export function filmSeconds(photos: number): number {
  return lengthRuleOn
    ? limitSeconds(photos)
    : WRAP_UP_LIMITS.longestFilmSeconds;
}

// The photos a film counts for its length: every photo not left out
// (after `withFilmPhotos`, at most 60).
export function filmPhotoCount(
  tripData: { photos: readonly { use_in_wrap_up?: boolean | null }[] },
): number {
  return tripData.photos.filter((p) => p.use_in_wrap_up !== false).length;
}

// How long [tripData]'s film plays, s.
export function filmSecondsOf(
  tripData: { photos: readonly { use_in_wrap_up?: boolean | null }[] },
): number {
  return filmSeconds(filmPhotoCount(tripData));
}

// Sky Story at its reference pacing, by page count (1–5 pages).
export const SKY_REFERENCE_SECONDS = [32.5, 41.5, 54, 66.5, 75];
// How far over its length a film may be at its reference pacing: the app
// shrinks pages a little, but a page with a note keeps its reading time,
// so a film rather stretches fewer pages.
const SKY_SLACK_SECONDS = 3;

// The most Sky Story pages a film of [seconds] holds.
export function skyPagesFor(seconds: number): number {
  let pages = 1;
  SKY_REFERENCE_SECONDS.forEach((length, i) => {
    if (length <= seconds + SKY_SLACK_SECONDS) pages = i + 1;
  });
  return pages;
}

// Golden Vows (golden_vows_timeline.dart): the invitation, the album
// rising and opening, the heart, the cover closing and the ending play
// whatever the shape; each page is its dwell plus a page turn.
export const GV_FIXED_SECONDS = 5.4 + 1.0 + 1.25 + 7.6 + 1.0 + 9.05;
export const GV_TURN_SECONDS = 1.25;
export const GV_PACKING_SECONDS = 6.5;
export const GV_HERO_DWELL_SECONDS = 3.0;
export const GV_CHAPTER_SECONDS = 3.4 + GV_TURN_SECONDS;
export const GV_CAROUSEL_SECONDS = 6.0 + GV_TURN_SECONDS;
// What a film may run over its length before a page is left out.
const GV_SLACK_SECONDS = 1.5;

// How long the user's words need on screen (FilmTextRules.readingTime).
export function readingSeconds(text: string): number {
  return 0.8 + [...text.trim()].length / 12;
}

// A photo-with-note page: its dwell (long enough to read its note) plus
// its turn.
export function gvHeroSeconds(note: string | null | undefined): number {
  const text = note?.trim() ?? "";
  const dwell = text
    ? Math.max(GV_HERO_DWELL_SECONDS, readingSeconds(text) - GV_TURN_SECONDS)
    : GV_HERO_DWELL_SECONDS;
  return dwell + GV_TURN_SECONDS;
}

export interface GvShape {
  heroes: number;
  chapters: number;
  packingCard: boolean;
  carousel: boolean;
}

// Which of the album's pages a film of [seconds] keeps (#434): pages with
// few photos first — photo pages, then chapters — then the packing card,
// the carousel last. Always at least one photo page. [heroSeconds] is
// each hero's length, in the album's order.
export function gvShapeFor(
  seconds: number,
  available: {
    heroSeconds: number[];
    chapters: number;
    packingCard: boolean;
    carousel: boolean;
  },
): GvShape {
  const shape: GvShape = {
    heroes: 0,
    chapters: 0,
    packingCard: false,
    carousel: false,
  };
  let total = GV_FIXED_SECONDS;
  const fits = (cost: number) => total + cost <= seconds + GV_SLACK_SECONDS;
  const hero = () =>
    shape.heroes < available.heroSeconds.length
      ? available.heroSeconds[shape.heroes]
      : null;
  const chapter = () =>
    shape.chapters < available.chapters ? GV_CHAPTER_SECONDS : null;
  // The order pages are added in.
  const order: ("hero" | "chapter" | "packing" | "carousel")[] = [
    "hero",
    "hero",
    "chapter",
    "hero",
    "packing",
    "chapter",
    "hero",
    "carousel",
    "chapter",
    "hero",
    "chapter",
    "hero",
  ];
  for (const kind of order) {
    const cost = kind === "hero"
      ? hero()
      : kind === "chapter"
      ? chapter()
      : kind === "packing"
      ? (available.packingCard && !shape.packingCard
        ? GV_PACKING_SECONDS
        : null)
      : (available.carousel && !shape.carousel ? GV_CAROUSEL_SECONDS : null);
    if (cost === null) continue;
    const first = kind === "hero" && shape.heroes === 0;
    if (!first && !fits(cost)) continue;
    total += cost;
    if (kind === "hero") shape.heroes++;
    else if (kind === "chapter") shape.chapters++;
    else if (kind === "packing") shape.packingCard = true;
    else shape.carousel = true;
  }
  return shape;
}

// Neon Night in beats (neon_night_scene_spec.dart): Ignition 8, Finale 16
// and Ending 12 always; the Plan and the Note 12 each; a chapter's card
// 16 beats on the first and last chapter (its laser zooms: 12 with 1–2
// photos), 8 between; a split or burst 8, a timeline 12.
// The film plays on its music's clock (NeonTrack.bpm).
export const NN_BPM = 124;
export const NN_FIXED_BEATS = 8 + 16 + 12;
export const NN_PLAN_BEATS = 12;
export const NN_NOTE_BEATS = 12;
export const NN_MOMENT_BEATS = { split: 8, burst: 8, timeline: 12, peak: 8 };
// What a film may run over its length before a scene is left out: a bar.
const NN_SLACK_BEATS = 4;

// A card zoom shows its caption for at most its 1½ beats plus this many
// (#446: about 4 s on screen; NeonZoomPicks.maxHoldBeats).
export const NN_MAX_ZOOM_HOLD_BEATS = 6;
// The fewest beats a zoom holds (#448: NeonZoomPicks.minHoldBeats).
export const NN_MIN_ZOOM_HOLD_BEATS = 2;

// Whether [caption] can be read within one card zoom (#446), as the app
// decides it (NnChapterTexts.zoomCaptionOf).
export function nnFitsZoom(caption: string): boolean {
  return nnBeatsFor(readingSeconds(caption)) <= 1.5 + NN_MAX_ZOOM_HOLD_BEATS;
}

export function nnBeatsFor(seconds: number): number {
  return seconds / (60 / NN_BPM);
}

// The zooms' extra beats for [caption] (NnReadingTime.zoomHolds): its
// reading time past the zoom's 1½ beats, from 2 to 6.
export function nnZoomHold(caption: string | null): number {
  const text = caption?.trim();
  if (!text || !nnFitsZoom(text)) return NN_MIN_ZOOM_HOLD_BEATS;
  const read = Math.ceil(nnBeatsFor(readingSeconds(text)) - 1.5 - 1e-9);
  return Math.min(
    NN_MAX_ZOOM_HOLD_BEATS,
    Math.max(NN_MIN_ZOOM_HOLD_BEATS, read),
  );
}

// A card's beats with its zooms as the app picks them (NeonZoomPicks.best,
// NnChapterCardSpec): captions a zoom can show first, then hero score —
// ties go to the longer hold, so the estimate never runs short. 8 without
// a zoom; else the last zoom's end in bars, 12 at least.
export function nnZoomCardBeats(chapter: NnShapeChapter): number {
  const captions = chapter.cardCaptions ?? [];
  const tiles = Math.min(captions.length, 6);
  const zooms = Math.min(tiles, chapter.zooms ?? 2);
  if (zooms === 0) return 8;
  const ranked = captions.slice(0, tiles).map((c, k) => ({
    fits: !!c?.trim() && nnFitsZoom(c.trim()),
    hero: chapter.cardHeroScores?.[k] ?? 0,
    hold: nnZoomHold(c),
  })).sort((a, b) =>
    Number(b.fits) - Number(a.fits) || b.hero - a.hero || b.hold - a.hold
  );
  const end = 6 + ranked.slice(0, zooms).reduce((s, r) => s + 3 + r.hold, 0);
  return Math.max(12, bars(end));
}

export function nnCardBeats(
  index: number,
  count: number,
  photos: number,
  // The zooms it may play (#448: fewer when the film runs long).
  zooms = 2,
): number {
  // Every card zooms up to 2 of its photos (#444: NeonZoomPicks), each
  // about 2.4 s (#448: 3 + NN_MIN_ZOOM_HOLD_BEATS): 16 beats with 2, 12
  // with 1, 8 without; longer caption holds are covered by the slack.
  void index, count;
  const n = Math.min(photos, zooms);
  return n === 0 ? 8 : n === 1 ? 12 : 16;
}

export interface NnShapeMoment {
  type: keyof typeof NN_MOMENT_BEATS;
  photos: number;
  // The words it plays under its photos (note lines, captions).
  lines: string[];
}

export interface NnShapeChapter {
  // The card's photos (its laser zooms).
  photos: number;
  moments: NnShapeMoment[];
  // The card's typed line, if any.
  cardLine?: string | null;
  // The zooms its card may play; absent = 2.
  zooms?: number;
  // The captions of the card's photos (null = none), and their hero
  // scores: which ones it zooms, and how long each holds (#448).
  cardCaptions?: (string | null)[];
  cardHeroScores?: (number | null)[];
}

// [beats] up to whole bars.
function bars(beats: number): number {
  return Math.ceil(beats / 4 - 1e-9) * 4;
}

// A timeline photo's zoom (NnTimelineLayout.zoomIn / zoomOut), s.
const NN_ZOOM_SECONDS = 0.35 + 0.3;

// A moment's beats: its type's, or longer to read its words
// (NnReadingTime.momentBeats).
export function nnMomentBeats(moment: NnShapeMoment): number {
  const own = NN_MOMENT_BEATS[moment.type];
  const words = moment.lines.filter((t) => t.trim());
  if (words.length === 0) return own;
  if (moment.type === "timeline") {
    const holds = words.reduce(
      (s, t) =>
        s +
        Math.max(
          2,
          Math.ceil(nnBeatsFor(NN_ZOOM_SECONDS + readingSeconds(t)) - 1e-9),
        ),
      Math.max(0, moment.photos - words.length),
    );
    return Math.max(own, bars(2 + holds + nnBeatsFor(0.18)));
  }
  const read = words.reduce((s, t) => s + readingSeconds(t), 0);
  return Math.max(own, bars(1 + nnBeatsFor(read + 0.18)));
}

// A chapter card's beats: its zooms', or longer to type and read its line
// (NnReadingTime.cardBeats).
export function nnChapterCardBeats(
  index: number,
  count: number,
  chapter: NnShapeChapter,
): number {
  const own = chapter.cardCaptions
    ? nnZoomCardBeats(chapter)
    : nnCardBeats(index, count, chapter.photos, chapter.zooms);
  const line = chapter.cardLine?.trim();
  if (!line) return own;
  const typing = ([...line].length + 2) / 30;
  const shown = Math.max(typing + 0.8, readingSeconds(line));
  // Typed from lb 4, or lb 2 on a card without zooms (#448).
  const from = (chapter.zooms ?? 2) === 0 ? 2 : 4;
  return Math.max(own, bars(from + nnBeatsFor(shown + 0.18)));
}

// The Note scene's beats for [text] (NnNoteTexts.beatsFor, #448): 12 at
// least, longer to read its line.
export function nnNoteBeats(text: string | null): number {
  if (!text?.trim()) return NN_NOTE_BEATS;
  return Math.max(
    NN_NOTE_BEATS,
    bars(1 + nnBeatsFor(readingSeconds(text)) + nnBeatsFor(0.25)),
  );
}

export function nnFilmBeats(
  chapters: NnShapeChapter[],
  hasPlan: boolean,
  // The Note scene: whether there is one, or its line.
  note: boolean | string,
): number {
  return NN_FIXED_BEATS + (hasPlan ? NN_PLAN_BEATS : 0) +
    (note === false ? 0 : nnNoteBeats(typeof note === "string" ? note : null)) +
    chapters.reduce(
      (sum, c, i) =>
        sum + nnChapterCardBeats(i, chapters.length, c) +
        c.moments.reduce((s, m) => s + nnMomentBeats(m), 0),
      0,
    );
}

// The most chapters a Neon Night film of [seconds] holds: each chapter
// costs its card and a moment.
export function nnChaptersFor(seconds: number): number {
  const budget = nnBeatsFor(seconds) + NN_SLACK_BEATS - NN_FIXED_BEATS;
  let chapters = 1;
  for (let n = 2; n <= 5; n++) {
    const cards = 16 * 2 + 8 * (n - 2);
    if (cards + 10 * n <= budget) chapters = n;
  }
  return chapters;
}

// Whether a film of [beats] fits within [seconds] exactly (a hard max).
export function nnFitsWithin(beats: number, seconds: number): boolean {
  return beats <= nnBeatsFor(seconds) + 1e-9;
}

// Whether a film of [beats] fits [seconds] (with a bar to spare).
export function nnFits(beats: number, seconds: number): boolean {
  return beats <= nnBeatsFor(seconds) + NN_SLACK_BEATS;
}
