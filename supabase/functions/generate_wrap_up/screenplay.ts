// Screenplay JSON shape for the wrap-up playback (functionality.md §15):
// hero -> route_chapter -> photo_beats -> stat_chapter -> achievement_moment -> close.
// screenplayToolSchema is handed to Claude as a forced tool call so the
// model's output is structurally guaranteed to match; validateScreenplay is
// still run defensively on the way back before we persist anything.

export interface RouteStop {
  place_text: string;
  day_date: string;
  lat: number | null;
  lng: number | null;
}

export interface PhotoBeat {
  photo_id: string;
  day_date: string | null;
  narrative: string;
}

export interface StatCard {
  label: string;
  value: string;
}

export interface AchievementMoment {
  code: string;
  title: string;
  description: string;
}

export interface Screenplay {
  hero: { title: string; subtitle: string | null; cover_photo_id: string | null };
  route_chapter: {
    intro: string;
    stops: RouteStop[];
    stats: { total_km: number | null; stop_count: number };
  };
  photo_beats: PhotoBeat[];
  stat_chapter: { stats: StatCard[] };
  achievement_moment: AchievementMoment | null;
  close: { line: string };
}

export const screenplayToolSchema = {
  name: "emit_screenplay",
  description: "Emit the wrap-up screenplay for this trip as structured JSON.",
  input_schema: {
    type: "object",
    properties: {
      hero: {
        type: "object",
        properties: {
          title: { type: "string" },
          subtitle: { type: ["string", "null"] },
          cover_photo_id: { type: ["string", "null"] },
        },
        required: ["title", "subtitle", "cover_photo_id"],
      },
      route_chapter: {
        type: "object",
        properties: {
          intro: { type: "string" },
          stops: {
            type: "array",
            items: {
              type: "object",
              properties: {
                place_text: { type: "string" },
                day_date: { type: "string" },
                lat: { type: ["number", "null"] },
                lng: { type: ["number", "null"] },
              },
              required: ["place_text", "day_date", "lat", "lng"],
            },
          },
          stats: {
            type: "object",
            properties: {
              total_km: { type: ["number", "null"] },
              stop_count: { type: "integer" },
            },
            required: ["total_km", "stop_count"],
          },
        },
        required: ["intro", "stops", "stats"],
      },
      photo_beats: {
        type: "array",
        items: {
          type: "object",
          properties: {
            photo_id: { type: "string" },
            day_date: { type: ["string", "null"] },
            narrative: { type: "string" },
          },
          required: ["photo_id", "day_date", "narrative"],
        },
      },
      stat_chapter: {
        type: "object",
        properties: {
          stats: {
            type: "array",
            items: {
              type: "object",
              properties: {
                label: { type: "string" },
                value: { type: "string" },
              },
              required: ["label", "value"],
            },
          },
        },
        required: ["stats"],
      },
      achievement_moment: {
        type: ["object", "null"],
        properties: {
          code: { type: "string" },
          title: { type: "string" },
          description: { type: "string" },
        },
        required: ["code", "title", "description"],
      },
      close: {
        type: "object",
        properties: { line: { type: "string" } },
        required: ["line"],
      },
    },
    required: [
      "hero",
      "route_chapter",
      "photo_beats",
      "stat_chapter",
      "achievement_moment",
      "close",
    ],
  },
} as const;

function isString(v: unknown): v is string {
  return typeof v === "string";
}

function isStringOrNull(v: unknown): v is string | null {
  return v === null || typeof v === "string";
}

function isNumberOrNull(v: unknown): v is number | null {
  return v === null || typeof v === "number";
}

export function validateScreenplay(data: unknown): data is Screenplay {
  if (typeof data !== "object" || data === null) return false;
  const d = data as Record<string, unknown>;

  const hero = d.hero as Record<string, unknown> | undefined;
  if (typeof hero !== "object" || hero === null) return false;
  if (
    !isString(hero.title) ||
    !isStringOrNull(hero.subtitle) ||
    !isStringOrNull(hero.cover_photo_id)
  ) {
    return false;
  }

  const route = d.route_chapter as Record<string, unknown> | undefined;
  if (typeof route !== "object" || route === null) return false;
  if (!isString(route.intro) || !Array.isArray(route.stops)) return false;
  for (const stop of route.stops) {
    if (typeof stop !== "object" || stop === null) return false;
    const s = stop as Record<string, unknown>;
    if (
      !isString(s.place_text) ||
      !isString(s.day_date) ||
      !isNumberOrNull(s.lat) ||
      !isNumberOrNull(s.lng)
    ) {
      return false;
    }
  }
  const routeStats = route.stats as Record<string, unknown> | undefined;
  if (typeof routeStats !== "object" || routeStats === null) return false;
  if (!isNumberOrNull(routeStats.total_km) || typeof routeStats.stop_count !== "number") {
    return false;
  }

  if (!Array.isArray(d.photo_beats)) return false;
  for (const beat of d.photo_beats) {
    if (typeof beat !== "object" || beat === null) return false;
    const b = beat as Record<string, unknown>;
    if (!isString(b.photo_id) || !isStringOrNull(b.day_date) || !isString(b.narrative)) {
      return false;
    }
  }

  const statChapter = d.stat_chapter as Record<string, unknown> | undefined;
  if (typeof statChapter !== "object" || statChapter === null || !Array.isArray(statChapter.stats)) {
    return false;
  }
  for (const stat of statChapter.stats) {
    if (typeof stat !== "object" || stat === null) return false;
    const s = stat as Record<string, unknown>;
    if (!isString(s.label) || !isString(s.value)) return false;
  }

  const achievement = d.achievement_moment;
  if (achievement !== null) {
    if (typeof achievement !== "object") return false;
    const a = achievement as Record<string, unknown>;
    if (!isString(a.code) || !isString(a.title) || !isString(a.description)) return false;
  }

  const close = d.close as Record<string, unknown> | undefined;
  if (typeof close !== "object" || close === null || !isString(close.line)) return false;

  return true;
}
