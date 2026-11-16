// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LessonProgressTable extends LessonProgress
    with TableInfo<$LessonProgressTable, LessonProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LessonProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _lessonIdMeta = const VerificationMeta(
    'lessonId',
  );
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
    'lesson_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bestScoreMeta = const VerificationMeta(
    'bestScore',
  );
  @override
  late final GeneratedColumn<double> bestScore = GeneratedColumn<double>(
    'best_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastScoreMeta = const VerificationMeta(
    'lastScore',
  );
  @override
  late final GeneratedColumn<double> lastScore = GeneratedColumn<double>(
    'last_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _completionsMeta = const VerificationMeta(
    'completions',
  );
  @override
  late final GeneratedColumn<int> completions = GeneratedColumn<int>(
    'completions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstCompletedAtMeta = const VerificationMeta(
    'firstCompletedAt',
  );
  @override
  late final GeneratedColumn<int> firstCompletedAt = GeneratedColumn<int>(
    'first_completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastCompletedAtMeta = const VerificationMeta(
    'lastCompletedAt',
  );
  @override
  late final GeneratedColumn<int> lastCompletedAt = GeneratedColumn<int>(
    'last_completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentVersionMeta = const VerificationMeta(
    'contentVersion',
  );
  @override
  late final GeneratedColumn<String> contentVersion = GeneratedColumn<String>(
    'content_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    lessonId,
    status,
    bestScore,
    lastScore,
    completions,
    startedAt,
    firstCompletedAt,
    lastCompletedAt,
    contentVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lesson_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<LessonProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('lesson_id')) {
      context.handle(
        _lessonIdMeta,
        lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('best_score')) {
      context.handle(
        _bestScoreMeta,
        bestScore.isAcceptableOrUnknown(data['best_score']!, _bestScoreMeta),
      );
    }
    if (data.containsKey('last_score')) {
      context.handle(
        _lastScoreMeta,
        lastScore.isAcceptableOrUnknown(data['last_score']!, _lastScoreMeta),
      );
    }
    if (data.containsKey('completions')) {
      context.handle(
        _completionsMeta,
        completions.isAcceptableOrUnknown(
          data['completions']!,
          _completionsMeta,
        ),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('first_completed_at')) {
      context.handle(
        _firstCompletedAtMeta,
        firstCompletedAt.isAcceptableOrUnknown(
          data['first_completed_at']!,
          _firstCompletedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_completed_at')) {
      context.handle(
        _lastCompletedAtMeta,
        lastCompletedAt.isAcceptableOrUnknown(
          data['last_completed_at']!,
          _lastCompletedAtMeta,
        ),
      );
    }
    if (data.containsKey('content_version')) {
      context.handle(
        _contentVersionMeta,
        contentVersion.isAcceptableOrUnknown(
          data['content_version']!,
          _contentVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {lessonId};
  @override
  LessonProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LessonProgressData(
      lessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lesson_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      bestScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}best_score'],
      )!,
      lastScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}last_score'],
      )!,
      completions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completions'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      )!,
      firstCompletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}first_completed_at'],
      ),
      lastCompletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_completed_at'],
      ),
      contentVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_version'],
      )!,
    );
  }

  @override
  $LessonProgressTable createAlias(String alias) {
    return $LessonProgressTable(attachedDatabase, alias);
  }
}

