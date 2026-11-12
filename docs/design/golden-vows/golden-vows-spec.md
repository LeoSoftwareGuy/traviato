# Storyni — "Golden Vows" memory video (exact reference)

Portrait 1080 × 1920, 30 fps, 70 s. Coordinates are in px from the top-left. Times are in seconds.
Eases use the standard names: power2/power3 in/out/inOut, sine.inOut, back.out(2), linear.
Opacity values are written 0–1; colour alpha is written @0–255.

## 1. Look

### Colours (RGB)
- ivory 250,245,236
- ivoryDeep 242,232,214
- paper 255,252,246
- gold 190,148,78
- goldLight 230,202,146
- goldDeep 138,100,44
- ink 66,50,34
- inkSoft 134,112,88
- blush 240,210,200
- peach 255,204,160

### Fonts
- Serif: Cormorant Garamond. Weight 500 for names and the wordmark, 600 for the uppercase small caps (letter-spacing 8–12).
- Script: Pinyon Script, for titles and handwritten notes.

### Background
A vertical gradient from ivory (top) to ivoryDeep (bottom).

### Layer order (bottom → top)
background · light leaks · intro · plan card · album · heart layer · end mark · gold frame · light flare · petals

### Music
A 70 s warm piano, strings and celesta piece (~70 bpm), no drums or vocals. The big swell is at 53–58 s, so the heart forms on it.

## 2. Seeded random (identical every render)
```js
const rng = seed => { let s = seed >>> 0; return () => (s = (s * 1664525 + 1013904223) >>> 0) / 4294967296; };
```

## 3. Ambient (0 → 70)

### Light leaks
Circles, blur 170, opacity 0.32.
- A: centre 120,260, r420, peach, drifts +260,+180
- B: centre 960,980, r480, goldLight, drifts −300,+220
- C: centre 300,1700, r380, blush, drifts +220,−260

Each drifts to its offset and opacity 0.45 over 17.5 s, back and forth 4 times (sine.inOut).

### Petals
16 of them, seed 11. Colours cycle blush, paper, goldLight, blush, peach.

Per petal, draw these values in this order:
- big = r()
- x = r()·1080
- w = 22 + big·22
- h = 13 + big·12
- dur = 10 + r()·7
- phase = r()
- rot = r()·360
- spin = (r() > .5 ? 1 : −1)·(200 + r()·400)
- sway = 40 + r()·70
- alpha = 170 + round(r()·70)

Each petal is a pill-shaped rect w×h (radius h/2) with a soft shadow.
- It falls linearly from y −60 to 2000 in dur seconds, looping. The first fall starts at y = −60 + phase·2060.
- It sways ±sway px with sine.inOut, back and forth, at about 2.8 s per leg.
- It rotates linearly by spin·7°.

### Gold double frame
- Outer: rect inset 52, gold, 2.5 px.
- Inner: rect inset 68, gold@140, 1.2 px.

Both draw on starting from the top-centre.

### Flare
A 520×2800 strip at x −900, y −400, rotated 18°, blur 90. It is a horizontal gradient: transparent → warm 255,214,150 @200 → transparent.

On every page turn it sweeps x −900 → 1500 while opacity goes 0 → 0.6, over 1.6 s (power1.inOut), starting 0.3 s into the turn.

## 4. Balloon mark (200×292 drawing; replace with the real Storyni logo)
- Envelope path: `M100 4 C158 4 196 48 196 104 C196 156 160 190 132 222 L68 222 C40 190 4 156 4 104 C4 48 42 4 100 4 Z`. Fill: horizontal gradient goldLight → gold (55%) → goldDeep.
- Gore lines: `M100 6 C66 42 62 160 84 222` and `M100 6 C134 42 138 160 116 222`, paper@150, 3 px.
- Band: rect 66,220 68×9, goldDeep.
- Ropes: `M70 229 L85 262` and `M130 229 L115 262`, goldDeep, 2.5 px.
- Basket: rect 82,260 36×30, radius 5, goldDeep.

