# Neon Night — film template spec

> **For the implementing agent (Claude Code).** This is the full spec for the Neon Night film template in the Storyni Flutter app (repo `LeoSoftwareGuy/traviato`). Build it with the same renderer as the existing wrap-up film (see `WRAP_UP_FILM_FLUTTER_SPEC.md`): one authored-time clock T, and every element is a pure function of T. The reference prototype is `Neon Night Film.dc.html` + `neon-night.jsx`. When this spec and the prototype disagree, the prototype's numbers win.
>
> Suggested order:
> 1. Beat clock and cue table (§3, §5).
> 2. Background, grain and the neon balloon (§4).
> 3. Scenes, in sequence order.
> 4. Finale heart and confetti (§5.8).
> 5. Ending card (§5.9).
> 6. Data binding and edge cases.
> 7. Export at 1080×1920 30 fps with the audio track.
>
> Acceptance: frame-match the prototype at the cue times in §5, with no counts on screen before the end card.


Storyni film template for nights out (raves, clubs, festivals, concerts).
Reference implementation: `neon-night.jsx` (played by `Neon Night Film.dc.html`). Every value below is taken from that file. When this doc and the code disagree, the code wins.

---

## 1. Output

| | |
|---|---|
| Canvas | 1080 × 1920 px, portrait, origin top-left. Clip everything to the frame. |
| Frame rate | 30 fps |
| Length | 64.762 s = 136 beats (3 chapters). See §9 for other chapter counts. |
| Determinism | Every pixel is a pure function of `T` (seconds). No live randomness, no wall clock, no physics. All randomness comes from `rng(seed)` (§3.3). |
| Safe zone | **Bottom-right `x ≥ 760, y ≥ 1640` (320 × 280)** is left for the platform UI. No text, labels, counters or key photos go here. Only lasers, haze, grain and (in Peak) the laser fan reach it. |

---

## 2. Music and the beat grid

**Track brief:** a 126 bpm, 4/4 melodic techno / electro track.
- Bars 1–2 (0–3.8 s): filtered intro. A buzzy synth stab rises as the sign lights.
- Bars 3–13 (3.8–24.8 s): groove. Four-on-the-floor kick, offbeat open hat, rolling bass.
- Bars 14–22 (24.8–41.9 s): main section. A clap is added on beats 2 and 4, plus a 16-step arp.
- Bars 25–27 (45.7–51.4 s): **build.** The kick drops out, a riser and snare roll come in, and the filter opens.
- **Bar 28, beat 1 = 51.429 s: the DROP** (finale). Full kick and bass, plus a supersaw lead.
- Bars 32–34 (59.0–64.8 s): outro. Pads only, with a long reverb tail.

```
BPM  = 126
BEAT = 60 / BPM = 0.476190 s
BAR  = 4 × BEAT = 1.904762 s
beatToSec(b) = b × BEAT
secToBeat(s) = s / BEAT
```

Scene lengths are whole bars (or half bars), so every scene starts on a downbeat. **Everything inside a scene is timed in local beats `lb` from the scene cue.** To re-sync to any track with a known bpm, change `BPM`. All seconds in this doc are then recomputed as `beats × 60 / bpm`, and the first downbeat is placed at T = 0. Every "hit" (cut, pop, flare, highlight jump, tick, wave landing) is on an integer or half beat.

`beatEnv(T)` is a global kick envelope used for subtle pulsing:
```
f = frac(T / BEAT);  beatEnv = exp(−f × BEAT / 0.14)      // 1 on the beat → ~0.03 by the next
flare(T, at, τ) = T < at ? 0 : exp(−(T − at) / τ)           // one-shot hit envelope
```

---

## 3. Shared tokens

### 3.1 Colours (RGB)

| Token | Hex | RGB | Use |
|---|---|---|---|
| black | #05030A | 5, 3, 10 | Background |
| pink | #FF2BD6 | 255, 43, 214 | Balloon envelope, slam flash, titles |
| cyan | #22F2FF | 34, 242, 255 | Balloon bands, chromatic offset (left), Ch 1 accent |
| green | #B6FF2E | 182, 255, 46 | Basket/flame, highlight frame, Ch 3 accent |
| violet | #9B5CFF | 155, 92, 255 | Ch 2 accent, timeline frames, flash tint |
| orange | #FF7A2B | 255, 122, 43 | Placeholder photos only |
| grey | #4A4458 | 74, 68, 88 | Plan rows that aren't done |
| haze | #6A2FB8 | 106, 47, 184 | Haze blobs at α 0.55 |
| tint-cyan / tint-pink / tint-violet / tint-green | #D9FDFF / #FFD6F6 / #EBDDFF / #F0FFD6 | | Lit neon text fill (the hot core of a tube) |
| body text | #E7E3F2 | 231, 227, 242 | Stats, closing line |

