# Security — index

- [DISCOVERED] No accounts and no server. User songs and voice recordings must stay on the device (`CLAUDE.md`).
- [DISCOVERED] CI publishes only `build/web` to the public site repo, with a fine-grained token limited to that repo. The source stays private (docs/DECISIONS.md 0.4).
- At start, the web test version asks only its own host: bundled fonts, CanvasKit from the site, and clips from the app's assets (since 2026-10-29). Keep it that way. A new request to another host at run time needs an entry in docs/DECISIONS.md.
- Check the public site repo by its file list after a deploy change: no `.dart` file, no source map, no docs. On 2026-10-30 it held 77 files, all build output.

## Features
| Slug | Review | Status |
| --- | --- | --- |
| `visual-identity` | `reviews/2026-10-30-2.2a-2.3-security.md` | Pass. Low: a glyph the fonts lack loads a Noto font from Google |
| `placeholder-library` | `reviews/2026-10-30-2.2a-2.3-security.md` | Pass |
