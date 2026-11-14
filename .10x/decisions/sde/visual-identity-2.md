# SDE notes: visual-identity-2 (ADR-005)

- **Glass without blur:** a `GlassCard` is a translucent fill with a hairline over the `Backdrop`'s gradients. No `BackdropFilter`: nothing moves behind a card, and a blur costs frames in CanvasKit.
- **Contrast:** `test/design/contrast_test.dart` blends each color field into the page and each glass fill over that, and checks every text and control pair on the darkest and the lightest result. The light marks `gentle`, `medium` and `strong` were darkened for it.
- **Strength colors on cards:** the deck and the calendar use fixed fills (`WakemixColors.gentleFill` and so on) with one ink (`onStrength`), the same in both themes, so a card reads the same in light and dark.
- **TimeWheels:** `ListWheelScrollView` with a looping delegate. A `_syncing` flag keeps the wheels' own jump to a new time from reporting a change; `_reported` holds the last time reported until the parent rebuilds, so quick changes add up.
- **SoundDeck:** cards are keyed by sound id in a `Stack` of `AnimatedPositioned`, so Reshuffle animates for free. Below `minStep` of visible width per card it is a horizontal `ListView`.
- **Analytics refresh:** `analyticsProvider` watches the ringing state, the snoozes and the Morning card, and the shell invalidates it when its tab is tapped. The log is small, so it reads everything.
- **Test rule of thumb:** on the Alarms tab a `MixBars` is always there, so a test that waits for the ringing page waits for the text "Stop".
