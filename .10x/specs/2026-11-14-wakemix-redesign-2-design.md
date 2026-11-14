# Wakemix redesign 2 — design spec

**Date:** 2026-11-14
**Status:** approved by the user on 2026-11-14, picture by picture, in the session that wrote it. The pictures and their HTML sources are in that session's notes folder (`redesign-2/round4-rich`, `redesign-2/round5-features`).
**Slug:** `visual-identity-2`
**Replaces:** section 1 ("Mixtape") of `2026-10-29-wakemix-redesign-design.md`. Sections 2 to 4 of that spec stay as they are.

## Why
The user did not like the first look at all: flat near-black, one cobalt accent, thin grey line art, text that looks like code, and on a laptop a narrow column in the middle of an empty page. Five rounds of pictures on 2026-11-13 and 2026-11-14 found what they want:

- Rejected: a dark glass look with neon glows, a light look with acid lime, a black look with a yellow-to-red gradient ("too harsh, colours wrong, too simple"); a gold watch dial on khaki with a serif font ("silly": the watch, too much gold, the serif, the decorated background); a flat calm look ("too simple").
- Accepted: the calm layout with depth. Soft colour fields behind the page, glass cards, a cream accent, Geist, big numerals, and a real wide layout on a laptop.
- Asked for: something that makes the alarm stand out. Chosen: **time wheels** and a **deck of sound cards**.
- Asked for: no Insights tab that nobody uses. In its place **Analytics**: day, week, month and year, with a calendar.

The product rules of `CLAUDE.md` do not change. Stop and Snooze stay at least as big and as easy to hit as before.

## 1. The look "Soft depth"

### Principles
1. **Soft, never harsh.** No pure black, no neon, no hard gradients on controls. Depth comes from soft colour fields behind the page and from glass cards.
2. **Rich, quiet colours.** Olive and khaki, pine green and bronze behind the page; cream as the one accent; green, sand and terracotta only to tell the three strengths of a sound apart.
3. **One font.** Geist everywhere: big tight numerals (weight 600), plain text. No serif, no monospace.
4. **No ornament.** No watch, no record, no gold frames, no rays, no dust.
5. **A site on a laptop, an app on a phone.** From 1000 px wide: a top bar with the tabs and two columns. Below: one column and a bottom bar.
6. **One thumb, half asleep.** Touch targets of 48 dp or more; the main action of a page is a wide button within reach.

### Colour tokens
Dark is the reference; light follows the device.

| Token | Dark | Light | Use |
| --- | --- | --- | --- |
| `background` | `#171B12` | `#F2EEE5` | the page, below the colour fields |
| `surface` | `#262B1D` | `#FFFFFF` | solid cards: dialogs, snack bars, the bottom bar |
| `surfaceHigh` | `#333A27` | `#E9E4D6` | inputs, keys that are off, pressed states |
| `outline` | `#3C432F` | `#DDD6C4` | hairlines |
| `text` | `#F5F2E6` | `#20211B` | main text |
| `textMuted` | `#B4B29B` | `#6B6955` | meta text, borders of controls |
| `textDisabled` | `#85846F` | `#9C9A86` | alarms that are off, always with the word "Off" |
| `accent` | `#E2D398` | `#59603A` | fills, active states |
| `onAccent` | `#1E2114` | `#FFFFFF` | text and icons on the accent |
| `accentText` | `#E2D398` | `#4A5130` | text in the accent colour |
| `danger` | `#F0907A` | `#B3402A` | errors |
| `glass` | white 6.5% | white 72% | the fill of a glass card |
| `glassLine` | white 11% | `#20211B` 8% | the hairline of a glass card |
| `gentle` | `#A9C27A` | `#7E9A4A` | a gentle sound, "got up at once" |
| `medium` | `#E2D398` | `#C9B25A` | a medium sound, "snoozed" |
| `strong` | `#E39A6B` | `#D07B48` | a strong sound, "missed" |
| `fieldOlive`, `fieldPine`, `fieldBronze` | `#6E8438`, `#2F5D46`, `#A0662F` | the same, much fainter | the colour fields behind the page |

A test checks every pair of text and background, and of control and background, against WCAG AA, as before. Text on a glass card is checked against the darkest and the lightest the card can be over the fields.

### Shape and motion
- Corners: 28 for big cards, 24 for rows and tiles, round for buttons, chips and the tabs.
- Glass card: the `glass` fill, a 1 px `glassLine`, a soft shadow. No backdrop blur: the fields behind are already soft, and a blur costs frames.
- The colour fields: three or four big radial gradients, drawn once behind each page.
- Motion 150 to 300 ms, ease-out; the deck shuffles in about 500 ms. Everything stops when the platform asks for less motion.

### Layout
- **Wide (1000 px and more):** a top bar with the wordmark on the left, the three tabs as one pill in the middle, Settings on the right. Content at most 1312 px wide, in two columns where a page has two kinds of content.
- **Narrow:** as before, one column of at most 560 px, the bottom bar with the three tabs.

