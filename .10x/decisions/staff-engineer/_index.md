# Staff engineer — index

- [DISCOVERED] Every task follows the `CLAUDE.md` workflow:
  - a plan first when 2 or more files change;
  - tests first in `lib/core`;
  - `dart format`, `flutter analyze` with 0 issues, and `flutter test`;
  - one commit per task, `type(scope): summary`, pushed to `main`.
- [DISCOVERED] Material comes only from `package:material_ui`, never from the SDK copy (docs/DECISIONS.md 0.3).
- [DISCOVERED] Code and docs are in plain English, with comments that explain why. Decisions are recorded in `docs/DECISIONS.md`.
- [DISCOVERED] Widget-test rules: see docs/DECISIONS.md 2.2, Limits. Fake time: never await a cancel or close; never close the memory database in widget tests.
