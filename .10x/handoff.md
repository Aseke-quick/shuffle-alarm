# Handoff

## Current handoff
**From:** QA and merge (the merge session), 2026-10-29. **To:** the next task, `PLAN.md` 2.4 (web scheduler), through `/next-task`.

- **State:** `main` has tasks 2.2a and 2.3, the two QA fixes and the follow-ups (`status.md`). Every check is green locally and in CI, and https://aseke-quick.github.io/shuffle-alarm-web/ shows Wakemix and keeps its data. QA reports: `reviews/2026-10-29-2.2a-qa.md` and `reviews/2026-10-29-2.3-qa.md`; QA notes: `decisions/qa/visual-identity.md` and `decisions/qa/placeholder-library.md`.
- **What 2.4 builds on:**
  - **Screens:** every color and text style comes from `lib/design/` (ADR-001). `test/architecture_test.dart` fails on a color literal in `lib/features/`. "Arm alarms" fits `WideButton` (primary, 52 dp). For "Keep this tab open", add a banner component to `lib/design/components/` that takes plain values. Keep the accent sparing on the Alarms tab (spec section 1, "quiet at night"). Motion through `Motion.of` and `Motion.styleOf`, so less motion stops it.
  - **The scheduler:** no `AlarmScheduler` exists yet. Put the interface in `lib/platform/` and the web version in `lib/platform/web/`; features must not import `lib/platform/web/`, and the architecture test checks it, conditional imports too.
  - **When to ring:** ask `nextRing(alarm, lastCheck)` on every tick and ring when that time is not after the clock (docs/DECISIONS.md 2.2, "after `now`, never at it"), so a late tick in a background tab still rings once. A one-time alarm stays on after its ring until 2.4 or 2.5 switches it off (`copyWith(enabled: false)`).
  - **Sounds:** at each start, `librarySyncProvider` saves the 9 built-in clips into the database, so `SoundRepository.all()` is the pool of `buildRingSequence`. The clips are `assets/library/<genre>/<id>.wav`; audioplayers' `AssetSource` adds `assets/` itself, so pass the asset path without it (docs/DECISIONS.md 2.3). Before adding audioplayers or a wake-lock package, check pub.dev as `CLAUDE.md` says.
  - **The browser:** audio starts only after a user gesture, so "Arm alarms" must be a tap. A screen wake lock needs HTTPS, which GitHub Pages has, and the browser drops it when the tab is hidden; ask again on `visibilitychange`.
- **How to check it:**
  - Build as the deploy job does: `flutter build web --release --base-href /shuffle-alarm-web/ --no-web-resources-cdn`.
  - Headless Chrome with a fresh profile, driven by `cdp.dart` in the merge session's notes folder (`local_77cb9a4a-…`; it adds `wheel=` and `init=` steps). The Claude browser pane cannot open the database.
  - `Runtime.enable` replays the console of the page that is already open, so read the console of a fresh `nav`.
  - Headless Chrome may treat autoplay differently from a normal window. Check the audio unlock with `--autoplay-policy=user-gesture-required`, or in a normal Chrome window.
- **Remaining risks and open items:** the 2.2a report lists them (Low and Info): the switch thumb moves when less motion is asked for, Noto fonts for glyphs the bundled fonts lack, tabs that screen readers call buttons, and the 1-minute gap between "Rings in" and "Sleep now" in the first minute.
- **Release readiness:** the web test version is ready for testers; nothing open blocks it.

## Handoff history
- **2026-10-29, planning (EM, senior engineer) to SDE agents A and B:** agent A did 2.2a after `decisions/senior-engineer/visual-identity.md` and spec sections 1–3, agent B did 2.3 after `decisions/senior-engineer/placeholder-library.md`. Agent B kept to its file boundaries of spec section 4; agent A changed three files outside its list, each for one purpose (the 2.2a report). Both pushed their own branches for CI, never touched `main`, and left hand-over notes in the shared notes folder.
