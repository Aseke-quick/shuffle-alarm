import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('kk'),
    Locale('ru'),
  ];

  /// No description provided for @tabAlarms.
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get tabAlarms;

  /// No description provided for @tabLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get tabLibrary;

  /// No description provided for @tabAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get tabAnalytics;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @alarmTone.
  ///
  /// In en, this message translates to:
  /// **'Alarm tone'**
  String get alarmTone;

  /// No description provided for @spanDays.
  ///
  /// In en, this message translates to:
  /// **'{n} d'**
  String spanDays(int n);

  /// No description provided for @spanHours.
  ///
  /// In en, this message translates to:
  /// **'{n} h'**
  String spanHours(int n);

  /// No description provided for @spanMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String spanMinutes(int n);

  /// No description provided for @spanSeconds.
  ///
  /// In en, this message translates to:
  /// **'{n} s'**
  String spanSeconds(int n);

  /// No description provided for @ringsIn.
  ///
  /// In en, this message translates to:
  /// **'Rings in {span}'**
  String ringsIn(String span);

  /// No description provided for @ringsNow.
  ///
  /// In en, this message translates to:
  /// **'Rings now'**
  String get ringsNow;

  /// No description provided for @countdownIn.
  ///
  /// In en, this message translates to:
  /// **'in {span}'**
  String countdownIn(String span);

  /// No description provided for @countdownNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get countdownNow;

  /// No description provided for @bedBy.
  ///
  /// In en, this message translates to:
  /// **'Bed by {time} for {span} of sleep'**
  String bedBy(String time, String span);

  /// No description provided for @sleepNowUnderMinute.
  ///
  /// In en, this message translates to:
  /// **'Sleep now: under 1 min'**
  String get sleepNowUnderMinute;

  /// No description provided for @sleepNow.
  ///
  /// In en, this message translates to:
  /// **'Sleep now: {span}'**
  String sleepNow(String span);

  /// No description provided for @bedtimeReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Time for bed'**
  String get bedtimeReminderTitle;

  /// No description provided for @bedtimeReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Sleep now for {span} before your {time} alarm.'**
  String bedtimeReminderBody(String span, String time);

  /// No description provided for @nextReminderAt.
  ///
  /// In en, this message translates to:
  /// **'Next at {time}'**
  String nextReminderAt(String time);

  /// No description provided for @bedtimePassed.
  ///
  /// In en, this message translates to:
  /// **'The bedtime of your next alarm has passed'**
  String get bedtimePassed;

  /// No description provided for @repeatOnce.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get repeatOnce;

  /// No description provided for @repeatEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get repeatEveryDay;

  /// No description provided for @repeatWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get repeatWeekdays;

  /// No description provided for @repeatWeekends.
  ///
  /// In en, this message translates to:
  /// **'Weekends'**
  String get repeatWeekends;

  /// No description provided for @dayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dayFri;

  /// No description provided for @daySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get daySat;

  /// No description provided for @daySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get daySun;

  /// No description provided for @dayMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get dayMonday;

  /// No description provided for @dayTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get dayTuesday;

  /// No description provided for @dayWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get dayWednesday;

  /// No description provided for @dayThursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get dayThursday;

  /// No description provided for @dayFriday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get dayFriday;

  /// No description provided for @daySaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get daySaturday;

  /// No description provided for @daySunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get daySunday;

  /// No description provided for @soundCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sound} other{{count} sounds}}'**
  String soundCount(int count);

  /// No description provided for @mixCaption.
  ///
  /// In en, this message translates to:
  /// **'Tonight\'s mix · {sounds}'**
  String mixCaption(String sounds);

  /// No description provided for @wokeAfter.
  ///
  /// In en, this message translates to:
  /// **'{span} after your {time} alarm'**
  String wokeAfter(String span, String time);

  /// No description provided for @wokeAfterUnderMinute.
  ///
  /// In en, this message translates to:
  /// **'Under 1 min after your {time} alarm'**
  String wokeAfterUnderMinute(String time);

  /// No description provided for @snoozeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No snoozes} =1{1 snooze} other{{count} snoozes}}'**
  String snoozeCount(int count);

  /// No description provided for @yourSong.
  ///
  /// In en, this message translates to:
  /// **'Your song'**
  String get yourSong;

  /// No description provided for @voiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Voice message'**
  String get voiceMessage;

  /// No description provided for @strengthGentle.
  ///
  /// In en, this message translates to:
  /// **'Gentle'**
  String get strengthGentle;

  /// No description provided for @strengthMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get strengthMedium;

  /// No description provided for @strengthStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get strengthStrong;

  /// No description provided for @newAlarm.
  ///
  /// In en, this message translates to:
  /// **'New alarm'**
  String get newAlarm;

  /// No description provided for @noAlarmSet.
  ///
  /// In en, this message translates to:
  /// **'No alarm set'**
  String get noAlarmSet;

  /// No description provided for @tapNewAlarm.
  ///
  /// In en, this message translates to:
  /// **'Tap New alarm to set one.'**
  String get tapNewAlarm;

  /// No description provided for @bedtime.
  ///
  /// In en, this message translates to:
  /// **'Bedtime'**
  String get bedtime;

  /// No description provided for @nextAlarm.
  ///
  /// In en, this message translates to:
  /// **'Next alarm'**
  String get nextAlarm;

  /// No description provided for @nextAlarmAt.
  ///
  /// In en, this message translates to:
  /// **'Next alarm {time}, {countdown}'**
  String nextAlarmAt(String time, String countdown);

  /// No description provided for @tonightsMixWith.
  ///
  /// In en, this message translates to:
  /// **'Tonight\'s mix, {sounds}'**
  String tonightsMixWith(String sounds);

  /// No description provided for @allAlarms.
  ///
  /// In en, this message translates to:
  /// **'All alarms'**
  String get allAlarms;

  /// No description provided for @alarmAt.
  ///
  /// In en, this message translates to:
  /// **'{time} alarm'**
  String alarmAt(String time);

  /// No description provided for @alarmGone.
  ///
  /// In en, this message translates to:
  /// **'This alarm no longer exists.'**
  String get alarmGone;

  /// No description provided for @editAlarm.
  ///
  /// In en, this message translates to:
  /// **'Edit alarm'**
  String get editAlarm;

  /// No description provided for @saveAlarm.
  ///
  /// In en, this message translates to:
  /// **'Save alarm'**
  String get saveAlarm;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @noDaysChosen.
  ///
  /// In en, this message translates to:
  /// **'No days chosen, so it rings once.'**
  String get noDaysChosen;

  /// No description provided for @label.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get label;

  /// No description provided for @labelHint.
  ///
  /// In en, this message translates to:
  /// **'For example: Gym'**
  String get labelHint;

  /// No description provided for @genres.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get genres;

  /// No description provided for @deleteAlarm.
  ///
  /// In en, this message translates to:
  /// **'Delete alarm'**
  String get deleteAlarm;

  /// No description provided for @deleteAlarmQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete this alarm?'**
  String get deleteAlarmQuestion;

  /// No description provided for @deleteAlarmNote.
  ///
  /// In en, this message translates to:
  /// **'It will not ring again.'**
  String get deleteAlarmNote;

  /// No description provided for @noGenresYet.
  ///
  /// In en, this message translates to:
  /// **'The library has no genres yet, so this alarm plays every sound.'**
  String get noGenresYet;

  /// No description provided for @noGenreChosen.
  ///
  /// In en, this message translates to:
  /// **'None chosen, so it plays every genre.'**
  String get noGenreChosen;

  /// No description provided for @alarmTime.
  ///
  /// In en, this message translates to:
  /// **'Alarm time'**
  String get alarmTime;

  /// No description provided for @typeTheTime.
  ///
  /// In en, this message translates to:
  /// **'Type the time'**
  String get typeTheTime;

  /// No description provided for @couldNotSaveAlarm.
  ///
  /// In en, this message translates to:
  /// **'Could not save the alarm: {error}'**
  String couldNotSaveAlarm(String error);

  /// No description provided for @couldNotDeleteAlarm.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the alarm: {error}'**
  String couldNotDeleteAlarm(String error);

  /// No description provided for @tonightsMix.
  ///
  /// In en, this message translates to:
  /// **'Tonight\'s mix'**
  String get tonightsMix;

  /// No description provided for @couldNotSaveMix.
  ///
  /// In en, this message translates to:
  /// **'Could not save the mix: {error}'**
  String couldNotSaveMix(String error);

  /// No description provided for @oneOrderOnly.
  ///
  /// In en, this message translates to:
  /// **'These sounds have one order only: gentle to strong.'**
  String get oneOrderOnly;

  /// No description provided for @turnAlarmOnForMix.
  ///
  /// In en, this message translates to:
  /// **'Turn an alarm on to see its mix.'**
  String get turnAlarmOnForMix;

  /// No description provided for @stopPreview.
  ///
  /// In en, this message translates to:
  /// **'Stop preview'**
  String get stopPreview;

  /// No description provided for @previewSound.
  ///
  /// In en, this message translates to:
  /// **'Preview {title}'**
  String previewSound(String title);

  /// No description provided for @notTonight.
  ///
  /// In en, this message translates to:
  /// **'Not tonight'**
  String get notTonight;

  /// No description provided for @notTonightSound.
  ///
  /// In en, this message translates to:
  /// **'Not tonight: {title}'**
  String notTonightSound(String title);

  /// No description provided for @inPlayOrder.
  ///
  /// In en, this message translates to:
  /// **'In play order'**
  String get inPlayOrder;

  /// No description provided for @thenAgain.
  ///
  /// In en, this message translates to:
  /// **'Then again in a new order, for {minutes} min at most.'**
  String thenAgain(int minutes);

  /// No description provided for @ringsForAtMost.
  ///
  /// In en, this message translates to:
  /// **'It rings for {minutes} min at most.'**
  String ringsForAtMost(int minutes);

  /// No description provided for @oneSoundStays.
  ///
  /// In en, this message translates to:
  /// **'One sound stays, so the alarm has something to play.'**
  String get oneSoundStays;

  /// No description provided for @bringBack.
  ///
  /// In en, this message translates to:
  /// **'Bring back'**
  String get bringBack;

  /// No description provided for @bringBackSound.
  ///
  /// In en, this message translates to:
  /// **'Bring back: {title}'**
  String bringBackSound(String title);

  /// No description provided for @reshuffle.
  ///
  /// In en, this message translates to:
  /// **'Reshuffle'**
  String get reshuffle;

  /// No description provided for @soundNumber.
  ///
  /// In en, this message translates to:
  /// **'Number {place}'**
  String soundNumber(int place);

  /// No description provided for @couldNotPlaySound.
  ///
  /// In en, this message translates to:
  /// **'Could not play this sound.'**
  String get couldNotPlaySound;

  /// No description provided for @armToHear.
  ///
  /// In en, this message translates to:
  /// **'Arm alarms to hear them'**
  String get armToHear;

  /// No description provided for @browserBlockedSound.
  ///
  /// In en, this message translates to:
  /// **'The browser did not let the sound play. Try again.'**
  String get browserBlockedSound;

  /// No description provided for @armExplain.
  ///
  /// In en, this message translates to:
  /// **'Your browser plays sound only after a tap. Arm alarms, then keep this tab open.'**
  String get armExplain;

  /// No description provided for @armAlarms.
  ///
  /// In en, this message translates to:
  /// **'Arm alarms'**
  String get armAlarms;

  /// No description provided for @keepTabOpen.
  ///
  /// In en, this message translates to:
  /// **'Keep this tab open'**
  String get keepTabOpen;

  /// No description provided for @keepTabOpenExplain.
  ///
  /// In en, this message translates to:
  /// **'Alarms ring only while this tab is open. Keep the sound on and the device plugged in.'**
  String get keepTabOpenExplain;

  /// No description provided for @screenStaysOn.
  ///
  /// In en, this message translates to:
  /// **'The screen stays on.'**
  String get screenStaysOn;

  /// No description provided for @screenMayTurnOff.
  ///
  /// In en, this message translates to:
  /// **'The screen may turn off. Keep this tab in front.'**
  String get screenMayTurnOff;

  /// No description provided for @alarmsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Alarms are not available'**
  String get alarmsNotAvailable;

  /// No description provided for @storageProblem.
  ///
  /// In en, this message translates to:
  /// **'The app could not open its storage, so it cannot show or save alarms, and no alarm can ring. {hint}'**
  String storageProblem(String hint);

  /// No description provided for @storageHintWeb.
  ///
  /// In en, this message translates to:
  /// **'Allow this site to store data, leave private browsing, or try the latest Chrome, Edge or Firefox.'**
  String get storageHintWeb;

  /// No description provided for @storageHintDevice.
  ///
  /// In en, this message translates to:
  /// **'Restart the app. If that does not help, free some space on the device.'**
  String get storageHintDevice;

  /// No description provided for @snoozeMinutes.
  ///
  /// In en, this message translates to:
  /// **'Snooze {minutes} min'**
  String snoozeMinutes(int minutes);

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @alarmPill.
  ///
  /// In en, this message translates to:
  /// **'Alarm {time}'**
  String alarmPill(String time);

  /// No description provided for @rangNobodyStopped.
  ///
  /// In en, this message translates to:
  /// **'It rang for {minutes} min, and nobody stopped it.'**
  String rangNobodyStopped(int minutes);

  /// No description provided for @soundDidNotPlay.
  ///
  /// In en, this message translates to:
  /// **'The sound did not play.'**
  String get soundDidNotPlay;

  /// No description provided for @playSound.
  ///
  /// In en, this message translates to:
  /// **'Play sound'**
  String get playSound;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get nowPlaying;

  /// No description provided for @theAlarm.
  ///
  /// In en, this message translates to:
  /// **'The alarm'**
  String get theAlarm;

  /// No description provided for @snoozedUntil.
  ///
  /// In en, this message translates to:
  /// **'Snoozed until {time}'**
  String snoozedUntil(String time);

  /// No description provided for @ringsAgainThen.
  ///
  /// In en, this message translates to:
  /// **'{name} rings again then, while this tab is open.'**
  String ringsAgainThen(String name);

  /// No description provided for @stopAlarm.
  ///
  /// In en, this message translates to:
  /// **'Stop alarm'**
  String get stopAlarm;

  /// No description provided for @thanksRemember.
  ///
  /// In en, this message translates to:
  /// **'Thanks. Wakemix will remember that.'**
  String get thanksRemember;

  /// No description provided for @morningCard.
  ///
  /// In en, this message translates to:
  /// **'Morning card'**
  String get morningCard;

  /// No description provided for @turnCardOff.
  ///
  /// In en, this message translates to:
  /// **'You can turn this card off in Settings.'**
  String get turnCardOff;

  /// No description provided for @notSure.
  ///
  /// In en, this message translates to:
  /// **'Not sure'**
  String get notSure;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @youWokeAt.
  ///
  /// In en, this message translates to:
  /// **'You woke at'**
  String get youWokeAt;

  /// No description provided for @whichSoundWoke.
  ///
  /// In en, this message translates to:
  /// **'Which sound woke you?'**
  String get whichSoundWoke;

  /// No description provided for @comeEarlier.
  ///
  /// In en, this message translates to:
  /// **'It will tend to come earlier in your next mixes.'**
  String get comeEarlier;

  /// No description provided for @thisOne.
  ///
  /// In en, this message translates to:
  /// **'This one'**
  String get thisOne;

  /// No description provided for @thisOneWokeMe.
  ///
  /// In en, this message translates to:
  /// **'This one woke me: {title}'**
  String thisOneWokeMe(String title);

  /// No description provided for @noSoundPlayed.
  ///
  /// In en, this message translates to:
  /// **'No sound played'**
  String get noSoundPlayed;

  /// No description provided for @nothingToAsk.
  ///
  /// In en, this message translates to:
  /// **'So there is nothing to ask this time.'**
  String get nothingToAsk;

  /// No description provided for @nothingToAskArm.
  ///
  /// In en, this message translates to:
  /// **'So there is nothing to ask this time. Tap Arm alarms before your next alarm, so that you can hear it.'**
  String get nothingToAskArm;

  /// No description provided for @bedtimeReminder.
  ///
  /// In en, this message translates to:
  /// **'Bedtime reminder'**
  String get bedtimeReminder;

  /// No description provided for @goToBedOnTime.
  ///
  /// In en, this message translates to:
  /// **'Go to bed on time'**
  String get goToBedOnTime;

  /// No description provided for @reminderExplain.
  ///
  /// In en, this message translates to:
  /// **'Get one notification at the bedtime of your next alarm, so you still sleep {span}.'**
  String reminderExplain(String span);

  /// No description provided for @browserWillAsk.
  ///
  /// In en, this message translates to:
  /// **'Your browser will ask to allow notifications. If you say no, your alarms still ring.'**
  String get browserWillAsk;

  /// No description provided for @worksWhileTabOpen.
  ///
  /// In en, this message translates to:
  /// **'It works only while this tab is open, like your alarms.'**
  String get worksWhileTabOpen;

  /// No description provided for @notAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Not available on this device'**
  String get notAvailableTitle;

  /// No description provided for @notAvailableBody.
  ///
  /// In en, this message translates to:
  /// **'This browser cannot show notifications from a page. Your alarms still ring.'**
  String get notAvailableBody;

  /// No description provided for @notificationsBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked'**
  String get notificationsBlockedTitle;

  /// No description provided for @notificationsBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'The reminder stays off, and your alarms still ring. To change it, allow notifications for this site in your browser\'s settings, then try again.'**
  String get notificationsBlockedBody;

  /// No description provided for @noAnswerTitle.
  ///
  /// In en, this message translates to:
  /// **'No answer from your browser'**
  String get noAnswerTitle;

  /// No description provided for @noAnswerBody.
  ///
  /// In en, this message translates to:
  /// **'The reminder stays off, and your alarms still ring. If your browser does not ask again, allow notifications for this site in its settings.'**
  String get noAnswerBody;

  /// No description provided for @waitingForBrowser.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your browser'**
  String get waitingForBrowser;

  /// No description provided for @turnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get turnOn;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @sleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleep;

  /// No description provided for @morningCardDescription.
  ///
  /// In en, this message translates to:
  /// **'After Stop: when you woke, your snoozes, the sounds that played, and which one woke you.'**
  String get morningCardDescription;

  /// No description provided for @bedtimeReminderDescription.
  ///
  /// In en, this message translates to:
  /// **'One notification at the bedtime of your next alarm, while this tab is open.'**
  String get bedtimeReminderDescription;

  /// No description provided for @notAvailableOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Not available on this device.'**
  String get notAvailableOnDevice;

  /// No description provided for @browserBlocksNotifications.
  ///
  /// In en, this message translates to:
  /// **'Your browser blocks notifications for this site.'**
  String get browserBlocksNotifications;

  /// No description provided for @noAlarmIsOn.
  ///
  /// In en, this message translates to:
  /// **'No alarm is on'**
  String get noAlarmIsOn;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageOfDevice.
  ///
  /// In en, this message translates to:
  /// **'Same as the device'**
  String get languageOfDevice;

  /// No description provided for @languageDescription.
  ///
  /// In en, this message translates to:
  /// **'The language of the app.'**
  String get languageDescription;

  /// No description provided for @noSoundsYet.
  ///
  /// In en, this message translates to:
  /// **'No sounds yet.'**
  String get noSoundsYet;

  /// No description provided for @librarySoundsHere.
  ///
  /// In en, this message translates to:
  /// **'The sounds your alarms play will show here.'**
  String get librarySoundsHere;

  /// No description provided for @noMorningsYet.
  ///
  /// In en, this message translates to:
  /// **'No mornings to show yet.'**
  String get noMorningsYet;

  /// No description provided for @afterFirstAlarm.
  ///
  /// In en, this message translates to:
  /// **'After your first alarm, your mornings will show here.'**
  String get afterFirstAlarm;

  /// No description provided for @couldNotReadMornings.
  ///
  /// In en, this message translates to:
  /// **'Could not read your mornings.'**
  String get couldNotReadMornings;

  /// No description provided for @noAlarmThatDay.
  ///
  /// In en, this message translates to:
  /// **'no alarm'**
  String get noAlarmThatDay;

  /// No description provided for @gotUp.
  ///
  /// In en, this message translates to:
  /// **'Got up'**
  String get gotUp;

  /// No description provided for @noneMissed.
  ///
  /// In en, this message translates to:
  /// **'none missed'**
  String get noneMissed;

  /// No description provided for @missedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} missed'**
  String missedCount(int count);

  /// No description provided for @alarmToStop.
  ///
  /// In en, this message translates to:
  /// **'Alarm to Stop'**
  String get alarmToStop;

  /// No description provided for @onAverage.
  ///
  /// In en, this message translates to:
  /// **'on average'**
  String get onAverage;

  /// No description provided for @noStopYet.
  ///
  /// In en, this message translates to:
  /// **'no Stop yet'**
  String get noStopYet;

  /// No description provided for @snoozes.
  ///
  /// In en, this message translates to:
  /// **'Snoozes'**
  String get snoozes;

  /// No description provided for @soundsPlayed.
  ///
  /// In en, this message translates to:
  /// **'Sounds played'**
  String get soundsPlayed;

  /// No description provided for @wakesYouBest.
  ///
  /// In en, this message translates to:
  /// **'Wakes you best'**
  String get wakesYouBest;

  /// No description provided for @notKnownYet.
  ///
  /// In en, this message translates to:
  /// **'Not known yet'**
  String get notKnownYet;

  /// No description provided for @answerMorningCard.
  ///
  /// In en, this message translates to:
  /// **'Answer the Morning card after Stop.'**
  String get answerMorningCard;

  /// No description provided for @deletedSound.
  ///
  /// In en, this message translates to:
  /// **'A deleted sound'**
  String get deletedSound;

  /// No description provided for @noAlarmRang.
  ///
  /// In en, this message translates to:
  /// **'No alarm rang on this day.'**
  String get noAlarmRang;

  /// No description provided for @wokeYou.
  ///
  /// In en, this message translates to:
  /// **'Woke you: {title}'**
  String wokeYou(String title);

  /// No description provided for @playedSounds.
  ///
  /// In en, this message translates to:
  /// **'Played: {titles}'**
  String playedSounds(String titles);

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @periodDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get periodDay;

  /// No description provided for @periodWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get periodMonth;

  /// No description provided for @periodYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get periodYear;

  /// No description provided for @markAtOnce.
  ///
  /// In en, this message translates to:
  /// **'Got up at once'**
  String get markAtOnce;

  /// No description provided for @markSnoozed.
  ///
  /// In en, this message translates to:
  /// **'Snoozed'**
  String get markSnoozed;

  /// No description provided for @markMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get markMissed;

  /// No description provided for @morningMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed: no Stop'**
  String get morningMissed;

  /// No description provided for @morningAtOnce.
  ///
  /// In en, this message translates to:
  /// **'Got up at once, {span} after the alarm'**
  String morningAtOnce(String span);

  /// No description provided for @morningSnoozed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Stop after 1 snooze, {span} after the alarm} other{Stop after {count} snoozes, {span} after the alarm}}'**
  String morningSnoozed(int count, String span);

  /// No description provided for @morningCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 morning} other{{count} mornings}}'**
  String morningCount(int count);

  /// No description provided for @namedOnCard.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Named once on the Morning card} other{Named {count} times on the Morning card}}'**
  String namedOnCard(int count);

  /// No description provided for @chartTitle.
  ///
  /// In en, this message translates to:
  /// **'Time from the alarm to Stop.'**
  String get chartTitle;

  /// No description provided for @chartNoStop.
  ///
  /// In en, this message translates to:
  /// **'No Stop in this period.'**
  String get chartNoStop;

  /// No description provided for @chartAverage.
  ///
  /// In en, this message translates to:
  /// **'On average {span}.'**
  String chartAverage(String span);

  /// No description provided for @chartMissed.
  ///
  /// In en, this message translates to:
  /// **'{mornings} missed.'**
  String chartMissed(String mornings);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
