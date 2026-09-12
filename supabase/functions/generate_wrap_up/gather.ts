// Gathers everything the wrap-up content (#125) is assembled from. The AI
// only ever sees a small slice of this (ai_fields.ts's prompt input) — most
// of what's fetched here feeds deterministic assembly in assemble.ts instead,
// so the caps below are generous (no AI cost to protect), just a defensive
// ceiling on query/response size.
//
// Quests are deliberately not fetched — the film has no route chapter (no
// Mapbox, ever; see the #94 memory note), so they never feed this content.
//
// photos.use_in_wrap_up doesn't exist yet — it's scoped to the Photo detail
// issue (M3-8), not this one. The moments/flurry assembly here uses every
// trip photo, matching the earlier #93 decision to not filter by it.

// deno-lint-ignore no-explicit-any
type SupabaseClient = any;

const MAX_PHOTOS = 500;
const MAX_BONUS_ASSIGNMENTS = 500;
const MAX_NOTE_CHARS = 500;

export interface TripData {
  trip: {
    name: string;
    destination: string | null;
    country_code: string | null;
    start_date: string | null;
    end_date: string | null;
    vibes: string[];
    cover_image_path: string | null;
  };
  notes: { day_date: string; content: string }[];
  photos: {
    id: string;
    day_date: string | null;
    created_at: string;
    storage_path: string;
    caption: string | null;
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
}

export async function gatherTripData(
  client: SupabaseClient,
  tripId: string,
): Promise<TripData> {
  const { data: trip, error: tripError } = await client
    .from("trips")
    .select(
      "name, destination, country_code, start_date, end_date, vibes, cover_image_path, user_id",
    )
    .eq("id", tripId)
    .single();
  if (tripError || !trip) {
    throw new Error(`trip ${tripId} not found`);
  }

  const [notesRes, photosRes, bonusRes, pointsRes, achievementsRes] =
    await Promise.all([
      client
        .from("day_notes")
        .select("day_date, content")
        .eq("trip_id", tripId)
        .order("day_date"),
      client
        .from("photos")
        .select("id, day_date, created_at, storage_path, caption")
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
    ]);

  for (
    const [label, res] of [
      ["day_notes", notesRes],
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
    },
    notes: (notesRes.data ?? []).map((n: Record<string, unknown>) => ({
      day_date: n.day_date as string,
      content: (n.content as string).slice(0, MAX_NOTE_CHARS),
    })),
    photos: (photosRes.data ?? []).map((p: Record<string, unknown>) => ({
      id: p.id as string,
      day_date: (p.day_date as string | null) ?? null,
      created_at: p.created_at as string,
      storage_path: p.storage_path as string,
      caption: (p.caption as string | null) ?? null,
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
  };
}