## 2. Screens
- **Alarms:** the next alarm as a big card (a tag "Next alarm", "in 7 h 20 min", the time at 120 to 170 px, the label and days, soft waves at the bottom); under it three tiles: Tonight's mix (bars, one per sound, taller and warmer for a stronger sound; it opens the mix), Bedtime ("10:30 PM, for 8 h of sleep" or "Sleep now"), Sound (armed or not). The alarms as glass rows: a coloured tile with a small waveform, the time, label and days, "Rings in …" or "Off", the switch. "New alarm" in the header of the list on a wide screen, a wide button at the bottom on a narrow one. The "Arm alarms" and "Keep this tab open" notices stay, as a card above the list.
- **Alarm editor:** the time wheels (below), then "Rings in …" and the bedtime line, a strip from midnight to midnight with a mark at the chosen time; Repeat, Label, Genres, Save alarm.
- **Tonight's mix:** the deck (below).
- **Ringing:** the page in the warm end of the fields, the time very big, the alarm's label, the mix as bars with the sound that plays lit, "Now playing" and the title, Snooze and Stop as two wide buttons, Stop the bigger and filled.
- **Morning card, Settings, Bedtime reminder, Library:** the same cards and type. Their texts and behavior do not change.
- **Analytics** (the third tab, in the place of Insights): section 4.

## 3. Signature features
Both only change how something looks and is handled. What they do is what the app already does.

### Time wheels
- Two wheels, hours and minutes, and AM and PM keys on a 12-hour device. The chosen value sits big in a band in the middle; the values before and after it are smaller and fainter.
- Drag or scroll a wheel to turn it; it settles on a value. Arrow keys turn the focused wheel by one, Page Up and Page Down the hours.
- A tap on the band opens typing the time (the time picker in input mode), as "Type the time" did.
- For screen readers it stays one adjustable value, "Alarm time", with increase and decrease by a minute.
- The page behind the editor gets warmer and lighter as the chosen time nears morning: the warm colour field grows from night to 6 to 9 AM and fades again towards the evening.

### Sound deck
- Tonight's mix shows the sounds of the first round as a fan of cards in play order: the place in the order, the title, the genre and strength, a small waveform, a play button for the preview. The colour of a card is the strength of its sound.
- Reshuffle mixes the deck in front of the user: the cards gather, change places and fan out in the new order.
- Each card has "Not tonight". A card can also be dragged up and away for it. The cards left out lie in a pile "Not tonight" with "Bring back".
- On a narrow screen the fan becomes a row of cards that scrolls sideways.
- Every card is a button a keyboard and a screen reader reach, with the labels of today ("Preview …", "Not tonight: …", "Bring back: …").

## 4. Analytics (PLAN task 2.8, made bigger)
The third tab. It reads the ring log and the answers of the Morning card that the app already keeps; no new table.

- **Calendar:** a month, Monday first, with a mark on each day an alarm rang: got up at once (Stop without a Snooze), snoozed (Stop after one or more), missed. Earlier and later months with the arrows. A tap on a day chooses it.
- **Period:** Day, Week, Month, Year. The period is the one that holds the chosen day.
- **Figures for the period:** mornings got up and missed; the average time from the alarm to Stop; snoozes; sounds played.
- **Chart:** the time from the alarm to Stop, per day for a week and a month, per month for a year.
- **Day:** what happened that morning, from the log: the alarm, each Snooze with its sound, the Stop, the sound named on the Morning card.
- **"Wakes you best":** the sound named most often on the Morning card in the period.
- With no ring yet: an empty state that says so.
- The logic is pure Dart in `lib/core/analytics.dart`, tests first. Days are days of the local calendar.

## Done when
- `dart format .` changes nothing, `flutter analyze` reports 0 issues, `flutter test` passes, also the daylight saving time tests of `CLAUDE.md`.
- New tests: the contrast of every token pair; the wheels (drag, keys, typing, the screen-reader value); the deck (order, Reshuffle, Not tonight, Bring back, labels); the analytics logic; every page at a 2.0 text scale on 360 × 740 without overflow, and at 1280 × 800; nothing moves when less motion is asked for.
- Headless Chrome, built as the site: screenshots of every page, dark and light, 390 × 844 and 1440 × 900; an armed alarm still rings on time, Snooze and Stop work and are logged; no console error; a profile with data of the live build opens with every row.
- The user has seen the real screenshots and said yes. Then `main` is pushed, CI is green and the live site shows the new look.
- `docs/DECISIONS.md` has an entry that links ADR-005; `PLAN.md` has the tasks ticked with Progress log lines; `.10x/` state is current.

## Out of scope
- Task 2.6 (import own songs), unfinished in its own worktree: it is rebased onto this look later.
- App icon and splash screen (8.1). Sounds beyond the placeholders.
- A setting for the theme: it follows the device.

## Risks
- **The size of the change:** nearly every screen and many tests. Done in steps that each pass every check.
- **The wheels are new input:** typing the time, the keys and the screen-reader value keep it usable for everyone.
- **Dragging a card away is easy to miss:** the "Not tonight" button on each card stays.
- **Alarm reliability:** the ringing code is not changed, only the ringing screen; the real-time checks in Chrome run again.
