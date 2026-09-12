import type { AiGeneratedFields } from "./ai_fields.ts";
import type { WrapUpContent } from "./content.ts";
import type { TripData } from "./gather.ts";

export const validAiFields: AiGeneratedFields = {
  invitation_line2: "One long road.",
  bridges: [
    "The first stretch.",
    "The middle of it.",
    "The last of the light.",
  ],
  unlock_reason: "You logged every single day of this one.",
  keepsake_closing_quote: "This one's yours to keep.",
};

// 10 photos over a 5-day trip, 2 completed bonus tasks (fewer than the 3
// badge slots the film has) so the fixture also exercises the fallback path
// where a badge slot degrades to a plain journal photo.
export const validTripData: TripData = {
  trip: {
    name: "Lisbon Getaway",
    destination: "Portugal",
    country_code: "PT",
    start_date: "2026-06-01",
    end_date: "2026-06-05",
    vibes: ["Foodie"],
    cover_image_path: "asset:sunset",
  },
  notes: [
    { day_date: "2026-06-01", content: "Landed, wandered Alfama." },
    {
      day_date: "2026-06-03",
      content: "Pasteis de nata for breakfast, obviously.",
    },
    {
      day_date: "2026-06-05",
      content: "Last tram ride before the flight home.",
    },
  ],
  photos: [
    {
      id: "p1",
      day_date: "2026-06-01",
      created_at: "2026-06-01T09:00:00Z",
      storage_path: "u/t/p1.jpg",
      caption: "Golden hour",
    },
    {
      id: "p2",
      day_date: "2026-06-01",
      created_at: "2026-06-01T10:00:00Z",
      storage_path: "u/t/p2.jpg",
      caption: null,
    },
    {
      id: "p3",
      day_date: "2026-06-02",
      created_at: "2026-06-02T09:00:00Z",
      storage_path: "u/t/p3.jpg",
      caption: "Best pastry of the trip",
    },
    {
      id: "p4",
      day_date: "2026-06-02",
      created_at: "2026-06-02T10:00:00Z",
      storage_path: "u/t/p4.jpg",
      caption: "Miradouro views",
    },
    {
      id: "p5",
      day_date: "2026-06-03",
      created_at: "2026-06-03T09:00:00Z",
      storage_path: "u/t/p5.jpg",
      caption: "Fresh catch",
    },
    {
      id: "p6",
      day_date: "2026-06-03",
      created_at: "2026-06-03T10:00:00Z",
      storage_path: "u/t/p6.jpg",
      caption: null,
    },
    {
      id: "p7",
      day_date: "2026-06-04",
      created_at: "2026-06-04T09:00:00Z",
      storage_path: "u/t/p7.jpg",
      caption: "Sunset walk",
    },
    {
      id: "p8",
      day_date: "2026-06-04",
      created_at: "2026-06-04T10:00:00Z",
      storage_path: "u/t/p8.jpg",
      caption: "Late night gelato",
    },
    {
      id: "p9",
      day_date: "2026-06-05",
      created_at: "2026-06-05T09:00:00Z",
      storage_path: "u/t/p9.jpg",
      caption: "Last tram ride",
    },
    {
      id: "p10",
      day_date: "2026-06-05",
      created_at: "2026-06-05T10:00:00Z",
      storage_path: "u/t/p10.jpg",
      caption: "Airport goodbye",
    },
  ],
  completedBonusTasks: [
    {
      completed_at: "2026-06-01T11:00:00Z",
      photo_id: "p1",
      title: "Snap anything at all",
      points: 1,
    },
    {
      completed_at: "2026-06-02T11:00:00Z",
      photo_id: "p3",
      title: "Try the local specialty",
      points: 2,
    },
  ],
  starsEarned: 14,
  latestAchievement: {
    code: "first_adventure",
    title: "First Adventure",
    description: "Logged your first trip.",
  },
};

export const validWrapUpContent: WrapUpContent = {
  dates: {
    start_date: "2026-06-01",
    end_date: "2026-06-05",
    formatted: "1–5 June 2026",
  },
  cover_photo: { image_path: "asset:sunset" },
  invitation: { line1: "Five days.", line2: "One long road." },
  bridges: [
    "The first stretch.",
    "The middle of it.",
    "The last of the light.",
  ],
  moments: [
    {
      photo_id: "p1",
      storage_path: "u/t/p1.jpg",
      day_date: "2026-06-01",
      note: "Golden hour",
      badge: "Dare · Snap anything at all · ✦1",
    },
    {
      photo_id: "p2",
      storage_path: "u/t/p2.jpg",
      day_date: "2026-06-01",
      note: null,
      badge: null,
    },
    {
      photo_id: "p3",
      storage_path: "u/t/p3.jpg",
      day_date: "2026-06-02",
      note: "Best pastry of the trip",
      badge: "Dare · Try the local specialty · ✦2",
    },
    {
      photo_id: "p4",
      storage_path: "u/t/p4.jpg",
      day_date: "2026-06-02",
      note: "Miradouro views",
      badge: null,
    },
    {
      photo_id: "p5",
      storage_path: "u/t/p5.jpg",
      day_date: "2026-06-03",
      note: "Fresh catch",
      badge: null,
    },
    {
      photo_id: "p6",
      storage_path: "u/t/p6.jpg",
      day_date: "2026-06-03",
      note: null,
      badge: null,
    },
    {
      photo_id: "p7",
      storage_path: "u/t/p7.jpg",
      day_date: "2026-06-04",
      note: "Sunset walk",
      badge: null,
    },
    {
      photo_id: "p8",
      storage_path: "u/t/p8.jpg",
      day_date: "2026-06-04",
      note: "Late night gelato",
      badge: null,
    },
  ],
  flurry_leftovers: {
    photos: [
      { photo_id: "p9", storage_path: "u/t/p9.jpg", day_date: "2026-06-05" },
      { photo_id: "p10", storage_path: "u/t/p10.jpg", day_date: "2026-06-05" },
    ],
    total_remaining_label: null,
  },
  footnote: { photo_count: 10, bonus_completed_count: 2, stars: 14 },
  unlock: {
    code: "first_adventure",
    name: "First Adventure",
    reason: "You logged every single day of this one.",
  },
  keepsake: {
    title_line1: "Lisbon",
    title_line2: "Getaway",
    closing_quote: "This one's yours to keep.",
  },
};
