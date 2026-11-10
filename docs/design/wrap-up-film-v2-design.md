# Wrap-Up Film v2 — Director + Renderer (design)
 
> **Direction change (2026-11-10):** instead of one scene library styled per recipe, the film is now a set of
> **templates**, each with its own complete look, designed in Synthesia and specified precisely:
> - #345 **Sky Story** — new default (trips, couples, city breaks)
> - #346 **Golden Vows** — weddings, engagements, anniversaries, date nights
> - planned: **Neon Night** (parties, raves, concerts, sports nights), **Confetti** (birthdays, kids,
>   graduations, family celebrations), **Field Notes** (camping, hiking, fishing, road trips)
>
> All templates share: 1080×1920, ~45–75 s, title → chapter pages → payoff ending, the Storyni balloon in
> every template, one licensed music track each, user's first name as signature, fallback to the old film.
>
> **Director (#328, merged)** stays the brain: it picks the template from the occasion and fills that
> template's slots (heroes, chapters, notes, headlines). Extensions are in #345 phase 6 / #346 phase 7.
>
> **#344** rescoped to PR 1 (timeline engine) + reading/validating the plan; old-scene plan playback dropped.
> Parts 1–2 below are kept for background; the scene-library/recipe tables are superseded by the templates.
 
Status: **proposal, not started** · Date: 2026-11-08 · Owner: Leo
Replaces: Milestone 7 "themes" in `issue-backlog.md` (the director picks a recipe; the user can override).
Related issues: #291, #292 (ordering bugs), #293 (AI lines), #294 (choose photos).
 
## Why
After real-trip testing, the current film (fixed 18-scene template, AI writes only 4 lines) looks the
same for every memory. A wedding, a rave and a camping trip should feel different. The missing piece is
an AI that **decides how each film is told**, not AI-generated video.
 
## Decisions
- **Director** = the existing Anthropic API call in `generate_wrap_up`, extended: photos (small) + notes
  in, a structured **film plan** (JSON) out. No new service.
- **Renderer** = stays in **Flutter, on device**, but becomes **plan-driven** with a scene library.
- **No generative video** (Runway etc.) for now: slow, costly, distorts real faces, conflicts with
  "your real memories".
- **No server rendering yet** (Remotion / Creatomate). Revisit when MP4 export/sharing becomes a priority.
  The plan format must be renderer-agnostic so a server renderer can read the same plan later.
- **Don't block MVP launch.** Ship with the current film + #291–#293; v2 ships as an update.
---
 
## Part 1 — Director (Supabase edge function `generate_wrap_up`)
 
### Pipeline
1. **Gather** photos, notes, day titles, places, tagged people, bonus tasks, dates, vibes, user picks
   (#294: must-include / exclude).
2. **Downscale** photos (~512px) for analysis.
3. **Call 1 — photo analysis** (vision): per photo → short description, subject, people count, energy
   (calm/medium/high), quality (sharp/blurry), near-duplicate group, orientation, "hero shot" score.
   Cache results per photo (only new photos are analysed on rebuilds).
4. **Call 2 — film plan**: analysis + notes + trip facts + recipe definitions → plan JSON via **tool use /
   structured output** (schema below).
5. **Validate** in code: known scene types only, real photo ids only, no excluded photos, chronological
   order, total length 45–100s, text length limits, language = UI language (#250). Invalid → one retry →
   fall back to the current template.
6. **Save** to `wrap_ups.content` (versioned: `plan_version: 2`).
### Plan schema (sketch)
```json
{
  "plan_version": 2,
  "occasion": "wedding | party | camping | city | family | birthday | other",
  "recipe": "keepsake | celebration | rave | outdoors | city_break | warm_family",
  "music": { "track_id": "string", "energy": "calm|medium|high" },
  "language": "en",
  "chapters": [
    {
      "title": "string?",
      "bridge_line": "string",
      "scenes": [
        { "type": "card_flip|collage_3|collage_4|collage_6|ken_burns|burst|split|polaroid_drop|flurry|text_card",
          "photo_ids": ["uuid"], "caption_note_id": "uuid?", "duration_s": 4.5, "emphasis": "normal|hero" }
      ]
    }
  ],
  "footnote": { "line": "string" },
  "closing_line": "string"
}
```
Opening (dust/invitation), stats footnote, badge unlock and keepsake stay fixed bookends filled by code.
 
### Recipes (first set, refine in prototype)
| Recipe | Fits | Pace | Scene bias | Music | Tone of lines |
|---|---|---|---|---|---|
| keepsake (current) | default, quiet trips | slow | card_flip, ken_burns | calm piano/ambient | quiet, wry |
| celebration | wedding, anniversary | medium | polaroid_drop, collage, ken_burns | warm strings/acoustic | tender |
| rave | party, festival, concert | fast, beat-cut | burst, split, collage_6 | electronic, high energy | playful |
| outdoors | camping, hiking, fishing | slow-medium | ken_burns (wide), polaroid | folk/acoustic | earthy, self-deprecating |
| city_break | city trips | medium | collage, split, card_flip | upbeat indie | curious, light |
| warm_family | birthdays, family | medium | polaroid_drop, collage_3 | gentle, cheerful | warm |
 
### Cost & privacy
- Vision input costs more than text; with ~512px images and one film per memory, expect cents to tens of
  cents per film. **Measure in the prototype**; log tokens per film.
- Photos are sent to the Anthropic API → update privacy policy (EU/GDPR) before release.
---
 
## Part 2 — Renderer (Flutter, on device)
 
### Architecture
- **Timeline engine:** plan → flat list of scenes with start time + duration. One master clock
  (`AnimationController`) drives everything; scrubbing seeks the clock. Each scene widget receives its
  local progress `0..1`. (The current film already runs off one timeline — extend it, don't rewrite.)
- **Scene library:** each scene type is a widget implementing one interface, e.g.
  `Widget build(BuildContext, SceneData, double progress, RecipeStyle style)`. Existing scenes
  (card flip, collages, flurries, dust, invitation, footnote, unlock, keepsake) become library entries.
- **Recipe styles:** data object per recipe: colours, fonts, transition style, pace multiplier, grade.
  - Colour grade: `ColorFiltered` matrix; film grain / light leaks via a small fragment shader.
- **Music:** `just_audio`. Audio position follows the master clock (play/pause/seek on scrub). Each bundled
  track ships with **beat markers** (JSON list of beat times) so cuts snap to beats — big perceived-quality
  win, especially for `rave`. Tracks need an in-app distribution licence.
- **Signature balloon:** one Rive (or Lottie) animation with states (drift, fly-through, land) on an
  overlay layer: crosses chapter transitions, lands on the keepsake card.
- **Performance:** precache the next scenes' images at screen size, `RepaintBoundary` per scene, test
  200+ photo memories on a mid-range Android and an older iPhone.
- **Fallback:** if a plan is missing/invalid, play the current template.
### Initial scene library (8–12)
Existing: card_flip, collage_3, collage_4, collage_6, flurry, text_card (bridges), bookends.
New: ken_burns (slow pan/zoom, landscape heroes), burst (3–6 quick cuts on beats), split (2–3 photos
side by side), polaroid_drop.
 
### Later: MP4 export / sharing (separate decision)
Options when sharing becomes the priority:
- **Server render** (Remotion or Creatomate) reading the same plan — richest output, per-render cost,
  scenes re-implemented on the web side.
- **On-device capture** of the Flutter film to video — no server cost; check current Flutter
  video-encoding packages at that time.
Music licence must then cover published videos (a music API like Epidemic Sound covers this).
---
 
## Build order (each item ≈ one or a few GitHub issues)
0. **Prototype (no app code):** run the director prompts on Amsterdam + 2–3 other occasions; judge whether
   plans differ and make sense; measure cost.
1. Director: photo analysis + plan generation + schema validation + fallback (edge function).
2. Renderer refactor: timeline engine + scene interface; current film re-expressed as a plan.
3. New scenes: ken_burns, burst, split, polaroid_drop.
4. Recipes + style objects (2–3 recipes first).
5. Music: licence 6–10 tracks, beat markers, synced playback.
6. Balloon signature (Rive).
7. Recipe override in UI ("Change style") + Pro gating (free: keepsake + 1; Pro: all).
8. Later: export/share.
## Open questions
1. Which 2–3 recipes ship first?
2. Music source and budget.
3. Free vs Pro split of recipes.
4. Max photos analysed per memory (cost cap), e.g. 120 most diverse.
 