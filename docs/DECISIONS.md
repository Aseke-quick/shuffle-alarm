# Decisions and limits

Technical decisions and platform limits, oldest first. Product decisions are in the Decisions table in `PLAN.md`; known platform pitfalls are under Gotchas in `CLAUDE.md`.

Add an entry when a task makes a choice that the code does not explain by itself, or runs into a platform limit. Use this format:

```markdown
## YYYY-MM-DD · <task ID> · <short title>
- **Decision:** what we chose.
- **Why:** the reason, and the options we turned down.
- **Limits / follow-up:** what it blocks, or when to look at it again (optional).
```

## 2026-10-27 · 0.1 · Flutter version and app IDs
- **Decision:** Flutter 3.47.8 stable (Dart 3.13.7). App IDs from `flutter create --org com.asanali`: `com.asanali.shuffle_alarm` on Android and Linux, `com.asanali.shuffleAlarm` on iOS and macOS.
- **Why:** the `flutter create` defaults for the working title.
- **Limits / follow-up:** an app ID cannot change after the first upload to Google Play or App Store Connect. If the app gets its final name, change the IDs before tasks 8.3 and 8.4.

## 2026-10-28 · 0.2 · Lint rules: very_good_analysis
- **Decision:** `very_good_analysis` 11.0.0 replaces `flutter_lints`. It turns on 214 lint rules plus the `strict-casts`, `strict-inference` and `strict-raw-types` analyzer modes. Two rules are off in `analysis_options.yaml`:
  - `public_member_api_docs` wants a doc comment on every public member. That is meant for published packages; this is an app. Very Good Ventures' own app template (`very_good_core`) turns it off too.
  - `unnecessary_type_name_in_constructor` rewrites `const HomePage({super.key})` into the new Dart 3.13 form `const new({super.key})`. We keep the classic form used in Flutter docs and samples.
- **Why:** stricter checks catch more bugs before the app runs (unsafe casts, futures that are never awaited, dynamic calls), and alarm reliability comes first. Checked on pub.dev on 2026-10-28: version 11.0.0, published 2026-09-03 by verygood.ventures, MIT license, 160/160 pub points, needs Dart ^3.13. It is a dev dependency only, so platform support does not apply.
- **Limits / follow-up:** a new minor version can add rules, so `flutter pub upgrade` may bring new `flutter analyze` issues; fix them in the same commit. Turn `unnecessary_type_name_in_constructor` back on once Flutter's own templates use the new form; `dart fix --apply` then rewrites every constructor.

## 2026-10-28 · 0.2 · Folder structure and layer test
- **Decision:** every folder from the Architecture section of `CLAUDE.md` exists from the start. Empty folders hold a `.gitkeep`, because git does not store empty folders; it can go once the folder has a real file. Folders under `test/` are created with their first test and mirror `lib/`. `test/architecture_test.dart` enforces two rules:
  - `lib/core/` imports no Flutter (`package:flutter*`, `dart:ui`) and no other part of the app.
  - `lib/features/` imports nothing from `lib/platform/{android,ios,desktop,web}/`; features use the interfaces in `lib/platform/`.
- **Why:** an automatic check keeps these rules true in every task, also after `/clear`. Core imports only core, so it stays plain Dart: it runs on all 6 platforms and its tests stay fast.

## 2026-10-28 · 0.3 · Navigation and state: go_router and flutter_riverpod
- **Decision:** `go_router` for navigation and `flutter_riverpod` for state, as planned in `CLAUDE.md`. The router is built inside a Riverpod provider (`routerProvider` in `lib/router.dart`), so every `ProviderScope`, and with it every widget test, gets a fresh router. Providers are written by hand, without `riverpod_generator` code generation. The three tabs are a `StatefulShellRoute.indexedStack`, so each tab keeps its own pages and state. Settings is a route outside the tabs, opened with `push` from the gear in each tab's app bar.
- **Why:** checked on pub.dev on 2026-10-28:
  - `go_router` 18.1.1: published 2026-10-20 by flutter.dev, BSD-3-Clause, Flutter Favorite, all 6 platforms, 150/160 pub points.
  - `flutter_riverpod` 3.4.3: published 2026-09-03 by dash-overflow.net (the Riverpod author), MIT, 140/160 pub points. pub.dev lists 5 of 6 platforms, without Web, because the package imports `flutter_test` for its `tester.container()` test helper, and `flutter_test` imports `dart:io`. Flutter web builds accept that import: `flutter build web --release` passes (its Wasm dry run too), the app works in Chrome, and no `flutter_test` code ends up in `main.dart.js`. The core package `riverpod` 3.4.3 lists all 6 platforms.
