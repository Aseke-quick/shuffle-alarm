# Wakemix — Build Plan

An alarm that plays a different sound every 30 seconds until you get up. One Flutter codebase for web, Android, iOS, macOS, Windows and Linux. The web version comes first, as the test version.

## How to use this plan with Claude Code
1. Make a folder named `shuffle_alarm` and put `CLAUDE.md`, `PLAN.md` and `.claude/skills/next-task/SKILL.md` in it.
2. Open a terminal in that folder and run `claude`.
3. Type `/next-task`. Claude takes the first unchecked task, shows a short plan, builds it, runs the checks, ticks it off and commits.
4. Try the result (from Phase 2 on: the live web site). If something is wrong, describe what you see.
5. Type `/clear`, then `/next-task` again.

Useful extras:
- Run a specific task: `/next-task 2.6`
- At the end of each phase: `Use a subagent to review this phase's changes against PLAN.md. Report only gaps that break a requirement or a "Done when" check.`
- Before a release: `/code-review`

## Before you start
- Flutter (stable channel); `flutter doctor` shows no errors for the platforms you build.
- On your Mac: Xcode 26 or newer (iOS, macOS) and Android Studio (Android).
- A GitHub account and Claude Code.
- For phone tests: an Android phone or emulator, and an iPhone on iOS 26 or newer.

## Decisions
| Topic | Decision |
| --- | --- |
| Stack | Flutter, one codebase for 6 platforms |
| 30-second rule | Each sound plays max 30 s, then the next one starts; it rotates until Stop or Snooze; total cap 10 min (default) |
| Snooze | 5 min (default, changeable) |
| Built-in library | Only free, properly licensed music, grouped by popular genres |
| Research features | Gentle-to-strong escalation, adaptive rotation, voice messages, experiment mode |
| UI language | English only |
| Data | Local-first: no accounts, nothing uploaded (MVP) |
| Build order | Core → Web test version → Library → Android → iOS → Desktop → Research features → Release |

## Why these features
- **Rotation:** the sleeping brain responds more strongly to an unfamiliar voice, and the response fades as the voice becomes familiar (Ameen et al., J Neurosci 2022, 17 people).
- **Gentle start:** alarm sounds rated melodic were linked with less morning grogginess than neutral ones (McFarlane et al., PLOS ONE 2020, 50 people, self-report).
- **Escalation:** a gradually rising alarm was linked with better morning mood in a 14-night home study (Yang, Cera & Pauletto, KTH).
- **Voice messages:** a mother's-voice alarm woke 86–91% of children vs 53% for a tone alarm (Smith et al., J Pediatrics 2018, ages 5–12).
- **Adaptive rotation:** 55.6% of over 3 million tracked nights ended with snooze (Robbins et al., Scientific Reports 2025).
- **Keep Snooze:** 30 min of snoozing did not hurt regular snoozers in a lab study (Sundelin et al., J Sleep Research 2023).
- **Experiment mode:** we found no study comparing "same sound every day" with "a new sound every morning". The app can collect that data.

---

## Phase 0 — Setup
Goal: the empty app builds and the web test version is online.
- [x] 0.1 Create the app in this folder: `flutter create --project-name shuffle_alarm --org com.<yourname> --platforms=android,ios,web,macos,windows,linux .` Material 3 theme, app name "Shuffle Alarm".
- [x] 0.2 Strict lints (`very_good_analysis` or `flutter_lints`), the folder structure from CLAUDE.md, and `docs/DECISIONS.md`.
- [x] 0.3 App shell with go_router and Riverpod: bottom tabs Alarms, Library, Insights, plus a Settings page.
- [x] 0.4 GitHub repo + GitHub Actions: every push runs `flutter analyze` and `flutter test`; every push to `main` builds the web app and deploys it (GitHub Pages for a public repo; Cloudflare Pages or Firebase Hosting for a private repo).

Done when: CI is green and the app shell opens at the live URL.

