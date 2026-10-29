# CTO — Wakemix redesign (2026-10-29)

- **Problem.** A public project follows our `PLAN.md` word for word, under the same name. Its features and its name are ours, and its look is already more distinct. For an app that will be sold, that leaves us nothing that tells the two apart.
- **Verdict: build.** Three things of our own: a look (Mixtape: cobalt, Unbounded with Geist, record, tracklist, dial), a name (Wakemix), and features (sleep calculator, Tonight's mix, Morning card, bedtime reminder).
  - Not buy: no UI kit or template gives a look of our own (ADR-001).
- **Tech direction.**
  - The same stack.
  - Our own design system in `lib/design/`, on Material 3 from `material_ui`.
  - Fonts bundled under the OFL.
  - No new runtime packages unless a task shows the need, and then checked on pub.dev as `CLAUDE.md` says.
- **Opportunity cost.** One task (2.2a) before the scheduler and ringing. Task 2.3 runs in parallel, so the alarm loses about one task's worth of time.
- **Success.**
  - A tester can tell Wakemix from the other app at a glance.
  - Every text meets WCAG AA.
  - Reliability stays the same: the alarm's tests and rules do not change.
