# DevOps — index

- [DISCOVERED] `.github/workflows/ci.yml`:
  - job `check` on every push: format, analyze, test, and the DST tests in Europe/Berlin and America/New_York;
  - job `deploy` on `main` only: builds the web app and publishes `build/web` to `Aseke-quick/shuffle-alarm-web` (GitHub Pages).
  - Since 2026-10-29 the deploy build uses `--no-web-resources-cdn`, so the site serves CanvasKit itself and makes no request to Google at start (docs/DECISIONS.md, 0.4 of that day).
  Actions are pinned by SHA (docs/DECISIONS.md 0.4).
