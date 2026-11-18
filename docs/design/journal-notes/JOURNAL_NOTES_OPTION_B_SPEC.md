# Journal Day — many timed notes · Option B "One timeline" (Claude Code handoff)

**Change:** a day stops holding one appended text block. **Every Done on the notebook page saves a separate note** with its own time. A day becomes a small timeline of short notes.

Reference design: `Journal Notes Timeline.dc.html` → option **1b**. The interactive phone is `JournalDayPhone.dc.html` with `variant="timeline"`.
**Scope: implement Option B only.** Ignore anything about Option A / the "Notes list".

Builds on `JOURNAL_NOTE_PAGETURN_SPEC.md`. The page-turn, voice/typing states, dock and star rules are unchanged unless noted in §7.

---

## 1. Data model

```dart
class JournalNote {
  String id;
  String dayId;            // day it belongs to (see §2 rule 2)
  DateTime takenAt;        // the time shown; set when Done is first tapped
  DateTime editedAt;
  String text;
  bool dictated;           // true if any part came from speech-to-text
  String? photoId;         // attached photo, optional
  bool legacy;             // migrated single entry (§2 rule 5)
}
```

Photos already have `takenAt` and `caption`. Add a derived `hasNotes` (any note with `photoId == photo.id`).

**Migration.** For each existing day with non-empty `entry.text`, create one `JournalNote(legacy: true, takenAt: entry.editedAt, editedAt: entry.editedAt, text: entry.text, dictated: false)`. Keep the old field read-only for one release, then drop it. No text is altered.

---

## 2. Rules

1. **Always in time order, oldest first**, sorted by `takenAt`. Tie between a photo and a note at the same minute: the photo comes first.
2. **After midnight belongs to the previous evening.** A note or photo with local time **00:00–04:59** belongs to the previous calendar day, as long as that day has at least one item after 18:00. Otherwise it starts its own day. Sort key: `minutes + (hour < 5 ? 1440 : 0)`. Show the real clock time (`01:10`, not `25:10`). Insert one divider before the first after-midnight item: `AFTER MIDNIGHT · FRI 24 OCT`.
3. **Voice icon.** If `dictated == true`, show a 11px mic glyph next to the time. Editing by typing keeps the flag. Dictating during an edit sets it.
4. **Attached photo.** The note card shows an "On photo" chip (thumbnail + photo time + caption). The photo tile shows a ✎ badge. The note keeps **its own** time and position. It does not move next to the photo.
5. **Legacy note.** One card with the `EARLIER NOTE` chip, positioned at its last-edited time. The footer reads `LAST EDITED 22:14 · 74 WORDS`. It can be edited or deleted like any note.
6. **Time of a new note** = device local time at the moment **Done** is tapped. Edits never change `takenAt`. They only update `editedAt`.
7. **Time labels:** 24h `HH:mm`, zero-padded (`06:45`, `21:16`), JetBrains Mono. Follow the device 12/24h setting in production (`h:mm a`). No seconds, no dates on cards. The date sits in the day header.

---

## 3. Tokens

| Token | Value | Use |
|---|---|---|
| bg | `#0C0F27`, top glow `#181541 → #0C0F27` over 360px | screen |
| card | `rgba(19,23,54,.75)` | note card |
| cardBorder | `rgba(29,34,72,.90)` 1px | card |
| fg | `#FBFAF6` | note text |
| muted | `#92909E` / `#AEACB7` | subtitles, captions, mic glyph |
| label | `#6D6D7A` | mono section labels |
| time | rail: notes `#F2A65A`, photos `#92909E` | time labels |
| primary | `#F29520` | links, FAB, fresh border `rgba(242,149,32,.75)` |
| legacyChip | bg `rgba(137,98,197,.16)`, fg `#C9A9F5` | EARLIER NOTE |
| danger | `#FF6D79` (button), `#FF8A94` (text on sheet) | delete |
| rail | `rgba(174,172,183,.16)` 1px | timeline line, dividers |
| sheet | `#12142F`, radius 26 top | bottom sheets |

