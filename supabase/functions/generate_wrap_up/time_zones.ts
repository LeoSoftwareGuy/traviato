// Every photo and note on the clock of where it happened (#461), not the
// phone's current zone.
//
// A photo's offset: its stored one (EXIF OffsetTimeOriginal, or the
// device's at an in-app capture), else the zone of its own GPS position,
// else the memory's zone, else the app's offset (the last resort, as
// before #461). A note's: its stored one (the device's when written), else
// the nearest photo's known offset within NOTE_NEAR_HOURS, else the
// memory's zone, else the app's.
//
// The memory's zone: trips.time_zone once resolved; else the zone most of
// its GPS photos are in; else its country (only when every zone there
// keeps the same offsets — the USA, Russia… are "unresolved", never a
// guess); else a city or country named in its destination. Offsets come
// from Intl for each instant, so daylight saving time is right.

import tzlookup from "npm:@photostructure/tz-lookup@11.0.0";
import zoneTable from "./time_zones.json" with { type: "json" };
import type { TripData } from "./gather.ts";

export type TripZoneSource =
  | "stored"
  | "gps"
  | "country"
  | "destination"
  | "unresolved";

export interface TripZone {
  zone: string | null;
  source: TripZoneSource;
  // What decided it, for the Plan inspector: "47 photos", "HU",
  // "Budapest", or why none ("US has several time zones").
  detail: string;
}

// Where a photo's or note's offset came from.
export type OffsetSource =
  | "exif"
  | "device"
  // Stored by the app (#468): taken_at is the EXIF wall clock (as UTC
  // fields), its zone unknown — read at the photo's GPS zone, else the
  // memory's, else the app's; resolved to "gps", "place" or "phone".
  | "wall"
  | "gps"
  | "nearby"
  | "place"
  | "phone";

const COUNTRIES = zoneTable.countries as Record<string, string[]>;
// Short names people write that Intl's country names don't cover.
const COUNTRY_ALIASES: Record<string, string> = {
  "USA": "US",
  "США": "US",
  "UK": "GB",
  "England": "GB",
  "Scotland": "GB",
  "Wales": "GB",
  "Англия": "GB",
  "Шотландия": "GB",
  "UAE": "AE",
  "ОАЭ": "AE",
  "Holland": "NL",
  "Голландия": "NL",
  "Czechia": "CZ",
  "Чехия": "CZ",
};
const NOTE_NEAR_HOURS = 3;

// [zone]'s UTC offset in minutes at [ms]; null for an unknown zone.
export function offsetIn(zone: string, ms: number): number | null {
  try {
    const name = new Intl.DateTimeFormat("en", {
      timeZone: zone,
      timeZoneName: "longOffset",
    }).formatToParts(new Date(ms)).find((p) => p.type === "timeZoneName")
      ?.value;
    if (!name || name === "GMT") return name === "GMT" ? 0 : null;
    const m = /^GMT([+-])(\d{2}):(\d{2})$/.exec(name);
    if (!m) return null;
    const minutes = Number(m[2]) * 60 + Number(m[3]);
    return m[1] === "-" ? -minutes : minutes;
  } catch {
    return null;
  }
}

// The zone at a position, or null.
export function zoneAt(lat: number, lng: number): string | null {
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
  if (Math.abs(lat) > 90 || Math.abs(lng) > 180) return null;
  try {
    return tzlookup(lat, lng);
  } catch {
    return null;
  }
}

// A country's one zone, or why there isn't one: its zones keep different
// offsets in winter or summer of [year].
export function countryZone(
  code: string,
  year: number,
): { zone: string } | { problem: string } {
  const zones = COUNTRIES[code.toUpperCase()];
  if (!zones?.length) return { problem: `${code}: no time zone known` };
  const offsets = (zone: string) =>
    [0, 6].map((month) => offsetIn(zone, Date.UTC(year, month, 15))).join();
  const first = offsets(zones[0]);
  return zones.every((z) => offsets(z) === first)
    ? { zone: zones[0] }
    : { problem: `${code.toUpperCase()} has several time zones` };
}

const norm = (t: string) =>
  ` ${
    t.toLowerCase().normalize("NFKD").replace(/\p{M}/gu, "").replace(
      /[^\p{L}\p{N}]+/gu,
      " ",
    ).trim()
  } `;

