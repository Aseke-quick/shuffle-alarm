# SRE — index

- [DISCOVERED] Alarm reliability comes first: any change to scheduling or ringing must pass the alarm test checklist (`PLAN.md` 4.5). On the web, armed alarms ring since 2.4, with Snooze and a log since 2.5.
- On the web, a ring does not need the network or a finished library sync (`placeholder-library.md`, both risks closed by 2.4 and 2.5).
- A ring only reads its stored plan, with a limit of 2 s, and any failure means no plan (2.5a, ADR-002). Nothing about a plan is written while a ring starts. A sound must not start after a Stop that came while its file loaded (`WebSoundPlayer._request`).

## Features
| Slug | Note | Status |
| --- | --- | --- |
| `visual-identity` | The site depends only on GitHub Pages; first visit 3.3 MB | Live since 2026-10-29 |
| `placeholder-library` | Failure modes at start, and two risks for the first ring | Live since 2026-10-29 |
