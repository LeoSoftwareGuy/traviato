// Gathers everything the wrap-up content (#125) is assembled from. The AI
// only ever sees a small slice of this (ai_fields.ts's prompt input) — most
// of what's fetched here feeds deterministic assembly in assemble.ts instead,
// so the caps below are generous (no AI cost to protect), just a defensive
// ceiling on query/response size.
//
// Quests feed only Golden Vows' packing card (#346) and Neon Night's plan
// rows (#363) — the film has no route chapter (no Mapbox, ever; see the
// #94 memory note).
//
// photos.use_in_wrap_up is the user's per-photo pick (#294): null = Auto,
// true = Always, false = Leave out. assemble.ts applies it.

import type { OffsetSource, TripZone } from "./time_zones.ts";

// deno-lint-ignore no-explicit-any
type SupabaseClient = any;

const MAX_PHOTOS = 500;
const MAX_BONUS_ASSIGNMENTS = 500;
// Whole notes (#398): a 500 cap cut the best lines off long legacy notes.
export const MAX_NOTE_CHARS = 4000;
// Golden Vows (#346) shows 5 items but counts them all.
const MAX_CHECKLIST_ITEMS = 500;
const MAX_QUESTS = 200;

export interface TripData {
  trip: {
    name: string;
    destination: string | null;
    country_code: string | null;
    start_date: string | null;
    end_date: string | null;
    vibes: string[];
    cover_image_path: string | null;
    // The memory's IANA zone once resolved (#461), else null.
    time_zone?: string | null;
  };
  // created_at: when the note was first written — places a one-sentence
  // note in its day for collage captions (#302). Never sent to the AI.
  // id: lets the director (#328) point a scene at a note.
  // taken_at / photo_id (#397): the note's own time (when Done was first
  // tapped; a legacy one-per-day note's last edit) and the photo it was
  // written on. A day holds many notes, oldest first.
  notes: {
    id?: string;
    day_date: string;
    content: string;
    created_at?: string | null;
    taken_at?: string | null;
    photo_id?: string | null;
    // One old one-per-day note (#400): its time is its last edit, not
    // when it happened.
    legacy?: boolean;
    // The offset where it was written (#461): stored (the device's), or
    // resolved by time_zones.ts.
    utc_offset_minutes?: number | null;
    utc_offset_source?: OffsetSource;
  }[];
  photos: {
    id: string;
    day_date: string | null;
    // Capture time when known; assemble.ts falls back to created_at.
    taken_at: string | null;
    created_at: string;
    storage_path: string;
    caption: string | null;
    use_in_wrap_up: boolean | null;
    // Tagged on Photo detail; given to the director (#328) as facts.
    place_text?: string | null;
    people_tags?: string[];
    // GPS, when the user allowed location (#461: its own zone).
    lat?: number | null;
    lng?: number | null;
    // The offset where it was taken (#461): stored (EXIF or the device's),
    // or resolved by time_zones.ts.
    utc_offset_minutes?: number | null;
    utc_offset_source?: OffsetSource;
    // The photo analysis's summary (#468): what a backfilled note is
    // matched to. Never shown, never the director's words.
    summary?: string | null;
  }[];
  completedBonusTasks: {
    completed_at: string;
    photo_id: string | null;
    title: string;
    points: number;
  }[];
  starsEarned: number;
  latestAchievement:
    | { code: string; title: string; description: string }
    | null;
  // The memory's checklist, in its order, and its quests by day and time
  // (#346): Golden Vows' packing card. Absent = none.
  checklist?: {
    title: string;
    suggestion_code: string | null;
    is_checked: boolean;
  }[];
  quests?: {
    title: string;
    day_date: string;
    // 'HH:MM:SS' wall-clock time, or null: Neon Night's plan rows (#363).
    time?: string | null;
    completed_at: string | null;
  }[];
  // The owner's profile name (#345): Sky Story signs notes with its first
  // word. Absent or null = no signature.
  username?: string | null;
  // The app's offset from UTC when it asked, in minutes (#363). Since
  // #461 only the last resort: each photo and note has its own.
  utc_offset_minutes?: number;
  // The memory's zone and where it came from (#461, time_zones.ts).
  zone?: TripZone;
}