// The cities the tz database names ("Budapest", "New York"), and every
// country's name in English and Russian.
let cities: Map<string, string> | null = null;
let countryNames: Map<string, string> | null = null;
function names() {
  if (!cities || !countryNames) {
    cities = new Map();
    countryNames = new Map();
    for (const [code, zones] of Object.entries(COUNTRIES)) {
      for (const zone of zones) {
        const city = zone.split("/").at(-1)!.replace(/_/g, " ");
        cities.set(norm(city), zone);
      }
      for (const lang of ["en", "ru"]) {
        try {
          const name = new Intl.DisplayNames([lang], { type: "region" }).of(
            code,
          );
          if (name && name !== code) countryNames.set(norm(name), code);
        } catch {
          // An unknown region code: no name.
        }
      }
    }
    for (const [alias, code] of Object.entries(COUNTRY_ALIASES)) {
      countryNames.set(norm(alias), code);
    }
  }
  return { cities, countryNames };
}

// A zone from the memory's destination text: a tz city in it, else a
// country named in it (only with one zone).
export function destinationZone(
  destination: string,
  year: number,
): TripZone | null {
  const text = norm(destination);
  if (!text.trim()) return null;
  const { cities, countryNames } = names();
  // The longest name first: "New York" before "York".
  const hit = (map: Map<string, string>) =>
    [...map.keys()].filter((n) => n.trim().length >= 3 && text.includes(n))
      .sort((a, b) => b.length - a.length)[0];
  const city = hit(cities);
  if (city) {
    return {
      zone: cities.get(city)!,
      source: "destination",
      detail: city.trim(),
    };
  }
  const country = hit(countryNames);
  if (!country) return null;
  const r = countryZone(countryNames.get(country)!, year);
  return "zone" in r
    ? { zone: r.zone, source: "destination", detail: country.trim() }
    : { zone: null, source: "unresolved", detail: r.problem };
}

type Photo = TripData["photos"][number];

const atOf = (p: Photo) => p.taken_at ?? p.created_at;

// The memory's zone.
export function tripZone(tripData: TripData): TripZone {
  const stored = tripData.trip.time_zone;
  if (stored && offsetIn(stored, Date.now()) !== null) {
    return { zone: stored, source: "stored", detail: stored };
  }
  const counts = new Map<string, number>();
  for (const p of tripData.photos) {
    const z = p.lat != null && p.lng != null ? zoneAt(p.lat, p.lng) : null;
    if (z) counts.set(z, (counts.get(z) ?? 0) + 1);
  }
  const top = [...counts].sort((a, b) => b[1] - a[1])[0];
  if (top) {
    return { zone: top[0], source: "gps", detail: `${top[1]} photos` };
  }
  const year = Number(
    (tripData.trip.start_date ?? new Date().toISOString()).slice(0, 4),
  );
  let unresolved: TripZone | null = null;
  if (tripData.trip.country_code) {
    const r = countryZone(tripData.trip.country_code, year);
    if ("zone" in r) {
      return {
        zone: r.zone,
        source: "country",
        detail: tripData.trip.country_code.toUpperCase(),
      };
    }
    unresolved = { zone: null, source: "unresolved", detail: r.problem };
  }
  const fromText = destinationZone(tripData.trip.destination ?? "", year);
  if (fromText?.zone) return fromText;
  return unresolved ?? fromText ??
    { zone: null, source: "unresolved", detail: "no GPS, country or place" };
}