## 5. Sequence

### 5.1 Invitation (0–5.6)
All text is centred across the full width.
- 0.2 / 0.45: outer / inner frame draw on over 2.6 s (power2.inOut).
- 0: balloon at x 440 rises y 1980 → 330 over 3.6 s (power2.out). It rocks −6° ↔ 4°, 1.8 s per leg, 3 legs.
- 1.5: "Our Wedding Day" (script 104, gold) fades in, y 740 → 700, 1.6 s (power3.out).
- 1.9: "Anna & Marco" (serif 500, 128, ink, y 840) fades in. Letter-spacing 24 → 2 and blur 10 → 0, over 2 s (power3.out).
- 2.5: gold rule (x 390, y 1020, 300×2) grows from the centre, 1.4 s.
- 2.8: "14 · 06 · 2026" (serif 600, 40, spacing 10, inkSoft) moves y 1080 → 1060 and fades in, 1.2 s.
- 3.05: "Lake Bled, Slovenia" (serif 44, inkSoft) moves y 1140 → 1120 and fades in, 1.2 s.
- 4.6: balloon flies up to y −420, 1.6 s (power2.in).
- 5.0: the texts rise 60 px and fade out, 0.9 s, 0.06 s apart.
- 5.2: the frames fade out, 0.8 s.

### 5.2 Packing card (5.4–12.9)
The card is at x 110, 860 wide, 1090 tall (330 + 5·138 + 70), rotated −2°.
- Card: paper, radius 8, soft shadow (blur 50). Gold@170 inner border inset 24.
- Heading: "Before the big day", script 96, gold, y 70.
- Subhead: "WHAT WE PACKED · 5 OF 5", serif 600, 30, spacing 9, inkSoft, y 222.
- Item i sits at y 330 + i·138:
  - a gold circle outline, centre 118,44, r 27, 2 px;
  - a tick `M104 44 L115 57 L135 30`, goldDeep, 5 px;
  - the text at x 176, y 10, serif 500, 54, ink.
- Items: Rings, triple-checked · Grandma's pearl earrings · Vows, written at 2am · Flat shoes for dancing · Tissues. So many tissues.

Timing:
- 5.4: the card rises y 2000 → 360 and rotates 6° → −2°, 1.4 s (power3.out).
- 6.3 + i·0.14: item i slides in from +40 px and fades in, 0.8 s.
- 7.4 + i·0.8: tick i draws on, 0.45 s.
- 6.8: the card rotates slowly to 1° over 4.5 s.
- 11.9: the card flies up to y −1500 at −10°, 1.0 s (power2.in).

### 5.3 The album (11.9–61.4)

**Geometry**

The spine is at x 70. A page is the rect x 70, y 220, 940×1480.
Every page and the cover hinge on the spine: they rotate around the vertical axis at x 70, with perspective 2600.

Each page has:
- an ivory base (radius 6);
- a gold@170 hairline inset 18;
- its content;
- an ink shade overlay, starting at 0.

Album stack (bottom → top):
- back board: rect 80,232 940×1480, goldLight, big soft shadow;
- page edge: rect 75,226, paper;
- the pages, with page 1 on top;
- the cover: paper, a 3 px gold border inset 30, and the balloon at 440,814 scaled 1.1. No text.

**Page turn (1.25 s)**
- The page rotates 0° → −100° (power2.inOut): the free edge swings towards the viewer and past the spine.
- The shade goes 0 → 0.32 during the first 0.875 s.
- The page fades out during the last 0.25 s.
- The flare sweeps across.
- The page underneath becomes visible the moment the turn starts.

**Every photo**
- It is cover-cropped inside its mat.
- It zooms slowly 1 → 1.08 (sine.out), from when its page starts to show until its page has turned away.

**Schedule**
- 11.9: the closed album rises y 1950 → 0 and rotates 3° → 0°, 1.2 s (power3.out).
- 12.9: the cover turns.