## Phase 1 — Core engine (pure Dart, no UI)
Goal: all the "smart" logic exists and is tested before any platform work.
- [x] 1.1 Models: `Alarm` (id, time, repeat days, label, enabled, genres, gentleStart, experimentGroup), `Sound` (id, title, source: builtin/user/voice, genre, intensity 1–3, duration, clipStart), `RingSession`, `RingEvent` (soundId, startedAt, endedAt, action: stop/snooze/timeout).
- [x] 1.2 Clip rule: a clip window never exceeds 30 s; bundled clips never exceed 29 s.
- [x] 1.3 Shuffle bag: no sound repeats until every sound in the pool has played, and never the same sound twice in a row (also across bag refills).
- [x] 1.4 Escalation: the first sound is intensity 1 (gentle, melodic); each next sound is one level stronger until level 3. A volume value per level (start values 40% → 70% → 100%) for platforms that allow it.
- [x] 1.5 Adaptive weights: each sound starts at 1.0; the sound playing when the user taps Snooze is multiplied by 0.8; the sound playing when the user taps Stop by 1.1; keep weights between 0.2 and 3.0; weighted pick inside the shuffle bag. (Start values; tune with real data.)
- [x] 1.6 `buildRingSequence(alarm, pool, weights, seed)`: ordered clips that cover the 10-min cap; same seed gives the same sequence.

Done when: `flutter test test/core` passes, with tests for every rule above, including "no clip over 30 s" and "no sound twice in a row".

## Phase 2 — Web test version
Goal: a working alarm in the browser to try the idea with real people.
- [x] 2.1 drift database (works on web): alarms, sounds, ring events, weights.
- [x] 2.2 Alarms screen: list, add/edit (time, repeat days, label, genres), on/off switch, "rings in 7 h 20 min".
- [x] 2.2a Wakemix look and name (`.10x/specs/2026-10-29-wakemix-redesign-design.md`): the Mixtape design system in `lib/design/` (cobalt accent; Unbounded, Geist and Geist Mono, bundled), the next alarm as a record, the alarm tracklist, a rotary time dial, every screen restyled, the display name Wakemix, and the sleep calculator ("Bed by 22:30 for 8 h of sleep").
- [x] 2.3 Placeholder library: a script in `tool/` generates 9 original clips (3 genres × 3, synthesized melodies) + `manifest.json` with license `original`. No downloads.
- [x] 2.4 Web scheduler: "Arm alarms" button (unlocks audio), checks the clock every second, banner "Keep this tab open", screen wake lock if the browser supports it.
- [x] 2.4a Bedtime reminder: an optional notification at the bedtime of the next alarm, after a short screen that explains it; on the web only while the tab is open.
- [x] 2.5 Ringing screen: big clock, current sound title, Stop and Snooze; plays the sequence from 1.6; logs every RingEvent.
- [ ] 2.5a Tonight's mix: the record shows the real mix of the next ring; tapping it lists the sounds in play order with a preview, Reshuffle and Not tonight; the ring plays exactly that stored plan (schema version 2).
- [ ] 2.5b Morning card: after Stop, when you woke, the snoozes and the sounds that played; "Which sound woke you?" teaches the weights and feeds Insights (2.8).
- [ ] 2.6 Import own songs (mp3, m4a, wav): pick a 30-s part with a start slider and preview; stored only in the browser.
- [ ] 2.7 Voice messages: record up to 30 s, give it a name ("Mom", "Best friend"), use it in the rotation.
- [ ] 2.8 Insights tab: last 14 mornings with time to Stop, number of snoozes and sounds played.

Done when: in Chrome, an alarm set 1 minute ahead rings after "Arm alarms" with rotating sounds of max 30 s each (on time when the tab is visible, at most about 1 minute late in a background tab); Stop and Snooze are logged; the live site behaves the same.

