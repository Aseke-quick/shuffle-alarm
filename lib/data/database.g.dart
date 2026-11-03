// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AlarmsTable extends Alarms with TableInfo<$AlarmsTable, AlarmRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlarmsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hourMeta = const VerificationMeta('hour');
  @override
  late final GeneratedColumn<int> hour = GeneratedColumn<int>(
    'hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minuteMeta = const VerificationMeta('minute');
  @override
  late final GeneratedColumn<int> minute = GeneratedColumn<int>(
    'minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Set<int>, String> repeatDays =
      GeneratedColumn<String>(
        'repeat_days',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Set<int>>($AlarmsTable.$converterrepeatDays);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Set<String>, String> genres =
      GeneratedColumn<String>(
        'genres',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Set<String>>($AlarmsTable.$convertergenres);
  static const VerificationMeta _gentleStartMeta = const VerificationMeta(
    'gentleStart',
  );
  @override
  late final GeneratedColumn<bool> gentleStart = GeneratedColumn<bool>(
    'gentle_start',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("gentle_start" IN (0, 1))',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ExperimentGroup?, String>
  experimentGroup = GeneratedColumn<String>(
    'experiment_group',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<ExperimentGroup?>($AlarmsTable.$converterexperimentGroupn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hour,
    minute,
    repeatDays,
    label,
    enabled,
    genres,
    gentleStart,
    experimentGroup,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alarms';
  @override
  VerificationContext validateIntegrity(
    Insertable<AlarmRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hour')) {
      context.handle(
        _hourMeta,
        hour.isAcceptableOrUnknown(data['hour']!, _hourMeta),
      );
    } else if (isInserting) {
      context.missing(_hourMeta);
    }
    if (data.containsKey('minute')) {
      context.handle(
        _minuteMeta,
        minute.isAcceptableOrUnknown(data['minute']!, _minuteMeta),
      );
    } else if (isInserting) {
      context.missing(_minuteMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    } else if (isInserting) {
      context.missing(_enabledMeta);
    }
    if (data.containsKey('gentle_start')) {
      context.handle(
        _gentleStartMeta,
        gentleStart.isAcceptableOrUnknown(
          data['gentle_start']!,
          _gentleStartMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_gentleStartMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AlarmRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlarmRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hour'],
      )!,
      minute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minute'],
      )!,
      repeatDays: $AlarmsTable.$converterrepeatDays.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}repeat_days'],
        )!,
      ),
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      genres: $AlarmsTable.$convertergenres.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}genres'],
        )!,
      ),
      gentleStart: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}gentle_start'],
      )!,
      experimentGroup: $AlarmsTable.$converterexperimentGroupn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}experiment_group'],
        ),
      ),
    );
  }

  @override
  $AlarmsTable createAlias(String alias) {
    return $AlarmsTable(attachedDatabase, alias);
  }

  static TypeConverter<Set<int>, String> $converterrepeatDays =
      const _SetConverter<int>();
  static TypeConverter<Set<String>, String> $convertergenres =
      const _SetConverter<String>();
  static JsonTypeConverter2<ExperimentGroup, String, String>
  $converterexperimentGroup = const EnumNameConverter<ExperimentGroup>(
    ExperimentGroup.values,
  );
  static JsonTypeConverter2<ExperimentGroup?, String?, String?>
  $converterexperimentGroupn = JsonTypeConverter2.asNullable(
    $converterexperimentGroup,
  );
}

class AlarmRow extends DataClass implements Insertable<AlarmRow> {
  final String id;
  final int hour;
  final int minute;

  /// A JSON list in ascending order, such as `[1,3,5]`.
  final Set<int> repeatDays;
  final String label;
  final bool enabled;

