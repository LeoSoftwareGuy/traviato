import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import fixture from "./fixtures/budapest_birthday.json" with { type: "json" };
import type { TripData } from "./gather.ts";
import { localClock } from "./director.ts";
import { tripLogicalDays } from "./logical_day.ts";
import {
  countryZone,
  destinationZone,
  localTimesOf,
  offsetIn,
  tripZone,
  withLocalTimes,
  zoneAt,
} from "./time_zones.ts";

// A memory with [photos] and [notes] only; the phone in Tallinn (+120).
function memory(
  trip: Partial<TripData["trip"]>,
  photos: Partial<TripData["photos"][number]>[],
  notes: Partial<TripData["notes"][number]>[] = [],
): TripData {
  return {
    trip: {
      name: "Trip",
      destination: null,
      country_code: null,
      start_date: "2026-02-26",
      end_date: "2026-03-01",
      vibes: [],
      cover_image_path: null,
      ...trip,
    },
    notes: notes.map((n, i) => ({
      id: `n${i}`,
      day_date: "2026-02-26",
      content: "A note.",
      ...n,
    })),
    photos: photos.map((p, i) => ({
      id: `p${i}`,
      day_date: null,
      taken_at: null,
      created_at: "2026-02-26T12:00:00Z",
      storage_path: `p${i}.jpg`,
      caption: null,
      use_in_wrap_up: null,
      ...p,
    })),
    completedBonusTasks: [],
    starsEarned: 0,
    latestAchievement: null,
    utc_offset_minutes: 120,
  };
}

const TALLINN = { lat: 59.4133, lng: 24.8328 }; // the airport
const BUDAPEST = { lat: 47.4979, lng: 19.0402 };
const LISBON = { lat: 38.7223, lng: -9.1393 };

Deno.test("Intl offsets follow daylight saving time", () => {
  const ms = (iso: string) => Date.parse(iso);
  assertEquals(offsetIn("Europe/Budapest", ms("2026-02-26T20:57:40Z")), 60);
  assertEquals(offsetIn("Europe/Budapest", ms("2026-07-10T12:00:00Z")), 120);
  assertEquals(offsetIn("Europe/Lisbon", ms("2026-02-26T12:00:00Z")), 0);
  assertEquals(offsetIn("America/New_York", ms("2026-01-10T12:00:00Z")), -300);
  assertEquals(offsetIn("Asia/Kolkata", ms("2026-01-10T12:00:00Z")), 330);
  assertEquals(offsetIn("Not/AZone", 0), null);
});

Deno.test("GPS, country and destination give a zone", () => {
  assertEquals(zoneAt(BUDAPEST.lat, BUDAPEST.lng), "Europe/Budapest");
  assertEquals(zoneAt(TALLINN.lat, TALLINN.lng), "Europe/Tallinn");
  assertEquals(zoneAt(200, 0), null);
  assertEquals(countryZone("hu", 2026), { zone: "Europe/Budapest" });
  // Several zones with different offsets: never a guess.
  assertEquals(countryZone("US", 2026), {
    problem: "US has several time zones",
  });
  assertEquals(countryZone("RU", 2026), {
    problem: "RU has several time zones",
  });
  // Spain's Canaries keep another offset; Germany's Busingen doesn't.
  assertEquals("problem" in countryZone("ES", 2026), true);
  assertEquals(countryZone("DE", 2026), { zone: "Europe/Berlin" });
  assertEquals(
    destinationZone("Budapest Hungary", 2026)?.zone,
    "Europe/Budapest",
  );
  assertEquals(destinationZone("Венгрия", 2026)?.zone, "Europe/Budapest");
  assertEquals(destinationZone("New York", 2026)?.zone, "America/New_York");
  assertEquals(destinationZone("Somewhere nice", 2026), null);
  assertEquals(destinationZone("USA road trip", 2026)?.source, "unresolved");
});

Deno.test("the memory's zone: stored, then GPS, country, destination", () => {
  const photo = { taken_at: "2026-02-26T12:00:00Z" };
  assertEquals(
    tripZone(
      memory({ time_zone: "Europe/Lisbon" }, [{ ...photo, ...BUDAPEST }]),
    )
      .source,
    "stored",
  );
  assertEquals(
    tripZone(memory({ destination: "Lisbon" }, [{ ...photo, ...BUDAPEST }])),
    { zone: "Europe/Budapest", source: "gps", detail: "1 photos" },
  );
  assertEquals(
    tripZone(memory({ country_code: "HU", destination: "Lisbon" }, [photo]))
      .zone,
    "Europe/Budapest",
  );
  assertEquals(
    tripZone(memory({ destination: "Budapest Hungary" }, [photo])).source,
    "destination",
  );
  // A country with several zones and no city: unresolved, the phone's
  // offset plays.
  const us = withLocalTimes(memory({ country_code: "US" }, [photo]));
  assertEquals(us.zone, {
    zone: null,
    source: "unresolved",
    detail: "US has several time zones",
  });
  assertEquals(us.photos[0].utc_offset_minutes, 120);
  assertEquals(us.photos[0].utc_offset_source, "phone");
  // …but a named city settles it.
  assertEquals(
    tripZone(memory({ country_code: "US", destination: "Chicago" }, [photo]))
      .zone,
    "America/Chicago",
  );
});

