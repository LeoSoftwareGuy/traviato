# Bonus tasks — final system rules

Companion to `README.md`. This is the authoritative spec for the bonus-task mechanic; the Bonus screen section in the README describes the *visual* design, this describes the *system*.

Design principle behind every rule below: **a quest is the user's own plan; a bonus task is the app's invitation.** An invitation that accumulates into a backlog has become homework. Every rule exists to prevent visible guilt.

---

## 1. Tray size and cadence

- Every day of an **active** memory (today between start and end date inclusive), the user gets a tray of **2 tasks**.
- **Day one is the exception: 3 tasks**, one of which is a deliberately trivial *starter* ("Snap anything at all"). Rationale: first-day completion is what brings a user back on day two, so the first tray must be impossible to fail.
- The tray **belongs to the day**. Tasks are valid until **midnight local time**.
- **No countdown clocks.** The expiry label reads `TODAY`. A rolling "expires in 4h" reads as pressure at 8pm; "today" does not.

## 2. Where tasks come from

Tasks are **not authored per trip**. They are drawn from a **template pool seeded into the DB once**.

A template is a fill-in-the-blank shape — `Snap your first {meal} there`, `The view from where you slept` — carrying:

| Field | Values | Purpose |
| --- | --- | --- |
| `phase` | `arrival` \| `middle` \| `departure` \| `anytime` | gates which day it can be drawn on |
| `kind` | `regular` \| `starter` \| `stretch` \| `milestone` \| `streak_saver` | gates how it's offered |
| `stars` | 1–3 (milestone 5, streak-saver 2) | reward |
| `slots` | e.g. `{meal}` | filled from trip context |

**Slot filling** uses only data already on hand: vibe tags, destination string, day index, season/dates. No external service.

### Draw algorithm (per trip, per day)

1. Filter the pool by phase: `arrival` templates only on day 1, `departure` only on the last day, `middle`/`anytime` otherwise.
2. Exclude anything the user has been **assigned in the last 10 days** (no-repeat window).
3. Pick 2 (day one: 3, one of which must be `kind = starter`).
4. **Deterministic seed** — `hash(trip_id + day_index)`. The same day always draws the same tasks, so reopening the app never reshuffles the tray. This is a correctness requirement, not a nicety.
5. Persist as **assignment rows**; do not re-draw on read.

## 3. Completion

- Completing a task awards its stars, fires the star toast (`✦ +2 stars · dare done`), and marks the assignment complete.
- **Completing both does not refill the tray.** Refilling teaches grinding. The tray shows a calm earned state: *"Both done. New dares tomorrow. You took ✦3 off today."*
- **One thing unlocks:** an optional **stretch task** worth ✦3, rendered only after both are complete, visibly opt-in (dashed border, `UNLOCKED · OPTIONAL` label). Completionists get a cherry; everyone else sees a finished tray.

## 4. Non-completion — the load-bearing rule

- **Nothing happens.** No red state, no "expired" badge, no failure screen, no accumulation.
- Technically: an assignment whose day is past and which has no completion **simply never renders again**.
- The only acknowledgement is the next day's *Yesterday* line, and it stays playful: *"Yesterday's dares got away. These two are new."* — never "you missed 2 tasks."

## 5. Special cases

**Streak-saver.** If the user logs nothing (no note, no photo, no completion) for **2 consecutive days**, a streak-saver task appears: fixed **✦2**, **does not expire** until acted on, bar deliberately on the floor (*"Anything at all. Truly, anything."*). Labelled `NO RUSH · WAITS FOR YOU`. This is the re-engagement hook; only one may be live at a time.

**Milestones on long trips.** On days **7 / 14 / 21**, add one **milestone** task (**✦5**, a bigger reflective prompt — *"A photo that says what this place has become to you"*). Gives a month-long trip a spine.

**Weekly theming (perceived variety).** Weight the draw by trip week — days 1–7 lean arrival/strangeness, 8–14 food/routine, 15–21 people, 22+ endings. Same pool, different weighting. Users perceive variety they cannot name.

