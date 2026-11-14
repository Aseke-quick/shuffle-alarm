import 'package:shuffle_alarm/l10n/app_localizations.dart';
import 'package:shuffle_alarm/l10n/app_localizations_en.dart';

AppLocalizations _texts = AppLocalizationsEn();

/// The texts of the app in the language it shows now: English, Russian or
/// Kazakh (task 2.9). English until the app has built, such as in a test of
/// a function that writes a text.
///
/// The app sets it each time it builds, and builds every page again when the
/// language changes (`ShuffleAlarmApp`), so a widget reads it like a
/// constant.
AppLocalizations get tr => _texts;

/// Makes [texts] the texts of the app.
void useTexts(AppLocalizations texts) => _texts = texts;
