// The memory's film template (#433), decided in code from its vibes —
// before the director runs, and never changed by it. The mapping lives in
// film_templates.json, shared with the app (lib/features/wrap_up/domain/
// film_template.dart mirrors it; a Dart test checks they agree).

import config from "./film_templates.json" with { type: "json" };

// Every template the mapping can name.
export const FILM_TEMPLATES = [
  "golden_vows",
  "neon_night",
  "field_notes",
  "sky_story",
] as const;
export type FilmTemplate = typeof FILM_TEMPLATES[number];

// The templates the app can play today: what a chosen template plays as.
export type PlayedTemplate = "golden_vows" | "neon_night" | "sky_story";

// The template [vibes] choose, by priority: the first rule with a vibe of
// the memory wins (Romantic > Nightlife > outdoors > the rest). Vibes are
// matched ignoring case and spacing.
export function chosenTemplate(vibes: readonly string[]): FilmTemplate {
  const own = new Set(vibes.map((v) => v.trim().toLowerCase()));
  for (const rule of config.priority) {
    if (rule.vibes.some((v) => own.has(v.toLowerCase()))) {
      return rule.template as FilmTemplate;
    }
  }
  return config.default as FilmTemplate;
}

// What the chosen template plays as today (Field Notes → Sky Story until
// it ships).
export function playedTemplate(vibes: readonly string[]): PlayedTemplate {
  const chosen = chosenTemplate(vibes);
  return ((config.playsAs as Record<string, string>)[chosen] ??
    chosen) as PlayedTemplate;
}
