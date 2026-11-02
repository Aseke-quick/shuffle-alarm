# SRE: placeholder-library (task 2.3)

## Failure modes at start
- **The database cannot open** (web: blocked storage or private browsing). The sync fails and logs it, and the app keeps running. The Alarms tab says "Alarms are not available" and offers Try again. That runs the sync again, because the sync watches `databaseProvider`.
- **Riverpod retries a failed sync by itself**, up to 10 times with a growing pause. So the log can show one failure several times.
- **A broken manifest** throws a `FormatException`, which is handled the same way. A test loads every bundled clip, so a broken manifest fails CI before it ships.

## Two risks for the first ring (tasks 2.4 and 2.5)
2.3 does not schedule or ring, so the alarm checklist of `PLAN.md` 4.5 does not apply to it yet. But the first ring will depend on it:
1. **An empty sound pool throws.** `buildRingSequence` throws an `ArgumentError` when the pool is empty. That happens when the sync failed while the database works and the user has no songs or voice messages of their own. The alarm would then make no sound. 2.5 needs a fallback, for example the manifest's clips straight from the assets, or a tone made in code.
2. **On the web, a clip downloads only when it plays.** Nothing caches the clips offline: the service worker only unregisters itself, and GitHub Pages lets the browser keep files for 10 minutes. If the network is down at ring time, a clip cannot load. Load the clips into memory when the user taps "Arm alarms", so the ring does not need the network.

## Cost
The 9 clips are 7.4 MB together, but none downloads before it plays.

## Done
Both risks are closed. Risk 2 with task 2.4: "Arm alarms" loads every sound into memory. Risk 1 with task 2.5: a ring plays the library straight from its files when the database has no sounds, and else a tone made in code (docs/DECISIONS.md, 2.5).
