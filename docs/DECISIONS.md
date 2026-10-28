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

## 2026-10-28 · 0.4 · GitHub repos, CI and the web test site
- **Decision:** the code lives in the private repo `Aseke-quick/shuffle-alarm`. The web test version is published as built files only to the public repo `Aseke-quick/shuffle-alarm-web`, which GitHub Pages serves from its `main` branch at https://aseke-quick.github.io/shuffle-alarm-web/. One workflow in the private repo, `.github/workflows/ci.yml`:
  - Job `check` runs on every push to any branch: `flutter pub get --enforce-lockfile`, `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test`.
  - Job `deploy` runs only on `main`, and only after `check` passed: `flutter build web --release --base-href /shuffle-alarm-web/`, then a force-push of `build/web` as one fresh commit to the site repo. It signs in with the repo secret `SITE_DEPLOY_TOKEN`, a fine-grained token limited to Contents read/write on the site repo.
  - Flutter 3.47.8 stable (`FLUTTER_VERSION` in the workflow), the same as on the Mac. Runner `ubuntu-24.04`, which is what `ubuntu-latest` means today.
  - Every action is pinned to the commit SHA of its latest release, with the version in a comment. Checked on 2026-10-28: `actions/checkout` v7.0.1 (Node 24) and `subosito/flutter-action` v2.23.0 (composite). The publish step uses plain `git`, so it adds no third-party action.
  - Commits use the GitHub no-reply address `199282587+Aseke-quick@users.noreply.github.com` (set in this repo's git config). The 3 commits made before the first push were rewritten to it.
- **Why:** the app is meant to be sold, so its code must not be public. A public repo shows every file and its whole history, so single files cannot be hidden in it. GitHub Pages is free only for public repos, so the built site goes to a second, public repo. Its compiled JavaScript (no Dart code, no source maps) is what every browser downloads from the site anyway, and the project cannot be rebuilt from it. One fresh commit per publish keeps old builds out of the site repo. Turned down: Cloudflare Pages or Firebase Hosting (one more account, service and token), GitHub Pro (paid), and no site until Phase 2. Deploying only after `check` keeps a broken build off the site. A commit SHA, unlike a tag, cannot be moved to other code. Web URLs use hash routing (`/#/alarms`), so deep links work on GitHub Pages without a 404.html fallback.
- **Limits / follow-up:**
  - The code repo was public for about an hour on 2026-10-28; it then held only the app shell and the docs.
  - Anyone with the link can open, and copy, the web test version. Before it does real alarms (Phase 2), decide who gets the link.
  - `SITE_DEPLOY_TOKEN` expires (set to one year, until about 2027-10-28). Then create a new token the same way and replace the secret; until then the `deploy` job fails with a clear error.
  - If the site repo is made private, GitHub Free takes the site down and deletes its Pages setting (seen on 2026-10-28). If the site repo is renamed, change `--base-href` and `SITE_REPO` in `ci.yml`.
  - The private repo uses the monthly free Actions minutes of GitHub Free (2,000 at the time of writing); a push to `main` takes about 3 minutes.
  - When Flutter is upgraded on the Mac, change `FLUTTER_VERSION` in the same commit. To update an action, replace both the SHA and the version comment. GitHub Pages limits: 1 GB per site and a soft limit of 100 GB traffic a month.

## 2026-10-28 · 1.1 · Core models
- **Decision:** the models live in `lib/core/models/`, one file each: `ClockTime`, `Alarm`, `Sound`, `RingEvent` and `RingSession`.
  - A `RingSession` is one time an alarm goes off, such as Tuesday's 07:00 alarm: every sound it played, from the first one until Stop, including the rings after each Snooze. Its `scheduledFor` time stays the same through the snoozes.
  - A `RingEvent` is one sound that played. Its `action` says how that sound ended: `stop` or `snooze` (the user tapped it), or `timeout` (its time ran out and the next sound started). When the alarm is over, a last event of `timeout` means the alarm reached its time cap: a missed alarm.
  - Every model has a `String` id. Built-in sounds keep their id from `manifest.json`; the data layer (task 2.1) creates the others.
  - Repeat days are `DateTime.weekday` numbers, 1 (Monday) to 7 (Sunday). No repeat days: the alarm rings once.
  - `ExperimentGroup` holds the two conditions of task 7.3, `sameSound` and `rotation`; an alarm outside experiment mode has none. `gentleStart` is on by default, as task 7.1 asks.
  - Constructors throw an `ArgumentError` for values that cannot be right: an hour outside 0–23, a minute outside 0–59, a repeat day outside 1–7, an intensity outside 1–3, a file without length, a clip start outside the file. `RingEvent` and `RingSession` check nothing.
  - Models are immutable and equal when all their values are equal. `meta` is now a direct dependency for its `@immutable` annotation: the lint rule `avoid_equals_and_hash_code_on_mutable_classes` allows `==` only on classes marked with it. Checked on pub.dev on 2026-10-28: published by dart.dev, BSD-3-Clause, all 6 platforms, 150/160 pub points, latest 1.19.0 (2026-07-09). Flutter itself depends on `meta ^1.18.3`, so the locked version stays 1.18.3.
- **Why:**
  - One session per alarm occurrence gives Insights (task 2.8) and the experiment export (task 7.4, one row per morning) their rows directly. Turned down: one session per ring, which would have to group the rings of one morning again.
  - One event per sound gives adaptive weights (task 1.5) the sound that played at each Stop and Snooze, and Insights the number of sounds played.
  - String ids, because sound ids from `manifest.json` are strings, and one id type keeps the data layer simple. If an Android alarm API needs int ids (task 4.1), the Android scheduler maps them.
  - Ring logs are written while an alarm rings. The device clock can jump back during a ring, so an event may end before it starts, and a check that throws there could stop the alarm.
- **Limits / follow-up:**
  - Task 1.6 decides what an alarm without genres plays. Tasks 2.1 and 2.3 add where a sound's audio lives (asset, file or browser storage).
  - Store the enums by name, not by index (task 2.1), so a new enum value never changes stored rows.
  - An alarm's `experimentGroup` changes during an experiment, so task 7.3 may need to copy it into each `RingSession`.