**Neon glow recipes.**
- Frame: `border 4–7px <c>`, plus `box-shadow 0 0 (8+18f)px <c>, 0 0 (26+44f)px <c>@60%, inset 0 0 (10+16f)px <c>@67%`, where `f` = flare 0..1. The photo's brightness is also multiplied by `1 + 0.35f`.
- Tube text: an outline stroke `<c>` plus `drop-shadow 0 0 6g px <c>` and `drop-shadow 0 0 22g px <c>`. On top sits a white core stroke at 35% of the stroke width, α 0.9.
- Chromatic text: white fill with `text-shadow −d 0 cyan, +d 0 pink, 0 0 28px white@22%`, where d = 4–5 px.

### 3.2 Type

| Role | Font | Weight | Notes |
|---|---|---|---|
| Titles (filled) | Big Shoulders Display | 900 | Caps, line-height 0.9 |
| Titles (neon tube) | Big Shoulders Display | 800 (note: 600) | Transparent fill, 4–6px stroke |
| Ghost numeral | JetBrains Mono | 800 | 380 px tube outline |
| Labels, times, notes, stats | JetBrains Mono | 400–500 | Caps, letter-spacing 2–3 px |
| Wordmark "Storyni" | Big Shoulders Display | 800 | 190 px, chromatic |

**Auto-fit:** `size = min(maxSize, maxWidth / (chars × k))`. The character-width factor `k` is 0.42–0.50 per call (listed per element). Use the longest line for multi-line text.

### 3.3 Seeded random (mulberry32)
```
rng(seed): a = seed >>> 0
  next(): a = (a + 0x6D2B79F5)>>>0; t = a;
          t = imul(t ^ t>>>15, t | 1);
          t ^= t + imul(t ^ t>>>7, t | 61);
          return ((t ^ t>>>14)>>>0) / 2^32
```
Seeds used: grain `frame×7+3` · placeholder photo `i×977+13` · glitch `seed×131+frame` · contact-sheet highlight `chapter×1000+j` · mosaic order `k×53+9` · mosaic flight `k×31+5`.

### 3.4 Easing (only these)
`enter = easeOutCubic` · `pop = easeOutBack (s = 1.70158)` · `slam = easeOutExpo` · `scroll = easeInOutCubic` · Ken Burns = linear.

### 3.5 Reusable effects

**Glitch-in** (titles), starting at time `at`. It lasts 0.5 s and is quantised to frames `f = floor((T − at) × 30)`; draw `r = rng(seed×131+f)`.
- Base layer: opacity is `r>0.35 ? 1 : 0.25` for the first 3 frames, then 1. It is offset `dx = (r−0.5) × 60 × (1−p)` px.
- Three slice copies, each `clip inset(top% 0 bottom% 0)` with `top = r×80`, `height = 6 + r×18 %`, `dx = (r−0.5) × 120 × (1−p)`.
- After 0.5 s the text is static.

**Tube-on flicker** (neon lighting up), dt = T − at:
`0–0.07 s → 0.75`, `0.07–0.17 s → 0.12`, `0.17–0.32 s → linear 0.12→1`, then 1. That is one flash per tube.

**Ken Burns:** the image inside every frame scales `1 + kb → 1` linearly across its scene (kb = 0.06–0.15).

---

## 4. Layer order (bottom → top)

1. Black fill `#05030A`.
2. **Haze**: three blobs, radial `closest-side` haze@0.55 → 0, size 1440 × 1240. Centres:
   - `(300 + 90 sin(0.21T), 520 + 70 cos(0.17T))`
   - `(820 + 90 sin(0.21T+2), 1080 + 70 cos(0.17T+1))`
   - `(520 + 90 sin(0.21T+4), 1560 + 70 cos(0.17T+2))`

   Opacity is 1.1 during chapter cards and 0.8 elsewhere. It fades to 0 over the last 2 beats.
3. **Scene content** (one block per scene, §5).
4. **Lasers** (blend `screen`). Six beams, each 2600 px long, rotating about their left end. Angle `a + amp × sin(2πT / (per × BAR) + ph)`:

   | # | pivot | a° | amp° | per (bars) | ph | colour | width |
   |---|---|---|---|---|---|---|---|
   | 1 | −40, 300 | −18 | 10 | 4 | 0 | green | 3 |
   | 2 | 1120, 520 | 200 | 8 | 6 | 1 | cyan | 3 |
   | 3 | −40, 1380 | −24 | 12 | 5 | 2 | pink | 3 |
   | 4 | 1120, 1200 | 192 | 9 | 3 | 0.5 | violet | 2 |
   | 5 | 300, −40 | 62 | 14 | 7 | 3 | cyan | 2 |
   | 6 | 900, 1960 | −115 | 10 | 5 | 1.7 | green | 2 |

   - Glow: `0 0 8px c, 0 0 22px c`.
   - Opacity: `amt × (0.45 + punch × 0.5 × beatEnv)`.
   - `amt` = 0.6 in Note, 1 elsewhere. It fades to 0 over the first 3 beats of Ending.
   - `punch` = 1 in Finale, 0.6 elsewhere (× 0.4 when reduced).
   - **During a chapter card, all six beams take the chapter accent colour.**