Each page then stays fully open for its dwell time, and the next turn starts:

| page | type | open | turns at |
|---|---|---|---|
| 1 | photo with note | 14.15 | 17.15 |
| 2 | photo with note | 18.40 | 21.40 |
| 3 | photo with note | 22.65 | 25.65 |
| 4 | photo with note | 26.90 | 29.90 |
| 5 | chapter (3 photos) | 31.15 | 34.55 |
| 6 | chapter | 35.80 | 39.20 |
| 7 | chapter | 40.45 | 43.85 |
| 8 | carousel | 45.10 | 51.10 |
| 9 | heart | 52.35 | never |

The rule behind the table: dwell is 3.0 s for a photo-with-note page, 3.4 s for a chapter, 6.0 s for the carousel and 9.0 s for the heart. Each turn takes 1.25 s.

**Photo-with-note page**
- Frame: at 150,300, 780×960, rotated (−2, 1.8, −1.2, 2.2)° for pages 1–4. Paper, soft shadow.
- Photo: 712×800 at 34,34, with a gold 1.5 px hairline 12 px outside it.
- Caption: e.g. "THE VOWS · 15:10", serif 600, 30, spacing 8, gold, centred, y 876.
- Note card: 640×190 at x 310 (pages 1 and 3) or x 130 (pages 2 and 4), y 1300, rotated +3° / −3°. Paper, with a goldLight tape strip 60×28 at 290,−14 rotated −4°.
- Note text: script 66, ink, centred.

Page contents:
- Photo: the couple in an embrace. Note "You cried before I did." Caption "THE VOWS · 15:10".
- Photo: the bride's bouquet. Note "Picked from Mum's garden". Caption "THE BOUQUET · 11:40".
- Photo: rings. Note "Gold, like that evening". Caption "THE RINGS · 15:22".
- Photo: a dance at sunset. Note "Barefoot by the last song". Caption "FIRST DANCE · 21:05".

**Chapter page**
- Title: script 92, gold, y 268.
- Line: serif 600, 28, spacing 9, inkSoft, y 398.
- Prints: paper mat with a 14 px border and a soft shadow. Each spot below is (x, y, w×h, rotation):
  - Layout A: (120,470, 840×600, −1.2°), (120,1100, 405×520, 1.5°), (555,1100, 405×520, −1°)
  - Layout B: (120,470, 470×1150, −1°), (620,470, 340×560, 1.6°), (620,1060, 340×560, −1.4°)
  - Layout C: (120,470, 405×520, −1.5°), (555,470, 405×520, 1.2°), (120,1020, 840×600, 1°)
- Chapters, cycling the layouts in order A, B, C:
  - "Getting ready" · CHAPTER ONE · MORNING
  - "The ceremony" · CHAPTER TWO · MIDDAY
  - "Just married" · CHAPTER THREE · AFTERNOON

**Carousel page**
- Title "And the night went on" and line "CHAPTER FOUR · EVENING", styled as on the chapter pages.
- A cropping window at 84,470, 912×1180, holds two rows of 6 prints:
  - each print is 460 tall, with width = round(430·clamp(aspect, 0.68, 1.45)) + 30;
  - gap 36, 15 px border, tilts alternating ±1.8°;
  - row 1 sits at local y 20, row 2 at local y 570.
- Over the page's whole visible life (8.5 s, sine.inOut):
  - row 1 moves from x 40 to x −1460;
  - row 2 moves from x (870 − rowWidth) to that +1500.

**Heart page**
- Title "Every moment", line "{N} MOMENTS · ONE DAY".

### 5.4 Heart → balloon (h0 = 52.35)

