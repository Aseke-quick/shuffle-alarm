# SDE — placeholder-library, task 2.3 (2026-10-29)

Built by agent B on branch `claude/2-3-placeholder-library-517447` (the spec named it `wakemix/2-3-library`; the app made the worktree with this name). The decisions are in docs/DECISIONS.md, entry "2.3 · Placeholder library and its sync".

## What was built
- **The tool,** `dart run tool/generate_placeholder_library.dart`, pure Dart:
  - `tool/placeholder_library/synth.dart`: oscillators, filters, plucked strings, FM electric piano, synthesizer, struck bars, drums, reverb, echo, tape wobble, crackle, loudness, a limiter, PCM and WAV.
  - `tool/placeholder_library/clips.dart`: the 9 clips as code, 3 genres × intensities 1–3.
  - `tool/placeholder_library/library.dart`: the files, by path, and the manifest.
- **The library:** `assets/library/{acoustic,electronic,lo-fi}/*.wav` and `assets/library/manifest.json`. WAV PCM 16-bit mono at 22,050 Hz, 16–21.5 s each, 7,427,718 bytes together, −18 / −16 / −14 LUFS by intensity.
- **The app:**
  - `lib/data/library_manifest.dart`: `LibraryEntry`, `parseLibraryManifest`, `loadLibraryManifest`.
  - `lib/data/library_sync.dart`: the pure `planLibrarySync`, and `syncLibrary`, which applies the plan through `SoundRepository` in one transaction.
  - `lib/data/providers.dart`: `librarySyncProvider` and `startLibrarySync`. `lib/main.dart` calls it with the app's `ProviderContainer`.
  - `pubspec.yaml` assets: `assets/library/` and each genre folder.
- **Tests (29 new, 242 in all):**
  - `test/data/library_sync_test.dart`: the planner, the sync on `memoryDatabase()` (weights kept, user sounds left alone, one stream update), the provider (the bundled library and its genres, a failed database, Try again).
  - `test/data/library_manifest_test.dart`: the parser, and the library in `assets/library` (in the app's assets, no stray files, allowed licenses, WAV headers at most 29 s and as long as the manifest says, ids and genre names).
  - `test/tool/generate_placeholder_library_test.dart`: the same bytes on every run, the committed files are what the tool makes, 3 × 3 clips, original clips, format and size budget, louder and brighter from gentle to strong.
  - 22 deliberate bugs, each caught.

## Beyond the senior engineer's approach
- Richer sounds than sine, triangle and square with ADSR: Karplus–Strong strings, FM electric piano, drums, a reverb and a limiter, so the test version sounds like music.
- Noise from a xorshift32 generator of the tool's own, because `Random`'s numbers may change in a new Dart release.
- The sync logs a change once and a failure always, and only once a run has settled: while a provider runs again, Riverpod still shows its old value.
- A manifest clip with the id of a song or voice message of the user's is left out and listed as a clash, so a user's sound is never saved over.

## For the next tasks
- 2.5 (player): on the web, an asset is at `assets/assets/library/...`. audioplayers' `AssetSource` adds the first `assets/` itself.
- Phase 3: the tool rewrites the whole manifest, so change it or retire it when real music arrives.
- 5.1: Flutter assets on iOS live in `App.framework/flutter_assets`; check whether AlarmKit plays a clip from there.
