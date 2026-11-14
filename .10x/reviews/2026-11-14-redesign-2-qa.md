# Redesign 2 (ADR-005): QA, database and code review

**Date:** 2026-11-14 · **Commits:** `fcc0a1e` (the look, wheels, deck, Analytics), `18f6de3`, `bed6382` (fixes) · **Verdict:** pass; publishing waits for the user's yes.

## QA
- `dart format .`: 0 changed. `flutter analyze`: 0 issues. `flutter test`: 1070 pass, 13 skip; the daylight saving tests pass in Europe/Berlin and America/New_York.
- New tests: `time_wheels_test` (drag, wheels go round, keys, typing, AM and PM, 24 hours, the screen-reader value, touch targets, large text), `sound_deck_test` (order, fan or row, cards move, less motion, action, flick, disabled, preview states, semantics, large text), `month_calendar_test` (with `BarChart`), `analytics_test`, `analytics_texts_test`, `analytics_screen_test`, `wide_layout_test` (1280 x 800, also at text scale 2.0), and the contrast of every token pair over the color fields.
- Found by the new tests and fixed before the commit: a card of the deck overflowed at a text scale of 2.0; one card alone could not be laid out; two key presses in one frame counted once.
- Headless Chrome 157, built as the site, fresh profile, `--autoplay-policy=user-gesture-required`, real time: three alarms set with the wheels and by typing; rings found 0.9 to 1.2 s after their minute; Snooze came back after 4 to 5 s; Stop, the Morning card and its answer were logged; a ring found 45 min late was logged as missed; Analytics showed the seven rings of six days. No console error. Screenshots: dark and light, 390 x 844 and 1440 x 900.

## Database (DBA)
| Checked | Result |
| --- | --- |
| Schema and generated code | version 3, 7 tables; `build_runner` changes nothing |
| Web files | `drift_worker.js` and `sqlite3.wasm` match the releases of drift 2.35.3 and sqlite3 3.8.0 |
| Migrations | each step can run twice; tested from versions 1 and 2, and with the version taken back |
| Integrity | foreign keys on; every child column is the start of a primary key |
| Speed | two years of rings (1.5 MB): every lookup by primary key, the whole log in 30 ms; no index missing |
| Old data | a profile of the live build (alarms, a plan) opens in the new build with every row |

Nothing was wrong, so nothing was changed. Analytics adds no table. Notes for later: ask for persistent storage; give `_restoreSnoozes` a query with a limit.

## Code review
| Found | Where | Fixed |
| --- | --- | --- |
| A ring is lost when the same check of the clock finds an older ring that is past its cap | `ringing_controller.dart`, `_onDue` | `18f6de3`, with two tests |
| The countdown of a passed ring reads "in " or "in 23 h 55 min" | `alarm_texts.dart` | `bed6382`, with a test |

Read: `lib/core`, `lib/data`, `lib/platform`, `lib/app.dart`, `lib/router.dart`, `lib/main.dart`, `lib/features` (all), `lib/design` (rewritten here), the CI workflow. Skimmed only: `tool/generate_placeholder_library.dart` and its clips. Not changed: two tabs ring twice (known since 2.4).