**Cells (works for N = 20–200)**
```js
const HX = 540, HY = 900, K = 370;
const inside = (x, y) => { const a = x*x + y*y - 1; return a*a*a - x*x*y*y*y <= 0; };
function cells(c) {
  const out = [], n = Math.ceil(1.4 * K / c);
  for (let j = -n; j <= n; j++) for (let i = -n; i <= n; i++) {
    const px = (i + .5) * c, py = (j + .5) * c;
    if (inside(px / K, -py / K + 0.1)) out.push({ x: HX + px, y: HY + py });
  }
  return out;
}
let c = 340, cl = cells(c);
for (let k = 0; k < 300; k++) { const c2 = c * .985, t = cells(c2); if (t.length > Math.max(N, 44)) break; c = c2; cl = t; }
```

**Tiles**

One square tile per cell, size c − 4, with a paper border of max(2.5, 5%) and a small shadow. Photos repeat only if N < 44.
Start positions use seed 53. For each tile: a = r()·2π; start = (HX, HY) + 1450·(cos a, sin a); tilt = r()·70 − 35.

**Confetti**

54 pieces, seed 29, colours cycling gold, goldLight, paper, blush, goldDeep.

Per piece, in this order:
- a = r()·2π
- d = 260 + r()·520 (then dx = cos a·d and dy = sin a·d·0.9 − 120)
- w = 10 + r()·16
- h = 6 + r()·8
- rot = r()·720 − 360
- fall = 500 + r()·500
- round = r() > 0.7 (a round piece is a w×w circle)

**Timing (from h0)**
- +0.2 + (i/M)·2.0: tile i flies to its cell and straightens, 1.2 s (power3.out). M is the number of tiles.
- +3.4: the heart beats twice, scaling 1 → 1.05 around 540,900 (4 legs of 0.35 s).
- +3.45: confetti bursts from the heart centre to centre + (dx,dy) and rotates to rot, 1.1 s (power3.out). At +4.55 it falls by fall, rotates to 2·rot and fades, 2.6 s (power1.in).
- +4.0 and +4.1: ropes draw on, 0.8 s each, from (474,1241) to (508,1399) and from (606,1241) to (572,1399). goldDeep, 3 px.
- +4.4: "Forever starts here" (script 88, gold) fades in, y 1560 → 1520.
- +4.6: the basket (rect 498,1395, 84×60, radius 8, goldDeep) pops in, y +32 → 0, back.out(2).
- +6.0: the line fades out.
- +6.2: the heart and basket rise to y −2100, 2.8 s (power2.in), tilting 3°.

### 5.5 Album closes (59.95)
- The cover reappears and swings back, −100° → 0° over 1.3 s (power2.inOut), as its shade clears.
- 61.35: the closed album rises 320 px, shrinks to 0.92 and fades out, 1.0 s (power2.in).

### 5.6 Storyni ending (e = 60.95 → 70)
- e: the balloon (scale 1.25, x 440) descends y −420 → 560, 2.6 s (power3.out), then bobs gently between 560 and 530 until the end.
- e+1.2: the gold frame fades back in, 1.6 s.
- e+1.4: "Storyni" (serif 500, 150, ink, y 1000) fades in, letter-spacing 40 → 8, blur 10 → 0, 2 s.
- e+2.4: a gold rule (440,1205, 200×2) grows in.
- e+2.7: "ANNA & MARCO · 14 JUNE 2026" (serif 600, 32, spacing 8, inkSoft) rises y 1265 → 1245 and fades in.
- 68.6: everything fades out over 1.4 s.

## 6. Data the app fills per memory
- names
- occasionLine (wedding / engagement / anniversary / date night)
- date
- place
- endLine
- plan[] (max 5 shown)
- heroes[] {photo, note, caption}: one page each
- chapters[] {title, line, 3 photos}: one page each
- carouselPhotos[12]
- allPhotos[20–200], which build the heart

Each extra photo-with-note page adds 4.25 s, and each extra chapter adds 4.65 s.

## Not included
The music track and the balloon logo. The spec describes the music so a similar licensed track can be sourced. The balloon above is a drawn placeholder: use the real Storyni logo in its three places (intro, album cover, ending).