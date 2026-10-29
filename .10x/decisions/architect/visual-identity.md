# Architect — visual-identity (2026-10-29)

See ADR-001.

## Layers
`lib/design/` is a UI kit. Features depend on it, and it depends on Flutter and `material_ui` only.
- Its files:
  - `tokens.dart` and `theme.dart` (with the `ThemeExtension`);
  - `fonts.dart` (license registration);
  - `components/`, one file per component.
- The sleep calculator's logic is in `lib/core/bedtime.dart` (pure Dart).

## Data flow
1. `alarmsProvider` and `clockProvider` give the feature its alarms and the time.
2. The feature works out `nextRing` and `bedtimeFor`.
3. The feature builds the design components with plain values: time text, subtitle, segment count, state.

## Failure modes
- The database fails: the error state of 2.2, restyled.
- A font fails to load: Flutter falls back to the platform font, and layouts must not depend on exact glyph widths.
- No enabled alarm: an empty record and the New alarm button.