5. **Neon balloon sign** (§4.1). It is one persistent element whose pose interpolates.
6. Finale headline, confetti, Ending text.
7. **Flash overlay**: radial `#FFF 0% → violet@70% 55% → 0`, opacity = drop flash + glow-up flash (§5.8).
8. **Grain**: 240 px fractal-noise tile (baseFrequency 0.9, 2 octaves, α 0.6), blend `overlay`, opacity 0.08. The tile offset is re-rolled every frame from `rng(frame×7+3)` (x, y in 0..240).
9. Vignette: radial ellipse at (50%, 45%), clear to 55%, black@0.55 at 100%.
10. Outro black: opacity 0→1 over the last 2 beats (63.810 → 64.762 s).

### 4.1 Balloon sign

- **ViewBox 200 × 300.** Rendered height = width × 1.5.
- **Tubes, in lighting order:**

  | Tube | Colour | Path |
  |---|---|---|
  | env | pink | `M100 12 C44 12 12 58 12 112 C12 160 46 192 74 226 L126 226 C154 192 188 160 188 112 C188 58 156 12 100 12 Z` |
  | gore ×4 | pink | `M100 12 C72 40 66 160 88 226` · `M100 12 C128 40 134 160 112 226` · `M100 12 C52 30 38 150 78 224` · `M100 12 C148 30 162 150 122 224` |
  | band ×3 | cyan | `M24 78 Q100 96 176 78` · `M14 132 Q100 152 186 132` · `M30 180 Q100 198 170 180` |
  | neck + ropes | pink | `M76 226 L124 226 L120 244 L80 244 Z` · `M82 244 L88 262 M118 244 L112 262` |
  | basket | green | `M84 262 L116 262 L113 292 L87 292 Z` |
  | flame | green | `M100 260 C94 253 95 246 100 240 C105 246 106 253 100 260 Z` |

- **Strokes:** each tube is drawn twice — the colour stroke, then a white core at 35% width, α 0.8. Round caps and joins.
  - On-screen tube thickness: `px = 4.5 + 6.5 × clamp((w − 130)/470)`. That is 4.5 px in the corner and 11 px at full size.
  - Glow filter: gaussian blurs of σ = `7g / scale` and 3× that, merged under the source.
  - Unlit tubes show at α 0.07 (glass).
- **Poses** (x, y, w): IGN `240,170,600` · COR `884,64,130` · END `375,330,330`.

  | When | Pose |
  |---|---|
  | 0 → 3.333 s | IGN |
  | 3.333 → 3.810 s (last beat of Ignition) | IGN→COR, enter |
  | Plan → Ending lb 1 | COR (stays in the corner through the heart finale) |
  | Ending lb 1 → 2.5 | COR→END, enter |

- **Laser emitter:** the chapter-card pointer laser starts from the basket of the corner sign, at **(949, 252)**.
- **Glow g:**
  - Normally `0.9 + 0.4 × beatEnv`.
  - In Finale, add `0.9 × flare(lb 8, 0.5)` for the glow-up (0.3 when reduced).
  - Ending: 1.2.

---

## 5. Sequence (3 chapters)

Columns: start s / beat (absolute). Times inside each scene are local beats `lb` (seconds = cue + lb × BEAT).

| # | Scene | Cue (s) | Beat | Length |
|---|---|---|---|---|
| 1 | Ignition | 0.000 | 0 | 2 bars |
| 2 | Plan | 3.810 | 8 | 3 bars |
| 3 | Ch1Card (with 3 laser zooms) | 9.524 | 20 | 4 bars |
| 4a | Ch1Split | 17.143 | 36 | 2 bars |
| 4b | Ch1Burst | 20.952 | 44 | 2 bars |
| 5a | Ch2Card | 24.762 | 52 | 2 bars |
| 5b | Ch2Timeline | 28.571 | 60 | 3 bars |
| 6a | Ch3Card (with 3 laser zooms) | 34.286 | 72 | 4 bars |
| 6b | Ch3Peak | 41.905 | 88 | 2 bars |
| 7 | Note | 45.714 | 96 | 3 bars |
| 8 | **Finale (drop) — heart** | **51.429** | **108** | 4 bars |
| 9 | Ending — end card | 59.048 | 124 | 3 bars → 64.762 s / b136 |

All scenes cut hard on the cue. Unless stated otherwise, each scene's content fades 1→0 over its last 0.18 s.

### 5.1 Ignition — 0.000 s, 8 beats

