# ADR-001: The Wakemix design system in `lib/design/`

**Status:** Accepted
**Date:** 2026-10-29
**Feature:** visual-identity
**Author:** 10x-Team (Architect + Staff Engineer)

## Context
The app uses Flutter's default Material 3 look, from a deep orange seed color, so it looks like any other Material app. Another public project follows the same `PLAN.md` and already has a look of its own. We need one of our own, set out in `.10x/specs/2026-10-29-wakemix-redesign-design.md`.

Constraints:
- 6 platforms, with the web first.
- Material comes only from `package:material_ui` (docs/DECISIONS.md 0.3).
- Local-first: no font downloads.
- WCAG AA contrast.
- Features never hard-code colors.
- Screens stay testable with widget tests.

## Decision
A design layer in `lib/design/`.
- **Tokens:** colors for dark and light, spacing, corner radii, durations and the type scale, in one file. These are the only color values in `lib/`.
- **Theme:** `WakemixTheme` builds the dark and light `ThemeData` (Material 3) from the tokens. It carries the colors Material lacks (`textMuted`, `textDisabled`, `accentText`, ...) as a `ThemeExtension`. The app uses `ThemeMode.system`, and dark is the reference.
- **Fonts:** Unbounded, Geist and Geist Mono, bundled in `assets/fonts/` with their OFL texts and registered with `LicenseRegistry`.
- **Components:**
  - presentational widgets with no Riverpod and no database: they take plain values;
  - `RecordHero` and `RotaryTimeDial`, as `CustomPainter`s with gestures, keyboard handling and `Semantics`;
  - `MiniWaveform`, `DayKeys`, `WideButton`, the navigation bar, and the empty and error states.
- **Features** work out the values (`nextRing`, bedtime, labels) and hand them to the components.
- **Guards:** `test/architecture_test.dart` gains two rules. `lib/design/` imports nothing from `lib/data/` or `lib/features/`. `lib/features/` has no `Color(0x…)` literals.

## Alternatives considered
| Alternative | Pros | Cons | Why not |
|-------------|------|------|---------|
| Tweak the seed-based Material theme | Least work | Still generic; nothing like the record or dial | Does not meet the goal |
| A third-party UI kit (for example forui or shadcn_ui for Flutter) | Ready-made polished widgets | Their look, not ours; one more dependency on 6 platforms; fights `material_ui` | Not distinct, more risk |
| Widgets of our own, without Material | Full control | Re-doing text input, dialogs, focus and accessibility | Too much risk for alarm reliability |

## Consequences

### Positive
- One place for every visual decision. Contrast is tested, and screens stay simple.
- Signature elements of our own: the record and the dial.

### Negative
- More custom painting code to maintain.
- The fonts make the first web download bigger.

### Risks
- Custom-painted controls can be hard to use with a screen reader or a keyboard. Mitigation: `Semantics` with an adjustable value, keyboard handling, and the dial's tap-to-type.
- Variable fonts on some platforms ignore `FontWeight` unless `fontVariations` sets the `wght` axis. Mitigation: the theme sets both; test on the web.
- Web download size. Mitigation: measure it, and use static weights or subsets if it is over about 600 KB.

## Dependencies
- `material_ui`.
- The core logic: `nextRing`, and the new `bedtimeFor`.
- Tasks 2.5 (ringing screen), 2.5a and 2.5b build on these components.
