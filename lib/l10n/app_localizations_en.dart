// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tabAlarms => 'Alarms';

  @override
  String get tabLibrary => 'Library';

  @override
  String get tabAnalytics => 'Analytics';

  @override
  String get settings => 'Settings';

  @override
  String get tryAgain => 'Try again';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get back => 'Back';

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get alarmTone => 'Alarm tone';

  @override
  String spanDays(int n) {
    return '$n d';
  }

  @override
  String spanHours(int n) {
    return '$n h';
  }

  @override
  String spanMinutes(int n) {
    return '$n min';
  }

  @override
  String spanSeconds(int n) {
    return '$n s';
  }

  @override
  String ringsIn(String span) {
    return 'Rings in $span';
  }

  @override
  String get ringsNow => 'Rings now';

  @override
  String countdownIn(String span) {
    return 'in $span';
  }

  @override
  String get countdownNow => 'now';

  @override
  String bedBy(String time, String span) {
    return 'Bed by $time for $span of sleep';
  }

  @override
  String get sleepNowUnderMinute => 'Sleep now: under 1 min';

  @override
  String sleepNow(String span) {
    return 'Sleep now: $span';
  }

  @override
  String get bedtimeReminderTitle => 'Time for bed';

  @override
  String bedtimeReminderBody(String span, String time) {
    return 'Sleep now for $span before your $time alarm.';
  }

  @override
  String nextReminderAt(String time) {
    return 'Next at $time';
  }

  @override
  String get bedtimePassed => 'The bedtime of your next alarm has passed';

  @override
  String get repeatOnce => 'Once';

  @override
  String get repeatEveryDay => 'Every day';

  @override
  String get repeatWeekdays => 'Weekdays';

  @override
  String get repeatWeekends => 'Weekends';

  @override
  String get dayMon => 'Mon';

  @override
  String get dayTue => 'Tue';

  @override
  String get dayWed => 'Wed';

  @override
  String get dayThu => 'Thu';

  @override
  String get dayFri => 'Fri';

  @override
  String get daySat => 'Sat';

  @override
  String get daySun => 'Sun';

  @override
  String get dayMonday => 'Monday';

  @override
  String get dayTuesday => 'Tuesday';

  @override
  String get dayWednesday => 'Wednesday';

  @override
  String get dayThursday => 'Thursday';

  @override
  String get dayFriday => 'Friday';

  @override
  String get daySaturday => 'Saturday';

  @override
  String get daySunday => 'Sunday';

  @override
  String soundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sounds',
      one: '1 sound',
    );
    return '$_temp0';
  }

  @override
  String mixCaption(String sounds) {
    return 'Tonight\'s mix · $sounds';
  }

  @override
  String wokeAfter(String span, String time) {
    return '$span after your $time alarm';
  }

  @override
  String wokeAfterUnderMinute(String time) {
    return 'Under 1 min after your $time alarm';
  }

  @override
  String snoozeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count snoozes',
      one: '1 snooze',
      zero: 'No snoozes',
    );
    return '$_temp0';
  }

  @override
  String get yourSong => 'Your song';

  @override
  String get voiceMessage => 'Voice message';

  @override
  String get strengthGentle => 'Gentle';

  @override
  String get strengthMedium => 'Medium';

  @override
  String get strengthStrong => 'Strong';

  @override
  String get newAlarm => 'New alarm';

  @override
  String get noAlarmSet => 'No alarm set';

  @override
  String get tapNewAlarm => 'Tap New alarm to set one.';

  @override
  String get bedtime => 'Bedtime';

  @override
  String get nextAlarm => 'Next alarm';

  @override
  String nextAlarmAt(String time, String countdown) {
    return 'Next alarm $time, $countdown';
  }

  @override
  String tonightsMixWith(String sounds) {
    return 'Tonight\'s mix, $sounds';
  }

  @override
  String get allAlarms => 'All alarms';

  @override
  String alarmAt(String time) {
    return '$time alarm';
  }

  @override
  String get alarmGone => 'This alarm no longer exists.';

  @override
  String get editAlarm => 'Edit alarm';

  @override
  String get saveAlarm => 'Save alarm';

  @override
  String get repeat => 'Repeat';

  @override
  String get noDaysChosen => 'No days chosen, so it rings once.';

  @override
  String get label => 'Label';

  @override
  String get labelHint => 'For example: Gym';

  @override
  String get genres => 'Genres';

  @override
  String get deleteAlarm => 'Delete alarm';

  @override
  String get deleteAlarmQuestion => 'Delete this alarm?';

  @override
  String get deleteAlarmNote => 'It will not ring again.';

  @override
  String get noGenresYet =>
      'The library has no genres yet, so this alarm plays every sound.';

  @override
  String get noGenreChosen => 'None chosen, so it plays every genre.';

  @override
  String get alarmTime => 'Alarm time';

  @override
  String get typeTheTime => 'Type the time';

  @override
  String couldNotSaveAlarm(String error) {
    return 'Could not save the alarm: $error';
  }

  @override
  String couldNotDeleteAlarm(String error) {
    return 'Could not delete the alarm: $error';
  }

  @override
  String get tonightsMix => 'Tonight\'s mix';

  @override
  String couldNotSaveMix(String error) {
    return 'Could not save the mix: $error';
  }

  @override
  String get oneOrderOnly =>
      'These sounds have one order only: gentle to strong.';

  @override
  String get turnAlarmOnForMix => 'Turn an alarm on to see its mix.';

  @override
  String get stopPreview => 'Stop preview';

  @override
  String previewSound(String title) {
    return 'Preview $title';
  }

  @override
  String get notTonight => 'Not tonight';

  @override
  String notTonightSound(String title) {
    return 'Not tonight: $title';
  }

  @override
  String get inPlayOrder => 'In play order';

  @override
  String thenAgain(int minutes) {
    return 'Then again in a new order, for $minutes min at most.';
  }

  @override
  String ringsForAtMost(int minutes) {
    return 'It rings for $minutes min at most.';
  }

  @override
  String get oneSoundStays =>
      'One sound stays, so the alarm has something to play.';

  @override
  String get bringBack => 'Bring back';

  @override
  String bringBackSound(String title) {
    return 'Bring back: $title';
  }

  @override
  String get reshuffle => 'Reshuffle';

  @override
  String soundNumber(int place) {
    return 'Number $place';
  }

  @override
  String get couldNotPlaySound => 'Could not play this sound.';

  @override
  String get armToHear => 'Arm alarms to hear them';

  @override
  String get browserBlockedSound =>
      'The browser did not let the sound play. Try again.';

  @override
  String get armExplain =>
      'Your browser plays sound only after a tap. Arm alarms, then keep this tab open.';

  @override
  String get armAlarms => 'Arm alarms';

  @override
  String get keepTabOpen => 'Keep this tab open';

  @override
  String get keepTabOpenExplain =>
      'Alarms ring only while this tab is open. Keep the sound on and the device plugged in.';

  @override
  String get screenStaysOn => 'The screen stays on.';

  @override
  String get screenMayTurnOff =>
      'The screen may turn off. Keep this tab in front.';

  @override
  String get alarmsNotAvailable => 'Alarms are not available';

  @override
  String storageProblem(String hint) {
    return 'The app could not open its storage, so it cannot show or save alarms, and no alarm can ring. $hint';
  }

  @override
  String get storageHintWeb =>
      'Allow this site to store data, leave private browsing, or try the latest Chrome, Edge or Firefox.';

  @override
  String get storageHintDevice =>
      'Restart the app. If that does not help, free some space on the device.';

  @override
  String snoozeMinutes(int minutes) {
    return 'Snooze $minutes min';
  }

  @override
  String get stop => 'Stop';

  @override
  String get close => 'Close';

  @override
  String alarmPill(String time) {
    return 'Alarm $time';
  }

  @override
  String rangNobodyStopped(int minutes) {
    return 'It rang for $minutes min, and nobody stopped it.';
  }

  @override
  String get soundDidNotPlay => 'The sound did not play.';

  @override
  String get playSound => 'Play sound';

  @override
  String get nowPlaying => 'Now playing';

  @override
  String get theAlarm => 'The alarm';

  @override
  String snoozedUntil(String time) {
    return 'Snoozed until $time';
  }

  @override
  String ringsAgainThen(String name) {
    return '$name rings again then, while this tab is open.';
  }

  @override
  String get stopAlarm => 'Stop alarm';

  @override
  String get thanksRemember => 'Thanks. Wakemix will remember that.';

  @override
  String get morningCard => 'Morning card';

  @override
  String get turnCardOff => 'You can turn this card off in Settings.';

  @override
  String get notSure => 'Not sure';

  @override
  String get done => 'Done';

  @override
  String get youWokeAt => 'You woke at';

  @override
  String get whichSoundWoke => 'Which sound woke you?';

  @override
  String get comeEarlier => 'It will tend to come earlier in your next mixes.';

  @override
  String get thisOne => 'This one';

  @override
  String thisOneWokeMe(String title) {
    return 'This one woke me: $title';
  }

  @override
  String get noSoundPlayed => 'No sound played';

  @override
  String get nothingToAsk => 'So there is nothing to ask this time.';

  @override
  String get nothingToAskArm =>
      'So there is nothing to ask this time. Tap Arm alarms before your next alarm, so that you can hear it.';

  @override
  String get bedtimeReminder => 'Bedtime reminder';

  @override
  String get goToBedOnTime => 'Go to bed on time';

  @override
  String reminderExplain(String span) {
    return 'Get one notification at the bedtime of your next alarm, so you still sleep $span.';
  }

  @override
  String get browserWillAsk =>
      'Your browser will ask to allow notifications. If you say no, your alarms still ring.';

  @override
  String get worksWhileTabOpen =>
      'It works only while this tab is open, like your alarms.';

  @override
  String get notAvailableTitle => 'Not available on this device';

  @override
  String get notAvailableBody =>
      'This browser cannot show notifications from a page. Your alarms still ring.';

  @override
  String get notificationsBlockedTitle => 'Notifications are blocked';

  @override
  String get notificationsBlockedBody =>
      'The reminder stays off, and your alarms still ring. To change it, allow notifications for this site in your browser\'s settings, then try again.';

  @override
  String get noAnswerTitle => 'No answer from your browser';

  @override
  String get noAnswerBody =>
      'The reminder stays off, and your alarms still ring. If your browser does not ask again, allow notifications for this site in its settings.';

  @override
  String get waitingForBrowser => 'Waiting for your browser';

  @override
  String get turnOn => 'Turn on';

  @override
  String get notNow => 'Not now';

  @override
  String get sleep => 'Sleep';

  @override
  String get morningCardDescription =>
      'After Stop: when you woke, your snoozes, the sounds that played, and which one woke you.';

  @override
  String get bedtimeReminderDescription =>
      'One notification at the bedtime of your next alarm, while this tab is open.';

  @override
  String get notAvailableOnDevice => 'Not available on this device.';

  @override
  String get browserBlocksNotifications =>
      'Your browser blocks notifications for this site.';

  @override
  String get noAlarmIsOn => 'No alarm is on';

  @override
  String get language => 'Language';

  @override
  String get languageOfDevice => 'Same as the device';

  @override
  String get languageDescription => 'The language of the app.';

  @override
  String get noSoundsYet => 'No sounds yet.';

  @override
  String get librarySoundsHere => 'The sounds your alarms play will show here.';

  @override
  String get noMorningsYet => 'No mornings to show yet.';

  @override
  String get afterFirstAlarm =>
      'After your first alarm, your mornings will show here.';

  @override
  String get couldNotReadMornings => 'Could not read your mornings.';

  @override
  String get noAlarmThatDay => 'no alarm';

  @override
  String get gotUp => 'Got up';

  @override
  String get noneMissed => 'none missed';

  @override
  String missedCount(int count) {
    return '$count missed';
  }

  @override
  String get alarmToStop => 'Alarm to Stop';

  @override
  String get onAverage => 'on average';

  @override
  String get noStopYet => 'no Stop yet';

  @override
  String get snoozes => 'Snoozes';

  @override
  String get soundsPlayed => 'Sounds played';

  @override
  String get wakesYouBest => 'Wakes you best';

  @override
  String get notKnownYet => 'Not known yet';

  @override
  String get answerMorningCard => 'Answer the Morning card after Stop.';

  @override
  String get deletedSound => 'A deleted sound';

  @override
  String get noAlarmRang => 'No alarm rang on this day.';

  @override
  String wokeYou(String title) {
    return 'Woke you: $title';
  }

  @override
  String playedSounds(String titles) {
    return 'Played: $titles';
  }

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get periodDay => 'Day';

  @override
  String get periodWeek => 'Week';

  @override
  String get periodMonth => 'Month';

  @override
  String get periodYear => 'Year';

  @override
  String get markAtOnce => 'Got up at once';

  @override
  String get markSnoozed => 'Snoozed';

  @override
  String get markMissed => 'Missed';

  @override
  String get morningMissed => 'Missed: no Stop';

  @override
  String morningAtOnce(String span) {
    return 'Got up at once, $span after the alarm';
  }

  @override
  String morningSnoozed(int count, String span) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Stop after $count snoozes, $span after the alarm',
      one: 'Stop after 1 snooze, $span after the alarm',
    );
    return '$_temp0';
  }

  @override
  String morningCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mornings',
      one: '1 morning',
    );
    return '$_temp0';
  }

  @override
  String namedOnCard(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Named $count times on the Morning card',
      one: 'Named once on the Morning card',
    );
    return '$_temp0';
  }

  @override
  String get chartTitle => 'Time from the alarm to Stop.';

  @override
  String get chartNoStop => 'No Stop in this period.';

  @override
  String chartAverage(String span) {
    return 'On average $span.';
  }

  @override
  String chartMissed(String mornings) {
    return '$mornings missed.';
  }
}