## 6. Reactive (EXIF-triggered) tasks

The magical tier, and it **costs no permission**.

- When the user adds a photo, read its **EXIF coordinates** — the app is already a photo app, so this needs no location grant.
- If context is recognisable (near water, high altitude, a city centre), offer a task **reactively**: *"Something that reflects — puddles count, and count double"*, rendered with a blue trigger line — `◍ BECAUSE YOU JUST SHOT WATER`.
- Reactive beats predictive: a predictive task arrives while the user is walking; a reactive one arrives when they have *just demonstrated* their phone is out and they're in a photographing mood.
- Reactive tasks occupy a tray slot; they do not add a third task.

### Location permission — ask late, ask for the map

Never ask at launch, and never frame it around bonus tasks. Ask **once**, at the first *Add photo* tap on day one, framed as the wrap-up map (a payoff they have already seen):

> **Want your memories on a map?**
> We'll pin each photo where you took it, so your wrap-up can draw the route you actually walked. *Only while you're using the app.*
> [Not now] [Pin my photos]

If declined: nothing breaks. EXIF still yields the route in most cases; tasks fall back to time/phase templates. **Re-ask exactly once**, after their first wrap-up.

**Three tiers, degrading gracefully:** (1) time/phase templates — needs nothing; (2) context-flavoured, from destination + season — needs nothing; (3) reactive, from EXIF — needs no permission, only a photo.

## 7. Notifications

Maximum **two per day**, both tied to natural moments.

| Trigger | Time | Condition |
| --- | --- | --- |
| Morning tray | ~09:00 local | only if **yesterday had activity** |
| Evening nudge | ~19:00 local | only if a task is undone **and** the app was opened today |
| Arrival day | memory start date | always — highest-intent moment |

**Silence rules:** none on days where both are already complete; none after 21:00; **hard mute after 3 consecutive ignores**. Never notify someone who is ignoring you — that is how you get uninstalled.

## 8. Tone

**Playful-provocative** — a slightly mischievous travel companion that dares you and never scolds you. The failure path is where tone matters most, and since misses vanish silently, the only surface is the next day's greeting, which stays light.

Sample register:

- The worst photo of the day
- Something you'd get told off for photographing
- Proof you were awake before someone else
- The least impressive meal you've had here
- Something that reflects — puddles count, and count double
- A stranger who helped (ask first, obviously)
- Whatever you're pretending not to be lost next to

## 9. Seed math — pool size

The pressure point is the combined **`anytime` + `middle`** bucket, because a long trip draws from it every day. 2 draws/day against a 10-day no-repeat window means that bucket must comfortably exceed 20.

| Bucket | Count |
| --- | --- |
| `anytime` + `middle` | 20–22 |
| `arrival` | 3–4 |
| `departure` | 2–3 |
| `starter` | 1 |
| `stretch` | 2–3 |
| `milestone` | 3 |
| `streak_saver` | 1 |
| **Total** | **≈ 30–35** |

One afternoon of authoring; serves a 30-day trip without repeats being noticeable.

## 10. Star economy — no cap in MVP

Bonus stars are the **seasoning**; planned quests are the **meal**. On a normal trip this holds without intervention: a 5-day trip yields ≈ ✦20 from bonus tasks against ≈ ✦46 from quests.

The edge case: a user who plans **zero quests** has bonus tasks as their only star income, so a 30-day passive trip could yield ≈ ✦120 just for showing up.

**Decision: no bonus-star cap in MVP.** Stars buy nothing yet, so inflation has no victim. **Revisit when stars gain redemption** — at that point the award RPC caps bonus stars per day.

---

# Issue texts

## M3-7a — Migration: reshape bonus tables + seed the template pool

Reshape the bonus schema from per-trip authored rows to a **template pool + per-day assignments**, and seed the pool.

**Tables**

