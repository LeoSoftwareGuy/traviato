# Design spec — "Lisbon, together" (best-wrap-upSofar.mp4)

Measured from the rendered MP4. Not exported from a project file, so:
- **Colours** were sampled by eye from compressed video: treat them as ±5% and adjust against the reference frames.
- **Fonts** are the closest visual matches, not confirmed names.
- **Times** come from frames every 3 s, so each boundary is accurate to about ±1.5 s.
- **Positions** are in px on the 1080×1920 frame, origin top-left.

Reference stills: ref-00.png … ref-54.png, the frame at that second (00 = 0.5 s, 54 = 53.8 s).

## 1. Format
- Frame 1080 × 1920 (9:16 vertical), 30 fps, 54.0 s
- Audio: music bed only, no narration
- The rounded dark pill bottom-right (~x 620–1020, y 1755–1860) is a free-plan watermark, NOT part of the design. Leave that corner empty.

## 2. Palette
| Role | Hex | Where |
|---|---|---|
| Sky – dusk top | #2E2350 | top of sky, 0–25 s |
| Sky – dusk mid | #5A3A6E | middle band |
| Sky – dusk horizon | #D9785E → #E8886A | bottom of frame at 0–5 s (sunset) |
| Sky – night top | #141838 | 30–54 s |
| Sky – night bottom | #211C4C | 30–54 s |
| Final night (outro) | #0C0F2E | 44–54 s, flat |
| Cloud | #8A5A8C ~45% opacity, blur ~20 px | drifting clouds |
| Balloon red | #C8283A (top) → #E8483E (bottom) | envelope gradient |
| Balloon stripe cream | #EED9C0 | stripes |
| Balloon basket | #7A5238 | basket |
| Burner glow | #FFD27A core, radial to transparent ~90 px | under envelope |
| Lantern / ember dots | #FFC870 + soft glow | floating lights |
| Stars | #C9CCE0 at 40–80% | 2–4 px dots, night only |
| Eyebrow gold | #F2B865 | DAY labels, "A MEMORY STORY" |
| Headline cream | #F6EBDD | serif headlines |
| Polaroid paper | #FDFAF4 | photo frames |
| Note card | #F6F0E6, rule lines #C9CFE0 1 px | journal card |
| Handwriting ink | #2C2A55 | captions + notes on paper |
| Signature red | #D2303E | signatures on paper |
| Signature gold | #F2B865 | signature on night sky, end tagline |
| Tape | #F4C46A ~70% | tape strips, Day 2 |
| Photo-count badge | fill #3A3560 ~85%, ring #F2B865 4 px | "71 PHOTOS" |

## 3. Type
| Role | Font (closest match) | Size | Setting | Colour |
|---|---|---|---|---|
| Title "Lisbon, together" | DM Serif Display | ~130 px, lh 1.0, centred | Regular | #F6EBDD |
| Day headline | DM Serif Display | ~88 px, left | Regular | #F6EBDD |
| "187 moments" | DM Serif Display | ~96 px, centred | Regular | #F6EBDD |
| Eyebrow (DAY 1 · …) | Open Sans | ~28 px, uppercase | Bold, tracking +0.15 em | #F2B865 |
| "A MEMORY STORY" | Open Sans | ~28 px, centred | Bold, tracking +0.25 em | #F2B865 |
| "YOUR MEMORY COMPANION" | Open Sans | ~28 px | Semibold, tracking +0.3 em | #F6EBDD |
| Subtitle "12 – 14 June 2026 · Mari & Jonas" | Caveat | ~56 px, centred | Regular | #F6EBDD |
| Polaroid caption | Caveat | ~44 px, centred | Regular | #2C2A55 |
| Note text | Caveat | ~50 px, lh ~64 px (on ruled lines) | Regular | #2C2A55 |
| Signature | Caveat | ~50 px | Bold | red or gold |
| Night-sky quote (Day 3) | Caveat | ~58 px, centred, lh ~80 px | Regular | #F6EBDD |
| Outro tagline | Caveat | ~60 px, centred | Regular | #F2B865 |