| Element | Position / size | Start (lb) | Dur | Easing / effect |
|---|---|---|---|---|
| Balloon env tube | Pose IGN 240,170 · 600 × 900 | 0 | 0.32 s | Tube-on flicker |
| gore tubes | — | 1 | 0.32 s | Flicker |
| band tubes | — | 2 | 0.32 s | Flicker |
| neck + ropes | — | 2.5 | 0.32 s | Flicker |
| basket | — | 3 | 0.32 s | Flicker |
| flame | — | 3.5 | 0.32 s | Flicker |
| Title `{title}` | Centred, top 1240. Tube text pink, core cyan, weight 800, stroke 5. Size fit(960, 230, k 0.47) | 4 | 0.5 s | Glitch-in, seed 11 |
| Reflection | Copy of title flipped vertically, top 1240 + 1.05·size + 30. Mask: black at bottom → clear at 65% | 4.5 | 0.4 s | Opacity 0→0.22 |
| Meta `{date}` (no counts — counts only appear on the end card) | Centred, top 1240 + size + 30. Mono 500, 38 px, ls 3, #CFEFFF | 6 | 0.5 s | Enter: fade, rise 16 px |
| Exit (title, meta, reflection) | — | 7.4 | 0.5 s | Fade out. The balloon moves to the corner (lb 7–8). |

### 5.2 Plan — 3.810 s, 12 beats

| Element | Position / size | Start (lb) | Dur | Effect |
|---|---|---|---|---|
| "TONIGHT'S PLAN" | Centred, top 250. Pink tube, 800, stroke 4. fit(860, 150, 0.46) | 0 | 0.5 s | Glitch-in, seed 21 |
| Row i (i = 0..4) | y = 520 + 200i | 1 + 0.1 s × i | 0.45 s | Enter: fade, rise 30 px |
| · time | x 110, BSD 900, 130 px | | | |
| · item | x 420, BSD 900. fit(440, 130, 0.44), baseline-aligned | | | |
| Done row d (d-th done item) | Colour = [cyan, pink, violet][d mod 3] | **3 + d** | instant | Fill → tint, text-shadow `0 0 2/14/34px c`. Plus flare τ 0.25 |
| · underlines | x 110 w 270 and x 420 w 440, top y+148, h 10, r 5 | 3 + d | 0.3 s | Enter: width 0→full |
| · tick | x 890, y+30, 96 × 86. Path `M4 40 L28 66 L76 6`, stroke 9 tint + double glow | 3 + d | 0.25 s | Draw: dash 120 → 0 |
| Rows not done | grey #4A4458, α 0.85, no glow | — | — | Stay grey |
| "+N MORE" (only when more than 5 items) | x 420, top 1530, mono 40 grey | 2 | 0.4 s | Fade |
| Exit | Whole block | 11.4 | 0.5 s | Fade out, scale 1→1.04 |

Rows are shown in chronological order and capped at 5. The ticks keep one per beat, so at most 5 ticks land on lb 3–7.

### 5.3 Chapter card (reusable) — Ch1 9.524 s (16 beats), Ch2 24.762 s (8), Ch3 34.286 s (16)

The accent `col` comes from the chapter (cycle: cyan, violet, green, pink, cyan…).

| Element | Position / size | Start (lb) | Dur | Effect |
|---|---|---|---|---|
| Pink slam flash | Full frame, radial at (30%, 25%) pink → 0 at 70% | 0 | τ 0.16 s | Opacity 0.4 × flare (reduced 0.12, τ 0.4) |
| "CH 0n/0N" | x 72, y 60. Mono 500 52 px, ls 2, col, glow 14 | 0.5 | 0.3 s | Fade |
| "{from} – {to}" | x 72, under the CH line (+4), mono 36, no wrap | 0.5 | 0.3 s | Fade |
| Ghost numeral "0n" | x 56, y 230. Mono 800, 380 px tube, stroke 6. Origin (20%, 60%) | 0 | 0.22 s | Slam: scale 1.8→1, opacity on in 0.05 s. Starts pink at glow 1 + flare, then crossfades pink→col over lb 1–2 |
| Title | x 72, y 610. BSD 900 white chromatic d 4, lh 0.9. fit(860, 170, 0.5) on the longest line. Titles over 10 chars with 2+ words split into 2 lines at the word midpoint | 1 | 0.5 s | Glitch-in, seed n × 7 |
| Contact sheet | Grid x 72, y 950. 8 columns, cell 106.5, gap 12, radius 10, border 3 px col + glow 6 | 2 + 0.03 s × k | 0.3 s each | Pop: scale 0.7→1, in reading order |
| Highlight | Tile `rng(n×1000+j)` (re-rolled if it repeats the previous one) | 4 + j, every beat. Stops at lb 6 on a 16-beat card | until the next beat | Current tile: brightness 1.5, col screen overlay 0.38, glow 30, scale 1.06. Previous two tiles at 0.5 and 0.25 (trail) |
| Typed line | x 72, y = gridBottom + 50, w 936. Mono 500 40/52, col + glow 12 | 4 | 1 char/frame | Text `> {note}`, then cursor ▌ blinking on half beats |
| Progress bar | x 72, y = max(1690, gridBottom + 50 + 52 × lines + 30); with no note, y = gridBottom + 70. Total width 636, N segments, gap 8, h 20. Border col@53%, radius 4 | 3 | 2 beats | Previous chapters full, current fills 0→1 (enter), later ones empty |

