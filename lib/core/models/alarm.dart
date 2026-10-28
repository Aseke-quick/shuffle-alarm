import 'package:meta/meta.dart';

import 'package:shuffle_alarm/core/models/clock_time.dart';

/// The two conditions of experiment mode (task 7.3).
enum ExperimentGroup {
  /// The same sound every morning.
  sameSound,

  /// The usual rotation of different sounds.
  rotation,
}

/// An alarm the user set.
@immutable
class Alarm {
  /// Throws a [RangeError] if a repeat day is not 1 to 7.
  Alarm({
    required this.id,
    required this.time,
    Set<int> repeatDays = const {},
    this.label = '',
    this.enabled = true,
    Set<String> genres = const {},
    this.gentleStart = true,
    this.experimentGroup,
  }) : repeatDays = Set.unmodifiable(repeatDays),
       genres = Set.unmodifiable(genres) {
    for (final day in repeatDays) {
      RangeError.checkValueInInterval(
        day,
        DateTime.monday,
        DateTime.sunday,
        'repeatDays',
      );
    }
  }

  /// Unique among all alarms.
  final String id;

  /// When it rings, in the device's local time zone.
  final ClockTime time;

  /// The days it rings on, as [DateTime.weekday] numbers: 1 is Monday and 7
  /// is Sunday. Empty: it rings once, at the next [time].
  final Set<int> repeatDays;

  /// A name the user gave it, such as "Gym". Can be empty.
  final String label;

  /// Whether it is switched on.
  final bool enabled;

  /// The genres of the built-in sounds it plays; no genres: every genre. The
  /// user's own songs and voice messages play in every alarm
  /// (`buildRingSequence`).
  final Set<String> genres;

  /// Whether it starts with a gentle sound and gets stronger (task 1.4).
  final bool gentleStart;

  /// The experiment condition it follows, or null outside experiment mode.
  final ExperimentGroup? experimentGroup;

  /// This alarm with the values given. It keeps its [id] and its
  /// [experimentGroup], which only experiment mode changes (task 7.3).
  ///
  /// Throws a [RangeError] if a repeat day is not 1 to 7.
  Alarm copyWith({
    ClockTime? time,
    Set<int>? repeatDays,
    String? label,
    bool? enabled,
    Set<String>? genres,
    bool? gentleStart,
  }) => Alarm(
    id: id,
    time: time ?? this.time,
    repeatDays: repeatDays ?? this.repeatDays,
    label: label ?? this.label,
    enabled: enabled ?? this.enabled,
    genres: genres ?? this.genres,
    gentleStart: gentleStart ?? this.gentleStart,
    experimentGroup: experimentGroup,
  );

  @override
  bool operator ==(Object other) =>
      other is Alarm &&
      other.id == id &&
      other.time == time &&
      _sameSet(other.repeatDays, repeatDays) &&
      other.label == label &&
      other.enabled == enabled &&
      _sameSet(other.genres, genres) &&
      other.gentleStart == gentleStart &&
      other.experimentGroup == experimentGroup;

  @override
  int get hashCode => Object.hash(
    id,
    time,
    Object.hashAllUnordered(repeatDays),
    label,
    enabled,
    Object.hashAllUnordered(genres),
    gentleStart,
    experimentGroup,
  );

  @override
  String toString() =>
      'Alarm(id: $id, time: $time, repeatDays: $repeatDays, label: $label, '
      'enabled: $enabled, genres: $genres, gentleStart: $gentleStart, '
      'experimentGroup: $experimentGroup)';
}

bool _sameSet<T>(Set<T> a, Set<T> b) =>
    a.length == b.length && a.containsAll(b);
