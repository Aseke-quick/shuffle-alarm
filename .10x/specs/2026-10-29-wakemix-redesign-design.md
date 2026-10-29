# Wakemix redesign — design spec

**Date:** 2026-10-29
**Status:** the user approved each of the four sections on 2026-10-29 in the lead session. The full spec is waiting for the user's review.
**Slugs:** `visual-identity`, `brand-name`, `signature-features`

## Goal
Another public project, https://github.com/adilkz21/shuffle-alarm, follows our `PLAN.md` word for word and has its own "Dawn" look:
- a violet night sky with an apricot sun;
- Fraunces serif and Manrope fonts;
- a floating tab bar;
- sunrise empty states.

Our app must look and work clearly differently, and be clearly better:
- a senior-level design system;
- features of our own;
- a name of our own.

The product rules in `CLAUDE.md` do not change: English UI, at most 30 s per sound, the 10-minute cap, local-first, licensed audio only.

Never copy that project's code or design. Stay away from its signature traits: gradients, a sky, a sun, serif titles, a floating tab bar, `lib/ui/`.

## 1. Visual identity "Mixtape" (task 2.2a)

### Principles
1. **Sound is the hero.** Every alarm shows its mix. The next alarm is a record whose tracks are the sounds of its ring.
2. **Dark first.** Alarms are set at night. The light theme is complete, but dark is the reference design.
3. **Quiet at night, loud in the morning.** The accent is used sparingly on the Alarms tab. The ringing screen (task 2.5) fills the screen with it.
4. **Flat and crisp.** No gradients, glows, skies or illustrations of the sun.
5. **One thumb, half asleep.** Touch targets are at least 48 dp. The main action of a screen is a wide button at the bottom.

### Color tokens
Dark, the default:

| Token | Value | Use |
| --- | --- | --- |
| `background` | `#0B0B0C` | page |
| `surface` | `#151518` | cards, the record's label |
| `surfaceHigh` | `#1E1E22` | inputs, pressed states, off day keys |
| `outline` | `#2E2E33` | hairlines, grooves |
| `text` | `#F4F4F5` | main text |
| `textMuted` | `#8A8A90` | meta text |
| `textDisabled` | `#55555B` | alarms that are off (always together with the word "Off") |
| `accent` | `#5B8CFF` | fills, active states, accent text |
| `onAccent` | `#0B0B0C` | text and icons on the accent |
| `danger` | `#FF6B6B` | errors |

Light, which follows the system setting:

| Token | Value |
| --- | --- |
| `background` | `#F6F6F3` |
| `surface` | `#FFFFFF` |
| `surfaceHigh` | `#EDEDE8` |
| `outline` | `#E3E3DE` |
| `text` | `#0B0B0C` |
| `textMuted` | `#5C5C63` |
| `textDisabled` | `#9A9AA0` |
| `accent` (fills) | `#2F5BFF`, with `onAccent` `#FFFFFF` |
| `accentText` | `#2348E0` |
| `danger` | `#C62828` |

- A test checks every text and background pair against WCAG AA: 4.5:1, or 3:1 for text of 24 px or more and for non-text parts such as switch tracks. Disabled text is exempt.
- The agent may tune the values to pass. The accent hue stays cobalt.

### Typography
All three fonts are variable fonts under the SIL Open Font License. They are bundled in `assets/fonts/<family>/` with their `OFL.txt` and registered with `LicenseRegistry`. The app never downloads a font (local-first), and the Credits screen (task 3.6) will list them.

| Role | Font | Where |
| --- | --- | --- |
| Display | Unbounded | the time (record, list rows, dial), screen titles, the wordmark `wakemix` |
| Text | Geist | body text, buttons, labels |
| Meta | Geist Mono | small counters and captions such as "in 7 h 20 min", "tonight's mix" and "bed by 22:30". Fixed-width digits keep countdowns steady |

