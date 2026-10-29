# Engineering manager — Wakemix redesign (2026-10-29)

## Work streams
| Stream | Who | Branch | Size |
| --- | --- | --- | --- |
| 2.2a Wakemix look, name and sleep calculator | Agent A, its own worktree | `wakemix/2-2a-design` | about one long session |
| 2.3 Placeholder library and syncing it into the database | Agent B, its own worktree | `wakemix/2-3-library` | about one session |
| QA review of each branch, the user's yes, the merge, the push, CI, the live check | the lead session | `main` | per branch |

## Sequence
1. A and B run in parallel. Whichever finishes first is reviewed and merged first. The other one then merges the new `main` into its branch, or the lead does it at merge time.
2. Then, in order: 2.4, 2.4a, 2.5, 2.5a, 2.5b, then the rest of `PLAN.md`.

## Risks
- **Conflicts in shared files** (`pubspec.yaml`, `PLAN.md`, `docs/DECISIONS.md`). Each agent owns certain files (see the spec), and the lead joins the docs by hand.
- **The user's attention.** Each agent asks the user only about new questions, in simple Russian.
- **Claude usage** is about twice as high while both run.
