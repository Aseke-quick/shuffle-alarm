# Status

- **Phase:** the first two tasks of the redesign are done and live (2026-10-29), and so is `PLAN.md` 2.4, the web scheduler (2026-10-30): armed alarms ring in an open tab. Next: 2.4a, the bedtime reminder, then 2.5 (`handoff.md`).
- **Team setup (the user's choice, 2026-10-29):** this session leads the process and writes the spec. After the user approves it, two agents work in parallel, each in its own worktree and branch: the design system, and `PLAN.md` task 2.3. A QA review of each branch comes before it merges into `main`, and only on the user's yes. On 2026-10-29 the user delegated every decision ("choose the best option yourself"), which stood in for that yes.

## Sub-projects of the redesign
The user wants the app to look and work clearly differently from https://github.com/adilkz21/shuffle-alarm, which follows the same `PLAN.md`, and to be clearly better.

| Slug | What | State |
| --- | --- | --- |
| `visual-identity` | Own design system (colors, type, components, motion) and every screen restyled | Built in 2.2a and live since 2026-10-29: Mixtape with a **Cobalt** accent (`#5B8CFF` on dark), **Unbounded** for display and **Geist** for text (Geist Mono for small meta), the vinyl-record hero, the alarm tracklist with mini waveforms, the rotary time dial and a wide "New alarm" button (spec section 1, ADR-001) |
| `signature-features` | Features of our own beyond `PLAN.md` | The sleep calculator is live (2.2a). Still to come, in this order: 2.4a bedtime reminder (after 2.4), 2.5a **Tonight's mix** and 2.5b **Morning card** (after 2.5). Not chosen: Name that sound |
| `brand-name` | A new app name instead of "Shuffle Alarm" | **Wakemix**, live since 2026-10-29: the display name only; package, app IDs, database name and site URL stay. First-pass trademark check on 2026-10-29: **low risk**, no live WAKEMIX mark, app, domain or business found; Kazpatent's own register could not be searched (docs/DECISIONS.md, 2026-10-30). Not legal advice: a lawyer's full search is due before filing and before task 8 |

## PLAN.md progress
Phase 0 and Phase 1 done; 2.1, 2.2, 2.2a, 2.3 and 2.4 done. Next: 2.4a (bedtime reminder), then 2.5 (ringing screen).

## Tasks
- [x] 2.2a Wakemix look, name and sleep calculator: agent A, on `main` as `70fb5bf` (cherry-picked from `47951f4`); QA passed after two fixes in `049c165` (`reviews/2026-10-29-2.2a-qa.md`, `decisions/sde/visual-identity.md`)
- [x] 2.3 Placeholder library and sync: agent B, on `main` as `48c00e0`; QA passed (`reviews/2026-10-29-2.3-qa.md`, `decisions/sde/placeholder-library.md`)
- [x] QA review and merge of each branch: done 2026-10-29 by the merge session; CI run 40879685261 green and deployed; the live site checked in headless Chrome
- [x] Follow-ups of the hand-overs: the site serves CanvasKit itself and its README says Wakemix (`b2e3e19`, CI run 40880832565 green and deployed; the live site checked again)
- [x] Security and SRE review of 2.2a and 2.3: pass, 2026-10-30 (`reviews/2026-10-30-2.2a-2.3-security.md`). Two risks for the first ring are in `decisions/sre/placeholder-library.md`

## Quality (QA, 2026-10-29)
- 416 tests since 2.4: 408 pass and 8 skip outside a time zone with daylight saving time, which CI runs in two such zones. Format and analyze clean, locally and in CI.
- The web test version is ready for testers: no open bug that blocks. Open low items (the 2.2a report): the switch thumb moves when less motion is asked for, Noto fonts for glyphs the bundled fonts lack, and tabs that screen readers call buttons.