Type:
- Note body: **Fraunces 400 italic 14.5 / 1.6**, `text-wrap: pretty`.
- Time: **JetBrains Mono 500 11**, letter-spacing .02–.04em.
- Labels (divider, `NOTES ON THIS PHOTO`): Mono 500 9.5, .14em, uppercase.
- Day title: Fraunces 400 26/1.15. Subtitle: Roboto 500 11 muted (`Thu 23 Oct · 12 photos · 6 notes`).
- Links ("more", "＋ Add a note"): Roboto 600 11, primary.
- Photo caption: Roboto 400 11.5/1.4 `#AEACB7`, max 2 lines.

Spacing: header/title side padding 22; timeline padding 12 left / 20 right. Card padding 12/14. Card radius `4 16 16 16`, so the card reads as speaking from the rail. Row bottom padding 18.

---

## 4. Layouts

### Layout — One timeline
- Grid `52px | 1fr`, column gap 13. The left column is the rail: time right-aligned, mic under the time, 1px line on the right edge, 8px dot on the line (notes `#F29520`, photos `#4B4A63`, with a 3px ring in bg colour).
- **Photo rows:** consecutive photos with no note between them and ≤ 20 min apart share one row.
  - 1 photo: max-width 236, height 196.
  - 2 photos: 150 high each.
  - 3 or more: 112 high, 3 visible, the third shows `+N`.
  - In groups, each tile shows its own time pill. The rail shows the first photo's time.
  - Caption under each tile (max 2 lines). No caption → nothing.
- **Note rows:** the card has no time inside, because the rail shows it. Chips (`EARLIER NOTE`, `JUST NOW`) sit at the top of the card.
- **Split capture button.** One floating capsule, centred, bottom 30 + safe area. Hidden on empty days (the empty state has its own buttons). No star counts on it.
  - Capsule: 194×60 (two 84px halves + 26px balloon gap), radius 999, `LinearGradient(135°, #F29520 → #FF6D79)` (the mic gradient). Shadow `0 16 34 rgba(0,0,0,.45)` + `0 8 22 rgba(242,149,32,.32)`, inner top highlight `rgba(255,255,255,.3)`.
  - **Left half = Photo:** camera icon 22px, stroke 1.9 `#0C0F27`, label "Photo" (Roboto 600 9.5). Opens the existing add-photo flow. New photos land in the timeline at their `takenAt`.
  - **Right half = Note:** notebook-page icon 22px, label "Note". Opens the notebook (new note).
  - **Centre: balloon cut-out.** A 26px-wide gap between the halves, filled with a hot-air-balloon silhouette (26×52) in the app background `#0C0F27`, so the button looks punched through in the shape of the logo. The envelope fills the top two-thirds, then two 1.4px ropes, then a 5.2×5.4 basket (r 1.2). No divider line, no disc. In Flutter, draw it as a `CustomPainter` path. If the capsule ever sits over photos, use a real transparent cut-out (`ClipPath` with `PathOperation.difference`) instead of a painted fill.
  - Each half is its own hit target (84×60). Pressed: overlay `rgba(12,15,39,.1)` + light haptic. Semantics labels: "Add a photo" / "Add a note".

### Note card
```
(time + mic live on the rail, not in the card)
[chip?]                         ← EARLIER NOTE / JUST NOW
Italic body text, max 4 lines…
more                            ← only if it overflows
[thumb 34×34] On photo · 18:25 · ribs on the bar   ← if attached
LAST EDITED 22:14 · 74 WORDS    ← legacy only
```
"On photo" chip: bg `rgba(29,34,72,.6)`, radius 12, padding 5/10/5/5, thumbnail radius 8, label Roboto 500 10.5 muted, ellipsised. Tapping it opens the photo.

