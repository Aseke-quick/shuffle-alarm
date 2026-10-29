# QA — index

- [DISCOVERED] Quality gates: `dart format`, `flutter analyze` with 0 issues, `flutter test`, and the DST step in CI. For core logic, a mutation check: deliberate bugs on a copy of the code must each fail a test. Web screens are checked in headless Chrome with a fresh profile, because the Claude browser pane cannot open the database.
