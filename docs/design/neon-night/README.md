# Neon Night — reference (#363)

- `NEON_NIGHT_SPEC.md` — the full spec. The prototype it names (`Neon Night Film.dc.html` + `neon-night.jsx`) was not provided, so **the spec and the MP4 are the reference**.
- `NeonNight.mp4` — reference render of the 3-chapter film, 64.77 s at 30 fps. It is **608 × 1080 with no audio**, not 1080 × 1920: compare frames scaled, and music sync can't be checked against it.
- `stills/` — frames from the MP4 at every §5 cue (`cueNN_…`) plus one or two in-scene beats per scene (`…_lbN` = local beat N), named by film time. Use them for side-by-side checks.

Regenerate a still: `ffmpeg -ss <seconds> -i NeonNight.mp4 -frames:v 1 -q:v 3 stills/<name>.jpg`

## Decisions that override the spec

- **Every long chapter card plays laser zooms**, however few photos the chapter has (overrides §8's "needs ≥ 4 tiles; fewer → no zooms"). Each tile is zoomed at most once: 3+ tiles → 3 zooms (lb 6, 9, 12), 2 tiles → 2 zooms (lb 6, 9), 1 tile → 1 zoom (lb 6). See `NeonZoomPicks`.
- **Card length:** middle chapters get the 8-beat card. The first and last chapter get the zoom card: 16 beats with 3+ photos, **12 beats with 1–2 photos** (each zoom takes 3 beats from lb 6, kept to whole bars so the drop stays on a downbeat). That chapter's film is 1 bar (1.905 s) shorter.
- **Film lengths for 1 and 2 chapters follow the scene rules** (23 and 30 bars), not §9's table (24 and 29).