Scale (sp):
- display 56 (dial) and 34 (the record's label);
- row time 22, title 20, body 15, label 13;
- caption 11, the smallest size used.

### Shape, space and motion
- **Space:** a 4-pt grid, with spacing 4, 8, 12, 16, 24 and 32.
- **Corners:** radius 16 for cards and buttons, 10 for day keys; switches and chips are fully round.
- **Motion:** 150–250 ms, ease-out. A new list item fades in and moves up 8 px. There is no idle animation on the Alarms tab (quiet at night); the record spins only on the ringing screen (2.5). All motion stops when the platform asks for less motion (`MediaQuery.disableAnimations`).
- **Wide screens** (web, desktop): content is at most 560 dp wide and centred.

### Components, in `lib/design/`
- **Theme:** `ThemeData` for dark and light from the tokens. Every Material part we use is themed: switch, chips, text fields, buttons, navigation bar, dialogs, snack bars, and the time picker for "tap to type".
- **Wordmark:** `wakemix`, lowercase, in Unbounded.
- **Record hero:** the next enabled alarm as a record.
  - The label disc shows the time (Unbounded) and "in 7 h 20 min" (Geist Mono, accent), with grooves around it.
  - The outer ring has one segment per sound. Until task 2.5a it shows 10 grey segments as decoration; 2.5a makes them the real mix. Decoration only, so that the agent does not repeat the sound-pool rule of `buildRingSequence` outside `lib/core`.
  - Under the record: label and days, and the bedtime line (section 3).
  - With no alarm on: an empty record, "No alarm set" and the New alarm button.
- **Alarm track row:**
  - the time (Unbounded 22), the label and the days;
  - a mini waveform, decorative, drawn from the alarm id so it never changes, grey when the alarm is off;
  - a switch. A tap opens the editor.
- **Rotary time dial:**
  - one turn is 60 minutes, and passing 12 o'clock moves the hour;
  - a tap on the time opens keyboard entry (the time picker in input mode);
  - arrow keys change the time by 1 minute, Page Up and Page Down by 1 hour;
  - for screen readers it is an adjustable value ("6:45 AM") with increase and decrease;
  - on phones, a light haptic tick every 5 minutes.
- **Day keys:** 7 toggle keys from Monday to Sunday, the selected ones filled with the accent, each with its full day name for screen readers.
- **Wide button:** a primary (accent) and a secondary (outlined) button, full width and 52 dp tall.
- **Navigation bar:** three tabs, each an icon and a label. The active tab has text color and a 4-px accent dot. It is not a floating card.
- **Empty and error states:** an outline record. The error state keeps the texts and the Try again button of task 2.2.

### Screens
- **Alarms tab:**
  - an app bar with the wordmark and the Settings gear;
  - the record hero;
  - an "All alarms" tracklist;
  - a wide "New alarm" button at the bottom.
- **Alarm editor:**
  - the top bar: Back, the title, and the bin for an alarm that already exists;
  - the dial, then "Rings in …" and the bedtime line;
  - day keys, the label field, genre chips;
  - a wide "Save alarm" button at the bottom.
  Behavior stays as in task 2.2: Save switches the alarm on, and Delete asks first.
- **Library, Insights and Settings:** placeholders in the new style.

### Done when (task 2.2a)
- `dart format .` changes nothing, `flutter analyze` reports 0 issues, and `flutter test` passes, with the tests of task 2.2 updated to the new texts and widgets.
- New tests:
  - every token pair meets the contrast rule;
  - the bedtime logic, with its tests written first;
  - the dial: dragging, the keyboard and its screen-reader value;
  - the Alarms tab and the editor at a 2.0 text scale on a 360 × 740 screen, without overflow;
  - with less motion asked for, nothing animates.
- Headless Chrome, with a fresh profile and the site's base href:
  - screenshots of the Alarms tab (empty, and with alarms) and the editor;
  - in dark and light, at 390 × 844 and 1280 × 800;
  - no errors in the console.
- `docs/DECISIONS.md` has an entry that links ADR-001. `PLAN.md` has 2.2a ticked, with a Progress log line. `.10x/decisions/sde/visual-identity.md` says what was built.

## 2. Name: Wakemix (part of task 2.2a)
- **Changes now:**
  - the `MaterialApp` title;
  - the `<title>` and description in `web/index.html`;
  - name, short name and description in `web/manifest.json`;
  - the description in `pubspec.yaml`;
  - the wordmark;
  - the title and intro of `README.md`;
  - the working title in `CLAUDE.md` and `PLAN.md`.
  Tagline: "A new mix every morning."
- **Stays as it is:**
  - the package name `shuffle_alarm` and the Dart imports;
  - the app IDs (change them before tasks 8.3 and 8.4, docs/DECISIONS.md 0.1);
  - the database name `shuffle_alarm`, so testers keep their alarms;
  - the repo names and the site URL.
- Check the trademark before task 8.

## 3. Signature features
- **Sleep calculator (task 2.2a):**
  - `lib/core/bedtime.dart`, pure Dart, tests first: the bedtime is the next ring minus the sleep goal (8 h by default; a setting later). It is a moment, so it stays right across daylight saving time.
  - Text in the editor and under the record: before the bedtime, "Bed by 22:30 for 8 h of sleep"; after it, "Sleep now: 7 h 5 min", the time left until the ring, rounded down to whole minutes.
- **2.4a Bedtime reminder (after 2.4):**
  - an optional notification at the bedtime of the next alarm, with a short screen that explains it before the permission is asked (`CLAUDE.md`);
  - on the web only while the tab is open and notifications are allowed.
  - It leaves "Later" in `PLAN.md`.
- **2.5a Tonight's mix (after 2.5):**
  - The record shows the real mix of the next ring.
  - Tapping it lists the sounds in play order, with a preview of each, Reshuffle (a new seed) and Not tonight (skip one sound for this ring only).
  - The ring plays exactly that stored plan (schema version 2 and a migration). A sound deleted in the meantime is skipped.
  - The task writes its own ADR.
- **2.5b Morning card (after 2.5):**
  - After Stop: when the user woke, how many minutes after the alarm, the snoozes, and the sounds that played.
  - "Which sound woke you?": one tap on a sound, or "Not sure". The answer adjusts that sound's weight (the exact rule and an ADR come with the task), is kept with the ring session (a schema change), and feeds Insights (2.8).
  - It can be turned off.

## 4. Delivery: two agents
Each agent works in its own git worktree, on its own branch, and never merges or pushes to `main`. They follow `CLAUDE.md`. The user's approval of this spec is the approval of their plans: they ask the user only about new questions, and they finish with a hand-over note for the lead.

**Agent A — task 2.2a, branch `wakemix/2-2a-design`:** sections 1 and 2, and the sleep calculator.
- May change:
  - `lib/design/**`, `lib/features/**`, `lib/app.dart`, `lib/router.dart`, `lib/core/bedtime.dart`;
  - `web/index.html`, `web/manifest.json`, `assets/fonts/**`;
  - `pubspec.yaml` (fonts and description only);
  - `README.md`; `CLAUDE.md` (the `lib/design/` line, the title);
  - its own entries in `PLAN.md`, `docs/DECISIONS.md` and `.10x/decisions/*/visual-identity.md`;
  - tests under `test/design/**` and `test/features/**`, plus `test/core/bedtime_test.dart`, `test/app_test.dart` and `test/router_test.dart`.

**Agent B — task 2.3, branch `wakemix/2-3-library`:** `PLAN.md` 2.3, and saving the manifest's sounds into the database at app start.
- Delete the built-in rows that left the manifest, and keep the weights of the others.
- A Dart script in `tool/` synthesizes the 9 clips (3 genres × intensities 1–3); no downloads.
- Format: WAV, PCM 16-bit mono at no more than 22.05 kHz, so every platform plays it without ffmpeg. Each clip is at most 29 s, and the 9 are at most about 8 MB together.
- `assets/library/manifest.json` carries license `original` and every field of `CLAUDE.md`.
- Genre ids must read well through `genreName` ("calm" shows as "Calm").
- May change:
  - `tool/**`, `assets/library/**`, `lib/data/**`, `lib/main.dart`;
  - `pubspec.yaml` (assets only);
  - `test/data/**` and `test/tool/**`;
  - its own entries in `PLAN.md`, `docs/DECISIONS.md` and `.10x/decisions/*/placeholder-library.md`.
- Must not change `lib/features/**`, `lib/design/**` or `lib/app.dart`.

**QA gate:** when an agent is done, a separate review agent checks its branch:
- the whole suite and the format and analyze checks;
- the product rules: clip lengths, licenses, no network use;
- this spec;
- accessibility.
The report goes to `.10x/reviews/`. The lead asks the user. Only on the user's yes does the lead merge the branch into `main` (shared docs are joined by hand), run every check, push, wait for CI and check the live site.

**Cost:** while both agents run, Claude usage is about twice as high.

## Out of scope
- Ringing (2.4, 2.5) stays as `PLAN.md` describes it.
- App icon and splash screen (8.1).
- Renaming IDs and repos.
- Sound design beyond the placeholders.

## Risks
- **Font weight on the web.** If the three fonts are over about 600 KB together, use static weights or subsets. The agent measures it and records the result.
- **The dial is harder to use than a picker** for some people. Keyboard entry, the screen-reader value and tap-to-type keep it usable.
- **Merge conflicts.** The file boundaries above. `pubspec.yaml` and the docs are the only shared files.
- **Looking like the other project.** Everything in the Goal section stays out.