### Long note
Collapse when the text is taller than 4 lines (measure with `TextPainter`, `maxLines: 4`; don't count characters). Collapsed: clip to 4 × line height (93px) with a bottom fade mask (`#000 60% → transparent`), plus a "more" link. Expanded: "less".

### Empty day
A small tilted notebook page (206×134, `#F3EDE0`, ruled 30px, rotate −3°, stamp `DAY 3 · SAT 25 OCT`, faded line "The first line goes here…"). Under it:
- Title "Nothing written for Saturday yet" (Fraunces 21).
- One line of Roboto 12.5 muted: "Write a line whenever something happens. Each time you tap Done it's kept as its own note, with the time."
- Primary button "✎ Write the first note ✦1".
- Secondary text link "or add a photo".

---

## 5. Interactions

| Action | Result |
|---|---|
| Tap "more" / "less" | Expand or collapse in place |
| **Long-press** a card (450ms, light haptic) | Sheet: note preview (time, mic, 2 lines) → **Edit note**, **Delete note**, Cancel |
| Swipe left on a card (iOS) | Reveals a red Delete action (80px). Tapping it opens the same confirm. Optional, same flow. |
| Tap Photo half of the capture button | Existing add-photo flow |
| Tap Note half of the capture button | Notebook, new note |
| Delete note | Confirm sheet: "Delete the 21:16 note?" / "It's removed from this day and won't appear in your film. Photos stay. This can't be undone." Buttons: Keep / **Delete** |
| Edit note | Notebook opens with that note's text in the field, stamped `EDIT NOTE · 21:16`. Done saves the new text, keeps the time, toast "Note updated" (no star). |
| Add a note (capture button Note half, empty state) | Notebook opens on an **empty** page stamped `NEW NOTE · HH:mm`. Never append to an old note. |
| Tap a photo / "On photo" chip | Photo detail (§6) |

Long-press must not trigger "more" or the chip on release (swallow the next tap).

---

## 6. Photo detail (addition)

Below the caption:
- **"✎ Add a note to this photo"**: full-width, 14px padding, radius 16, bg `rgba(242,149,32,.12)`, 1px border `rgba(242,149,32,.45)`, Roboto 600 12.5 primary.
- If the photo has notes: label `NOTES ON THIS PHOTO · N`, then the cards (full text, time + mic). If not: Fraunces italic 13 `#6D6D7A`, "No notes on this photo yet."

Tapping "Add a note" opens the notebook with `photoId` set:
- Stamp `PHOTO NOTE · HH:mm`.
- Polaroid at the top of the ruled area: 96×112, white, padding 6/6/22, rotate −3°, shadow `0 8 18 rgba(30,27,58,.2)`. Beside it: `ON THIS PHOTO · 18:25` (Mono 9, .14em) and the caption (Fraunces italic 14, `#625D7A`). If there's no caption, use the photo's place label.
- The turning page's front-face polaroid shows this photo instead of the day cover.
- Placeholder: "What was happening here? Type, or tap the mic."

On save, return to the photo detail. The new note appears under the photo with the slide-in animation (§7) and the star toast. It also appears in the day timeline at its own time.

---

## 7. Animations

| What | Spec |
|---|---|
| Notebook open/close | Unchanged (1170ms open / 880ms close page-turn) |
| **New note slides in** | After the route pops: (1) scroll so the target slot is ~250px from the top (smooth, ~350ms); (2) at +420ms the slot opens, height 0 → auto, 340ms `Cubic(.2,.8,.2,1)`; (3) the card drops in from translateY −18 / scale .96 / opacity 0 → rest, 700ms, same curve, 120ms delay; (4) one orange glow ring (box-shadow 0 → 14px, fading), 1.4s, starting at 800ms. The border stays `primary` and the `JUST NOW` chip shows for 3s, then both fade back. |
| Star toast | Existing `awardPop`, 2.3s, top 104: "✦ +1 star · note saved". Edits: neutral toast "Note updated" (bg `rgba(29,34,72,.96)`, fg `#FBFAF6`). Delete: "Note deleted". |
| Expand / collapse | `max-height` 93 ↔ measured height, 380ms `Cubic(.2,.8,.2,1)`. The fade mask is removed when expanded. Use `AnimatedSize` + `ShaderMask`. |
| Delete | On confirm: opacity 1 → 0 (250ms) while the height folds to 0 (340ms). Cards below move up. Then remove from the list and show the toast. |
| Sheets | Slide up 280ms `Cubic(.2,.8,.2,1)`, backdrop `rgba(7,9,26,.62)` fades in 180ms |
| Reduced motion | No slide or glow. Crossfade 200ms. Scroll jumps instead of animating. |

---

## 8. Stars and counters (change from page-turn spec §5)

- +1 star **per new note saved** (cap 3 note-stars per day, as before). Edits and deletes never give or take stars.
- Storyteller progress counts **notes**, not saves. Deleting a note decrements it.
- Wrap-up gate "≥1 note": at least one non-empty `JournalNote` in the trip.

## 9. Film

Each note is placed in the film by `takenAt`, next to the photos nearest in time. If `photoId` is set, the note goes on that photo. Notes after midnight use the day from rule 2.

---

## 10. Test cases

1. Sample Day 1 timeline order: 06:40+06:42 photo row · 06:45 note · 06:50 · 10:10 · 10:30 note · 11:25 · 12:31 · 14:40 note · 15:42 · 18:25 · 19:30 · 21:16 note · 22:46 · 23:30 note · divider · 01:04 · 01:10 note · 04:34.
2. Notes 06:45, 14:40, 21:16 and 01:10 show the mic. 10:30 and 23:30 don't.
3. 21:16 shows the 18:25 thumbnail. The 18:25 tile has a ✎ badge (20px circle `rgba(7,9,26,.72)`, glyph `#F2A65A`, top/right 7). Its photo detail lists the 21:16 note.
4. 23:30 is collapsed with "more". Tap expands, "less" collapses.
5. Two Dones in a row create two cards with different times. The first card's text is unchanged.
6. A note saved at 23:52 slides in between 23:30 and the divider. Toast "+1 star · note saved".
7. A note written at 00:40 after an evening with items lands in the previous day, after the divider.
8. Long-press → Edit → change text → Done: same time, new text, "Note updated", no star.
9. Long-press → Delete → Keep: nothing changes. Delete: the card folds away, counts update, "Note deleted".
10. A day migrated from the single-entry model shows one EARLIER NOTE card at its last-edited time, with all its text.
11. Empty day: the prompt shows. "Write the first note" opens an empty notebook page.
12. Photo → Add a note to this photo: the polaroid shows on the page. On save the note appears under the photo and in the timeline.
13. Reduced motion: no slide or turn, crossfades only.
14. The capture button stays above the home indicator, never covers the last row (list bottom padding 130), and is hidden on empty days.
15. Photos within 20 min with no note between share a row; a note between them splits the row.

---

## 11. Sample data (for fixtures/tests — keep the Russian text exactly)

Amsterdam, Day 1, Thu 23 Oct.

Notes:
- 06:45 · voice · «Прибыл в аэропорт за 10 минут до посадки, а там толпа людей, даже немного испугался, что не успею.»
- 10:30 · «Приземлились в Амстердаме и сразу пошли завтракать. Пока ели в McDonald's, к нам пришли друзья, которые прибыли двумя днями раньше.»
- 14:40 · voice · «Сидели дома часа два, помылись, выпили немножечко и выходим.»
- 21:16 · voice · photo 18:25 · «Сидим в баре, ждём полтора метра рёбер: заказали 4,5 килограмма и по пиву каждому.»
- 01:10 · voice · «Начался рейв, это самый крутой сет, который я слышал. Мурашки по коже.»

Photos: 06:40 "fast check-in" · 06:42 "Did not expect that many people in the airport, have 15m before boarding" · 06:50 (airport play area) · 10:10 "we are here" · 11:25 "getting oatmeal with almonds and bananas" · 12:31 "our castle" · 15:42 "боча пролил пиво" · 18:25 (ribs, no caption) · 19:30 "back to the roots" · 22:46 "боча застрял в толчке" · 01:04 (rave stage) · 04:34 (club selfie).

The prototype also adds a long 23:30 typed note to demo collapse — it's a design sample, not real data.
