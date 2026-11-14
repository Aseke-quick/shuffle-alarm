// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get tabAlarms => 'Будильники';

  @override
  String get tabLibrary => 'Библиотека';

  @override
  String get tabAnalytics => 'Аналитика';

  @override
  String get settings => 'Настройки';

  @override
  String get tryAgain => 'Повторить';

  @override
  String get cancel => 'Отмена';

  @override
  String get delete => 'Удалить';

  @override
  String get back => 'Назад';

  @override
  String get on => 'Включено';

  @override
  String get off => 'Выключено';

  @override
  String get alarmTone => 'Сигнал будильника';

  @override
  String spanDays(int n) {
    return '$n д';
  }

  @override
  String spanHours(int n) {
    return '$n ч';
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
    return 'Зазвонит через $span';
  }

  @override
  String get ringsNow => 'Звонит сейчас';

  @override
  String countdownIn(String span) {
    return 'через $span';
  }

  @override
  String get countdownNow => 'сейчас';

  @override
  String bedBy(String time, String span) {
    return 'Лечь до $time, чтобы спать $span';
  }

  @override
  String get sleepNowUnderMinute => 'Ложитесь сейчас: сна меньше 1 мин';

  @override
  String sleepNow(String span) {
    return 'Ложитесь сейчас: сна $span';
  }

  @override
  String get bedtimeReminderTitle => 'Пора спать';

  @override
  String bedtimeReminderBody(String span, String time) {
    return 'Ложитесь сейчас, чтобы поспать $span до будильника в $time.';
  }

  @override
  String nextReminderAt(String time) {
    return 'Следующее в $time';
  }

  @override
  String get bedtimePassed =>
      'Время лечь перед следующим будильником уже прошло';

  @override
  String get repeatOnce => 'Один раз';

  @override
  String get repeatEveryDay => 'Каждый день';

  @override
  String get repeatWeekdays => 'По будням';

  @override
  String get repeatWeekends => 'По выходным';

  @override
  String get dayMon => 'Пн';

  @override
  String get dayTue => 'Вт';

  @override
  String get dayWed => 'Ср';

  @override
  String get dayThu => 'Чт';

  @override
  String get dayFri => 'Пт';

  @override
  String get daySat => 'Сб';

  @override
  String get daySun => 'Вс';

  @override
  String get dayMonday => 'Понедельник';

  @override
  String get dayTuesday => 'Вторник';

  @override
  String get dayWednesday => 'Среда';

  @override
  String get dayThursday => 'Четверг';

  @override
  String get dayFriday => 'Пятница';

  @override
  String get daySaturday => 'Суббота';

  @override
  String get daySunday => 'Воскресенье';

  @override
  String soundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count звука',
      many: '$count звуков',
      few: '$count звука',
      one: '$count звук',
    );
    return '$_temp0';
  }

  @override
  String mixCaption(String sounds) {
    return 'Микс на сегодня · $sounds';
  }

  @override
  String wokeAfter(String span, String time) {
    return 'Через $span после будильника в $time';
  }

  @override
  String wokeAfterUnderMinute(String time) {
    return 'Меньше чем через 1 мин после будильника в $time';
  }

  @override
  String snoozeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count откладывания',
      many: '$count откладываний',
      few: '$count откладывания',
      one: '$count откладывание',
      zero: 'Без откладываний',
    );
    return '$_temp0';
  }

  @override
  String get yourSong => 'Ваша песня';

  @override
  String get voiceMessage => 'Голосовое сообщение';

  @override
  String get strengthGentle => 'Мягкий';

  @override
  String get strengthMedium => 'Средний';

  @override
  String get strengthStrong => 'Сильный';

  @override
  String get newAlarm => 'Новый будильник';

  @override
  String get noAlarmSet => 'Будильник не задан';

  @override
  String get tapNewAlarm => 'Нажмите «Новый будильник», чтобы поставить.';

  @override
  String get bedtime => 'Время сна';

  @override
  String get nextAlarm => 'Следующий будильник';

  @override
  String nextAlarmAt(String time, String countdown) {
    return 'Следующий будильник $time, $countdown';
  }

  @override
  String tonightsMixWith(String sounds) {
    return 'Микс на сегодня, $sounds';
  }

  @override
  String get allAlarms => 'Все будильники';

  @override
  String alarmAt(String time) {
    return 'Будильник на $time';
  }

  @override
  String get alarmGone => 'Этого будильника больше нет.';

  @override
  String get editAlarm => 'Изменить будильник';

  @override
  String get saveAlarm => 'Сохранить будильник';

  @override
  String get repeat => 'Повтор';

  @override
  String get noDaysChosen => 'Дни не выбраны, поэтому он прозвонит один раз.';

  @override
  String get label => 'Название';

  @override
  String get labelHint => 'Например: Спортзал';

  @override
  String get genres => 'Жанры';

  @override
  String get deleteAlarm => 'Удалить будильник';

  @override
  String get deleteAlarmQuestion => 'Удалить этот будильник?';

  @override
  String get deleteAlarmNote => 'Он больше не прозвонит.';

  @override
  String get noGenresYet =>
      'В библиотеке пока нет жанров, поэтому этот будильник играет все звуки.';

  @override
  String get noGenreChosen => 'Ничего не выбрано, поэтому играют все жанры.';

  @override
  String get alarmTime => 'Время будильника';

  @override
  String get typeTheTime => 'Ввести время';

  @override
  String couldNotSaveAlarm(String error) {
    return 'Не удалось сохранить будильник: $error';
  }

  @override
  String couldNotDeleteAlarm(String error) {
    return 'Не удалось удалить будильник: $error';
  }

  @override
  String get tonightsMix => 'Микс на сегодня';

  @override
  String couldNotSaveMix(String error) {
    return 'Не удалось сохранить микс: $error';
  }

  @override
  String get oneOrderOnly =>
      'У этих звуков только один порядок: от мягкого к сильному.';

  @override
  String get turnAlarmOnForMix => 'Включите будильник, чтобы увидеть его микс.';

  @override
  String get stopPreview => 'Остановить прослушивание';

  @override
  String previewSound(String title) {
    return 'Прослушать: $title';
  }

  @override
  String get notTonight => 'Не сегодня';

  @override
  String notTonightSound(String title) {
    return 'Не сегодня: $title';
  }

  @override
  String get inPlayOrder => 'В порядке звучания';

  @override
  String thenAgain(int minutes) {
    return 'Потом снова в новом порядке, не дольше $minutes мин.';
  }

  @override
  String ringsForAtMost(int minutes) {
    return 'Звонит не дольше $minutes мин.';
  }

  @override
  String get oneSoundStays =>
      'Один звук остаётся, чтобы будильнику было что играть.';

  @override
  String get bringBack => 'Вернуть';

  @override
  String bringBackSound(String title) {
    return 'Вернуть: $title';
  }

  @override
  String get reshuffle => 'Перемешать';

  @override
  String soundNumber(int place) {
    return 'Номер $place';
  }

  @override
  String get couldNotPlaySound => 'Не удалось воспроизвести этот звук.';

  @override
  String get armToHear => 'Включите будильники, чтобы их слышать';

  @override
  String get browserBlockedSound =>
      'Браузер не дал включить звук. Попробуйте ещё раз.';

  @override
  String get armExplain =>
      'Браузер включает звук только после нажатия. Нажмите «Включить будильники» и не закрывайте эту вкладку.';

  @override
  String get armAlarms => 'Включить будильники';

  @override
  String get keepTabOpen => 'Не закрывайте эту вкладку';

  @override
  String get keepTabOpenExplain =>
      'Будильники звонят, только пока открыта эта вкладка. Не выключайте звук и держите устройство на зарядке.';

  @override
  String get screenStaysOn => 'Экран не погаснет.';

  @override
  String get screenMayTurnOff =>
      'Экран может погаснуть. Держите эту вкладку на переднем плане.';

  @override
  String get alarmsNotAvailable => 'Будильники недоступны';

  @override
  String storageProblem(String hint) {
    return 'Приложение не смогло открыть своё хранилище, поэтому не может показывать и сохранять будильники, и ни один будильник не прозвонит. $hint';
  }

  @override
  String get storageHintWeb =>
      'Разрешите этому сайту хранить данные, выйдите из приватного режима или откройте последнюю версию Chrome, Edge или Firefox.';

  @override
  String get storageHintDevice =>
      'Перезапустите приложение. Если не поможет, освободите место на устройстве.';

  @override
  String snoozeMinutes(int minutes) {
    return 'Отложить на $minutes мин';
  }

  @override
  String get stop => 'Стоп';

  @override
  String get close => 'Закрыть';

  @override
  String alarmPill(String time) {
    return 'Будильник $time';
  }

  @override
  String rangNobodyStopped(int minutes) {
    return 'Он звонил $minutes мин, и его никто не остановил.';
  }

  @override
  String get soundDidNotPlay => 'Звук не включился.';

  @override
  String get playSound => 'Включить звук';

  @override
  String get nowPlaying => 'Сейчас играет';

  @override
  String get theAlarm => 'Будильник';

  @override
  String snoozedUntil(String time) {
    return 'Отложен до $time';
  }

  @override
  String ringsAgainThen(String name) {
    return '$name прозвонит снова в это время, если эта вкладка открыта.';
  }

  @override
  String get stopAlarm => 'Выключить будильник';

  @override
  String get thanksRemember => 'Спасибо. Wakemix это запомнит.';

  @override
  String get morningCard => 'Утренняя карточка';

  @override
  String get turnCardOff => 'Эту карточку можно отключить в настройках.';

  @override
  String get notSure => 'Не знаю';

  @override
  String get done => 'Готово';

  @override
  String get youWokeAt => 'Вы проснулись в';

  @override
  String get whichSoundWoke => 'Какой звук вас разбудил?';

  @override
  String get comeEarlier => 'В следующих миксах он будет чаще звучать раньше.';

  @override
  String get thisOne => 'Этот';

  @override
  String thisOneWokeMe(String title) {
    return 'Меня разбудил этот: $title';
  }

  @override
  String get noSoundPlayed => 'Звук не играл';

  @override
  String get nothingToAsk => 'Поэтому в этот раз спрашивать не о чем.';

  @override
  String get nothingToAskArm =>
      'Поэтому в этот раз спрашивать не о чем. Перед следующим будильником нажмите «Включить будильники», чтобы его услышать.';

  @override
  String get bedtimeReminder => 'Напоминание о сне';

  @override
  String get goToBedOnTime => 'Ложитесь вовремя';

  @override
  String reminderExplain(String span) {
    return 'Одно уведомление в то время, когда пора лечь перед следующим будильником, чтобы вы успели поспать $span.';
  }

  @override
  String get browserWillAsk =>
      'Браузер спросит разрешение на уведомления. Если вы откажете, будильники всё равно прозвонят.';

  @override
  String get worksWhileTabOpen =>
      'Оно работает, только пока открыта эта вкладка, как и будильники.';

  @override
  String get notAvailableTitle => 'Недоступно на этом устройстве';

  @override
  String get notAvailableBody =>
      'Этот браузер не умеет показывать уведомления со страницы. Будильники всё равно прозвонят.';

  @override
  String get notificationsBlockedTitle => 'Уведомления заблокированы';

  @override
  String get notificationsBlockedBody =>
      'Напоминание останется выключенным, а будильники прозвонят. Чтобы изменить это, разрешите уведомления для этого сайта в настройках браузера и попробуйте снова.';

  @override
  String get noAnswerTitle => 'Браузер не ответил';

  @override
  String get noAnswerBody =>
      'Напоминание останется выключенным, а будильники прозвонят. Если браузер больше не спросит, разрешите уведомления для этого сайта в его настройках.';

  @override
  String get waitingForBrowser => 'Ждём ответа браузера';

  @override
  String get turnOn => 'Включить';

  @override
  String get notNow => 'Не сейчас';

  @override
  String get sleep => 'Сон';

  @override
  String get morningCardDescription =>
      'После «Стоп»: когда вы проснулись, сколько раз откладывали, какие звуки играли и какой вас разбудил.';

  @override
  String get bedtimeReminderDescription =>
      'Одно уведомление, когда пора лечь перед следующим будильником, пока открыта эта вкладка.';

  @override
  String get notAvailableOnDevice => 'Недоступно на этом устройстве.';

  @override
  String get browserBlocksNotifications =>
      'Браузер блокирует уведомления для этого сайта.';

  @override
  String get noAlarmIsOn => 'Нет включённых будильников';

  @override
  String get language => 'Язык';

  @override
  String get languageOfDevice => 'Как на устройстве';

  @override
  String get languageDescription => 'Язык приложения.';

  @override
  String get noSoundsYet => 'Пока нет звуков.';

  @override
  String get librarySoundsHere =>
      'Здесь появятся звуки, которые играют ваши будильники.';

  @override
  String get noMorningsYet => 'Пока нет ни одного утра.';

  @override
  String get afterFirstAlarm =>
      'После первого будильника здесь появятся ваши утра.';

  @override
  String get couldNotReadMornings => 'Не удалось прочитать ваши утра.';

  @override
  String get noAlarmThatDay => 'будильника не было';

  @override
  String get gotUp => 'Подъёмов';

  @override
  String get noneMissed => 'без пропусков';

  @override
  String missedCount(int count) {
    return 'пропущено: $count';
  }

  @override
  String get alarmToStop => 'От звонка до «Стоп»';

  @override
  String get onAverage => 'в среднем';

  @override
  String get noStopYet => '«Стоп» ещё не нажимали';

  @override
  String get snoozes => 'Откладываний';

  @override
  String get soundsPlayed => 'Сыграно звуков';

  @override
  String get wakesYouBest => 'Будит вас лучше всего';

  @override
  String get notKnownYet => 'Пока неизвестно';

  @override
  String get answerMorningCard => 'Ответьте на утренней карточке после «Стоп».';

  @override
  String get deletedSound => 'Удалённый звук';

  @override
  String get noAlarmRang => 'В этот день будильник не звонил.';

  @override
  String wokeYou(String title) {
    return 'Разбудил: $title';
  }

  @override
  String playedSounds(String titles) {
    return 'Играли: $titles';
  }

  @override
  String get previousMonth => 'Предыдущий месяц';

  @override
  String get nextMonth => 'Следующий месяц';

  @override
  String get periodDay => 'День';

  @override
  String get periodWeek => 'Неделя';

  @override
  String get periodMonth => 'Месяц';

  @override
  String get periodYear => 'Год';

  @override
  String get markAtOnce => 'Подъём сразу';

  @override
  String get markSnoozed => 'С откладыванием';

  @override
  String get markMissed => 'Пропущен';

  @override
  String get morningMissed => 'Пропущен: «Стоп» не нажат';

  @override
  String morningAtOnce(String span) {
    return 'Подъём сразу, через $span после звонка';
  }

  @override
  String morningSnoozed(int count, String span) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '«Стоп» после $count откладываний, через $span после звонка',
      one: '«Стоп» после $count откладывания, через $span после звонка',
    );
    return '$_temp0';
  }

  @override
  String morningCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count утра',
      many: '$count утр',
      few: '$count утра',
      one: '$count утро',
    );
    return '$_temp0';
  }

  @override
  String namedOnCard(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Назван $count раза на утренней карточке',
      many: 'Назван $count раз на утренней карточке',
      few: 'Назван $count раза на утренней карточке',
      one: 'Назван $count раз на утренней карточке',
    );
    return '$_temp0';
  }

  @override
  String get chartTitle => 'Время от звонка до «Стоп».';

  @override
  String get chartNoStop => 'За этот период «Стоп» не нажимали.';

  @override
  String chartAverage(String span) {
    return 'В среднем $span.';
  }

  @override
  String chartMissed(String mornings) {
    return 'Пропущено: $mornings.';
  }
}
