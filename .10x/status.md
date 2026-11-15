# Status

- **2026-11-15:** redesign 2, Analytics and the three languages are pushed and live. The repo is public and the site is at https://aseke-quick.github.io/shuffle-alarm/ (`gh-pages` branch; `docs/DECISIONS.md`). Read the rule "Work fast and spend few tokens" in `CLAUDE.md` first.
- **Now (2026-11-14):** redesign 2, slug `visual-identity-2`, is built on `main` (ADR-005, spec `specs/2026-11-14-wakemix-redesign-2-design.md`): the "Soft depth" look, the wide layout, the time wheels, the sound deck and Analytics (task 2.8). Every check passes and it ran in headless Chrome (`reviews/2026-11-14-redesign-2-qa.md`). Task 2.6 waits in its worktree and must rebase onto this look.
- **Also built on 2026-11-14:** task 2.9, three languages (English, Russian, Kazakh; `docs/DECISIONS.md`). The Russian and Kazakh texts wait for the user's reading. Task 2.10 (a Stop that is hard to hit half asleep) is in `PLAN.md`, not started: ask the user which of its two parts first.

- **Phase:** the first two tasks of the redesign are done and live (2026-10-29), and so are `PLAN.md` 2.4, the web scheduler (2026-10-30): armed alarms ring in an open tab; 2.4a, the bedtime reminder (2026-11-02); 2.5, the ringing screen with Snooze and the ring log (2026-11-02); 2.5a, Tonight's mix (2026-11-03); and 2.5b, the Morning card (2026-11-05). Next: 2.6, import own songs (`handoff.md`).
- **Team setup (the user's choice, 2026-10-29):** this session leads the process and writes the spec. After the user approves it, two agents work in parallel, each in its own worktree and branch: the design system, and `PLAN.md` task 2.3. A QA review of each branch comes before it merges into `main`, and only on the user's yes. On 2026-10-29 the user delegated every decision ("choose the best option yourself"), which stood in for that yes.

## Sub-projects of the redesign
The user wants the app to look and work clearly differently from https://github.com/adilkz21/shuffle-alarm, which follows the same `PLAN.md`, and to be clearly better.

| Slug | What | State |
| --- | --- | --- |
| `visual-identity` | Own design system (colors, type, components, motion) and every screen restyled | Built in 2.2a and live since 2026-10-29: Mixtape with a **Cobalt** accent (`#5B8CFF` on dark), **Unbounded** for display and **Geist** for text (Geist Mono for small meta), the vinyl-record hero, the alarm tracklist with mini waveforms, the rotary time dial and a wide "New alarm" button (spec section 1, ADR-001). The ringing screen fills the page with the accent, with a spinning record, since 2.5. The record shows the real mix since 2.5a |
| `visual-identity-2` | The look the user chose after rejecting Mixtape: "Soft depth" | Built 2026-11-14 (ADR-005): olive, pine and bronze color fields, glass cards, a cream accent `#E2D398`, Geist only, a top bar and two columns from 1000 px; `TimeWheels`, `SoundDeck`, `MonthCalendar`, `BarChart`. The record, the dial and Unbounded are gone |
| `signature-features` | Features of our own beyond `PLAN.md` | The sleep calculator (2.2a), the bedtime reminder (2.4a), **Tonight's mix** (2.5a, ADR-002) and the **Morning card** (2.5b, ADR-003) are live. Not chosen: Name that sound |
| `brand-name` | A new app name instead of "Shuffle Alarm" | **Wakemix**, live since 2026-10-29: the display name only; package, app IDs, database name and site URL stay. First-pass trademark check on 2026-10-29: **low risk**, no live WAKEMIX mark, app, domain or business found; Kazpatent's own register could not be searched (docs/DECISIONS.md, 2026-10-30). Not legal advice: a lawyer's full search is due before filing and before task 8 |

## PLAN.md progress
Phase 0 and Phase 1 done; 2.1, 2.2, 2.2a, 2.3, 2.4, 2.4a, 2.5, 2.5a, 2.5b, 2.8 and 2.9 done. Next: 2.6 (import own songs), then 2.7 and 2.10.

## Tasks
- [x] 2.2a Wakemix look, name and sleep calculator: agent A, on `main` as `70fb5bf` (cherry-picked from `47951f4`); QA passed after two fixes in `049c165` (`reviews/2026-10-29-2.2a-qa.md`, `decisions/sde/visual-identity.md`)
- [x] 2.3 Placeholder library and sync: agent B, on `main` as `48c00e0`; QA passed (`reviews/2026-10-29-2.3-qa.md`, `decisions/sde/placeholder-library.md`)
- [x] QA review and merge of each branch: done 2026-10-29 by the merge session; CI run 40879685261 green and deployed; the live site checked in headless Chrome
- [x] Follow-ups of the hand-overs: the site serves CanvasKit itself and its README says Wakemix (`b2e3e19`, CI run 40880832565 green and deployed; the live site checked again)
- [x] Security and SRE review of 2.2a and 2.3: pass, 2026-10-30 (`reviews/2026-10-30-2.2a-2.3-security.md`). Two risks for the first ring are in `decisions/sre/placeholder-library.md`

## Quality (QA, 2026-10-29)
- 1109 tests since 2.9 (2026-11-14): 1096 pass and 13 skip outside a time zone with daylight saving time, which CI runs in two such zones. Format and analyze clean, locally and in CI.
- The web test version is ready for testers: no open bug that blocks. Open low items (the 2.2a report): the switch thumb moves when less motion is asked for, Noto fonts for glyphs the bundled fonts lack, and tabs that screen readers call buttons.