- **Limits / follow-up:** `push` does not change the browser URL (go_router default), so on web the address bar keeps the tab's address while Settings is open. If a Flutter update ever breaks the web build on that `dart:io` import, CI (task 0.4) shows it on the next push.

## 2026-10-28 · 0.3 · Material from the material_ui package
- **Decision:** app code imports Material from `package:material_ui/material_ui.dart` (package `material_ui` 1.8.0), never from `package:flutter/material.dart`. Cupertino, if we need it, comes from the `cupertino_ui` package the same way. `test/architecture_test.dart` fails if a file in `lib/` imports the SDK versions, and it counts both packages as Flutter for the `lib/core/` rule.
- **Why:** Flutter 3.47 moved Material and Cupertino out of the SDK into the `material_ui` and `cupertino_ui` packages (flutter.dev, BSD-3-Clause, all 6 platforms, 160/160 pub points; `material_ui` 1.8.0 published 2026-10-20). The SDK still ships its old copy, which the `flutter create` template uses, but its `MaterialApp`, `Theme` and other classes are different types from the package's. go_router 18 only recognizes the package's `MaterialApp`; with the SDK copy it silently falls back to pages without Material transitions, and widgets from one copy do not see the theme of the other. go_router 17.5, the last version on the SDK copy, was turned down: it is an older major version without the 18.x fixes for tab routes, and the move would only come later.
- **Limits / follow-up:** widgets from a package that still uses `package:flutter/material.dart` need a `MaterialUiCompatibilityBridge` around them (see the `material_ui` README). The SDK's `dart fix --apply --code=migrate_design_widgets` does this move for existing code.

## 2026-10-28 · 0.4 · GitHub repo, CI and web hosting
- **Decision:** public repo `Aseke-quick/shuffle-alarm`; the web test version is on GitHub Pages at https://aseke-quick.github.io/shuffle-alarm/. One workflow, `.github/workflows/ci.yml`:
  - Job `check` runs on every push to any branch: `flutter pub get --enforce-lockfile`, `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test`.
  - Job `deploy` runs only on `main`, and only after `check` passed: `flutter build web --release`, then GitHub's Pages actions publish `build/web` (repo Settings → Pages → Source: GitHub Actions). The base href comes from `actions/configure-pages` (`/shuffle-alarm`), so a repo rename or a custom domain does not break the site.
  - Flutter 3.47.8 stable (`FLUTTER_VERSION` in the workflow), the same as on the Mac. Runner `ubuntu-24.04`, which is what `ubuntu-latest` means today.
  - Every action is pinned to the commit SHA of its latest release, with the version in a comment. Checked on 2026-10-28: `actions/checkout` v7.0.1, `subosito/flutter-action` v2.23.0, `actions/configure-pages` v6.0.0, `actions/upload-pages-artifact` v5.0.0, `actions/deploy-pages` v5.0.1. All of them run on Node 24 or are composite actions.
  - Commits use the GitHub no-reply address `199282587+Aseke-quick@users.noreply.github.com` (set in this repo's git config). The 3 commits made before the first push were rewritten to it, so no personal email is public.
- **Why:** GitHub Pages is free for public repos and needs no extra account or API token, and Actions minutes on GitHub's runners are free for public repos. A private repo would need Cloudflare Pages or Firebase Hosting plus a token secret (GitHub Pages for private repos needs a paid plan), and its Actions minutes have a monthly limit. Nothing in the repo is secret, and user audio is never committed. A commit SHA, unlike a tag, cannot be moved to other code. Deploying only after `check` keeps a broken build off the live site. Web URLs use hash routing (`/#/alarms`), so deep links work on GitHub Pages without a 404.html fallback.
- **Limits / follow-up:** anyone with the link can open the test version. When Flutter is upgraded on the Mac, change `FLUTTER_VERSION` in the same commit. To update an action, replace both the SHA and the version comment. GitHub Pages limits: 1 GB per site and a soft limit of 100 GB traffic a month. Making the repo private, even for a minute, takes the site down and deletes the Pages setting (tried on 2026-10-28). After making it public again, set Settings → Pages → Source back to GitHub Actions and rerun the workflow on `main` from the Actions tab.
