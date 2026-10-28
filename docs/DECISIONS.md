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

## 2026-10-28 · 1.2 · Clip rule
- **Decision:** the clip rule lives in `lib/core/clip_rule.dart` as `ClipWindow`: the part of a sound's file that plays when the sound rings. `ClipWindow.of(sound)` is the only way to get one. A window starts at the sound's `clipStart` and ends after 30 s (`ClipWindow.maxLength`), after 29 s for a built-in sound (`ClipWindow.maxBuiltinLength`), or at the end of the file if that comes first.
  - A longer file is cut, not rejected: a built-in file of 29.5 s plays its first 29 s, and a voice message of 30.4 s (a recorder that stopped late) plays 30 s.
  - A shorter file plays whole, such as a 12-s voice message, and the next sound starts right after it.
- **Why:** the constructor is private, so no code can make a window longer than its limit. Turned down: a `Sound` constructor that throws for a built-in file over 29 s. One wrong file would then break loading the library, and could keep an alarm from ringing; alarm reliability comes first. The limits live in one place, so the player (task 2.5), the song import (2.6), the voice recorder (2.7) and the license check (3.5) use the same numbers.
- **Limits / follow-up:** on iOS, AlarmKit gets the sound file itself and cannot play just a part of it, so each built-in file must be shorter than 30 s. `tool/prepare_audio.sh` (task 3.3) cuts the files to 29 s, and `tool/check_licenses.dart` (task 3.5) fails CI for a longer one; it can use `ClipWindow.maxBuiltinLength`. If task 5.1(c) shows that user songs and voice messages can be AlarmKit sounds too, their files must be shorter than 30 s as well.

## 2026-10-28 · 1.3 · Shuffle bag
- **Decision:** the shuffle bag lives in `lib/core/shuffle_bag.dart` as `ShuffleBag`. `ShuffleBag(pool, random: Random(seed))` puts every sound of the pool in a bag, and each `next()` takes one of the sounds left out of it at random. When the bag is empty, every sound goes back in, and the sound that just played cannot be the first one out of the new bag.
  - Every choice goes through one private method, `_pick`, the only code that uses the `Random`. Task 1.5 turns it into a weighted choice there.
  - Sounds are told apart by `Sound.id`. Sounds with the same id count as one sound, the first of them, and the bag sorts the pool by id. So the order of the list does not matter: the same sounds and the same seed give the same sounds in the same order.
  - A pool of one sound plays that sound every time: "never twice in a row" holds for two sounds or more, and two sounds take turns. The "same sound" condition of experiment mode (task 7.3) is such a pool.
  - An empty pool has nothing to play, so the constructor throws an `ArgumentError`. Task 1.6 must give an alarm without sounds all the built-in sounds, from every genre, before it makes a bag, so the alarm still rings. The user chose this on 2026-10-28; one standard alarm signal was the other option.
- **Why:** taking out one sound at a time keeps both rules in one small step, and leaves one place for the weights of task 1.5. Turned down: shuffling the whole bag at each refill and swapping its first sound when it is the one that just played. That is just as random, but a weighted shuffle of a whole bag is harder to get right than one weighted choice. A pool of one repeats its sound rather than going silent, because the alarm must ring. An empty pool throws, rather than `next()` returning null: every caller would then have to handle a null on every sound, although only an empty pool can cause it. The bag gets a `Random`, not a seed, so the caller decides where chance comes from.
- **Limits / follow-up:** the `dart:math` docs say that the numbers from `Random(seed)` may change in a new Dart release. If task 1.6 must rebuild a sequence after an app update, such as the sounds of an iOS alarm chain scheduled before the update, it needs a random number generator of its own. `Random` is an interface, so the bag takes such a generator as it is.

## 2026-10-28 · 1.4 · Escalation: the gentle start
- **Decision:** the gentle start lives in `lib/core/escalation.dart` as `Escalation`. `Escalation.at(index, gentleStart: ...)` tells the sound at `index` in a ring (0 is the first sound) which intensity it should have and how loud it plays. The shuffle bag then picks the sound with `ShuffleBag.next(intensity: ...)`.
  - With a gentle start, a ring climbs one level per sound: intensity 1 at 40% volume, intensity 2 at 70%, intensity 3 at 100%. From the fourth sound on, any sound of the alarm plays, gentle ones too, at 100%. The volumes are `Escalation.volumes`, as a share of full volume (`Escalation.fullVolume`, 1.0). They are start values; tune them with real data.
  - With `Alarm.gentleStart` off, a ring is a plain shuffle at 100%: the same sounds in the same order as the bag of task 1.3.
  - A ring after Snooze plays at 100% from its first sound, like a ring with gentle start off: its caller passes `gentleStart: false`.
  - `next(intensity: ...)` takes a sound of that intensity from the sounds the bag rules allow. If none of them has it, it takes one of the nearest intensity, the gentler one on a tie: asked for 2 with only 1 and 3 there, it takes 1. So the three sounds of the climb come out of the first bag, and a pool without some intensity still rings.