// [tripData] with every photo's and note's offset resolved
// (`utc_offset_minutes`, `utc_offset_source`) and its zone (`zone`).
// Idempotent; stored offsets are kept.
export function withLocalTimes(tripData: TripData): TripData {
  const zone = tripZone(tripData);
  const app = tripData.utc_offset_minutes ?? 0;
  const place = (ms: number) => zone.zone ? offsetIn(zone.zone, ms) : null;
  const photos = tripData.photos.map((p) => {
    if (p.utc_offset_source === "wall" && p.taken_at) return fromWall(p);
    if (p.utc_offset_minutes != null && p.utc_offset_source) return p;
    if (p.utc_offset_minutes != null) {
      return { ...p, utc_offset_source: p.utc_offset_source ?? "exif" };
    }
    const ms = Date.parse(atOf(p));
    const own = p.lat != null && p.lng != null ? zoneAt(p.lat, p.lng) : null;
    const gps = own ? offsetIn(own, ms) : null;
    if (gps !== null) {
      return {
        ...p,
        utc_offset_minutes: gps,
        utc_offset_source: "gps" as const,
      };
    }
    const fromPlace = Number.isNaN(ms) ? null : place(ms);
    return fromPlace !== null
      ? {
        ...p,
        utc_offset_minutes: fromPlace,
        utc_offset_source: "place" as const,
      }
      : { ...p, utc_offset_minutes: app, utc_offset_source: "phone" as const };
  });
  // A wall-clock photo (#468): its offset where it was, and its taken_at
  // the real instant.
  function fromWall(p: Photo): Photo {
    const wall = Date.parse(p.taken_at!);
    if (Number.isNaN(wall)) return { ...p, utc_offset_source: "phone" };
    const own = p.lat != null && p.lng != null ? zoneAt(p.lat, p.lng) : null;
    const gps = own ? offsetIn(own, wall) : null;
    const fromPlace = gps === null ? place(wall) : null;
    const offset = gps ?? fromPlace ?? app;
    return {
      ...p,
      taken_at: new Date(wall - offset * 60_000).toISOString(),
      utc_offset_minutes: offset,
      utc_offset_source: gps !== null
        ? "gps"
        : fromPlace !== null
        ? "place"
        : "phone",
    };
  }
  // Photos whose offset says where they were (not the place's guess).
  const known = photos.filter((p) =>
    p.utc_offset_source === "exif" || p.utc_offset_source === "device" ||
    p.utc_offset_source === "gps"
  ).map((p) => ({ ms: Date.parse(atOf(p)), offset: p.utc_offset_minutes! }))
    .filter((p) => !Number.isNaN(p.ms));
  const notes = tripData.notes.map((n) => {
    if (n.utc_offset_minutes != null) {
      return { ...n, utc_offset_source: n.utc_offset_source ?? "device" };
    }
    const ms = n.taken_at ? Date.parse(n.taken_at) : NaN;
    if (!Number.isNaN(ms)) {
      const near = known.map((p) => ({ ...p, d: Math.abs(p.ms - ms) }))
        .sort((a, b) => a.d - b.d)[0];
      if (near && near.d <= NOTE_NEAR_HOURS * 3_600_000) {
        return {
          ...n,
          utc_offset_minutes: near.offset,
          utc_offset_source: "nearby" as const,
        };
      }
      const fromPlace = place(ms);
      if (fromPlace !== null) {
        return {
          ...n,
          utc_offset_minutes: fromPlace,
          utc_offset_source: "place" as const,
        };
      }
    }
    return {
      ...n,
      utc_offset_minutes: app,
      utc_offset_source: "phone" as const,
    };
  });
  return { ...tripData, photos, notes, zone };
}

// [iso] on the clock of its own place: a wall-clock time as UTC millis.
// Without a resolved offset, the app's (as before #461).
export function localMs(
  tripData: TripData,
  item: { utc_offset_minutes?: number | null },
  iso: string,
): number {
  return Date.parse(iso) +
    (item.utc_offset_minutes ?? tripData.utc_offset_minutes ?? 0) * 60_000;
}

// What the app plays a film's times on (#461, `content.local_times`): each
// photo's and note's UTC offset in minutes, and the memory's zone. A kept
// film without it keeps the phone's clock until rebuilt.
export interface LocalTimes {
  zone: string | null;
  // For the Plan inspector: where the zone came from and what decided it
  // ("unresolved" = the phone's offset is used where nothing else is).
  zone_source: TripZoneSource;
  zone_detail: string;
  photos: Record<string, number>;
  notes: Record<string, number>;
  // How many photos and notes took each source.
  photo_sources: Partial<Record<OffsetSource, number>>;
  note_sources: Partial<Record<OffsetSource, number>>;
}

export function localTimesOf(tripData: TripData): LocalTimes {
  const photos: Record<string, number> = {};
  for (const p of tripData.photos) {
    if (p.utc_offset_minutes != null) photos[p.id] = p.utc_offset_minutes;
  }
  const notes: Record<string, number> = {};
  for (const n of tripData.notes) {
    if (n.id && n.utc_offset_minutes != null) {
      notes[n.id] = n.utc_offset_minutes;
    }
  }
  const count = (items: { utc_offset_source?: OffsetSource }[]) => {
    const out: Partial<Record<OffsetSource, number>> = {};
    for (const i of items) {
      const k = i.utc_offset_source ?? "phone";
      out[k] = (out[k] ?? 0) + 1;
    }
    return out;
  };
  const zone = tripData.zone ??
    { zone: null, source: "unresolved" as const, detail: "not resolved" };
  return {
    zone: zone.zone,
    zone_source: zone.source,
    zone_detail: zone.detail,
    photos,
    notes,
    photo_sources: count(tripData.photos),
    note_sources: count(tripData.notes),
  };
}