**Contact-sheet layout** for chapter photo count `n`:
- **n ≥ 10:** rows = clamp(2 + floor((n − 10)/8), 2, 5).
  - Rows 0–1: hero A (cols 0–1, 2×2) · col 2 ×2 · hero B (cols 3–4, 2×2) · cols 5, 6, 7 ×2.
  - Rows 2+: 8 tiles each.
  - Tiles = 10 + 8 × (rows − 2), up to 34. Hero A = the chapter's first photo, hero B = the 4th.
- **n < 10:** one row of up to 4 heroes (2×2).
- `gridBottom = 950 + rows × 118.5 − 12`.

**Laser zooms** (only on 16-beat cards). These pick out a few photos from the sheet so they can actually be seen. Three zoom cycles start at **lb 6, 9 and 12**, each 3 beats long. Tile picks: `rng(n×77+1)`, three different tiles.

| Element (cycle start c) | Position / size | Start | Dur | Effect |
|---|---|---|---|---|
| Laser | 4 px white core with glow `0 0 8/22/44px col`. Runs from the emitter (949, 252) to the centre of the tile (it follows the tile as it grows) | c | ½ beat | Length grows 0→full (enter) |
| Hit spot | 80 px radial: white → col 30% → 0, on the laser tip | c + ½ beat | — | Hit flare τ 0.25 |
| Scrim | Full frame `rgba(5,3,10,.72)` × z | c + ½ beat | — | Darkens the card behind the zoom |
| Zoomed photo | Grid rect → **(90, 480, 900 × 900)**. Radius 10→22, border 3→6 col | c + ½ beat | ½ beat | Enter. z = 0→1. Landing flare τ 0.3. Ken Burns 0.08 |
| Time label | Label box at (90, 1400): the photo's `takenAt` | with z | — | Opacity z |
| Laser off | — | c + 2 beats | ½ beat | Fade |
| Zoom back | Big rect → grid rect | c + 2.5 beats | ½ beat | easeInOutCubic |

On cards of 8 beats (Ch 2 here) there are no zooms: the highlight jumps on every beat instead.

**No note** (Ch 2 here): the typed line and cursor are omitted and the progress bar moves up to gridBottom + 70. The card still reads as complete: header, numeral, title, sheet, bar.

**No counts during the film.** Photo / note / tick totals appear only on the end card (§5.9).

### 5.4a Split — 17.143 s, 8 beats (Ch 1)

| Element | Position / size | Start (lb) | Dur | Effect |
|---|---|---|---|---|
| Strip i (i < n, n = 2–3) | x = 40 + i(sw + 26), y 440, h 1000. sw = (1000 − 26(n−1))/n (316 for 3). Radius 22, border 6. Colours pink / cyan / green | 0.5 i | 0.45 s | Wipe down: `clip inset(0 0 (1−e)% 0)`, enter |
| Pulse | Strip i | 2 + i and 5 + i | τ 0.3 s | Flare plus scale 1→1.035 |
| Ken Burns | kb 0.14 | scene | — | — |
| Label `{split.label}` | Label box at x 48, y 1760 | 1 | 0.3 s | Fade |

Label box: mono 500 38 px, ls 2, white text on `rgba(5,3,10,.8)`, padding 10/18, 1 px white@14% border.

### 5.4b Burst — 20.952 s, 8 beats (Ch 1)

Frames as (x, y, w, h, rot°, colour), painted in this order:
`[50,140,720,450,−3,pink]` `[340,560,680,420,2.5,cyan]` `[40,920,740,460,−2,green]` `[400,1240,600,380,2.5,violet]`

| Element | Start (lb) | Dur | Effect |
|---|---|---|---|
| Photo i pops in | 1 + i | 0.4 s | Pop: scale 1.25→1 (forward then settle), opacity in 0.13 s. Flare τ 0.3 |
| Photo i jumps forward again | 5 + i | 1 beat | Moves on top (z 10), scale × 1.06 then back over the last 40% of the beat. Flare τ 0.35 |
| Label `{burst.label}` | 1 | 0.3 s | Label box at x 48, y 1760 |

### 5.5b Timeline — 28.571 s, 12 beats (Ch 2)

