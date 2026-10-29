# Senior engineer — visual-identity, task 2.2a (2026-10-29)

## Approach
1. **Tests first for `lib/core/bedtime.dart`.**
   - `bedtimeFor(DateTime ring, {Duration goal = const Duration(hours: 8)})` returns the moment `ring - goal`.
   - Before that time, the text is "Bed by …"; after it, "Sleep now: …", the time until the ring rounded down to whole minutes.
   - Run the DST zones too: `TZ=Europe/Berlin` and `America/New_York`.
2. **Tokens and theme**, with the contrast test.
   - WCAG relative luminance and contrast ratio, worked out in the test.
   - Every text and background pair: 4.5:1, or 3:1 for large text and for non-text parts.
3. **Fonts:**
   - download the OFL variable TTFs of Unbounded, Geist and Geist Mono from their official sources (Google Fonts, or Vercel's Geist repo), with the `OFL.txt` files;
   - write in docs/DECISIONS.md where each came from and its SHA-256, as task 2.1 did for the web files;
   - register them in `pubspec.yaml` and with `LicenseRegistry`;
   - set `fontVariations` for `wght` as well as `fontWeight`;
   - measure the web download.
4. **Components,** one at a time, each with widget tests.
   - **Rotary dial:**
     - the angle from 12 o'clock gives the minute, `(angle / 2π · 60)`, snapped to 1 minute;
     - crossing 12 o'clock clockwise adds an hour, and counter-clockwise subtracts one;
     - keyboard: arrows ±1 min, Page Up/Down ±1 h;
     - `Semantics` with value, increase and decrease;
     - a tap on the time opens `showTimePicker` in input mode;
     - a haptic tick every 5 minutes on mobile (`HapticFeedback.selectionClick`).
   - **Mini waveform:** points from a seeded `Random(alarm.id.hashCode)`. The waveform is decorative, so a stable but changeable hash does no harm.
5. **Screens:** Alarms tab and editor, then the placeholders. Keep the behavior of task 2.2 and its tests, with the texts updated.
6. **Name** (spec section 2), and the two new architecture-test rules (ADR-001).
7. **Checks:** 2.0 text scale on 360 × 740, less motion, the web check in headless Chrome (screenshots, console), format, analyze, test, DST runs.

## Tricky parts
- **Variable fonts on the web** need `fontVariations`.
- **Drag precision on the dial,** near the center and when crossing 12.
- **Widget tests run on fake time** (docs/DECISIONS.md 2.2, Limits).
- **The Claude browser pane** cannot open the database, so check the web in headless Chrome (`cdp.dart` in the shared notes folder).
