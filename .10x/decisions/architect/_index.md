# Architect — index

- [DISCOVERED] Layers:
  - `lib/core/`: pure Dart (models, clip rule, shuffle bag, escalation, adaptive weights, ring sequence, next ring);
  - `lib/data/`: drift database, repositories and Riverpod providers;
  - `lib/platform/`: scheduler and player interfaces, still empty;
  - `lib/features/`: screens.
  `test/architecture_test.dart` guards the imports.
- [DISCOVERED] Routing: tabs Alarms, Library and Insights in a `StatefulShellRoute`. Settings and the alarm editor open above the tabs, through the root navigator (`lib/router.dart`).
- [DISCOVERED] State: hand-written Riverpod providers, no code generation. `clockProvider` ticks at each minute.
- No theme layer yet: `lib/app.dart` builds `ThemeData` from a seed color. The redesign adds one (sub-project `visual-identity`).
- 2026-10-29 · `visual-identity`: the `lib/design/` layer and ADR-001 (see `visual-identity.md`).
