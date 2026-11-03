# ADR-002: A ring plays a stored plan, replayed through the shuffle bag

**Status:** Accepted
**Date:** 2026-11-03
**Feature:** signature-features (`PLAN.md` 2.5a, Tonight's mix)
**Author:** the 2.5a session (Architect + DBA + SRE views), plan approved by the user on 2026-11-02 ("Да, проба включает")

## Context
Until 2.5, `RingingController._start` built a first ring with `buildRingSequence` and a new seed at the moment the ring started. Tonight's mix shows the mix of the next ring the evening before, lets the user change it, and the ring must play what the list showed.

Constraints:
- **Alarm reliability beats features:** a plan that is missing, empty, unreadable or only has sounds that are gone must still ring, with the steps of 2.5 (the sounds of the database, the library from its files, the tone).
- A plan outlives a reload, and lives in the database next to real alarms, weights and mornings of testers.
- `docs/DECISIONS.md` 1.6: a seed alone cannot rebuild a ring. The weights or the sounds may change by then, and `Random` may change with a Dart release. A platform that schedules ahead keeps its clips, as iOS will (task 5.3).
- The rules of a ring hold after every change: each clip within the clip rule, no sound twice in a row, the gentle start, up to the time cap.
- A sound deleted in the meantime is skipped (spec section 3).

## Decision
A new table in schema version 2, `ring_plans`, and a replay through the code that makes a ring anyway.

- **What is stored:** `RingPlan` in `lib/core/ring_plan.dart`: the alarm, the moment of the ring, the seed, the ids of the sounds in play order for the whole time cap, and the ids of Not tonight. Sounds are stored by id only. Windows and volumes come from the sounds and `Escalation` at ring time.
- **The replay:** `ShuffleBag(planned:)` takes, among the sounds its rules allow, the one that comes first in the plan, and uses chance only when the plan names none of them. `clipsOfPlan` is `buildRingSequence` with that order. With the sounds the plan was made of, it gives the plan back exactly, whatever the weights or the seed (a test over 200 seeds). With a sound less or more, every rule still holds by construction, because no other code path decides what plays.
- **Not tonight is a filter,** not an edit of the order: the list of ids stays, so Bring back puts a sound back in its place, and the others keep their order.
- **Which plan:** `planForRing`: the plan of that ring; else the plan of a ring still to come, which moves with the alarm; else a new one. `RingPlanRepository.settle` does this in one transaction, so two runs at once agree. An alarm keeps one plan for a ring still to come; the plan of a ring that has come stays for 2 days, for a ring after Snooze.
- **A sound joins the ring:** the order is made again with the same seed and Not tonight (`planFits`). A plan the time cap ended before its second round cannot tell a new sound from one that did not fit, so it stays, and the new sound comes after the planned ones.
- **The ring only reads:** `_planOf` reads the plan with a limit of 2 s and any failure means no plan, so `_start` falls back to what it did in 2.5. Nothing about a plan is written while a ring starts.
- **A ring after Snooze** still builds a new sequence with `snoozedSoundId`, and keeps Not tonight out.

## Alternatives considered
| Alternative | Pros | Cons | Why not |
|-------------|------|------|---------|
| Store only the seed and Not tonight, and build at ring time | The smallest table | Weights learned since, a new sound or a Dart release give another ring than the list showed (1.6) | It breaks "plays exactly that stored plan" |
| Store whole clips: windows and volumes too | The plan alone says everything | A second truth next to the sounds; a sound whose clip changed plays outside its window, and each reader must check the clip rule again | The clip rule must stay in one place |
| Walk the stored ids directly, with its own repair rules | Simple when nothing changes | A second implementation of "no sound twice", the nearest intensity and the cut at the cap; each change needs a repair step, and a bug there silences or breaks a ring | The bag already has these rules, with their tests |
| Rebuild the order at Not tonight, with the same seed and one sound less | Very little code | Every other sound jumps, and Bring back cannot restore the order | The user just chose a mix and sees it change |
| A row per sound, in a child table | Plain SQL | More rows and writes for a list that is always read whole; an unreadable row is not a real risk there but the plan is never queried by sound | JSON text is what `repeat_days` and `genres` use, and a broken row counts as no plan |
| A column on `alarms` | No new table | A snoozed ring still needs the plan of its morning while the next ring has its own, so two plans of one alarm exist at once | Primary key (alarm, ring) says it directly |
| A `TypeConverter` for the lists | Less code in the repository | A row that cannot be decoded throws inside the query, for every row of the alarm | Plain text, parsed in the repository: a broken row is no plan |

## Consequences

### Positive
- What the list shows, the record shows and the ring plays come from one function of one row.
- A plan can never break a rule of a ring, or keep it from ringing.
- Task 5.3 can schedule an iOS chain from the same plan. 2.5b and 2.8 read the ring log as before.

### Negative
- `ShuffleBag` and `buildRingSequence` have two more parameters.
- A plan is only made while the Alarms tab has been shown in the app that runs: a ring without one makes its own, as in 2.5.
- Two open tabs share the row but show a change only at their next read. They already ring twice (2.4).

### Risks
- **The migration:** `onUpgrade` only creates a table. A test moves a real database of version 1, with rows in every table, and compares its tables with a new database; a check in headless Chrome did it with the database of the live build.
- **A plan keyed by a moment:** a time zone change moves the moment of the ring. A ring still to come moves with its plan; one that has passed by then makes a new plan. `test/core/next_ring_test.dart` checks across daylight saving time that the moment planned the evening before is the moment found at the ring, to the microsecond.

## Dependencies
- `buildRingSequence`, `ShuffleBag`, `ClipWindow`, `Escalation`.
- `docs/DECISIONS.md`, entries 1.6, 2.1, 2.5 and 2.5a.