| Element | Position / size | Start (lb) | Dur | Effect |
|---|---|---|---|---|
| Title `{chapter.title}` | x 72, y 110. Pink tube, core tint-violet. fit(760, 140, 0.46). Fixed, does not scroll | 0 | 0.5 s | Glitch-in, seed 41 |
| Item i (m ≤ 8, chronological) | Masonry, 2 columns: x 70 / 570, w 440, start y 330. h 280, or 560 for i = 1 and 6. Each item goes in the shorter column; column advances by h + 100 | 1 + 0.06 s × i | 0.4 s | Enter: fade, rise 40 |
| · time | Centred under the frame +14, mono 44 #ECE8F6 | | | |
| · frame | Violet border 3, radius 10, brightness 0.7 | | | |
| Highlight | Item j | 2 + j | — | Border 8, green, brightness 1, flare (0.4 + τ 0.3). Time turns tint-green + glow. Holds on the last item |
| Scroll | List translateY(−s) | 2 + j | 0.35 s | Scroll ease. s = clamp(itemCentreY − 900, 0, maxS), maxS = contentBottom − 1540 |
| List mask | Clear above 250 · solid 330–1470 · clear by 1600 | — | — | Keeps the safe zone free |

### 5.6b Peak — 41.905 s, 8 beats (Ch 3)

| Element | Position / size | Start (lb) | Dur | Effect |
|---|---|---|---|---|
| Laser fan | 9 beams from pivot (540, 1790), 18 × 1500, angles −80…+80 in steps of 20. cyan/pink alternating. Gradient colour → 0, blur 3, glow 30 | 0 | 0.6 s | Enter, then opacity 0.5 + 0.4 × beatEnv |
| Strip i (n = 3–5) | Box 250 × 1150, bottom centre on the pivot. Clip `polygon(0 0, 100% 0, 54% 100%, 46% 100%)`. Angle = (i − (n−1)/2) × 16°. Outline: polygon stroke 6, centre strip green, others pink, + white core 2 | 0.08 s × i | 0.6 s | Pop: rotate 0→angle. Outer strips painted first |
| Pulse L→R | Strip i | 2 + i, then all at 7 | τ 0.3 s | Flare, scale 1.03, z on top |
| Title | Centred, top 290. BSD 900 pink with chromatic. fit(820, 260, 0.42) | 0 | 0.5 s | Glitch-in, seed 61 |
| Label `{peak.label}` (time range only, e.g. `00:12 → 00:40`) | Centred, top 290 + 0.9·size + 30. Mono 40, white | 1 | 0.4 s | Fade |

### 5.7 Note — 45.714 s, 12 beats

| Element | Position / size | Start (lb) | Dur | Effect |
|---|---|---|---|---|
| Background photo | inset −60 (bleed), blur 28, brightness 0.5. Gradient overlay violet@0.35 → black@0.55 | 0 | 0.2 s | Fade in. Scale 1.15 → 1.07 linear over the scene |
| Tag `{tag}` | Centred, top 550. Label box, 40 px, border gradient cyan→pink | 0.5 | 0.3 s | Fade |
| Line i (max 5) | Centred, top 720 + i × 1.06 × size. Tube BSD 600, stroke 4. Colour [cyan, pink, cyan, green, pink][i]. size = fit(900, 210, 0.43) on the longest line | **1 + 2i** | 0.32 s | Tube-on flicker, glow 1 + 0.3 beatEnv |
| Signature `— {firstName}` | Centred, 40 px under the last line, mono 48 | 1 + 2 × lines | 0.4 s | Fade |
| Exit | — | t1 − 0.25 s | 0.25 s | Fade |

**Line split (app side):** uppercase; greedy word-wrap at 16 characters; up to 5 lines. A longer note is cut at the last whole word that fits and ends with "…".

### 5.8 Finale — 51.429 s (the drop), 16 beats

| Element | Position / size | Start (lb) | Dur | Effect |
|---|---|---|---|---|
| Drop flash | Flash overlay | 0 | τ 0.12 s | Opacity 0.5 (reduced 0.12, τ 0.4) |
| Photos appear | Each heart cell pops in **in place** (scale 0→1 pop, rotation ±20°→0, flare τ 0.3). Order: a seeded shuffle (`rng(424242)`, Fisher–Yates) | 0.5 + 5.5 × rank/cells | 0.35 s each | The heart shape builds up gradually from scattered photos |
| Heart outline | `HEART` path at box (90, 330, 900 × 810, scale 4.5), drawn 20 px outside the tiles. Pink stroke 2.6 vb + white core 0.9 vb, glow σ 1.6g / 4.8g | **6** (after all photos are in) | 2 beats | Draw: `pathLength 1`, dashoffset 1→0, enter |
| Heartbeat | Whole heart (tiles + outline) scales about (540, 735) | from 8, every beat | — | `1 + 0.05 × (flare(beat, 0.09) + 0.6 × flare(beat + 0.16 s, 0.09))`, a lub-dub (0.025 when reduced). Continues while the heart fades in Ending |
| Glow-up | Heart g 0.9→1.4, + 0.9 flare. Balloon + 0.9 flare. Tiles brightness + 0.6 flare (then + 0.15 holds) | 8 | τ 0.5 s | Plus a flash overlay at 0.22 (reduced 0.08) |
| Confetti burst 1 | 70 pieces from (540, 700) | 8 | 5 s | See below |
| Confetti burst 2 | 50 pieces | 12 | 5 s | — |
| Headline `{finaleHeadline}` | Centred, top 1230. BSD 900 chromatic d 5. fit(960, 150, 0.45) | 9 | 0.5 s | Glitch-in, seed 81, plus pop scale 1.3→1 |