## 4. Day-page layout (left margin 76 px)
- Eyebrow: x 76, centre y ≈ 212
- Headline: x 76, cap top ≈ 250, baseline ≈ 320
- Corner balloon: centre ≈ (930, 145), ~110 px wide, bobs
- Hero polaroid: ≈ x 150–930, y 415–1300 (≈780×885); photo inset ~40 px sides/top, ~150 px caption strip; rotated −2° to −3°; soft drop shadow
- Caption: centred in the bottom strip, y ≈ 1180
- Note card: x 71–1011, y 1372–1748 (≈940×376), radius ~18; 4 rule lines 64 px apart from y ≈ 1478; text inset x 130
- Badge (Day 2): circle Ø ≈ 190, centre ≈ (885, 1245), overlapping the polaroid's corner

## 5. Shot list
1. 0.0–2.5 Ascent: sunset gradient sky. A large balloon (~360 px) rises from the bottom; 2 small balloons, ~20 embers and 6 blurred clouds drift.
2. 2.5–5.0 Title: balloon settles at ≈(540, 700). Below it, y ≈ 1180–1600: "A MEMORY STORY" / "Lisbon, together" / subtitle, each line fading and rising.
3. 5.0–7.0 Transition: title and balloon leave upward while the sky keeps scrolling (one continuous rise). The Day 1 eyebrow and headline fade in, and the corner balloon arrives.
4. 7.0–16.5 Day 1 "Lost, on purpose": a 3-photo polaroid fan (−4°, +3°, 0°) drops in. Hero: Alfama street, yellow 28 tram, couple. Caption "Alfama · Fri morning". The note card rises and its text writes on line by line, then "— Jonas" in red (~12 s).
5. 16.5–19.5 Interlude: the page exits up, the sky darkens, stars appear, and the balloon drifts across the centre.
6. 19.5–29.0 Day 2 "The quiet hour": hero sunset-over-rooftops photo with 4 photos peeking behind it and 2 tape strips. Caption "Miradouro · Sat evening". The "71 PHOTOS" badge pops (~23 s). The note writes on, then "— Mari" in red (~27 s).
7. 29.0–31.5 Interlude: the page tilts (~−4°) and slides off the bottom. Full night, balloon at centre.
8. 31.5–43.0 Day 3 "Salt in our hair": 3 polaroids fly out of the balloon (boat beach, clams, train window), then the beach-feet polaroid settles as the hero with a warm halo #E8A060. Caption "Cascais · Sun". A cream handwritten quote sits on the sky, with "— Jonas" in gold. At ~41 s the page drifts down as the balloon rises.
9. 43.0–46.0 Gather: background goes flat #0C0F2E. Hundreds of ~36 px photo tiles (radius 6, most tinted 30–40% red) swirl up.
10. 46.0–54.0 Outro: the tiles lock into a balloon mosaic (~16×21 tiles, 38 px, 4 px gaps, ≈ x 220–860, y 300–1160). Untinted tiles form the stripes. "187 moments" (y ≈ 1400) and the tagline (y ≈ 1515) appear. At ~50 s, the app icon (110 px, radius 22) and "YOUR MEMORY COMPANION" appear (y ≈ 1655). Hold.

## 6. Motion
- One continuous upward camera; pages enter from below and leave off the top. No hard cuts.
- Ambient loops: balloons bob ±8 px on a ~3 s sine, embers rise ~20 px/s, clouds drift ~10 px/s, stars twinkle softly.
- Headlines: fade + rise 40 px, 0.6–0.8 s, power3.out.
- Polaroids: scale 1.08 → 1 with a rotation settle, ~0.7 s, back.out(1.2).
- Note card: rise 80 px, 0.6 s. Handwriting: left→right wipe per line, ~0.9 s each, 0.2 s apart; the signature last.
- Badge: scale 0 → 1, 0.5 s, back.out(1.7).
- Mosaic: tiles settle on staggered paths over ~3 s, power2.out.

## 7. Copy
A MEMORY STORY / Lisbon, together / 12 – 14 June 2026 · Mari & Jonas
DAY 1 · FRI 12 JUNE · 64 PHOTOS / Lost, on purpose / Alfama · Fri morning / "Took the 28 tram the wrong way, twice. Found the best little bakery because of it." — Jonas
DAY 2 · SAT 13 JUNE / The quiet hour / Miradouro · Sat evening / 71 PHOTOS / "Everyone went quiet when the sun hit the river. I forgot to take a photo for a whole minute." — Mari
DAY 3 · SUN 14 JUNE · 52 PHOTOS / Salt in our hair / Cascais · Sun / "Last morning. Sand in everything, and already planning the next one." — Jonas
187 moments / Every memory, beautifully captured / YOUR MEMORY COMPANION