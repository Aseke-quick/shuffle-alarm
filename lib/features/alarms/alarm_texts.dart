/// "Rings in 7 h 20 min": how long until an alarm rings, [untilRing],
/// rounded up to whole minutes.
///
/// Rounded up, as the clock counts: at 23:40:30 the clock shows 23:40, and an
/// alarm at 07:00 rings in 7 h 20 min. From 24 hours on it says days too,
/// such as "Rings in 1 d 2 h 5 min", and it leaves out the parts that are 0.
String ringsIn(Duration untilRing) {
  final minutes = (untilRing.inMicroseconds / Duration.microsecondsPerMinute)
      .ceil();
  final days = minutes ~/ Duration.minutesPerDay;
  final hours = minutes % Duration.minutesPerDay ~/ Duration.minutesPerHour;
  final rest = minutes % Duration.minutesPerHour;
  return [
    'Rings in',
    if (days > 0) '$days d',
    if (hours > 0) '$hours h',
    if (rest > 0) '$rest min',
  ].join(' ');
}

/// How often an alarm with these [repeatDays] rings: "Once", "Every day",
/// "Weekdays", "Weekends", or its days from Monday on, such as
/// "Mon, Wed, Fri".
String repeatText(Set<int> repeatDays) {
  final days = repeatDays.toList()..sort();
  return switch (days) {
    [] => 'Once',
    [1, 2, 3, 4, 5, 6, 7] => 'Every day',
    [1, 2, 3, 4, 5] => 'Weekdays',
    [6, 7] => 'Weekends',
    _ => days.map(dayName).join(', '),
  };
}

/// The short name of a [DateTime.weekday]: "Mon" for 1 to "Sun" for 7.
String dayName(int weekday) => _dayNames[weekday - DateTime.monday];

const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// A genre as the user reads it: its name in the library with a capital
/// first letter, such as "Pop" for `pop` and "Hip-hop" for `hip-hop`.
String genreName(String genre) =>
    genre.isEmpty ? genre : genre[0].toUpperCase() + genre.substring(1);