`HEART = M100 172 C40 128 6 96 6 58 C6 28 28 8 56 8 C76 8 92 20 100 36 C108 20 124 8 144 8 C172 8 194 28 194 58 C194 96 160 128 100 172 Z` (viewBox 200 × 180).

**Heart cells:** a 44 px grid (20 columns, centred) over the heart box. A cell is used if all four corners (inset 3 px) are inside the path, which gives about 220 cells.
- Photo for cell k = `floor(k × N / cells) mod N`.

**Confetti** (piece k, seed s; t = T − burst; r = `rng(s×1000+k)`):
- angle a = −90° ± 80° (r), speed 900–2000 px/s, d = (1 − e^(−2.2t)) / 2.2.
- x = 540 + cos a · speed · d + 30 sin(4t + k); y = 700 + sin a · speed · d + 240 t².
- Size 8–16 × 14–26, colour pink/cyan/green/violet with a 10 px glow, rotation r·360 + t·(±450)°.
- Opacity 1 until t = 3 s, then linear to 0 at t = 5 s.

### 5.9 Ending — 59.048 s, 12 beats

| Element | Position / size | Start (lb) | Dur | Effect |
|---|---|---|---|---|
| Heart + tiles | Scale 1→0.85 about (540, 735) | 0 | 1.5 beats | Fade out |
| Headline, confetti | — | 0 | 1.5 beats | Fade out |
| Lasers | — | 0 | 3 beats | Fade to 0 |
| Balloon | COR → END (375, 330, 330 × 495) | 1 | 1.5 beats | Enter, g 1.2 |
| `{momentsCount} moments` | Centred, top 870. BSD 800, 150 px, chromatic d 4, lowercase "moments" | 3 | 0.5 s | Enter: fade, rise 24 |
| Final numbers `{photos} PHOTOS · {notes} NOTES · {ticks} TICKS` | Centred, top 1050. Mono 36, ls 3, #E7E3F2 | 4 | 0.5 s | Enter |
| `{title} · {date}` | Centred, top 1110. Mono 36, ls 3, pink + 14 px glow | 4.5 | 0.5 s | Enter |
| "Storyni" | Centred, top 1250. Neon tube BSD 800, 120 px, pink + cyan core, stroke 3 | 5.5 | 0.5 s | Enter |
| Fade to black | Full frame | 10 | 2 beats | Linear 0→1 → 64.762 s |

---

## 6. Flashing safety

- **Limit: no more than 3 flashes in any 1 s window.** At 126 bpm, beat-locked flares run at 2.1/s.
  - The finale's ½-beat photo changes (4.2/s) are **cuts between photos of similar luminance, with no white flash.** The frame flare only fires on whole beats.
  - Tube flicker is one dip per tube, and tubes are ≥ 0.5 beats apart.
- There are only 5 full-frame flashes in the film: three chapter slams (pink, radial, α ≤ 0.4), the drop (white→violet, α 0.5) and the glow-up at lb 8 (α 0.22). Laser-zoom hit spots are local (80 px). **There are no red full-screen flashes anywhere.**
- **Reduced-flashing version** (`reducedFlashing = true`, offer it as a user setting and use it whenever the OS has "reduce motion" on):
  - Tube flicker becomes a 0.3 s linear fade.
  - Glitch-in becomes a 0.3 s fade (no slices, no jitter).
  - Slam flash goes to α 0.12, τ 0.4. Drop flash to α 0.12, τ 0.4. Glow-up flash to α 0.08.
  - Every frame flare is ×0.4–0.5. Laser beat punch is ×0.4.
  - Contact-sheet and timeline highlights fade in over 0.15 s instead of switching instantly.
  - Laser-zoom hit and landing flares ×0.4.
  - Plan rows fade in over 0.2 s, without the flare.
  - Beat sync and all timings are unchanged, so both versions share one cue sheet.

---

## 7. Data the app fills

