# Storyni — MVP Functionality (v5)

> One-liner: the place where your travel life lives — plan your memory, log it as you
> go, and it becomes a beautiful journal you keep forever.

v5: bonus-task mechanic v2 (daily tray). Source of truth for screens: the **redesign handoff** (`docs/design/` — 13-screen
design reference `Wander - Travel Memory Journal.dc.html` + README with tokens,
interactions, motion). Supersedes the "Leo's team library" Figma file. A Figma copy
can be made via `traviato-figma-import.html` (html.to.design).

**Canonical values note:** where the design mockup's sample values conflict with our
data model, the data model wins: quest completion = 1 star flat (no per-quest
values), photo = 2 stars, the existing 10-vibe list, and the existing 8-achievement
set. Mockup copy showing other numbers is adjusted at implementation.

## Product language (ALL UI copy)

- Trip = **memory** · points = **stars ✦** · generated recap = **wrap-up**.
- App name: **Storyni** (decided 2026-10-11, #191; pronounced "sto-REE-nee"). Always
  one word, capital S only. It replaces the working name "Trevy" and the design files'
  "Traviato"/"Wander". `traviato` is the **codename** — repo, Dart package, DB and
  code identifiers keep it. The iOS bundle id and Android application id are
  `com.leo.storyni` (#200, #210). In code, use `AppConstants.appName`.
- UI languages: **English and Russian** (#220), following the phone by default
  with an override in You → Settings. Estonian users read the app in English;
  journal **dictation** also offers Estonian (#218, #245).

## 1. Guest landing ✅

- Pre-auth marketing screen: star specks, hero image with overhanging polaroids,
  eyebrow + serif headline ("Every memory, *beautifully captured*"), occasion chips
  (Weddings · Trips · Birthdays · Milestones — positioning beyond travel),
  how-it-works cards (third card highlighted), sample memories scroller,
  testimonial, sticky pulsing CTA ("Start capturing your moments") + Log in.
- Static content in MVP.

## 2. Auth ✅ — redesigned

- Single screen, segmented toggle Create account | Log in; mono field labels,
  focus states, password-strength segments; reward-tease card ("first memory earns
  10 stars"). Supabase email/password unchanged.

## 3. Home ✅ — redesigned

- Header: mono date eyebrow, "Hello, {name}"; **stars badge (tappable → Bonus
  tasks)**; avatar → Profile.
- Stats bar: Memories · Places · Days.
- **Happening now** hero card: cover, Day X of Y + vibe chips, title, place/dates,
  thin trip-progress bar; actions Plan · Expenses · **Journal (primary)**; dashed
  full-width **Checklist** row with packed count.
- **Coming up**: cards with countdown badge, planning state ("6 quests planned" /
  "Nothing planned yet"), **whole card taps into Plan** (plan months ahead).
- **Kept forever**: finished-memory grid, ▸ Recap badge, days + photo count.
  Tap: a memory not kept yet → Journal (#101); a kept one → the **Kept
  Memory page** (§17, #279, #281).
- Bottom nav: Home · **balloon ＋** · Expenses — 28 pt tab icons; the centre is
  the Journal's hot-air balloon in the CTA gradient with a "+" on its
  envelope, rising above the bar; tap creates a memory (#424).
- **Kept forever** grid: two columns that fill Home's side padding (equal
  left/right gaps on every phone), tiles keep their aspect (#424).

## 4. Create memory ✅ — redesigned, + cover picker

- One screen: name, where, start/end dates, **vibe chips** (canonical 10:
  Romantic, Adventure, Cultural, Chill, Foodie, Road trip, Wellness, Wildlife,
  Nightlife, Photography), reward-nudge card, Create CTA.
  At most **3 vibes** (#432) — a 4th tap shows "Pick up to 3"; memories made
  before keep theirs.
- **NEW — cover picker**: 8 bundled cover options as thumbnails; explicit choice,
  or **auto-suggestion from the first selected vibe** (mapping in handoff);
  empty-state slot shows "Choose a cover / or we'll pick one that suits the vibe".
  Custom photo upload for covers: see open questions.

## 5. Manage memory ✅ — NEW (sheet, from Plan)

- Rename; **edit dates** — the Starts/Ends cards open the date picker; quests
  move with the start date, notes/photos/bonus tasks keep their calendar date,
  and anything left outside the new range is deleted after a two-step warning
  with exact counts (#271; the old ±1-day tap is gone); change cover (same
  thumbnail strip); **two-step delete** (armed state shows consequences:
  photos and notes are removed and **the memory's earned stars are lost**,
  can't be undone — #247; unlocked badges stay).

## 6. Plan (day quests) ✅ — redesigned

- Cover **banner** with dates + Day X of Y pill; summary line ("25 quests planned ·
  5 days total"); day pager with segment dots; **timeline rail** with check
  circles, mono times, quest titles + detail lines; check-off awards ✦1 (flat) via
  RPC + star toast; dashed "+ Add a quest to Day N"; top-right ☑ Checklist and
  ⋯ Manage buttons.

## 7. Checklist ✅ — redesigned

- Overall gradient progress bar + "X of Y packed"; category tabs with inline
  counts (5 categories: travel_essentials, clothing_shoes, toiletries_health,
  gadgets_tech, nice_to_haves); Essential badges (coral); check-off (toast, no
  stars); dashed custom-add row.

## 8. Journal ✅ — redesigned

- Day tabs as photo tiles (active = primary border); day title + sub-line; note
  card (italic serif body, "EDITED · N WORDS" footer, ✦1 via RPC; the whole note is editable in the note page, and
  clearing it + confirming deletes it — #276; since #397 the ✦1 stays);
- **Many timed notes per day** (#397, Option B, `docs/design/journal-notes/`):
  every Done saves a separate note with its own time; ✦1 per new note, at
  most 3 per day; edits and deletes never change stars. Notes and photos
  after midnight stay on the evening's day (logical-day rule: until 08:00,
  a new day only after a 4-hour break). Storyteller counts days with notes.
  Data landed in #400. Old day notes became one "earlier note" each.
- **Photo notes** (#402): the photo viewer has "✎ Add a note to this
  photo" and lists NOTES ON THIS PHOTO · N. The note page shows the photo's
  polaroid with its time and caption (else its place). A photo note keeps
  its own time on the timeline, with an "On photo" chip; the photo gets ✎.
- **One timeline** (#401): the day is one rail of photos and notes by time
  (photos ≤ 20 min apart share a row: 1 / 2 / 3 + "+N"), an AFTER MIDNIGHT
  divider, and a LATER section for things added after the day was over.
  Notes fold at 4 lines ("more" / "less"); long-press → Edit / Delete (with
  a confirm), or on iOS swipe left → Delete. A saved note's slot opens and
  the card drops in with one orange glow; a deleted one folds away (#407;
  crossfades under reduced motion). A floating Photo | Note bar — since #424 in the Home nav's style (same surface,
  icons and labels, two equal halves, no balloon; the balloon moved to Home's
  "+") — is the Journal's only bottom control — no app bottom bar there (#410); an empty
  day shows a notebook page with "Write the first note ✦1". The Journal
  opens on the logical today (after midnight, the evening before).
  photos strip ("TODAY'S PHOTOS · N", **add tile awards ✦2** on successful photo,
  tiles → Photo detail; long-press a timeline photo (450 ms) → a sheet with
  its preview and Delete photo → "Delete this photo?" confirm, then it folds
  away like a note (#424). The photo viewer has close top-left, delete
  top-right, and asks the same confirm before deleting (#424); "▸ N IN THE FILM" + per-thumb film badges, #294);
  "To Do · N left" → Plan; **"View wrap-up ▸"** gradient button — it
  unlocks at **15 photos and 1 note** for the whole memory (#432, no
  per-day rules; the guide line says what's missing; kept films are never
  locked);
  achievement-nudge card with progress ring.
- **In the film** (#294, `docs/design/photo-pick/`): the day's photo viewer
  has an Auto · Always · Leave out control per photo, saved at once.
  A film shows at most **60 photos**, so Always stops at 60 and the panel
  counts the picks ("23 / 60", #432). Always
  photos get a main moment first; Leave out photos appear nowhere in the
  film. Never an AI call. **Always means you see it (#378):** in every film
  an Always photo gets a real moment — a Sky Story page (a busy day spreads
  over extra pages, up to 5 in all), a Golden Vows hero, chapter or
  carousel photo, a Neon Night moment. The decorative endings (Sky Story's
  balloon mosaic, the Golden Vows and Neon Night hearts) are made of the
  other photos; Always photos only top them up below 12 photos, or appear
  there when more than Sky Story's 5 pages × 5 photos are marked. A kept film whose photos changed offers "Photos
  changed · Rebuild film" (film HUD + Kept Memory page) — rebuilt on tap,
  keeping its AI lines. The all-days "Choose photos" screen is #294 part 2.
- Days where `day_date > today` are locked (no note/photo entry, blurred
  balloon thumbnail); `day_date <= today` are open/bright. (Reinstated — see
  issue #118.)

## 9. Photo detail + tagging ✅ — NEW, in MVP

- Full-bleed photo, day/time + place overlay, pager dots.
- Place row (place text + coordinates when geotagged, "Change").
- **WHO WAS THERE**: person chips (free-text people, tag/untag), + Add.
- Caption card (tap to edit).
- Actions: **Set as cover** · **Use in wrap-up** (marks photo for the generator).

## 10. Expenses ✅ — reworked

- Overview: search, sort toggle (**latest-first default** ⇄ biggest spender),
  memory rows with total, meta, **relative spend bar** (÷ max), "Load 3 more"
  pagination (page size 3).
- **Selected-memory breakdown**: TOTAL SPENT + PER DAY AVG cards, BIGGEST
  CATEGORY card, BY CATEGORY bars (÷ largest category), ALL EXPENSES list
  (zebra rows, sorted by amount desc). Empty state prompts selection.
- Add-expense sheet: memory selector, description, amount (€), 6 category chips
  (Food & drinks, Transport, Accommodation, Activities, Shopping, Other), date.
- EUR only in MVP.

## 11. Expenses · Compare ✅ — NEW, in MVP

- Pick a pair (A = orange, B = purple; promote/swap rules per handoff).
- FINANCIAL COMPARISON table: per-category amounts side by side (**larger value
  emphasized**), missing = "—", Total + Per-day rows; computed **verdict card**
  ("X cost €N more overall, but Y ran €N/day higher…").
- "Done comparing" clears. All values derived client-side — no schema impact.

## 12. Bonus tasks ✅ — mechanic v2 (daily tray)

> Principle: a quest is your plan; a bonus task is the app's invitation.
> It must never feel like homework.

- **Daily tray:** 2 tasks per day of an active memory, valid until end of day
  (local time). No countdown clocks — "today" framing. **Day one: 3 tasks**,
  one of them a trivially easy starter ("Snap anything at all").
- **Source:** a seeded pool of ~30–35 task *templates* (shapes with slots
  filled from vibe/destination/day), each tagged with a **phase**
  (arrival / middle / departure / anytime) and a **kind** (regular / starter /
  stretch / milestone / streak_saver). Weather slots: post-MVP.
- **Draw:** deterministic per (memory, day) — reopening the app never
  reshuffles. Phase-filtered (arrival only on day 1, departure only on the
  last day). **No template repeats within 10 days** per memory.
- **Unfinished tasks vanish silently** at day end. No failed state, no red,
  nothing accumulates. This is the load-bearing rule.
- **Both done:** calm earned state ("Both done · ✦N today. New ones
  tomorrow"), no refill; unlocks one **opt-in stretch task** (✦3).
- **Streak-saver:** if nothing logged for 2 straight days, one ✦2 task
  appears and persists until acted on (max one active).
- **Milestones:** days 7 / 14 / 21 of long memories each add one ✦5
  reflective task.
- Completion = photo capture → stars via RPC + award toast.
- **Design deviation from handoff §10 (intentional):** no hard countdowns or
  coral urgency; a 2-slot tray with an earned state instead. Completed
  section keeps "COMPLETED · DAY N" rows.
- **Star economy note:** no daily bonus cap in MVP (stars aren't spendable);
  revisit when redemption exists.

### Notifications (local, no push infrastructure) — reworked (#307)

- **Planned ahead**, not only from app opens: every evaluation (app open/
  close, memory create/edit/delete) schedules the next 14 days of the
  memory that's underway, so a day the app is never opened still gets
  reminders. Today's entries follow what was actually logged.
- **Each day of a memory, at most 2:** ~9:00 "Day N of {name} ✦" (day one
  uses the arrival reminder instead); ~19:00 "Nothing from today yet" — or
  "Still time for a dare" if something was logged but a task is open; none
  if something was logged **and** the tray is done.
- **Last day:** ~9:00 "Last day of {name} ✦" and ~18:00 "Bonus tasks end
  tonight".
- **Day after the end:** one ~10:00 "{name} has ended — keep it forever"
  (opens the Journal; skipped once kept).
- Silence rules: never after 21:00; times already past are skipped. After
  three days without the app being opened, only the evening reminder is
  left (last-day and after-end ones stay) — opening the app resets it. The
  old sticky "mute after 3 ignored" is gone.
- **You → Settings → Memory reminders** on/off (default on); off cancels
  everything, arrival reminders included. The permission rationale is shown
  once, after the first memory is created.

## 13. Stars ✅

- Ledger server-side; values: note 1 (at most 3 a day, #397) · photo 2 · quest 1 · bonus per template.
- **Star award toast** (shared component): "✦ +2 stars · photo logged" etc.,
  auto-dismiss ~1.65s; the only success affordance (no snackbars for awards).
  Unchecking never removes stars.

## 14. Location capture — backend (unchanged)

- Auto geotag on photo upload (permission-gated, never blocks); optional place
  text on quests/photos; feeds wrap-up map + Places/Countries stats.

## 15. Wrap-up playback ✅ — NOW DESIGNED

- One long controlled scroll (user-driven, not autoplay):
  **Hero** (ken-burns cover, staggered title reveal) → **Chapter one · The route**
  (animated route draw, node dots, place labels, KM/stops stats) → **Chapter two ·
  What you saw** (photo beats with ken-burns + second-person AI narrative in
  italic serif) → **Chapter three · By the numbers** (stat cards with animating
  bars) → **Achievement moment** (badge unlocked card) → close line + "Open
  journal" / "Keep forever".
- Generation pipeline unchanged: edge function → Anthropic → screenplay JSONB in
  `wrap_ups.content`; app renders live; MP4 export post-MVP.
- **The film comes from the vibes (#433):** Romantic → Golden Vows,
  Nightlife → Neon Night, Adventure / Road trip / Wildlife → Field Notes
  (Sky Story until it ships), everything else → Sky Story; with several
  vibes Romantic > Nightlife > outdoors > the rest. Code decides it before
  the director runs, and the director only fills that film's plan — never
  another film. Under View wrap-up: "Film style: Neon Night". The chosen
  film always plays: what the director gets wrong is repaired (banned
  phrases out of AI lines, lines cut at a word, a day with one photo joins
  the next, Always photos without a moment go to the heart), and when
  nothing of it can be kept code builds the same film's plan. Golden Vows
  writes wedding words only when photos or notes show a wedding, else
  neutral romantic lines. A film shows up to 60 photos (15+ Always photos
  are exactly the film's), and at most 12 of the user's lines — feelings
  first, then lines matching the vibe, then details, generic ones last.
  The Plan inspector shows the film, who planned it and every repair.
  Kept films keep their film. The notes below describe each film; where
  they say "the director reads the memory as …", the vibes decide since
  #433.
- **Film length follows the photos (#434):** about 30 s at 15 photos,
  growing evenly to 75 s at 40 or more. Sky Story plays 1 page at 30 s up
  to 5 at 75 s (busy days get extra pages); Neon Night merges chapters
  and, in short films, leaves out a chapter's second moment, then the
  Plan and Note scenes, then extra lines; Golden Vows keeps photo pages
  first, then chapters, the packing card and the carousel last — and its
  heart holds every photo, shown ones too. The app then fits the pages'
  time (Neon Night by whole bars). Words keep their reading time, so a
  film with long notes can run a little over. Kept films keep their
  pacing until "Rebuild film".
- **Sky Story is the default film (#345):** a balloon over a dusk-to-night sky,
  one page per day or group of days (up to 5) — headline, a polaroid fan,
  taped grid or fly-out, the day's note or a short line on the sky — then the
  mosaic of moments; 32.5–75 s, with music (speaker button in the controls).
  Every draft with photos plays it, and so does a film kept as one. Films
  kept before Sky Story, a memory without photos, or any failure while it
  plays fall back to the classic film above.
- **Golden Vows (#346):** an ivory-and-gold wedding album for memories the
  director reads as a wedding, engagement, anniversary or date night —
  invitation, a packing card (checked checklist items, else planned
  quests), photo-with-note pages (notes only in the user's own words:
  caption, else an exact excerpt of that day's note), chapter pages, a
  carousel, every photo forming a heart that lifts off as the Storyni
  balloon, then the Storyni ending; 70–83 s, with its own music. It plays
  before Sky Story; any failure hands over to Sky Story, then the classic
  film. A film kept as Golden Vows stays one while its section still fits.
- **Neon Night (#363):** a beat-synced party film for memories the director
  reads as a party, rave, club night, festival, concert or night out —
  ignition, the neon balloon sign, "Tonight's plan" (quests with a time;
  only with 3 or more),
  1–5 chapters by time (card with the user's own line, then 1–2 moments:
  split, burst or a timeline of 5–8 photos; no peak since #386; small
  chapters merge into fuller ones, and the card shows its own photos so
  nothing repeats — #390; zooms and timeline labels show the photo's
  caption, the time only without one — #387), the note written out in neon, a heart
  of every photo and the end card with real counts; on Summer Party, cut
  to the film's length. Times are the phone's local times. It plays after
  Golden Vows and before Sky Story; any failure hands over to Sky Story,
  then the classic film. **Reduce flashing** plays its softer version.
  Kept films follow Golden Vows' rules.

- **The real story (#398):** the director reads every note whole and
  each photo's logical day. Neon Night gives a memory over several days
  one chapter per day (after midnight belongs to the evening), and each
  chapter up to 4 of the notes' most specific lines — exact words, cut at
  sentence or clause ends, each tied to its photo; generic summaries lose
  to a real detail. Everything plays in time order. Drug references and
  swearing never become a headline, title or the note scene. The plan
  inspector shows each chapter's days, photos, lines (score, director or
  code) and the lines left out. **The film plays them (#416, #426):** a
  chapter card types its first line; the others play inside the moments,
  on their own photo (else the moment photo nearest in time, one without
  a caption first): a timeline's lit photo zooms in with its line under
  it — or its caption — for the reading time; a split or burst shows it
  under the photos. No separate Lines scene, so no photo plays twice; a
  line no photo is left for is left out, and the Note scene is left out
  when its line already played. **A day in parts (#426):** a long day
  breaks into chapters at its long breaks (2 h or more, each part at
  least 4 photos, up to 5 chapters in all; a part the director didn't
  title is titled by its place, else its first photo's time), and inside
  a chapter the card opens with its earliest photos, then each moment
  takes the next stretch — nothing goes back in time. **Sky Story and Golden Vows
  (#419):** a Sky Story note page shows the best lines of its days' notes
  (about two per page, in the notes' order) instead of the note's first
  sentences, continued over the day's pages; with nothing specific the
  note plays as before. A Golden Vows photo page without a caption or a
  director's line gets its day's best line — from a note on that photo
  first — never one another page already shows. **Per page (#422):** a
  day spread over several Sky pages puts each line on the page whose
  photos are nearest it in time (the rave note on the rave photos); each
  page shows its own lines, nothing flows over. Sky Story uses logical
  days too (the night is the evening's), and a page with time to spare
  deals its photos slower — up to 1.2 s apart, over about half the page —
  instead of all at once and a long hold; the note's timing is unchanged.
- **Neon Night deals its own scenes (#444):** one chapter per logical
  day (parts at 2 h breaks while ≤ 5), never fewer for a short film —
  a short film shortens scenes instead (a chapter's two moments become
  one; then the Plan scene goes; the Note scene stays). Code deals each
  chapter in time order, whatever the director said: the card shows the
  first 4–6 photos in a full grid (1–3 side by side, 4 squares, 5–6 a
  mosaic); the rest make one moment, two from 6 left (split at the
  longest gap) — 3–4 photos within 2 min a burst, else a split (4 as a
  2 × 2 grid), 5+ a timeline of up to 8. A day of up to 6 photos is
  its card alone. Every card zooms up to 2 photos — captioned ones
  first, then the best hero score (#446); a zoom holds a caption up to
  ~4 s, and a longer caption is never zoomed: its photo plays in a
  moment, which holds it for its reading time. The time shows only for
  a photo without a caption. A card's
  time range is its own photos'. Director lines that differ only in
  case, spacing, punctuation or ё/е take the note's exact words; a line
  plays over its own photo (brought into a moment); the Note scene
  falls back to code's best unused line; a headline too long is
  dropped, never cut. The director re-runs when it hasn't seen every
  film photo. The storyboard shows "N / M photos shown in scenes".
- **The user's words (#399, display only; which words are chosen is #398,
  multi-excerpt note moments #416):** captions and notes are never cut
  with "…". A text that doesn't fit gets smaller type or more lines, then
  only its first whole sentences, else it isn't shown. Each one stays on
  screen for at least 0.8 s + 1 s per 12 characters; scenes grow to make
  room (Neon Night by whole bars, so it stays on the beat). Captions:
  ≥ 40 px, the user's caption on Sky Story's hero (else place · time),
  Neon Night captions on zooms, splits and bursts in turn, and on a
  timeline only the lit photo's caption, large. Sky Story continues a
  long note on the day's next pages, sentence by sentence (#383). No zero
  counts on end cards or stats. Photos in a scene play in time order.

## 16. Profile ("You") ✅ — redesigned

- Avatar with stars pill, name, @handle, bio, joined date; stats row (Memories ·
  Countries · Days · Stars); achievements 2-col grid — earned vs locked with
  progress bar + mono progress line ("9 OF 14 DAYS"). Canonical badge set: our
  seeded 8 (design's sample names are placeholders where they differ).
- **Settings → Reduce flashing** (#363, default off): films with flashes (Neon
  Night) play their softer version. Always on while the phone reduces motion.

## 17. Kept Memory page — NEW (#279)

- `/memory/:tripId`, design `docs/design/kept-memory/` (option 1b). Every
  photo and note of a kept memory, day by day, with the film on top.
- Hero (cover, KEPT FOREVER · dates, title, days · photos · notes · ✦),
  **Play the film** (ends on "Back to memory") and **Slideshow**.
- One chapter per day with content: photo strip (bonus-task photos marked
  ✦) and every note in full, in time order with its time on the phone's
  clock (an old one-a-day note says EARLIER NOTE instead, #402). The plan, read-only and collapsed, at the end.
- Full-screen viewer over all photos: swipe / tap zones, pinch, swipe down
  to close, progress split by day, caption + bonus task; slideshow every
  3.2s with crossfade and slow zoom (no zoom under reduced motion).
- Home opens it directly for every kept memory (#281). A kept film opened
  elsewhere (Journal → View wrap-up) offers "Open memory" in its HUD.
  Read-only — no editing from this page.

## Out of scope for MVP

Social feed, follows/likes/comments, public profiles, shared memories, star
redemption, video export, route planner, multi-currency, web app.

## Design gaps (residual)

1. Wrap-up **edit** mode (reorder/remove blocks) — playback is designed, editing
   UI is not. Decide: design it, or ship publish-only first.
2. Cover **photo upload** (design shows an "Upload photo" pill) — MVP could ship
   bundled covers + "Set as cover" from Photo detail only. Confirm.
3. Quest rows in the mockup show per-quest ✦ values — with our flat ✦1, show a
   uniform ✦1 badge or none. Pick at implementation.

## Monetization (context)

Freemium: free = 3 memories & basics; paid = unlimited, full features, export.