- `bonus_templates` — `id`, `body` (with `{slot}` placeholders), `phase` (`arrival|middle|departure|anytime`), `kind` (`regular|starter|stretch|milestone|streak_saver`), `stars` (int), `slots` (jsonb), `active` (bool).
- `bonus_assignments` — `id`, `trip_id`, `template_id`, `day_index` (int), `assigned_for` (date, local), `expires_at` (timestamptz, local midnight), `reactive` (bool), `trigger_label` (text, nullable), `resolved_body` (text — slots already filled at assign time), `completed_at` (timestamptz, nullable), `photo_id` (nullable fk).
- Index `bonus_assignments (trip_id, assigned_for)` and `(trip_id, template_id, assigned_for desc)` — the second serves the 10-day no-repeat lookup.

**Seed** ≈30–35 templates per the table in §9 of `BONUS_TASKS.md`, in the playful-provocative register of §8. Include the day-one starter (`Snap anything at all`, ✦1), the three milestones (✦5), and the single streak-saver (✦2).

**Award path** — completing an assignment writes to the existing points ledger. **No per-day bonus cap** (see §10); leave a comment at the RPC noting the cap belongs here when stars become spendable.

**Acceptance:** migration is reversible; seeding is idempotent; the no-repeat query returns in a single index scan.

---

## M3-7b — Bonus tray feature

Implement the daily tray and the Bonus screen per the design reference and `BONUS_TASKS.md` §1–6.

**Draw** — on first open of a day for an active memory, assign that day's tray: 2 tasks (day one: 3, one `starter`), phase-filtered, excluding anything assigned in the last 10 days, seeded by `hash(trip_id + day_index)` so the tray is **stable across reopens**. Persist assignments; never re-draw on read.

**Screen states** (all four are in the prototype behind the segmented switcher — that switcher is a demo affordance, not production UI):

1. **Day one** — 3 tasks, starter first.
2. **Two live** — the daily default; a reactive task renders its blue `◍ BECAUSE YOU JUST SHOT WATER` trigger line above the row.
3. **Both done** — earned state ("Both done. New dares tomorrow. You took ✦3 off today.") + the optional ✦3 stretch task, dashed/opt-in.
4. **Gone quiet** — streak-saver present (✦2, `NO RUSH · WAITS FOR YOU`, no expiry).

**Expiry label is `TODAY`**, never a countdown. **Missed assignments never render again** — no expired state anywhere in the UI.

**Reactive tasks** — on photo add, read EXIF coords and, where context is recognisable, assign a reactive task into a tray slot with its `trigger_label`. No location permission required for this path.

**Location permission sheet** — shown at the first *Add photo* tap on day one, copy exactly as in §6; re-ask at most once, after the first wrap-up.

**Completion** — awards stars, fires the existing star toast (`✦ +2 stars · dare done`), marks the assignment. Completing both must **not** refill.

**Acceptance:** tray is stable across app restarts within a day; no template repeats within 10 days; no UI surface anywhere shows a failed/expired task; declining location degrades to time/phase tasks with no functional loss.

---

## M3-7c — Local notifications for bonus tasks

Schedule the three notification triggers in §7 using local (on-device) notifications; no push infrastructure.

| Trigger | Schedule | Condition |
| --- | --- | --- |
| Morning tray | ~09:00 local | yesterday had activity (note, photo, or completion) |
| Evening nudge | ~19:00 local | a task is undone **and** app opened today |
| Arrival day | memory start date | unconditional |

**Silence rules:** skip when both tasks are complete; nothing after 21:00; **hard mute after 3 consecutive ignores** (persist an ignore counter, reset on any open-from-notification).

**Platform-honest approximations** — local notifications cannot evaluate conditions at fire time, so schedule optimistically and **cancel/reschedule on app open and on task completion**. Evening nudges are scheduled only for a day the app has already been opened, which naturally satisfies that condition. Timezone changes mid-trip must reschedule against the new local midnight.

Copy stays in the §8 register — *"Two little dares today ✦"* — and never references a miss.

**Acceptance:** never more than 2 notifications in a rolling 24h; none fire after both tasks are done; muting engages after 3 ignores and lifts on the next open-from-notification.
