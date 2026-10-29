# QA — visual-identity, task 2.2a (2026-10-29)

- **Gate result:** pass after two medium fixes on the merge branch (`049c165`), each with a test that failed first. Report: `.10x/reviews/2026-10-29-2.2a-qa.md`. Merged into `main` as `70fb5bf`.
- **Bugs found:**
  - A selected chip's label was the plain text color on the accent (2.88:1 dark). The token test could not see it: the tokens were right, the theme paired them wrongly. Lesson: test what a themed widget draws, not only the token pairs.
  - The dial's own gesture recognizer stayed "accepted" when the arena gave it a pointer after a tap had ended, so its next drag lost to a list. Lesson: a custom recognizer must ignore `acceptGesture` for a pointer it no longer tracks.
- **How it was tested:** the whole suite, format, analyze and the DST runs; contrast worked out again for every pair; touch targets and screen-reader roles read from the semantics DOM in headless Chrome; screens in dark and light at 390 × 844 and 1280 × 800.
- **Known and accepted:** the switch thumb moves with less motion; unselected chips and day keys differ from the page by their fill only; Noto fonts for missing glyphs on the web; tabs read as buttons.
