import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/core/analytics.dart';
import 'package:shuffle_alarm/core/bedtime.dart';
import 'package:shuffle_alarm/core/models/ring_event.dart';
import 'package:shuffle_alarm/core/models/ring_session.dart';
import 'package:shuffle_alarm/features/alarms/alarm_texts.dart';
import 'package:shuffle_alarm/features/insights/analytics_texts.dart';
import 'package:shuffle_alarm/l10n/app_localizations.dart';
import 'package:shuffle_alarm/l10n/texts.dart';

/// The texts of [code], as its .arb file holds them: every key but the
/// notes, which start with "@".
Map<String, String> _texts(String code) => {
  for (final MapEntry(:key, :value) in (jsonDecode(
    File('lib/l10n/app_$code.arb').readAsStringSync(),
  ) as Map<String, dynamic>).entries)
    if (!key.startsWith('@')) key: value as String,
};

/// The names in braces that [text] fills in, such as `span` in "in {span}".
Set<String> _placeholders(String text) => {
  for (final match in RegExp(r'\{(\w+)[,}]').allMatches(text)) match.group(1)!,
};

void main() {
  final english = _texts('en');

  // Back to English, which every other test expects.
  tearDown(() => useTexts(lookupAppLocalizations(const Locale('en'))));

  group('The .arb files', () {
    for (final code in ['ru', 'kk']) {
      final texts = _texts(code);

      test('$code has every text of the English template, and no other', () {
        expect(texts.keys.toSet(), english.keys.toSet());
      });

      test('$code fills in what English fills in', () {
        for (final key in english.keys) {
          expect(
            _placeholders(texts[key]!),
            _placeholders(english[key]!),
            reason: key,
          );
        }
      });

      test('$code has no empty text, and none left in English', () {
        // The same in every language: a name, or letters that are shared.
        const same = {'tabAnalytics', 'spanMinutes', 'spanSeconds'};
        for (final key in english.keys) {
          expect(texts[key]!.trim(), isNotEmpty, reason: key);
          if (!same.contains(key) && !(code == 'kk' && key == 'dayWed')) {
            expect(texts[key], isNot(english[key]), reason: key);
          }
        }
      });
    }

    test('the app supports exactly the three languages', () {
      expect(
        AppLocalizations.supportedLocales.map((locale) => locale.languageCode),
        unorderedEquals(['en', 'ru', 'kk']),
      );
      // English first: it stands in for any other language of a device.
      expect(AppLocalizations.supportedLocales.first, const Locale('en'));
    });
  });

  group('Russian', () {
    setUp(() => useTexts(lookupAppLocalizations(const Locale('ru'))));

    test('counts with the three forms of a Russian noun', () {
      expect(soundCount(1), '1 звук');
      expect(soundCount(3), '3 звука');
      expect(soundCount(5), '5 звуков');
      expect(soundCount(11), '11 звуков');
      expect(soundCount(21), '21 звук');
      expect(morningCount(2), '2 утра');
      expect(morningCount(6), '6 утр');
      expect(morningFacts(snoozes: 0, sounds: 0), 'Без откладываний');
      expect(morningFacts(snoozes: 2, sounds: 4), '2 откладывания · 4 звука');
      expect(namedText(1), 'Назван 1 раз на утренней карточке');
      expect(namedText(3), 'Назван 3 раза на утренней карточке');
    });

    test('writes times, days and how often an alarm rings', () {
      expect(
        ringsIn(const Duration(days: 1, hours: 7, minutes: 20)),
        'Зазвонит через 1 д 7 ч 20 мин',
      );
      expect(ringsIn(Duration.zero), 'Звонит сейчас');
      expect(countdownText(const Duration(minutes: 5)), 'через 5 мин');
      expect(repeatText(const {}), 'Один раз');
      expect(repeatText(const {1, 2, 3, 4, 5}), 'По будням');
      expect(repeatText(const {1, 3}), 'Пн, Ср');
      expect(fullDayName(DateTime.sunday), 'Воскресенье');
      expect(spanText(const Duration(minutes: 5, seconds: 40)), '5 мин 40 с');
    });

    test('says the bedtime, and how a morning went', () {
      final now = DateTime(2026, 11, 14, 20);
      expect(
        sleepText(
          BedBy(DateTime(2026, 11, 14, 23), goal: const Duration(hours: 8)),
          now: now,
          clock: (time) => '${time.hour}:00',
        ),
        'Лечь до 23:00, чтобы спать 8 ч',
      );
      final at = DateTime(2026, 11, 14, 7);
      final morning = LoggedMorning.of(
        RingSession(
          id: 's',
          alarmId: 'a',
          scheduledFor: at,
          events: [
            RingEvent(
              soundId: 'x',
              startedAt: at,
              endedAt: at.add(const Duration(seconds: 30)),
              action: RingAction.snooze,
            ),
            RingEvent(
              soundId: 'x',
              startedAt: at.add(const Duration(minutes: 5)),
              endedAt: at.add(const Duration(minutes: 6)),
              action: RingAction.stop,
            ),
          ],
        ),
      );
      expect(
        morningLine(morning),
        '«Стоп» после 1 откладывания, через 6 мин после звонка',
      );
      expect(wokeAfterText(Duration.zero, alarmTime: '7:00'), contains('7:00'));
    });
  });

  group('Kazakh', () {
    setUp(() => useTexts(lookupAppLocalizations(const Locale('kk'))));

    test('writes times, days and counts', () {
      expect(
        ringsIn(const Duration(hours: 7, minutes: 20)),
        '7 сағ 20 мин кейін шырылдайды',
      );
      expect(countdownText(const Duration(days: 1)), '1 күн кейін');
      expect(soundCount(1), '1 дыбыс');
      expect(soundCount(9), '9 дыбыс');
      expect(repeatText(const {6, 7}), 'Демалыс күндері');
      expect(repeatText(const {1, 5}), 'Дс, Жм');
      expect(fullDayName(DateTime.monday), 'Дүйсенбі');
      expect(
        morningFacts(snoozes: 0, sounds: 2),
        'Кейінге қалдырусыз · 2 дыбыс',
      );
      expect(strengthName(1), 'Жұмсақ');
    });
  });

  test('the texts are English until the app chooses a language', () {
    expect(tr.localeName, 'en');
    expect(ringsIn(const Duration(minutes: 20)), 'Rings in 20 min');
  });
}
