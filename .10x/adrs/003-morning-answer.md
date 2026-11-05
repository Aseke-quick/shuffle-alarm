# ADR-003: The answer of the Morning card has a table of its own, and the card never holds up a ring

**Status:** Accepted
**Date:** 2026-11-05
**Feature:** signature-features (`PLAN.md` 2.5b, Morning card)
**Author:** the 2.5b session (Architect + DBA + SRE views), plan approved by the user ("Да, по плану")

## Context
After Stop, the Morning card says when the user woke, how long after the alarm, the snoozes and the sounds that played, and asks "Which sound woke you?". The answer adjusts the weight of that sound, stays with the ring session, and feeds Insights (2.8).

Constraints:
- **Alarm reliability beats features:** the card, its answer and its setting must never keep a later alarm from ringing, and a ring that comes due while the card shows must take over.
- Testers have real alarms, weights, mornings and plans in schema version 2. Each update must keep them.
- The rules of 1.5 for Stop, Snooze and a missed ring stay as they are. The answer only adds to them.

Two facts about the web database decide where the answer goes. Both come from the code of drift 2.35.3, and `run_old_tab.sh` showed both in Chrome:
- **An open database does not migrate.** `ensureOpen` returns at once when the database is open, and the shared worker keeps it open while any tab uses it. So a tab of the new build, next to a tab of the old build, runs on the old tables. In Chrome: version 2 and no `morning_answers`, with the new build open.
- **A tab of an older build takes the version back.** `_runMigrations` calls `onUpgrade` for any difference in the version, up or down, and then writes the version of the build that opened it. So the next visit of the new build runs its step again. In Chrome: 3, then 2 with the old build, then 3 again with the new one.

## Decision
- **A table, `morning_answers`, in schema version 3:** the session (primary key, a foreign key that goes with its session), the sound (null for "Not sure", no foreign key, as the history stays when a sound is deleted), and the moment. A session without an answer has no row. `onUpgrade` only creates it, and creating a table can run twice (`CREATE TABLE IF NOT EXISTS`). `MorningAnswer` in `lib/core/models/`, `MorningAnswerRepository` in `lib/data/`. `ring_sessions` and `ring_events` do not change, and neither does a line of the code that reads or writes them.
- **The rule of the weights:** `SoundWeights.afterWoke`: the named sound times 1.2 (`wokeFactor`), once for each morning, between the same limits. What Stop or Snooze taught stays. "Not sure" changes no weight. A clear answer says more than a tap, which falls on whichever clip plays then, so it counts about twice a Stop. No sound gets lighter for not being named.
- **What the card reads:** `Morning.of(session)` in `lib/core/morning.dart`, only for a session that a Stop ended. Only events with a length are sounds that played (`RingEvent.played`). 2.8 can read a morning the same way.
- **The state of the card** is one value in memory (`morningCardProvider`): the session of the Stop. A Stop sets it, or clears it when the card is off. The answer clears it, so it counts once. A reload ends it, and the session stays in the log without an answer.
- **A ring takes over:** `_start` sets the ring and starts its sound first, and only then clears the card. `openRingingPage` replaces a card page with the ringing page, so no old card waits below a ring. A tap in the moment between does nothing to the ringing page (`_leave`).
- **Nothing about the card can stop a ring:** the ring reads nothing of it. The answer goes through the same queue of writes as the log (`_write`), after the Stop, and a failure only goes to the debug log. The setting is read when the app starts and held in memory, so a Stop never waits for it, and it stays on when it cannot be read.

## Alternatives considered
| Alternative | Pros | Cons | Why not |
|-------------|------|------|---------|
| Two nullable columns on `ring_sessions` | One read gives the session and its answer; closest to "kept with the session" | `ALTER TABLE ADD COLUMN` cannot run twice. After a tab of an older build took the version back, the step fails with "duplicate column", the database does not open, and no alarm rings. Next to an old tab, reads and writes of the log itself touch a column that is not there | The log is what a snooze comes back from, and a failed step means no alarm at all |
| Columns, with a check of `PRAGMA table_info` first | The step can run twice | More code in the one step that must not fail, and the old tab still breaks the log | A table has neither problem |
| The answer as a special `RingEvent` | No schema change | Every reader of the log must skip it, and `RingSession.outcome` reads the last event | The log stays what it is |
| `shared_preferences` | No schema change | A second place that can disagree with the log, out of reach of a query for 2.8, and it grows with each morning | It belongs with the mornings |
| A card that stays in the ringing page | No new route | The screen is filled with the accent and only Stop or Snooze may leave it; the redirect would have to tell a ring from a card | A route of its own, with the redirect of 2.5 around it |
| The card as a page below a new ring | No replacement | An old question comes back after the ring, and a Close would land on it | The ring replaces it |
| ×1.1 for the answer | The same as Stop | A person's clear answer counts as little as a tap | Too weak |
| Moving the ×1.1 of Stop to the named sound | One credit for each morning, so weights climb more slowly | Taking it back is not exact near the limits of 0.2 and 3.0 | More code for a start value |
| Sounds not named get lighter | Weights do not climb | It punishes the quiet sounds of the start, which play at 40% | It teaches the wrong thing |

## Consequences

### Positive
- The log and its code stay the same, and every step of the update can run again.
- A failed or missing answer costs one row and nothing else.
- 2.8 reads `MorningAnswerRepository.all()` and `Morning.of`.

### Negative
- 2.8 reads two lists and joins them by session id.
- Weights climb faster than they did. This is the known limit of 1.5, and real data can tune it.
- One tap is final: a wrong tap cannot be taken back. It moves one weight by ×1.2.

### Risks
- **The update:** a test moves a real database of version 2, with rows in every table, `ring_plans` too, and compares its tables with a new database. Another takes its version back and opens it again. `run_upgrade.sh` and `run_live_before.sh` with `run_live_after.sh` do it with the files of the live build.
- **A tab of the old build through a deploy:** the new tab rings, logs and shows the card, and its answer is lost with one line in the console, until every tab has closed. `run_old_tab.sh` showed that.
- **Any later step of a migration** must also be able to run twice. `addColumn` cannot, so a later task that needs one must check first (`docs/DECISIONS.md`, 2.5b).

## Dependencies
- `RingSession`, `RingEvent`, `SoundWeights`, `WeightRepository`, `MixPreviewController`, `MixTrackRow`, `RecordArt`, `SettingSwitchRow`.
- `docs/DECISIONS.md`, entries 1.5, 2.1, 2.5, 2.5a and 2.5b.
