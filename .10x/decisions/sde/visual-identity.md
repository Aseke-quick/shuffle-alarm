# SDE — visual-identity, task 2.2a (2026-10-29)

Agent A of spec section 4. Branch `claude/2-2a-wakemix-design-3e0318`. The details and the reasons are in docs/DECISIONS.md, entry "2.2a · The Wakemix look, its name and the sleep calculator".

## What was built
- **`lib/design/`**, which imports only Flutter and `material_ui`:
  - `tokens.dart`: `WakemixColors` (the spec's colors, as a `ThemeExtension`), `Space`, `Corners`, `Motion` (with `reduceMotion`, `of` and `styleOf`), `TypeScale` and `Layout`.
  - `theme.dart`: `WakemixTheme.dark` / `.light` and `WakemixType` (Geist Mono `meta` and `caption`).
  - `fonts.dart` and `font_licenses.dart`: the families, `WakemixFonts.style` / `.weighted` (`fontWeight` plus the `wght` axis), and `registerFontLicenses()`.
  - `components/`: `record.dart` (`RecordArt`, `RecordHero`), `alarm_track_row.dart`, `mini_waveform.dart`, `rotary_time_dial.dart`, `day_keys.dart`, `wide_button.dart`, `layout.dart` (`ContentWidth`, `ContentAppBar`, `BottomAction`), `section_label.dart`, `nav_bar.dart`, `status_view.dart`, `time_text.dart`, `wordmark.dart`, `enter_motion.dart`.
- **Fonts** in `assets/fonts/`:
  - Unbounded and Geist Mono are cut down to Latin; Geist is whole.
  - 401 KB for all three, about 212 KB gzipped on GitHub Pages.
- **`lib/core/bedtime.dart`**: `bedtimeFor`, `sleepAdvice`, and `BedBy` / `SleepNow`, with tests written first, the zones with daylight saving time included.
- **Screens**:
  - the Alarms tab, with the record of the next alarm, the bedtime line, "ALL ALARMS" and the New alarm button;
  - the editor, with the dial, "Rings in", the bedtime line, day keys, the label, genres and Save alarm;
  - Library, Insights and Settings as placeholders;
  - the shell with `WakemixNavBar`;
  - pages above the tabs without a transition when less motion is asked for.
- **Name**: Wakemix, in the app title, `web/index.html`, `web/manifest.json`, the `pubspec.yaml` description, `README.md`, `CLAUDE.md` and `PLAN.md`.
- **Tests**: 113 new, 326 in all (8 of them for daylight saving time).
  - `test/design/**`: the contrast rule, fonts, theme, and each component.
  - `test/features/motion_test.dart` and `text_scale_test.dart`.
  - The 2.2 tests, updated.
  - The two ADR-001 rules in `test/architecture_test.dart`.
  - 13 deliberate bugs were each caught.

## Deviations from the spec, the ADR and the file list
- **Branch**: the worktree's own branch, not `wakemix/2-2a-design`.
- **Files outside agent A's list**, all one-purpose and none of agent B's:
  - `.github/workflows/ci.yml`: the DST step also runs `test/core/bedtime_test.dart`, else CI (UTC) skips its DST tests.
  - `CLAUDE.md`: the matching command line.
  - `test/architecture_test.dart`: the ADR's rules, as the task asked.
- **`pubspec.yaml`**: a fourth font family, `Roboto`, maps to Geist, so Flutter's web engine does not fetch Roboto from Google.
- **License texts**: kept as Dart constants that a test compares with `OFL.txt`, instead of assets read at runtime. That would have needed an `assets:` entry, which is agent B's part of `pubspec.yaml`.
- **Where the colors live**: `WakemixColors` (the `ThemeExtension`) is in `tokens.dart`, and `WakemixType` in `theme.dart`.
- **Colors**: no color token was tuned; all pass. Material's `outline` role is `textMuted`, so the borders of fields, switches and outlined buttons meet 3:1.
- **Small things the spec leaves open**:
  - the day keys show "Mon"…"Sun", and the editor gives them 12 px margins for 48-dp targets;
  - the "LABEL" caption is left out, because the field has its own label;
  - the Delete dialog says "It will not ring again.";
  - the bedtime shows its day when it is not today;
  - "Sleep now: under 1 min";
  - "TAP TO TYPE" under the dial's time;
  - the record is not tappable until 2.5a.

## Tech debt and follow-ups
- **Switch under less motion**: the switch thumb still slides for 200 ms, because Material's `Switch` has no way to turn it off. A switch of our own in `lib/design/` would stop it.
- **CanvasKit**: the web build loads it from `www.gstatic.com`. `flutter build web --no-web-resources-cdn` in the deploy job would serve it from the site. That is the lead's call, in `ci.yml`.
- **Missing glyphs on the web**: glyphs no bundled font has (CJK, Arabic, emoji) still come from Google's Noto fonts.
- **Tab semantics**: the tab bar tells screen readers "button, selected". Flutter's tab roles (`SemanticsRole.tab`) could say "tab, 1 of 3".
- **Rounding**: in the first minute after the app opens, "Rings in" (rounded up) and "Sleep now" (rounded down) can differ by one minute.
- **No golden tests yet**: the screenshots were checked by eye in headless Chrome.
