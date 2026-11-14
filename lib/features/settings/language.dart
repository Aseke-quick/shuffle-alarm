import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:shuffle_alarm/data/providers.dart';
import 'package:shuffle_alarm/l10n/app_localizations.dart';

/// The language the user chose in Settings, or null to follow the device
/// (task 2.9). Null until the setting is read, and when it cannot be read.
final languageProvider = NotifierProvider<LanguageSetting, Locale?>(
  LanguageSetting.new,
);

/// The languages to choose from, each by its own name, in the order of the
/// list in Settings.
const languageNames = {'en': 'English', 'ru': 'Русский', 'kk': 'Қазақша'};

/// The setting behind [languageProvider].
class LanguageSetting extends Notifier<Locale?> {
  final _loaded = Completer<void>();

  /// Completes when the setting is read, or could not be read: the app waits
  /// for it before its first page, so that page is in the chosen language.
  Future<void> get loaded => _loaded.future;

  @override
  Locale? build() {
    unawaited(_load());
    return null;
  }

  Future<void> _load() async {
    try {
      final code = await ref.read(settingsRepositoryProvider).language();
      if (ref.mounted && _supported(code)) state = Locale(code!);
    } on Object catch (error) {
      debugPrint('Could not read the language setting: $error');
    } finally {
      if (!_loaded.isCompleted) _loaded.complete();
    }
  }

  static bool _supported(String? code) => AppLocalizations.supportedLocales.any(
    (locale) => locale.languageCode == code,
  );

  /// Chooses the language with [code], or the device's for null. If that
  /// cannot be saved, the choice holds until the app closes.
  Future<void> choose(String? code) async {
    state = code == null ? null : Locale(code);
    try {
      await ref.read(settingsRepositoryProvider).saveLanguage(code);
    } on Object catch (error) {
      debugPrint('Could not save the language setting: $error');
    }
  }
}