Deno.test("Budapest (UTC+1 in February) plays 21:57 while the phone is in Tallinn", () => {
  const raw = structuredClone(fixture.trip_data) as unknown as TripData;
  assertEquals(raw.utc_offset_minutes, 120);
  const before = raw.photos.find((p) => p.id.startsWith("f8710f"))!;
  assertEquals(localClock(before.taken_at, raw, before), "22:57");

  const local = withLocalTimes(raw);
  assertEquals(local.zone?.zone, "Europe/Budapest");
  assertEquals(local.zone?.source, "destination");
  const photo = local.photos.find((p) => p.id.startsWith("f8710f"))!;
  assertEquals(photo.utc_offset_minutes, 60);
  assertEquals(photo.utc_offset_source, "place");
  assertEquals(localClock(photo.taken_at, local, photo), "21:57");
  // Every photo and note of the memory is on Budapest's clock.
  assertEquals(
    new Set(local.photos.map((p) => p.utc_offset_minutes)),
    new Set([60]),
  );
  assertEquals(
    new Set(local.notes.map((n) => n.utc_offset_minutes)),
    new Set([60]),
  );
  const times = localTimesOf(local);
  assertEquals(times.zone, "Europe/Budapest");
  assertEquals(times.photos[photo.id], 60);
  assertEquals(times.photo_sources, { place: local.photos.length });
});

Deno.test("a trip across zones shows each photo in its own local time", () => {
  // Tallinn airport at 07:10 local (05:10Z), Lisbon at 23:30 local — a
  // night out — and 01:30 the next night (same Lisbon evening).
  const local = withLocalTimes(memory(
    { destination: "Lisbon Portugal" },
    [
      { taken_at: "2026-02-26T05:10:00Z", ...TALLINN },
      { taken_at: "2026-02-26T23:30:00Z", ...LISBON },
      { taken_at: "2026-02-27T01:30:00Z" }, // no GPS: the memory's zone
      // EXIF said +02:00 (taken before leaving), no GPS.
      {
        taken_at: "2026-02-26T04:00:00Z",
        utc_offset_minutes: 120,
        utc_offset_source: "exif",
      },
      { taken_at: "2026-02-27T12:00:00Z", ...LISBON },
    ],
    [
      // Written in Tallinn: the device's offset was stored.
      { taken_at: "2026-02-26T05:20:00Z", utc_offset_minutes: 120 },
      // An older note without one, next to the Lisbon photo.
      { taken_at: "2026-02-26T23:45:00Z" },
    ],
  ));
  const clock = (i: number) =>
    localClock(local.photos[i].taken_at, local, local.photos[i]);
  // Most GPS photos are in Lisbon: the memory's zone.
  assertEquals(local.zone, {
    zone: "Europe/Lisbon",
    source: "gps",
    detail: "2 photos",
  });
  assertEquals(clock(0), "07:10");
  assertEquals(local.photos[0].utc_offset_source, "gps");
  assertEquals(clock(1), "23:30");
  assertEquals(clock(2), "01:30");
  assertEquals(local.photos[2].utc_offset_source, "place");
  assertEquals(clock(3), "06:00");
  assertEquals(local.photos[3].utc_offset_source, "exif");
  assertEquals(local.notes[0].utc_offset_minutes, 120);
  assertEquals(local.notes[0].utc_offset_source, "device");
  assertEquals(local.notes[1].utc_offset_minutes, 0);
  assertEquals(local.notes[1].utc_offset_source, "nearby");
  // Logical days on each place's clock: 01:30 in Lisbon stays on the 26th.
  const days = tripLogicalDays(local);
  assertEquals(days.get("p0"), "2026-02-26");
  assertEquals(days.get("p2"), "2026-02-26");
});

Deno.test("a summer trip across the clock change takes each instant's offset", () => {
  // Paris, the night Europe moves to summer time (29 March 2026, 01:00Z).
  const local = withLocalTimes(memory(
    { destination: "Paris", start_date: "2026-03-28", end_date: "2026-03-30" },
    [
      { taken_at: "2026-03-28T21:00:00Z" }, // 22:00 CET
      { taken_at: "2026-03-28T23:30:00Z" }, // 00:30 CET
      { taken_at: "2026-03-29T01:30:00Z" }, // 03:30 CEST
      { taken_at: "2026-07-10T18:00:00Z" }, // 20:00 CEST
    ],
  ));
  assertEquals(local.zone?.zone, "Europe/Paris");
  const clocks = local.photos.map((p) => localClock(p.taken_at, local, p));
  assertEquals(clocks, ["22:00", "00:30", "03:30", "20:00"]);
  assertEquals(local.photos.map((p) => p.utc_offset_minutes), [
    60,
    60,
    120,
    120,
  ]);
  // The night photos stay on the 28th's evening.
  const days = tripLogicalDays(local);
  assertEquals(
    [days.get("p0"), days.get("p1"), days.get("p2")],
    ["2026-03-28", "2026-03-28", "2026-03-28"],
  );
});

Deno.test("withLocalTimes is idempotent and keeps stored offsets", () => {
  const once = withLocalTimes(memory({ destination: "Budapest" }, [
    {
      taken_at: "2026-02-26T20:00:00Z",
      utc_offset_minutes: 330,
      utc_offset_source: "device",
    },
    { taken_at: "2026-02-26T20:00:00Z" },
  ]));
  const twice = withLocalTimes(once);
  assertEquals(twice.photos, once.photos);
  assertEquals(once.photos[0].utc_offset_minutes, 330);
  assertEquals(once.photos[1].utc_offset_minutes, 60);
});