- **Why:** the user made these four choices on 2026-10-28:
  - After the climb every sound rotates, not only the intensity-3 sounds in a bag of their own. With few strong sounds, those would take turns for 9 minutes, and gentle sounds, user songs and voice messages below intensity 3 would play once at most. With one bag for all sounds, the 1.3 rules (every sound once per bag, never twice in a row) hold all through a ring.
  - A missing level plays the nearest intensity, so the order still climbs as far as the pool allows. The volume climbs either way. Turned down: any sound for a missing level.
  - Gentle start off is a plain shuffle. Turned down: starting at level 3, with a strong sound first.
  - After Snooze the alarm is at full volume at once. Turned down: a gentle start again after each Snooze.
  - The intensity only narrows down the sounds the bag rules allow, before `_pick` chooses among them. So `_pick` still makes every choice with the seeded `Random` (task 1.5 adds the weights there), and the same seed gives the same ring.
- **Limits / follow-up:**
  - iOS has no public API for alarm loudness (`CLAUDE.md`, Gotchas). There only the order climbs, from gentle to strong, and from the fourth sound on gentle sounds can come back.
  - iPhone Safari has long ignored the volume a web page sets on an audio element (Apple's Safari docs; still reported on iOS 17). Task 2.5 checks whether the volume climbs there, for example with a Web Audio gain node.
  - Task 1.6 counts `index` from 0 in each ring and passes `gentleStart: false` for a ring after Snooze. The players (tasks 2.5, 4.3, 6.2) set the volume to `volume`; task 7.1's max-volume setting scales it. On Android, task 4.3 decides what full volume is: the phone's alarm volume or the loudest.

## 2026-10-28 · 1.5 · Adaptive weights
- **Decision:** the adaptive weights live in `lib/core/adaptive_weights.dart` as `SoundWeights`, an immutable value with one weight per `Sound.id`. `ShuffleBag(pool, random: ..., weights: ...)` makes a weighted pick with them.
  - Every sound starts at weight 1.0 (`SoundWeights.startWeight`). `afterSnooze(soundId)` multiplies the weight of the sound that played when the user tapped Snooze by 0.8, and `afterStop(soundId)` the one at Stop by 1.1. A weight stays between 0.2 and 3.0 (`minWeight`, `maxWeight`): 8 Snoozes in a row take a sound from 1.0 to 0.2, and 12 Stops in a row to 3.0. Each update gives a new value. These are start values; tune them with real data.
  - The sound that played at the tap is the sound of the ring's last `RingEvent`, whose action is `snooze` or `stop`. Only its weight changes.
  - A missed alarm, which reached its time cap without a tap, changes no weight.
  - One set of weights for all alarms, kept by sound id. A sound that leaves an alarm's pool, for example because the user turned off its genre, keeps its weight: it may still be in another alarm, or come back. A new sound, like any sound without a stored weight, has 1.0. A weight goes only when its sound is deleted (task 2.1).
  - Built-in sounds, user songs and voice messages all learn by the same rules. A weight is only a number on the device, next to a sound id.
  - Among the sounds the bag rules and the gentle start allow, the bag picks each one as likely as its weight says: a sound of weight 2 is twice as likely to come next as one of weight 1. It draws one `nextDouble()` per `next()`, so the same sounds, weights and seed give the same ring (task 1.6).
  - A stored weight outside the limits, such as one saved before the limits were tuned, moves to the nearest limit, and one that is not a number gets 1.0, so a bad stored value cannot break an alarm. Weights of exactly 1.0 are not kept, so two values that give every sound the same weight are equal.
- **Why:** the user took the recommended option for each of these on 2026-10-28:
  - An immutable value, like the other core values: the start weight, the factors and the limits live in one place, and no caller can make a weight outside the limits. Turned down: plain functions over a map of weights.
  - The sound at the tap, as `PLAN.md` says. Turned down: giving the change to the sound before when the last one had played less than about 3 s (the user may have woken from the one before). Real data can show whether that is needed.
  - A missed alarm says nothing about the sounds: nobody may have been there to hear it. Turned down: ×0.8 for every sound of a missed alarm.
  - One set for all alarms learns from every morning, so it learns faster. Turned down: weights per alarm, erased when a sound leaves its alarm.
  - The same rules for every sound: what counts is what wakes this user, not where the sound came from. Turned down: user songs and voice messages always at 1.0.
- **Limits / follow-up:**
  - The bag still plays every sound once per bag, so over a long ring every sound plays about as often. A weight changes how early in its bag a sound tends to come: with 8 sounds, one of weight 3.0 among sounds of 1.0 is the first sound out in 30% of the bags instead of 12.5%. Most rings end within the first few sounds, so in practice heavier sounds play more.
  - Every morning that is not missed ends with one Stop, so weights tend to climb. If the user rarely snoozes, more and more sounds reach 3.0, and they are equal again. Tune the factors with real data, or keep the average weight at 1.0 (Phase 7).
  - Task 2.1 stores the weights by sound id and deletes a sound's weight with the sound. Task 2.5 calls `afterSnooze` or `afterStop` with the id of the sound playing at the tap. Task 7.2's "Reset learning" goes back to `SoundWeights.start()`, and with adaptive rotation off the bag gets no weights.
  - Task 1.6 passes the weights to the bag of each ring. If the ring after a Snooze gets a new bag, the snoozed sound is already lighter there.

## 2026-10-28 · 1.6 · Ring sequence
- **Decision:** `buildRingSequence(alarm, pool, weights, seed)` in `lib/core/ring_sequence.dart` lists the clips of one ring ahead, in order. Each `RingClip` has its sound, its clip window, its volume, and when it starts (`startsAt`) and ends (`endsAt`), counted from the start of the ring.
  - The clips play back to back from 0 until the time cap: each one starts when the one before ends. The cap is the parameter `cap`: 10 min (`defaultRingCap`) unless the caller passes the user's setting. The last clip is cut (`ClipWindow.cutTo`), so the ring ends at the cap exactly; a ring that gets there without a tap is missed.
  - `pool` is every sound on the device. A ring plays the built-in sounds of the alarm's genres, plus every song and voice message of the user's own, whatever its genre. An alarm without genres, or whose genres have no built-in sound, plays every built-in sound of every genre (the 1.3 choice), plus the user's own.
  - One shuffle bag per ring, with `Random(seed)` and the weights. `Escalation.at` counts the clips from 0 in each ring.
  - A ring after Snooze: the caller passes `snoozedSoundId`, the id of the sound that was playing at the tap, the weights after `afterSnooze`, and a new seed. That ring is a new bag at full volume from its first sound, and it does not start with the snoozed sound: `ShuffleBag` takes an optional `lastId` for this.
  - A cap that is not positive throws an `ArgumentError`, and so does an empty pool (the bag's error). From task 2.3 on, the app always has built-in sounds.
- **Why:** the user took the recommended option for each of these on 2026-10-28:
  - The user's own songs and voice messages always play: the user added them to wake up to them, and a mother's-voice alarm woke far more children than a tone alarm (Why these features, `PLAN.md`). Genres stay the genres of the library. Turned down: songs and voice messages as genres of their own ("My songs", "Voice messages"), ticked per alarm; a new voice message would then be silent in every alarm until it was ticked.
  - A new bag after Snooze needs only what the caller has at hand, and it already uses what the Snooze taught the weights. Not starting with the snoozed sound keeps "never twice in a row" across the Snooze. Turned down: continuing the bag of the ring before, which needs that ring's seed, its weights from before the Snooze and the number of sounds it played.
  - Cutting the last clip makes the list end at the cap by itself, so no player has to check the cap. Turned down: the last clip whole, up to 29 s past the cap, with each player stopping it.
  - `Random(seed)` from `dart:math` stays. Its numbers may change in a new Dart release, but a ring scheduled ahead cannot be rebuilt from its seed anyway: by the time it rings, the weights (after another alarm's Stop) or the sounds may have changed, and with them the ring, whatever the generator. So a platform that schedules a ring ahead keeps the clips it scheduled. Turned down: a seeded generator of our own, which is more code to test and easy to get wrong on the web, where Dart has no 64-bit integers.
- **Limits / follow-up:**
  - iOS (task 5.3): the chain gets one AlarmKit alarm per clip, at the ring time plus the clip's `startsAt`, with the clip's sound file. Built-in clips are at most 29 s, so the alarms are at most 29 s apart; a 10-min ring of 29-s clips needs 21 of them, shorter clips more, and each ring after Snooze is a new chain. Task 5.1(d) checks how many alarms can be scheduled at once. AlarmKit plays whole files and has no public volume API, so the cut of the last clip and `volume` do not apply there. Task 5.3 keeps each alarm's sound id (in the alarm's metadata or in the database) to log the `RingEvent`s and update the weights.
  - Players (tasks 2.5, 4.3, 6.2): play each clip from `window.start` to `window.end` at `volume`, starting at the ring's start plus `startsAt`. After a delay, such as a throttled background tab, play the clip whose `startsAt`–`endsAt` holds the time since the ring started, so the ring keeps to the clock. The ring is missed when that time reaches the last clip's `endsAt`.
  - Each ring needs a seed of its own, such as a random number stored with the ring (task 2.1). The same app version can then rebuild a ring it is playing, for example after Android restarts the alarm service (task 4.3).
  - The number of clips is the cap divided by their lengths: 21 for 29-s clips, but 600 for a pool of only 1-s sounds. Task 2.7 can reject recordings shorter than about 1 s.
  - The "same sound" condition of experiment mode (task 7.3) passes that one sound as the pool. A cap setting (task 7.1 or the Settings page) must stay positive.
