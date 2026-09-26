// wrap_ups.content shape for the Wrap-Up Film player (#125).
// docs/design/WRAP_UP_FILM_FLUTTER_SPEC.md §4 (data contract) is the source of truth.
// Supersedes the old hero/route_chapter/photo_beats screenplay from #93 —
// the film has no route chapter (no Mapbox, ever — see memory from #94).
//
// Only four fields are genuinely AI-generated (invitation.line2, bridges,
// unlock.reason, keepsake.closing_quote) — see ai_fields.ts. Everything else
// here is assembled deterministically in assemble.ts from plain queries.

export interface PhotoRef {
  photo_id: string;
  storage_path: string;
  day_date: string | null;
}

// Photo-count-aware "cut" (#151): how much of the film a trip's photo
// library can fill without ever repeating a photo. Chosen at generation
// time — the player only ever performs this fully-resolved plan.
export type FilmCut = "highlight" | "compact" | "full";

// Collage layouts (WRAP_UP_FILM_COLLAGE_SPEC.md §3), by tile count.
export type CollageLayout = "stack3" | "torn4" | "tilt6" | "torn6";

export interface Moment extends PhotoRef {
  note: string | null;
  badge: string | null;
  // null = card flip. Otherwise tile 0 is this moment's own photo and
  // collage_extras fills tiles 1..n-1, in paint order.
  layout: CollageLayout | null;
  collage_extras: PhotoRef[];
}

export interface WrapUpContent {
  cut: FilmCut;
  dates: {
    start_date: string | null;
    end_date: string | null;
    formatted: string;
  };
  cover_photo: {
    image_path: string | null;
  };
  invitation: {
    line1: string;
    line2: string;
  };
  bridges: [string, string, string];
  moments: Moment[];
  flurry_leftovers: {
    // Every photo not shown in a moment (primary or collage tile).
    photos: PhotoRef[];
    // What each Flurry scene shows; an empty list means the scene is cut
    // from the film entirely (#151).
    flurry1: PhotoRef[];
    flurry2: PhotoRef[];
    total_remaining_label: string | null;
  };
  footnote: {
    photo_count: number;
    bonus_completed_count: number;
    stars: number;
  };
  unlock: { code: string; name: string; reason: string } | null;
  keepsake: {
    title_line1: string;
    title_line2: string;
    closing_quote: string;
  };
}

function isString(v: unknown): v is string {
  return typeof v === "string";
}

function isStringOrNull(v: unknown): v is string | null {
  return v === null || typeof v === "string";
}

const FILM_CUTS: readonly string[] = ["highlight", "compact", "full"];
const COLLAGE_LAYOUTS: readonly string[] = [
  "stack3",
  "torn4",
  "tilt6",
  "torn6",
];

function isPhotoRef(v: unknown): v is PhotoRef {
  if (typeof v !== "object" || v === null) return false;
  const p = v as Record<string, unknown>;
  return isString(p.photo_id) && isString(p.storage_path) &&
    isStringOrNull(p.day_date);
}

export function validateWrapUpContent(data: unknown): data is WrapUpContent {
  if (typeof data !== "object" || data === null) return false;
  const d = data as Record<string, unknown>;

  if (!isString(d.cut) || !FILM_CUTS.includes(d.cut)) return false;

  const dates = d.dates as Record<string, unknown> | undefined;
  if (typeof dates !== "object" || dates === null) return false;
  if (
    !isStringOrNull(dates.start_date) ||
    !isStringOrNull(dates.end_date) ||
    !isString(dates.formatted)
  ) {
    return false;
  }

  const coverPhoto = d.cover_photo as Record<string, unknown> | undefined;
  if (typeof coverPhoto !== "object" || coverPhoto === null) return false;
  if (!isStringOrNull(coverPhoto.image_path)) return false;

  const invitation = d.invitation as Record<string, unknown> | undefined;
  if (typeof invitation !== "object" || invitation === null) return false;
  if (!isString(invitation.line1) || !isString(invitation.line2)) return false;

  if (
    !Array.isArray(d.bridges) || d.bridges.length !== 3 ||
    !d.bridges.every(isString)
  ) {
    return false;
  }

  if (!Array.isArray(d.moments)) return false;
  for (const moment of d.moments) {
    if (!isPhotoRef(moment)) return false;
    const m = moment as unknown as Record<string, unknown>;
    if (!isStringOrNull(m.note) || !isStringOrNull(m.badge)) return false;
    if (m.layout !== null && !COLLAGE_LAYOUTS.includes(m.layout as string)) {
      return false;
    }
    if (
      !Array.isArray(m.collage_extras) || !m.collage_extras.every(isPhotoRef)
    ) {
      return false;
    }
  }

  const flurry = d.flurry_leftovers as Record<string, unknown> | undefined;
  if (typeof flurry !== "object" || flurry === null) return false;
  for (const key of ["photos", "flurry1", "flurry2"]) {
    const list = flurry[key];
    if (!Array.isArray(list) || !list.every(isPhotoRef)) return false;
  }
  if (!isStringOrNull(flurry.total_remaining_label)) return false;

  const footnote = d.footnote as Record<string, unknown> | undefined;
  if (typeof footnote !== "object" || footnote === null) return false;
  if (
    typeof footnote.photo_count !== "number" ||
    typeof footnote.bonus_completed_count !== "number" ||
    typeof footnote.stars !== "number"
  ) {
    return false;
  }

  const unlock = d.unlock;
  if (unlock !== null) {
    if (typeof unlock !== "object") return false;
    const u = unlock as Record<string, unknown>;
    if (!isString(u.code) || !isString(u.name) || !isString(u.reason)) {
      return false;
    }
  }

  const keepsake = d.keepsake as Record<string, unknown> | undefined;
  if (typeof keepsake !== "object" || keepsake === null) return false;
  if (
    !isString(keepsake.title_line1) ||
    !isString(keepsake.title_line2) ||
    !isString(keepsake.closing_quote)
  ) {
    return false;
  }

  return true;
}
