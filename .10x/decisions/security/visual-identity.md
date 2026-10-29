# Security: visual-identity (task 2.2a)

- **Review:** `reviews/2026-10-30-2.2a-2.3-security.md`. Pass.
- **Decisions:**
  - The fonts are bundled and never fetched. The three OFL files are in `assets/fonts/`, pinned by SHA-256 (docs/DECISIONS.md 2.2a). The `Roboto` → Geist entry in `pubspec.yaml` stops the web engine's own Roboto request.
  - CanvasKit comes from the site itself (`--no-web-resources-cdn`, docs/DECISIONS.md 0.4 of 2026-10-29).
  - So at start the web test version asks no host but its own.
- **Open:**
  - Low 1 of the review: a glyph the fonts lack loads a Noto font from Google.
  - Info 2: a CSP meta tag would make "own host only" a rule.