export async function gatherTripData(
  client: SupabaseClient,
  tripId: string,
): Promise<TripData> {
  const { data: trip, error: tripError } = await client
    .from("trips")
    .select(
      "name, destination, country_code, start_date, end_date, vibes, cover_image_path, time_zone, user_id",
    )
    .eq("id", tripId)
    .single();
  if (tripError || !trip) {
    throw new Error(`trip ${tripId} not found`);
  }

  const [
    notesRes,
    photosRes,
    bonusRes,
    pointsRes,
    achievementsRes,
    profileRes,
    checklistRes,
    questsRes,
  ] = await Promise.all([
    client
      .from("journal_notes")
      .select(
        "id, day_date, content, created_at, taken_at, photo_id, legacy, utc_offset_minutes",
      )
      .eq("trip_id", tripId)
      .order("day_date")
      .order("taken_at"),
    client
      .from("photos")
      .select(
        "id, day_date, taken_at, created_at, storage_path, caption, use_in_wrap_up, place_text, people_tags, lat, lng, utc_offset_minutes, utc_offset_source",
      )
      .eq("trip_id", tripId)
      .order("day_date")
      .order("created_at")
      .limit(MAX_PHOTOS),
    client
      .from("bonus_task_assignments")
      .select("completed_at, photo_id, bonus_task_templates(title, points)")
      .eq("trip_id", tripId)
      .not("completed_at", "is", null)
      .order("completed_at")
      .limit(MAX_BONUS_ASSIGNMENTS),
    client
      .from("points_ledger")
      .select("points")
      .eq("trip_id", tripId),
    client
      .from("user_achievements")
      .select("earned_at, achievement_templates(code, title, description)")
      .eq("user_id", trip.user_id)
      .gte("earned_at", trip.start_date ?? "1970-01-01")
      .order("earned_at", { ascending: false })
      .limit(1),
    client
      .from("profiles")
      .select("username")
      .eq("id", trip.user_id)
      .maybeSingle(),
    client
      .from("checklist_items")
      .select("title, suggestion_code, is_checked")
      .eq("trip_id", tripId)
      .order("position")
      .limit(MAX_CHECKLIST_ITEMS),
    client
      .from("quests")
      .select("title, day_date, time, completed_at")
      .eq("trip_id", tripId)
      .order("day_date")
      .order("time", { nullsFirst: false })
      .order("position")
      .limit(MAX_QUESTS),
  ]);

  for (
    const [label, res] of [
      ["journal_notes", notesRes],
      ["photos", photosRes],
      ["bonus_task_assignments", bonusRes],
      ["points_ledger", pointsRes],
      ["user_achievements", achievementsRes],
    ] as const
  ) {
    if (res.error) {
      throw new Error(`failed to load ${label}: ${res.error.message}`);
    }
  }

  const latest = achievementsRes.data?.[0];
  const latestTemplate = latest?.achievement_templates;

  return {
    trip: {
      name: trip.name,
      destination: trip.destination,
      country_code: trip.country_code,
      start_date: trip.start_date,
      end_date: trip.end_date,
      vibes: trip.vibes ?? [],
      cover_image_path: trip.cover_image_path ?? null,
      time_zone: (trip.time_zone as string | null) ?? null,
    },
    notes: (notesRes.data ?? []).map((n: Record<string, unknown>) => ({
      ...(typeof n.id === "string" ? { id: n.id } : {}),
      day_date: n.day_date as string,
      content: (n.content as string).slice(0, MAX_NOTE_CHARS),
      created_at: (n.created_at as string | null) ?? null,
      taken_at: (n.taken_at as string | null) ?? null,
      photo_id: (n.photo_id as string | null) ?? null,
      legacy: n.legacy === true,
      utc_offset_minutes: (n.utc_offset_minutes as number | null) ?? null,
    })),
    photos: (photosRes.data ?? []).map((p: Record<string, unknown>) => ({
      id: p.id as string,
      day_date: (p.day_date as string | null) ?? null,
      taken_at: (p.taken_at as string | null) ?? null,
      created_at: p.created_at as string,
      storage_path: p.storage_path as string,
      caption: (p.caption as string | null) ?? null,
      use_in_wrap_up: (p.use_in_wrap_up as boolean | null) ?? null,
      place_text: (p.place_text as string | null) ?? null,
      people_tags: (p.people_tags as string[] | null) ?? [],
      lat: (p.lat as number | null) ?? null,
      lng: (p.lng as number | null) ?? null,
      utc_offset_minutes: (p.utc_offset_minutes as number | null) ?? null,
      ...(p.utc_offset_source
        ? { utc_offset_source: p.utc_offset_source as OffsetSource }
        : {}),
    })),
    completedBonusTasks: (bonusRes.data ?? []).map(
      (b: Record<string, unknown>) => {
        const template = b.bonus_task_templates as
          | Record<string, unknown>
          | null;
        return {
          completed_at: b.completed_at as string,
          photo_id: (b.photo_id as string | null) ?? null,
          title: (template?.title as string) ?? "",
          points: (template?.points as number) ?? 0,
        };
      },
    ),
    starsEarned: (pointsRes.data ?? []).reduce(
      (sum: number, row: Record<string, unknown>) =>
        sum + (row.points as number),
      0,
    ),
    latestAchievement: latestTemplate
      ? {
        code: latestTemplate.code as string,
        title: latestTemplate.title as string,
        description: latestTemplate.description as string,
      }
      : null,
    // A failed read of either only costs the packing card.
    checklist: checklistRes.error
      ? []
      : (checklistRes.data ?? []).map((i: Record<string, unknown>) => ({
        title: i.title as string,
        suggestion_code: (i.suggestion_code as string | null) ?? null,
        is_checked: i.is_checked === true,
      })),
    quests: questsRes.error
      ? []
      : (questsRes.data ?? []).map((q: Record<string, unknown>) => ({
        title: q.title as string,
        day_date: q.day_date as string,
        time: (q.time as string | null) ?? null,
        completed_at: (q.completed_at as string | null) ?? null,
      })),
    // A failed profile read only costs the signature.
    username: profileRes.error
      ? null
      : (profileRes.data?.username as string | null | undefined) ?? null,
  };
}
