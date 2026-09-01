// Gathers everything the wrap-up screenplay is generated from. Caps below
// keep the Anthropic call's input (and cost) bounded regardless of trip size.
//
// photos.use_in_wrap_up doesn't exist yet — it's scoped to the Photo detail
// issue (M3-8), not this one (#93). Once it lands, prefer photos where it's
// true when any are flagged, falling back to this unfiltered query otherwise.

// deno-lint-ignore no-explicit-any
type SupabaseClient = any;

const MAX_PHOTOS = 40;
const MAX_QUESTS = 60;
const MAX_NOTE_CHARS = 500;

export interface TripData {
  trip: {
    name: string;
    destination: string | null;
    country_code: string | null;
    start_date: string | null;
    end_date: string | null;
    vibes: string[];
  };
  quests: {
    day_date: string;
    time: string | null;
    title: string;
    place_text: string | null;
    completed_at: string | null;
  }[];
  notes: { day_date: string; content: string }[];
  photos: {
    id: string;
    day_date: string | null;
    place_text: string | null;
    people_tags: string[];
    caption: string | null;
  }[];
  latestAchievement: { code: string; title: string; description: string } | null;
}

export async function gatherTripData(
  client: SupabaseClient,
  tripId: string,
): Promise<TripData> {
  const { data: trip, error: tripError } = await client
    .from("trips")
    .select("name, destination, country_code, start_date, end_date, vibes, user_id")
    .eq("id", tripId)
    .single();
  if (tripError || !trip) {
    throw new Error(`trip ${tripId} not found`);
  }

  const [questsRes, notesRes, photosRes, achievementsRes] = await Promise.all([
    client
      .from("quests")
      .select("day_date, time, title, place_text, completed_at")
      .eq("trip_id", tripId)
      .order("day_date")
      .limit(MAX_QUESTS),
    client
      .from("day_notes")
      .select("day_date, content")
      .eq("trip_id", tripId)
      .order("day_date"),
    client
      .from("photos")
      .select("id, day_date, place_text, people_tags, caption")
      .eq("trip_id", tripId)
      .order("day_date")
      .limit(MAX_PHOTOS),
    client
      .from("user_achievements")
      .select("earned_at, achievement_templates(code, title, description)")
      .eq("user_id", trip.user_id)
      .gte("earned_at", trip.start_date ?? "1970-01-01")
      .order("earned_at", { ascending: false })
      .limit(1),
  ]);

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
    },
    quests: (questsRes.data ?? []).map((q: Record<string, unknown>) => ({
      day_date: q.day_date as string,
      time: (q.time as string | null) ?? null,
      title: q.title as string,
      place_text: (q.place_text as string | null) ?? null,
      completed_at: (q.completed_at as string | null) ?? null,
    })),
    notes: (notesRes.data ?? []).map((n: Record<string, unknown>) => ({
      day_date: n.day_date as string,
      content: (n.content as string).slice(0, MAX_NOTE_CHARS),
    })),
    photos: (photosRes.data ?? []).map((p: Record<string, unknown>) => ({
      id: p.id as string,
      day_date: (p.day_date as string | null) ?? null,
      place_text: (p.place_text as string | null) ?? null,
      people_tags: (p.people_tags as string[] | null) ?? [],
      caption: (p.caption as string | null) ?? null,
    })),
    latestAchievement: latestTemplate
      ? {
          code: latestTemplate.code as string,
          title: latestTemplate.title as string,
          description: latestTemplate.description as string,
        }
      : null,
  };
}
