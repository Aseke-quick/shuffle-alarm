# Senior engineer — placeholder-library, task 2.3 (2026-10-29)

## Approach
1. **`tool/generate_placeholder_library.dart`,** pure Dart, run with `dart run`:
   - It synthesizes 9 original melodies: 3 genres × intensities 1–3.
   - Tones are sine, triangle or square, shaped by ADSR envelopes. Gentle clips are slower, softer and higher; strong ones are faster and brighter.
   - A fixed seed, so every run gives the same bytes.
   - It writes WAV (PCM 16-bit mono, at most 22.05 kHz) to `assets/library/<genre>/<id>.wav`, and writes `assets/library/manifest.json`. Every field `CLAUDE.md` asks for, with `license: original`, artist "Wakemix", and `sourceUrl`/`attribution` set as the rules allow for our own work.
2. **Library sync in `lib/data/`.**
   - A pure planner (manifest entries plus stored sounds give the rows to save and the ids to delete) and a function that applies the plan through `SoundRepository`.
   - Only `SoundSource.builtin` rows are deleted, and the upsert keeps the weights.
   - It is triggered once at app start from `lib/main.dart`, for example through a `ProviderContainer` and an `UncontrolledProviderScope`. Widget tests pump `ShuffleAlarmApp` without it.
3. **Tests:**
   - the planner (adds, updates, deletes, never user or voice sounds);
   - the sync against `memoryDatabase()`;
   - the manifest: every file exists, the fields are filled, each clip is at most 29 s (read from the WAV header), the total size is within budget, and the genre ids read well through `genreName`.
4. **Docs:** docs/DECISIONS.md (genres, format, sizes, sync rules), and `PLAN.md` 2.3 ticked.

## Tricky parts
- **Asset paths:** `audioPath` is the asset path (docs/DECISIONS.md 2.1). On the web, assets come from `assets/assets/...` at runtime, and the player of 2.5 resolves them.
- **The database can fail to open on the web.** The sync catches the error and logs it, never crashes the app; the Alarms tab already shows the error.
- **Shared files:** do not touch `lib/features/`, `lib/design/` or `lib/app.dart`. Only the assets part of `pubspec.yaml`.