  /// A JSON list in ascending order, such as `["jazz","pop"]`.
  final Set<String> genres;
  final bool gentleStart;
  final ExperimentGroup? experimentGroup;
  const AlarmRow({
    required this.id,
    required this.hour,
    required this.minute,
    required this.repeatDays,
    required this.label,
    required this.enabled,
    required this.genres,
    required this.gentleStart,
    this.experimentGroup,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hour'] = Variable<int>(hour);
    map['minute'] = Variable<int>(minute);
    {
      map['repeat_days'] = Variable<String>(
        $AlarmsTable.$converterrepeatDays.toSql(repeatDays),
      );
    }
    map['label'] = Variable<String>(label);
    map['enabled'] = Variable<bool>(enabled);
    {
      map['genres'] = Variable<String>(
        $AlarmsTable.$convertergenres.toSql(genres),
      );
    }
    map['gentle_start'] = Variable<bool>(gentleStart);
    if (!nullToAbsent || experimentGroup != null) {
      map['experiment_group'] = Variable<String>(
        $AlarmsTable.$converterexperimentGroupn.toSql(experimentGroup),
      );
    }
    return map;
  }

  AlarmsCompanion toCompanion(bool nullToAbsent) {
    return AlarmsCompanion(
      id: Value(id),
      hour: Value(hour),
      minute: Value(minute),
      repeatDays: Value(repeatDays),
      label: Value(label),
      enabled: Value(enabled),
      genres: Value(genres),
      gentleStart: Value(gentleStart),
      experimentGroup: experimentGroup == null && nullToAbsent
          ? const Value.absent()
          : Value(experimentGroup),
    );
  }

  factory AlarmRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlarmRow(
      id: serializer.fromJson<String>(json['id']),
      hour: serializer.fromJson<int>(json['hour']),
      minute: serializer.fromJson<int>(json['minute']),
      repeatDays: serializer.fromJson<Set<int>>(json['repeatDays']),
      label: serializer.fromJson<String>(json['label']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      genres: serializer.fromJson<Set<String>>(json['genres']),
      gentleStart: serializer.fromJson<bool>(json['gentleStart']),
      experimentGroup: $AlarmsTable.$converterexperimentGroupn.fromJson(
        serializer.fromJson<String?>(json['experimentGroup']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hour': serializer.toJson<int>(hour),
      'minute': serializer.toJson<int>(minute),
      'repeatDays': serializer.toJson<Set<int>>(repeatDays),
      'label': serializer.toJson<String>(label),
      'enabled': serializer.toJson<bool>(enabled),
      'genres': serializer.toJson<Set<String>>(genres),
      'gentleStart': serializer.toJson<bool>(gentleStart),
      'experimentGroup': serializer.toJson<String?>(
        $AlarmsTable.$converterexperimentGroupn.toJson(experimentGroup),
      ),
    };
  }

  AlarmRow copyWith({
    String? id,
    int? hour,
    int? minute,
    Set<int>? repeatDays,
    String? label,
    bool? enabled,
    Set<String>? genres,
    bool? gentleStart,
    Value<ExperimentGroup?> experimentGroup = const Value.absent(),
  }) => AlarmRow(
    id: id ?? this.id,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    repeatDays: repeatDays ?? this.repeatDays,
    label: label ?? this.label,
    enabled: enabled ?? this.enabled,
    genres: genres ?? this.genres,
    gentleStart: gentleStart ?? this.gentleStart,
    experimentGroup: experimentGroup.present
        ? experimentGroup.value
        : this.experimentGroup,
  );
  AlarmRow copyWithCompanion(AlarmsCompanion data) {
    return AlarmRow(
      id: data.id.present ? data.id.value : this.id,
      hour: data.hour.present ? data.hour.value : this.hour,
      minute: data.minute.present ? data.minute.value : this.minute,
      repeatDays: data.repeatDays.present
          ? data.repeatDays.value
          : this.repeatDays,
      label: data.label.present ? data.label.value : this.label,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      genres: data.genres.present ? data.genres.value : this.genres,
      gentleStart: data.gentleStart.present
          ? data.gentleStart.value
          : this.gentleStart,
      experimentGroup: data.experimentGroup.present
          ? data.experimentGroup.value
          : this.experimentGroup,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlarmRow(')
          ..write('id: $id, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('repeatDays: $repeatDays, ')
          ..write('label: $label, ')
          ..write('enabled: $enabled, ')
          ..write('genres: $genres, ')
          ..write('gentleStart: $gentleStart, ')
          ..write('experimentGroup: $experimentGroup')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    hour,
    minute,
    repeatDays,
    label,
    enabled,
    genres,
    gentleStart,
    experimentGroup,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlarmRow &&
          other.id == this.id &&
          other.hour == this.hour &&
          other.minute == this.minute &&
          other.repeatDays == this.repeatDays &&
          other.label == this.label &&
          other.enabled == this.enabled &&
          other.genres == this.genres &&
          other.gentleStart == this.gentleStart &&
          other.experimentGroup == this.experimentGroup);
}

class AlarmsCompanion extends UpdateCompanion<AlarmRow> {
  final Value<String> id;
  final Value<int> hour;
  final Value<int> minute;
  final Value<Set<int>> repeatDays;
  final Value<String> label;
  final Value<bool> enabled;
  final Value<Set<String>> genres;
  final Value<bool> gentleStart;
  final Value<ExperimentGroup?> experimentGroup;
  final Value<int> rowid;
  const AlarmsCompanion({
    this.id = const Value.absent(),
    this.hour = const Value.absent(),
    this.minute = const Value.absent(),
    this.repeatDays = const Value.absent(),
    this.label = const Value.absent(),
    this.enabled = const Value.absent(),
    this.genres = const Value.absent(),
    this.gentleStart = const Value.absent(),
    this.experimentGroup = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlarmsCompanion.insert({
    required String id,
    required int hour,
    required int minute,
    required Set<int> repeatDays,
    required String label,
    required bool enabled,
    required Set<String> genres,
    required bool gentleStart,
    this.experimentGroup = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       hour = Value(hour),
       minute = Value(minute),
       repeatDays = Value(repeatDays),
       label = Value(label),
       enabled = Value(enabled),
       genres = Value(genres),
       gentleStart = Value(gentleStart);
  static Insertable<AlarmRow> custom({
    Expression<String>? id,
    Expression<int>? hour,
    Expression<int>? minute,
    Expression<String>? repeatDays,
    Expression<String>? label,
    Expression<bool>? enabled,
    Expression<String>? genres,
    Expression<bool>? gentleStart,
    Expression<String>? experimentGroup,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hour != null) 'hour': hour,
      if (minute != null) 'minute': minute,
      if (repeatDays != null) 'repeat_days': repeatDays,
      if (label != null) 'label': label,
      if (enabled != null) 'enabled': enabled,
      if (genres != null) 'genres': genres,
      if (gentleStart != null) 'gentle_start': gentleStart,
      if (experimentGroup != null) 'experiment_group': experimentGroup,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlarmsCompanion copyWith({
    Value<String>? id,
    Value<int>? hour,
    Value<int>? minute,
    Value<Set<int>>? repeatDays,
    Value<String>? label,
    Value<bool>? enabled,
    Value<Set<String>>? genres,
    Value<bool>? gentleStart,
    Value<ExperimentGroup?>? experimentGroup,
    Value<int>? rowid,
  }) {
    return AlarmsCompanion(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      repeatDays: repeatDays ?? this.repeatDays,
      label: label ?? this.label,
      enabled: enabled ?? this.enabled,
      genres: genres ?? this.genres,
      gentleStart: gentleStart ?? this.gentleStart,
      experimentGroup: experimentGroup ?? this.experimentGroup,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hour.present) {
      map['hour'] = Variable<int>(hour.value);
    }
    if (minute.present) {
      map['minute'] = Variable<int>(minute.value);
    }
    if (repeatDays.present) {
      map['repeat_days'] = Variable<String>(
        $AlarmsTable.$converterrepeatDays.toSql(repeatDays.value),
      );
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (genres.present) {
      map['genres'] = Variable<String>(
        $AlarmsTable.$convertergenres.toSql(genres.value),
      );
    }
    if (gentleStart.present) {
      map['gentle_start'] = Variable<bool>(gentleStart.value);
    }
    if (experimentGroup.present) {
      map['experiment_group'] = Variable<String>(
        $AlarmsTable.$converterexperimentGroupn.toSql(experimentGroup.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlarmsCompanion(')
          ..write('id: $id, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('repeatDays: $repeatDays, ')
          ..write('label: $label, ')
          ..write('enabled: $enabled, ')
          ..write('genres: $genres, ')
          ..write('gentleStart: $gentleStart, ')
          ..write('experimentGroup: $experimentGroup, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SoundsTable extends Sounds with TableInfo<$SoundsTable, SoundRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SoundsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SoundSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SoundSource>($SoundsTable.$convertersource);
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
    'genre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intensityMeta = const VerificationMeta(
    'intensity',
  );
  @override
  late final GeneratedColumn<int> intensity = GeneratedColumn<int>(
    'intensity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Duration, int> duration =
      GeneratedColumn<int>(
        'duration',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<Duration>($SoundsTable.$converterduration);
  @override
  late final GeneratedColumnWithTypeConverter<Duration, int> clipStart =
      GeneratedColumn<int>(
        'clip_start',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<Duration>($SoundsTable.$converterclipStart);
  static const VerificationMeta _audioPathMeta = const VerificationMeta(
    'audioPath',
  );
  @override
  late final GeneratedColumn<String> audioPath = GeneratedColumn<String>(
    'audio_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    source,
    genre,
    intensity,
    duration,
    clipStart,
    audioPath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sounds';
  @override
  VerificationContext validateIntegrity(
    Insertable<SoundRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('genre')) {
      context.handle(
        _genreMeta,
        genre.isAcceptableOrUnknown(data['genre']!, _genreMeta),
      );
    } else if (isInserting) {
      context.missing(_genreMeta);
    }
    if (data.containsKey('intensity')) {
      context.handle(
        _intensityMeta,
        intensity.isAcceptableOrUnknown(data['intensity']!, _intensityMeta),
      );
    } else if (isInserting) {
      context.missing(_intensityMeta);
    }
    if (data.containsKey('audio_path')) {
      context.handle(
        _audioPathMeta,
        audioPath.isAcceptableOrUnknown(data['audio_path']!, _audioPathMeta),
      );
    } else if (isInserting) {
      context.missing(_audioPathMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SoundRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SoundRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      source: $SoundsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      genre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre'],
      )!,
      intensity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}intensity'],
      )!,
      duration: $SoundsTable.$converterduration.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}duration'],
        )!,
      ),
      clipStart: $SoundsTable.$converterclipStart.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}clip_start'],
        )!,
      ),
      audioPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_path'],
      )!,
    );
  }

  @override
  $SoundsTable createAlias(String alias) {
    return $SoundsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SoundSource, String, String> $convertersource =
      const EnumNameConverter<SoundSource>(SoundSource.values);
  static TypeConverter<Duration, int> $converterduration =
      const _DurationConverter();
  static TypeConverter<Duration, int> $converterclipStart =
      const _DurationConverter();
}

class SoundRow extends DataClass implements Insertable<SoundRow> {
  final String id;
  final String title;
  final SoundSource source;
  final String genre;
  final int intensity;

  /// In microseconds.
  final Duration duration;

  /// In microseconds.
  final Duration clipStart;
  final String audioPath;
  const SoundRow({
    required this.id,
    required this.title,
    required this.source,
    required this.genre,
    required this.intensity,
    required this.duration,
    required this.clipStart,
    required this.audioPath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    {
      map['source'] = Variable<String>(
        $SoundsTable.$convertersource.toSql(source),
      );
    }
    map['genre'] = Variable<String>(genre);
    map['intensity'] = Variable<int>(intensity);
    {
      map['duration'] = Variable<int>(
        $SoundsTable.$converterduration.toSql(duration),
      );
    }
    {
      map['clip_start'] = Variable<int>(
        $SoundsTable.$converterclipStart.toSql(clipStart),
      );
    }
    map['audio_path'] = Variable<String>(audioPath);
    return map;
  }

  SoundsCompanion toCompanion(bool nullToAbsent) {
    return SoundsCompanion(
      id: Value(id),
      title: Value(title),
      source: Value(source),
      genre: Value(genre),
      intensity: Value(intensity),
      duration: Value(duration),
      clipStart: Value(clipStart),
      audioPath: Value(audioPath),
    );
  }

  factory SoundRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SoundRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      source: $SoundsTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      genre: serializer.fromJson<String>(json['genre']),
      intensity: serializer.fromJson<int>(json['intensity']),
      duration: serializer.fromJson<Duration>(json['duration']),
      clipStart: serializer.fromJson<Duration>(json['clipStart']),
      audioPath: serializer.fromJson<String>(json['audioPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'source': serializer.toJson<String>(
        $SoundsTable.$convertersource.toJson(source),
      ),
      'genre': serializer.toJson<String>(genre),
      'intensity': serializer.toJson<int>(intensity),
      'duration': serializer.toJson<Duration>(duration),
      'clipStart': serializer.toJson<Duration>(clipStart),
      'audioPath': serializer.toJson<String>(audioPath),
    };
  }

  SoundRow copyWith({
    String? id,
    String? title,
    SoundSource? source,
    String? genre,
    int? intensity,
    Duration? duration,
    Duration? clipStart,
    String? audioPath,
  }) => SoundRow(
    id: id ?? this.id,
    title: title ?? this.title,
    source: source ?? this.source,
    genre: genre ?? this.genre,
    intensity: intensity ?? this.intensity,
    duration: duration ?? this.duration,
    clipStart: clipStart ?? this.clipStart,
    audioPath: audioPath ?? this.audioPath,
  );
  SoundRow copyWithCompanion(SoundsCompanion data) {
    return SoundRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      source: data.source.present ? data.source.value : this.source,
      genre: data.genre.present ? data.genre.value : this.genre,
      intensity: data.intensity.present ? data.intensity.value : this.intensity,
      duration: data.duration.present ? data.duration.value : this.duration,
      clipStart: data.clipStart.present ? data.clipStart.value : this.clipStart,
      audioPath: data.audioPath.present ? data.audioPath.value : this.audioPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SoundRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('source: $source, ')
          ..write('genre: $genre, ')
          ..write('intensity: $intensity, ')
          ..write('duration: $duration, ')
          ..write('clipStart: $clipStart, ')
          ..write('audioPath: $audioPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    source,
    genre,
    intensity,
    duration,
    clipStart,
    audioPath,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SoundRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.source == this.source &&
          other.genre == this.genre &&
          other.intensity == this.intensity &&
          other.duration == this.duration &&
          other.clipStart == this.clipStart &&
          other.audioPath == this.audioPath);
}

class SoundsCompanion extends UpdateCompanion<SoundRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<SoundSource> source;
  final Value<String> genre;
  final Value<int> intensity;
  final Value<Duration> duration;
  final Value<Duration> clipStart;
  final Value<String> audioPath;
  final Value<int> rowid;
  const SoundsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.source = const Value.absent(),
    this.genre = const Value.absent(),
    this.intensity = const Value.absent(),
    this.duration = const Value.absent(),
    this.clipStart = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SoundsCompanion.insert({
    required String id,
    required String title,
    required SoundSource source,
    required String genre,
    required int intensity,
    required Duration duration,
    required Duration clipStart,
    required String audioPath,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       source = Value(source),
       genre = Value(genre),
       intensity = Value(intensity),
       duration = Value(duration),
       clipStart = Value(clipStart),
       audioPath = Value(audioPath);
  static Insertable<SoundRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? source,
    Expression<String>? genre,
    Expression<int>? intensity,
    Expression<int>? duration,
    Expression<int>? clipStart,
    Expression<String>? audioPath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (source != null) 'source': source,
      if (genre != null) 'genre': genre,
      if (intensity != null) 'intensity': intensity,
      if (duration != null) 'duration': duration,
      if (clipStart != null) 'clip_start': clipStart,
      if (audioPath != null) 'audio_path': audioPath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SoundsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<SoundSource>? source,
    Value<String>? genre,
    Value<int>? intensity,
    Value<Duration>? duration,
    Value<Duration>? clipStart,
    Value<String>? audioPath,
    Value<int>? rowid,
  }) {
    return SoundsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      source: source ?? this.source,
      genre: genre ?? this.genre,
      intensity: intensity ?? this.intensity,
      duration: duration ?? this.duration,
      clipStart: clipStart ?? this.clipStart,
      audioPath: audioPath ?? this.audioPath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $SoundsTable.$convertersource.toSql(source.value),
      );
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (intensity.present) {
      map['intensity'] = Variable<int>(intensity.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(
        $SoundsTable.$converterduration.toSql(duration.value),
      );
    }
    if (clipStart.present) {
      map['clip_start'] = Variable<int>(
        $SoundsTable.$converterclipStart.toSql(clipStart.value),
      );
    }
    if (audioPath.present) {
      map['audio_path'] = Variable<String>(audioPath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SoundsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('source: $source, ')
          ..write('genre: $genre, ')
          ..write('intensity: $intensity, ')
          ..write('duration: $duration, ')
          ..write('clipStart: $clipStart, ')
          ..write('audioPath: $audioPath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeightsTable extends Weights with TableInfo<$WeightsTable, WeightRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeightsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _soundIdMeta = const VerificationMeta(
    'soundId',
  );
  @override
  late final GeneratedColumn<String> soundId = GeneratedColumn<String>(
    'sound_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sounds (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
    'weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [soundId, weight];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weights';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeightRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sound_id')) {
      context.handle(
        _soundIdMeta,
        soundId.isAcceptableOrUnknown(data['sound_id']!, _soundIdMeta),
      );
    } else if (isInserting) {
      context.missing(_soundIdMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    } else if (isInserting) {
      context.missing(_weightMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {soundId};
  @override
  WeightRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeightRow(
      soundId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sound_id'],
      )!,
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight'],
      )!,
    );
  }

  @override
  $WeightsTable createAlias(String alias) {
    return $WeightsTable(attachedDatabase, alias);
  }
}

class WeightRow extends DataClass implements Insertable<WeightRow> {
  final String soundId;
  final double weight;
  const WeightRow({required this.soundId, required this.weight});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['sound_id'] = Variable<String>(soundId);
    map['weight'] = Variable<double>(weight);
    return map;
  }

  WeightsCompanion toCompanion(bool nullToAbsent) {
    return WeightsCompanion(soundId: Value(soundId), weight: Value(weight));
  }

  factory WeightRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeightRow(
      soundId: serializer.fromJson<String>(json['soundId']),
      weight: serializer.fromJson<double>(json['weight']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'soundId': serializer.toJson<String>(soundId),
      'weight': serializer.toJson<double>(weight),
    };
  }

  WeightRow copyWith({String? soundId, double? weight}) => WeightRow(
    soundId: soundId ?? this.soundId,
    weight: weight ?? this.weight,
  );
  WeightRow copyWithCompanion(WeightsCompanion data) {
    return WeightRow(
      soundId: data.soundId.present ? data.soundId.value : this.soundId,
      weight: data.weight.present ? data.weight.value : this.weight,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeightRow(')
          ..write('soundId: $soundId, ')
          ..write('weight: $weight')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(soundId, weight);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeightRow &&
          other.soundId == this.soundId &&
          other.weight == this.weight);
}

class WeightsCompanion extends UpdateCompanion<WeightRow> {
  final Value<String> soundId;
  final Value<double> weight;
  final Value<int> rowid;
  const WeightsCompanion({
    this.soundId = const Value.absent(),
    this.weight = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeightsCompanion.insert({
    required String soundId,
    required double weight,
    this.rowid = const Value.absent(),
  }) : soundId = Value(soundId),
       weight = Value(weight);
  static Insertable<WeightRow> custom({
    Expression<String>? soundId,
    Expression<double>? weight,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (soundId != null) 'sound_id': soundId,
      if (weight != null) 'weight': weight,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeightsCompanion copyWith({
    Value<String>? soundId,
    Value<double>? weight,
    Value<int>? rowid,
  }) {
    return WeightsCompanion(
      soundId: soundId ?? this.soundId,
      weight: weight ?? this.weight,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (soundId.present) {
      map['sound_id'] = Variable<String>(soundId.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeightsCompanion(')
          ..write('soundId: $soundId, ')
          ..write('weight: $weight, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RingSessionsTable extends RingSessions
    with TableInfo<$RingSessionsTable, RingSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RingSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _alarmIdMeta = const VerificationMeta(
    'alarmId',
  );
  @override
  late final GeneratedColumn<String> alarmId = GeneratedColumn<String>(
    'alarm_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> scheduledFor =
      GeneratedColumn<int>(
        'scheduled_for',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($RingSessionsTable.$converterscheduledFor);
  @override
  List<GeneratedColumn> get $columns => [id, alarmId, scheduledFor];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ring_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<RingSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('alarm_id')) {
      context.handle(
        _alarmIdMeta,
        alarmId.isAcceptableOrUnknown(data['alarm_id']!, _alarmIdMeta),
      );
    } else if (isInserting) {
      context.missing(_alarmIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RingSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RingSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      alarmId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alarm_id'],
      )!,
      scheduledFor: $RingSessionsTable.$converterscheduledFor.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}scheduled_for'],
        )!,
      ),
    );
  }

  @override
  $RingSessionsTable createAlias(String alias) {
    return $RingSessionsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterscheduledFor =
      const _TimeConverter();
}

class RingSessionRow extends DataClass implements Insertable<RingSessionRow> {
  final String id;

  /// The `Alarm.id`, without a foreign key: the ring history stays when the
  /// alarm is deleted.
  final String alarmId;

  /// In microseconds since 1970 UTC.
  final DateTime scheduledFor;
  const RingSessionRow({
    required this.id,
    required this.alarmId,
    required this.scheduledFor,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['alarm_id'] = Variable<String>(alarmId);
    {
      map['scheduled_for'] = Variable<int>(
        $RingSessionsTable.$converterscheduledFor.toSql(scheduledFor),
      );
    }
    return map;
  }

  RingSessionsCompanion toCompanion(bool nullToAbsent) {
    return RingSessionsCompanion(
      id: Value(id),
      alarmId: Value(alarmId),
      scheduledFor: Value(scheduledFor),
    );
  }

  factory RingSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RingSessionRow(
      id: serializer.fromJson<String>(json['id']),
      alarmId: serializer.fromJson<String>(json['alarmId']),
      scheduledFor: serializer.fromJson<DateTime>(json['scheduledFor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'alarmId': serializer.toJson<String>(alarmId),
      'scheduledFor': serializer.toJson<DateTime>(scheduledFor),
    };
  }

  RingSessionRow copyWith({
    String? id,
    String? alarmId,
    DateTime? scheduledFor,
  }) => RingSessionRow(
    id: id ?? this.id,
    alarmId: alarmId ?? this.alarmId,
    scheduledFor: scheduledFor ?? this.scheduledFor,
  );
  RingSessionRow copyWithCompanion(RingSessionsCompanion data) {
    return RingSessionRow(
      id: data.id.present ? data.id.value : this.id,
      alarmId: data.alarmId.present ? data.alarmId.value : this.alarmId,
      scheduledFor: data.scheduledFor.present
          ? data.scheduledFor.value
          : this.scheduledFor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RingSessionRow(')
          ..write('id: $id, ')
          ..write('alarmId: $alarmId, ')
          ..write('scheduledFor: $scheduledFor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, alarmId, scheduledFor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RingSessionRow &&
          other.id == this.id &&
          other.alarmId == this.alarmId &&
          other.scheduledFor == this.scheduledFor);
}

class RingSessionsCompanion extends UpdateCompanion<RingSessionRow> {
  final Value<String> id;
  final Value<String> alarmId;
  final Value<DateTime> scheduledFor;
  final Value<int> rowid;
  const RingSessionsCompanion({
    this.id = const Value.absent(),
    this.alarmId = const Value.absent(),
    this.scheduledFor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RingSessionsCompanion.insert({
    required String id,
    required String alarmId,
    required DateTime scheduledFor,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       alarmId = Value(alarmId),
       scheduledFor = Value(scheduledFor);
  static Insertable<RingSessionRow> custom({
    Expression<String>? id,
    Expression<String>? alarmId,
    Expression<int>? scheduledFor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (alarmId != null) 'alarm_id': alarmId,
      if (scheduledFor != null) 'scheduled_for': scheduledFor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RingSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? alarmId,
    Value<DateTime>? scheduledFor,
    Value<int>? rowid,
  }) {
    return RingSessionsCompanion(
      id: id ?? this.id,
      alarmId: alarmId ?? this.alarmId,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (alarmId.present) {
      map['alarm_id'] = Variable<String>(alarmId.value);
    }
    if (scheduledFor.present) {
      map['scheduled_for'] = Variable<int>(
        $RingSessionsTable.$converterscheduledFor.toSql(scheduledFor.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RingSessionsCompanion(')
          ..write('id: $id, ')
          ..write('alarmId: $alarmId, ')
          ..write('scheduledFor: $scheduledFor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RingEventsTable extends RingEvents
    with TableInfo<$RingEventsTable, RingEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RingEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ring_sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _soundIdMeta = const VerificationMeta(
    'soundId',
  );
  @override
  late final GeneratedColumn<String> soundId = GeneratedColumn<String>(
    'sound_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> startedAt =
      GeneratedColumn<int>(
        'started_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($RingEventsTable.$converterstartedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> endedAt =
      GeneratedColumn<int>(
        'ended_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($RingEventsTable.$converterendedAt);
  @override
  late final GeneratedColumnWithTypeConverter<RingAction, String> action =
      GeneratedColumn<String>(
        'action',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RingAction>($RingEventsTable.$converteraction);
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    position,
    soundId,
    startedAt,
    endedAt,
    action,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ring_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<RingEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('sound_id')) {
      context.handle(
        _soundIdMeta,
        soundId.isAcceptableOrUnknown(data['sound_id']!, _soundIdMeta),
      );
    } else if (isInserting) {
      context.missing(_soundIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId, position};
  @override
  RingEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RingEventRow(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      soundId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sound_id'],
      )!,
      startedAt: $RingEventsTable.$converterstartedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}started_at'],
        )!,
      ),
      endedAt: $RingEventsTable.$converterendedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}ended_at'],
        )!,
      ),
      action: $RingEventsTable.$converteraction.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}action'],
        )!,
      ),
    );
  }

  @override
  $RingEventsTable createAlias(String alias) {
    return $RingEventsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterstartedAt =
      const _TimeConverter();
  static TypeConverter<DateTime, int> $converterendedAt =
      const _TimeConverter();
  static JsonTypeConverter2<RingAction, String, String> $converteraction =
      const EnumNameConverter<RingAction>(RingAction.values);
}

class RingEventRow extends DataClass implements Insertable<RingEventRow> {
  final String sessionId;

  /// Where the event is in its session, from 0: the order the sounds played.
  /// The times cannot tell it when the clock jumped back during a ring.
  final int position;

  /// The `Sound.id`, without a foreign key: the ring history stays when the
  /// sound is deleted.
  final String soundId;

  /// In microseconds since 1970 UTC.
  final DateTime startedAt;

  /// In microseconds since 1970 UTC.
  final DateTime endedAt;
  final RingAction action;
  const RingEventRow({
    required this.sessionId,
    required this.position,
    required this.soundId,
    required this.startedAt,
    required this.endedAt,
    required this.action,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['position'] = Variable<int>(position);
    map['sound_id'] = Variable<String>(soundId);
    {
      map['started_at'] = Variable<int>(
        $RingEventsTable.$converterstartedAt.toSql(startedAt),
      );
    }
    {
      map['ended_at'] = Variable<int>(
        $RingEventsTable.$converterendedAt.toSql(endedAt),
      );
    }
    {
      map['action'] = Variable<String>(
        $RingEventsTable.$converteraction.toSql(action),
      );
    }
    return map;
  }

  RingEventsCompanion toCompanion(bool nullToAbsent) {
    return RingEventsCompanion(
      sessionId: Value(sessionId),
      position: Value(position),
      soundId: Value(soundId),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
      action: Value(action),
    );
  }

  factory RingEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RingEventRow(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      position: serializer.fromJson<int>(json['position']),
      soundId: serializer.fromJson<String>(json['soundId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime>(json['endedAt']),
      action: $RingEventsTable.$converteraction.fromJson(
        serializer.fromJson<String>(json['action']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'position': serializer.toJson<int>(position),
      'soundId': serializer.toJson<String>(soundId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime>(endedAt),
      'action': serializer.toJson<String>(
        $RingEventsTable.$converteraction.toJson(action),
      ),
    };
  }

  RingEventRow copyWith({
    String? sessionId,
    int? position,
    String? soundId,
    DateTime? startedAt,
    DateTime? endedAt,
    RingAction? action,
  }) => RingEventRow(
    sessionId: sessionId ?? this.sessionId,
    position: position ?? this.position,
    soundId: soundId ?? this.soundId,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    action: action ?? this.action,
  );
  RingEventRow copyWithCompanion(RingEventsCompanion data) {
    return RingEventRow(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      position: data.position.present ? data.position.value : this.position,
      soundId: data.soundId.present ? data.soundId.value : this.soundId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      action: data.action.present ? data.action.value : this.action,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RingEventRow(')
          ..write('sessionId: $sessionId, ')
          ..write('position: $position, ')
          ..write('soundId: $soundId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('action: $action')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(sessionId, position, soundId, startedAt, endedAt, action);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RingEventRow &&
          other.sessionId == this.sessionId &&
          other.position == this.position &&
          other.soundId == this.soundId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.action == this.action);
}

class RingEventsCompanion extends UpdateCompanion<RingEventRow> {
  final Value<String> sessionId;
  final Value<int> position;
  final Value<String> soundId;
  final Value<DateTime> startedAt;
  final Value<DateTime> endedAt;
  final Value<RingAction> action;
  final Value<int> rowid;
  const RingEventsCompanion({
    this.sessionId = const Value.absent(),
    this.position = const Value.absent(),
    this.soundId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.action = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RingEventsCompanion.insert({
    required String sessionId,
    required int position,
    required String soundId,
    required DateTime startedAt,
    required DateTime endedAt,
    required RingAction action,
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       position = Value(position),
       soundId = Value(soundId),
       startedAt = Value(startedAt),
       endedAt = Value(endedAt),
       action = Value(action);
  static Insertable<RingEventRow> custom({
    Expression<String>? sessionId,
    Expression<int>? position,
    Expression<String>? soundId,
    Expression<int>? startedAt,
    Expression<int>? endedAt,
    Expression<String>? action,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (position != null) 'position': position,
      if (soundId != null) 'sound_id': soundId,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (action != null) 'action': action,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RingEventsCompanion copyWith({
    Value<String>? sessionId,
    Value<int>? position,
    Value<String>? soundId,
    Value<DateTime>? startedAt,
    Value<DateTime>? endedAt,
    Value<RingAction>? action,
    Value<int>? rowid,
  }) {
    return RingEventsCompanion(
      sessionId: sessionId ?? this.sessionId,
      position: position ?? this.position,
      soundId: soundId ?? this.soundId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      action: action ?? this.action,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (soundId.present) {
      map['sound_id'] = Variable<String>(soundId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(
        $RingEventsTable.$converterstartedAt.toSql(startedAt.value),
      );
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<int>(
        $RingEventsTable.$converterendedAt.toSql(endedAt.value),
      );
    }
    if (action.present) {
      map['action'] = Variable<String>(
        $RingEventsTable.$converteraction.toSql(action.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RingEventsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('position: $position, ')
          ..write('soundId: $soundId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('action: $action, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RingPlansTable extends RingPlans
    with TableInfo<$RingPlansTable, RingPlanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RingPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _alarmIdMeta = const VerificationMeta(
    'alarmId',
  );
  @override
  late final GeneratedColumn<String> alarmId = GeneratedColumn<String>(
    'alarm_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES alarms (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> ringAt =
      GeneratedColumn<int>(
        'ring_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($RingPlansTable.$converterringAt);
  static const VerificationMeta _seedMeta = const VerificationMeta('seed');
  @override
  late final GeneratedColumn<int> seed = GeneratedColumn<int>(
    'seed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _soundIdsMeta = const VerificationMeta(
    'soundIds',
  );
  @override
  late final GeneratedColumn<String> soundIds = GeneratedColumn<String>(
    'sound_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notTonightMeta = const VerificationMeta(
    'notTonight',
  );
  @override
  late final GeneratedColumn<String> notTonight = GeneratedColumn<String>(
    'not_tonight',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    alarmId,
    ringAt,
    seed,
    soundIds,
    notTonight,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ring_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<RingPlanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('alarm_id')) {
      context.handle(
        _alarmIdMeta,
        alarmId.isAcceptableOrUnknown(data['alarm_id']!, _alarmIdMeta),
      );
    } else if (isInserting) {
      context.missing(_alarmIdMeta);
    }
    if (data.containsKey('seed')) {
      context.handle(
        _seedMeta,
        seed.isAcceptableOrUnknown(data['seed']!, _seedMeta),
      );
    } else if (isInserting) {
      context.missing(_seedMeta);
    }
    if (data.containsKey('sound_ids')) {
      context.handle(
        _soundIdsMeta,
        soundIds.isAcceptableOrUnknown(data['sound_ids']!, _soundIdsMeta),
      );
    } else if (isInserting) {
      context.missing(_soundIdsMeta);
    }
    if (data.containsKey('not_tonight')) {
      context.handle(
        _notTonightMeta,
        notTonight.isAcceptableOrUnknown(data['not_tonight']!, _notTonightMeta),
      );
    } else if (isInserting) {
      context.missing(_notTonightMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {alarmId, ringAt};
  @override
  RingPlanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RingPlanRow(
      alarmId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alarm_id'],
      )!,
      ringAt: $RingPlansTable.$converterringAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}ring_at'],
        )!,
      ),
      seed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seed'],
      )!,
      soundIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sound_ids'],
      )!,
      notTonight: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}not_tonight'],
      )!,
    );
  }

  @override
  $RingPlansTable createAlias(String alias) {
    return $RingPlansTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterringAt = const _TimeConverter();
}

class RingPlanRow extends DataClass implements Insertable<RingPlanRow> {
  final String alarmId;

  /// In microseconds since 1970 UTC.
  final DateTime ringAt;
  final int seed;

  /// A JSON list in play order, such as `["warm-tape","mom"]`. The sounds have
  /// no foreign key: a plan stays when one is deleted, and the ring skips it.
  /// Plain text, not a converter: a row that cannot be read then counts as no
  /// plan, and does not fail the query (`RingPlanRepository`).
  final String soundIds;

  /// A JSON list, like [soundIds].
  final String notTonight;
  const RingPlanRow({
    required this.alarmId,
    required this.ringAt,
    required this.seed,
    required this.soundIds,
    required this.notTonight,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['alarm_id'] = Variable<String>(alarmId);
    {
      map['ring_at'] = Variable<int>(
        $RingPlansTable.$converterringAt.toSql(ringAt),
      );
    }
    map['seed'] = Variable<int>(seed);
    map['sound_ids'] = Variable<String>(soundIds);
    map['not_tonight'] = Variable<String>(notTonight);
    return map;
  }

  RingPlansCompanion toCompanion(bool nullToAbsent) {
    return RingPlansCompanion(
      alarmId: Value(alarmId),
      ringAt: Value(ringAt),
      seed: Value(seed),
      soundIds: Value(soundIds),
      notTonight: Value(notTonight),
    );
  }

  factory RingPlanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RingPlanRow(
      alarmId: serializer.fromJson<String>(json['alarmId']),
      ringAt: serializer.fromJson<DateTime>(json['ringAt']),
      seed: serializer.fromJson<int>(json['seed']),
      soundIds: serializer.fromJson<String>(json['soundIds']),
      notTonight: serializer.fromJson<String>(json['notTonight']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'alarmId': serializer.toJson<String>(alarmId),
      'ringAt': serializer.toJson<DateTime>(ringAt),
      'seed': serializer.toJson<int>(seed),
      'soundIds': serializer.toJson<String>(soundIds),
      'notTonight': serializer.toJson<String>(notTonight),
    };
  }

  RingPlanRow copyWith({
    String? alarmId,
    DateTime? ringAt,
    int? seed,
    String? soundIds,
    String? notTonight,
  }) => RingPlanRow(
    alarmId: alarmId ?? this.alarmId,
    ringAt: ringAt ?? this.ringAt,
    seed: seed ?? this.seed,
    soundIds: soundIds ?? this.soundIds,
    notTonight: notTonight ?? this.notTonight,
  );
  RingPlanRow copyWithCompanion(RingPlansCompanion data) {
    return RingPlanRow(
      alarmId: data.alarmId.present ? data.alarmId.value : this.alarmId,
      ringAt: data.ringAt.present ? data.ringAt.value : this.ringAt,
      seed: data.seed.present ? data.seed.value : this.seed,
      soundIds: data.soundIds.present ? data.soundIds.value : this.soundIds,
      notTonight: data.notTonight.present
          ? data.notTonight.value
          : this.notTonight,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RingPlanRow(')
          ..write('alarmId: $alarmId, ')
          ..write('ringAt: $ringAt, ')
          ..write('seed: $seed, ')
          ..write('soundIds: $soundIds, ')
          ..write('notTonight: $notTonight')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(alarmId, ringAt, seed, soundIds, notTonight);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RingPlanRow &&
          other.alarmId == this.alarmId &&
          other.ringAt == this.ringAt &&
          other.seed == this.seed &&
          other.soundIds == this.soundIds &&
          other.notTonight == this.notTonight);
}

class RingPlansCompanion extends UpdateCompanion<RingPlanRow> {
  final Value<String> alarmId;
  final Value<DateTime> ringAt;
  final Value<int> seed;
  final Value<String> soundIds;
  final Value<String> notTonight;
  final Value<int> rowid;
  const RingPlansCompanion({
    this.alarmId = const Value.absent(),
    this.ringAt = const Value.absent(),
    this.seed = const Value.absent(),
    this.soundIds = const Value.absent(),
    this.notTonight = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RingPlansCompanion.insert({
    required String alarmId,
    required DateTime ringAt,
    required int seed,
    required String soundIds,
    required String notTonight,
    this.rowid = const Value.absent(),
  }) : alarmId = Value(alarmId),
       ringAt = Value(ringAt),
       seed = Value(seed),
       soundIds = Value(soundIds),
       notTonight = Value(notTonight);
  static Insertable<RingPlanRow> custom({
    Expression<String>? alarmId,
    Expression<int>? ringAt,
    Expression<int>? seed,
    Expression<String>? soundIds,
    Expression<String>? notTonight,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (alarmId != null) 'alarm_id': alarmId,
      if (ringAt != null) 'ring_at': ringAt,
      if (seed != null) 'seed': seed,
      if (soundIds != null) 'sound_ids': soundIds,
      if (notTonight != null) 'not_tonight': notTonight,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RingPlansCompanion copyWith({
    Value<String>? alarmId,
    Value<DateTime>? ringAt,
    Value<int>? seed,
    Value<String>? soundIds,
    Value<String>? notTonight,
    Value<int>? rowid,
  }) {
    return RingPlansCompanion(
      alarmId: alarmId ?? this.alarmId,
      ringAt: ringAt ?? this.ringAt,
      seed: seed ?? this.seed,
      soundIds: soundIds ?? this.soundIds,
      notTonight: notTonight ?? this.notTonight,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (alarmId.present) {
      map['alarm_id'] = Variable<String>(alarmId.value);
    }
    if (ringAt.present) {
      map['ring_at'] = Variable<int>(
        $RingPlansTable.$converterringAt.toSql(ringAt.value),
      );
    }
    if (seed.present) {
      map['seed'] = Variable<int>(seed.value);
    }
    if (soundIds.present) {
      map['sound_ids'] = Variable<String>(soundIds.value);
    }
    if (notTonight.present) {
      map['not_tonight'] = Variable<String>(notTonight.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RingPlansCompanion(')
          ..write('alarmId: $alarmId, ')
          ..write('ringAt: $ringAt, ')
          ..write('seed: $seed, ')
          ..write('soundIds: $soundIds, ')
          ..write('notTonight: $notTonight, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $AlarmsTable alarms = $AlarmsTable(this);
  late final $SoundsTable sounds = $SoundsTable(this);
  late final $WeightsTable weights = $WeightsTable(this);
  late final $RingSessionsTable ringSessions = $RingSessionsTable(this);
  late final $RingEventsTable ringEvents = $RingEventsTable(this);
  late final $RingPlansTable ringPlans = $RingPlansTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    alarms,
    sounds,
    weights,
    ringSessions,
    ringEvents,
    ringPlans,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sounds',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('weights', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'ring_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ring_events', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'alarms',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ring_plans', kind: UpdateKind.delete)],
    ),
  ]);
}