class LessonProgressData extends DataClass
    implements Insertable<LessonProgressData> {
  final String lessonId;

  /// `started` or `completed`.
  final String status;

  /// Best first-try accuracy (0..1) over all completed runs.
  final double bestScore;
  final double lastScore;
  final int completions;
  final int startedAt;
  final int? firstCompletedAt;
  final int? lastCompletedAt;

  /// Content version the lesson was completed against.
  final String contentVersion;
  const LessonProgressData({
    required this.lessonId,
    required this.status,
    required this.bestScore,
    required this.lastScore,
    required this.completions,
    required this.startedAt,
    this.firstCompletedAt,
    this.lastCompletedAt,
    required this.contentVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['lesson_id'] = Variable<String>(lessonId);
    map['status'] = Variable<String>(status);
    map['best_score'] = Variable<double>(bestScore);
    map['last_score'] = Variable<double>(lastScore);
    map['completions'] = Variable<int>(completions);
    map['started_at'] = Variable<int>(startedAt);
    if (!nullToAbsent || firstCompletedAt != null) {
      map['first_completed_at'] = Variable<int>(firstCompletedAt);
    }
    if (!nullToAbsent || lastCompletedAt != null) {
      map['last_completed_at'] = Variable<int>(lastCompletedAt);
    }
    map['content_version'] = Variable<String>(contentVersion);
    return map;
  }

  LessonProgressCompanion toCompanion(bool nullToAbsent) {
    return LessonProgressCompanion(
      lessonId: Value(lessonId),
      status: Value(status),
      bestScore: Value(bestScore),
      lastScore: Value(lastScore),
      completions: Value(completions),
      startedAt: Value(startedAt),
      firstCompletedAt: firstCompletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(firstCompletedAt),
      lastCompletedAt: lastCompletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCompletedAt),
      contentVersion: Value(contentVersion),
    );
  }

  factory LessonProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LessonProgressData(
      lessonId: serializer.fromJson<String>(json['lessonId']),
      status: serializer.fromJson<String>(json['status']),
      bestScore: serializer.fromJson<double>(json['bestScore']),
      lastScore: serializer.fromJson<double>(json['lastScore']),
      completions: serializer.fromJson<int>(json['completions']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      firstCompletedAt: serializer.fromJson<int?>(json['firstCompletedAt']),
      lastCompletedAt: serializer.fromJson<int?>(json['lastCompletedAt']),
      contentVersion: serializer.fromJson<String>(json['contentVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lessonId': serializer.toJson<String>(lessonId),
      'status': serializer.toJson<String>(status),
      'bestScore': serializer.toJson<double>(bestScore),
      'lastScore': serializer.toJson<double>(lastScore),
      'completions': serializer.toJson<int>(completions),
      'startedAt': serializer.toJson<int>(startedAt),
      'firstCompletedAt': serializer.toJson<int?>(firstCompletedAt),
      'lastCompletedAt': serializer.toJson<int?>(lastCompletedAt),
      'contentVersion': serializer.toJson<String>(contentVersion),
    };
  }

  LessonProgressData copyWith({
    String? lessonId,
    String? status,
    double? bestScore,
    double? lastScore,
    int? completions,
    int? startedAt,
    Value<int?> firstCompletedAt = const Value.absent(),
    Value<int?> lastCompletedAt = const Value.absent(),
    String? contentVersion,
  }) => LessonProgressData(
    lessonId: lessonId ?? this.lessonId,
    status: status ?? this.status,
    bestScore: bestScore ?? this.bestScore,
    lastScore: lastScore ?? this.lastScore,
    completions: completions ?? this.completions,
    startedAt: startedAt ?? this.startedAt,
    firstCompletedAt: firstCompletedAt.present
        ? firstCompletedAt.value
        : this.firstCompletedAt,
    lastCompletedAt: lastCompletedAt.present
        ? lastCompletedAt.value
        : this.lastCompletedAt,
    contentVersion: contentVersion ?? this.contentVersion,
  );
  LessonProgressData copyWithCompanion(LessonProgressCompanion data) {
    return LessonProgressData(
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      status: data.status.present ? data.status.value : this.status,
      bestScore: data.bestScore.present ? data.bestScore.value : this.bestScore,
      lastScore: data.lastScore.present ? data.lastScore.value : this.lastScore,
      completions: data.completions.present
          ? data.completions.value
          : this.completions,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      firstCompletedAt: data.firstCompletedAt.present
          ? data.firstCompletedAt.value
          : this.firstCompletedAt,
      lastCompletedAt: data.lastCompletedAt.present
          ? data.lastCompletedAt.value
          : this.lastCompletedAt,
      contentVersion: data.contentVersion.present
          ? data.contentVersion.value
          : this.contentVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LessonProgressData(')
          ..write('lessonId: $lessonId, ')
          ..write('status: $status, ')
          ..write('bestScore: $bestScore, ')
          ..write('lastScore: $lastScore, ')
          ..write('completions: $completions, ')
          ..write('startedAt: $startedAt, ')
          ..write('firstCompletedAt: $firstCompletedAt, ')
          ..write('lastCompletedAt: $lastCompletedAt, ')
          ..write('contentVersion: $contentVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    lessonId,
    status,
    bestScore,
    lastScore,
    completions,
    startedAt,
    firstCompletedAt,
    lastCompletedAt,
    contentVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LessonProgressData &&
          other.lessonId == this.lessonId &&
          other.status == this.status &&
          other.bestScore == this.bestScore &&
          other.lastScore == this.lastScore &&
          other.completions == this.completions &&
          other.startedAt == this.startedAt &&
          other.firstCompletedAt == this.firstCompletedAt &&
          other.lastCompletedAt == this.lastCompletedAt &&
          other.contentVersion == this.contentVersion);
}

class LessonProgressCompanion extends UpdateCompanion<LessonProgressData> {
  final Value<String> lessonId;
  final Value<String> status;
  final Value<double> bestScore;
  final Value<double> lastScore;
  final Value<int> completions;
  final Value<int> startedAt;
  final Value<int?> firstCompletedAt;
  final Value<int?> lastCompletedAt;
  final Value<String> contentVersion;
  final Value<int> rowid;
  const LessonProgressCompanion({
    this.lessonId = const Value.absent(),
    this.status = const Value.absent(),
    this.bestScore = const Value.absent(),
    this.lastScore = const Value.absent(),
    this.completions = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.firstCompletedAt = const Value.absent(),
    this.lastCompletedAt = const Value.absent(),
    this.contentVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LessonProgressCompanion.insert({
    required String lessonId,
    required String status,
    this.bestScore = const Value.absent(),
    this.lastScore = const Value.absent(),
    this.completions = const Value.absent(),
    required int startedAt,
    this.firstCompletedAt = const Value.absent(),
    this.lastCompletedAt = const Value.absent(),
    this.contentVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : lessonId = Value(lessonId),
       status = Value(status),
       startedAt = Value(startedAt);
  static Insertable<LessonProgressData> custom({
    Expression<String>? lessonId,
    Expression<String>? status,
    Expression<double>? bestScore,
    Expression<double>? lastScore,
    Expression<int>? completions,
    Expression<int>? startedAt,
    Expression<int>? firstCompletedAt,
    Expression<int>? lastCompletedAt,
    Expression<String>? contentVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lessonId != null) 'lesson_id': lessonId,
      if (status != null) 'status': status,
      if (bestScore != null) 'best_score': bestScore,
      if (lastScore != null) 'last_score': lastScore,
      if (completions != null) 'completions': completions,
      if (startedAt != null) 'started_at': startedAt,
      if (firstCompletedAt != null) 'first_completed_at': firstCompletedAt,
      if (lastCompletedAt != null) 'last_completed_at': lastCompletedAt,
      if (contentVersion != null) 'content_version': contentVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LessonProgressCompanion copyWith({
    Value<String>? lessonId,
    Value<String>? status,
    Value<double>? bestScore,
    Value<double>? lastScore,
    Value<int>? completions,
    Value<int>? startedAt,
    Value<int?>? firstCompletedAt,
    Value<int?>? lastCompletedAt,
    Value<String>? contentVersion,
    Value<int>? rowid,
  }) {
    return LessonProgressCompanion(
      lessonId: lessonId ?? this.lessonId,
      status: status ?? this.status,
      bestScore: bestScore ?? this.bestScore,
      lastScore: lastScore ?? this.lastScore,
      completions: completions ?? this.completions,
      startedAt: startedAt ?? this.startedAt,
      firstCompletedAt: firstCompletedAt ?? this.firstCompletedAt,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      contentVersion: contentVersion ?? this.contentVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (bestScore.present) {
      map['best_score'] = Variable<double>(bestScore.value);
    }
    if (lastScore.present) {
      map['last_score'] = Variable<double>(lastScore.value);
    }
    if (completions.present) {
      map['completions'] = Variable<int>(completions.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (firstCompletedAt.present) {
      map['first_completed_at'] = Variable<int>(firstCompletedAt.value);
    }
    if (lastCompletedAt.present) {
      map['last_completed_at'] = Variable<int>(lastCompletedAt.value);
    }
    if (contentVersion.present) {
      map['content_version'] = Variable<String>(contentVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonProgressCompanion(')
          ..write('lessonId: $lessonId, ')
          ..write('status: $status, ')
          ..write('bestScore: $bestScore, ')
          ..write('lastScore: $lastScore, ')
          ..write('completions: $completions, ')
          ..write('startedAt: $startedAt, ')
          ..write('firstCompletedAt: $firstCompletedAt, ')
          ..write('lastCompletedAt: $lastCompletedAt, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ActivityAttemptsTable extends ActivityAttempts
    with TableInfo<$ActivityAttemptsTable, ActivityAttempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivityAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _activityIdMeta = const VerificationMeta(
    'activityId',
  );
  @override
  late final GeneratedColumn<String> activityId = GeneratedColumn<String>(
    'activity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lessonIdMeta = const VerificationMeta(
    'lessonId',
  );
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
    'lesson_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _skillMeta = const VerificationMeta('skill');
  @override
  late final GeneratedColumn<String> skill = GeneratedColumn<String>(
    'skill',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseTypeMeta = const VerificationMeta(
    'exerciseType',
  );
  @override
  late final GeneratedColumn<String> exerciseType = GeneratedColumn<String>(
    'exercise_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contextMeta = const VerificationMeta(
    'context',
  );
  @override
  late final GeneratedColumn<String> context = GeneratedColumn<String>(
    'context',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCorrectMeta = const VerificationMeta(
    'isCorrect',
  );
  @override
  late final GeneratedColumn<bool> isCorrect = GeneratedColumn<bool>(
    'is_correct',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_correct" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isMeasuredMeta = const VerificationMeta(
    'isMeasured',
  );
  @override
  late final GeneratedColumn<bool> isMeasured = GeneratedColumn<bool>(
    'is_measured',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_measured" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _userAnswerMeta = const VerificationMeta(
    'userAnswer',
  );
  @override
  late final GeneratedColumn<String> userAnswer = GeneratedColumn<String>(
    'user_answer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _expectedMeta = const VerificationMeta(
    'expected',
  );
  @override
  late final GeneratedColumn<String> expected = GeneratedColumn<String>(
    'expected',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    activityId,
    lessonId,
    itemId,
    skill,
    exerciseType,
    context,
    isCorrect,
    isMeasured,
    userAnswer,
    expected,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activity_attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActivityAttempt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('activity_id')) {
      context.handle(
        _activityIdMeta,
        activityId.isAcceptableOrUnknown(data['activity_id']!, _activityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_activityIdMeta);
    }
    if (data.containsKey('lesson_id')) {
      context.handle(
        _lessonIdMeta,
        lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta),
      );
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    }
    if (data.containsKey('skill')) {
      context.handle(
        _skillMeta,
        skill.isAcceptableOrUnknown(data['skill']!, _skillMeta),
      );
    } else if (isInserting) {
      context.missing(_skillMeta);
    }
    if (data.containsKey('exercise_type')) {
      context.handle(
        _exerciseTypeMeta,
        exerciseType.isAcceptableOrUnknown(
          data['exercise_type']!,
          _exerciseTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exerciseTypeMeta);
    }
    if (data.containsKey('context')) {
      context.handle(
        _contextMeta,
        this.context.isAcceptableOrUnknown(data['context']!, _contextMeta),
      );
    } else if (isInserting) {
      context.missing(_contextMeta);
    }
    if (data.containsKey('is_correct')) {
      context.handle(
        _isCorrectMeta,
        isCorrect.isAcceptableOrUnknown(data['is_correct']!, _isCorrectMeta),
      );
    } else if (isInserting) {
      context.missing(_isCorrectMeta);
    }
    if (data.containsKey('is_measured')) {
      context.handle(
        _isMeasuredMeta,
        isMeasured.isAcceptableOrUnknown(data['is_measured']!, _isMeasuredMeta),
      );
    }
    if (data.containsKey('user_answer')) {
      context.handle(
        _userAnswerMeta,
        userAnswer.isAcceptableOrUnknown(data['user_answer']!, _userAnswerMeta),
      );
    }
    if (data.containsKey('expected')) {
      context.handle(
        _expectedMeta,
        expected.isAcceptableOrUnknown(data['expected']!, _expectedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActivityAttempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityAttempt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      activityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_id'],
      )!,
      lessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lesson_id'],
      ),
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      ),
      skill: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}skill'],
      )!,
      exerciseType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_type'],
      )!,
      context: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context'],
      )!,
      isCorrect: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_correct'],
      )!,
      isMeasured: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_measured'],
      )!,
      userAnswer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_answer'],
      )!,
      expected: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expected'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ActivityAttemptsTable createAlias(String alias) {
    return $ActivityAttemptsTable(attachedDatabase, alias);
  }
}

class ActivityAttempt extends DataClass implements Insertable<ActivityAttempt> {
  final int id;
  final String activityId;
  final String? lessonId;
  final String? itemId;

  /// reading | listening | writing | speaking | vocabulary | grammar
  final String skill;
  final String exerciseType;

  /// lesson | practice
  final String context;
  final bool isCorrect;

  /// False for self-assessed activities (e.g. listen-and-repeat) that must
  /// never count as measured accuracy.
  final bool isMeasured;
  final String userAnswer;
  final String expected;
  final int createdAt;
  const ActivityAttempt({
    required this.id,
    required this.activityId,
    this.lessonId,
    this.itemId,
    required this.skill,
    required this.exerciseType,
    required this.context,
    required this.isCorrect,
    required this.isMeasured,
    required this.userAnswer,
    required this.expected,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['activity_id'] = Variable<String>(activityId);
    if (!nullToAbsent || lessonId != null) {
      map['lesson_id'] = Variable<String>(lessonId);
    }
    if (!nullToAbsent || itemId != null) {
      map['item_id'] = Variable<String>(itemId);
    }
    map['skill'] = Variable<String>(skill);
    map['exercise_type'] = Variable<String>(exerciseType);
    map['context'] = Variable<String>(context);
    map['is_correct'] = Variable<bool>(isCorrect);
    map['is_measured'] = Variable<bool>(isMeasured);
    map['user_answer'] = Variable<String>(userAnswer);
    map['expected'] = Variable<String>(expected);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  ActivityAttemptsCompanion toCompanion(bool nullToAbsent) {
    return ActivityAttemptsCompanion(
      id: Value(id),
      activityId: Value(activityId),
      lessonId: lessonId == null && nullToAbsent
          ? const Value.absent()
          : Value(lessonId),
      itemId: itemId == null && nullToAbsent
          ? const Value.absent()
          : Value(itemId),
      skill: Value(skill),
      exerciseType: Value(exerciseType),
      context: Value(context),
      isCorrect: Value(isCorrect),
      isMeasured: Value(isMeasured),
      userAnswer: Value(userAnswer),
      expected: Value(expected),
      createdAt: Value(createdAt),
    );
  }

  factory ActivityAttempt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityAttempt(
      id: serializer.fromJson<int>(json['id']),
      activityId: serializer.fromJson<String>(json['activityId']),
      lessonId: serializer.fromJson<String?>(json['lessonId']),
      itemId: serializer.fromJson<String?>(json['itemId']),
      skill: serializer.fromJson<String>(json['skill']),
      exerciseType: serializer.fromJson<String>(json['exerciseType']),
      context: serializer.fromJson<String>(json['context']),
      isCorrect: serializer.fromJson<bool>(json['isCorrect']),
      isMeasured: serializer.fromJson<bool>(json['isMeasured']),
      userAnswer: serializer.fromJson<String>(json['userAnswer']),
      expected: serializer.fromJson<String>(json['expected']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'activityId': serializer.toJson<String>(activityId),
      'lessonId': serializer.toJson<String?>(lessonId),
      'itemId': serializer.toJson<String?>(itemId),
      'skill': serializer.toJson<String>(skill),
      'exerciseType': serializer.toJson<String>(exerciseType),
      'context': serializer.toJson<String>(context),
      'isCorrect': serializer.toJson<bool>(isCorrect),
      'isMeasured': serializer.toJson<bool>(isMeasured),
      'userAnswer': serializer.toJson<String>(userAnswer),
      'expected': serializer.toJson<String>(expected),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  ActivityAttempt copyWith({
    int? id,
    String? activityId,
    Value<String?> lessonId = const Value.absent(),
    Value<String?> itemId = const Value.absent(),
    String? skill,
    String? exerciseType,
    String? context,
    bool? isCorrect,
    bool? isMeasured,
    String? userAnswer,
    String? expected,
    int? createdAt,
  }) => ActivityAttempt(
    id: id ?? this.id,
    activityId: activityId ?? this.activityId,
    lessonId: lessonId.present ? lessonId.value : this.lessonId,
    itemId: itemId.present ? itemId.value : this.itemId,
    skill: skill ?? this.skill,
    exerciseType: exerciseType ?? this.exerciseType,
    context: context ?? this.context,
    isCorrect: isCorrect ?? this.isCorrect,
    isMeasured: isMeasured ?? this.isMeasured,
    userAnswer: userAnswer ?? this.userAnswer,
    expected: expected ?? this.expected,
    createdAt: createdAt ?? this.createdAt,
  );
  ActivityAttempt copyWithCompanion(ActivityAttemptsCompanion data) {
    return ActivityAttempt(
      id: data.id.present ? data.id.value : this.id,
      activityId: data.activityId.present
          ? data.activityId.value
          : this.activityId,
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      skill: data.skill.present ? data.skill.value : this.skill,
      exerciseType: data.exerciseType.present
          ? data.exerciseType.value
          : this.exerciseType,
      context: data.context.present ? data.context.value : this.context,
      isCorrect: data.isCorrect.present ? data.isCorrect.value : this.isCorrect,
      isMeasured: data.isMeasured.present
          ? data.isMeasured.value
          : this.isMeasured,
      userAnswer: data.userAnswer.present
          ? data.userAnswer.value
          : this.userAnswer,
      expected: data.expected.present ? data.expected.value : this.expected,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityAttempt(')
          ..write('id: $id, ')
          ..write('activityId: $activityId, ')
          ..write('lessonId: $lessonId, ')
          ..write('itemId: $itemId, ')
          ..write('skill: $skill, ')
          ..write('exerciseType: $exerciseType, ')
          ..write('context: $context, ')
          ..write('isCorrect: $isCorrect, ')
          ..write('isMeasured: $isMeasured, ')
          ..write('userAnswer: $userAnswer, ')
          ..write('expected: $expected, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    activityId,
    lessonId,
    itemId,
    skill,
    exerciseType,
    context,
    isCorrect,
    isMeasured,
    userAnswer,
    expected,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityAttempt &&
          other.id == this.id &&
          other.activityId == this.activityId &&
          other.lessonId == this.lessonId &&
          other.itemId == this.itemId &&
          other.skill == this.skill &&
          other.exerciseType == this.exerciseType &&
          other.context == this.context &&
          other.isCorrect == this.isCorrect &&
          other.isMeasured == this.isMeasured &&
          other.userAnswer == this.userAnswer &&
          other.expected == this.expected &&
          other.createdAt == this.createdAt);
}

class ActivityAttemptsCompanion extends UpdateCompanion<ActivityAttempt> {
  final Value<int> id;
  final Value<String> activityId;
  final Value<String?> lessonId;
  final Value<String?> itemId;
  final Value<String> skill;
  final Value<String> exerciseType;
  final Value<String> context;
  final Value<bool> isCorrect;
  final Value<bool> isMeasured;
  final Value<String> userAnswer;
  final Value<String> expected;
  final Value<int> createdAt;
  const ActivityAttemptsCompanion({
    this.id = const Value.absent(),
    this.activityId = const Value.absent(),
    this.lessonId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.skill = const Value.absent(),
    this.exerciseType = const Value.absent(),
    this.context = const Value.absent(),
    this.isCorrect = const Value.absent(),
    this.isMeasured = const Value.absent(),
    this.userAnswer = const Value.absent(),
    this.expected = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ActivityAttemptsCompanion.insert({
    this.id = const Value.absent(),
    required String activityId,
    this.lessonId = const Value.absent(),
    this.itemId = const Value.absent(),
    required String skill,
    required String exerciseType,
    required String context,
    required bool isCorrect,
    this.isMeasured = const Value.absent(),
    this.userAnswer = const Value.absent(),
    this.expected = const Value.absent(),
    required int createdAt,
  }) : activityId = Value(activityId),
       skill = Value(skill),
       exerciseType = Value(exerciseType),
       context = Value(context),
       isCorrect = Value(isCorrect),
       createdAt = Value(createdAt);
  static Insertable<ActivityAttempt> custom({
    Expression<int>? id,
    Expression<String>? activityId,
    Expression<String>? lessonId,
    Expression<String>? itemId,
    Expression<String>? skill,
    Expression<String>? exerciseType,
    Expression<String>? context,
    Expression<bool>? isCorrect,
    Expression<bool>? isMeasured,
    Expression<String>? userAnswer,
    Expression<String>? expected,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (activityId != null) 'activity_id': activityId,
      if (lessonId != null) 'lesson_id': lessonId,
      if (itemId != null) 'item_id': itemId,
      if (skill != null) 'skill': skill,
      if (exerciseType != null) 'exercise_type': exerciseType,
      if (context != null) 'context': context,
      if (isCorrect != null) 'is_correct': isCorrect,
      if (isMeasured != null) 'is_measured': isMeasured,
      if (userAnswer != null) 'user_answer': userAnswer,
      if (expected != null) 'expected': expected,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ActivityAttemptsCompanion copyWith({
    Value<int>? id,
    Value<String>? activityId,
    Value<String?>? lessonId,
    Value<String?>? itemId,
    Value<String>? skill,
    Value<String>? exerciseType,
    Value<String>? context,
    Value<bool>? isCorrect,
    Value<bool>? isMeasured,
    Value<String>? userAnswer,
    Value<String>? expected,
    Value<int>? createdAt,
  }) {
    return ActivityAttemptsCompanion(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      lessonId: lessonId ?? this.lessonId,
      itemId: itemId ?? this.itemId,
      skill: skill ?? this.skill,
      exerciseType: exerciseType ?? this.exerciseType,
      context: context ?? this.context,
      isCorrect: isCorrect ?? this.isCorrect,
      isMeasured: isMeasured ?? this.isMeasured,
      userAnswer: userAnswer ?? this.userAnswer,
      expected: expected ?? this.expected,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (activityId.present) {
      map['activity_id'] = Variable<String>(activityId.value);
    }
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (skill.present) {
      map['skill'] = Variable<String>(skill.value);
    }
    if (exerciseType.present) {
      map['exercise_type'] = Variable<String>(exerciseType.value);
    }
    if (context.present) {
      map['context'] = Variable<String>(context.value);
    }
    if (isCorrect.present) {
      map['is_correct'] = Variable<bool>(isCorrect.value);
    }
    if (isMeasured.present) {
      map['is_measured'] = Variable<bool>(isMeasured.value);
    }
    if (userAnswer.present) {
      map['user_answer'] = Variable<String>(userAnswer.value);
    }
    if (expected.present) {
      map['expected'] = Variable<String>(expected.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivityAttemptsCompanion(')
          ..write('id: $id, ')
          ..write('activityId: $activityId, ')
          ..write('lessonId: $lessonId, ')
          ..write('itemId: $itemId, ')
          ..write('skill: $skill, ')
          ..write('exerciseType: $exerciseType, ')
          ..write('context: $context, ')
          ..write('isCorrect: $isCorrect, ')
          ..write('isMeasured: $isMeasured, ')
          ..write('userAnswer: $userAnswer, ')
          ..write('expected: $expected, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ReviewCardsTable extends ReviewCards
    with TableInfo<$ReviewCardsTable, ReviewCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardTypeMeta = const VerificationMeta(
    'cardType',
  );
  @override
  late final GeneratedColumn<String> cardType = GeneratedColumn<String>(
    'card_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<int> state = GeneratedColumn<int>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _stepMeta = const VerificationMeta('step');
  @override
  late final GeneratedColumn<int> step = GeneratedColumn<int>(
    'step',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stabilityMeta = const VerificationMeta(
    'stability',
  );
  @override
  late final GeneratedColumn<double> stability = GeneratedColumn<double>(
    'stability',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<double> difficulty = GeneratedColumn<double>(
    'difficulty',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueMeta = const VerificationMeta('due');
  @override
  late final GeneratedColumn<int> due = GeneratedColumn<int>(
    'due',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastReviewMeta = const VerificationMeta(
    'lastReview',
  );
  @override
  late final GeneratedColumn<int> lastReview = GeneratedColumn<int>(
    'last_review',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lapsesMeta = const VerificationMeta('lapses');
  @override
  late final GeneratedColumn<int> lapses = GeneratedColumn<int>(
    'lapses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sourceLessonIdMeta = const VerificationMeta(
    'sourceLessonId',
  );
  @override
  late final GeneratedColumn<String> sourceLessonId = GeneratedColumn<String>(
    'source_lesson_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    cardType,
    state,
    step,
    stability,
    difficulty,
    due,
    lastReview,
    reps,
    lapses,
    sourceLessonId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewCard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('card_type')) {
      context.handle(
        _cardTypeMeta,
        cardType.isAcceptableOrUnknown(data['card_type']!, _cardTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_cardTypeMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('step')) {
      context.handle(
        _stepMeta,
        step.isAcceptableOrUnknown(data['step']!, _stepMeta),
      );
    }
    if (data.containsKey('stability')) {
      context.handle(
        _stabilityMeta,
        stability.isAcceptableOrUnknown(data['stability']!, _stabilityMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('due')) {
      context.handle(
        _dueMeta,
        due.isAcceptableOrUnknown(data['due']!, _dueMeta),
      );
    } else if (isInserting) {
      context.missing(_dueMeta);
    }
    if (data.containsKey('last_review')) {
      context.handle(
        _lastReviewMeta,
        lastReview.isAcceptableOrUnknown(data['last_review']!, _lastReviewMeta),
      );
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('lapses')) {
      context.handle(
        _lapsesMeta,
        lapses.isAcceptableOrUnknown(data['lapses']!, _lapsesMeta),
      );
    }
    if (data.containsKey('source_lesson_id')) {
      context.handle(
        _sourceLessonIdMeta,
        sourceLessonId.isAcceptableOrUnknown(
          data['source_lesson_id']!,
          _sourceLessonIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {itemId, cardType},
  ];
  @override
  ReviewCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewCard(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      cardType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_type'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}state'],
      )!,
      step: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}step'],
      ),
      stability: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stability'],
      ),
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}difficulty'],
      ),
      due: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due'],
      )!,
      lastReview: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_review'],
      ),
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      )!,
      lapses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lapses'],
      )!,
      sourceLessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_lesson_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ReviewCardsTable createAlias(String alias) {
    return $ReviewCardsTable(attachedDatabase, alias);
  }
}

class ReviewCard extends DataClass implements Insertable<ReviewCard> {
  final int id;
  final String itemId;

  /// `recognition` (Spanish → meaning) or `production` (Arabic → Spanish).
  final String cardType;

  /// FSRS state: 1 learning, 2 review, 3 relearning.
  final int state;
  final int? step;
  final double? stability;
  final double? difficulty;
  final int due;
  final int? lastReview;
  final int reps;
  final int lapses;
  final String? sourceLessonId;
  final int createdAt;
  const ReviewCard({
    required this.id,
    required this.itemId,
    required this.cardType,
    required this.state,
    this.step,
    this.stability,
    this.difficulty,
    required this.due,
    this.lastReview,
    required this.reps,
    required this.lapses,
    this.sourceLessonId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_id'] = Variable<String>(itemId);
    map['card_type'] = Variable<String>(cardType);
    map['state'] = Variable<int>(state);
    if (!nullToAbsent || step != null) {
      map['step'] = Variable<int>(step);
    }
    if (!nullToAbsent || stability != null) {
      map['stability'] = Variable<double>(stability);
    }
    if (!nullToAbsent || difficulty != null) {
      map['difficulty'] = Variable<double>(difficulty);
    }
    map['due'] = Variable<int>(due);
    if (!nullToAbsent || lastReview != null) {
      map['last_review'] = Variable<int>(lastReview);
    }
    map['reps'] = Variable<int>(reps);
    map['lapses'] = Variable<int>(lapses);
    if (!nullToAbsent || sourceLessonId != null) {
      map['source_lesson_id'] = Variable<String>(sourceLessonId);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  ReviewCardsCompanion toCompanion(bool nullToAbsent) {
    return ReviewCardsCompanion(
      id: Value(id),
      itemId: Value(itemId),
      cardType: Value(cardType),
      state: Value(state),
      step: step == null && nullToAbsent ? const Value.absent() : Value(step),
      stability: stability == null && nullToAbsent
          ? const Value.absent()
          : Value(stability),
      difficulty: difficulty == null && nullToAbsent
          ? const Value.absent()
          : Value(difficulty),
      due: Value(due),
      lastReview: lastReview == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReview),
      reps: Value(reps),
      lapses: Value(lapses),
      sourceLessonId: sourceLessonId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceLessonId),
      createdAt: Value(createdAt),
    );
  }

  factory ReviewCard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewCard(
      id: serializer.fromJson<int>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      cardType: serializer.fromJson<String>(json['cardType']),
      state: serializer.fromJson<int>(json['state']),
      step: serializer.fromJson<int?>(json['step']),
      stability: serializer.fromJson<double?>(json['stability']),
      difficulty: serializer.fromJson<double?>(json['difficulty']),
      due: serializer.fromJson<int>(json['due']),
      lastReview: serializer.fromJson<int?>(json['lastReview']),
      reps: serializer.fromJson<int>(json['reps']),
      lapses: serializer.fromJson<int>(json['lapses']),
      sourceLessonId: serializer.fromJson<String?>(json['sourceLessonId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemId': serializer.toJson<String>(itemId),
      'cardType': serializer.toJson<String>(cardType),
      'state': serializer.toJson<int>(state),
      'step': serializer.toJson<int?>(step),
      'stability': serializer.toJson<double?>(stability),
      'difficulty': serializer.toJson<double?>(difficulty),
      'due': serializer.toJson<int>(due),
      'lastReview': serializer.toJson<int?>(lastReview),
      'reps': serializer.toJson<int>(reps),
      'lapses': serializer.toJson<int>(lapses),
      'sourceLessonId': serializer.toJson<String?>(sourceLessonId),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  ReviewCard copyWith({
    int? id,
    String? itemId,
    String? cardType,
    int? state,
    Value<int?> step = const Value.absent(),
    Value<double?> stability = const Value.absent(),
    Value<double?> difficulty = const Value.absent(),
    int? due,
    Value<int?> lastReview = const Value.absent(),
    int? reps,
    int? lapses,
    Value<String?> sourceLessonId = const Value.absent(),
    int? createdAt,
  }) => ReviewCard(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    cardType: cardType ?? this.cardType,
    state: state ?? this.state,
    step: step.present ? step.value : this.step,
    stability: stability.present ? stability.value : this.stability,
    difficulty: difficulty.present ? difficulty.value : this.difficulty,
    due: due ?? this.due,
    lastReview: lastReview.present ? lastReview.value : this.lastReview,
    reps: reps ?? this.reps,
    lapses: lapses ?? this.lapses,
    sourceLessonId: sourceLessonId.present
        ? sourceLessonId.value
        : this.sourceLessonId,
    createdAt: createdAt ?? this.createdAt,
  );
  ReviewCard copyWithCompanion(ReviewCardsCompanion data) {
    return ReviewCard(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      cardType: data.cardType.present ? data.cardType.value : this.cardType,
      state: data.state.present ? data.state.value : this.state,
      step: data.step.present ? data.step.value : this.step,
      stability: data.stability.present ? data.stability.value : this.stability,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      due: data.due.present ? data.due.value : this.due,
      lastReview: data.lastReview.present
          ? data.lastReview.value
          : this.lastReview,
      reps: data.reps.present ? data.reps.value : this.reps,
      lapses: data.lapses.present ? data.lapses.value : this.lapses,
      sourceLessonId: data.sourceLessonId.present
          ? data.sourceLessonId.value
          : this.sourceLessonId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewCard(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('cardType: $cardType, ')
          ..write('state: $state, ')
          ..write('step: $step, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('due: $due, ')
          ..write('lastReview: $lastReview, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('sourceLessonId: $sourceLessonId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    cardType,
    state,
    step,
    stability,
    difficulty,
    due,
    lastReview,
    reps,
    lapses,
    sourceLessonId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewCard &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.cardType == this.cardType &&
          other.state == this.state &&
          other.step == this.step &&
          other.stability == this.stability &&
          other.difficulty == this.difficulty &&
          other.due == this.due &&
          other.lastReview == this.lastReview &&
          other.reps == this.reps &&
          other.lapses == this.lapses &&
          other.sourceLessonId == this.sourceLessonId &&
          other.createdAt == this.createdAt);
}

class ReviewCardsCompanion extends UpdateCompanion<ReviewCard> {
  final Value<int> id;
  final Value<String> itemId;
  final Value<String> cardType;
  final Value<int> state;
  final Value<int?> step;
  final Value<double?> stability;
  final Value<double?> difficulty;
  final Value<int> due;
  final Value<int?> lastReview;
  final Value<int> reps;
  final Value<int> lapses;
  final Value<String?> sourceLessonId;
  final Value<int> createdAt;
  const ReviewCardsCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.cardType = const Value.absent(),
    this.state = const Value.absent(),
    this.step = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.due = const Value.absent(),
    this.lastReview = const Value.absent(),
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    this.sourceLessonId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ReviewCardsCompanion.insert({
    this.id = const Value.absent(),
    required String itemId,
    required String cardType,
    this.state = const Value.absent(),
    this.step = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    required int due,
    this.lastReview = const Value.absent(),
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    this.sourceLessonId = const Value.absent(),
    required int createdAt,
  }) : itemId = Value(itemId),
       cardType = Value(cardType),
       due = Value(due),
       createdAt = Value(createdAt);
  static Insertable<ReviewCard> custom({
    Expression<int>? id,
    Expression<String>? itemId,
    Expression<String>? cardType,
    Expression<int>? state,
    Expression<int>? step,
    Expression<double>? stability,
    Expression<double>? difficulty,
    Expression<int>? due,
    Expression<int>? lastReview,
    Expression<int>? reps,
    Expression<int>? lapses,
    Expression<String>? sourceLessonId,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (cardType != null) 'card_type': cardType,
      if (state != null) 'state': state,
      if (step != null) 'step': step,
      if (stability != null) 'stability': stability,
      if (difficulty != null) 'difficulty': difficulty,
      if (due != null) 'due': due,
      if (lastReview != null) 'last_review': lastReview,
      if (reps != null) 'reps': reps,
      if (lapses != null) 'lapses': lapses,
      if (sourceLessonId != null) 'source_lesson_id': sourceLessonId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ReviewCardsCompanion copyWith({
    Value<int>? id,
    Value<String>? itemId,
    Value<String>? cardType,
    Value<int>? state,
    Value<int?>? step,
    Value<double?>? stability,
    Value<double?>? difficulty,
    Value<int>? due,
    Value<int?>? lastReview,
    Value<int>? reps,
    Value<int>? lapses,
    Value<String?>? sourceLessonId,
    Value<int>? createdAt,
  }) {
    return ReviewCardsCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      cardType: cardType ?? this.cardType,
      state: state ?? this.state,
      step: step ?? this.step,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      due: due ?? this.due,
      lastReview: lastReview ?? this.lastReview,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      sourceLessonId: sourceLessonId ?? this.sourceLessonId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (cardType.present) {
      map['card_type'] = Variable<String>(cardType.value);
    }
    if (state.present) {
      map['state'] = Variable<int>(state.value);
    }
    if (step.present) {
      map['step'] = Variable<int>(step.value);
    }
    if (stability.present) {
      map['stability'] = Variable<double>(stability.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<double>(difficulty.value);
    }
    if (due.present) {
      map['due'] = Variable<int>(due.value);
    }
    if (lastReview.present) {
      map['last_review'] = Variable<int>(lastReview.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (lapses.present) {
      map['lapses'] = Variable<int>(lapses.value);
    }
    if (sourceLessonId.present) {
      map['source_lesson_id'] = Variable<String>(sourceLessonId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewCardsCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('cardType: $cardType, ')
          ..write('state: $state, ')
          ..write('step: $step, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('due: $due, ')
          ..write('lastReview: $lastReview, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('sourceLessonId: $sourceLessonId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ReviewLogsTable extends ReviewLogs
    with TableInfo<$ReviewLogsTable, ReviewLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<int> cardId = GeneratedColumn<int>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES review_cards (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateBeforeMeta = const VerificationMeta(
    'stateBefore',
  );
  @override
  late final GeneratedColumn<int> stateBefore = GeneratedColumn<int>(
    'state_before',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta(
    'reviewedAt',
  );
  @override
  late final GeneratedColumn<int> reviewedAt = GeneratedColumn<int>(
    'reviewed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stabilityAfterMeta = const VerificationMeta(
    'stabilityAfter',
  );
  @override
  late final GeneratedColumn<double> stabilityAfter = GeneratedColumn<double>(
    'stability_after',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _difficultyAfterMeta = const VerificationMeta(
    'difficultyAfter',
  );
  @override
  late final GeneratedColumn<double> difficultyAfter = GeneratedColumn<double>(
    'difficulty_after',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueAfterMeta = const VerificationMeta(
    'dueAfter',
  );
  @override
  late final GeneratedColumn<int> dueAfter = GeneratedColumn<int>(
    'due_after',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retrievabilityMeta = const VerificationMeta(
    'retrievability',
  );
  @override
  late final GeneratedColumn<double> retrievability = GeneratedColumn<double>(
    'retrievability',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cardId,
    rating,
    stateBefore,
    reviewedAt,
    durationMs,
    stabilityAfter,
    difficultyAfter,
    dueAfter,
    retrievability,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('state_before')) {
      context.handle(
        _stateBeforeMeta,
        stateBefore.isAcceptableOrUnknown(
          data['state_before']!,
          _stateBeforeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stateBeforeMeta);
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
        _reviewedAtMeta,
        reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_reviewedAtMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('stability_after')) {
      context.handle(
        _stabilityAfterMeta,
        stabilityAfter.isAcceptableOrUnknown(
          data['stability_after']!,
          _stabilityAfterMeta,
        ),
      );
    }
    if (data.containsKey('difficulty_after')) {
      context.handle(
        _difficultyAfterMeta,
        difficultyAfter.isAcceptableOrUnknown(
          data['difficulty_after']!,
          _difficultyAfterMeta,
        ),
      );
    }
    if (data.containsKey('due_after')) {
      context.handle(
        _dueAfterMeta,
        dueAfter.isAcceptableOrUnknown(data['due_after']!, _dueAfterMeta),
      );
    } else if (isInserting) {
      context.missing(_dueAfterMeta);
    }
    if (data.containsKey('retrievability')) {
      context.handle(
        _retrievabilityMeta,
        retrievability.isAcceptableOrUnknown(
          data['retrievability']!,
          _retrievabilityMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}card_id'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      )!,
      stateBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}state_before'],
      )!,
      reviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reviewed_at'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      stabilityAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stability_after'],
      ),
      difficultyAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}difficulty_after'],
      ),
      dueAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_after'],
      )!,
      retrievability: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}retrievability'],
      ),
    );
  }

  @override
  $ReviewLogsTable createAlias(String alias) {
    return $ReviewLogsTable(attachedDatabase, alias);
  }
}

class ReviewLog extends DataClass implements Insertable<ReviewLog> {
  final int id;
  final int cardId;

  /// 1 again, 2 hard, 3 good, 4 easy.
  final int rating;
  final int stateBefore;
  final int reviewedAt;
  final int? durationMs;
  final double? stabilityAfter;
  final double? difficultyAfter;
  final int dueAfter;

  /// Predicted recall probability at the moment of review (null for new cards).
  final double? retrievability;
  const ReviewLog({
    required this.id,
    required this.cardId,
    required this.rating,
    required this.stateBefore,
    required this.reviewedAt,
    this.durationMs,
    this.stabilityAfter,
    this.difficultyAfter,
    required this.dueAfter,
    this.retrievability,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['card_id'] = Variable<int>(cardId);
    map['rating'] = Variable<int>(rating);
    map['state_before'] = Variable<int>(stateBefore);
    map['reviewed_at'] = Variable<int>(reviewedAt);
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    if (!nullToAbsent || stabilityAfter != null) {
      map['stability_after'] = Variable<double>(stabilityAfter);
    }
    if (!nullToAbsent || difficultyAfter != null) {
      map['difficulty_after'] = Variable<double>(difficultyAfter);
    }
    map['due_after'] = Variable<int>(dueAfter);
    if (!nullToAbsent || retrievability != null) {
      map['retrievability'] = Variable<double>(retrievability);
    }
    return map;
  }

  ReviewLogsCompanion toCompanion(bool nullToAbsent) {
    return ReviewLogsCompanion(
      id: Value(id),
      cardId: Value(cardId),
      rating: Value(rating),
      stateBefore: Value(stateBefore),
      reviewedAt: Value(reviewedAt),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      stabilityAfter: stabilityAfter == null && nullToAbsent
          ? const Value.absent()
          : Value(stabilityAfter),
      difficultyAfter: difficultyAfter == null && nullToAbsent
          ? const Value.absent()
          : Value(difficultyAfter),
      dueAfter: Value(dueAfter),
      retrievability: retrievability == null && nullToAbsent
          ? const Value.absent()
          : Value(retrievability),
    );
  }

  factory ReviewLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewLog(
      id: serializer.fromJson<int>(json['id']),
      cardId: serializer.fromJson<int>(json['cardId']),
      rating: serializer.fromJson<int>(json['rating']),
      stateBefore: serializer.fromJson<int>(json['stateBefore']),
      reviewedAt: serializer.fromJson<int>(json['reviewedAt']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      stabilityAfter: serializer.fromJson<double?>(json['stabilityAfter']),
      difficultyAfter: serializer.fromJson<double?>(json['difficultyAfter']),
      dueAfter: serializer.fromJson<int>(json['dueAfter']),
      retrievability: serializer.fromJson<double?>(json['retrievability']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cardId': serializer.toJson<int>(cardId),
      'rating': serializer.toJson<int>(rating),
      'stateBefore': serializer.toJson<int>(stateBefore),
      'reviewedAt': serializer.toJson<int>(reviewedAt),
      'durationMs': serializer.toJson<int?>(durationMs),
      'stabilityAfter': serializer.toJson<double?>(stabilityAfter),
      'difficultyAfter': serializer.toJson<double?>(difficultyAfter),
      'dueAfter': serializer.toJson<int>(dueAfter),
      'retrievability': serializer.toJson<double?>(retrievability),
    };
  }

  ReviewLog copyWith({
    int? id,
    int? cardId,
    int? rating,
    int? stateBefore,
    int? reviewedAt,
    Value<int?> durationMs = const Value.absent(),
    Value<double?> stabilityAfter = const Value.absent(),
    Value<double?> difficultyAfter = const Value.absent(),
    int? dueAfter,
    Value<double?> retrievability = const Value.absent(),
  }) => ReviewLog(
    id: id ?? this.id,
    cardId: cardId ?? this.cardId,
    rating: rating ?? this.rating,
    stateBefore: stateBefore ?? this.stateBefore,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    stabilityAfter: stabilityAfter.present
        ? stabilityAfter.value
        : this.stabilityAfter,
    difficultyAfter: difficultyAfter.present
        ? difficultyAfter.value
        : this.difficultyAfter,
    dueAfter: dueAfter ?? this.dueAfter,
    retrievability: retrievability.present
        ? retrievability.value
        : this.retrievability,
  );
  ReviewLog copyWithCompanion(ReviewLogsCompanion data) {
    return ReviewLog(
      id: data.id.present ? data.id.value : this.id,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      rating: data.rating.present ? data.rating.value : this.rating,
      stateBefore: data.stateBefore.present
          ? data.stateBefore.value
          : this.stateBefore,
      reviewedAt: data.reviewedAt.present
          ? data.reviewedAt.value
          : this.reviewedAt,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      stabilityAfter: data.stabilityAfter.present
          ? data.stabilityAfter.value
          : this.stabilityAfter,
      difficultyAfter: data.difficultyAfter.present
          ? data.difficultyAfter.value
          : this.difficultyAfter,
      dueAfter: data.dueAfter.present ? data.dueAfter.value : this.dueAfter,
      retrievability: data.retrievability.present
          ? data.retrievability.value
          : this.retrievability,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLog(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('rating: $rating, ')
          ..write('stateBefore: $stateBefore, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('durationMs: $durationMs, ')
          ..write('stabilityAfter: $stabilityAfter, ')
          ..write('difficultyAfter: $difficultyAfter, ')
          ..write('dueAfter: $dueAfter, ')
          ..write('retrievability: $retrievability')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cardId,
    rating,
    stateBefore,
    reviewedAt,
    durationMs,
    stabilityAfter,
    difficultyAfter,
    dueAfter,
    retrievability,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewLog &&
          other.id == this.id &&
          other.cardId == this.cardId &&
          other.rating == this.rating &&
          other.stateBefore == this.stateBefore &&
          other.reviewedAt == this.reviewedAt &&
          other.durationMs == this.durationMs &&
          other.stabilityAfter == this.stabilityAfter &&
          other.difficultyAfter == this.difficultyAfter &&
          other.dueAfter == this.dueAfter &&
          other.retrievability == this.retrievability);
}

class ReviewLogsCompanion extends UpdateCompanion<ReviewLog> {
  final Value<int> id;
  final Value<int> cardId;
  final Value<int> rating;
  final Value<int> stateBefore;
  final Value<int> reviewedAt;
  final Value<int?> durationMs;
  final Value<double?> stabilityAfter;
  final Value<double?> difficultyAfter;
  final Value<int> dueAfter;
  final Value<double?> retrievability;
  const ReviewLogsCompanion({
    this.id = const Value.absent(),
    this.cardId = const Value.absent(),
    this.rating = const Value.absent(),
    this.stateBefore = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.stabilityAfter = const Value.absent(),
    this.difficultyAfter = const Value.absent(),
    this.dueAfter = const Value.absent(),
    this.retrievability = const Value.absent(),
  });
  ReviewLogsCompanion.insert({
    this.id = const Value.absent(),
    required int cardId,
    required int rating,
    required int stateBefore,
    required int reviewedAt,
    this.durationMs = const Value.absent(),
    this.stabilityAfter = const Value.absent(),
    this.difficultyAfter = const Value.absent(),
    required int dueAfter,
    this.retrievability = const Value.absent(),
  }) : cardId = Value(cardId),
       rating = Value(rating),
       stateBefore = Value(stateBefore),
       reviewedAt = Value(reviewedAt),
       dueAfter = Value(dueAfter);
  static Insertable<ReviewLog> custom({
    Expression<int>? id,
    Expression<int>? cardId,
    Expression<int>? rating,
    Expression<int>? stateBefore,
    Expression<int>? reviewedAt,
    Expression<int>? durationMs,
    Expression<double>? stabilityAfter,
    Expression<double>? difficultyAfter,
    Expression<int>? dueAfter,
    Expression<double>? retrievability,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cardId != null) 'card_id': cardId,
      if (rating != null) 'rating': rating,
      if (stateBefore != null) 'state_before': stateBefore,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (durationMs != null) 'duration_ms': durationMs,
      if (stabilityAfter != null) 'stability_after': stabilityAfter,
      if (difficultyAfter != null) 'difficulty_after': difficultyAfter,
      if (dueAfter != null) 'due_after': dueAfter,
      if (retrievability != null) 'retrievability': retrievability,
    });
  }

  ReviewLogsCompanion copyWith({
    Value<int>? id,
    Value<int>? cardId,
    Value<int>? rating,
    Value<int>? stateBefore,
    Value<int>? reviewedAt,
    Value<int?>? durationMs,
    Value<double?>? stabilityAfter,
    Value<double?>? difficultyAfter,
    Value<int>? dueAfter,
    Value<double?>? retrievability,
  }) {
    return ReviewLogsCompanion(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      rating: rating ?? this.rating,
      stateBefore: stateBefore ?? this.stateBefore,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      durationMs: durationMs ?? this.durationMs,
      stabilityAfter: stabilityAfter ?? this.stabilityAfter,
      difficultyAfter: difficultyAfter ?? this.difficultyAfter,
      dueAfter: dueAfter ?? this.dueAfter,
      retrievability: retrievability ?? this.retrievability,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<int>(cardId.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (stateBefore.present) {
      map['state_before'] = Variable<int>(stateBefore.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<int>(reviewedAt.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (stabilityAfter.present) {
      map['stability_after'] = Variable<double>(stabilityAfter.value);
    }
    if (difficultyAfter.present) {
      map['difficulty_after'] = Variable<double>(difficultyAfter.value);
    }
    if (dueAfter.present) {
      map['due_after'] = Variable<int>(dueAfter.value);
    }
    if (retrievability.present) {
      map['retrievability'] = Variable<double>(retrievability.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogsCompanion(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('rating: $rating, ')
          ..write('stateBefore: $stateBefore, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('durationMs: $durationMs, ')
          ..write('stabilityAfter: $stabilityAfter, ')
          ..write('difficultyAfter: $difficultyAfter, ')
          ..write('dueAfter: $dueAfter, ')
          ..write('retrievability: $retrievability')
          ..write(')'))
        .toString();
  }
}

class $StudySessionsTable extends StudySessions
    with TableInfo<$StudySessionsTable, StudySession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudySessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refIdMeta = const VerificationMeta('refId');
  @override
  late final GeneratedColumn<String> refId = GeneratedColumn<String>(
    'ref_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _secondsMeta = const VerificationMeta(
    'seconds',
  );
  @override
  late final GeneratedColumn<int> seconds = GeneratedColumn<int>(
    'seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    day,
    kind,
    refId,
    startedAt,
    seconds,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'study_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudySession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('ref_id')) {
      context.handle(
        _refIdMeta,
        refId.isAcceptableOrUnknown(data['ref_id']!, _refIdMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('seconds')) {
      context.handle(
        _secondsMeta,
        seconds.isAcceptableOrUnknown(data['seconds']!, _secondsMeta),
      );
    } else if (isInserting) {
      context.missing(_secondsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StudySession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudySession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      refId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ref_id'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      )!,
      seconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seconds'],
      )!,
    );
  }

  @override
  $StudySessionsTable createAlias(String alias) {
    return $StudySessionsTable(attachedDatabase, alias);
  }
}

class StudySession extends DataClass implements Insertable<StudySession> {
  final int id;

  /// Local calendar day, `YYYY-MM-DD`, fixed at write time.
  final String day;

  /// lesson | review | listening | writing | pronunciation | errors
  final String kind;
  final String? refId;
  final int startedAt;
  final int seconds;
  const StudySession({
    required this.id,
    required this.day,
    required this.kind,
    this.refId,
    required this.startedAt,
    required this.seconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day'] = Variable<String>(day);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || refId != null) {
      map['ref_id'] = Variable<String>(refId);
    }
    map['started_at'] = Variable<int>(startedAt);
    map['seconds'] = Variable<int>(seconds);
    return map;
  }

  StudySessionsCompanion toCompanion(bool nullToAbsent) {
    return StudySessionsCompanion(
      id: Value(id),
      day: Value(day),
      kind: Value(kind),
      refId: refId == null && nullToAbsent
          ? const Value.absent()
          : Value(refId),
      startedAt: Value(startedAt),
      seconds: Value(seconds),
    );
  }

  factory StudySession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudySession(
      id: serializer.fromJson<int>(json['id']),
      day: serializer.fromJson<String>(json['day']),
      kind: serializer.fromJson<String>(json['kind']),
      refId: serializer.fromJson<String?>(json['refId']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      seconds: serializer.fromJson<int>(json['seconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'day': serializer.toJson<String>(day),
      'kind': serializer.toJson<String>(kind),
      'refId': serializer.toJson<String?>(refId),
      'startedAt': serializer.toJson<int>(startedAt),
      'seconds': serializer.toJson<int>(seconds),
    };
  }

  StudySession copyWith({
    int? id,
    String? day,
    String? kind,
    Value<String?> refId = const Value.absent(),
    int? startedAt,
    int? seconds,
  }) => StudySession(
    id: id ?? this.id,
    day: day ?? this.day,
    kind: kind ?? this.kind,
    refId: refId.present ? refId.value : this.refId,
    startedAt: startedAt ?? this.startedAt,
    seconds: seconds ?? this.seconds,
  );
  StudySession copyWithCompanion(StudySessionsCompanion data) {
    return StudySession(
      id: data.id.present ? data.id.value : this.id,
      day: data.day.present ? data.day.value : this.day,
      kind: data.kind.present ? data.kind.value : this.kind,
      refId: data.refId.present ? data.refId.value : this.refId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      seconds: data.seconds.present ? data.seconds.value : this.seconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudySession(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('kind: $kind, ')
          ..write('refId: $refId, ')
          ..write('startedAt: $startedAt, ')
          ..write('seconds: $seconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, day, kind, refId, startedAt, seconds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudySession &&
          other.id == this.id &&
          other.day == this.day &&
          other.kind == this.kind &&
          other.refId == this.refId &&
          other.startedAt == this.startedAt &&
          other.seconds == this.seconds);
}

class StudySessionsCompanion extends UpdateCompanion<StudySession> {
  final Value<int> id;
  final Value<String> day;
  final Value<String> kind;
  final Value<String?> refId;
  final Value<int> startedAt;
  final Value<int> seconds;
  const StudySessionsCompanion({
    this.id = const Value.absent(),
    this.day = const Value.absent(),
    this.kind = const Value.absent(),
    this.refId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.seconds = const Value.absent(),
  });
  StudySessionsCompanion.insert({
    this.id = const Value.absent(),
    required String day,
    required String kind,
    this.refId = const Value.absent(),
    required int startedAt,
    required int seconds,
  }) : day = Value(day),
       kind = Value(kind),
       startedAt = Value(startedAt),
       seconds = Value(seconds);
  static Insertable<StudySession> custom({
    Expression<int>? id,
    Expression<String>? day,
    Expression<String>? kind,
    Expression<String>? refId,
    Expression<int>? startedAt,
    Expression<int>? seconds,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (day != null) 'day': day,
      if (kind != null) 'kind': kind,
      if (refId != null) 'ref_id': refId,
      if (startedAt != null) 'started_at': startedAt,
      if (seconds != null) 'seconds': seconds,
    });
  }

  StudySessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? day,
    Value<String>? kind,
    Value<String?>? refId,
    Value<int>? startedAt,
    Value<int>? seconds,
  }) {
    return StudySessionsCompanion(
      id: id ?? this.id,
      day: day ?? this.day,
      kind: kind ?? this.kind,
      refId: refId ?? this.refId,
      startedAt: startedAt ?? this.startedAt,
      seconds: seconds ?? this.seconds,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (refId.present) {
      map['ref_id'] = Variable<String>(refId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (seconds.present) {
      map['seconds'] = Variable<int>(seconds.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudySessionsCompanion(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('kind: $kind, ')
          ..write('refId: $refId, ')
          ..write('startedAt: $startedAt, ')
          ..write('seconds: $seconds')
          ..write(')'))
        .toString();
  }
}

class $ErrorRecordsTable extends ErrorRecords
    with TableInfo<$ErrorRecordsTable, ErrorRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ErrorRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _signatureMeta = const VerificationMeta(
    'signature',
  );
  @override
  late final GeneratedColumn<String> signature = GeneratedColumn<String>(
    'signature',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _incorrectMeta = const VerificationMeta(
    'incorrect',
  );
  @override
  late final GeneratedColumn<String> incorrect = GeneratedColumn<String>(
    'incorrect',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctMeta = const VerificationMeta(
    'correct',
  );
  @override
  late final GeneratedColumn<String> correct = GeneratedColumn<String>(
    'correct',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _promptArMeta = const VerificationMeta(
    'promptAr',
  );
  @override
  late final GeneratedColumn<String> promptAr = GeneratedColumn<String>(
    'prompt_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _lessonIdMeta = const VerificationMeta(
    'lessonId',
  );
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
    'lesson_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _correctSinceMeta = const VerificationMeta(
    'correctSince',
  );
  @override
  late final GeneratedColumn<int> correctSince = GeneratedColumn<int>(
    'correct_since',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _firstSeenMeta = const VerificationMeta(
    'firstSeen',
  );
  @override
  late final GeneratedColumn<int> firstSeen = GeneratedColumn<int>(
    'first_seen',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSeenMeta = const VerificationMeta(
    'lastSeen',
  );
  @override
  late final GeneratedColumn<int> lastSeen = GeneratedColumn<int>(
    'last_seen',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    signature,
    incorrect,
    correct,
    category,
    promptAr,
    lessonId,
    itemId,
    count,
    correctSince,
    firstSeen,
    lastSeen,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'error_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ErrorRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('signature')) {
      context.handle(
        _signatureMeta,
        signature.isAcceptableOrUnknown(data['signature']!, _signatureMeta),
      );
    } else if (isInserting) {
      context.missing(_signatureMeta);
    }
    if (data.containsKey('incorrect')) {
      context.handle(
        _incorrectMeta,
        incorrect.isAcceptableOrUnknown(data['incorrect']!, _incorrectMeta),
      );
    } else if (isInserting) {
      context.missing(_incorrectMeta);
    }
    if (data.containsKey('correct')) {
      context.handle(
        _correctMeta,
        correct.isAcceptableOrUnknown(data['correct']!, _correctMeta),
      );
    } else if (isInserting) {
      context.missing(_correctMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('prompt_ar')) {
      context.handle(
        _promptArMeta,
        promptAr.isAcceptableOrUnknown(data['prompt_ar']!, _promptArMeta),
      );
    }
    if (data.containsKey('lesson_id')) {
      context.handle(
        _lessonIdMeta,
        lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta),
      );
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    }
    if (data.containsKey('correct_since')) {
      context.handle(
        _correctSinceMeta,
        correctSince.isAcceptableOrUnknown(
          data['correct_since']!,
          _correctSinceMeta,
        ),
      );
    }
    if (data.containsKey('first_seen')) {
      context.handle(
        _firstSeenMeta,
        firstSeen.isAcceptableOrUnknown(data['first_seen']!, _firstSeenMeta),
      );
    } else if (isInserting) {
      context.missing(_firstSeenMeta);
    }
    if (data.containsKey('last_seen')) {
      context.handle(
        _lastSeenMeta,
        lastSeen.isAcceptableOrUnknown(data['last_seen']!, _lastSeenMeta),
      );
    } else if (isInserting) {
      context.missing(_lastSeenMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ErrorRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ErrorRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      signature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signature'],
      )!,
      incorrect: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}incorrect'],
      )!,
      correct: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}correct'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      promptAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt_ar'],
      )!,
      lessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lesson_id'],
      ),
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      ),
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
      correctSince: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_since'],
      )!,
      firstSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}first_seen'],
      )!,
      lastSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_seen'],
      )!,
    );
  }

  @override
  $ErrorRecordsTable createAlias(String alias) {
    return $ErrorRecordsTable(attachedDatabase, alias);
  }
}

class ErrorRecord extends DataClass implements Insertable<ErrorRecord> {
  final int id;

  /// Stable identity of the mistake target (normalised expected answer +
  /// exercise type).
  final String signature;
  final String incorrect;
  final String correct;

  /// vocabulary | spelling | word_order | listening | grammar | meaning
  final String category;
  final String promptAr;
  final String? lessonId;
  final String? itemId;
  final int count;

  /// Correct answers given to the same target AFTER the last mistake.
  final int correctSince;
  final int firstSeen;
  final int lastSeen;
  const ErrorRecord({
    required this.id,
    required this.signature,
    required this.incorrect,
    required this.correct,
    required this.category,
    required this.promptAr,
    this.lessonId,
    this.itemId,
    required this.count,
    required this.correctSince,
    required this.firstSeen,
    required this.lastSeen,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['signature'] = Variable<String>(signature);
    map['incorrect'] = Variable<String>(incorrect);
    map['correct'] = Variable<String>(correct);
    map['category'] = Variable<String>(category);
    map['prompt_ar'] = Variable<String>(promptAr);
    if (!nullToAbsent || lessonId != null) {
      map['lesson_id'] = Variable<String>(lessonId);
    }
    if (!nullToAbsent || itemId != null) {
      map['item_id'] = Variable<String>(itemId);
    }
    map['count'] = Variable<int>(count);
    map['correct_since'] = Variable<int>(correctSince);
    map['first_seen'] = Variable<int>(firstSeen);
    map['last_seen'] = Variable<int>(lastSeen);
    return map;
  }

  ErrorRecordsCompanion toCompanion(bool nullToAbsent) {
    return ErrorRecordsCompanion(
      id: Value(id),
      signature: Value(signature),
      incorrect: Value(incorrect),
      correct: Value(correct),
      category: Value(category),
      promptAr: Value(promptAr),
      lessonId: lessonId == null && nullToAbsent
          ? const Value.absent()
          : Value(lessonId),
      itemId: itemId == null && nullToAbsent
          ? const Value.absent()
          : Value(itemId),
      count: Value(count),
      correctSince: Value(correctSince),
      firstSeen: Value(firstSeen),
      lastSeen: Value(lastSeen),
    );
  }

  factory ErrorRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ErrorRecord(
      id: serializer.fromJson<int>(json['id']),
      signature: serializer.fromJson<String>(json['signature']),
      incorrect: serializer.fromJson<String>(json['incorrect']),
      correct: serializer.fromJson<String>(json['correct']),
      category: serializer.fromJson<String>(json['category']),
      promptAr: serializer.fromJson<String>(json['promptAr']),
      lessonId: serializer.fromJson<String?>(json['lessonId']),
      itemId: serializer.fromJson<String?>(json['itemId']),
      count: serializer.fromJson<int>(json['count']),
      correctSince: serializer.fromJson<int>(json['correctSince']),
      firstSeen: serializer.fromJson<int>(json['firstSeen']),
      lastSeen: serializer.fromJson<int>(json['lastSeen']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'signature': serializer.toJson<String>(signature),
      'incorrect': serializer.toJson<String>(incorrect),
      'correct': serializer.toJson<String>(correct),
      'category': serializer.toJson<String>(category),
      'promptAr': serializer.toJson<String>(promptAr),
      'lessonId': serializer.toJson<String?>(lessonId),
      'itemId': serializer.toJson<String?>(itemId),
      'count': serializer.toJson<int>(count),
      'correctSince': serializer.toJson<int>(correctSince),
      'firstSeen': serializer.toJson<int>(firstSeen),
      'lastSeen': serializer.toJson<int>(lastSeen),
    };
  }

  ErrorRecord copyWith({
    int? id,
    String? signature,
    String? incorrect,
    String? correct,
    String? category,
    String? promptAr,
    Value<String?> lessonId = const Value.absent(),
    Value<String?> itemId = const Value.absent(),
    int? count,
    int? correctSince,
    int? firstSeen,
    int? lastSeen,
  }) => ErrorRecord(
    id: id ?? this.id,
    signature: signature ?? this.signature,
    incorrect: incorrect ?? this.incorrect,
    correct: correct ?? this.correct,
    category: category ?? this.category,
    promptAr: promptAr ?? this.promptAr,
    lessonId: lessonId.present ? lessonId.value : this.lessonId,
    itemId: itemId.present ? itemId.value : this.itemId,
    count: count ?? this.count,
    correctSince: correctSince ?? this.correctSince,
    firstSeen: firstSeen ?? this.firstSeen,
    lastSeen: lastSeen ?? this.lastSeen,
  );
  ErrorRecord copyWithCompanion(ErrorRecordsCompanion data) {
    return ErrorRecord(
      id: data.id.present ? data.id.value : this.id,
      signature: data.signature.present ? data.signature.value : this.signature,
      incorrect: data.incorrect.present ? data.incorrect.value : this.incorrect,
      correct: data.correct.present ? data.correct.value : this.correct,
      category: data.category.present ? data.category.value : this.category,
      promptAr: data.promptAr.present ? data.promptAr.value : this.promptAr,
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      count: data.count.present ? data.count.value : this.count,
      correctSince: data.correctSince.present
          ? data.correctSince.value
          : this.correctSince,
      firstSeen: data.firstSeen.present ? data.firstSeen.value : this.firstSeen,
      lastSeen: data.lastSeen.present ? data.lastSeen.value : this.lastSeen,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ErrorRecord(')
          ..write('id: $id, ')
          ..write('signature: $signature, ')
          ..write('incorrect: $incorrect, ')
          ..write('correct: $correct, ')
          ..write('category: $category, ')
          ..write('promptAr: $promptAr, ')
          ..write('lessonId: $lessonId, ')
          ..write('itemId: $itemId, ')
          ..write('count: $count, ')
          ..write('correctSince: $correctSince, ')
          ..write('firstSeen: $firstSeen, ')
          ..write('lastSeen: $lastSeen')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    signature,
    incorrect,
    correct,
    category,
    promptAr,
    lessonId,
    itemId,
    count,
    correctSince,
    firstSeen,
    lastSeen,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ErrorRecord &&
          other.id == this.id &&
          other.signature == this.signature &&
          other.incorrect == this.incorrect &&
          other.correct == this.correct &&
          other.category == this.category &&
          other.promptAr == this.promptAr &&
          other.lessonId == this.lessonId &&
          other.itemId == this.itemId &&
          other.count == this.count &&
          other.correctSince == this.correctSince &&
          other.firstSeen == this.firstSeen &&
          other.lastSeen == this.lastSeen);
}

class ErrorRecordsCompanion extends UpdateCompanion<ErrorRecord> {
  final Value<int> id;
  final Value<String> signature;
  final Value<String> incorrect;
  final Value<String> correct;
  final Value<String> category;
  final Value<String> promptAr;
  final Value<String?> lessonId;
  final Value<String?> itemId;
  final Value<int> count;
  final Value<int> correctSince;
  final Value<int> firstSeen;
  final Value<int> lastSeen;
  const ErrorRecordsCompanion({
    this.id = const Value.absent(),
    this.signature = const Value.absent(),
    this.incorrect = const Value.absent(),
    this.correct = const Value.absent(),
    this.category = const Value.absent(),
    this.promptAr = const Value.absent(),
    this.lessonId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.count = const Value.absent(),
    this.correctSince = const Value.absent(),
    this.firstSeen = const Value.absent(),
    this.lastSeen = const Value.absent(),
  });
  ErrorRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String signature,
    required String incorrect,
    required String correct,
    required String category,
    this.promptAr = const Value.absent(),
    this.lessonId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.count = const Value.absent(),
    this.correctSince = const Value.absent(),
    required int firstSeen,
    required int lastSeen,
  }) : signature = Value(signature),
       incorrect = Value(incorrect),
       correct = Value(correct),
       category = Value(category),
       firstSeen = Value(firstSeen),
       lastSeen = Value(lastSeen);
  static Insertable<ErrorRecord> custom({
    Expression<int>? id,
    Expression<String>? signature,
    Expression<String>? incorrect,
    Expression<String>? correct,
    Expression<String>? category,
    Expression<String>? promptAr,
    Expression<String>? lessonId,
    Expression<String>? itemId,
    Expression<int>? count,
    Expression<int>? correctSince,
    Expression<int>? firstSeen,
    Expression<int>? lastSeen,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (signature != null) 'signature': signature,
      if (incorrect != null) 'incorrect': incorrect,
      if (correct != null) 'correct': correct,
      if (category != null) 'category': category,
      if (promptAr != null) 'prompt_ar': promptAr,
      if (lessonId != null) 'lesson_id': lessonId,
      if (itemId != null) 'item_id': itemId,
      if (count != null) 'count': count,
      if (correctSince != null) 'correct_since': correctSince,
      if (firstSeen != null) 'first_seen': firstSeen,
      if (lastSeen != null) 'last_seen': lastSeen,
    });
  }

  ErrorRecordsCompanion copyWith({
    Value<int>? id,
    Value<String>? signature,
    Value<String>? incorrect,
    Value<String>? correct,
    Value<String>? category,
    Value<String>? promptAr,
    Value<String?>? lessonId,
    Value<String?>? itemId,
    Value<int>? count,
    Value<int>? correctSince,
    Value<int>? firstSeen,
    Value<int>? lastSeen,
  }) {
    return ErrorRecordsCompanion(
      id: id ?? this.id,
      signature: signature ?? this.signature,
      incorrect: incorrect ?? this.incorrect,
      correct: correct ?? this.correct,
      category: category ?? this.category,
      promptAr: promptAr ?? this.promptAr,
      lessonId: lessonId ?? this.lessonId,
      itemId: itemId ?? this.itemId,
      count: count ?? this.count,
      correctSince: correctSince ?? this.correctSince,
      firstSeen: firstSeen ?? this.firstSeen,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (signature.present) {
      map['signature'] = Variable<String>(signature.value);
    }
    if (incorrect.present) {
      map['incorrect'] = Variable<String>(incorrect.value);
    }
    if (correct.present) {
      map['correct'] = Variable<String>(correct.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (promptAr.present) {
      map['prompt_ar'] = Variable<String>(promptAr.value);
    }
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (correctSince.present) {
      map['correct_since'] = Variable<int>(correctSince.value);
    }
    if (firstSeen.present) {
      map['first_seen'] = Variable<int>(firstSeen.value);
    }
    if (lastSeen.present) {
      map['last_seen'] = Variable<int>(lastSeen.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ErrorRecordsCompanion(')
          ..write('id: $id, ')
          ..write('signature: $signature, ')
          ..write('incorrect: $incorrect, ')
          ..write('correct: $correct, ')
          ..write('category: $category, ')
          ..write('promptAr: $promptAr, ')
          ..write('lessonId: $lessonId, ')
          ..write('itemId: $itemId, ')
          ..write('count: $count, ')
          ..write('correctSince: $correctSince, ')
          ..write('firstSeen: $firstSeen, ')
          ..write('lastSeen: $lastSeen')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $LessonProgressTable lessonProgress = $LessonProgressTable(this);
  late final $ActivityAttemptsTable activityAttempts = $ActivityAttemptsTable(
    this,
  );
  late final $ReviewCardsTable reviewCards = $ReviewCardsTable(this);
  late final $ReviewLogsTable reviewLogs = $ReviewLogsTable(this);
  late final $StudySessionsTable studySessions = $StudySessionsTable(this);
  late final $ErrorRecordsTable errorRecords = $ErrorRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    settings,
    lessonProgress,
    activityAttempts,
    reviewCards,
    reviewLogs,
    studySessions,
    errorRecords,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'review_cards',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('review_logs', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$LessonProgressTableCreateCompanionBuilder =
    LessonProgressCompanion Function({
      required String lessonId,
      required String status,
      Value<double> bestScore,
      Value<double> lastScore,
      Value<int> completions,
      required int startedAt,
      Value<int?> firstCompletedAt,
      Value<int?> lastCompletedAt,
      Value<String> contentVersion,
      Value<int> rowid,
    });
typedef $$LessonProgressTableUpdateCompanionBuilder =
    LessonProgressCompanion Function({
      Value<String> lessonId,
      Value<String> status,
      Value<double> bestScore,
      Value<double> lastScore,
      Value<int> completions,
      Value<int> startedAt,
      Value<int?> firstCompletedAt,
      Value<int?> lastCompletedAt,
      Value<String> contentVersion,
      Value<int> rowid,
    });

class $$LessonProgressTableFilterComposer
    extends Composer<_$AppDatabase, $LessonProgressTable> {
  $$LessonProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bestScore => $composableBuilder(
    column: $table.bestScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lastScore => $composableBuilder(
    column: $table.lastScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completions => $composableBuilder(
    column: $table.completions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstCompletedAt => $composableBuilder(
    column: $table.firstCompletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastCompletedAt => $composableBuilder(
    column: $table.lastCompletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LessonProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $LessonProgressTable> {
  $$LessonProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bestScore => $composableBuilder(
    column: $table.bestScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lastScore => $composableBuilder(
    column: $table.lastScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completions => $composableBuilder(
    column: $table.completions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstCompletedAt => $composableBuilder(
    column: $table.firstCompletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastCompletedAt => $composableBuilder(
    column: $table.lastCompletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LessonProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $LessonProgressTable> {
  $$LessonProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get bestScore =>
      $composableBuilder(column: $table.bestScore, builder: (column) => column);

  GeneratedColumn<double> get lastScore =>
      $composableBuilder(column: $table.lastScore, builder: (column) => column);

  GeneratedColumn<int> get completions => $composableBuilder(
    column: $table.completions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get firstCompletedAt => $composableBuilder(
    column: $table.firstCompletedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastCompletedAt => $composableBuilder(
    column: $table.lastCompletedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => column,
  );
}

class $$LessonProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LessonProgressTable,
          LessonProgressData,
          $$LessonProgressTableFilterComposer,
          $$LessonProgressTableOrderingComposer,
          $$LessonProgressTableAnnotationComposer,
          $$LessonProgressTableCreateCompanionBuilder,
          $$LessonProgressTableUpdateCompanionBuilder,
          (
            LessonProgressData,
            BaseReferences<
              _$AppDatabase,
              $LessonProgressTable,
              LessonProgressData
            >,
          ),
          LessonProgressData,
          PrefetchHooks Function()
        > {
  $$LessonProgressTableTableManager(
    _$AppDatabase db,
    $LessonProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LessonProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LessonProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LessonProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> lessonId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double> bestScore = const Value.absent(),
                Value<double> lastScore = const Value.absent(),
                Value<int> completions = const Value.absent(),
                Value<int> startedAt = const Value.absent(),
                Value<int?> firstCompletedAt = const Value.absent(),
                Value<int?> lastCompletedAt = const Value.absent(),
                Value<String> contentVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LessonProgressCompanion(
                lessonId: lessonId,
                status: status,
                bestScore: bestScore,
                lastScore: lastScore,
                completions: completions,
                startedAt: startedAt,
                firstCompletedAt: firstCompletedAt,
                lastCompletedAt: lastCompletedAt,
                contentVersion: contentVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String lessonId,
                required String status,
                Value<double> bestScore = const Value.absent(),
                Value<double> lastScore = const Value.absent(),
                Value<int> completions = const Value.absent(),
                required int startedAt,
                Value<int?> firstCompletedAt = const Value.absent(),
                Value<int?> lastCompletedAt = const Value.absent(),
                Value<String> contentVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LessonProgressCompanion.insert(
                lessonId: lessonId,
                status: status,
                bestScore: bestScore,
                lastScore: lastScore,
                completions: completions,
                startedAt: startedAt,
                firstCompletedAt: firstCompletedAt,
                lastCompletedAt: lastCompletedAt,
                contentVersion: contentVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LessonProgressTable, LessonProgressData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LessonProgressTable,
                    LessonProgressData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LessonProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LessonProgressTable,
      LessonProgressData,
      $$LessonProgressTableFilterComposer,
      $$LessonProgressTableOrderingComposer,
      $$LessonProgressTableAnnotationComposer,
      $$LessonProgressTableCreateCompanionBuilder,
      $$LessonProgressTableUpdateCompanionBuilder,
      (
        LessonProgressData,
        BaseReferences<_$AppDatabase, $LessonProgressTable, LessonProgressData>,
      ),
      LessonProgressData,
      PrefetchHooks Function()
    >;
typedef $$ActivityAttemptsTableCreateCompanionBuilder =
    ActivityAttemptsCompanion Function({
      Value<int> id,
      required String activityId,
      Value<String?> lessonId,
      Value<String?> itemId,
      required String skill,
      required String exerciseType,
      required String context,
      required bool isCorrect,
      Value<bool> isMeasured,
      Value<String> userAnswer,
      Value<String> expected,
      required int createdAt,
    });
typedef $$ActivityAttemptsTableUpdateCompanionBuilder =
    ActivityAttemptsCompanion Function({
      Value<int> id,
      Value<String> activityId,
      Value<String?> lessonId,
      Value<String?> itemId,
      Value<String> skill,
      Value<String> exerciseType,
      Value<String> context,
      Value<bool> isCorrect,
      Value<bool> isMeasured,
      Value<String> userAnswer,
      Value<String> expected,
      Value<int> createdAt,
    });

class $$ActivityAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $ActivityAttemptsTable> {
  $$ActivityAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get skill => $composableBuilder(
    column: $table.skill,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseType => $composableBuilder(
    column: $table.exerciseType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get context => $composableBuilder(
    column: $table.context,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCorrect => $composableBuilder(
    column: $table.isCorrect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMeasured => $composableBuilder(
    column: $table.isMeasured,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userAnswer => $composableBuilder(
    column: $table.userAnswer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expected => $composableBuilder(
    column: $table.expected,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ActivityAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivityAttemptsTable> {
  $$ActivityAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skill => $composableBuilder(
    column: $table.skill,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseType => $composableBuilder(
    column: $table.exerciseType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get context => $composableBuilder(
    column: $table.context,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCorrect => $composableBuilder(
    column: $table.isCorrect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMeasured => $composableBuilder(
    column: $table.isMeasured,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userAnswer => $composableBuilder(
    column: $table.userAnswer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expected => $composableBuilder(
    column: $table.expected,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ActivityAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivityAttemptsTable> {
  $$ActivityAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get skill =>
      $composableBuilder(column: $table.skill, builder: (column) => column);

  GeneratedColumn<String> get exerciseType => $composableBuilder(
    column: $table.exerciseType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get context =>
      $composableBuilder(column: $table.context, builder: (column) => column);

  GeneratedColumn<bool> get isCorrect =>
      $composableBuilder(column: $table.isCorrect, builder: (column) => column);

  GeneratedColumn<bool> get isMeasured => $composableBuilder(
    column: $table.isMeasured,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userAnswer => $composableBuilder(
    column: $table.userAnswer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get expected =>
      $composableBuilder(column: $table.expected, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ActivityAttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActivityAttemptsTable,
          ActivityAttempt,
          $$ActivityAttemptsTableFilterComposer,
          $$ActivityAttemptsTableOrderingComposer,
          $$ActivityAttemptsTableAnnotationComposer,
          $$ActivityAttemptsTableCreateCompanionBuilder,
          $$ActivityAttemptsTableUpdateCompanionBuilder,
          (
            ActivityAttempt,
            BaseReferences<
              _$AppDatabase,
              $ActivityAttemptsTable,
              ActivityAttempt
            >,
          ),
          ActivityAttempt,
          PrefetchHooks Function()
        > {
  $$ActivityAttemptsTableTableManager(
    _$AppDatabase db,
    $ActivityAttemptsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivityAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivityAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivityAttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> activityId = const Value.absent(),
                Value<String?> lessonId = const Value.absent(),
                Value<String?> itemId = const Value.absent(),
                Value<String> skill = const Value.absent(),
                Value<String> exerciseType = const Value.absent(),
                Value<String> context = const Value.absent(),
                Value<bool> isCorrect = const Value.absent(),
                Value<bool> isMeasured = const Value.absent(),
                Value<String> userAnswer = const Value.absent(),
                Value<String> expected = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => ActivityAttemptsCompanion(
                id: id,
                activityId: activityId,
                lessonId: lessonId,
                itemId: itemId,
                skill: skill,
                exerciseType: exerciseType,
                context: context,
                isCorrect: isCorrect,
                isMeasured: isMeasured,
                userAnswer: userAnswer,
                expected: expected,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String activityId,
                Value<String?> lessonId = const Value.absent(),
                Value<String?> itemId = const Value.absent(),
                required String skill,
                required String exerciseType,
                required String context,
                required bool isCorrect,
                Value<bool> isMeasured = const Value.absent(),
                Value<String> userAnswer = const Value.absent(),
                Value<String> expected = const Value.absent(),
                required int createdAt,
              }) => ActivityAttemptsCompanion.insert(
                id: id,
                activityId: activityId,
                lessonId: lessonId,
                itemId: itemId,
                skill: skill,
                exerciseType: exerciseType,
                context: context,
                isCorrect: isCorrect,
                isMeasured: isMeasured,
                userAnswer: userAnswer,
                expected: expected,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ActivityAttemptsTable, ActivityAttempt>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ActivityAttemptsTable,
                    ActivityAttempt
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ActivityAttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActivityAttemptsTable,
      ActivityAttempt,
      $$ActivityAttemptsTableFilterComposer,
      $$ActivityAttemptsTableOrderingComposer,
      $$ActivityAttemptsTableAnnotationComposer,
      $$ActivityAttemptsTableCreateCompanionBuilder,
      $$ActivityAttemptsTableUpdateCompanionBuilder,
      (
        ActivityAttempt,
        BaseReferences<_$AppDatabase, $ActivityAttemptsTable, ActivityAttempt>,
      ),
      ActivityAttempt,
      PrefetchHooks Function()
    >;
typedef $$ReviewCardsTableCreateCompanionBuilder =
    ReviewCardsCompanion Function({
      Value<int> id,
      required String itemId,
      required String cardType,
      Value<int> state,
      Value<int?> step,
      Value<double?> stability,
      Value<double?> difficulty,
      required int due,
      Value<int?> lastReview,
      Value<int> reps,
      Value<int> lapses,
      Value<String?> sourceLessonId,
      required int createdAt,
    });
typedef $$ReviewCardsTableUpdateCompanionBuilder =
    ReviewCardsCompanion Function({
      Value<int> id,
      Value<String> itemId,
      Value<String> cardType,
      Value<int> state,
      Value<int?> step,
      Value<double?> stability,
      Value<double?> difficulty,
      Value<int> due,
      Value<int?> lastReview,
      Value<int> reps,
      Value<int> lapses,
      Value<String?> sourceLessonId,
      Value<int> createdAt,
    });

final class $$ReviewCardsTableReferences
    extends BaseReferences<_$AppDatabase, $ReviewCardsTable, ReviewCard> {
  $$ReviewCardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ReviewLogsTable, List<ReviewLog>>
  _reviewLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reviewLogs,
    aliasName: 'review_cards__id__review_logs__card_id',
  );

  $$ReviewLogsTableProcessedTableManager get reviewLogsRefs {
    final manager = $$ReviewLogsTableTableManager(
      $_db,
      $_db.reviewLogs,
    ).filter((f) => f.cardId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_reviewLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ReviewCardsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewCardsTable> {
  $$ReviewCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardType => $composableBuilder(
    column: $table.cardType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get due => $composableBuilder(
    column: $table.due,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceLessonId => $composableBuilder(
    column: $table.sourceLessonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> reviewLogsRefs(
    Expression<bool> Function($$ReviewLogsTableFilterComposer f) f,
  ) {
    final $$ReviewLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewLogs,
      getReferencedColumn: (t) => t.cardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewLogsTableFilterComposer(
            $db: $db,
            $table: $db.reviewLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ReviewCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewCardsTable> {
  $$ReviewCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardType => $composableBuilder(
    column: $table.cardType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get due => $composableBuilder(
    column: $table.due,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceLessonId => $composableBuilder(
    column: $table.sourceLessonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReviewCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewCardsTable> {
  $$ReviewCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get cardType =>
      $composableBuilder(column: $table.cardType, builder: (column) => column);

  GeneratedColumn<int> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get step =>
      $composableBuilder(column: $table.step, builder: (column) => column);

  GeneratedColumn<double> get stability =>
      $composableBuilder(column: $table.stability, builder: (column) => column);

  GeneratedColumn<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<int> get due =>
      $composableBuilder(column: $table.due, builder: (column) => column);

  GeneratedColumn<int> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => column);

  GeneratedColumn<String> get sourceLessonId => $composableBuilder(
    column: $table.sourceLessonId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> reviewLogsRefs<T extends Object>(
    Expression<T> Function($$ReviewLogsTableAnnotationComposer a) f,
  ) {
    final $$ReviewLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewLogs,
      getReferencedColumn: (t) => t.cardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.reviewLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ReviewCardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewCardsTable,
          ReviewCard,
          $$ReviewCardsTableFilterComposer,
          $$ReviewCardsTableOrderingComposer,
          $$ReviewCardsTableAnnotationComposer,
          $$ReviewCardsTableCreateCompanionBuilder,
          $$ReviewCardsTableUpdateCompanionBuilder,
          (ReviewCard, $$ReviewCardsTableReferences),
          ReviewCard,
          PrefetchHooks Function({bool reviewLogsRefs})
        > {
  $$ReviewCardsTableTableManager(_$AppDatabase db, $ReviewCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> cardType = const Value.absent(),
                Value<int> state = const Value.absent(),
                Value<int?> step = const Value.absent(),
                Value<double?> stability = const Value.absent(),
                Value<double?> difficulty = const Value.absent(),
                Value<int> due = const Value.absent(),
                Value<int?> lastReview = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<String?> sourceLessonId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => ReviewCardsCompanion(
                id: id,
                itemId: itemId,
                cardType: cardType,
                state: state,
                step: step,
                stability: stability,
                difficulty: difficulty,
                due: due,
                lastReview: lastReview,
                reps: reps,
                lapses: lapses,
                sourceLessonId: sourceLessonId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String itemId,
                required String cardType,
                Value<int> state = const Value.absent(),
                Value<int?> step = const Value.absent(),
                Value<double?> stability = const Value.absent(),
                Value<double?> difficulty = const Value.absent(),
                required int due,
                Value<int?> lastReview = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<String?> sourceLessonId = const Value.absent(),
                required int createdAt,
              }) => ReviewCardsCompanion.insert(
                id: id,
                itemId: itemId,
                cardType: cardType,
                state: state,
                step: step,
                stability: stability,
                difficulty: difficulty,
                due: due,
                lastReview: lastReview,
                reps: reps,
                lapses: lapses,
                sourceLessonId: sourceLessonId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReviewCardsTable, ReviewCard>(table),
                  $$ReviewCardsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({reviewLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (reviewLogsRefs) db.reviewLogs],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (reviewLogsRefs)
                    await $_getPrefetchedDataByColumns<
                      ReviewCard,
                      $ReviewCardsTable,
                      ReviewLog,
                      $ReviewLogsTable
                    >(
                      currentTable: table,
                      referencedTable: $$ReviewCardsTableReferences
                          ._reviewLogsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ReviewCardsTableReferences(
                            db,
                            table,
                            p0,
                          ).reviewLogsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'card_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ReviewCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewCardsTable,
      ReviewCard,
      $$ReviewCardsTableFilterComposer,
      $$ReviewCardsTableOrderingComposer,
      $$ReviewCardsTableAnnotationComposer,
      $$ReviewCardsTableCreateCompanionBuilder,
      $$ReviewCardsTableUpdateCompanionBuilder,
      (ReviewCard, $$ReviewCardsTableReferences),
      ReviewCard,
      PrefetchHooks Function({bool reviewLogsRefs})
    >;
typedef $$ReviewLogsTableCreateCompanionBuilder = ReviewLogsCompanion Function({
  Value<int> id,
  required int cardId,
  required int rating,
  required int stateBefore,
  required int reviewedAt,
  Value<int?> durationMs,
  Value<double?> stabilityAfter,
  Value<double?> difficultyAfter,
  required int dueAfter,
  Value<double?> retrievability,
});
typedef $$ReviewLogsTableUpdateCompanionBuilder = ReviewLogsCompanion Function({
  Value<int> id,
  Value<int> cardId,
  Value<int> rating,
  Value<int> stateBefore,
  Value<int> reviewedAt,
  Value<int?> durationMs,
  Value<double?> stabilityAfter,
  Value<double?> difficultyAfter,
  Value<int> dueAfter,
  Value<double?> retrievability,
});

final class $$ReviewLogsTableReferences
    extends BaseReferences<_$AppDatabase, $ReviewLogsTable, ReviewLog> {
  $$ReviewLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ReviewCardsTable _cardIdTable(_$AppDatabase db) =>
      db.reviewCards.createAlias('review_logs__card_id__review_cards__id');

  $$ReviewCardsTableProcessedTableManager get cardId {
    final $_column = $_itemColumn<int>('card_id')!;

    final manager = $$ReviewCardsTableTableManager(
      $_db,
      $_db.reviewCards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReviewLogsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stateBefore => $composableBuilder(
    column: $table.stateBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stabilityAfter => $composableBuilder(
    column: $table.stabilityAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get difficultyAfter => $composableBuilder(
    column: $table.difficultyAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueAfter => $composableBuilder(
    column: $table.dueAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get retrievability => $composableBuilder(
    column: $table.retrievability,
    builder: (column) => ColumnFilters(column),
  );

  $$ReviewCardsTableFilterComposer get cardId {
    final $$ReviewCardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.reviewCards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewCardsTableFilterComposer(
            $db: $db,
            $table: $db.reviewCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stateBefore => $composableBuilder(
    column: $table.stateBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stabilityAfter => $composableBuilder(
    column: $table.stabilityAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get difficultyAfter => $composableBuilder(
    column: $table.difficultyAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueAfter => $composableBuilder(
    column: $table.dueAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get retrievability => $composableBuilder(
    column: $table.retrievability,
    builder: (column) => ColumnOrderings(column),
  );

  $$ReviewCardsTableOrderingComposer get cardId {
    final $$ReviewCardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.reviewCards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewCardsTableOrderingComposer(
            $db: $db,
            $table: $db.reviewCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get stateBefore => $composableBuilder(
    column: $table.stateBefore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get stabilityAfter => $composableBuilder(
    column: $table.stabilityAfter,
    builder: (column) => column,
  );

  GeneratedColumn<double> get difficultyAfter => $composableBuilder(
    column: $table.difficultyAfter,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dueAfter =>
      $composableBuilder(column: $table.dueAfter, builder: (column) => column);

  GeneratedColumn<double> get retrievability => $composableBuilder(
    column: $table.retrievability,
    builder: (column) => column,
  );

  $$ReviewCardsTableAnnotationComposer get cardId {
    final $$ReviewCardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.reviewCards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewCardsTableAnnotationComposer(
            $db: $db,
            $table: $db.reviewCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewLogsTable,
          ReviewLog,
          $$ReviewLogsTableFilterComposer,
          $$ReviewLogsTableOrderingComposer,
          $$ReviewLogsTableAnnotationComposer,
          $$ReviewLogsTableCreateCompanionBuilder,
          $$ReviewLogsTableUpdateCompanionBuilder,
          (ReviewLog, $$ReviewLogsTableReferences),
          ReviewLog,
          PrefetchHooks Function({bool cardId})
        > {
  $$ReviewLogsTableTableManager(_$AppDatabase db, $ReviewLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> cardId = const Value.absent(),
                Value<int> rating = const Value.absent(),
                Value<int> stateBefore = const Value.absent(),
                Value<int> reviewedAt = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<double?> stabilityAfter = const Value.absent(),
                Value<double?> difficultyAfter = const Value.absent(),
                Value<int> dueAfter = const Value.absent(),
                Value<double?> retrievability = const Value.absent(),
              }) => ReviewLogsCompanion(
                id: id,
                cardId: cardId,
                rating: rating,
                stateBefore: stateBefore,
                reviewedAt: reviewedAt,
                durationMs: durationMs,
                stabilityAfter: stabilityAfter,
                difficultyAfter: difficultyAfter,
                dueAfter: dueAfter,
                retrievability: retrievability,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int cardId,
                required int rating,
                required int stateBefore,
                required int reviewedAt,
                Value<int?> durationMs = const Value.absent(),
                Value<double?> stabilityAfter = const Value.absent(),
                Value<double?> difficultyAfter = const Value.absent(),
                required int dueAfter,
                Value<double?> retrievability = const Value.absent(),
              }) => ReviewLogsCompanion.insert(
                id: id,
                cardId: cardId,
                rating: rating,
                stateBefore: stateBefore,
                reviewedAt: reviewedAt,
                durationMs: durationMs,
                stabilityAfter: stabilityAfter,
                difficultyAfter: difficultyAfter,
                dueAfter: dueAfter,
                retrievability: retrievability,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReviewLogsTable, ReviewLog>(table),
                  $$ReviewLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cardId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (cardId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.cardId,
                        referencedTable: $$ReviewLogsTableReferences
                            ._cardIdTable(db),
                        referencedColumn: $$ReviewLogsTableReferences
                            ._cardIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReviewLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewLogsTable,
      ReviewLog,
      $$ReviewLogsTableFilterComposer,
      $$ReviewLogsTableOrderingComposer,
      $$ReviewLogsTableAnnotationComposer,
      $$ReviewLogsTableCreateCompanionBuilder,
      $$ReviewLogsTableUpdateCompanionBuilder,
      (ReviewLog, $$ReviewLogsTableReferences),
      ReviewLog,
      PrefetchHooks Function({bool cardId})
    >;
typedef $$StudySessionsTableCreateCompanionBuilder =
    StudySessionsCompanion Function({
      Value<int> id,
      required String day,
      required String kind,
      Value<String?> refId,
      required int startedAt,
      required int seconds,
    });
typedef $$StudySessionsTableUpdateCompanionBuilder =
    StudySessionsCompanion Function({
      Value<int> id,
      Value<String> day,
      Value<String> kind,
      Value<String?> refId,
      Value<int> startedAt,
      Value<int> seconds,
    });

class $$StudySessionsTableFilterComposer
    extends Composer<_$AppDatabase, $StudySessionsTable> {
  $$StudySessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refId => $composableBuilder(
    column: $table.refId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StudySessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $StudySessionsTable> {
  $$StudySessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refId => $composableBuilder(
    column: $table.refId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StudySessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StudySessionsTable> {
  $$StudySessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get refId =>
      $composableBuilder(column: $table.refId, builder: (column) => column);

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get seconds =>
      $composableBuilder(column: $table.seconds, builder: (column) => column);
}

class $$StudySessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StudySessionsTable,
          StudySession,
          $$StudySessionsTableFilterComposer,
          $$StudySessionsTableOrderingComposer,
          $$StudySessionsTableAnnotationComposer,
          $$StudySessionsTableCreateCompanionBuilder,
          $$StudySessionsTableUpdateCompanionBuilder,
          (
            StudySession,
            BaseReferences<_$AppDatabase, $StudySessionsTable, StudySession>,
          ),
          StudySession,
          PrefetchHooks Function()
        > {
  $$StudySessionsTableTableManager(_$AppDatabase db, $StudySessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudySessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudySessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudySessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> refId = const Value.absent(),
                Value<int> startedAt = const Value.absent(),
                Value<int> seconds = const Value.absent(),
              }) => StudySessionsCompanion(
                id: id,
                day: day,
                kind: kind,
                refId: refId,
                startedAt: startedAt,
                seconds: seconds,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String day,
                required String kind,
                Value<String?> refId = const Value.absent(),
                required int startedAt,
                required int seconds,
              }) => StudySessionsCompanion.insert(
                id: id,
                day: day,
                kind: kind,
                refId: refId,
                startedAt: startedAt,
                seconds: seconds,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StudySessionsTable, StudySession>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $StudySessionsTable,
                    StudySession
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StudySessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StudySessionsTable,
      StudySession,
      $$StudySessionsTableFilterComposer,
      $$StudySessionsTableOrderingComposer,
      $$StudySessionsTableAnnotationComposer,
      $$StudySessionsTableCreateCompanionBuilder,
      $$StudySessionsTableUpdateCompanionBuilder,
      (
        StudySession,
        BaseReferences<_$AppDatabase, $StudySessionsTable, StudySession>,
      ),
      StudySession,
      PrefetchHooks Function()
    >;
typedef $$ErrorRecordsTableCreateCompanionBuilder =
    ErrorRecordsCompanion Function({
      Value<int> id,
      required String signature,
      required String incorrect,
      required String correct,
      required String category,
      Value<String> promptAr,
      Value<String?> lessonId,
      Value<String?> itemId,
      Value<int> count,
      Value<int> correctSince,
      required int firstSeen,
      required int lastSeen,
    });
typedef $$ErrorRecordsTableUpdateCompanionBuilder =
    ErrorRecordsCompanion Function({
      Value<int> id,
      Value<String> signature,
      Value<String> incorrect,
      Value<String> correct,
      Value<String> category,
      Value<String> promptAr,
      Value<String?> lessonId,
      Value<String?> itemId,
      Value<int> count,
      Value<int> correctSince,
      Value<int> firstSeen,
      Value<int> lastSeen,
    });

class $$ErrorRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ErrorRecordsTable> {
  $$ErrorRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get signature => $composableBuilder(
    column: $table.signature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get incorrect => $composableBuilder(
    column: $table.incorrect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get promptAr => $composableBuilder(
    column: $table.promptAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctSince => $composableBuilder(
    column: $table.correctSince,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstSeen => $composableBuilder(
    column: $table.firstSeen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSeen => $composableBuilder(
    column: $table.lastSeen,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ErrorRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ErrorRecordsTable> {
  $$ErrorRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get signature => $composableBuilder(
    column: $table.signature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get incorrect => $composableBuilder(
    column: $table.incorrect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get promptAr => $composableBuilder(
    column: $table.promptAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctSince => $composableBuilder(
    column: $table.correctSince,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstSeen => $composableBuilder(
    column: $table.firstSeen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSeen => $composableBuilder(
    column: $table.lastSeen,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ErrorRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ErrorRecordsTable> {
  $$ErrorRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get signature =>
      $composableBuilder(column: $table.signature, builder: (column) => column);

  GeneratedColumn<String> get incorrect =>
      $composableBuilder(column: $table.incorrect, builder: (column) => column);

  GeneratedColumn<String> get correct =>
      $composableBuilder(column: $table.correct, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get promptAr =>
      $composableBuilder(column: $table.promptAr, builder: (column) => column);

  GeneratedColumn<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);

  GeneratedColumn<int> get correctSince => $composableBuilder(
    column: $table.correctSince,
    builder: (column) => column,
  );

  GeneratedColumn<int> get firstSeen =>
      $composableBuilder(column: $table.firstSeen, builder: (column) => column);

  GeneratedColumn<int> get lastSeen =>
      $composableBuilder(column: $table.lastSeen, builder: (column) => column);
}

class $$ErrorRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ErrorRecordsTable,
          ErrorRecord,
          $$ErrorRecordsTableFilterComposer,
          $$ErrorRecordsTableOrderingComposer,
          $$ErrorRecordsTableAnnotationComposer,
          $$ErrorRecordsTableCreateCompanionBuilder,
          $$ErrorRecordsTableUpdateCompanionBuilder,
          (
            ErrorRecord,
            BaseReferences<_$AppDatabase, $ErrorRecordsTable, ErrorRecord>,
          ),
          ErrorRecord,
          PrefetchHooks Function()
        > {
  $$ErrorRecordsTableTableManager(_$AppDatabase db, $ErrorRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ErrorRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ErrorRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ErrorRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> signature = const Value.absent(),
                Value<String> incorrect = const Value.absent(),
                Value<String> correct = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> promptAr = const Value.absent(),
                Value<String?> lessonId = const Value.absent(),
                Value<String?> itemId = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<int> correctSince = const Value.absent(),
                Value<int> firstSeen = const Value.absent(),
                Value<int> lastSeen = const Value.absent(),
              }) => ErrorRecordsCompanion(
                id: id,
                signature: signature,
                incorrect: incorrect,
                correct: correct,
                category: category,
                promptAr: promptAr,
                lessonId: lessonId,
                itemId: itemId,
                count: count,
                correctSince: correctSince,
                firstSeen: firstSeen,
                lastSeen: lastSeen,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String signature,
                required String incorrect,
                required String correct,
                required String category,
                Value<String> promptAr = const Value.absent(),
                Value<String?> lessonId = const Value.absent(),
                Value<String?> itemId = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<int> correctSince = const Value.absent(),
                required int firstSeen,
                required int lastSeen,
              }) => ErrorRecordsCompanion.insert(
                id: id,
                signature: signature,
                incorrect: incorrect,
                correct: correct,
                category: category,
                promptAr: promptAr,
                lessonId: lessonId,
                itemId: itemId,
                count: count,
                correctSince: correctSince,
                firstSeen: firstSeen,
                lastSeen: lastSeen,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ErrorRecordsTable, ErrorRecord>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ErrorRecordsTable,
                    ErrorRecord
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ErrorRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ErrorRecordsTable,
      ErrorRecord,
      $$ErrorRecordsTableFilterComposer,
      $$ErrorRecordsTableOrderingComposer,
      $$ErrorRecordsTableAnnotationComposer,
      $$ErrorRecordsTableCreateCompanionBuilder,
      $$ErrorRecordsTableUpdateCompanionBuilder,
      (
        ErrorRecord,
        BaseReferences<_$AppDatabase, $ErrorRecordsTable, ErrorRecord>,
      ),
      ErrorRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$LessonProgressTableTableManager get lessonProgress =>
      $$LessonProgressTableTableManager(_db, _db.lessonProgress);
  $$ActivityAttemptsTableTableManager get activityAttempts =>
      $$ActivityAttemptsTableTableManager(_db, _db.activityAttempts);
  $$ReviewCardsTableTableManager get reviewCards =>
      $$ReviewCardsTableTableManager(_db, _db.reviewCards);
  $$ReviewLogsTableTableManager get reviewLogs =>
      $$ReviewLogsTableTableManager(_db, _db.reviewLogs);
  $$StudySessionsTableTableManager get studySessions =>
      $$StudySessionsTableTableManager(_db, _db.studySessions);
  $$ErrorRecordsTableTableManager get errorRecords =>
      $$ErrorRecordsTableTableManager(_db, _db.errorRecords);
}