## Phase 3 — Licensed music library
Goal: a real genre library that is 100% legal.
- [ ] 3.1 Genres v1: Pop, Rock, Hip-Hop, Electronic, Lo-fi, Classical, Jazz, Acoustic, plus Nature sounds.
- [ ] 3.2 `docs/MUSIC_SOURCING.md`: allowed licenses, candidate sources (Freesound with the CC0 filter; Free Music Archive and Incompetech after checking each track's license; Pixabay Music only after reading its Content License) and how to keep proof (license URL + date saved). You choose and download tracks; Claude Code processes them.
- [ ] 3.3 `tool/prepare_audio.sh` (ffmpeg): cut to max 29 s, 0.5 s fade in/out, normalize all clips to the same loudness (e.g. −14 LUFS), export `.mp3` (Android, desktop, web) and `.caf` (iOS, in a format iOS alarm sounds accept).
- [ ] 3.4 `manifest.json` fields: id, title, artist, genre, intensity (1–3), file, durationSec, license, sourceUrl, attribution.
- [ ] 3.5 `tool/check_licenses.dart`: fails if any audio file has no manifest entry, a disallowed license, or is longer than 29 s. Runs in CI.
- [ ] 3.6 Credits screen with all attributions (required for CC BY).
- [ ] 3.7 Library screen: browse by genre, preview, choose genres per alarm.

Done when: every genre has at least 8 clips, the license check passes in CI, and every CC BY track appears in Credits.

## Phase 4 — Android
Goal: alarms ring reliably on a real phone, even when the app is closed.
- [ ] 4.1 Spike: `alarm` package vs a small Kotlin plugin (`setAlarmClock` + foreground service + full-screen intent). Pick one and record why in `docs/DECISIONS.md`.
- [ ] 4.2 `AndroidAlarmScheduler`: single-fire alarms; reschedule after each ring, after reboot, and after a time or time-zone change.
- [ ] 4.3 Ring over the lock screen (full-screen intent); a foreground service plays the rotation with the volume ramp.
- [ ] 4.4 Permission onboarding: notifications, exact alarms, full-screen notifications, battery-optimization tips.
- [ ] 4.5 Alarm test checklist on a real phone: app open / in background / swiped away / phone locked / after reboot / Do Not Disturb on / phone idle overnight.

Done when: every 4.5 check passes on at least one real Android phone.

## Phase 5 — iOS (iOS 26+, AlarmKit)
Goal: alarms ring with the app closed and the phone on silent.
- [ ] 5.1 Spike on a real iPhone: (a) a bundled `.caf` plays as the alarm sound; (b) a chain of alarms 30 s apart with different sounds, where Stop cancels the rest; (c) can a user song or voice recording be the alarm sound?; (d) how many alarms can be scheduled at once? Record results in `docs/DECISIONS.md`.
- [ ] 5.2 `IosAlarmScheduler` with the chosen plugin (`flutter_alarmkit` ships a setup skill for Claude Code); `NSAlarmKitUsageDescription` in Info.plist; a permission screen.
- [ ] 5.3 Rotation through the alarm chain; escalation = clips ordered from gentle to strong.
- [ ] 5.4 If 5.1(c) fails: user songs and voice messages play inside the app after the user opens the alarm; explain this in the UI.
- [ ] 5.5 Run the alarm test checklist from 4.5 on the iPhone.

Done when: the alarm rings with the app closed and the phone on silent, and the rotation works on a real device.

## Phase 6 — Desktop (macOS, Windows, Linux)
Goal: alarms ring while the computer is on.
- [ ] 6.1 Tray icon and "Launch at login"; closing the window keeps the app running in the tray.
- [ ] 6.2 `DesktopAlarmScheduler`: checks the clock every second; the ringing window comes to the front.
- [ ] 6.3 A note in the UI: "Your computer must be awake for alarms to ring."
- [ ] 6.4 Builds: macOS on your Mac; Windows and Linux in GitHub Actions; a manual test on each system.

Done when: the alarm rings with the main window closed on all three systems.

## Phase 7 — Research features, full version
- [ ] 7.1 Escalation settings: gentle start (on by default), max volume.
- [ ] 7.2 Adaptive rotation on by default; "Why this sound?" info; "Reset learning" button.
- [ ] 7.3 Experiment mode: 4 weeks, 2 weeks "same sound" and 2 weeks "rotation" in random order; after Stop, a check-in "How hard was it to get up? (1–5)"; tracks time to Stop, snoozes and missed alarms.
- [ ] 7.4 Export the experiment data as CSV (only when the user taps Export). If friends take part, ask for their consent and collect no names.
- [ ] 7.5 Voice messages from friends: import audio files sent by chat (share sheet or file picker), trim to 30 s.

Done when: a 4-week experiment can run on one device and export a CSV with one row per morning.

## Phase 8 — Release
- [ ] 8.1 App icon, splash screen, store screenshots (English).
- [ ] 8.2 Privacy policy (local-first, no data collected), published on the web site.
- [ ] 8.3 Android: Play Console declarations (exact alarms, full-screen intent); internal testing track.
- [ ] 8.4 iOS: TestFlight (needs a paid Apple Developer account).
- [ ] 8.5 Desktop: signed and notarized macOS build, Windows installer (MSIX), Linux AppImage or Flatpak.
- [ ] 8.6 Final check: `/code-review`, the license check, and the alarm test checklist on every platform.

Done when: testers can install the app on every platform.

## Later (not in the MVP)
- Accounts and cloud sync; sending a voice message straight to a friend's alarm (needs a server and moderation).
- More genres; smart wake-up in light sleep (needs sleep tracking; check the evidence first).

## Progress log
<!-- Claude Code adds one line per finished task: date, task ID, short note. -->
- 2026-10-27 · 0.1 · Flutter 3.47.8 app created for 6 platforms (org com.asanali), Material 3 theme, display name "Shuffle Alarm".
- 2026-10-28 · 0.2 · very_good_analysis 11 replaces flutter_lints (2 rules off, see docs/DECISIONS.md); folder structure with .gitkeep placeholders; test/architecture_test.dart guards the layer rules; docs/DECISIONS.md started.
- 2026-10-28 · 0.3 · App shell: go_router 18 tabs Alarms, Library, Insights with placeholder screens, plus a Settings page above them; router in a flutter_riverpod 3 provider; Material now comes from the material_ui package (see docs/DECISIONS.md); widget tests for switching tabs and opening Settings.
- 2026-10-28 · 0.4 · Private repo github.com/Aseke-quick/shuffle-alarm; `.github/workflows/ci.yml` runs a format check, analyze and test on every push, and publishes the built web app from `main` to the public repo Aseke-quick/shuffle-alarm-web (built files only), served at https://aseke-quick.github.io/shuffle-alarm-web/. Actions pinned by commit SHA, Flutter 3.47.8 in CI; commits use the GitHub no-reply email (see docs/DECISIONS.md).
- 2026-10-28 · 1.1 · Core models in `lib/core/models/`: `ClockTime`, `Alarm` (+ `ExperimentGroup`), `Sound` (+ `SoundSource`), `RingEvent` (+ `RingAction`) and `RingSession` (one alarm occurrence, snoozes included). Constructors reject impossible values; models are immutable with value equality, so `meta` is now a direct dependency for `@immutable` (see docs/DECISIONS.md). 34 tests in `test/core/models/`.
- 2026-10-28 · 1.2 · Clip rule in `lib/core/clip_rule.dart`: `ClipWindow.of(sound)` plays a sound from its `clipStart` for at most 30 s, at most 29 s for a built-in clip, and never past the end of its file; a longer file is cut, not rejected (see docs/DECISIONS.md). 11 tests in `test/core/clip_rule_test.dart`, among them "no clip over 30 s, and no built-in clip over 29 s" over 141 sounds.
- 2026-10-28 · 1.3 · Shuffle bag in `lib/core/shuffle_bag.dart`: each `next()` of `ShuffleBag(pool, random: Random(seed))` takes a random sound out of the bag, so every sound plays once per bag, and a refilled bag never starts with the sound that just played. Every choice goes through one method, where 1.5 adds weights. A pool of one sound repeats it; an empty pool throws, and 1.6 must give such an alarm all the built-in sounds (the user's choice, see docs/DECISIONS.md). 10 tests in `test/core/shuffle_bag_test.dart`, among them "no sound twice in a row" over 1000 picks for pools of 2–10 sounds and 200 seeds each.
- 2026-10-28 · 1.4 · Gentle start in `lib/core/escalation.dart`: `Escalation.at(index, gentleStart:)` gives the first three sounds of a ring intensity 1, 2 and 3 at 40%, 70% and 100% volume, then any sound at 100%. `ShuffleBag.next(intensity:)` takes a sound of that intensity, or of the nearest one the bag rules allow (the gentler on a tie), so the 1.3 rules still hold. Gentle start off and a ring after Snooze: a plain shuffle at 100% (the user's choices, see docs/DECISIONS.md). 13 new tests in `test/core/escalation_test.dart` and `test/core/shuffle_bag_test.dart`; 5 deliberate bugs were each caught.
- 2026-10-28 · 1.5 · Adaptive weights in `lib/core/adaptive_weights.dart`: `SoundWeights` starts every sound at 1.0; `afterSnooze` multiplies the weight of the sound playing at Snooze by 0.8, `afterStop` the one at Stop by 1.1, always within 0.2–3.0. `ShuffleBag(weights:)` picks among the sounds the bag rules allow, each as likely as its weight, with one random number per pick, so a heavier sound tends to come earlier in its bag. A missed alarm changes no weight; one set of weights for all alarms and every kind of sound (the user's choices, see docs/DECISIONS.md). 22 new tests in `test/core/adaptive_weights_test.dart` and `test/core/shuffle_bag_test.dart`; 9 deliberate bugs were each caught.
- 2026-10-28 · 1.6 · Ring sequence in `lib/core/ring_sequence.dart`: `buildRingSequence(alarm, pool, weights, seed)` lists the clips of one ring back to back until the time cap (`cap:`, 10 min by default), the last one cut to end there (`ClipWindow.cutTo`); each `RingClip` has its sound, clip window, volume and `startsAt`. One shuffle bag per ring, with the weights and the gentle start. A ring plays the built-in sounds of the alarm's genres (all of them if there are none) plus the user's own songs and voice messages; a ring after Snooze (`snoozedSoundId:`) plays at full volume and never starts with the snoozed sound (`ShuffleBag(lastId:)`); `Random(seed)` stays (the user's choices, see docs/DECISIONS.md). 30 new tests in `test/core/ring_sequence_test.dart`, `test/core/clip_rule_test.dart` and `test/core/shuffle_bag_test.dart`; 18 deliberate bugs were each caught. Phase 1 is done.
- 2026-10-28 · 2.1 · drift database `AppDatabase` in `lib/data/database.dart` (drift 2.35.3 and sqlite3 3.8.0, pinned): tables alarms, sounds, weights, ring sessions and ring events, read and written through `AlarmRepository`, `SoundRepository`, `WeightRepository` and `RingSessionRepository` with the core models. A sound comes with where its audio is (`StoredSound.audioPath`: an asset path for built-in clips, a path in the app's own storage for songs and voice messages); a weight goes with its sound; the ring history stays when an alarm or sound is deleted; enums by name, times and lengths in microseconds; `newId()` for new ids. Web: `web/sqlite3.wasm` and `web/drift_worker.js` from the matching GitHub releases (a test checks their SHA-256); in Chrome the data lives in IndexedDB. `tool/web_database_check.dart` passed in headless Chrome 156, and a second visit found the data of the first (the Claude browser pane cannot open the database, see docs/DECISIONS.md). 36 new tests in `test/data/`; 17 deliberate bugs were each caught.
- 2026-10-29 · 2.2 · Alarms tab: the alarms by time of day, each with its label, repeat days ("Weekdays", "Mon, Wed, Fri"), "Rings in 7 h 20 min" or "Off", and an on/off switch. `AlarmEditorScreen` (`/alarms/new`, `/alarms/<id>`, above the tabs) sets the time with the time picker, the repeat days, the label and the genres; Save switches the alarm on, and Delete asks first. `nextRing(alarm, now)` in `lib/core/next_ring.dart` counts days of the calendar, so an alarm keeps its clock time when the clock changes for daylight saving time; CI runs its tests again in Europe/Berlin and America/New_York. "Rings in" rounds up to the minute and updates at the start of each minute (`clockProvider`). Riverpod providers for the database, the repositories, the alarm list and the library's genres are in `lib/data/providers.dart`; a database that cannot open shows an error with Try again, not an empty list. The genres are those of the built-in sounds (none until task 2.3), and times use the device's 12- or 24-hour format (the user's choices, see docs/DECISIONS.md). 49 new tests; 26 deliberate bugs were each caught; checked in headless Chrome 156: add, live countdown, switch, reload, delete.
- 2026-10-29 · 2.3 · Placeholder library: `tool/generate_placeholder_library.dart` synthesizes 9 original clips without a download and writes `assets/library/manifest.json` (license `original`, artist Wakemix): the genres acoustic, electronic and lo-fi (the user's choice), each with a gentle, a medium and a strong clip, slower and softer to faster, louder and brighter (−18 to −14 LUFS). WAV PCM 16-bit mono at 22.05 kHz, 16–21.5 s each, 7.4 MB together; the same bytes on every run. At each start `main` saves the manifest's clips into the database in one transaction (`syncLibrary` in `lib/data/library_sync.dart`): new and changed clips saved with their weights kept, built-in sounds that left the manifest deleted, songs and voice messages never touched; a failure is only logged (see docs/DECISIONS.md). 29 new tests; 22 deliberate bugs were each caught; checked in headless Chrome 156: the editor offers Acoustic, Electronic and Lo-fi, and every clip decodes.
- 2026-10-29 · 2.2a · The Wakemix look (spec in `.10x/specs/`, ADR-001): `lib/design/` holds the tokens (the colors of the spec, every text and control pair tested against WCAG AA), `WakemixTheme` (Material 3, dark and light, following the device) and the components: the next alarm as a record, the alarm tracklist with mini waveforms, the rotary time dial (drag on the ring, passing 12 o'clock moves the hour; tap to type; arrow and Page keys; an adjustable value for screen readers; a haptic tick every 5 min on phones), day keys, wide buttons, a flat tab bar with an accent dot, and the empty and error states. Every screen restyled, with the behavior of 2.2. Unbounded, Geist and Geist Mono bundled from Google Fonts with their OFL texts and registered licenses; Unbounded and Geist Mono cut down to Latin, 401 KB for all three (about 212 KB gzipped), and Geist also named `Roboto`, so the web app downloads no font (see docs/DECISIONS.md). Display name Wakemix, "A new mix every morning."; package, app IDs, database and site URL unchanged. Sleep calculator in `lib/core/bedtime.dart` (tests first, also in Europe/Berlin and America/New_York, now in CI too): "Bed by 10:45 PM for 8 h of sleep", then "Sleep now: 7 h 5 min". Less motion: pages, dialogs and new rows without motion. 113 new tests (326 in all, 8 of them for daylight saving time), among them 2.0 text scale on 360 × 740 with the real fonts and the two design rules of ADR-001 in the architecture test; 13 deliberate bugs were each caught. Checked in headless Chrome 156 with a fresh profile and the site's base href: the Alarms tab empty and with alarms, and the editor, dark and light, 390 × 844 and 1280 × 800; no console error.
- 2026-10-30 · 2.4 · Web scheduler: `dueRings` in `lib/core/due_rings.dart` (tests first) finds each ring once after the check before, also after a late check; `TickingAlarmScheduler` checks the clock every second and when the tab comes back into view; `AlarmScheduler`, `SoundPlayer` and `ScreenWakeLock` interfaces in `lib/platform/` with web versions (Web Audio, unlocked in the tap on "Arm alarms"; `navigator.wakeLock`) and idle ones for the other platforms until Phases 4–6. The Alarms tab asks "Arm alarms to hear them" while an alarm is on, then says "Keep this tab open" and whether the screen stays on. A due alarm opens a plain ringing page with Stop and plays its ring sequence from where the clock says (`ringPosition`) until Stop or the 10-min cap; a one-time alarm switches off; a ring found after its cap is missed (the ringing screen, Snooze and the log come with 2.5; see docs/DECISIONS.md). "Arm alarms" also loads every sound into memory, so a ring needs no network. `web` 1.1.2 is a direct dependency. 58 new tests (416 in all); checked in headless Chrome 156 with `--autoplay-policy=user-gesture-required`: on time in a visible tab (0.6 s), 21.7 s late in a tab hidden for 6 min, clips rotating in the background, no console error.
- 2026-11-02 · 2.4a · Bedtime reminder: an optional notification at the bedtime of the next alarm, off until someone turns it on, with one switch in Settings, its first real setting (the user's choice: no link on the Alarms tab, no test button, see docs/DECISIONS.md). `BedtimeReminderScreen` explains it, and the browser's question comes only in the tap on "Turn on"; a no, no answer or "Not now" leaves the alarms as they are. `dueBedtimeRing` and `soonestRing` in `lib/core/` (tests first, also in both time zones): each bedtime once, also after a late check, less than 30 min late, one a night. `SystemNotifications` in `lib/platform/`, with a web version (`new Notification`) and an idle one; browsers that cannot show one from a page say "Not available on this device." and ask nothing. `BedtimeReminderController` runs on the minute clock of the "Rings in" texts, so nothing that rings changed. `shared_preferences` 2.5.6 saves the choice. 79 new tests (495 in all, 10 of them for daylight saving time); 37 deliberate bugs were each caught. Checked in headless Chrome 156 with a fresh profile: the question comes only after the tap; in an open tab the reminder showed 17 ms after its bedtime, in a tab hidden for 7 min 57 s after it; an armed alarm rang 42 ms after its minute with the reminder in that same minute, and 105 ms after it when the browser refused; no console error.
- 2026-11-02 · 2.5 · Ringing screen: `RingingScreen` fills the page with the accent (`AccentPage`), with a big clock on a turning record (`SpinningRecord`, still when no sound plays or less motion is asked for), the title of the sound that plays, "Snooze 5 min" and "Stop". Snooze: `ringAfterSnooze` in `lib/core/snooze.dart` (tests first) and `AlarmScheduler.schedule`, so a late check finds it too; a card on the Alarms tab with "Stop alarm"; it outlives a reload, from the log. The log: a `RingSession` from the start of each ring, a `RingEvent` for each clip, Stop and Snooze, with `RingSession.outcome` and `RingEvent.silent`, also for a ring found after its cap or due while another rang; the weights learn from Stop and Snooze. A ring always has a sound: the database, the library straight from its files, or a tone made in code (`fallbackTone`, `SoundPlayer.playTone`), also in the place of a clip that cannot be read or is not in memory within 2 s. Four things from 2.4 that could keep an alarm silent are fixed: a ring over its cap or blocked held back later alarms, a blocked ring had no cap, the wake lock let go during the ring of a one-time alarm, and a browser's Back hid the ring with its sound on (see docs/DECISIONS.md). No schema change. 128 new tests (623 in all, 10 of them for daylight saving time); 99 deliberate bugs were each caught, 5 of them after a better test. Checked in headless Chrome 156 with a fresh profile and `--autoplay-policy=user-gesture-required`, in real time: found 0.56 s after its minute in a visible tab, clips rotating, back 0.15 s after a Snooze; back 55.3 s late in a hidden tab, clips rotating; 32 clips in 599.9 s, quiet at the 10-min cap, and the next alarm rang on the page left open. A ring, a Stop, a Snooze and a missed ring read back from the browser's real database; no console error.

## References
- Unfamiliar voices in sleep: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8896625/
- Melodic alarms (PLOS ONE): https://doi.org/10.1371/journal.pone.0215788
- Rising alarm (KTH): https://dael.euracoustics.org/confs/fa2026/data/articles/000156.pdf
- Mother's-voice smoke alarm: https://www.nationwidechildrens.org/newsroom/news-releases/2018/10/smoke-alarm-study
- Snooze study (Scientific Reports): https://news.massgeneralbrigham.org/en/dont-hit-snooze-on-new-research-about-waking-up-each-morning
- Snoozing lab study: https://www.nbcnews.com/health/health-news/ok-hit-snooze-button-according-science-rcna120830
- Bedtime procrastination: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC11059092/
- AlarmKit custom sounds (developer reports): https://developer.apple.com/forums/thread/798140
- flutter_alarmkit: https://pub.dev/packages/flutter_alarmkit
- alarm_kit: https://pub.dev/packages/alarm_kit
- Android full-screen intent limits: https://source.android.com/docs/core/permissions/fsi-limits
- Chrome background tabs: https://developer.chrome.com/blog/background_tabs
- Pixabay terms: https://pixabay.com/service/terms/
- Claude Code best practices: https://code.claude.com/docs/en/best-practices