```ts
NeonNightFilm {
  title: string                 // 'NIGHT OUT', uppercase, ≤ 14 chars recommended
  date: string                  // 'SAT 14 NOV'
  place?: string                // used inside split/burst labels
  firstName: string             // 'Leo'
  monthYear: string             // 'NOV 2026' → rendered 'Nov 2026' in Ending
  photosTotal: int              // 20–200 → meta line
  notesTotal: int               // meta line
  videosTotal: int              // added to photos for the finale count
  plan: [{ time:'HH:MM', item:string, done:bool }]      // 0..n, first 5 shown
  chapters: [{                  // 1..5
    number: int, title: string, from:'HH:MM', to:'HH:MM', minutes:int,
    photos: Photo[],            // contact sheet (first 34 used)
    stats: { photos:int, notes:int, ticks:int },
    note: string | null,        // typed line; null → counted fallback
    moment:                     // exactly ONE per chapter, chosen by the app:
      | { type:'split',    label:string, photos: Photo[2..3] }
      | { type:'burst',    label:string, photos: Photo[2..4] }
      | { type:'timeline', photos: [{photo, time:'HH:MM'}] /*2..8*/ }
      | { type:'peak',     label:string, photos: Photo[3..5] }
    moment2?: same union        // optional second block (Ch 1 uses split+burst)
  }]
  noteMoment: { lines: string[1..5], tag:'NOTE 04 · 00:31', bgPhoto: Photo } | null
  finalePhotos: Photo[]         // all photos, chronological
  momentsCount: int             // shown as '{n} MOMENTS' (default photos + videos)
  finaleHeadline: string        // 'BEST NIGHT EVER' ≤ 18 chars (owner-picked, or the first line of noteMoment)
}
Photo { uri, takenAt:'HH:MM', focalX?:0..1, focalY?:0..1 }   // cover-crop on the focal point
```

Choosing a moment type: `split` for 2–3 photos within 10 min; `burst` for 2–4 photos within 1 min; `timeline` for 4+ photos spread across the chapter; `peak` for 3–5 starred or most-liked photos. Ch 1 → split + burst, Ch 2 → timeline, Ch 3 → peak, Ch 4+ → whichever type fits best.

---

## 8. How each block adapts

| Block | Fewer photos | No note | Long text |
|---|---|---|---|
| Ignition | — | — | Title fit(960, 230). Over 14 chars, the size drops to ~140 |
| Plan | 0 items → scene skipped (−5.714 s). 1–5 rows keep the 200 px pitch from y 520 | — | Item fit(440, 130). Over 13 chars, the size shrinks |
| Chapter card | Rows trimmed in steps of 8 (§5.3); 2–9 photos → 1–4 heroes | Counted line `> n PHOTOS IN x MIN` | Title auto-splits into 2 lines, fit(860, 170). Note wraps to 2 lines; stats move down |
| Split | 2 strips → sw 487 | — | Label is mono 38, no wrap. Keep under 24 chars |
| Burst | 2–3 frames → uses the first 2–3 slots; counter stops at that number | — | — |
| Timeline | 2–8 items; the highlight holds on the last one | Doesn't use a note | Title fit(760, 140) |
| Peak | 3–5 strips, always 16° apart | — | Title fit(820, 260) |
| Note | 1–5 lines; the signature follows the last line | `noteMoment = null` → scene skipped (−5.714 s; next cue moves up) | 16 chars per line, size fit(900, 210) |
| Chapter-card zooms | Needs ≥ 4 tiles; fewer → no zooms, highlight runs to the end | — | — |
| Finale | N < cells (~220) → photos repeat in order; N > cells → sampled evenly | — | Headline fit(960, 150) |
| Ending | — | — | `{n} moments` at 150 px fits n ≤ 9999 |

**Photo count 20–200:** the film length never changes with photo count. Only densities change (contact-sheet rows, mosaic sampling).

---

## 9. Chapter count → length

| Chapters | Blocks | Length |
|---|---|---|
| 1 | Card (4 bars, with zooms) + split + burst | 9 + 8 + 7 = 24 bars → 45.7 s |
| 2 | + card (2) + timeline (3) | 29 bars → 55.2 s |
| 3 (reference) | + card (4, with zooms) + peak (2) | 34 bars → 64.8 s |
| 4 | + card (2) + 1 moment (2) | 38 bars → 72.4 s |
| 5 | + card (2) + 1 moment (2) | 42 bars → 80.0 s |

- **Each extra chapter adds 4 bars = 7.619 s** (card 2 + moment 2). A timeline moment adds 3 bars (9.524 s) instead. A chapter whose card gets laser zooms adds 2 more bars (3.810 s).
- **Zoom rule:** the first and the last chapter get the 16-beat zoom card; middle chapters get the 8-beat card. With 1 chapter, it gets the zoom card.
- Plan (3 bars) and Note (3 bars) are optional. Skipping them shortens the film by 5.714 s each. Finale (4) + Ending (3) always close the film.
- The drop always falls on the Finale cue (a downbeat). Schedule the track's drop there, or cut the track so its drop lands on that bar.

---

## 10. Render checklist

- Fonts: Big Shoulders Display (400–900) and JetBrains Mono (400–800), loaded before the first frame.
- Neon strokes need a blur-based glow (Flutter: `MaskFilter.blur` or `ImageFilter.blur` on a saveLayer). The glow colour must match the stroke colour.
- Use the same seeds (§3.3) on every platform; two renders at the same T must match pixel for pixel, apart from codec noise.
- Export at 30 fps: frame f is rendered at `T = f / 30`.
