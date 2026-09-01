import type { Screenplay } from "./screenplay.ts";

export const validScreenplay: Screenplay = {
  hero: { title: "Lisbon, remembered", subtitle: "5 days by the water", cover_photo_id: "p1" },
  route_chapter: {
    intro: "You started in Alfama and let the trams carry you the rest of the way.",
    stops: [{ place_text: "Alfama", day_date: "2026-06-01", lat: 38.71, lng: -9.13 }],
    stats: { total_km: 42, stop_count: 1 },
  },
  photo_beats: [{ photo_id: "p1", day_date: "2026-06-01", narrative: "Golden hour over the river." }],
  stat_chapter: { stats: [{ label: "Days", value: "5" }] },
  achievement_moment: { code: "first_adventure", title: "First Adventure", description: "Logged your first trip." },
  close: { line: "This one's yours to keep." },
};
