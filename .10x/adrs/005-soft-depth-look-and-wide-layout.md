# ADR-005: The "Soft depth" look, a wide layout, time wheels and the sound deck

**Status:** Accepted
**Date:** 2026-11-14
**Feature:** visual-identity-2
**Author:** 10x-Team (Architect + Staff Engineer)

(ADR-004 is taken by task 2.6, which is not on `main` yet.)

## Context
The user rejected the look of ADR-001 ("Mixtape") and four more directions, and approved one: soft colour fields behind the page, glass cards, a cream accent, Geist only, a real wide layout on a laptop, time wheels, a deck of sound cards, and Analytics in the place of Insights (`.10x/specs/2026-11-14-wakemix-redesign-2-design.md`).

Constraints:
- The structure of ADR-001 holds: every colour in `lib/design/tokens.dart`, components in `lib/design/` that take plain values, features that take colours and text styles from the theme, and the two rules in `test/architecture_test.dart`.
- The ringing code must not change. Web first, CanvasKit, also on phones.
- WCAG AA contrast, keyboard and screen-reader use, less motion.

## Decision
- **Tokens:** `WakemixColors` gets the new palette and new roles: `glass` and `glassLine` for cards, `gentle`, `medium` and `strong` for the three strengths, and the three colour fields. `lib/design/` stays the only place with colour values.
- **Fonts:** Geist only. `WakemixFonts.display` and `.meta` point at Geist, so the callers stay. Unbounded and Geist Mono leave the bundle with their licenses.
- **Backdrop:** a `Backdrop` widget paints the page colour and the colour fields as radial gradients, once per page, behind a transparent `Scaffold`. No blur filter and no `BackdropFilter`: gradients cost nothing per frame, and glass is a translucent fill with a hairline.
- **Wide layout:** `Layout.isWide(context)` is true from 1000 px. The shell shows a top bar with the tabs then, and the bottom bar below that width. Pages lay out one or two columns from the same widgets.
- **Components replaced:** the record hero, the spinning record and the rotary dial go. New: `NextAlarmCard`, `MixBars`, `GlassCard`, `TimeWheels`, `SoundDeck`, `MonthCalendar`, `BarChart`. `TimeWheels` keeps the contract of the dial: `time`, `onChanged`, "Type the time", one adjustable value "Alarm time" for screen readers.
- **Analytics:** pure logic in `lib/core/analytics.dart` over `RingSession` and `MorningAnswer`; the screen reads `RingSessionRepository.all()` and `MorningAnswerRepository.all()`. No schema change.

## Alternatives considered
| Alternative | Pros | Cons | Why not |
|-------------|------|------|---------|
| Keep ADR-001's components and only change the tokens | Least work, tests stay | Still a record, a dial and a narrow column: what the user rejected | Does not meet the goal |
| Real glass with `BackdropFilter` | Truer glass over moving content | Costly on phones and in CanvasKit; nothing moves behind the cards | No visible gain |
| A new font pair | More character | A second download; the serif was rejected | Geist is already bundled and was accepted |
| A separate desktop app shell with its own pages | Freedom per form factor | Two sets of screens to keep in step | One set of widgets in one or two columns is enough |
| A new table of daily totals for Analytics | Fast reads | A migration, and totals that can disagree with the log | The log is small (30 ms for two years, measured 2026-11-13) |

## Consequences

### Positive
- One look the user chose from pictures; the web version reads as a site on a laptop.
- Fewer fonts: a smaller first download.
- The ringing path is untouched.

### Negative
- Nearly every screen and many widget tests change in one go.
- Three custom components with gestures to maintain: the wheels, the deck, the calendar.

### Risks
- Wheels and a deck can be hard with a keyboard or a screen reader. Mitigation: the wheels are one adjustable value with typing; every card and its actions are buttons.
- Text on glass over colour fields can lose contrast. Mitigation: the contrast test covers the lightest and darkest a card can be.
- Task 2.6 changes `lib/design/theme.dart`, `layout.dart` and the Library screen in its worktree. Mitigation: it rebases onto this ADR; its hand-over says so.

## Dependencies
- ADR-001 for the structure of `lib/design/`; this ADR replaces its look.
- ADR-002 (stored ring plan) and ADR-003 (morning answer): the deck and Analytics read what they store.
- Task 2.8 is done by the Analytics tab.
