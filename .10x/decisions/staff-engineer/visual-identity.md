# Staff engineer — visual-identity (2026-10-29)

## Patterns
- Colors come from `Theme.of(context).colorScheme` and the Wakemix `ThemeExtension`, never from hex values in features. Text styles come from `theme.textTheme`, defined from the token scale.
- A new widget that paints itself carries `Semantics`. Any value it shows also works from the keyboard.
- Motion goes through the duration tokens, and stops when `MediaQuery.disableAnimationsOf(context)` is true.
- Keep the rules of `CLAUDE.md` and docs/DECISIONS.md:
  - `material_ui` imports only;
  - English UI;
  - comments that explain why;
  - very_good_analysis with 0 issues.

## Cross-cutting
- **Accessibility:** contrast tests, a 2.0 text scale, screen-reader labels and keyboard use.
- **Wide screens:** at most 560 dp of content.

## Reuse
- From task 2.2: `nextRing`, `ringsIn`, `repeatText`, `dayName`, `genreName`, `saveAlarm`/`deleteAlarm` and `DatabaseErrorView` (restyle it, keep its texts).
- The test helper `openAlarms` and `TestClock`.
