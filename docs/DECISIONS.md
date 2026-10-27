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
