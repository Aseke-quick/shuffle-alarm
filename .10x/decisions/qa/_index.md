# QA — index

- [DISCOVERED] Quality gates: `dart format`, `flutter analyze` with 0 issues, `flutter test`, and the DST step in CI. For core logic, a mutation check: deliberate bugs on a copy of the code must each fail a test. Web screens are checked in headless Chrome with a fresh profile, because the Claude browser pane cannot open the database.
- The QA gate of a branch (spec section 4) runs the checks on the branch itself, re-derives the key numbers with a script of the reviewer's own (contrast, clip lengths), and checks the merged tree again, in headless Chrome too. A small bug is fixed on the merge branch with a test that fails first.
- In headless Chrome, `Runtime.enable` replays the console of the page that is already open: read the console of a fresh `nav`, or clear it first.
- The shared worker of the web database outlives a navigation and keeps the database in memory. To test what a new visit reads from IndexedDB, patch it in a new browser on the same profile, before the app opens (`run_corrupt.sh`). A dump right after a write can show the block before it: drift flushes a moment later.

## Features
| Slug | What | Status |
| --- | --- | --- |
| `placeholder-library` | Task 2.3, the 9 placeholder clips and their sync | Passed, merged 2026-10-29 |
| `visual-identity` | Task 2.2a, the Wakemix design system, name and sleep calculator | Passed after two fixes, merged 2026-10-29 |
