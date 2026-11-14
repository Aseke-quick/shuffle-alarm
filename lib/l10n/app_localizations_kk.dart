// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class AppLocalizationsKk extends AppLocalizations {
  AppLocalizationsKk([String locale = 'kk']) : super(locale);

  @override
  String get tabAlarms => 'Оятқыштар';

  @override
  String get tabLibrary => 'Кітапхана';

  @override
  String get tabAnalytics => 'Аналитика';

  @override
  String get settings => 'Баптаулар';

  @override
  String get tryAgain => 'Қайталап көру';

  @override
  String get cancel => 'Бас тарту';

  @override
  String get delete => 'Жою';

  @override
  String get back => 'Артқа';

  @override
  String get on => 'Қосулы';

  @override
  String get off => 'Өшірулі';

  @override
  String get alarmTone => 'Оятқыш сигналы';

  @override
  String spanDays(int n) {
    return '$n күн';
  }

  @override
  String spanHours(int n) {
    return '$n сағ';
  }

  @override
  String spanMinutes(int n) {
    return '$n мин';
  }

  @override
  String spanSeconds(int n) {
    return '$n с';
  }

  @override
  String ringsIn(String span) {
    return '$span кейін шырылдайды';
  }

  @override
  String get ringsNow => 'Қазір шырылдайды';

  @override
  String countdownIn(String span) {
    return '$span кейін';
  }

  @override
  String get countdownNow => 'қазір';

  @override
  String bedBy(String time, String span) {
    return '$span ұйықтау үшін $time дейін жатыңыз';
  }

  @override
  String get sleepNowUnderMinute => 'Қазір жатыңыз: ұйқы 1 мин жетпейді';

  @override
  String sleepNow(String span) {
    return 'Қазір жатыңыз: ұйқы $span';
  }

  @override
  String get bedtimeReminderTitle => 'Ұйықтайтын уақыт';

  @override
  String bedtimeReminderBody(String span, String time) {
    return '$time оятқышына дейін $span ұйықтау үшін қазір жатыңыз.';
  }

  @override
  String nextReminderAt(String time) {
    return 'Келесісі: $time';
  }

  @override
  String get bedtimePassed =>
      'Келесі оятқыштың алдында жататын уақыт өтіп кетті';

  @override
  String get repeatOnce => 'Бір рет';

  @override
  String get repeatEveryDay => 'Күн сайын';

  @override
  String get repeatWeekdays => 'Жұмыс күндері';

  @override
  String get repeatWeekends => 'Демалыс күндері';

  @override
  String get dayMon => 'Дс';

  @override
  String get dayTue => 'Сс';

  @override
  String get dayWed => 'Ср';

  @override
  String get dayThu => 'Бс';

  @override
  String get dayFri => 'Жм';

  @override
  String get daySat => 'Сб';

  @override
  String get daySun => 'Жс';

  @override
  String get dayMonday => 'Дүйсенбі';

  @override
  String get dayTuesday => 'Сейсенбі';

  @override
  String get dayWednesday => 'Сәрсенбі';

  @override
  String get dayThursday => 'Бейсенбі';

  @override
  String get dayFriday => 'Жұма';

  @override
  String get daySaturday => 'Сенбі';

  @override
  String get daySunday => 'Жексенбі';

  @override
  String soundCount(int count) {
    return '$count дыбыс';
  }

  @override
  String mixCaption(String sounds) {
    return 'Бүгінгі микс · $sounds';
  }

  @override
  String wokeAfter(String span, String time) {
    return '$time оятқышынан $span кейін';
  }

  @override
  String wokeAfterUnderMinute(String time) {
    return '$time оятқышынан кейін 1 мин жетпей';
  }

  @override
  String snoozeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count рет кейінге қалдырылды',
      zero: 'Кейінге қалдырусыз',
    );
    return '$_temp0';
  }

  @override
  String get yourSong => 'Сіздің әніңіз';

  @override
  String get voiceMessage => 'Дауыстық хабар';

  @override
  String get strengthGentle => 'Жұмсақ';

  @override
  String get strengthMedium => 'Орташа';

  @override
  String get strengthStrong => 'Күшті';

  @override
  String get newAlarm => 'Жаңа оятқыш';

  @override
  String get noAlarmSet => 'Оятқыш қойылмаған';

  @override
  String get tapNewAlarm => 'Қою үшін «Жаңа оятқыш» түймесін басыңыз.';

  @override
  String get bedtime => 'Ұйқы уақыты';

  @override
  String get nextAlarm => 'Келесі оятқыш';

  @override
  String nextAlarmAt(String time, String countdown) {
    return 'Келесі оятқыш $time, $countdown';
  }

  @override
  String tonightsMixWith(String sounds) {
    return 'Бүгінгі микс, $sounds';
  }

  @override
  String get allAlarms => 'Барлық оятқыштар';

  @override
  String alarmAt(String time) {
    return '$time оятқышы';
  }

  @override
  String get alarmGone => 'Бұл оятқыш енді жоқ.';

  @override
  String get editAlarm => 'Оятқышты өзгерту';

  @override
  String get saveAlarm => 'Оятқышты сақтау';

  @override
  String get repeat => 'Қайталануы';

  @override
  String get noDaysChosen =>
      'Күндер таңдалмаған, сондықтан ол бір рет шырылдайды.';

  @override
  String get label => 'Атауы';

  @override
  String get labelHint => 'Мысалы: Спортзал';

  @override
  String get genres => 'Жанрлар';

  @override
  String get deleteAlarm => 'Оятқышты жою';

  @override
  String get deleteAlarmQuestion => 'Бұл оятқышты жою керек пе?';

  @override
  String get deleteAlarmNote => 'Ол енді шырылдамайды.';

  @override
  String get noGenresYet =>
      'Кітапханада әзірге жанр жоқ, сондықтан бұл оятқыш барлық дыбысты ойнатады.';

  @override
  String get noGenreChosen =>
      'Ештеңе таңдалмаған, сондықтан барлық жанр ойнайды.';

  @override
  String get alarmTime => 'Оятқыш уақыты';

  @override
  String get typeTheTime => 'Уақытты теру';

  @override
  String couldNotSaveAlarm(String error) {
    return 'Оятқышты сақтау мүмкін болмады: $error';
  }

  @override
  String couldNotDeleteAlarm(String error) {
    return 'Оятқышты жою мүмкін болмады: $error';
  }

  @override
  String get tonightsMix => 'Бүгінгі микс';

  @override
  String couldNotSaveMix(String error) {
    return 'Миксті сақтау мүмкін болмады: $error';
  }

  @override
  String get oneOrderOnly =>
      'Бұл дыбыстардың бір ғана реті бар: жұмсақтан күштіге.';

  @override
  String get turnAlarmOnForMix => 'Миксін көру үшін оятқышты қосыңыз.';

  @override
  String get stopPreview => 'Тыңдауды тоқтату';

  @override
  String previewSound(String title) {
    return 'Тыңдау: $title';
  }

  @override
  String get notTonight => 'Бүгін емес';

  @override
  String notTonightSound(String title) {
    return 'Бүгін емес: $title';
  }

  @override
  String get inPlayOrder => 'Ойнау ретімен';

  @override
  String thenAgain(int minutes) {
    return 'Содан кейін жаңа ретпен қайта, ең көбі $minutes мин.';
  }

  @override
  String ringsForAtMost(int minutes) {
    return 'Ең көбі $minutes мин шырылдайды.';
  }

  @override
  String get oneSoundStays =>
      'Оятқыштың ойнататыны болуы үшін бір дыбыс қалады.';

  @override
  String get bringBack => 'Қайтару';

  @override
  String bringBackSound(String title) {
    return 'Қайтару: $title';
  }

  @override
  String get reshuffle => 'Араластыру';

  @override
  String soundNumber(int place) {
    return '$place-нөмір';
  }

  @override
  String get couldNotPlaySound => 'Бұл дыбысты ойнату мүмкін болмады.';

  @override
  String get armToHear => 'Оятқыштарды есту үшін оларды қосыңыз';

  @override
  String get browserBlockedSound =>
      'Браузер дыбысты ойнатуға рұқсат бермеді. Қайталап көріңіз.';

  @override
  String get armExplain =>
      'Браузер дыбысты тек басқаннан кейін ойнатады. «Оятқыштарды қосу» түймесін басып, бұл қойындыны жаппаңыз.';

  @override
  String get armAlarms => 'Оятқыштарды қосу';

  @override
  String get keepTabOpen => 'Бұл қойындыны жаппаңыз';

  @override
  String get keepTabOpenExplain =>
      'Оятқыштар тек осы қойынды ашық тұрғанда шырылдайды. Дыбысты өшірмеңіз, құрылғыны қуат көзінен ажыратпаңыз.';

  @override
  String get screenStaysOn => 'Экран сөнбейді.';

  @override
  String get screenMayTurnOff =>
      'Экран сөнуі мүмкін. Бұл қойындыны алдыңғы қатарда ұстаңыз.';

  @override
  String get alarmsNotAvailable => 'Оятқыштар қолжетімсіз';

  @override
  String storageProblem(String hint) {
    return 'Қолданба өз қоймасын аша алмады, сондықтан оятқыштарды көрсете де, сақтай да алмайды, ешбір оятқыш шырылдамайды. $hint';
  }

  @override
  String get storageHintWeb =>
      'Осы сайтқа деректерді сақтауға рұқсат беріңіз, құпия режимнен шығыңыз немесе Chrome, Edge не Firefox-тың соңғы нұсқасын қолданып көріңіз.';

  @override
  String get storageHintDevice =>
      'Қолданбаны қайта іске қосыңыз. Көмектеспесе, құрылғыда орын босатыңыз.';

  @override
  String snoozeMinutes(int minutes) {
    return '$minutes мин кейінге қалдыру';
  }

  @override
  String get stop => 'Тоқтату';

  @override
  String get close => 'Жабу';

  @override
  String alarmPill(String time) {
    return 'Оятқыш $time';
  }

  @override
  String rangNobodyStopped(int minutes) {
    return 'Ол $minutes мин шырылдады, оны ешкім тоқтатпады.';
  }

  @override
  String get soundDidNotPlay => 'Дыбыс ойнамады.';

  @override
  String get playSound => 'Дыбысты қосу';

  @override
  String get nowPlaying => 'Қазір ойнап тұр';

  @override
  String get theAlarm => 'Оятқыш';

  @override
  String snoozedUntil(String time) {
    return '$time дейін кейінге қалдырылды';
  }

  @override
  String ringsAgainThen(String name) {
    return '$name сол кезде қайта шырылдайды, егер бұл қойынды ашық болса.';
  }

  @override
  String get stopAlarm => 'Оятқышты өшіру';

  @override
  String get thanksRemember => 'Рақмет. Wakemix мұны есте сақтайды.';

  @override
  String get morningCard => 'Таңғы карточка';

  @override
  String get turnCardOff => 'Бұл карточканы баптаулардан өшіруге болады.';

  @override
  String get notSure => 'Білмеймін';

  @override
  String get done => 'Дайын';

  @override
  String get youWokeAt => 'Оянған уақытыңыз';

  @override
  String get whichSoundWoke => 'Сізді қай дыбыс оятты?';

  @override
  String get comeEarlier => 'Келесі микстерде ол ертерек ойнайтын болады.';

  @override
  String get thisOne => 'Осы';

  @override
  String thisOneWokeMe(String title) {
    return 'Мені осы оятты: $title';
  }

  @override
  String get noSoundPlayed => 'Ешқандай дыбыс ойнаған жоқ';

  @override
  String get nothingToAsk => 'Сондықтан бұл жолы сұрайтын ештеңе жоқ.';

  @override
  String get nothingToAskArm =>
      'Сондықтан бұл жолы сұрайтын ештеңе жоқ. Келесі оятқышты есту үшін оның алдында «Оятқыштарды қосу» түймесін басыңыз.';

  @override
  String get bedtimeReminder => 'Ұйқы туралы еске салу';

  @override
  String get goToBedOnTime => 'Уақытында жатыңыз';

  @override
  String reminderExplain(String span) {
    return 'Келесі оятқыштың алдында жататын уақытта бір хабарландыру келеді, сонда сіз $span ұйықтап үлгересіз.';
  }

  @override
  String get browserWillAsk =>
      'Браузер хабарландыруға рұқсат сұрайды. Бас тартсаңыз да, оятқыштар шырылдайды.';

  @override
  String get worksWhileTabOpen =>
      'Ол оятқыштар сияқты тек осы қойынды ашық тұрғанда жұмыс істейді.';

  @override
  String get notAvailableTitle => 'Бұл құрылғыда қолжетімсіз';

  @override
  String get notAvailableBody =>
      'Бұл браузер беттен хабарландыру көрсете алмайды. Оятқыштар бәрібір шырылдайды.';

  @override
  String get notificationsBlockedTitle => 'Хабарландырулар бұғатталған';

  @override
  String get notificationsBlockedBody =>
      'Еске салу өшірулі қалады, ал оятқыштар шырылдайды. Мұны өзгерту үшін браузер баптауларында осы сайтқа хабарландыруға рұқсат беріп, қайталап көріңіз.';

  @override
  String get noAnswerTitle => 'Браузер жауап бермеді';

  @override
  String get noAnswerBody =>
      'Еске салу өшірулі қалады, ал оятқыштар шырылдайды. Браузер қайта сұрамаса, оның баптауларында осы сайтқа хабарландыруға рұқсат беріңіз.';

  @override
  String get waitingForBrowser => 'Браузердің жауабын күтудеміз';

  @override
  String get turnOn => 'Қосу';

  @override
  String get notNow => 'Қазір емес';

  @override
  String get sleep => 'Ұйқы';

  @override
  String get morningCardDescription =>
      '«Тоқтатудан» кейін: қашан оянғаныңыз, неше рет кейінге қалдырғаныңыз, қандай дыбыстар ойнағаны және қайсысы оятқаны.';

  @override
  String get bedtimeReminderDescription =>
      'Келесі оятқыштың алдында жататын уақытта бір хабарландыру, осы қойынды ашық тұрғанда.';

  @override
  String get notAvailableOnDevice => 'Бұл құрылғыда қолжетімсіз.';

  @override
  String get browserBlocksNotifications =>
      'Браузер осы сайттың хабарландыруларын бұғаттайды.';

  @override
  String get noAlarmIsOn => 'Қосулы оятқыш жоқ';

  @override
  String get language => 'Тіл';

  @override
  String get languageOfDevice => 'Құрылғыдағыдай';

  @override
  String get languageDescription => 'Қолданбаның тілі.';

  @override
  String get noSoundsYet => 'Әзірге дыбыс жоқ.';

  @override
  String get librarySoundsHere =>
      'Мұнда оятқыштарыңыз ойнататын дыбыстар көрсетіледі.';

  @override
  String get noMorningsYet => 'Әзірге көрсететін таң жоқ.';

  @override
  String get afterFirstAlarm =>
      'Алғашқы оятқыштан кейін таңдарыңыз осында көрсетіледі.';

  @override
  String get couldNotReadMornings => 'Таңдарыңызды оқу мүмкін болмады.';

  @override
  String get noAlarmThatDay => 'оятқыш болмады';

  @override
  String get gotUp => 'Тұрған таңдар';

  @override
  String get noneMissed => 'өткізіп алған жоқ';

  @override
  String missedCount(int count) {
    return 'өткізіп алынғаны: $count';
  }

  @override
  String get alarmToStop => 'Шырылдан «Тоқтатуға» дейін';

  @override
  String get onAverage => 'орта есеппен';

  @override
  String get noStopYet => '«Тоқтату» әлі басылмаған';

  @override
  String get snoozes => 'Кейінге қалдырулар';

  @override
  String get soundsPlayed => 'Ойнаған дыбыстар';

  @override
  String get wakesYouBest => 'Сізді ең жақсы оятады';

  @override
  String get notKnownYet => 'Әзірге белгісіз';

  @override
  String get answerMorningCard =>
      '«Тоқтатудан» кейін таңғы карточкаға жауап беріңіз.';

  @override
  String get deletedSound => 'Жойылған дыбыс';

  @override
  String get noAlarmRang => 'Бұл күні оятқыш шырылдаған жоқ.';

  @override
  String wokeYou(String title) {
    return 'Оятқан: $title';
  }

  @override
  String playedSounds(String titles) {
    return 'Ойнағандар: $titles';
  }

  @override
  String get previousMonth => 'Алдыңғы ай';

  @override
  String get nextMonth => 'Келесі ай';

  @override
  String get periodDay => 'Күн';

  @override
  String get periodWeek => 'Апта';

  @override
  String get periodMonth => 'Ай';

  @override
  String get periodYear => 'Жыл';

  @override
  String get markAtOnce => 'Бірден тұрды';

  @override
  String get markSnoozed => 'Кейінге қалдырды';

  @override
  String get markMissed => 'Өткізіп алды';

  @override
  String get morningMissed => 'Өткізіп алынды: «Тоқтату» басылмады';

  @override
  String morningAtOnce(String span) {
    return 'Бірден тұрды, шырылдан $span кейін';
  }

  @override
  String morningSnoozed(int count, String span) {
    return '$count рет кейінге қалдырғаннан соң «Тоқтату», шырылдан $span кейін';
  }

  @override
  String morningCount(int count) {
    return '$count таң';
  }

  @override
  String namedOnCard(int count) {
    return 'Таңғы карточкада $count рет аталды';
  }

  @override
  String get chartTitle => 'Шырылдан «Тоқтатуға» дейінгі уақыт.';

  @override
  String get chartNoStop => 'Бұл кезеңде «Тоқтату» басылмаған.';

  @override
  String chartAverage(String span) {
    return 'Орта есеппен $span.';
  }

  @override
  String chartMissed(String mornings) {
    return 'Өткізіп алынғаны: $mornings.';
  }
}
