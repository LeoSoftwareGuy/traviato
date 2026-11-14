# Neon Night — reference (#363)

- `NEON_NIGHT_SPEC.md` — the full spec. The prototype it names (`Neon Night Film.dc.html` + `neon-night.jsx`) was not provided, so **the spec and the MP4 are the reference**.
- `NeonNight.mp4` — reference render of the 3-chapter film, 64.77 s at 30 fps. It is **608 × 1080 with no audio**, not 1080 × 1920: compare frames scaled, and music sync can't be checked against it.
- `stills/` — frames from the MP4 at every §5 cue (`cueNN_…`) plus one or two in-scene beats per scene (`…_lbN` = local beat N), named by film time. Use them for side-by-side checks.

Regenerate a still: `ffmpeg -ss <seconds> -i NeonNight.mp4 -frames:v 1 -q:v 3 stills/<name>.jpg`

## Decisions that override the spec

- **Every long chapter card plays laser zooms**, however few photos the chapter has (overrides §8's "needs ≥ 4 tiles; fewer → no zooms"). Each tile is zoomed at most once: 3+ tiles → 3 zooms (lb 6, 9, 12), 2 tiles → 2 zooms (lb 6, 9), 1 tile → 1 zoom (lb 6). See `NeonZoomPicks`.
- **Card length:** middle chapters get the 8-beat card. The first and last chapter get the zoom card: 16 beats with 3+ photos, **12 beats with 1–2 photos** (each zoom takes 3 beats from lb 6, kept to whole bars so the drop stays on a downbeat). That chapter's film is 1 bar (1.905 s) shorter.
- **Film lengths for 1 and 2 chapters follow the scene rules** (23 and 30 bars), not §9's table (24 and 29).
- **A chapter with no note has no typed line** and its bar moves up to gridBottom + 70 (§5.3, and the MP4's Ch 2). §8's counted fallback line (`> n PHOTOS IN x MIN`) is not used: no counts during the film.
- **The laser zoom's hit spot stays lit while the laser is on** (0.55 + the τ 0.25 hit flare), as in the MP4; the spec has only the flare.
- **The ghost numeral's box is line-height 1.12**, which puts its glyph tops at y ≈ 275 like the MP4's (the spec's y 230 is the CSS box).
- The reference's Ch 1 has **34 photos** (5 sheet rows, as in the MP4 at 15.7 s); Ch 2 has 12, Ch 3 has 40.
- **Ken Burns on the moments:** the spec gives only Split's (0.14). Burst uses 0.08, Timeline 0.06 and Peak 0.10, all within §3.5's 0.06–0.15.
- **Moment labels are built from the data**, so they translate: Split `{time} · {PLACE}` (only the time without a place), Burst `BURST · {time}` (`neonNight_burst`), Peak `{first} → {last}`.
