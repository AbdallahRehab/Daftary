// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PeopleTable extends People with TableInfo<$PeopleTable, PeopleData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeopleTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedNameMeta = const VerificationMeta(
    'normalizedName',
  );
  @override
  late final GeneratedColumn<String> normalizedName = GeneratedColumn<String>(
    'normalized_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneNumberMeta = const VerificationMeta(
    'phoneNumber',
  );
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
    'phone_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarPathMeta = const VerificationMeta(
    'avatarPath',
  );
  @override
  late final GeneratedColumn<String> avatarPath = GeneratedColumn<String>(
    'avatar_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _relationshipTagMeta = const VerificationMeta(
    'relationshipTag',
  );
  @override
  late final GeneratedColumn<String> relationshipTag = GeneratedColumn<String>(
    'relationship_tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    normalizedName,
    phoneNumber,
    avatarPath,
    relationshipTag,
    notes,
    isArchived,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'people';
  @override
  VerificationContext validateIntegrity(
    Insertable<PeopleData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('normalized_name')) {
      context.handle(
        _normalizedNameMeta,
        normalizedName.isAcceptableOrUnknown(
          data['normalized_name']!,
          _normalizedNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedNameMeta);
    }
    if (data.containsKey('phone_number')) {
      context.handle(
        _phoneNumberMeta,
        phoneNumber.isAcceptableOrUnknown(
          data['phone_number']!,
          _phoneNumberMeta,
        ),
      );
    }
    if (data.containsKey('avatar_path')) {
      context.handle(
        _avatarPathMeta,
        avatarPath.isAcceptableOrUnknown(data['avatar_path']!, _avatarPathMeta),
      );
    }
    if (data.containsKey('relationship_tag')) {
      context.handle(
        _relationshipTagMeta,
        relationshipTag.isAcceptableOrUnknown(
          data['relationship_tag']!,
          _relationshipTagMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PeopleData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PeopleData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      normalizedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_name'],
      )!,
      phoneNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone_number'],
      ),
      avatarPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_path'],
      ),
      relationshipTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relationship_tag'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PeopleTable createAlias(String alias) {
    return $PeopleTable(attachedDatabase, alias);
  }
}

class PeopleData extends DataClass implements Insertable<PeopleData> {
  final String id;
  final String name;
  final String normalizedName;
  final String? phoneNumber;
  final String? avatarPath;
  final String? relationshipTag;
  final String? notes;
  final bool isArchived;
  final int createdAt;
  final int updatedAt;
  const PeopleData({
    required this.id,
    required this.name,
    required this.normalizedName,
    this.phoneNumber,
    this.avatarPath,
    this.relationshipTag,
    this.notes,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['normalized_name'] = Variable<String>(normalizedName);
    if (!nullToAbsent || phoneNumber != null) {
      map['phone_number'] = Variable<String>(phoneNumber);
    }
    if (!nullToAbsent || avatarPath != null) {
      map['avatar_path'] = Variable<String>(avatarPath);
    }
    if (!nullToAbsent || relationshipTag != null) {
      map['relationship_tag'] = Variable<String>(relationshipTag);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  PeopleCompanion toCompanion(bool nullToAbsent) {
    return PeopleCompanion(
      id: Value(id),
      name: Value(name),
      normalizedName: Value(normalizedName),
      phoneNumber: phoneNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneNumber),
      avatarPath: avatarPath == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarPath),
      relationshipTag: relationshipTag == null && nullToAbsent
          ? const Value.absent()
          : Value(relationshipTag),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PeopleData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeopleData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      normalizedName: serializer.fromJson<String>(json['normalizedName']),
      phoneNumber: serializer.fromJson<String?>(json['phoneNumber']),
      avatarPath: serializer.fromJson<String?>(json['avatarPath']),
      relationshipTag: serializer.fromJson<String?>(json['relationshipTag']),
      notes: serializer.fromJson<String?>(json['notes']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'normalizedName': serializer.toJson<String>(normalizedName),
      'phoneNumber': serializer.toJson<String?>(phoneNumber),
      'avatarPath': serializer.toJson<String?>(avatarPath),
      'relationshipTag': serializer.toJson<String?>(relationshipTag),
      'notes': serializer.toJson<String?>(notes),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  PeopleData copyWith({
    String? id,
    String? name,
    String? normalizedName,
    Value<String?> phoneNumber = const Value.absent(),
    Value<String?> avatarPath = const Value.absent(),
    Value<String?> relationshipTag = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    bool? isArchived,
    int? createdAt,
    int? updatedAt,
  }) => PeopleData(
    id: id ?? this.id,
    name: name ?? this.name,
    normalizedName: normalizedName ?? this.normalizedName,
    phoneNumber: phoneNumber.present ? phoneNumber.value : this.phoneNumber,
    avatarPath: avatarPath.present ? avatarPath.value : this.avatarPath,
    relationshipTag: relationshipTag.present
        ? relationshipTag.value
        : this.relationshipTag,
    notes: notes.present ? notes.value : this.notes,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PeopleData copyWithCompanion(PeopleCompanion data) {
    return PeopleData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      normalizedName: data.normalizedName.present
          ? data.normalizedName.value
          : this.normalizedName,
      phoneNumber: data.phoneNumber.present
          ? data.phoneNumber.value
          : this.phoneNumber,
      avatarPath: data.avatarPath.present
          ? data.avatarPath.value
          : this.avatarPath,
      relationshipTag: data.relationshipTag.present
          ? data.relationshipTag.value
          : this.relationshipTag,
      notes: data.notes.present ? data.notes.value : this.notes,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeopleData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('relationshipTag: $relationshipTag, ')
          ..write('notes: $notes, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    normalizedName,
    phoneNumber,
    avatarPath,
    relationshipTag,
    notes,
    isArchived,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeopleData &&
          other.id == this.id &&
          other.name == this.name &&
          other.normalizedName == this.normalizedName &&
          other.phoneNumber == this.phoneNumber &&
          other.avatarPath == this.avatarPath &&
          other.relationshipTag == this.relationshipTag &&
          other.notes == this.notes &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PeopleCompanion extends UpdateCompanion<PeopleData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> normalizedName;
  final Value<String?> phoneNumber;
  final Value<String?> avatarPath;
  final Value<String?> relationshipTag;
  final Value<String?> notes;
  final Value<bool> isArchived;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const PeopleCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.normalizedName = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.avatarPath = const Value.absent(),
    this.relationshipTag = const Value.absent(),
    this.notes = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PeopleCompanion.insert({
    required String id,
    required String name,
    required String normalizedName,
    this.phoneNumber = const Value.absent(),
    this.avatarPath = const Value.absent(),
    this.relationshipTag = const Value.absent(),
    this.notes = const Value.absent(),
    this.isArchived = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       normalizedName = Value(normalizedName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PeopleData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? normalizedName,
    Expression<String>? phoneNumber,
    Expression<String>? avatarPath,
    Expression<String>? relationshipTag,
    Expression<String>? notes,
    Expression<bool>? isArchived,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (normalizedName != null) 'normalized_name': normalizedName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (avatarPath != null) 'avatar_path': avatarPath,
      if (relationshipTag != null) 'relationship_tag': relationshipTag,
      if (notes != null) 'notes': notes,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PeopleCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? normalizedName,
    Value<String?>? phoneNumber,
    Value<String?>? avatarPath,
    Value<String?>? relationshipTag,
    Value<String?>? notes,
    Value<bool>? isArchived,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return PeopleCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarPath: avatarPath ?? this.avatarPath,
      relationshipTag: relationshipTag ?? this.relationshipTag,
      notes: notes ?? this.notes,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (normalizedName.present) {
      map['normalized_name'] = Variable<String>(normalizedName.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (avatarPath.present) {
      map['avatar_path'] = Variable<String>(avatarPath.value);
    }
    if (relationshipTag.present) {
      map['relationship_tag'] = Variable<String>(relationshipTag.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeopleCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('relationshipTag: $relationshipTag, ')
          ..write('notes: $notes, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OccasionsTable extends Occasions
    with TableInfo<$OccasionsTable, Occasion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OccasionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    idempotencyKey,
    name,
    date,
    type,
    notes,
    isArchived,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'occasions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Occasion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Occasion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Occasion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $OccasionsTable createAlias(String alias) {
    return $OccasionsTable(attachedDatabase, alias);
  }
}

class Occasion extends DataClass implements Insertable<Occasion> {
  final String id;
  final String idempotencyKey;
  final String name;

  /// Epoch millis, date-only. May be in the future (pre-planned occasions).
  final int date;

  /// A standard `OccasionType` value or free text, same open-set pattern as
  /// [People.relationshipTag] (008 research.md Decision 6).
  final String type;
  final String? notes;
  final bool isArchived;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const Occasion({
    required this.id,
    required this.idempotencyKey,
    required this.name,
    required this.date,
    required this.type,
    this.notes,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['name'] = Variable<String>(name);
    map['date'] = Variable<int>(date);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  OccasionsCompanion toCompanion(bool nullToAbsent) {
    return OccasionsCompanion(
      id: Value(id),
      idempotencyKey: Value(idempotencyKey),
      name: Value(name),
      date: Value(date),
      type: Value(type),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Occasion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Occasion(
      id: serializer.fromJson<String>(json['id']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      name: serializer.fromJson<String>(json['name']),
      date: serializer.fromJson<int>(json['date']),
      type: serializer.fromJson<String>(json['type']),
      notes: serializer.fromJson<String?>(json['notes']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'name': serializer.toJson<String>(name),
      'date': serializer.toJson<int>(date),
      'type': serializer.toJson<String>(type),
      'notes': serializer.toJson<String?>(notes),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  Occasion copyWith({
    String? id,
    String? idempotencyKey,
    String? name,
    int? date,
    String? type,
    Value<String?> notes = const Value.absent(),
    bool? isArchived,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
  }) => Occasion(
    id: id ?? this.id,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    name: name ?? this.name,
    date: date ?? this.date,
    type: type ?? this.type,
    notes: notes.present ? notes.value : this.notes,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Occasion copyWithCompanion(OccasionsCompanion data) {
    return Occasion(
      id: data.id.present ? data.id.value : this.id,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      name: data.name.present ? data.name.value : this.name,
      date: data.date.present ? data.date.value : this.date,
      type: data.type.present ? data.type.value : this.type,
      notes: data.notes.present ? data.notes.value : this.notes,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Occasion(')
          ..write('id: $id, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('name: $name, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('notes: $notes, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    idempotencyKey,
    name,
    date,
    type,
    notes,
    isArchived,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Occasion &&
          other.id == this.id &&
          other.idempotencyKey == this.idempotencyKey &&
          other.name == this.name &&
          other.date == this.date &&
          other.type == this.type &&
          other.notes == this.notes &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class OccasionsCompanion extends UpdateCompanion<Occasion> {
  final Value<String> id;
  final Value<String> idempotencyKey;
  final Value<String> name;
  final Value<int> date;
  final Value<String> type;
  final Value<String?> notes;
  final Value<bool> isArchived;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const OccasionsCompanion({
    this.id = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.name = const Value.absent(),
    this.date = const Value.absent(),
    this.type = const Value.absent(),
    this.notes = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OccasionsCompanion.insert({
    required String id,
    required String idempotencyKey,
    required String name,
    required int date,
    required String type,
    this.notes = const Value.absent(),
    this.isArchived = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       idempotencyKey = Value(idempotencyKey),
       name = Value(name),
       date = Value(date),
       type = Value(type),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Occasion> custom({
    Expression<String>? id,
    Expression<String>? idempotencyKey,
    Expression<String>? name,
    Expression<int>? date,
    Expression<String>? type,
    Expression<String>? notes,
    Expression<bool>? isArchived,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (name != null) 'name': name,
      if (date != null) 'date': date,
      if (type != null) 'type': type,
      if (notes != null) 'notes': notes,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OccasionsCompanion copyWith({
    Value<String>? id,
    Value<String>? idempotencyKey,
    Value<String>? name,
    Value<int>? date,
    Value<String>? type,
    Value<String?>? notes,
    Value<bool>? isArchived,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return OccasionsCompanion(
      id: id ?? this.id,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      name: name ?? this.name,
      date: date ?? this.date,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(date.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OccasionsCompanion(')
          ..write('id: $id, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('name: $name, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('notes: $notes, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MoneyTransactionsTable extends MoneyTransactions
    with TableInfo<$MoneyTransactionsTable, MoneyTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MoneyTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES people (id)',
    ),
  );
  static const VerificationMeta _amountMinorUnitsMeta = const VerificationMeta(
    'amountMinorUnits',
  );
  @override
  late final GeneratedColumn<int> amountMinorUnits = GeneratedColumn<int>(
    'amount_minor_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
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
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occasionIdMeta = const VerificationMeta(
    'occasionId',
  );
  @override
  late final GeneratedColumn<String> occasionId = GeneratedColumn<String>(
    'occasion_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES occasions (id)',
    ),
  );
  static const VerificationMeta _countsTowardBalanceMeta =
      const VerificationMeta('countsTowardBalance');
  @override
  late final GeneratedColumn<bool> countsTowardBalance = GeneratedColumn<bool>(
    'counts_toward_balance',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("counts_toward_balance" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _ocrScanIdMeta = const VerificationMeta(
    'ocrScanId',
  );
  @override
  late final GeneratedColumn<String> ocrScanId = GeneratedColumn<String>(
    'ocr_scan_id',
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
  static const VerificationMeta _editedAtMeta = const VerificationMeta(
    'editedAt',
  );
  @override
  late final GeneratedColumn<int> editedAt = GeneratedColumn<int>(
    'edited_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    idempotencyKey,
    personId,
    amountMinorUnits,
    direction,
    kind,
    date,
    note,
    occasionId,
    countsTowardBalance,
    source,
    ocrScanId,
    createdAt,
    editedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'money_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<MoneyTransaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('amount_minor_units')) {
      context.handle(
        _amountMinorUnitsMeta,
        amountMinorUnits.isAcceptableOrUnknown(
          data['amount_minor_units']!,
          _amountMinorUnitsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorUnitsMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('occasion_id')) {
      context.handle(
        _occasionIdMeta,
        occasionId.isAcceptableOrUnknown(data['occasion_id']!, _occasionIdMeta),
      );
    }
    if (data.containsKey('counts_toward_balance')) {
      context.handle(
        _countsTowardBalanceMeta,
        countsTowardBalance.isAcceptableOrUnknown(
          data['counts_toward_balance']!,
          _countsTowardBalanceMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('ocr_scan_id')) {
      context.handle(
        _ocrScanIdMeta,
        ocrScanId.isAcceptableOrUnknown(data['ocr_scan_id']!, _ocrScanIdMeta),
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
    if (data.containsKey('edited_at')) {
      context.handle(
        _editedAtMeta,
        editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MoneyTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MoneyTransaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      )!,
      amountMinorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor_units'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      occasionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occasion_id'],
      ),
      countsTowardBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}counts_toward_balance'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      ocrScanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ocr_scan_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      editedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}edited_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $MoneyTransactionsTable createAlias(String alias) {
    return $MoneyTransactionsTable(attachedDatabase, alias);
  }
}

class MoneyTransaction extends DataClass
    implements Insertable<MoneyTransaction> {
  final String id;
  final String idempotencyKey;
  final String personId;
  final int amountMinorUnits;
  final String direction;
  final String kind;
  final int date;
  final String? note;

  /// The [Occasions] row this contribution was recorded under (008).
  /// `NULL` for every ordinary transaction — which is every row that
  /// existed before this feature, so the migration needs no backfill.
  final String? occasionId;

  /// Whether this row counts toward the person's net balance (008 FR-018).
  /// `TRUE` for every kind but an occasion contribution recorded as
  /// non-counting, so the default keeps all pre-existing rows correct.
  final bool countsTowardBalance;

  /// How this row was created: `'manual'` or `'ocr'` (009 FR-012). The
  /// default keeps every pre-009 row correct with no backfill — they were
  /// all typed in by hand.
  final String source;

  /// The [OcrScans] row this transaction was confirmed from (009).
  /// `NULL` for every manually entered row. Intentionally *not* declared
  /// as a `references()` FK: 009 FR-023 lets the user delete a past scan
  /// while the transactions it produced stay — a real FK would either
  /// block that delete or cascade it, and both are wrong here
  /// (data-model.md Relationships).
  final String? ocrScanId;
  final int createdAt;
  final int? editedAt;
  final int? deletedAt;
  const MoneyTransaction({
    required this.id,
    required this.idempotencyKey,
    required this.personId,
    required this.amountMinorUnits,
    required this.direction,
    required this.kind,
    required this.date,
    this.note,
    this.occasionId,
    required this.countsTowardBalance,
    required this.source,
    this.ocrScanId,
    required this.createdAt,
    this.editedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['person_id'] = Variable<String>(personId);
    map['amount_minor_units'] = Variable<int>(amountMinorUnits);
    map['direction'] = Variable<String>(direction);
    map['kind'] = Variable<String>(kind);
    map['date'] = Variable<int>(date);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || occasionId != null) {
      map['occasion_id'] = Variable<String>(occasionId);
    }
    map['counts_toward_balance'] = Variable<bool>(countsTowardBalance);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || ocrScanId != null) {
      map['ocr_scan_id'] = Variable<String>(ocrScanId);
    }
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || editedAt != null) {
      map['edited_at'] = Variable<int>(editedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  MoneyTransactionsCompanion toCompanion(bool nullToAbsent) {
    return MoneyTransactionsCompanion(
      id: Value(id),
      idempotencyKey: Value(idempotencyKey),
      personId: Value(personId),
      amountMinorUnits: Value(amountMinorUnits),
      direction: Value(direction),
      kind: Value(kind),
      date: Value(date),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      occasionId: occasionId == null && nullToAbsent
          ? const Value.absent()
          : Value(occasionId),
      countsTowardBalance: Value(countsTowardBalance),
      source: Value(source),
      ocrScanId: ocrScanId == null && nullToAbsent
          ? const Value.absent()
          : Value(ocrScanId),
      createdAt: Value(createdAt),
      editedAt: editedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(editedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory MoneyTransaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MoneyTransaction(
      id: serializer.fromJson<String>(json['id']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      personId: serializer.fromJson<String>(json['personId']),
      amountMinorUnits: serializer.fromJson<int>(json['amountMinorUnits']),
      direction: serializer.fromJson<String>(json['direction']),
      kind: serializer.fromJson<String>(json['kind']),
      date: serializer.fromJson<int>(json['date']),
      note: serializer.fromJson<String?>(json['note']),
      occasionId: serializer.fromJson<String?>(json['occasionId']),
      countsTowardBalance: serializer.fromJson<bool>(
        json['countsTowardBalance'],
      ),
      source: serializer.fromJson<String>(json['source']),
      ocrScanId: serializer.fromJson<String?>(json['ocrScanId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      editedAt: serializer.fromJson<int?>(json['editedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'personId': serializer.toJson<String>(personId),
      'amountMinorUnits': serializer.toJson<int>(amountMinorUnits),
      'direction': serializer.toJson<String>(direction),
      'kind': serializer.toJson<String>(kind),
      'date': serializer.toJson<int>(date),
      'note': serializer.toJson<String?>(note),
      'occasionId': serializer.toJson<String?>(occasionId),
      'countsTowardBalance': serializer.toJson<bool>(countsTowardBalance),
      'source': serializer.toJson<String>(source),
      'ocrScanId': serializer.toJson<String?>(ocrScanId),
      'createdAt': serializer.toJson<int>(createdAt),
      'editedAt': serializer.toJson<int?>(editedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  MoneyTransaction copyWith({
    String? id,
    String? idempotencyKey,
    String? personId,
    int? amountMinorUnits,
    String? direction,
    String? kind,
    int? date,
    Value<String?> note = const Value.absent(),
    Value<String?> occasionId = const Value.absent(),
    bool? countsTowardBalance,
    String? source,
    Value<String?> ocrScanId = const Value.absent(),
    int? createdAt,
    Value<int?> editedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
  }) => MoneyTransaction(
    id: id ?? this.id,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    personId: personId ?? this.personId,
    amountMinorUnits: amountMinorUnits ?? this.amountMinorUnits,
    direction: direction ?? this.direction,
    kind: kind ?? this.kind,
    date: date ?? this.date,
    note: note.present ? note.value : this.note,
    occasionId: occasionId.present ? occasionId.value : this.occasionId,
    countsTowardBalance: countsTowardBalance ?? this.countsTowardBalance,
    source: source ?? this.source,
    ocrScanId: ocrScanId.present ? ocrScanId.value : this.ocrScanId,
    createdAt: createdAt ?? this.createdAt,
    editedAt: editedAt.present ? editedAt.value : this.editedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  MoneyTransaction copyWithCompanion(MoneyTransactionsCompanion data) {
    return MoneyTransaction(
      id: data.id.present ? data.id.value : this.id,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      personId: data.personId.present ? data.personId.value : this.personId,
      amountMinorUnits: data.amountMinorUnits.present
          ? data.amountMinorUnits.value
          : this.amountMinorUnits,
      direction: data.direction.present ? data.direction.value : this.direction,
      kind: data.kind.present ? data.kind.value : this.kind,
      date: data.date.present ? data.date.value : this.date,
      note: data.note.present ? data.note.value : this.note,
      occasionId: data.occasionId.present
          ? data.occasionId.value
          : this.occasionId,
      countsTowardBalance: data.countsTowardBalance.present
          ? data.countsTowardBalance.value
          : this.countsTowardBalance,
      source: data.source.present ? data.source.value : this.source,
      ocrScanId: data.ocrScanId.present ? data.ocrScanId.value : this.ocrScanId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MoneyTransaction(')
          ..write('id: $id, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('personId: $personId, ')
          ..write('amountMinorUnits: $amountMinorUnits, ')
          ..write('direction: $direction, ')
          ..write('kind: $kind, ')
          ..write('date: $date, ')
          ..write('note: $note, ')
          ..write('occasionId: $occasionId, ')
          ..write('countsTowardBalance: $countsTowardBalance, ')
          ..write('source: $source, ')
          ..write('ocrScanId: $ocrScanId, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    idempotencyKey,
    personId,
    amountMinorUnits,
    direction,
    kind,
    date,
    note,
    occasionId,
    countsTowardBalance,
    source,
    ocrScanId,
    createdAt,
    editedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MoneyTransaction &&
          other.id == this.id &&
          other.idempotencyKey == this.idempotencyKey &&
          other.personId == this.personId &&
          other.amountMinorUnits == this.amountMinorUnits &&
          other.direction == this.direction &&
          other.kind == this.kind &&
          other.date == this.date &&
          other.note == this.note &&
          other.occasionId == this.occasionId &&
          other.countsTowardBalance == this.countsTowardBalance &&
          other.source == this.source &&
          other.ocrScanId == this.ocrScanId &&
          other.createdAt == this.createdAt &&
          other.editedAt == this.editedAt &&
          other.deletedAt == this.deletedAt);
}

class MoneyTransactionsCompanion extends UpdateCompanion<MoneyTransaction> {
  final Value<String> id;
  final Value<String> idempotencyKey;
  final Value<String> personId;
  final Value<int> amountMinorUnits;
  final Value<String> direction;
  final Value<String> kind;
  final Value<int> date;
  final Value<String?> note;
  final Value<String?> occasionId;
  final Value<bool> countsTowardBalance;
  final Value<String> source;
  final Value<String?> ocrScanId;
  final Value<int> createdAt;
  final Value<int?> editedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const MoneyTransactionsCompanion({
    this.id = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.personId = const Value.absent(),
    this.amountMinorUnits = const Value.absent(),
    this.direction = const Value.absent(),
    this.kind = const Value.absent(),
    this.date = const Value.absent(),
    this.note = const Value.absent(),
    this.occasionId = const Value.absent(),
    this.countsTowardBalance = const Value.absent(),
    this.source = const Value.absent(),
    this.ocrScanId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MoneyTransactionsCompanion.insert({
    required String id,
    required String idempotencyKey,
    required String personId,
    required int amountMinorUnits,
    required String direction,
    required String kind,
    required int date,
    this.note = const Value.absent(),
    this.occasionId = const Value.absent(),
    this.countsTowardBalance = const Value.absent(),
    this.source = const Value.absent(),
    this.ocrScanId = const Value.absent(),
    required int createdAt,
    this.editedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       idempotencyKey = Value(idempotencyKey),
       personId = Value(personId),
       amountMinorUnits = Value(amountMinorUnits),
       direction = Value(direction),
       kind = Value(kind),
       date = Value(date),
       createdAt = Value(createdAt);
  static Insertable<MoneyTransaction> custom({
    Expression<String>? id,
    Expression<String>? idempotencyKey,
    Expression<String>? personId,
    Expression<int>? amountMinorUnits,
    Expression<String>? direction,
    Expression<String>? kind,
    Expression<int>? date,
    Expression<String>? note,
    Expression<String>? occasionId,
    Expression<bool>? countsTowardBalance,
    Expression<String>? source,
    Expression<String>? ocrScanId,
    Expression<int>? createdAt,
    Expression<int>? editedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (personId != null) 'person_id': personId,
      if (amountMinorUnits != null) 'amount_minor_units': amountMinorUnits,
      if (direction != null) 'direction': direction,
      if (kind != null) 'kind': kind,
      if (date != null) 'date': date,
      if (note != null) 'note': note,
      if (occasionId != null) 'occasion_id': occasionId,
      if (countsTowardBalance != null)
        'counts_toward_balance': countsTowardBalance,
      if (source != null) 'source': source,
      if (ocrScanId != null) 'ocr_scan_id': ocrScanId,
      if (createdAt != null) 'created_at': createdAt,
      if (editedAt != null) 'edited_at': editedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MoneyTransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? idempotencyKey,
    Value<String>? personId,
    Value<int>? amountMinorUnits,
    Value<String>? direction,
    Value<String>? kind,
    Value<int>? date,
    Value<String?>? note,
    Value<String?>? occasionId,
    Value<bool>? countsTowardBalance,
    Value<String>? source,
    Value<String?>? ocrScanId,
    Value<int>? createdAt,
    Value<int?>? editedAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return MoneyTransactionsCompanion(
      id: id ?? this.id,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      personId: personId ?? this.personId,
      amountMinorUnits: amountMinorUnits ?? this.amountMinorUnits,
      direction: direction ?? this.direction,
      kind: kind ?? this.kind,
      date: date ?? this.date,
      note: note ?? this.note,
      occasionId: occasionId ?? this.occasionId,
      countsTowardBalance: countsTowardBalance ?? this.countsTowardBalance,
      source: source ?? this.source,
      ocrScanId: ocrScanId ?? this.ocrScanId,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (amountMinorUnits.present) {
      map['amount_minor_units'] = Variable<int>(amountMinorUnits.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(date.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (occasionId.present) {
      map['occasion_id'] = Variable<String>(occasionId.value);
    }
    if (countsTowardBalance.present) {
      map['counts_toward_balance'] = Variable<bool>(countsTowardBalance.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (ocrScanId.present) {
      map['ocr_scan_id'] = Variable<String>(ocrScanId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<int>(editedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MoneyTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('personId: $personId, ')
          ..write('amountMinorUnits: $amountMinorUnits, ')
          ..write('direction: $direction, ')
          ..write('kind: $kind, ')
          ..write('date: $date, ')
          ..write('note: $note, ')
          ..write('occasionId: $occasionId, ')
          ..write('countsTowardBalance: $countsTowardBalance, ')
          ..write('source: $source, ')
          ..write('ocrScanId: $ocrScanId, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionAuditEntriesTable extends TransactionAuditEntries
    with TableInfo<$TransactionAuditEntriesTable, TransactionAuditEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionAuditEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES money_transactions (id)',
    ),
  );
  static const VerificationMeta _changeTypeMeta = const VerificationMeta(
    'changeType',
  );
  @override
  late final GeneratedColumn<String> changeType = GeneratedColumn<String>(
    'change_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _previousValuesJsonMeta =
      const VerificationMeta('previousValuesJson');
  @override
  late final GeneratedColumn<String> previousValuesJson =
      GeneratedColumn<String>(
        'previous_values_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _changedAtMeta = const VerificationMeta(
    'changedAt',
  );
  @override
  late final GeneratedColumn<int> changedAt = GeneratedColumn<int>(
    'changed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    transactionId,
    changeType,
    previousValuesJson,
    changedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_audit_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionAuditEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('change_type')) {
      context.handle(
        _changeTypeMeta,
        changeType.isAcceptableOrUnknown(data['change_type']!, _changeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_changeTypeMeta);
    }
    if (data.containsKey('previous_values_json')) {
      context.handle(
        _previousValuesJsonMeta,
        previousValuesJson.isAcceptableOrUnknown(
          data['previous_values_json']!,
          _previousValuesJsonMeta,
        ),
      );
    }
    if (data.containsKey('changed_at')) {
      context.handle(
        _changedAtMeta,
        changedAt.isAcceptableOrUnknown(data['changed_at']!, _changedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_changedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionAuditEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionAuditEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      )!,
      changeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}change_type'],
      )!,
      previousValuesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous_values_json'],
      ),
      changedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}changed_at'],
      )!,
    );
  }

  @override
  $TransactionAuditEntriesTable createAlias(String alias) {
    return $TransactionAuditEntriesTable(attachedDatabase, alias);
  }
}

class TransactionAuditEntry extends DataClass
    implements Insertable<TransactionAuditEntry> {
  final String id;
  final String transactionId;
  final String changeType;
  final String? previousValuesJson;
  final int changedAt;
  const TransactionAuditEntry({
    required this.id,
    required this.transactionId,
    required this.changeType,
    this.previousValuesJson,
    required this.changedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['transaction_id'] = Variable<String>(transactionId);
    map['change_type'] = Variable<String>(changeType);
    if (!nullToAbsent || previousValuesJson != null) {
      map['previous_values_json'] = Variable<String>(previousValuesJson);
    }
    map['changed_at'] = Variable<int>(changedAt);
    return map;
  }

  TransactionAuditEntriesCompanion toCompanion(bool nullToAbsent) {
    return TransactionAuditEntriesCompanion(
      id: Value(id),
      transactionId: Value(transactionId),
      changeType: Value(changeType),
      previousValuesJson: previousValuesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(previousValuesJson),
      changedAt: Value(changedAt),
    );
  }

  factory TransactionAuditEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionAuditEntry(
      id: serializer.fromJson<String>(json['id']),
      transactionId: serializer.fromJson<String>(json['transactionId']),
      changeType: serializer.fromJson<String>(json['changeType']),
      previousValuesJson: serializer.fromJson<String?>(
        json['previousValuesJson'],
      ),
      changedAt: serializer.fromJson<int>(json['changedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'transactionId': serializer.toJson<String>(transactionId),
      'changeType': serializer.toJson<String>(changeType),
      'previousValuesJson': serializer.toJson<String?>(previousValuesJson),
      'changedAt': serializer.toJson<int>(changedAt),
    };
  }

  TransactionAuditEntry copyWith({
    String? id,
    String? transactionId,
    String? changeType,
    Value<String?> previousValuesJson = const Value.absent(),
    int? changedAt,
  }) => TransactionAuditEntry(
    id: id ?? this.id,
    transactionId: transactionId ?? this.transactionId,
    changeType: changeType ?? this.changeType,
    previousValuesJson: previousValuesJson.present
        ? previousValuesJson.value
        : this.previousValuesJson,
    changedAt: changedAt ?? this.changedAt,
  );
  TransactionAuditEntry copyWithCompanion(
    TransactionAuditEntriesCompanion data,
  ) {
    return TransactionAuditEntry(
      id: data.id.present ? data.id.value : this.id,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      changeType: data.changeType.present
          ? data.changeType.value
          : this.changeType,
      previousValuesJson: data.previousValuesJson.present
          ? data.previousValuesJson.value
          : this.previousValuesJson,
      changedAt: data.changedAt.present ? data.changedAt.value : this.changedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionAuditEntry(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('changeType: $changeType, ')
          ..write('previousValuesJson: $previousValuesJson, ')
          ..write('changedAt: $changedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, transactionId, changeType, previousValuesJson, changedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionAuditEntry &&
          other.id == this.id &&
          other.transactionId == this.transactionId &&
          other.changeType == this.changeType &&
          other.previousValuesJson == this.previousValuesJson &&
          other.changedAt == this.changedAt);
}

class TransactionAuditEntriesCompanion
    extends UpdateCompanion<TransactionAuditEntry> {
  final Value<String> id;
  final Value<String> transactionId;
  final Value<String> changeType;
  final Value<String?> previousValuesJson;
  final Value<int> changedAt;
  final Value<int> rowid;
  const TransactionAuditEntriesCompanion({
    this.id = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.changeType = const Value.absent(),
    this.previousValuesJson = const Value.absent(),
    this.changedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionAuditEntriesCompanion.insert({
    required String id,
    required String transactionId,
    required String changeType,
    this.previousValuesJson = const Value.absent(),
    required int changedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       transactionId = Value(transactionId),
       changeType = Value(changeType),
       changedAt = Value(changedAt);
  static Insertable<TransactionAuditEntry> custom({
    Expression<String>? id,
    Expression<String>? transactionId,
    Expression<String>? changeType,
    Expression<String>? previousValuesJson,
    Expression<int>? changedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      if (changeType != null) 'change_type': changeType,
      if (previousValuesJson != null)
        'previous_values_json': previousValuesJson,
      if (changedAt != null) 'changed_at': changedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionAuditEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? transactionId,
    Value<String>? changeType,
    Value<String?>? previousValuesJson,
    Value<int>? changedAt,
    Value<int>? rowid,
  }) {
    return TransactionAuditEntriesCompanion(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      changeType: changeType ?? this.changeType,
      previousValuesJson: previousValuesJson ?? this.previousValuesJson,
      changedAt: changedAt ?? this.changedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (changeType.present) {
      map['change_type'] = Variable<String>(changeType.value);
    }
    if (previousValuesJson.present) {
      map['previous_values_json'] = Variable<String>(previousValuesJson.value);
    }
    if (changedAt.present) {
      map['changed_at'] = Variable<int>(changedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionAuditEntriesCompanion(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('changeType: $changeType, ')
          ..write('previousValuesJson: $previousValuesJson, ')
          ..write('changedAt: $changedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageCodeMeta = const VerificationMeta(
    'languageCode',
  );
  @override
  late final GeneratedColumn<String> languageCode = GeneratedColumn<String>(
    'language_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _themeModeMeta = const VerificationMeta(
    'themeMode',
  );
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
    'theme_mode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    languageCode,
    themeMode,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('language_code')) {
      context.handle(
        _languageCodeMeta,
        languageCode.isAcceptableOrUnknown(
          data['language_code']!,
          _languageCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_languageCodeMeta);
    }
    if (data.containsKey('theme_mode')) {
      context.handle(
        _themeModeMeta,
        themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      languageCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_code'],
      )!,
      themeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_mode'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String id;
  final String languageCode;
  final String? themeMode;
  final int updatedAt;
  const AppSetting({
    required this.id,
    required this.languageCode,
    this.themeMode,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['language_code'] = Variable<String>(languageCode);
    if (!nullToAbsent || themeMode != null) {
      map['theme_mode'] = Variable<String>(themeMode);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      languageCode: Value(languageCode),
      themeMode: themeMode == null && nullToAbsent
          ? const Value.absent()
          : Value(themeMode),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<String>(json['id']),
      languageCode: serializer.fromJson<String>(json['languageCode']),
      themeMode: serializer.fromJson<String?>(json['themeMode']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'languageCode': serializer.toJson<String>(languageCode),
      'themeMode': serializer.toJson<String?>(themeMode),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  AppSetting copyWith({
    String? id,
    String? languageCode,
    Value<String?> themeMode = const Value.absent(),
    int? updatedAt,
  }) => AppSetting(
    id: id ?? this.id,
    languageCode: languageCode ?? this.languageCode,
    themeMode: themeMode.present ? themeMode.value : this.themeMode,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      languageCode: data.languageCode.present
          ? data.languageCode.value
          : this.languageCode,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('languageCode: $languageCode, ')
          ..write('themeMode: $themeMode, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, languageCode, themeMode, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.languageCode == this.languageCode &&
          other.themeMode == this.themeMode &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> id;
  final Value<String> languageCode;
  final Value<String?> themeMode;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.languageCode = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String id,
    required String languageCode,
    this.themeMode = const Value.absent(),
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       languageCode = Value(languageCode),
       updatedAt = Value(updatedAt);
  static Insertable<AppSetting> custom({
    Expression<String>? id,
    Expression<String>? languageCode,
    Expression<String>? themeMode,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (languageCode != null) 'language_code': languageCode,
      if (themeMode != null) 'theme_mode': themeMode,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? id,
    Value<String>? languageCode,
    Value<String?>? themeMode,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      languageCode: languageCode ?? this.languageCode,
      themeMode: themeMode ?? this.themeMode,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (languageCode.present) {
      map['language_code'] = Variable<String>(languageCode.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('languageCode: $languageCode, ')
          ..write('themeMode: $themeMode, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OnboardingStatusTable extends OnboardingStatus
    with TableInfo<$OnboardingStatusTable, OnboardingStatusData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OnboardingStatusTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCompleteMeta = const VerificationMeta(
    'isComplete',
  );
  @override
  late final GeneratedColumn<bool> isComplete = GeneratedColumn<bool>(
    'is_complete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_complete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, isComplete, completedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'onboarding_status';
  @override
  VerificationContext validateIntegrity(
    Insertable<OnboardingStatusData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('is_complete')) {
      context.handle(
        _isCompleteMeta,
        isComplete.isAcceptableOrUnknown(data['is_complete']!, _isCompleteMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OnboardingStatusData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OnboardingStatusData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      isComplete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_complete'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $OnboardingStatusTable createAlias(String alias) {
    return $OnboardingStatusTable(attachedDatabase, alias);
  }
}

class OnboardingStatusData extends DataClass
    implements Insertable<OnboardingStatusData> {
  final String id;
  final bool isComplete;
  final int? completedAt;
  const OnboardingStatusData({
    required this.id,
    required this.isComplete,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['is_complete'] = Variable<bool>(isComplete);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    return map;
  }

  OnboardingStatusCompanion toCompanion(bool nullToAbsent) {
    return OnboardingStatusCompanion(
      id: Value(id),
      isComplete: Value(isComplete),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory OnboardingStatusData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OnboardingStatusData(
      id: serializer.fromJson<String>(json['id']),
      isComplete: serializer.fromJson<bool>(json['isComplete']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'isComplete': serializer.toJson<bool>(isComplete),
      'completedAt': serializer.toJson<int?>(completedAt),
    };
  }

  OnboardingStatusData copyWith({
    String? id,
    bool? isComplete,
    Value<int?> completedAt = const Value.absent(),
  }) => OnboardingStatusData(
    id: id ?? this.id,
    isComplete: isComplete ?? this.isComplete,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  OnboardingStatusData copyWithCompanion(OnboardingStatusCompanion data) {
    return OnboardingStatusData(
      id: data.id.present ? data.id.value : this.id,
      isComplete: data.isComplete.present
          ? data.isComplete.value
          : this.isComplete,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OnboardingStatusData(')
          ..write('id: $id, ')
          ..write('isComplete: $isComplete, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, isComplete, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OnboardingStatusData &&
          other.id == this.id &&
          other.isComplete == this.isComplete &&
          other.completedAt == this.completedAt);
}

class OnboardingStatusCompanion extends UpdateCompanion<OnboardingStatusData> {
  final Value<String> id;
  final Value<bool> isComplete;
  final Value<int?> completedAt;
  final Value<int> rowid;
  const OnboardingStatusCompanion({
    this.id = const Value.absent(),
    this.isComplete = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OnboardingStatusCompanion.insert({
    required String id,
    this.isComplete = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<OnboardingStatusData> custom({
    Expression<String>? id,
    Expression<bool>? isComplete,
    Expression<int>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (isComplete != null) 'is_complete': isComplete,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OnboardingStatusCompanion copyWith({
    Value<String>? id,
    Value<bool>? isComplete,
    Value<int?>? completedAt,
    Value<int>? rowid,
  }) {
    return OnboardingStatusCompanion(
      id: id ?? this.id,
      isComplete: isComplete ?? this.isComplete,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (isComplete.present) {
      map['is_complete'] = Variable<bool>(isComplete.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OnboardingStatusCompanion(')
          ..write('id: $id, ')
          ..write('isComplete: $isComplete, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FinanceCategoriesTable extends FinanceCategories
    with TableInfo<$FinanceCategoriesTable, FinanceCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinanceCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedNameMeta = const VerificationMeta(
    'normalizedName',
  );
  @override
  late final GeneratedColumn<String> normalizedName = GeneratedColumn<String>(
    'normalized_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    normalizedName,
    type,
    icon,
    isDefault,
    isArchived,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'finance_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<FinanceCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('normalized_name')) {
      context.handle(
        _normalizedNameMeta,
        normalizedName.isAcceptableOrUnknown(
          data['normalized_name']!,
          _normalizedNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedNameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    } else if (isInserting) {
      context.missing(_iconMeta);
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FinanceCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FinanceCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      normalizedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FinanceCategoriesTable createAlias(String alias) {
    return $FinanceCategoriesTable(attachedDatabase, alias);
  }
}

class FinanceCategory extends DataClass implements Insertable<FinanceCategory> {
  final String id;
  final String name;

  /// Trimmed, whitespace-collapsed, lowercased copy of [name], indexed with
  /// [type] for the FR-008 duplicate check — same precedent as
  /// [People.normalizedName].
  final String normalizedName;

  /// `'income'` | `'expense'`. Immutable after creation (data-model.md).
  final String type;

  /// A key into `CategoryIconRegistry`, never a raw icon codepoint or hex
  /// color (research.md Decision 10).
  final String icon;
  final bool isDefault;
  final bool isArchived;
  final int createdAt;
  final int updatedAt;
  const FinanceCategory({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.type,
    required this.icon,
    required this.isDefault,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['normalized_name'] = Variable<String>(normalizedName);
    map['type'] = Variable<String>(type);
    map['icon'] = Variable<String>(icon);
    map['is_default'] = Variable<bool>(isDefault);
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  FinanceCategoriesCompanion toCompanion(bool nullToAbsent) {
    return FinanceCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      normalizedName: Value(normalizedName),
      type: Value(type),
      icon: Value(icon),
      isDefault: Value(isDefault),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FinanceCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FinanceCategory(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      normalizedName: serializer.fromJson<String>(json['normalizedName']),
      type: serializer.fromJson<String>(json['type']),
      icon: serializer.fromJson<String>(json['icon']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'normalizedName': serializer.toJson<String>(normalizedName),
      'type': serializer.toJson<String>(type),
      'icon': serializer.toJson<String>(icon),
      'isDefault': serializer.toJson<bool>(isDefault),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  FinanceCategory copyWith({
    String? id,
    String? name,
    String? normalizedName,
    String? type,
    String? icon,
    bool? isDefault,
    bool? isArchived,
    int? createdAt,
    int? updatedAt,
  }) => FinanceCategory(
    id: id ?? this.id,
    name: name ?? this.name,
    normalizedName: normalizedName ?? this.normalizedName,
    type: type ?? this.type,
    icon: icon ?? this.icon,
    isDefault: isDefault ?? this.isDefault,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FinanceCategory copyWithCompanion(FinanceCategoriesCompanion data) {
    return FinanceCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      normalizedName: data.normalizedName.present
          ? data.normalizedName.value
          : this.normalizedName,
      type: data.type.present ? data.type.value : this.type,
      icon: data.icon.present ? data.icon.value : this.icon,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FinanceCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('type: $type, ')
          ..write('icon: $icon, ')
          ..write('isDefault: $isDefault, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    normalizedName,
    type,
    icon,
    isDefault,
    isArchived,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinanceCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.normalizedName == this.normalizedName &&
          other.type == this.type &&
          other.icon == this.icon &&
          other.isDefault == this.isDefault &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FinanceCategoriesCompanion extends UpdateCompanion<FinanceCategory> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> normalizedName;
  final Value<String> type;
  final Value<String> icon;
  final Value<bool> isDefault;
  final Value<bool> isArchived;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const FinanceCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.normalizedName = const Value.absent(),
    this.type = const Value.absent(),
    this.icon = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FinanceCategoriesCompanion.insert({
    required String id,
    required String name,
    required String normalizedName,
    required String type,
    required String icon,
    this.isDefault = const Value.absent(),
    this.isArchived = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       normalizedName = Value(normalizedName),
       type = Value(type),
       icon = Value(icon),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<FinanceCategory> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? normalizedName,
    Expression<String>? type,
    Expression<String>? icon,
    Expression<bool>? isDefault,
    Expression<bool>? isArchived,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (normalizedName != null) 'normalized_name': normalizedName,
      if (type != null) 'type': type,
      if (icon != null) 'icon': icon,
      if (isDefault != null) 'is_default': isDefault,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FinanceCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? normalizedName,
    Value<String>? type,
    Value<String>? icon,
    Value<bool>? isDefault,
    Value<bool>? isArchived,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return FinanceCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (normalizedName.present) {
      map['normalized_name'] = Variable<String>(normalizedName.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FinanceCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('type: $type, ')
          ..write('icon: $icon, ')
          ..write('isDefault: $isDefault, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FinanceEntriesTable extends FinanceEntries
    with TableInfo<$FinanceEntriesTable, FinanceEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinanceEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES finance_categories (id)',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorUnitsMeta = const VerificationMeta(
    'amountMinorUnits',
  );
  @override
  late final GeneratedColumn<int> amountMinorUnits = GeneratedColumn<int>(
    'amount_minor_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
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
  static const VerificationMeta _editedAtMeta = const VerificationMeta(
    'editedAt',
  );
  @override
  late final GeneratedColumn<int> editedAt = GeneratedColumn<int>(
    'edited_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    idempotencyKey,
    categoryId,
    type,
    amountMinorUnits,
    date,
    note,
    createdAt,
    editedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'finance_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<FinanceEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('amount_minor_units')) {
      context.handle(
        _amountMinorUnitsMeta,
        amountMinorUnits.isAcceptableOrUnknown(
          data['amount_minor_units']!,
          _amountMinorUnitsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorUnitsMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
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
    if (data.containsKey('edited_at')) {
      context.handle(
        _editedAtMeta,
        editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FinanceEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FinanceEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      amountMinorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor_units'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      editedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}edited_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $FinanceEntriesTable createAlias(String alias) {
    return $FinanceEntriesTable(attachedDatabase, alias);
  }
}

class FinanceEntry extends DataClass implements Insertable<FinanceEntry> {
  final String id;
  final String idempotencyKey;
  final String categoryId;

  /// `'income'` | `'expense'`. Always equal to the referenced category's
  /// `type` (enforced in the repository, not only by the schema).
  final String type;
  final int amountMinorUnits;
  final int date;
  final String? note;
  final int createdAt;
  final int? editedAt;
  final int? deletedAt;
  const FinanceEntry({
    required this.id,
    required this.idempotencyKey,
    required this.categoryId,
    required this.type,
    required this.amountMinorUnits,
    required this.date,
    this.note,
    required this.createdAt,
    this.editedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['category_id'] = Variable<String>(categoryId);
    map['type'] = Variable<String>(type);
    map['amount_minor_units'] = Variable<int>(amountMinorUnits);
    map['date'] = Variable<int>(date);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || editedAt != null) {
      map['edited_at'] = Variable<int>(editedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  FinanceEntriesCompanion toCompanion(bool nullToAbsent) {
    return FinanceEntriesCompanion(
      id: Value(id),
      idempotencyKey: Value(idempotencyKey),
      categoryId: Value(categoryId),
      type: Value(type),
      amountMinorUnits: Value(amountMinorUnits),
      date: Value(date),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      editedAt: editedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(editedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory FinanceEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FinanceEntry(
      id: serializer.fromJson<String>(json['id']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      type: serializer.fromJson<String>(json['type']),
      amountMinorUnits: serializer.fromJson<int>(json['amountMinorUnits']),
      date: serializer.fromJson<int>(json['date']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      editedAt: serializer.fromJson<int?>(json['editedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'categoryId': serializer.toJson<String>(categoryId),
      'type': serializer.toJson<String>(type),
      'amountMinorUnits': serializer.toJson<int>(amountMinorUnits),
      'date': serializer.toJson<int>(date),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<int>(createdAt),
      'editedAt': serializer.toJson<int?>(editedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  FinanceEntry copyWith({
    String? id,
    String? idempotencyKey,
    String? categoryId,
    String? type,
    int? amountMinorUnits,
    int? date,
    Value<String?> note = const Value.absent(),
    int? createdAt,
    Value<int?> editedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
  }) => FinanceEntry(
    id: id ?? this.id,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    categoryId: categoryId ?? this.categoryId,
    type: type ?? this.type,
    amountMinorUnits: amountMinorUnits ?? this.amountMinorUnits,
    date: date ?? this.date,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    editedAt: editedAt.present ? editedAt.value : this.editedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  FinanceEntry copyWithCompanion(FinanceEntriesCompanion data) {
    return FinanceEntry(
      id: data.id.present ? data.id.value : this.id,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      type: data.type.present ? data.type.value : this.type,
      amountMinorUnits: data.amountMinorUnits.present
          ? data.amountMinorUnits.value
          : this.amountMinorUnits,
      date: data.date.present ? data.date.value : this.date,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FinanceEntry(')
          ..write('id: $id, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('categoryId: $categoryId, ')
          ..write('type: $type, ')
          ..write('amountMinorUnits: $amountMinorUnits, ')
          ..write('date: $date, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    idempotencyKey,
    categoryId,
    type,
    amountMinorUnits,
    date,
    note,
    createdAt,
    editedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinanceEntry &&
          other.id == this.id &&
          other.idempotencyKey == this.idempotencyKey &&
          other.categoryId == this.categoryId &&
          other.type == this.type &&
          other.amountMinorUnits == this.amountMinorUnits &&
          other.date == this.date &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.editedAt == this.editedAt &&
          other.deletedAt == this.deletedAt);
}

class FinanceEntriesCompanion extends UpdateCompanion<FinanceEntry> {
  final Value<String> id;
  final Value<String> idempotencyKey;
  final Value<String> categoryId;
  final Value<String> type;
  final Value<int> amountMinorUnits;
  final Value<int> date;
  final Value<String?> note;
  final Value<int> createdAt;
  final Value<int?> editedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const FinanceEntriesCompanion({
    this.id = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.type = const Value.absent(),
    this.amountMinorUnits = const Value.absent(),
    this.date = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FinanceEntriesCompanion.insert({
    required String id,
    required String idempotencyKey,
    required String categoryId,
    required String type,
    required int amountMinorUnits,
    required int date,
    this.note = const Value.absent(),
    required int createdAt,
    this.editedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       idempotencyKey = Value(idempotencyKey),
       categoryId = Value(categoryId),
       type = Value(type),
       amountMinorUnits = Value(amountMinorUnits),
       date = Value(date),
       createdAt = Value(createdAt);
  static Insertable<FinanceEntry> custom({
    Expression<String>? id,
    Expression<String>? idempotencyKey,
    Expression<String>? categoryId,
    Expression<String>? type,
    Expression<int>? amountMinorUnits,
    Expression<int>? date,
    Expression<String>? note,
    Expression<int>? createdAt,
    Expression<int>? editedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (categoryId != null) 'category_id': categoryId,
      if (type != null) 'type': type,
      if (amountMinorUnits != null) 'amount_minor_units': amountMinorUnits,
      if (date != null) 'date': date,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (editedAt != null) 'edited_at': editedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FinanceEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? idempotencyKey,
    Value<String>? categoryId,
    Value<String>? type,
    Value<int>? amountMinorUnits,
    Value<int>? date,
    Value<String?>? note,
    Value<int>? createdAt,
    Value<int?>? editedAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return FinanceEntriesCompanion(
      id: id ?? this.id,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      amountMinorUnits: amountMinorUnits ?? this.amountMinorUnits,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amountMinorUnits.present) {
      map['amount_minor_units'] = Variable<int>(amountMinorUnits.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(date.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<int>(editedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FinanceEntriesCompanion(')
          ..write('id: $id, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('categoryId: $categoryId, ')
          ..write('type: $type, ')
          ..write('amountMinorUnits: $amountMinorUnits, ')
          ..write('date: $date, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OccasionAttachmentsTable extends OccasionAttachments
    with TableInfo<$OccasionAttachmentsTable, OccasionAttachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OccasionAttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occasionIdMeta = const VerificationMeta(
    'occasionId',
  );
  @override
  late final GeneratedColumn<String> occasionId = GeneratedColumn<String>(
    'occasion_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES occasions (id)',
    ),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    occasionId,
    filePath,
    createdAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'occasion_attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<OccasionAttachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('occasion_id')) {
      context.handle(
        _occasionIdMeta,
        occasionId.isAcceptableOrUnknown(data['occasion_id']!, _occasionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_occasionIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OccasionAttachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OccasionAttachment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      occasionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occasion_id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $OccasionAttachmentsTable createAlias(String alias) {
    return $OccasionAttachmentsTable(attachedDatabase, alias);
  }
}

class OccasionAttachment extends DataClass
    implements Insertable<OccasionAttachment> {
  final String id;
  final String occasionId;
  final String filePath;
  final int createdAt;
  final int? deletedAt;
  const OccasionAttachment({
    required this.id,
    required this.occasionId,
    required this.filePath,
    required this.createdAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['occasion_id'] = Variable<String>(occasionId);
    map['file_path'] = Variable<String>(filePath);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  OccasionAttachmentsCompanion toCompanion(bool nullToAbsent) {
    return OccasionAttachmentsCompanion(
      id: Value(id),
      occasionId: Value(occasionId),
      filePath: Value(filePath),
      createdAt: Value(createdAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory OccasionAttachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OccasionAttachment(
      id: serializer.fromJson<String>(json['id']),
      occasionId: serializer.fromJson<String>(json['occasionId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'occasionId': serializer.toJson<String>(occasionId),
      'filePath': serializer.toJson<String>(filePath),
      'createdAt': serializer.toJson<int>(createdAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  OccasionAttachment copyWith({
    String? id,
    String? occasionId,
    String? filePath,
    int? createdAt,
    Value<int?> deletedAt = const Value.absent(),
  }) => OccasionAttachment(
    id: id ?? this.id,
    occasionId: occasionId ?? this.occasionId,
    filePath: filePath ?? this.filePath,
    createdAt: createdAt ?? this.createdAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  OccasionAttachment copyWithCompanion(OccasionAttachmentsCompanion data) {
    return OccasionAttachment(
      id: data.id.present ? data.id.value : this.id,
      occasionId: data.occasionId.present
          ? data.occasionId.value
          : this.occasionId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OccasionAttachment(')
          ..write('id: $id, ')
          ..write('occasionId: $occasionId, ')
          ..write('filePath: $filePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, occasionId, filePath, createdAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OccasionAttachment &&
          other.id == this.id &&
          other.occasionId == this.occasionId &&
          other.filePath == this.filePath &&
          other.createdAt == this.createdAt &&
          other.deletedAt == this.deletedAt);
}

class OccasionAttachmentsCompanion extends UpdateCompanion<OccasionAttachment> {
  final Value<String> id;
  final Value<String> occasionId;
  final Value<String> filePath;
  final Value<int> createdAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const OccasionAttachmentsCompanion({
    this.id = const Value.absent(),
    this.occasionId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OccasionAttachmentsCompanion.insert({
    required String id,
    required String occasionId,
    required String filePath,
    required int createdAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       occasionId = Value(occasionId),
       filePath = Value(filePath),
       createdAt = Value(createdAt);
  static Insertable<OccasionAttachment> custom({
    Expression<String>? id,
    Expression<String>? occasionId,
    Expression<String>? filePath,
    Expression<int>? createdAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (occasionId != null) 'occasion_id': occasionId,
      if (filePath != null) 'file_path': filePath,
      if (createdAt != null) 'created_at': createdAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OccasionAttachmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? occasionId,
    Value<String>? filePath,
    Value<int>? createdAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return OccasionAttachmentsCompanion(
      id: id ?? this.id,
      occasionId: occasionId ?? this.occasionId,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (occasionId.present) {
      map['occasion_id'] = Variable<String>(occasionId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OccasionAttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('occasionId: $occasionId, ')
          ..write('filePath: $filePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OcrScansTable extends OcrScans with TableInfo<$OcrScansTable, OcrScan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OcrScansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceImagePathMeta = const VerificationMeta(
    'sourceImagePath',
  );
  @override
  late final GeneratedColumn<String> sourceImagePath = GeneratedColumn<String>(
    'source_image_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cropBoundsMeta = const VerificationMeta(
    'cropBounds',
  );
  @override
  late final GeneratedColumn<String> cropBounds = GeneratedColumn<String>(
    'crop_bounds',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rotationDegreesMeta = const VerificationMeta(
    'rotationDegrees',
  );
  @override
  late final GeneratedColumn<int> rotationDegrees = GeneratedColumn<int>(
    'rotation_degrees',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _occasionIdMeta = const VerificationMeta(
    'occasionId',
  );
  @override
  late final GeneratedColumn<String> occasionId = GeneratedColumn<String>(
    'occasion_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES occasions (id)',
    ),
  );
  static const VerificationMeta _defaultDirectionMeta = const VerificationMeta(
    'defaultDirection',
  );
  @override
  late final GeneratedColumn<String> defaultDirection = GeneratedColumn<String>(
    'default_direction',
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
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    idempotencyKey,
    sourceImagePath,
    cropBounds,
    rotationDegrees,
    status,
    occasionId,
    defaultDirection,
    createdAt,
    completedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ocr_scans';
  @override
  VerificationContext validateIntegrity(
    Insertable<OcrScan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('source_image_path')) {
      context.handle(
        _sourceImagePathMeta,
        sourceImagePath.isAcceptableOrUnknown(
          data['source_image_path']!,
          _sourceImagePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceImagePathMeta);
    }
    if (data.containsKey('crop_bounds')) {
      context.handle(
        _cropBoundsMeta,
        cropBounds.isAcceptableOrUnknown(data['crop_bounds']!, _cropBoundsMeta),
      );
    }
    if (data.containsKey('rotation_degrees')) {
      context.handle(
        _rotationDegreesMeta,
        rotationDegrees.isAcceptableOrUnknown(
          data['rotation_degrees']!,
          _rotationDegreesMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('occasion_id')) {
      context.handle(
        _occasionIdMeta,
        occasionId.isAcceptableOrUnknown(data['occasion_id']!, _occasionIdMeta),
      );
    }
    if (data.containsKey('default_direction')) {
      context.handle(
        _defaultDirectionMeta,
        defaultDirection.isAcceptableOrUnknown(
          data['default_direction']!,
          _defaultDirectionMeta,
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
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OcrScan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OcrScan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      sourceImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_image_path'],
      )!,
      cropBounds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crop_bounds'],
      ),
      rotationDegrees: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rotation_degrees'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      occasionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occasion_id'],
      ),
      defaultDirection: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_direction'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $OcrScansTable createAlias(String alias) {
    return $OcrScansTable(attachedDatabase, alias);
  }
}

class OcrScan extends DataClass implements Insertable<OcrScan> {
  final String id;

  /// Regenerated per confirm attempt; the UNIQUE index above is what makes
  /// a double-tapped confirm a no-op rather than a second batch of
  /// transactions (009 FR-021).
  final String idempotencyKey;

  /// Path into the app's own sandboxed storage. Never a remote URL — the
  /// bytes are never uploaded (009 FR-019/FR-023).
  final String sourceImagePath;
  final String? cropBounds;
  final int rotationDegrees;

  /// `'processing'|'needsReview'|'confirmed'|'discarded'|'failed'`.
  final String status;

  /// Set when the user tags the whole batch to an occasion at review time
  /// (009 FR-014), so every entry confirmed afterwards is recorded as that
  /// occasion's contribution (008).
  final String? occasionId;

  /// `'given'|'received'`, or `NULL` while the user has not chosen a batch
  /// default yet (009 FR-005).
  final String? defaultDirection;
  final int createdAt;
  final int? completedAt;
  final int? deletedAt;
  const OcrScan({
    required this.id,
    required this.idempotencyKey,
    required this.sourceImagePath,
    this.cropBounds,
    required this.rotationDegrees,
    required this.status,
    this.occasionId,
    this.defaultDirection,
    required this.createdAt,
    this.completedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['source_image_path'] = Variable<String>(sourceImagePath);
    if (!nullToAbsent || cropBounds != null) {
      map['crop_bounds'] = Variable<String>(cropBounds);
    }
    map['rotation_degrees'] = Variable<int>(rotationDegrees);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || occasionId != null) {
      map['occasion_id'] = Variable<String>(occasionId);
    }
    if (!nullToAbsent || defaultDirection != null) {
      map['default_direction'] = Variable<String>(defaultDirection);
    }
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  OcrScansCompanion toCompanion(bool nullToAbsent) {
    return OcrScansCompanion(
      id: Value(id),
      idempotencyKey: Value(idempotencyKey),
      sourceImagePath: Value(sourceImagePath),
      cropBounds: cropBounds == null && nullToAbsent
          ? const Value.absent()
          : Value(cropBounds),
      rotationDegrees: Value(rotationDegrees),
      status: Value(status),
      occasionId: occasionId == null && nullToAbsent
          ? const Value.absent()
          : Value(occasionId),
      defaultDirection: defaultDirection == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultDirection),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory OcrScan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OcrScan(
      id: serializer.fromJson<String>(json['id']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      sourceImagePath: serializer.fromJson<String>(json['sourceImagePath']),
      cropBounds: serializer.fromJson<String?>(json['cropBounds']),
      rotationDegrees: serializer.fromJson<int>(json['rotationDegrees']),
      status: serializer.fromJson<String>(json['status']),
      occasionId: serializer.fromJson<String?>(json['occasionId']),
      defaultDirection: serializer.fromJson<String?>(json['defaultDirection']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'sourceImagePath': serializer.toJson<String>(sourceImagePath),
      'cropBounds': serializer.toJson<String?>(cropBounds),
      'rotationDegrees': serializer.toJson<int>(rotationDegrees),
      'status': serializer.toJson<String>(status),
      'occasionId': serializer.toJson<String?>(occasionId),
      'defaultDirection': serializer.toJson<String?>(defaultDirection),
      'createdAt': serializer.toJson<int>(createdAt),
      'completedAt': serializer.toJson<int?>(completedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  OcrScan copyWith({
    String? id,
    String? idempotencyKey,
    String? sourceImagePath,
    Value<String?> cropBounds = const Value.absent(),
    int? rotationDegrees,
    String? status,
    Value<String?> occasionId = const Value.absent(),
    Value<String?> defaultDirection = const Value.absent(),
    int? createdAt,
    Value<int?> completedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
  }) => OcrScan(
    id: id ?? this.id,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    sourceImagePath: sourceImagePath ?? this.sourceImagePath,
    cropBounds: cropBounds.present ? cropBounds.value : this.cropBounds,
    rotationDegrees: rotationDegrees ?? this.rotationDegrees,
    status: status ?? this.status,
    occasionId: occasionId.present ? occasionId.value : this.occasionId,
    defaultDirection: defaultDirection.present
        ? defaultDirection.value
        : this.defaultDirection,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  OcrScan copyWithCompanion(OcrScansCompanion data) {
    return OcrScan(
      id: data.id.present ? data.id.value : this.id,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      sourceImagePath: data.sourceImagePath.present
          ? data.sourceImagePath.value
          : this.sourceImagePath,
      cropBounds: data.cropBounds.present
          ? data.cropBounds.value
          : this.cropBounds,
      rotationDegrees: data.rotationDegrees.present
          ? data.rotationDegrees.value
          : this.rotationDegrees,
      status: data.status.present ? data.status.value : this.status,
      occasionId: data.occasionId.present
          ? data.occasionId.value
          : this.occasionId,
      defaultDirection: data.defaultDirection.present
          ? data.defaultDirection.value
          : this.defaultDirection,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OcrScan(')
          ..write('id: $id, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('sourceImagePath: $sourceImagePath, ')
          ..write('cropBounds: $cropBounds, ')
          ..write('rotationDegrees: $rotationDegrees, ')
          ..write('status: $status, ')
          ..write('occasionId: $occasionId, ')
          ..write('defaultDirection: $defaultDirection, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    idempotencyKey,
    sourceImagePath,
    cropBounds,
    rotationDegrees,
    status,
    occasionId,
    defaultDirection,
    createdAt,
    completedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OcrScan &&
          other.id == this.id &&
          other.idempotencyKey == this.idempotencyKey &&
          other.sourceImagePath == this.sourceImagePath &&
          other.cropBounds == this.cropBounds &&
          other.rotationDegrees == this.rotationDegrees &&
          other.status == this.status &&
          other.occasionId == this.occasionId &&
          other.defaultDirection == this.defaultDirection &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt &&
          other.deletedAt == this.deletedAt);
}

class OcrScansCompanion extends UpdateCompanion<OcrScan> {
  final Value<String> id;
  final Value<String> idempotencyKey;
  final Value<String> sourceImagePath;
  final Value<String?> cropBounds;
  final Value<int> rotationDegrees;
  final Value<String> status;
  final Value<String?> occasionId;
  final Value<String?> defaultDirection;
  final Value<int> createdAt;
  final Value<int?> completedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const OcrScansCompanion({
    this.id = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.sourceImagePath = const Value.absent(),
    this.cropBounds = const Value.absent(),
    this.rotationDegrees = const Value.absent(),
    this.status = const Value.absent(),
    this.occasionId = const Value.absent(),
    this.defaultDirection = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OcrScansCompanion.insert({
    required String id,
    required String idempotencyKey,
    required String sourceImagePath,
    this.cropBounds = const Value.absent(),
    this.rotationDegrees = const Value.absent(),
    required String status,
    this.occasionId = const Value.absent(),
    this.defaultDirection = const Value.absent(),
    required int createdAt,
    this.completedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       idempotencyKey = Value(idempotencyKey),
       sourceImagePath = Value(sourceImagePath),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<OcrScan> custom({
    Expression<String>? id,
    Expression<String>? idempotencyKey,
    Expression<String>? sourceImagePath,
    Expression<String>? cropBounds,
    Expression<int>? rotationDegrees,
    Expression<String>? status,
    Expression<String>? occasionId,
    Expression<String>? defaultDirection,
    Expression<int>? createdAt,
    Expression<int>? completedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (sourceImagePath != null) 'source_image_path': sourceImagePath,
      if (cropBounds != null) 'crop_bounds': cropBounds,
      if (rotationDegrees != null) 'rotation_degrees': rotationDegrees,
      if (status != null) 'status': status,
      if (occasionId != null) 'occasion_id': occasionId,
      if (defaultDirection != null) 'default_direction': defaultDirection,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OcrScansCompanion copyWith({
    Value<String>? id,
    Value<String>? idempotencyKey,
    Value<String>? sourceImagePath,
    Value<String?>? cropBounds,
    Value<int>? rotationDegrees,
    Value<String>? status,
    Value<String?>? occasionId,
    Value<String?>? defaultDirection,
    Value<int>? createdAt,
    Value<int?>? completedAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return OcrScansCompanion(
      id: id ?? this.id,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      sourceImagePath: sourceImagePath ?? this.sourceImagePath,
      cropBounds: cropBounds ?? this.cropBounds,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      status: status ?? this.status,
      occasionId: occasionId ?? this.occasionId,
      defaultDirection: defaultDirection ?? this.defaultDirection,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (sourceImagePath.present) {
      map['source_image_path'] = Variable<String>(sourceImagePath.value);
    }
    if (cropBounds.present) {
      map['crop_bounds'] = Variable<String>(cropBounds.value);
    }
    if (rotationDegrees.present) {
      map['rotation_degrees'] = Variable<int>(rotationDegrees.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (occasionId.present) {
      map['occasion_id'] = Variable<String>(occasionId.value);
    }
    if (defaultDirection.present) {
      map['default_direction'] = Variable<String>(defaultDirection.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OcrScansCompanion(')
          ..write('id: $id, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('sourceImagePath: $sourceImagePath, ')
          ..write('cropBounds: $cropBounds, ')
          ..write('rotationDegrees: $rotationDegrees, ')
          ..write('status: $status, ')
          ..write('occasionId: $occasionId, ')
          ..write('defaultDirection: $defaultDirection, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CandidateEntriesTable extends CandidateEntries
    with TableInfo<$CandidateEntriesTable, CandidateEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CandidateEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scanIdMeta = const VerificationMeta('scanId');
  @override
  late final GeneratedColumn<String> scanId = GeneratedColumn<String>(
    'scan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ocr_scans (id)',
    ),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pendingReview'),
  );
  static const VerificationMeta _personNameMeta = const VerificationMeta(
    'personName',
  );
  @override
  late final GeneratedColumn<String> personName = GeneratedColumn<String>(
    'person_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _personNameConfidenceKindMeta =
      const VerificationMeta('personNameConfidenceKind');
  @override
  late final GeneratedColumn<String> personNameConfidenceKind =
      GeneratedColumn<String>(
        'person_name_confidence_kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _personNameConfidenceLevelMeta =
      const VerificationMeta('personNameConfidenceLevel');
  @override
  late final GeneratedColumn<String> personNameConfidenceLevel =
      GeneratedColumn<String>(
        'person_name_confidence_level',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _matchedPersonIdMeta = const VerificationMeta(
    'matchedPersonId',
  );
  @override
  late final GeneratedColumn<String> matchedPersonId = GeneratedColumn<String>(
    'matched_person_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES people (id)',
    ),
  );
  static const VerificationMeta _amountMinorUnitsMeta = const VerificationMeta(
    'amountMinorUnits',
  );
  @override
  late final GeneratedColumn<int> amountMinorUnits = GeneratedColumn<int>(
    'amount_minor_units',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountConfidenceKindMeta =
      const VerificationMeta('amountConfidenceKind');
  @override
  late final GeneratedColumn<String> amountConfidenceKind =
      GeneratedColumn<String>(
        'amount_confidence_kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _amountConfidenceLevelMeta =
      const VerificationMeta('amountConfidenceLevel');
  @override
  late final GeneratedColumn<String> amountConfidenceLevel =
      GeneratedColumn<String>(
        'amount_confidence_level',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _directionConfidenceKindMeta =
      const VerificationMeta('directionConfidenceKind');
  @override
  late final GeneratedColumn<String> directionConfidenceKind =
      GeneratedColumn<String>(
        'direction_confidence_kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _directionConfidenceLevelMeta =
      const VerificationMeta('directionConfidenceLevel');
  @override
  late final GeneratedColumn<String> directionConfidenceLevel =
      GeneratedColumn<String>(
        'direction_confidence_level',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
    'date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateConfidenceKindMeta =
      const VerificationMeta('dateConfidenceKind');
  @override
  late final GeneratedColumn<String> dateConfidenceKind =
      GeneratedColumn<String>(
        'date_confidence_kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _dateConfidenceLevelMeta =
      const VerificationMeta('dateConfidenceLevel');
  @override
  late final GeneratedColumn<String> dateConfidenceLevel =
      GeneratedColumn<String>(
        'date_confidence_level',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawOcrTextMeta = const VerificationMeta(
    'rawOcrText',
  );
  @override
  late final GeneratedColumn<String> rawOcrText = GeneratedColumn<String>(
    'raw_ocr_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _editedAtMeta = const VerificationMeta(
    'editedAt',
  );
  @override
  late final GeneratedColumn<int> editedAt = GeneratedColumn<int>(
    'edited_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scanId,
    status,
    personName,
    personNameConfidenceKind,
    personNameConfidenceLevel,
    matchedPersonId,
    amountMinorUnits,
    amountConfidenceKind,
    amountConfidenceLevel,
    direction,
    directionConfidenceKind,
    directionConfidenceLevel,
    date,
    dateConfidenceKind,
    dateConfidenceLevel,
    notes,
    rawOcrText,
    createdAt,
    editedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'candidate_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<CandidateEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('scan_id')) {
      context.handle(
        _scanIdMeta,
        scanId.isAcceptableOrUnknown(data['scan_id']!, _scanIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scanIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('person_name')) {
      context.handle(
        _personNameMeta,
        personName.isAcceptableOrUnknown(data['person_name']!, _personNameMeta),
      );
    } else if (isInserting) {
      context.missing(_personNameMeta);
    }
    if (data.containsKey('person_name_confidence_kind')) {
      context.handle(
        _personNameConfidenceKindMeta,
        personNameConfidenceKind.isAcceptableOrUnknown(
          data['person_name_confidence_kind']!,
          _personNameConfidenceKindMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_personNameConfidenceKindMeta);
    }
    if (data.containsKey('person_name_confidence_level')) {
      context.handle(
        _personNameConfidenceLevelMeta,
        personNameConfidenceLevel.isAcceptableOrUnknown(
          data['person_name_confidence_level']!,
          _personNameConfidenceLevelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_personNameConfidenceLevelMeta);
    }
    if (data.containsKey('matched_person_id')) {
      context.handle(
        _matchedPersonIdMeta,
        matchedPersonId.isAcceptableOrUnknown(
          data['matched_person_id']!,
          _matchedPersonIdMeta,
        ),
      );
    }
    if (data.containsKey('amount_minor_units')) {
      context.handle(
        _amountMinorUnitsMeta,
        amountMinorUnits.isAcceptableOrUnknown(
          data['amount_minor_units']!,
          _amountMinorUnitsMeta,
        ),
      );
    }
    if (data.containsKey('amount_confidence_kind')) {
      context.handle(
        _amountConfidenceKindMeta,
        amountConfidenceKind.isAcceptableOrUnknown(
          data['amount_confidence_kind']!,
          _amountConfidenceKindMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountConfidenceKindMeta);
    }
    if (data.containsKey('amount_confidence_level')) {
      context.handle(
        _amountConfidenceLevelMeta,
        amountConfidenceLevel.isAcceptableOrUnknown(
          data['amount_confidence_level']!,
          _amountConfidenceLevelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountConfidenceLevelMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    }
    if (data.containsKey('direction_confidence_kind')) {
      context.handle(
        _directionConfidenceKindMeta,
        directionConfidenceKind.isAcceptableOrUnknown(
          data['direction_confidence_kind']!,
          _directionConfidenceKindMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_directionConfidenceKindMeta);
    }
    if (data.containsKey('direction_confidence_level')) {
      context.handle(
        _directionConfidenceLevelMeta,
        directionConfidenceLevel.isAcceptableOrUnknown(
          data['direction_confidence_level']!,
          _directionConfidenceLevelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_directionConfidenceLevelMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    }
    if (data.containsKey('date_confidence_kind')) {
      context.handle(
        _dateConfidenceKindMeta,
        dateConfidenceKind.isAcceptableOrUnknown(
          data['date_confidence_kind']!,
          _dateConfidenceKindMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dateConfidenceKindMeta);
    }
    if (data.containsKey('date_confidence_level')) {
      context.handle(
        _dateConfidenceLevelMeta,
        dateConfidenceLevel.isAcceptableOrUnknown(
          data['date_confidence_level']!,
          _dateConfidenceLevelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dateConfidenceLevelMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('raw_ocr_text')) {
      context.handle(
        _rawOcrTextMeta,
        rawOcrText.isAcceptableOrUnknown(
          data['raw_ocr_text']!,
          _rawOcrTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rawOcrTextMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('edited_at')) {
      context.handle(
        _editedAtMeta,
        editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CandidateEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CandidateEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scan_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      personName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_name'],
      )!,
      personNameConfidenceKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_name_confidence_kind'],
      )!,
      personNameConfidenceLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_name_confidence_level'],
      )!,
      matchedPersonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}matched_person_id'],
      ),
      amountMinorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor_units'],
      ),
      amountConfidenceKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}amount_confidence_kind'],
      )!,
      amountConfidenceLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}amount_confidence_level'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      ),
      directionConfidenceKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction_confidence_kind'],
      )!,
      directionConfidenceLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction_confidence_level'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date'],
      ),
      dateConfidenceKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_confidence_kind'],
      )!,
      dateConfidenceLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_confidence_level'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      rawOcrText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_ocr_text'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      editedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}edited_at'],
      ),
    );
  }

  @override
  $CandidateEntriesTable createAlias(String alias) {
    return $CandidateEntriesTable(attachedDatabase, alias);
  }
}

class CandidateEntry extends DataClass implements Insertable<CandidateEntry> {
  final String id;
  final String scanId;

  /// `'pendingReview'|'confirmed'|'discarded'`.
  final String status;
  final String personName;

  /// Per-field provenance, stored as a `kind`/`level` pair per field
  /// (009 data-model.md's `FieldConfidence`): `'read'|'inferred'` and
  /// `'low'|'medium'|'high'|'none'`. Kept as two columns rather than one
  /// encoded string so a future query can filter on either half.
  final String personNameConfidenceKind;
  final String personNameConfidenceLevel;
  final String? matchedPersonId;
  final int? amountMinorUnits;
  final String amountConfidenceKind;
  final String amountConfidenceLevel;
  final String? direction;
  final String directionConfidenceKind;
  final String directionConfidenceLevel;
  final int? date;
  final String dateConfidenceKind;
  final String dateConfidenceLevel;
  final String? notes;

  /// The unedited recognized line this entry was parsed from, so review can
  /// compare against the page and a past scan stays explainable.
  final String rawOcrText;
  final int createdAt;
  final int? editedAt;
  const CandidateEntry({
    required this.id,
    required this.scanId,
    required this.status,
    required this.personName,
    required this.personNameConfidenceKind,
    required this.personNameConfidenceLevel,
    this.matchedPersonId,
    this.amountMinorUnits,
    required this.amountConfidenceKind,
    required this.amountConfidenceLevel,
    this.direction,
    required this.directionConfidenceKind,
    required this.directionConfidenceLevel,
    this.date,
    required this.dateConfidenceKind,
    required this.dateConfidenceLevel,
    this.notes,
    required this.rawOcrText,
    required this.createdAt,
    this.editedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['scan_id'] = Variable<String>(scanId);
    map['status'] = Variable<String>(status);
    map['person_name'] = Variable<String>(personName);
    map['person_name_confidence_kind'] = Variable<String>(
      personNameConfidenceKind,
    );
    map['person_name_confidence_level'] = Variable<String>(
      personNameConfidenceLevel,
    );
    if (!nullToAbsent || matchedPersonId != null) {
      map['matched_person_id'] = Variable<String>(matchedPersonId);
    }
    if (!nullToAbsent || amountMinorUnits != null) {
      map['amount_minor_units'] = Variable<int>(amountMinorUnits);
    }
    map['amount_confidence_kind'] = Variable<String>(amountConfidenceKind);
    map['amount_confidence_level'] = Variable<String>(amountConfidenceLevel);
    if (!nullToAbsent || direction != null) {
      map['direction'] = Variable<String>(direction);
    }
    map['direction_confidence_kind'] = Variable<String>(
      directionConfidenceKind,
    );
    map['direction_confidence_level'] = Variable<String>(
      directionConfidenceLevel,
    );
    if (!nullToAbsent || date != null) {
      map['date'] = Variable<int>(date);
    }
    map['date_confidence_kind'] = Variable<String>(dateConfidenceKind);
    map['date_confidence_level'] = Variable<String>(dateConfidenceLevel);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['raw_ocr_text'] = Variable<String>(rawOcrText);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || editedAt != null) {
      map['edited_at'] = Variable<int>(editedAt);
    }
    return map;
  }

  CandidateEntriesCompanion toCompanion(bool nullToAbsent) {
    return CandidateEntriesCompanion(
      id: Value(id),
      scanId: Value(scanId),
      status: Value(status),
      personName: Value(personName),
      personNameConfidenceKind: Value(personNameConfidenceKind),
      personNameConfidenceLevel: Value(personNameConfidenceLevel),
      matchedPersonId: matchedPersonId == null && nullToAbsent
          ? const Value.absent()
          : Value(matchedPersonId),
      amountMinorUnits: amountMinorUnits == null && nullToAbsent
          ? const Value.absent()
          : Value(amountMinorUnits),
      amountConfidenceKind: Value(amountConfidenceKind),
      amountConfidenceLevel: Value(amountConfidenceLevel),
      direction: direction == null && nullToAbsent
          ? const Value.absent()
          : Value(direction),
      directionConfidenceKind: Value(directionConfidenceKind),
      directionConfidenceLevel: Value(directionConfidenceLevel),
      date: date == null && nullToAbsent ? const Value.absent() : Value(date),
      dateConfidenceKind: Value(dateConfidenceKind),
      dateConfidenceLevel: Value(dateConfidenceLevel),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      rawOcrText: Value(rawOcrText),
      createdAt: Value(createdAt),
      editedAt: editedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(editedAt),
    );
  }

  factory CandidateEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CandidateEntry(
      id: serializer.fromJson<String>(json['id']),
      scanId: serializer.fromJson<String>(json['scanId']),
      status: serializer.fromJson<String>(json['status']),
      personName: serializer.fromJson<String>(json['personName']),
      personNameConfidenceKind: serializer.fromJson<String>(
        json['personNameConfidenceKind'],
      ),
      personNameConfidenceLevel: serializer.fromJson<String>(
        json['personNameConfidenceLevel'],
      ),
      matchedPersonId: serializer.fromJson<String?>(json['matchedPersonId']),
      amountMinorUnits: serializer.fromJson<int?>(json['amountMinorUnits']),
      amountConfidenceKind: serializer.fromJson<String>(
        json['amountConfidenceKind'],
      ),
      amountConfidenceLevel: serializer.fromJson<String>(
        json['amountConfidenceLevel'],
      ),
      direction: serializer.fromJson<String?>(json['direction']),
      directionConfidenceKind: serializer.fromJson<String>(
        json['directionConfidenceKind'],
      ),
      directionConfidenceLevel: serializer.fromJson<String>(
        json['directionConfidenceLevel'],
      ),
      date: serializer.fromJson<int?>(json['date']),
      dateConfidenceKind: serializer.fromJson<String>(
        json['dateConfidenceKind'],
      ),
      dateConfidenceLevel: serializer.fromJson<String>(
        json['dateConfidenceLevel'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      rawOcrText: serializer.fromJson<String>(json['rawOcrText']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      editedAt: serializer.fromJson<int?>(json['editedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scanId': serializer.toJson<String>(scanId),
      'status': serializer.toJson<String>(status),
      'personName': serializer.toJson<String>(personName),
      'personNameConfidenceKind': serializer.toJson<String>(
        personNameConfidenceKind,
      ),
      'personNameConfidenceLevel': serializer.toJson<String>(
        personNameConfidenceLevel,
      ),
      'matchedPersonId': serializer.toJson<String?>(matchedPersonId),
      'amountMinorUnits': serializer.toJson<int?>(amountMinorUnits),
      'amountConfidenceKind': serializer.toJson<String>(amountConfidenceKind),
      'amountConfidenceLevel': serializer.toJson<String>(amountConfidenceLevel),
      'direction': serializer.toJson<String?>(direction),
      'directionConfidenceKind': serializer.toJson<String>(
        directionConfidenceKind,
      ),
      'directionConfidenceLevel': serializer.toJson<String>(
        directionConfidenceLevel,
      ),
      'date': serializer.toJson<int?>(date),
      'dateConfidenceKind': serializer.toJson<String>(dateConfidenceKind),
      'dateConfidenceLevel': serializer.toJson<String>(dateConfidenceLevel),
      'notes': serializer.toJson<String?>(notes),
      'rawOcrText': serializer.toJson<String>(rawOcrText),
      'createdAt': serializer.toJson<int>(createdAt),
      'editedAt': serializer.toJson<int?>(editedAt),
    };
  }

  CandidateEntry copyWith({
    String? id,
    String? scanId,
    String? status,
    String? personName,
    String? personNameConfidenceKind,
    String? personNameConfidenceLevel,
    Value<String?> matchedPersonId = const Value.absent(),
    Value<int?> amountMinorUnits = const Value.absent(),
    String? amountConfidenceKind,
    String? amountConfidenceLevel,
    Value<String?> direction = const Value.absent(),
    String? directionConfidenceKind,
    String? directionConfidenceLevel,
    Value<int?> date = const Value.absent(),
    String? dateConfidenceKind,
    String? dateConfidenceLevel,
    Value<String?> notes = const Value.absent(),
    String? rawOcrText,
    int? createdAt,
    Value<int?> editedAt = const Value.absent(),
  }) => CandidateEntry(
    id: id ?? this.id,
    scanId: scanId ?? this.scanId,
    status: status ?? this.status,
    personName: personName ?? this.personName,
    personNameConfidenceKind:
        personNameConfidenceKind ?? this.personNameConfidenceKind,
    personNameConfidenceLevel:
        personNameConfidenceLevel ?? this.personNameConfidenceLevel,
    matchedPersonId: matchedPersonId.present
        ? matchedPersonId.value
        : this.matchedPersonId,
    amountMinorUnits: amountMinorUnits.present
        ? amountMinorUnits.value
        : this.amountMinorUnits,
    amountConfidenceKind: amountConfidenceKind ?? this.amountConfidenceKind,
    amountConfidenceLevel: amountConfidenceLevel ?? this.amountConfidenceLevel,
    direction: direction.present ? direction.value : this.direction,
    directionConfidenceKind:
        directionConfidenceKind ?? this.directionConfidenceKind,
    directionConfidenceLevel:
        directionConfidenceLevel ?? this.directionConfidenceLevel,
    date: date.present ? date.value : this.date,
    dateConfidenceKind: dateConfidenceKind ?? this.dateConfidenceKind,
    dateConfidenceLevel: dateConfidenceLevel ?? this.dateConfidenceLevel,
    notes: notes.present ? notes.value : this.notes,
    rawOcrText: rawOcrText ?? this.rawOcrText,
    createdAt: createdAt ?? this.createdAt,
    editedAt: editedAt.present ? editedAt.value : this.editedAt,
  );
  CandidateEntry copyWithCompanion(CandidateEntriesCompanion data) {
    return CandidateEntry(
      id: data.id.present ? data.id.value : this.id,
      scanId: data.scanId.present ? data.scanId.value : this.scanId,
      status: data.status.present ? data.status.value : this.status,
      personName: data.personName.present
          ? data.personName.value
          : this.personName,
      personNameConfidenceKind: data.personNameConfidenceKind.present
          ? data.personNameConfidenceKind.value
          : this.personNameConfidenceKind,
      personNameConfidenceLevel: data.personNameConfidenceLevel.present
          ? data.personNameConfidenceLevel.value
          : this.personNameConfidenceLevel,
      matchedPersonId: data.matchedPersonId.present
          ? data.matchedPersonId.value
          : this.matchedPersonId,
      amountMinorUnits: data.amountMinorUnits.present
          ? data.amountMinorUnits.value
          : this.amountMinorUnits,
      amountConfidenceKind: data.amountConfidenceKind.present
          ? data.amountConfidenceKind.value
          : this.amountConfidenceKind,
      amountConfidenceLevel: data.amountConfidenceLevel.present
          ? data.amountConfidenceLevel.value
          : this.amountConfidenceLevel,
      direction: data.direction.present ? data.direction.value : this.direction,
      directionConfidenceKind: data.directionConfidenceKind.present
          ? data.directionConfidenceKind.value
          : this.directionConfidenceKind,
      directionConfidenceLevel: data.directionConfidenceLevel.present
          ? data.directionConfidenceLevel.value
          : this.directionConfidenceLevel,
      date: data.date.present ? data.date.value : this.date,
      dateConfidenceKind: data.dateConfidenceKind.present
          ? data.dateConfidenceKind.value
          : this.dateConfidenceKind,
      dateConfidenceLevel: data.dateConfidenceLevel.present
          ? data.dateConfidenceLevel.value
          : this.dateConfidenceLevel,
      notes: data.notes.present ? data.notes.value : this.notes,
      rawOcrText: data.rawOcrText.present
          ? data.rawOcrText.value
          : this.rawOcrText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CandidateEntry(')
          ..write('id: $id, ')
          ..write('scanId: $scanId, ')
          ..write('status: $status, ')
          ..write('personName: $personName, ')
          ..write('personNameConfidenceKind: $personNameConfidenceKind, ')
          ..write('personNameConfidenceLevel: $personNameConfidenceLevel, ')
          ..write('matchedPersonId: $matchedPersonId, ')
          ..write('amountMinorUnits: $amountMinorUnits, ')
          ..write('amountConfidenceKind: $amountConfidenceKind, ')
          ..write('amountConfidenceLevel: $amountConfidenceLevel, ')
          ..write('direction: $direction, ')
          ..write('directionConfidenceKind: $directionConfidenceKind, ')
          ..write('directionConfidenceLevel: $directionConfidenceLevel, ')
          ..write('date: $date, ')
          ..write('dateConfidenceKind: $dateConfidenceKind, ')
          ..write('dateConfidenceLevel: $dateConfidenceLevel, ')
          ..write('notes: $notes, ')
          ..write('rawOcrText: $rawOcrText, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scanId,
    status,
    personName,
    personNameConfidenceKind,
    personNameConfidenceLevel,
    matchedPersonId,
    amountMinorUnits,
    amountConfidenceKind,
    amountConfidenceLevel,
    direction,
    directionConfidenceKind,
    directionConfidenceLevel,
    date,
    dateConfidenceKind,
    dateConfidenceLevel,
    notes,
    rawOcrText,
    createdAt,
    editedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CandidateEntry &&
          other.id == this.id &&
          other.scanId == this.scanId &&
          other.status == this.status &&
          other.personName == this.personName &&
          other.personNameConfidenceKind == this.personNameConfidenceKind &&
          other.personNameConfidenceLevel == this.personNameConfidenceLevel &&
          other.matchedPersonId == this.matchedPersonId &&
          other.amountMinorUnits == this.amountMinorUnits &&
          other.amountConfidenceKind == this.amountConfidenceKind &&
          other.amountConfidenceLevel == this.amountConfidenceLevel &&
          other.direction == this.direction &&
          other.directionConfidenceKind == this.directionConfidenceKind &&
          other.directionConfidenceLevel == this.directionConfidenceLevel &&
          other.date == this.date &&
          other.dateConfidenceKind == this.dateConfidenceKind &&
          other.dateConfidenceLevel == this.dateConfidenceLevel &&
          other.notes == this.notes &&
          other.rawOcrText == this.rawOcrText &&
          other.createdAt == this.createdAt &&
          other.editedAt == this.editedAt);
}

class CandidateEntriesCompanion extends UpdateCompanion<CandidateEntry> {
  final Value<String> id;
  final Value<String> scanId;
  final Value<String> status;
  final Value<String> personName;
  final Value<String> personNameConfidenceKind;
  final Value<String> personNameConfidenceLevel;
  final Value<String?> matchedPersonId;
  final Value<int?> amountMinorUnits;
  final Value<String> amountConfidenceKind;
  final Value<String> amountConfidenceLevel;
  final Value<String?> direction;
  final Value<String> directionConfidenceKind;
  final Value<String> directionConfidenceLevel;
  final Value<int?> date;
  final Value<String> dateConfidenceKind;
  final Value<String> dateConfidenceLevel;
  final Value<String?> notes;
  final Value<String> rawOcrText;
  final Value<int> createdAt;
  final Value<int?> editedAt;
  final Value<int> rowid;
  const CandidateEntriesCompanion({
    this.id = const Value.absent(),
    this.scanId = const Value.absent(),
    this.status = const Value.absent(),
    this.personName = const Value.absent(),
    this.personNameConfidenceKind = const Value.absent(),
    this.personNameConfidenceLevel = const Value.absent(),
    this.matchedPersonId = const Value.absent(),
    this.amountMinorUnits = const Value.absent(),
    this.amountConfidenceKind = const Value.absent(),
    this.amountConfidenceLevel = const Value.absent(),
    this.direction = const Value.absent(),
    this.directionConfidenceKind = const Value.absent(),
    this.directionConfidenceLevel = const Value.absent(),
    this.date = const Value.absent(),
    this.dateConfidenceKind = const Value.absent(),
    this.dateConfidenceLevel = const Value.absent(),
    this.notes = const Value.absent(),
    this.rawOcrText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CandidateEntriesCompanion.insert({
    required String id,
    required String scanId,
    this.status = const Value.absent(),
    required String personName,
    required String personNameConfidenceKind,
    required String personNameConfidenceLevel,
    this.matchedPersonId = const Value.absent(),
    this.amountMinorUnits = const Value.absent(),
    required String amountConfidenceKind,
    required String amountConfidenceLevel,
    this.direction = const Value.absent(),
    required String directionConfidenceKind,
    required String directionConfidenceLevel,
    this.date = const Value.absent(),
    required String dateConfidenceKind,
    required String dateConfidenceLevel,
    this.notes = const Value.absent(),
    required String rawOcrText,
    required int createdAt,
    this.editedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       scanId = Value(scanId),
       personName = Value(personName),
       personNameConfidenceKind = Value(personNameConfidenceKind),
       personNameConfidenceLevel = Value(personNameConfidenceLevel),
       amountConfidenceKind = Value(amountConfidenceKind),
       amountConfidenceLevel = Value(amountConfidenceLevel),
       directionConfidenceKind = Value(directionConfidenceKind),
       directionConfidenceLevel = Value(directionConfidenceLevel),
       dateConfidenceKind = Value(dateConfidenceKind),
       dateConfidenceLevel = Value(dateConfidenceLevel),
       rawOcrText = Value(rawOcrText),
       createdAt = Value(createdAt);
  static Insertable<CandidateEntry> custom({
    Expression<String>? id,
    Expression<String>? scanId,
    Expression<String>? status,
    Expression<String>? personName,
    Expression<String>? personNameConfidenceKind,
    Expression<String>? personNameConfidenceLevel,
    Expression<String>? matchedPersonId,
    Expression<int>? amountMinorUnits,
    Expression<String>? amountConfidenceKind,
    Expression<String>? amountConfidenceLevel,
    Expression<String>? direction,
    Expression<String>? directionConfidenceKind,
    Expression<String>? directionConfidenceLevel,
    Expression<int>? date,
    Expression<String>? dateConfidenceKind,
    Expression<String>? dateConfidenceLevel,
    Expression<String>? notes,
    Expression<String>? rawOcrText,
    Expression<int>? createdAt,
    Expression<int>? editedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scanId != null) 'scan_id': scanId,
      if (status != null) 'status': status,
      if (personName != null) 'person_name': personName,
      if (personNameConfidenceKind != null)
        'person_name_confidence_kind': personNameConfidenceKind,
      if (personNameConfidenceLevel != null)
        'person_name_confidence_level': personNameConfidenceLevel,
      if (matchedPersonId != null) 'matched_person_id': matchedPersonId,
      if (amountMinorUnits != null) 'amount_minor_units': amountMinorUnits,
      if (amountConfidenceKind != null)
        'amount_confidence_kind': amountConfidenceKind,
      if (amountConfidenceLevel != null)
        'amount_confidence_level': amountConfidenceLevel,
      if (direction != null) 'direction': direction,
      if (directionConfidenceKind != null)
        'direction_confidence_kind': directionConfidenceKind,
      if (directionConfidenceLevel != null)
        'direction_confidence_level': directionConfidenceLevel,
      if (date != null) 'date': date,
      if (dateConfidenceKind != null)
        'date_confidence_kind': dateConfidenceKind,
      if (dateConfidenceLevel != null)
        'date_confidence_level': dateConfidenceLevel,
      if (notes != null) 'notes': notes,
      if (rawOcrText != null) 'raw_ocr_text': rawOcrText,
      if (createdAt != null) 'created_at': createdAt,
      if (editedAt != null) 'edited_at': editedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CandidateEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? scanId,
    Value<String>? status,
    Value<String>? personName,
    Value<String>? personNameConfidenceKind,
    Value<String>? personNameConfidenceLevel,
    Value<String?>? matchedPersonId,
    Value<int?>? amountMinorUnits,
    Value<String>? amountConfidenceKind,
    Value<String>? amountConfidenceLevel,
    Value<String?>? direction,
    Value<String>? directionConfidenceKind,
    Value<String>? directionConfidenceLevel,
    Value<int?>? date,
    Value<String>? dateConfidenceKind,
    Value<String>? dateConfidenceLevel,
    Value<String?>? notes,
    Value<String>? rawOcrText,
    Value<int>? createdAt,
    Value<int?>? editedAt,
    Value<int>? rowid,
  }) {
    return CandidateEntriesCompanion(
      id: id ?? this.id,
      scanId: scanId ?? this.scanId,
      status: status ?? this.status,
      personName: personName ?? this.personName,
      personNameConfidenceKind:
          personNameConfidenceKind ?? this.personNameConfidenceKind,
      personNameConfidenceLevel:
          personNameConfidenceLevel ?? this.personNameConfidenceLevel,
      matchedPersonId: matchedPersonId ?? this.matchedPersonId,
      amountMinorUnits: amountMinorUnits ?? this.amountMinorUnits,
      amountConfidenceKind: amountConfidenceKind ?? this.amountConfidenceKind,
      amountConfidenceLevel:
          amountConfidenceLevel ?? this.amountConfidenceLevel,
      direction: direction ?? this.direction,
      directionConfidenceKind:
          directionConfidenceKind ?? this.directionConfidenceKind,
      directionConfidenceLevel:
          directionConfidenceLevel ?? this.directionConfidenceLevel,
      date: date ?? this.date,
      dateConfidenceKind: dateConfidenceKind ?? this.dateConfidenceKind,
      dateConfidenceLevel: dateConfidenceLevel ?? this.dateConfidenceLevel,
      notes: notes ?? this.notes,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scanId.present) {
      map['scan_id'] = Variable<String>(scanId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (personName.present) {
      map['person_name'] = Variable<String>(personName.value);
    }
    if (personNameConfidenceKind.present) {
      map['person_name_confidence_kind'] = Variable<String>(
        personNameConfidenceKind.value,
      );
    }
    if (personNameConfidenceLevel.present) {
      map['person_name_confidence_level'] = Variable<String>(
        personNameConfidenceLevel.value,
      );
    }
    if (matchedPersonId.present) {
      map['matched_person_id'] = Variable<String>(matchedPersonId.value);
    }
    if (amountMinorUnits.present) {
      map['amount_minor_units'] = Variable<int>(amountMinorUnits.value);
    }
    if (amountConfidenceKind.present) {
      map['amount_confidence_kind'] = Variable<String>(
        amountConfidenceKind.value,
      );
    }
    if (amountConfidenceLevel.present) {
      map['amount_confidence_level'] = Variable<String>(
        amountConfidenceLevel.value,
      );
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (directionConfidenceKind.present) {
      map['direction_confidence_kind'] = Variable<String>(
        directionConfidenceKind.value,
      );
    }
    if (directionConfidenceLevel.present) {
      map['direction_confidence_level'] = Variable<String>(
        directionConfidenceLevel.value,
      );
    }
    if (date.present) {
      map['date'] = Variable<int>(date.value);
    }
    if (dateConfidenceKind.present) {
      map['date_confidence_kind'] = Variable<String>(dateConfidenceKind.value);
    }
    if (dateConfidenceLevel.present) {
      map['date_confidence_level'] = Variable<String>(
        dateConfidenceLevel.value,
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rawOcrText.present) {
      map['raw_ocr_text'] = Variable<String>(rawOcrText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<int>(editedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CandidateEntriesCompanion(')
          ..write('id: $id, ')
          ..write('scanId: $scanId, ')
          ..write('status: $status, ')
          ..write('personName: $personName, ')
          ..write('personNameConfidenceKind: $personNameConfidenceKind, ')
          ..write('personNameConfidenceLevel: $personNameConfidenceLevel, ')
          ..write('matchedPersonId: $matchedPersonId, ')
          ..write('amountMinorUnits: $amountMinorUnits, ')
          ..write('amountConfidenceKind: $amountConfidenceKind, ')
          ..write('amountConfidenceLevel: $amountConfidenceLevel, ')
          ..write('direction: $direction, ')
          ..write('directionConfidenceKind: $directionConfidenceKind, ')
          ..write('directionConfidenceLevel: $directionConfidenceLevel, ')
          ..write('date: $date, ')
          ..write('dateConfidenceKind: $dateConfidenceKind, ')
          ..write('dateConfidenceLevel: $dateConfidenceLevel, ')
          ..write('notes: $notes, ')
          ..write('rawOcrText: $rawOcrText, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets with TableInfo<$BudgetsTable, Budget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<String> month = GeneratedColumn<String>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expectedIncomeMinorUnitsMeta =
      const VerificationMeta('expectedIncomeMinorUnits');
  @override
  late final GeneratedColumn<int> expectedIncomeMinorUnits =
      GeneratedColumn<int>(
        'expected_income_minor_units',
        aliasedName,
        true,
        type: DriftSqlType.int,
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    idempotencyKey,
    month,
    expectedIncomeMinorUnits,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Budget> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('expected_income_minor_units')) {
      context.handle(
        _expectedIncomeMinorUnitsMeta,
        expectedIncomeMinorUnits.isAcceptableOrUnknown(
          data['expected_income_minor_units']!,
          _expectedIncomeMinorUnitsMeta,
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Budget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Budget(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}month'],
      )!,
      expectedIncomeMinorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expected_income_minor_units'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }
}

class Budget extends DataClass implements Insertable<Budget> {
  final String id;
  final String idempotencyKey;

  /// `'YYYY-MM'` — at most one active budget per calendar month.
  final String month;

  /// Optional reference figure (010 FR-003); never aggregated from income
  /// entries.
  final int? expectedIncomeMinorUnits;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const Budget({
    required this.id,
    required this.idempotencyKey,
    required this.month,
    this.expectedIncomeMinorUnits,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['month'] = Variable<String>(month);
    if (!nullToAbsent || expectedIncomeMinorUnits != null) {
      map['expected_income_minor_units'] = Variable<int>(
        expectedIncomeMinorUnits,
      );
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      id: Value(id),
      idempotencyKey: Value(idempotencyKey),
      month: Value(month),
      expectedIncomeMinorUnits: expectedIncomeMinorUnits == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedIncomeMinorUnits),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Budget.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Budget(
      id: serializer.fromJson<String>(json['id']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      month: serializer.fromJson<String>(json['month']),
      expectedIncomeMinorUnits: serializer.fromJson<int?>(
        json['expectedIncomeMinorUnits'],
      ),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'month': serializer.toJson<String>(month),
      'expectedIncomeMinorUnits': serializer.toJson<int?>(
        expectedIncomeMinorUnits,
      ),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  Budget copyWith({
    String? id,
    String? idempotencyKey,
    String? month,
    Value<int?> expectedIncomeMinorUnits = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
  }) => Budget(
    id: id ?? this.id,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    month: month ?? this.month,
    expectedIncomeMinorUnits: expectedIncomeMinorUnits.present
        ? expectedIncomeMinorUnits.value
        : this.expectedIncomeMinorUnits,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Budget copyWithCompanion(BudgetsCompanion data) {
    return Budget(
      id: data.id.present ? data.id.value : this.id,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      month: data.month.present ? data.month.value : this.month,
      expectedIncomeMinorUnits: data.expectedIncomeMinorUnits.present
          ? data.expectedIncomeMinorUnits.value
          : this.expectedIncomeMinorUnits,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Budget(')
          ..write('id: $id, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('month: $month, ')
          ..write('expectedIncomeMinorUnits: $expectedIncomeMinorUnits, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    idempotencyKey,
    month,
    expectedIncomeMinorUnits,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Budget &&
          other.id == this.id &&
          other.idempotencyKey == this.idempotencyKey &&
          other.month == this.month &&
          other.expectedIncomeMinorUnits == this.expectedIncomeMinorUnits &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class BudgetsCompanion extends UpdateCompanion<Budget> {
  final Value<String> id;
  final Value<String> idempotencyKey;
  final Value<String> month;
  final Value<int?> expectedIncomeMinorUnits;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const BudgetsCompanion({
    this.id = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.month = const Value.absent(),
    this.expectedIncomeMinorUnits = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetsCompanion.insert({
    required String id,
    required String idempotencyKey,
    required String month,
    this.expectedIncomeMinorUnits = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       idempotencyKey = Value(idempotencyKey),
       month = Value(month),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Budget> custom({
    Expression<String>? id,
    Expression<String>? idempotencyKey,
    Expression<String>? month,
    Expression<int>? expectedIncomeMinorUnits,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (month != null) 'month': month,
      if (expectedIncomeMinorUnits != null)
        'expected_income_minor_units': expectedIncomeMinorUnits,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetsCompanion copyWith({
    Value<String>? id,
    Value<String>? idempotencyKey,
    Value<String>? month,
    Value<int?>? expectedIncomeMinorUnits,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return BudgetsCompanion(
      id: id ?? this.id,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      month: month ?? this.month,
      expectedIncomeMinorUnits:
          expectedIncomeMinorUnits ?? this.expectedIncomeMinorUnits,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (month.present) {
      map['month'] = Variable<String>(month.value);
    }
    if (expectedIncomeMinorUnits.present) {
      map['expected_income_minor_units'] = Variable<int>(
        expectedIncomeMinorUnits.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('id: $id, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('month: $month, ')
          ..write('expectedIncomeMinorUnits: $expectedIncomeMinorUnits, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetCategoryAllocationsTable extends BudgetCategoryAllocations
    with TableInfo<$BudgetCategoryAllocationsTable, BudgetCategoryAllocation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetCategoryAllocationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _budgetIdMeta = const VerificationMeta(
    'budgetId',
  );
  @override
  late final GeneratedColumn<String> budgetId = GeneratedColumn<String>(
    'budget_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES budgets (id)',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES finance_categories (id)',
    ),
  );
  static const VerificationMeta _plannedAmountMinorUnitsMeta =
      const VerificationMeta('plannedAmountMinorUnits');
  @override
  late final GeneratedColumn<int> plannedAmountMinorUnits =
      GeneratedColumn<int>(
        'planned_amount_minor_units',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    idempotencyKey,
    budgetId,
    categoryId,
    plannedAmountMinorUnits,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budget_category_allocations';
  @override
  VerificationContext validateIntegrity(
    Insertable<BudgetCategoryAllocation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('budget_id')) {
      context.handle(
        _budgetIdMeta,
        budgetId.isAcceptableOrUnknown(data['budget_id']!, _budgetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_budgetIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('planned_amount_minor_units')) {
      context.handle(
        _plannedAmountMinorUnitsMeta,
        plannedAmountMinorUnits.isAcceptableOrUnknown(
          data['planned_amount_minor_units']!,
          _plannedAmountMinorUnitsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plannedAmountMinorUnitsMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BudgetCategoryAllocation map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetCategoryAllocation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      budgetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}budget_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      plannedAmountMinorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_amount_minor_units'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BudgetCategoryAllocationsTable createAlias(String alias) {
    return $BudgetCategoryAllocationsTable(attachedDatabase, alias);
  }
}

class BudgetCategoryAllocation extends DataClass
    implements Insertable<BudgetCategoryAllocation> {
  final String id;

  /// What lets a retried "add allocation" return the row it already wrote
  /// instead of tripping the `(budget_id, category_id)` duplicate guard —
  /// without it a retry and a genuine duplicate would be indistinguishable.
  final String idempotencyKey;
  final String budgetId;
  final String categoryId;

  /// `>= 0`; zero is a valid plan (010 FR-002).
  final int plannedAmountMinorUnits;
  final int createdAt;
  final int updatedAt;
  const BudgetCategoryAllocation({
    required this.id,
    required this.idempotencyKey,
    required this.budgetId,
    required this.categoryId,
    required this.plannedAmountMinorUnits,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['budget_id'] = Variable<String>(budgetId);
    map['category_id'] = Variable<String>(categoryId);
    map['planned_amount_minor_units'] = Variable<int>(plannedAmountMinorUnits);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  BudgetCategoryAllocationsCompanion toCompanion(bool nullToAbsent) {
    return BudgetCategoryAllocationsCompanion(
      id: Value(id),
      idempotencyKey: Value(idempotencyKey),
      budgetId: Value(budgetId),
      categoryId: Value(categoryId),
      plannedAmountMinorUnits: Value(plannedAmountMinorUnits),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BudgetCategoryAllocation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetCategoryAllocation(
      id: serializer.fromJson<String>(json['id']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      budgetId: serializer.fromJson<String>(json['budgetId']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      plannedAmountMinorUnits: serializer.fromJson<int>(
        json['plannedAmountMinorUnits'],
      ),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'budgetId': serializer.toJson<String>(budgetId),
      'categoryId': serializer.toJson<String>(categoryId),
      'plannedAmountMinorUnits': serializer.toJson<int>(
        plannedAmountMinorUnits,
      ),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  BudgetCategoryAllocation copyWith({
    String? id,
    String? idempotencyKey,
    String? budgetId,
    String? categoryId,
    int? plannedAmountMinorUnits,
    int? createdAt,
    int? updatedAt,
  }) => BudgetCategoryAllocation(
    id: id ?? this.id,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    budgetId: budgetId ?? this.budgetId,
    categoryId: categoryId ?? this.categoryId,
    plannedAmountMinorUnits:
        plannedAmountMinorUnits ?? this.plannedAmountMinorUnits,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BudgetCategoryAllocation copyWithCompanion(
    BudgetCategoryAllocationsCompanion data,
  ) {
    return BudgetCategoryAllocation(
      id: data.id.present ? data.id.value : this.id,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      budgetId: data.budgetId.present ? data.budgetId.value : this.budgetId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      plannedAmountMinorUnits: data.plannedAmountMinorUnits.present
          ? data.plannedAmountMinorUnits.value
          : this.plannedAmountMinorUnits,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetCategoryAllocation(')
          ..write('id: $id, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('budgetId: $budgetId, ')
          ..write('categoryId: $categoryId, ')
          ..write('plannedAmountMinorUnits: $plannedAmountMinorUnits, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    idempotencyKey,
    budgetId,
    categoryId,
    plannedAmountMinorUnits,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetCategoryAllocation &&
          other.id == this.id &&
          other.idempotencyKey == this.idempotencyKey &&
          other.budgetId == this.budgetId &&
          other.categoryId == this.categoryId &&
          other.plannedAmountMinorUnits == this.plannedAmountMinorUnits &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BudgetCategoryAllocationsCompanion
    extends UpdateCompanion<BudgetCategoryAllocation> {
  final Value<String> id;
  final Value<String> idempotencyKey;
  final Value<String> budgetId;
  final Value<String> categoryId;
  final Value<int> plannedAmountMinorUnits;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const BudgetCategoryAllocationsCompanion({
    this.id = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.budgetId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.plannedAmountMinorUnits = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetCategoryAllocationsCompanion.insert({
    required String id,
    required String idempotencyKey,
    required String budgetId,
    required String categoryId,
    required int plannedAmountMinorUnits,
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       idempotencyKey = Value(idempotencyKey),
       budgetId = Value(budgetId),
       categoryId = Value(categoryId),
       plannedAmountMinorUnits = Value(plannedAmountMinorUnits),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<BudgetCategoryAllocation> custom({
    Expression<String>? id,
    Expression<String>? idempotencyKey,
    Expression<String>? budgetId,
    Expression<String>? categoryId,
    Expression<int>? plannedAmountMinorUnits,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (budgetId != null) 'budget_id': budgetId,
      if (categoryId != null) 'category_id': categoryId,
      if (plannedAmountMinorUnits != null)
        'planned_amount_minor_units': plannedAmountMinorUnits,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetCategoryAllocationsCompanion copyWith({
    Value<String>? id,
    Value<String>? idempotencyKey,
    Value<String>? budgetId,
    Value<String>? categoryId,
    Value<int>? plannedAmountMinorUnits,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return BudgetCategoryAllocationsCompanion(
      id: id ?? this.id,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      budgetId: budgetId ?? this.budgetId,
      categoryId: categoryId ?? this.categoryId,
      plannedAmountMinorUnits:
          plannedAmountMinorUnits ?? this.plannedAmountMinorUnits,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (budgetId.present) {
      map['budget_id'] = Variable<String>(budgetId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (plannedAmountMinorUnits.present) {
      map['planned_amount_minor_units'] = Variable<int>(
        plannedAmountMinorUnits.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetCategoryAllocationsCompanion(')
          ..write('id: $id, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('budgetId: $budgetId, ')
          ..write('categoryId: $categoryId, ')
          ..write('plannedAmountMinorUnits: $plannedAmountMinorUnits, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PeopleTable people = $PeopleTable(this);
  late final $OccasionsTable occasions = $OccasionsTable(this);
  late final $MoneyTransactionsTable moneyTransactions =
      $MoneyTransactionsTable(this);
  late final $TransactionAuditEntriesTable transactionAuditEntries =
      $TransactionAuditEntriesTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $OnboardingStatusTable onboardingStatus = $OnboardingStatusTable(
    this,
  );
  late final $FinanceCategoriesTable financeCategories =
      $FinanceCategoriesTable(this);
  late final $FinanceEntriesTable financeEntries = $FinanceEntriesTable(this);
  late final $OccasionAttachmentsTable occasionAttachments =
      $OccasionAttachmentsTable(this);
  late final $OcrScansTable ocrScans = $OcrScansTable(this);
  late final $CandidateEntriesTable candidateEntries = $CandidateEntriesTable(
    this,
  );
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $BudgetCategoryAllocationsTable budgetCategoryAllocations =
      $BudgetCategoryAllocationsTable(this);
  late final Index idxPeopleNormalizedName = Index(
    'idx_people_normalized_name',
    'CREATE INDEX idx_people_normalized_name ON people (normalized_name)',
  );
  late final Index idxTransactionsPersonId = Index(
    'idx_transactions_person_id',
    'CREATE INDEX idx_transactions_person_id ON money_transactions (person_id, deleted_at)',
  );
  late final Index idxTransactionsOccasionId = Index(
    'idx_transactions_occasion_id',
    'CREATE INDEX idx_transactions_occasion_id ON money_transactions (occasion_id, deleted_at)',
  );
  late final Index idxTransactionsOcrScanId = Index(
    'idx_transactions_ocr_scan_id',
    'CREATE INDEX idx_transactions_ocr_scan_id ON money_transactions (ocr_scan_id, deleted_at)',
  );
  late final Index idxAuditTransactionId = Index(
    'idx_audit_transaction_id',
    'CREATE INDEX idx_audit_transaction_id ON transaction_audit_entries (transaction_id)',
  );
  late final Index idxFinanceCategoriesNormalizedName = Index(
    'idx_finance_categories_normalized_name',
    'CREATE INDEX idx_finance_categories_normalized_name ON finance_categories (normalized_name, type)',
  );
  late final Index idxFinanceEntriesCategoryId = Index(
    'idx_finance_entries_category_id',
    'CREATE INDEX idx_finance_entries_category_id ON finance_entries (category_id, deleted_at)',
  );
  late final Index idxFinanceEntriesDate = Index(
    'idx_finance_entries_date',
    'CREATE INDEX idx_finance_entries_date ON finance_entries (date, deleted_at)',
  );
  late final Index idxOccasionsIdempotencyKey = Index(
    'idx_occasions_idempotency_key',
    'CREATE UNIQUE INDEX idx_occasions_idempotency_key ON occasions (idempotency_key)',
  );
  late final Index idxOccasionsDate = Index(
    'idx_occasions_date',
    'CREATE INDEX idx_occasions_date ON occasions (date, deleted_at)',
  );
  late final Index idxOccasionsType = Index(
    'idx_occasions_type',
    'CREATE INDEX idx_occasions_type ON occasions (type)',
  );
  late final Index idxOccasionAttachmentsOccasionId = Index(
    'idx_occasion_attachments_occasion_id',
    'CREATE INDEX idx_occasion_attachments_occasion_id ON occasion_attachments (occasion_id, deleted_at)',
  );
  late final Index idxOcrScansIdempotencyKey = Index(
    'idx_ocr_scans_idempotency_key',
    'CREATE UNIQUE INDEX idx_ocr_scans_idempotency_key ON ocr_scans (idempotency_key)',
  );
  late final Index idxOcrScansStatus = Index(
    'idx_ocr_scans_status',
    'CREATE INDEX idx_ocr_scans_status ON ocr_scans (status, deleted_at)',
  );
  late final Index idxCandidateEntriesScanId = Index(
    'idx_candidate_entries_scan_id',
    'CREATE INDEX idx_candidate_entries_scan_id ON candidate_entries (scan_id)',
  );
  late final Index idxBudgetsIdempotencyKey = Index(
    'idx_budgets_idempotency_key',
    'CREATE UNIQUE INDEX idx_budgets_idempotency_key ON budgets (idempotency_key)',
  );
  late final Index idxBudgetsMonth = Index(
    'idx_budgets_month',
    'CREATE UNIQUE INDEX idx_budgets_month ON budgets (month) WHERE deleted_at IS NULL',
  );
  late final Index idxBudgetAllocationsBudgetCategory = Index(
    'idx_budget_allocations_budget_category',
    'CREATE UNIQUE INDEX idx_budget_allocations_budget_category ON budget_category_allocations (budget_id, category_id)',
  );
  late final Index idxBudgetAllocationsIdempotencyKey = Index(
    'idx_budget_allocations_idempotency_key',
    'CREATE UNIQUE INDEX idx_budget_allocations_idempotency_key ON budget_category_allocations (idempotency_key)',
  );
  late final Index idxBudgetAllocationsBudgetId = Index(
    'idx_budget_allocations_budget_id',
    'CREATE INDEX idx_budget_allocations_budget_id ON budget_category_allocations (budget_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    people,
    occasions,
    moneyTransactions,
    transactionAuditEntries,
    appSettings,
    onboardingStatus,
    financeCategories,
    financeEntries,
    occasionAttachments,
    ocrScans,
    candidateEntries,
    budgets,
    budgetCategoryAllocations,
    idxPeopleNormalizedName,
    idxTransactionsPersonId,
    idxTransactionsOccasionId,
    idxTransactionsOcrScanId,
    idxAuditTransactionId,
    idxFinanceCategoriesNormalizedName,
    idxFinanceEntriesCategoryId,
    idxFinanceEntriesDate,
    idxOccasionsIdempotencyKey,
    idxOccasionsDate,
    idxOccasionsType,
    idxOccasionAttachmentsOccasionId,
    idxOcrScansIdempotencyKey,
    idxOcrScansStatus,
    idxCandidateEntriesScanId,
    idxBudgetsIdempotencyKey,
    idxBudgetsMonth,
    idxBudgetAllocationsBudgetCategory,
    idxBudgetAllocationsIdempotencyKey,
    idxBudgetAllocationsBudgetId,
  ];
}

typedef $$PeopleTableCreateCompanionBuilder =
    PeopleCompanion Function({
      required String id,
      required String name,
      required String normalizedName,
      Value<String?> phoneNumber,
      Value<String?> avatarPath,
      Value<String?> relationshipTag,
      Value<String?> notes,
      Value<bool> isArchived,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$PeopleTableUpdateCompanionBuilder =
    PeopleCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> normalizedName,
      Value<String?> phoneNumber,
      Value<String?> avatarPath,
      Value<String?> relationshipTag,
      Value<String?> notes,
      Value<bool> isArchived,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$PeopleTableReferences
    extends BaseReferences<_$AppDatabase, $PeopleTable, PeopleData> {
  $$PeopleTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MoneyTransactionsTable, List<MoneyTransaction>>
  _moneyTransactionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.moneyTransactions,
        aliasName: 'people__id__money_transactions__person_id',
      );

  $$MoneyTransactionsTableProcessedTableManager get moneyTransactionsRefs {
    final manager = $$MoneyTransactionsTableTableManager(
      $_db,
      $_db.moneyTransactions,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _moneyTransactionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CandidateEntriesTable, List<CandidateEntry>>
  _candidateEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.candidateEntries,
    aliasName: 'people__id__candidate_entries__matched_person_id',
  );

  $$CandidateEntriesTableProcessedTableManager get candidateEntriesRefs {
    final manager =
        $$CandidateEntriesTableTableManager($_db, $_db.candidateEntries).filter(
          (f) => f.matchedPersonId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _candidateEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PeopleTableFilterComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relationshipTag => $composableBuilder(
    column: $table.relationshipTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> moneyTransactionsRefs(
    Expression<bool> Function($$MoneyTransactionsTableFilterComposer f) f,
  ) {
    final $$MoneyTransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.moneyTransactions,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MoneyTransactionsTableFilterComposer(
            $db: $db,
            $table: $db.moneyTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> candidateEntriesRefs(
    Expression<bool> Function($$CandidateEntriesTableFilterComposer f) f,
  ) {
    final $$CandidateEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.candidateEntries,
      getReferencedColumn: (t) => t.matchedPersonId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CandidateEntriesTableFilterComposer(
            $db: $db,
            $table: $db.candidateEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PeopleTableOrderingComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relationshipTag => $composableBuilder(
    column: $table.relationshipTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PeopleTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relationshipTag => $composableBuilder(
    column: $table.relationshipTag,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> moneyTransactionsRefs<T extends Object>(
    Expression<T> Function($$MoneyTransactionsTableAnnotationComposer a) f,
  ) {
    final $$MoneyTransactionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.moneyTransactions,
          getReferencedColumn: (t) => t.personId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MoneyTransactionsTableAnnotationComposer(
                $db: $db,
                $table: $db.moneyTransactions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> candidateEntriesRefs<T extends Object>(
    Expression<T> Function($$CandidateEntriesTableAnnotationComposer a) f,
  ) {
    final $$CandidateEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.candidateEntries,
      getReferencedColumn: (t) => t.matchedPersonId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CandidateEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.candidateEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PeopleTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PeopleTable,
          PeopleData,
          $$PeopleTableFilterComposer,
          $$PeopleTableOrderingComposer,
          $$PeopleTableAnnotationComposer,
          $$PeopleTableCreateCompanionBuilder,
          $$PeopleTableUpdateCompanionBuilder,
          (PeopleData, $$PeopleTableReferences),
          PeopleData,
          PrefetchHooks Function({
            bool moneyTransactionsRefs,
            bool candidateEntriesRefs,
          })
        > {
  $$PeopleTableTableManager(_$AppDatabase db, $PeopleTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeopleTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeopleTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeopleTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> normalizedName = const Value.absent(),
                Value<String?> phoneNumber = const Value.absent(),
                Value<String?> avatarPath = const Value.absent(),
                Value<String?> relationshipTag = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PeopleCompanion(
                id: id,
                name: name,
                normalizedName: normalizedName,
                phoneNumber: phoneNumber,
                avatarPath: avatarPath,
                relationshipTag: relationshipTag,
                notes: notes,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String normalizedName,
                Value<String?> phoneNumber = const Value.absent(),
                Value<String?> avatarPath = const Value.absent(),
                Value<String?> relationshipTag = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PeopleCompanion.insert(
                id: id,
                name: name,
                normalizedName: normalizedName,
                phoneNumber: phoneNumber,
                avatarPath: avatarPath,
                relationshipTag: relationshipTag,
                notes: notes,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PeopleTable, PeopleData>(table),
                  $$PeopleTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({moneyTransactionsRefs = false, candidateEntriesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (moneyTransactionsRefs) db.moneyTransactions,
                    if (candidateEntriesRefs) db.candidateEntries,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (moneyTransactionsRefs)
                        await $_getPrefetchedData<
                          PeopleData,
                          $PeopleTable,
                          MoneyTransaction
                        >(
                          currentTable: table,
                          referencedTable: $$PeopleTableReferences
                              ._moneyTransactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PeopleTableReferences(
                                db,
                                table,
                                p0,
                              ).moneyTransactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (candidateEntriesRefs)
                        await $_getPrefetchedData<
                          PeopleData,
                          $PeopleTable,
                          CandidateEntry
                        >(
                          currentTable: table,
                          referencedTable: $$PeopleTableReferences
                              ._candidateEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PeopleTableReferences(
                                db,
                                table,
                                p0,
                              ).candidateEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.matchedPersonId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PeopleTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PeopleTable,
      PeopleData,
      $$PeopleTableFilterComposer,
      $$PeopleTableOrderingComposer,
      $$PeopleTableAnnotationComposer,
      $$PeopleTableCreateCompanionBuilder,
      $$PeopleTableUpdateCompanionBuilder,
      (PeopleData, $$PeopleTableReferences),
      PeopleData,
      PrefetchHooks Function({
        bool moneyTransactionsRefs,
        bool candidateEntriesRefs,
      })
    >;
typedef $$OccasionsTableCreateCompanionBuilder =
    OccasionsCompanion Function({
      required String id,
      required String idempotencyKey,
      required String name,
      required int date,
      required String type,
      Value<String?> notes,
      Value<bool> isArchived,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });
typedef $$OccasionsTableUpdateCompanionBuilder =
    OccasionsCompanion Function({
      Value<String> id,
      Value<String> idempotencyKey,
      Value<String> name,
      Value<int> date,
      Value<String> type,
      Value<String?> notes,
      Value<bool> isArchived,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });

final class $$OccasionsTableReferences
    extends BaseReferences<_$AppDatabase, $OccasionsTable, Occasion> {
  $$OccasionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MoneyTransactionsTable, List<MoneyTransaction>>
  _moneyTransactionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.moneyTransactions,
        aliasName: 'occasions__id__money_transactions__occasion_id',
      );

  $$MoneyTransactionsTableProcessedTableManager get moneyTransactionsRefs {
    final manager = $$MoneyTransactionsTableTableManager(
      $_db,
      $_db.moneyTransactions,
    ).filter((f) => f.occasionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _moneyTransactionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $OccasionAttachmentsTable,
    List<OccasionAttachment>
  >
  _occasionAttachmentsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.occasionAttachments,
        aliasName: 'occasions__id__occasion_attachments__occasion_id',
      );

  $$OccasionAttachmentsTableProcessedTableManager get occasionAttachmentsRefs {
    final manager = $$OccasionAttachmentsTableTableManager(
      $_db,
      $_db.occasionAttachments,
    ).filter((f) => f.occasionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _occasionAttachmentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$OcrScansTable, List<OcrScan>> _ocrScansRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.ocrScans,
    aliasName: 'occasions__id__ocr_scans__occasion_id',
  );

  $$OcrScansTableProcessedTableManager get ocrScansRefs {
    final manager = $$OcrScansTableTableManager(
      $_db,
      $_db.ocrScans,
    ).filter((f) => f.occasionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ocrScansRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$OccasionsTableFilterComposer
    extends Composer<_$AppDatabase, $OccasionsTable> {
  $$OccasionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> moneyTransactionsRefs(
    Expression<bool> Function($$MoneyTransactionsTableFilterComposer f) f,
  ) {
    final $$MoneyTransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.moneyTransactions,
      getReferencedColumn: (t) => t.occasionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MoneyTransactionsTableFilterComposer(
            $db: $db,
            $table: $db.moneyTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> occasionAttachmentsRefs(
    Expression<bool> Function($$OccasionAttachmentsTableFilterComposer f) f,
  ) {
    final $$OccasionAttachmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.occasionAttachments,
      getReferencedColumn: (t) => t.occasionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OccasionAttachmentsTableFilterComposer(
            $db: $db,
            $table: $db.occasionAttachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ocrScansRefs(
    Expression<bool> Function($$OcrScansTableFilterComposer f) f,
  ) {
    final $$OcrScansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ocrScans,
      getReferencedColumn: (t) => t.occasionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OcrScansTableFilterComposer(
            $db: $db,
            $table: $db.ocrScans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$OccasionsTableOrderingComposer
    extends Composer<_$AppDatabase, $OccasionsTable> {
  $$OccasionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OccasionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OccasionsTable> {
  $$OccasionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> moneyTransactionsRefs<T extends Object>(
    Expression<T> Function($$MoneyTransactionsTableAnnotationComposer a) f,
  ) {
    final $$MoneyTransactionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.moneyTransactions,
          getReferencedColumn: (t) => t.occasionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MoneyTransactionsTableAnnotationComposer(
                $db: $db,
                $table: $db.moneyTransactions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> occasionAttachmentsRefs<T extends Object>(
    Expression<T> Function($$OccasionAttachmentsTableAnnotationComposer a) f,
  ) {
    final $$OccasionAttachmentsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.occasionAttachments,
          getReferencedColumn: (t) => t.occasionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$OccasionAttachmentsTableAnnotationComposer(
                $db: $db,
                $table: $db.occasionAttachments,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> ocrScansRefs<T extends Object>(
    Expression<T> Function($$OcrScansTableAnnotationComposer a) f,
  ) {
    final $$OcrScansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ocrScans,
      getReferencedColumn: (t) => t.occasionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OcrScansTableAnnotationComposer(
            $db: $db,
            $table: $db.ocrScans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$OccasionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OccasionsTable,
          Occasion,
          $$OccasionsTableFilterComposer,
          $$OccasionsTableOrderingComposer,
          $$OccasionsTableAnnotationComposer,
          $$OccasionsTableCreateCompanionBuilder,
          $$OccasionsTableUpdateCompanionBuilder,
          (Occasion, $$OccasionsTableReferences),
          Occasion,
          PrefetchHooks Function({
            bool moneyTransactionsRefs,
            bool occasionAttachmentsRefs,
            bool ocrScansRefs,
          })
        > {
  $$OccasionsTableTableManager(_$AppDatabase db, $OccasionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OccasionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OccasionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OccasionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> date = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OccasionsCompanion(
                id: id,
                idempotencyKey: idempotencyKey,
                name: name,
                date: date,
                type: type,
                notes: notes,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String idempotencyKey,
                required String name,
                required int date,
                required String type,
                Value<String?> notes = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OccasionsCompanion.insert(
                id: id,
                idempotencyKey: idempotencyKey,
                name: name,
                date: date,
                type: type,
                notes: notes,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OccasionsTable, Occasion>(table),
                  $$OccasionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                moneyTransactionsRefs = false,
                occasionAttachmentsRefs = false,
                ocrScansRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (moneyTransactionsRefs) db.moneyTransactions,
                    if (occasionAttachmentsRefs) db.occasionAttachments,
                    if (ocrScansRefs) db.ocrScans,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (moneyTransactionsRefs)
                        await $_getPrefetchedData<
                          Occasion,
                          $OccasionsTable,
                          MoneyTransaction
                        >(
                          currentTable: table,
                          referencedTable: $$OccasionsTableReferences
                              ._moneyTransactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$OccasionsTableReferences(
                                db,
                                table,
                                p0,
                              ).moneyTransactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.occasionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (occasionAttachmentsRefs)
                        await $_getPrefetchedData<
                          Occasion,
                          $OccasionsTable,
                          OccasionAttachment
                        >(
                          currentTable: table,
                          referencedTable: $$OccasionsTableReferences
                              ._occasionAttachmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$OccasionsTableReferences(
                                db,
                                table,
                                p0,
                              ).occasionAttachmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.occasionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (ocrScansRefs)
                        await $_getPrefetchedData<
                          Occasion,
                          $OccasionsTable,
                          OcrScan
                        >(
                          currentTable: table,
                          referencedTable: $$OccasionsTableReferences
                              ._ocrScansRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$OccasionsTableReferences(
                                db,
                                table,
                                p0,
                              ).ocrScansRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.occasionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$OccasionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OccasionsTable,
      Occasion,
      $$OccasionsTableFilterComposer,
      $$OccasionsTableOrderingComposer,
      $$OccasionsTableAnnotationComposer,
      $$OccasionsTableCreateCompanionBuilder,
      $$OccasionsTableUpdateCompanionBuilder,
      (Occasion, $$OccasionsTableReferences),
      Occasion,
      PrefetchHooks Function({
        bool moneyTransactionsRefs,
        bool occasionAttachmentsRefs,
        bool ocrScansRefs,
      })
    >;
typedef $$MoneyTransactionsTableCreateCompanionBuilder =
    MoneyTransactionsCompanion Function({
      required String id,
      required String idempotencyKey,
      required String personId,
      required int amountMinorUnits,
      required String direction,
      required String kind,
      required int date,
      Value<String?> note,
      Value<String?> occasionId,
      Value<bool> countsTowardBalance,
      Value<String> source,
      Value<String?> ocrScanId,
      required int createdAt,
      Value<int?> editedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });
typedef $$MoneyTransactionsTableUpdateCompanionBuilder =
    MoneyTransactionsCompanion Function({
      Value<String> id,
      Value<String> idempotencyKey,
      Value<String> personId,
      Value<int> amountMinorUnits,
      Value<String> direction,
      Value<String> kind,
      Value<int> date,
      Value<String?> note,
      Value<String?> occasionId,
      Value<bool> countsTowardBalance,
      Value<String> source,
      Value<String?> ocrScanId,
      Value<int> createdAt,
      Value<int?> editedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });

final class $$MoneyTransactionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $MoneyTransactionsTable,
          MoneyTransaction
        > {
  $$MoneyTransactionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PeopleTable _personIdTable(_$AppDatabase db) =>
      db.people.createAlias('money_transactions__person_id__people__id');

  $$PeopleTableProcessedTableManager get personId {
    final $_column = $_itemColumn<String>('person_id')!;

    final manager = $$PeopleTableTableManager(
      $_db,
      $_db.people,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $OccasionsTable _occasionIdTable(_$AppDatabase db) => db.occasions
      .createAlias('money_transactions__occasion_id__occasions__id');

  $$OccasionsTableProcessedTableManager? get occasionId {
    final $_column = $_itemColumn<String>('occasion_id');
    if ($_column == null) return null;
    final manager = $$OccasionsTableTableManager(
      $_db,
      $_db.occasions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_occasionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $TransactionAuditEntriesTable,
    List<TransactionAuditEntry>
  >
  _transactionAuditEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.transactionAuditEntries,
        aliasName:
            'money_transactions__id__transaction_audit_entries__transaction_id',
      );

  $$TransactionAuditEntriesTableProcessedTableManager
  get transactionAuditEntriesRefs {
    final manager = $$TransactionAuditEntriesTableTableManager(
      $_db,
      $_db.transactionAuditEntries,
    ).filter((f) => f.transactionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _transactionAuditEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MoneyTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $MoneyTransactionsTable> {
  $$MoneyTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get countsTowardBalance => $composableBuilder(
    column: $table.countsTowardBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ocrScanId => $composableBuilder(
    column: $table.ocrScanId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PeopleTableFilterComposer get personId {
    final $$PeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableFilterComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$OccasionsTableFilterComposer get occasionId {
    final $$OccasionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occasionId,
      referencedTable: $db.occasions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OccasionsTableFilterComposer(
            $db: $db,
            $table: $db.occasions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> transactionAuditEntriesRefs(
    Expression<bool> Function($$TransactionAuditEntriesTableFilterComposer f) f,
  ) {
    final $$TransactionAuditEntriesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.transactionAuditEntries,
          getReferencedColumn: (t) => t.transactionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionAuditEntriesTableFilterComposer(
                $db: $db,
                $table: $db.transactionAuditEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$MoneyTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $MoneyTransactionsTable> {
  $$MoneyTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get countsTowardBalance => $composableBuilder(
    column: $table.countsTowardBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ocrScanId => $composableBuilder(
    column: $table.ocrScanId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PeopleTableOrderingComposer get personId {
    final $$PeopleTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableOrderingComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$OccasionsTableOrderingComposer get occasionId {
    final $$OccasionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occasionId,
      referencedTable: $db.occasions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OccasionsTableOrderingComposer(
            $db: $db,
            $table: $db.occasions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MoneyTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MoneyTransactionsTable> {
  $$MoneyTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get countsTowardBalance => $composableBuilder(
    column: $table.countsTowardBalance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get ocrScanId =>
      $composableBuilder(column: $table.ocrScanId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get editedAt =>
      $composableBuilder(column: $table.editedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$PeopleTableAnnotationComposer get personId {
    final $$PeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$OccasionsTableAnnotationComposer get occasionId {
    final $$OccasionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occasionId,
      referencedTable: $db.occasions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OccasionsTableAnnotationComposer(
            $db: $db,
            $table: $db.occasions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> transactionAuditEntriesRefs<T extends Object>(
    Expression<T> Function($$TransactionAuditEntriesTableAnnotationComposer a)
    f,
  ) {
    final $$TransactionAuditEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.transactionAuditEntries,
          getReferencedColumn: (t) => t.transactionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionAuditEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.transactionAuditEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$MoneyTransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MoneyTransactionsTable,
          MoneyTransaction,
          $$MoneyTransactionsTableFilterComposer,
          $$MoneyTransactionsTableOrderingComposer,
          $$MoneyTransactionsTableAnnotationComposer,
          $$MoneyTransactionsTableCreateCompanionBuilder,
          $$MoneyTransactionsTableUpdateCompanionBuilder,
          (MoneyTransaction, $$MoneyTransactionsTableReferences),
          MoneyTransaction,
          PrefetchHooks Function({
            bool personId,
            bool occasionId,
            bool transactionAuditEntriesRefs,
          })
        > {
  $$MoneyTransactionsTableTableManager(
    _$AppDatabase db,
    $MoneyTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MoneyTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MoneyTransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MoneyTransactionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String> personId = const Value.absent(),
                Value<int> amountMinorUnits = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> date = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> occasionId = const Value.absent(),
                Value<bool> countsTowardBalance = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> ocrScanId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> editedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MoneyTransactionsCompanion(
                id: id,
                idempotencyKey: idempotencyKey,
                personId: personId,
                amountMinorUnits: amountMinorUnits,
                direction: direction,
                kind: kind,
                date: date,
                note: note,
                occasionId: occasionId,
                countsTowardBalance: countsTowardBalance,
                source: source,
                ocrScanId: ocrScanId,
                createdAt: createdAt,
                editedAt: editedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String idempotencyKey,
                required String personId,
                required int amountMinorUnits,
                required String direction,
                required String kind,
                required int date,
                Value<String?> note = const Value.absent(),
                Value<String?> occasionId = const Value.absent(),
                Value<bool> countsTowardBalance = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> ocrScanId = const Value.absent(),
                required int createdAt,
                Value<int?> editedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MoneyTransactionsCompanion.insert(
                id: id,
                idempotencyKey: idempotencyKey,
                personId: personId,
                amountMinorUnits: amountMinorUnits,
                direction: direction,
                kind: kind,
                date: date,
                note: note,
                occasionId: occasionId,
                countsTowardBalance: countsTowardBalance,
                source: source,
                ocrScanId: ocrScanId,
                createdAt: createdAt,
                editedAt: editedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MoneyTransactionsTable, MoneyTransaction>(table),
                  $$MoneyTransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                personId = false,
                occasionId = false,
                transactionAuditEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (transactionAuditEntriesRefs) db.transactionAuditEntries,
                  ],
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
                        if (personId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.personId,
                                    referencedTable:
                                        $$MoneyTransactionsTableReferences
                                            ._personIdTable(db),
                                    referencedColumn:
                                        $$MoneyTransactionsTableReferences
                                            ._personIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (occasionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.occasionId,
                                    referencedTable:
                                        $$MoneyTransactionsTableReferences
                                            ._occasionIdTable(db),
                                    referencedColumn:
                                        $$MoneyTransactionsTableReferences
                                            ._occasionIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (transactionAuditEntriesRefs)
                        await $_getPrefetchedData<
                          MoneyTransaction,
                          $MoneyTransactionsTable,
                          TransactionAuditEntry
                        >(
                          currentTable: table,
                          referencedTable: $$MoneyTransactionsTableReferences
                              ._transactionAuditEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MoneyTransactionsTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionAuditEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.transactionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MoneyTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MoneyTransactionsTable,
      MoneyTransaction,
      $$MoneyTransactionsTableFilterComposer,
      $$MoneyTransactionsTableOrderingComposer,
      $$MoneyTransactionsTableAnnotationComposer,
      $$MoneyTransactionsTableCreateCompanionBuilder,
      $$MoneyTransactionsTableUpdateCompanionBuilder,
      (MoneyTransaction, $$MoneyTransactionsTableReferences),
      MoneyTransaction,
      PrefetchHooks Function({
        bool personId,
        bool occasionId,
        bool transactionAuditEntriesRefs,
      })
    >;
typedef $$TransactionAuditEntriesTableCreateCompanionBuilder =
    TransactionAuditEntriesCompanion Function({
      required String id,
      required String transactionId,
      required String changeType,
      Value<String?> previousValuesJson,
      required int changedAt,
      Value<int> rowid,
    });
typedef $$TransactionAuditEntriesTableUpdateCompanionBuilder =
    TransactionAuditEntriesCompanion Function({
      Value<String> id,
      Value<String> transactionId,
      Value<String> changeType,
      Value<String?> previousValuesJson,
      Value<int> changedAt,
      Value<int> rowid,
    });

final class $$TransactionAuditEntriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TransactionAuditEntriesTable,
          TransactionAuditEntry
        > {
  $$TransactionAuditEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MoneyTransactionsTable _transactionIdTable(_$AppDatabase db) =>
      db.moneyTransactions.createAlias(
        'transaction_audit_entries__transaction_id__money_transactions__id',
      );

  $$MoneyTransactionsTableProcessedTableManager get transactionId {
    final $_column = $_itemColumn<String>('transaction_id')!;

    final manager = $$MoneyTransactionsTableTableManager(
      $_db,
      $_db.moneyTransactions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transactionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransactionAuditEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionAuditEntriesTable> {
  $$TransactionAuditEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get changeType => $composableBuilder(
    column: $table.changeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get previousValuesJson => $composableBuilder(
    column: $table.previousValuesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MoneyTransactionsTableFilterComposer get transactionId {
    final $$MoneyTransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.moneyTransactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MoneyTransactionsTableFilterComposer(
            $db: $db,
            $table: $db.moneyTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionAuditEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionAuditEntriesTable> {
  $$TransactionAuditEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get changeType => $composableBuilder(
    column: $table.changeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get previousValuesJson => $composableBuilder(
    column: $table.previousValuesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MoneyTransactionsTableOrderingComposer get transactionId {
    final $$MoneyTransactionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.moneyTransactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MoneyTransactionsTableOrderingComposer(
            $db: $db,
            $table: $db.moneyTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionAuditEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionAuditEntriesTable> {
  $$TransactionAuditEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get changeType => $composableBuilder(
    column: $table.changeType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get previousValuesJson => $composableBuilder(
    column: $table.previousValuesJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get changedAt =>
      $composableBuilder(column: $table.changedAt, builder: (column) => column);

  $$MoneyTransactionsTableAnnotationComposer get transactionId {
    final $$MoneyTransactionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.transactionId,
          referencedTable: $db.moneyTransactions,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MoneyTransactionsTableAnnotationComposer(
                $db: $db,
                $table: $db.moneyTransactions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$TransactionAuditEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionAuditEntriesTable,
          TransactionAuditEntry,
          $$TransactionAuditEntriesTableFilterComposer,
          $$TransactionAuditEntriesTableOrderingComposer,
          $$TransactionAuditEntriesTableAnnotationComposer,
          $$TransactionAuditEntriesTableCreateCompanionBuilder,
          $$TransactionAuditEntriesTableUpdateCompanionBuilder,
          (TransactionAuditEntry, $$TransactionAuditEntriesTableReferences),
          TransactionAuditEntry,
          PrefetchHooks Function({bool transactionId})
        > {
  $$TransactionAuditEntriesTableTableManager(
    _$AppDatabase db,
    $TransactionAuditEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionAuditEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$TransactionAuditEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TransactionAuditEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> transactionId = const Value.absent(),
                Value<String> changeType = const Value.absent(),
                Value<String?> previousValuesJson = const Value.absent(),
                Value<int> changedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionAuditEntriesCompanion(
                id: id,
                transactionId: transactionId,
                changeType: changeType,
                previousValuesJson: previousValuesJson,
                changedAt: changedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String transactionId,
                required String changeType,
                Value<String?> previousValuesJson = const Value.absent(),
                required int changedAt,
                Value<int> rowid = const Value.absent(),
              }) => TransactionAuditEntriesCompanion.insert(
                id: id,
                transactionId: transactionId,
                changeType: changeType,
                previousValuesJson: previousValuesJson,
                changedAt: changedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $TransactionAuditEntriesTable,
                    TransactionAuditEntry
                  >(table),
                  $$TransactionAuditEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({transactionId = false}) {
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
                    if (transactionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.transactionId,
                                referencedTable:
                                    $$TransactionAuditEntriesTableReferences
                                        ._transactionIdTable(db),
                                referencedColumn:
                                    $$TransactionAuditEntriesTableReferences
                                        ._transactionIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$TransactionAuditEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionAuditEntriesTable,
      TransactionAuditEntry,
      $$TransactionAuditEntriesTableFilterComposer,
      $$TransactionAuditEntriesTableOrderingComposer,
      $$TransactionAuditEntriesTableAnnotationComposer,
      $$TransactionAuditEntriesTableCreateCompanionBuilder,
      $$TransactionAuditEntriesTableUpdateCompanionBuilder,
      (TransactionAuditEntry, $$TransactionAuditEntriesTableReferences),
      TransactionAuditEntry,
      PrefetchHooks Function({bool transactionId})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String id,
      required String languageCode,
      Value<String?> themeMode,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> id,
      Value<String> languageCode,
      Value<String?> themeMode,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> languageCode = const Value.absent(),
                Value<String?> themeMode = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                languageCode: languageCode,
                themeMode: themeMode,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String languageCode,
                Value<String?> themeMode = const Value.absent(),
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                languageCode: languageCode,
                themeMode: themeMode,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSetting>(table),
                  BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>(
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

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$OnboardingStatusTableCreateCompanionBuilder =
    OnboardingStatusCompanion Function({
      required String id,
      Value<bool> isComplete,
      Value<int?> completedAt,
      Value<int> rowid,
    });
typedef $$OnboardingStatusTableUpdateCompanionBuilder =
    OnboardingStatusCompanion Function({
      Value<String> id,
      Value<bool> isComplete,
      Value<int?> completedAt,
      Value<int> rowid,
    });

class $$OnboardingStatusTableFilterComposer
    extends Composer<_$AppDatabase, $OnboardingStatusTable> {
  $$OnboardingStatusTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isComplete => $composableBuilder(
    column: $table.isComplete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OnboardingStatusTableOrderingComposer
    extends Composer<_$AppDatabase, $OnboardingStatusTable> {
  $$OnboardingStatusTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isComplete => $composableBuilder(
    column: $table.isComplete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OnboardingStatusTableAnnotationComposer
    extends Composer<_$AppDatabase, $OnboardingStatusTable> {
  $$OnboardingStatusTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isComplete => $composableBuilder(
    column: $table.isComplete,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$OnboardingStatusTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OnboardingStatusTable,
          OnboardingStatusData,
          $$OnboardingStatusTableFilterComposer,
          $$OnboardingStatusTableOrderingComposer,
          $$OnboardingStatusTableAnnotationComposer,
          $$OnboardingStatusTableCreateCompanionBuilder,
          $$OnboardingStatusTableUpdateCompanionBuilder,
          (
            OnboardingStatusData,
            BaseReferences<
              _$AppDatabase,
              $OnboardingStatusTable,
              OnboardingStatusData
            >,
          ),
          OnboardingStatusData,
          PrefetchHooks Function()
        > {
  $$OnboardingStatusTableTableManager(
    _$AppDatabase db,
    $OnboardingStatusTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OnboardingStatusTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OnboardingStatusTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OnboardingStatusTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<bool> isComplete = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OnboardingStatusCompanion(
                id: id,
                isComplete: isComplete,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<bool> isComplete = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OnboardingStatusCompanion.insert(
                id: id,
                isComplete: isComplete,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OnboardingStatusTable, OnboardingStatusData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $OnboardingStatusTable,
                    OnboardingStatusData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OnboardingStatusTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OnboardingStatusTable,
      OnboardingStatusData,
      $$OnboardingStatusTableFilterComposer,
      $$OnboardingStatusTableOrderingComposer,
      $$OnboardingStatusTableAnnotationComposer,
      $$OnboardingStatusTableCreateCompanionBuilder,
      $$OnboardingStatusTableUpdateCompanionBuilder,
      (
        OnboardingStatusData,
        BaseReferences<
          _$AppDatabase,
          $OnboardingStatusTable,
          OnboardingStatusData
        >,
      ),
      OnboardingStatusData,
      PrefetchHooks Function()
    >;
typedef $$FinanceCategoriesTableCreateCompanionBuilder =
    FinanceCategoriesCompanion Function({
      required String id,
      required String name,
      required String normalizedName,
      required String type,
      required String icon,
      Value<bool> isDefault,
      Value<bool> isArchived,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$FinanceCategoriesTableUpdateCompanionBuilder =
    FinanceCategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> normalizedName,
      Value<String> type,
      Value<String> icon,
      Value<bool> isDefault,
      Value<bool> isArchived,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$FinanceCategoriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $FinanceCategoriesTable,
          FinanceCategory
        > {
  $$FinanceCategoriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$FinanceEntriesTable, List<FinanceEntry>>
  _financeEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.financeEntries,
    aliasName: 'finance_categories__id__finance_entries__category_id',
  );

  $$FinanceEntriesTableProcessedTableManager get financeEntriesRefs {
    final manager = $$FinanceEntriesTableTableManager(
      $_db,
      $_db.financeEntries,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_financeEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $BudgetCategoryAllocationsTable,
    List<BudgetCategoryAllocation>
  >
  _budgetCategoryAllocationsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.budgetCategoryAllocations,
        aliasName:
            'finance_categories__id__budget_category_allocations__category_id',
      );

  $$BudgetCategoryAllocationsTableProcessedTableManager
  get budgetCategoryAllocationsRefs {
    final manager = $$BudgetCategoryAllocationsTableTableManager(
      $_db,
      $_db.budgetCategoryAllocations,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _budgetCategoryAllocationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FinanceCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $FinanceCategoriesTable> {
  $$FinanceCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> financeEntriesRefs(
    Expression<bool> Function($$FinanceEntriesTableFilterComposer f) f,
  ) {
    final $$FinanceEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.financeEntries,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinanceEntriesTableFilterComposer(
            $db: $db,
            $table: $db.financeEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> budgetCategoryAllocationsRefs(
    Expression<bool> Function($$BudgetCategoryAllocationsTableFilterComposer f)
    f,
  ) {
    final $$BudgetCategoryAllocationsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.budgetCategoryAllocations,
          getReferencedColumn: (t) => t.categoryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BudgetCategoryAllocationsTableFilterComposer(
                $db: $db,
                $table: $db.budgetCategoryAllocations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$FinanceCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $FinanceCategoriesTable> {
  $$FinanceCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FinanceCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FinanceCategoriesTable> {
  $$FinanceCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> financeEntriesRefs<T extends Object>(
    Expression<T> Function($$FinanceEntriesTableAnnotationComposer a) f,
  ) {
    final $$FinanceEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.financeEntries,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinanceEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.financeEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> budgetCategoryAllocationsRefs<T extends Object>(
    Expression<T> Function($$BudgetCategoryAllocationsTableAnnotationComposer a)
    f,
  ) {
    final $$BudgetCategoryAllocationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.budgetCategoryAllocations,
          getReferencedColumn: (t) => t.categoryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BudgetCategoryAllocationsTableAnnotationComposer(
                $db: $db,
                $table: $db.budgetCategoryAllocations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$FinanceCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FinanceCategoriesTable,
          FinanceCategory,
          $$FinanceCategoriesTableFilterComposer,
          $$FinanceCategoriesTableOrderingComposer,
          $$FinanceCategoriesTableAnnotationComposer,
          $$FinanceCategoriesTableCreateCompanionBuilder,
          $$FinanceCategoriesTableUpdateCompanionBuilder,
          (FinanceCategory, $$FinanceCategoriesTableReferences),
          FinanceCategory,
          PrefetchHooks Function({
            bool financeEntriesRefs,
            bool budgetCategoryAllocationsRefs,
          })
        > {
  $$FinanceCategoriesTableTableManager(
    _$AppDatabase db,
    $FinanceCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FinanceCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FinanceCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FinanceCategoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> normalizedName = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FinanceCategoriesCompanion(
                id: id,
                name: name,
                normalizedName: normalizedName,
                type: type,
                icon: icon,
                isDefault: isDefault,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String normalizedName,
                required String type,
                required String icon,
                Value<bool> isDefault = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => FinanceCategoriesCompanion.insert(
                id: id,
                name: name,
                normalizedName: normalizedName,
                type: type,
                icon: icon,
                isDefault: isDefault,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FinanceCategoriesTable, FinanceCategory>(table),
                  $$FinanceCategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                financeEntriesRefs = false,
                budgetCategoryAllocationsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (financeEntriesRefs) db.financeEntries,
                    if (budgetCategoryAllocationsRefs)
                      db.budgetCategoryAllocations,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (financeEntriesRefs)
                        await $_getPrefetchedData<
                          FinanceCategory,
                          $FinanceCategoriesTable,
                          FinanceEntry
                        >(
                          currentTable: table,
                          referencedTable: $$FinanceCategoriesTableReferences
                              ._financeEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FinanceCategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).financeEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (budgetCategoryAllocationsRefs)
                        await $_getPrefetchedData<
                          FinanceCategory,
                          $FinanceCategoriesTable,
                          BudgetCategoryAllocation
                        >(
                          currentTable: table,
                          referencedTable: $$FinanceCategoriesTableReferences
                              ._budgetCategoryAllocationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FinanceCategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).budgetCategoryAllocationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$FinanceCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FinanceCategoriesTable,
      FinanceCategory,
      $$FinanceCategoriesTableFilterComposer,
      $$FinanceCategoriesTableOrderingComposer,
      $$FinanceCategoriesTableAnnotationComposer,
      $$FinanceCategoriesTableCreateCompanionBuilder,
      $$FinanceCategoriesTableUpdateCompanionBuilder,
      (FinanceCategory, $$FinanceCategoriesTableReferences),
      FinanceCategory,
      PrefetchHooks Function({
        bool financeEntriesRefs,
        bool budgetCategoryAllocationsRefs,
      })
    >;
typedef $$FinanceEntriesTableCreateCompanionBuilder =
    FinanceEntriesCompanion Function({
      required String id,
      required String idempotencyKey,
      required String categoryId,
      required String type,
      required int amountMinorUnits,
      required int date,
      Value<String?> note,
      required int createdAt,
      Value<int?> editedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });
typedef $$FinanceEntriesTableUpdateCompanionBuilder =
    FinanceEntriesCompanion Function({
      Value<String> id,
      Value<String> idempotencyKey,
      Value<String> categoryId,
      Value<String> type,
      Value<int> amountMinorUnits,
      Value<int> date,
      Value<String?> note,
      Value<int> createdAt,
      Value<int?> editedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });

final class $$FinanceEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $FinanceEntriesTable, FinanceEntry> {
  $$FinanceEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FinanceCategoriesTable _categoryIdTable(_$AppDatabase db) => db
      .financeCategories
      .createAlias('finance_entries__category_id__finance_categories__id');

  $$FinanceCategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<String>('category_id')!;

    final manager = $$FinanceCategoriesTableTableManager(
      $_db,
      $_db.financeCategories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FinanceEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $FinanceEntriesTable> {
  $$FinanceEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FinanceCategoriesTableFilterComposer get categoryId {
    final $$FinanceCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.financeCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinanceCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.financeCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FinanceEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $FinanceEntriesTable> {
  $$FinanceEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FinanceCategoriesTableOrderingComposer get categoryId {
    final $$FinanceCategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.financeCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinanceCategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.financeCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FinanceEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FinanceEntriesTable> {
  $$FinanceEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get editedAt =>
      $composableBuilder(column: $table.editedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$FinanceCategoriesTableAnnotationComposer get categoryId {
    final $$FinanceCategoriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.categoryId,
          referencedTable: $db.financeCategories,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FinanceCategoriesTableAnnotationComposer(
                $db: $db,
                $table: $db.financeCategories,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$FinanceEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FinanceEntriesTable,
          FinanceEntry,
          $$FinanceEntriesTableFilterComposer,
          $$FinanceEntriesTableOrderingComposer,
          $$FinanceEntriesTableAnnotationComposer,
          $$FinanceEntriesTableCreateCompanionBuilder,
          $$FinanceEntriesTableUpdateCompanionBuilder,
          (FinanceEntry, $$FinanceEntriesTableReferences),
          FinanceEntry,
          PrefetchHooks Function({bool categoryId})
        > {
  $$FinanceEntriesTableTableManager(
    _$AppDatabase db,
    $FinanceEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FinanceEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FinanceEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FinanceEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> amountMinorUnits = const Value.absent(),
                Value<int> date = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> editedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FinanceEntriesCompanion(
                id: id,
                idempotencyKey: idempotencyKey,
                categoryId: categoryId,
                type: type,
                amountMinorUnits: amountMinorUnits,
                date: date,
                note: note,
                createdAt: createdAt,
                editedAt: editedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String idempotencyKey,
                required String categoryId,
                required String type,
                required int amountMinorUnits,
                required int date,
                Value<String?> note = const Value.absent(),
                required int createdAt,
                Value<int?> editedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FinanceEntriesCompanion.insert(
                id: id,
                idempotencyKey: idempotencyKey,
                categoryId: categoryId,
                type: type,
                amountMinorUnits: amountMinorUnits,
                date: date,
                note: note,
                createdAt: createdAt,
                editedAt: editedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FinanceEntriesTable, FinanceEntry>(table),
                  $$FinanceEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
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
                    if (categoryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.categoryId,
                                referencedTable: $$FinanceEntriesTableReferences
                                    ._categoryIdTable(db),
                                referencedColumn:
                                    $$FinanceEntriesTableReferences
                                        ._categoryIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$FinanceEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FinanceEntriesTable,
      FinanceEntry,
      $$FinanceEntriesTableFilterComposer,
      $$FinanceEntriesTableOrderingComposer,
      $$FinanceEntriesTableAnnotationComposer,
      $$FinanceEntriesTableCreateCompanionBuilder,
      $$FinanceEntriesTableUpdateCompanionBuilder,
      (FinanceEntry, $$FinanceEntriesTableReferences),
      FinanceEntry,
      PrefetchHooks Function({bool categoryId})
    >;
typedef $$OccasionAttachmentsTableCreateCompanionBuilder =
    OccasionAttachmentsCompanion Function({
      required String id,
      required String occasionId,
      required String filePath,
      required int createdAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });
typedef $$OccasionAttachmentsTableUpdateCompanionBuilder =
    OccasionAttachmentsCompanion Function({
      Value<String> id,
      Value<String> occasionId,
      Value<String> filePath,
      Value<int> createdAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });

final class $$OccasionAttachmentsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $OccasionAttachmentsTable,
          OccasionAttachment
        > {
  $$OccasionAttachmentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $OccasionsTable _occasionIdTable(_$AppDatabase db) => db.occasions
      .createAlias('occasion_attachments__occasion_id__occasions__id');

  $$OccasionsTableProcessedTableManager get occasionId {
    final $_column = $_itemColumn<String>('occasion_id')!;

    final manager = $$OccasionsTableTableManager(
      $_db,
      $_db.occasions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_occasionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OccasionAttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $OccasionAttachmentsTable> {
  $$OccasionAttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$OccasionsTableFilterComposer get occasionId {
    final $$OccasionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occasionId,
      referencedTable: $db.occasions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OccasionsTableFilterComposer(
            $db: $db,
            $table: $db.occasions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OccasionAttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $OccasionAttachmentsTable> {
  $$OccasionAttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$OccasionsTableOrderingComposer get occasionId {
    final $$OccasionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occasionId,
      referencedTable: $db.occasions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OccasionsTableOrderingComposer(
            $db: $db,
            $table: $db.occasions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OccasionAttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OccasionAttachmentsTable> {
  $$OccasionAttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$OccasionsTableAnnotationComposer get occasionId {
    final $$OccasionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occasionId,
      referencedTable: $db.occasions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OccasionsTableAnnotationComposer(
            $db: $db,
            $table: $db.occasions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OccasionAttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OccasionAttachmentsTable,
          OccasionAttachment,
          $$OccasionAttachmentsTableFilterComposer,
          $$OccasionAttachmentsTableOrderingComposer,
          $$OccasionAttachmentsTableAnnotationComposer,
          $$OccasionAttachmentsTableCreateCompanionBuilder,
          $$OccasionAttachmentsTableUpdateCompanionBuilder,
          (OccasionAttachment, $$OccasionAttachmentsTableReferences),
          OccasionAttachment,
          PrefetchHooks Function({bool occasionId})
        > {
  $$OccasionAttachmentsTableTableManager(
    _$AppDatabase db,
    $OccasionAttachmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OccasionAttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OccasionAttachmentsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$OccasionAttachmentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> occasionId = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OccasionAttachmentsCompanion(
                id: id,
                occasionId: occasionId,
                filePath: filePath,
                createdAt: createdAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String occasionId,
                required String filePath,
                required int createdAt,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OccasionAttachmentsCompanion.insert(
                id: id,
                occasionId: occasionId,
                filePath: filePath,
                createdAt: createdAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OccasionAttachmentsTable, OccasionAttachment>(
                    table,
                  ),
                  $$OccasionAttachmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({occasionId = false}) {
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
                    if (occasionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.occasionId,
                                referencedTable:
                                    $$OccasionAttachmentsTableReferences
                                        ._occasionIdTable(db),
                                referencedColumn:
                                    $$OccasionAttachmentsTableReferences
                                        ._occasionIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$OccasionAttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OccasionAttachmentsTable,
      OccasionAttachment,
      $$OccasionAttachmentsTableFilterComposer,
      $$OccasionAttachmentsTableOrderingComposer,
      $$OccasionAttachmentsTableAnnotationComposer,
      $$OccasionAttachmentsTableCreateCompanionBuilder,
      $$OccasionAttachmentsTableUpdateCompanionBuilder,
      (OccasionAttachment, $$OccasionAttachmentsTableReferences),
      OccasionAttachment,
      PrefetchHooks Function({bool occasionId})
    >;
typedef $$OcrScansTableCreateCompanionBuilder =
    OcrScansCompanion Function({
      required String id,
      required String idempotencyKey,
      required String sourceImagePath,
      Value<String?> cropBounds,
      Value<int> rotationDegrees,
      required String status,
      Value<String?> occasionId,
      Value<String?> defaultDirection,
      required int createdAt,
      Value<int?> completedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });
typedef $$OcrScansTableUpdateCompanionBuilder =
    OcrScansCompanion Function({
      Value<String> id,
      Value<String> idempotencyKey,
      Value<String> sourceImagePath,
      Value<String?> cropBounds,
      Value<int> rotationDegrees,
      Value<String> status,
      Value<String?> occasionId,
      Value<String?> defaultDirection,
      Value<int> createdAt,
      Value<int?> completedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });

final class $$OcrScansTableReferences
    extends BaseReferences<_$AppDatabase, $OcrScansTable, OcrScan> {
  $$OcrScansTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $OccasionsTable _occasionIdTable(_$AppDatabase db) =>
      db.occasions.createAlias('ocr_scans__occasion_id__occasions__id');

  $$OccasionsTableProcessedTableManager? get occasionId {
    final $_column = $_itemColumn<String>('occasion_id');
    if ($_column == null) return null;
    final manager = $$OccasionsTableTableManager(
      $_db,
      $_db.occasions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_occasionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CandidateEntriesTable, List<CandidateEntry>>
  _candidateEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.candidateEntries,
    aliasName: 'ocr_scans__id__candidate_entries__scan_id',
  );

  $$CandidateEntriesTableProcessedTableManager get candidateEntriesRefs {
    final manager = $$CandidateEntriesTableTableManager(
      $_db,
      $_db.candidateEntries,
    ).filter((f) => f.scanId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _candidateEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$OcrScansTableFilterComposer
    extends Composer<_$AppDatabase, $OcrScansTable> {
  $$OcrScansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceImagePath => $composableBuilder(
    column: $table.sourceImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cropBounds => $composableBuilder(
    column: $table.cropBounds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rotationDegrees => $composableBuilder(
    column: $table.rotationDegrees,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultDirection => $composableBuilder(
    column: $table.defaultDirection,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$OccasionsTableFilterComposer get occasionId {
    final $$OccasionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occasionId,
      referencedTable: $db.occasions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OccasionsTableFilterComposer(
            $db: $db,
            $table: $db.occasions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> candidateEntriesRefs(
    Expression<bool> Function($$CandidateEntriesTableFilterComposer f) f,
  ) {
    final $$CandidateEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.candidateEntries,
      getReferencedColumn: (t) => t.scanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CandidateEntriesTableFilterComposer(
            $db: $db,
            $table: $db.candidateEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$OcrScansTableOrderingComposer
    extends Composer<_$AppDatabase, $OcrScansTable> {
  $$OcrScansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceImagePath => $composableBuilder(
    column: $table.sourceImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cropBounds => $composableBuilder(
    column: $table.cropBounds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rotationDegrees => $composableBuilder(
    column: $table.rotationDegrees,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultDirection => $composableBuilder(
    column: $table.defaultDirection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$OccasionsTableOrderingComposer get occasionId {
    final $$OccasionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occasionId,
      referencedTable: $db.occasions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OccasionsTableOrderingComposer(
            $db: $db,
            $table: $db.occasions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OcrScansTableAnnotationComposer
    extends Composer<_$AppDatabase, $OcrScansTable> {
  $$OcrScansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceImagePath => $composableBuilder(
    column: $table.sourceImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cropBounds => $composableBuilder(
    column: $table.cropBounds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rotationDegrees => $composableBuilder(
    column: $table.rotationDegrees,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get defaultDirection => $composableBuilder(
    column: $table.defaultDirection,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$OccasionsTableAnnotationComposer get occasionId {
    final $$OccasionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occasionId,
      referencedTable: $db.occasions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OccasionsTableAnnotationComposer(
            $db: $db,
            $table: $db.occasions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> candidateEntriesRefs<T extends Object>(
    Expression<T> Function($$CandidateEntriesTableAnnotationComposer a) f,
  ) {
    final $$CandidateEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.candidateEntries,
      getReferencedColumn: (t) => t.scanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CandidateEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.candidateEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$OcrScansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OcrScansTable,
          OcrScan,
          $$OcrScansTableFilterComposer,
          $$OcrScansTableOrderingComposer,
          $$OcrScansTableAnnotationComposer,
          $$OcrScansTableCreateCompanionBuilder,
          $$OcrScansTableUpdateCompanionBuilder,
          (OcrScan, $$OcrScansTableReferences),
          OcrScan,
          PrefetchHooks Function({bool occasionId, bool candidateEntriesRefs})
        > {
  $$OcrScansTableTableManager(_$AppDatabase db, $OcrScansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OcrScansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OcrScansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OcrScansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String> sourceImagePath = const Value.absent(),
                Value<String?> cropBounds = const Value.absent(),
                Value<int> rotationDegrees = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> occasionId = const Value.absent(),
                Value<String?> defaultDirection = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OcrScansCompanion(
                id: id,
                idempotencyKey: idempotencyKey,
                sourceImagePath: sourceImagePath,
                cropBounds: cropBounds,
                rotationDegrees: rotationDegrees,
                status: status,
                occasionId: occasionId,
                defaultDirection: defaultDirection,
                createdAt: createdAt,
                completedAt: completedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String idempotencyKey,
                required String sourceImagePath,
                Value<String?> cropBounds = const Value.absent(),
                Value<int> rotationDegrees = const Value.absent(),
                required String status,
                Value<String?> occasionId = const Value.absent(),
                Value<String?> defaultDirection = const Value.absent(),
                required int createdAt,
                Value<int?> completedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OcrScansCompanion.insert(
                id: id,
                idempotencyKey: idempotencyKey,
                sourceImagePath: sourceImagePath,
                cropBounds: cropBounds,
                rotationDegrees: rotationDegrees,
                status: status,
                occasionId: occasionId,
                defaultDirection: defaultDirection,
                createdAt: createdAt,
                completedAt: completedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OcrScansTable, OcrScan>(table),
                  $$OcrScansTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({occasionId = false, candidateEntriesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (candidateEntriesRefs) db.candidateEntries,
                  ],
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
                        if (occasionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.occasionId,
                                    referencedTable: $$OcrScansTableReferences
                                        ._occasionIdTable(db),
                                    referencedColumn: $$OcrScansTableReferences
                                        ._occasionIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (candidateEntriesRefs)
                        await $_getPrefetchedData<
                          OcrScan,
                          $OcrScansTable,
                          CandidateEntry
                        >(
                          currentTable: table,
                          referencedTable: $$OcrScansTableReferences
                              ._candidateEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$OcrScansTableReferences(
                                db,
                                table,
                                p0,
                              ).candidateEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scanId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$OcrScansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OcrScansTable,
      OcrScan,
      $$OcrScansTableFilterComposer,
      $$OcrScansTableOrderingComposer,
      $$OcrScansTableAnnotationComposer,
      $$OcrScansTableCreateCompanionBuilder,
      $$OcrScansTableUpdateCompanionBuilder,
      (OcrScan, $$OcrScansTableReferences),
      OcrScan,
      PrefetchHooks Function({bool occasionId, bool candidateEntriesRefs})
    >;
typedef $$CandidateEntriesTableCreateCompanionBuilder =
    CandidateEntriesCompanion Function({
      required String id,
      required String scanId,
      Value<String> status,
      required String personName,
      required String personNameConfidenceKind,
      required String personNameConfidenceLevel,
      Value<String?> matchedPersonId,
      Value<int?> amountMinorUnits,
      required String amountConfidenceKind,
      required String amountConfidenceLevel,
      Value<String?> direction,
      required String directionConfidenceKind,
      required String directionConfidenceLevel,
      Value<int?> date,
      required String dateConfidenceKind,
      required String dateConfidenceLevel,
      Value<String?> notes,
      required String rawOcrText,
      required int createdAt,
      Value<int?> editedAt,
      Value<int> rowid,
    });
typedef $$CandidateEntriesTableUpdateCompanionBuilder =
    CandidateEntriesCompanion Function({
      Value<String> id,
      Value<String> scanId,
      Value<String> status,
      Value<String> personName,
      Value<String> personNameConfidenceKind,
      Value<String> personNameConfidenceLevel,
      Value<String?> matchedPersonId,
      Value<int?> amountMinorUnits,
      Value<String> amountConfidenceKind,
      Value<String> amountConfidenceLevel,
      Value<String?> direction,
      Value<String> directionConfidenceKind,
      Value<String> directionConfidenceLevel,
      Value<int?> date,
      Value<String> dateConfidenceKind,
      Value<String> dateConfidenceLevel,
      Value<String?> notes,
      Value<String> rawOcrText,
      Value<int> createdAt,
      Value<int?> editedAt,
      Value<int> rowid,
    });

final class $$CandidateEntriesTableReferences
    extends
        BaseReferences<_$AppDatabase, $CandidateEntriesTable, CandidateEntry> {
  $$CandidateEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $OcrScansTable _scanIdTable(_$AppDatabase db) =>
      db.ocrScans.createAlias('candidate_entries__scan_id__ocr_scans__id');

  $$OcrScansTableProcessedTableManager get scanId {
    final $_column = $_itemColumn<String>('scan_id')!;

    final manager = $$OcrScansTableTableManager(
      $_db,
      $_db.ocrScans,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scanIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PeopleTable _matchedPersonIdTable(_$AppDatabase db) =>
      db.people.createAlias('candidate_entries__matched_person_id__people__id');

  $$PeopleTableProcessedTableManager? get matchedPersonId {
    final $_column = $_itemColumn<String>('matched_person_id');
    if ($_column == null) return null;
    final manager = $$PeopleTableTableManager(
      $_db,
      $_db.people,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_matchedPersonIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CandidateEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $CandidateEntriesTable> {
  $$CandidateEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personName => $composableBuilder(
    column: $table.personName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personNameConfidenceKind => $composableBuilder(
    column: $table.personNameConfidenceKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personNameConfidenceLevel => $composableBuilder(
    column: $table.personNameConfidenceLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get amountConfidenceKind => $composableBuilder(
    column: $table.amountConfidenceKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get amountConfidenceLevel => $composableBuilder(
    column: $table.amountConfidenceLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get directionConfidenceKind => $composableBuilder(
    column: $table.directionConfidenceKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get directionConfidenceLevel => $composableBuilder(
    column: $table.directionConfidenceLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dateConfidenceKind => $composableBuilder(
    column: $table.dateConfidenceKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dateConfidenceLevel => $composableBuilder(
    column: $table.dateConfidenceLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawOcrText => $composableBuilder(
    column: $table.rawOcrText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$OcrScansTableFilterComposer get scanId {
    final $$OcrScansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.ocrScans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OcrScansTableFilterComposer(
            $db: $db,
            $table: $db.ocrScans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableFilterComposer get matchedPersonId {
    final $$PeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.matchedPersonId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableFilterComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CandidateEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CandidateEntriesTable> {
  $$CandidateEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personName => $composableBuilder(
    column: $table.personName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personNameConfidenceKind => $composableBuilder(
    column: $table.personNameConfidenceKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personNameConfidenceLevel => $composableBuilder(
    column: $table.personNameConfidenceLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get amountConfidenceKind => $composableBuilder(
    column: $table.amountConfidenceKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get amountConfidenceLevel => $composableBuilder(
    column: $table.amountConfidenceLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get directionConfidenceKind => $composableBuilder(
    column: $table.directionConfidenceKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get directionConfidenceLevel => $composableBuilder(
    column: $table.directionConfidenceLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dateConfidenceKind => $composableBuilder(
    column: $table.dateConfidenceKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dateConfidenceLevel => $composableBuilder(
    column: $table.dateConfidenceLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawOcrText => $composableBuilder(
    column: $table.rawOcrText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$OcrScansTableOrderingComposer get scanId {
    final $$OcrScansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.ocrScans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OcrScansTableOrderingComposer(
            $db: $db,
            $table: $db.ocrScans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableOrderingComposer get matchedPersonId {
    final $$PeopleTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.matchedPersonId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableOrderingComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CandidateEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CandidateEntriesTable> {
  $$CandidateEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get personName => $composableBuilder(
    column: $table.personName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get personNameConfidenceKind => $composableBuilder(
    column: $table.personNameConfidenceKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get personNameConfidenceLevel => $composableBuilder(
    column: $table.personNameConfidenceLevel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get amountConfidenceKind => $composableBuilder(
    column: $table.amountConfidenceKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get amountConfidenceLevel => $composableBuilder(
    column: $table.amountConfidenceLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get directionConfidenceKind => $composableBuilder(
    column: $table.directionConfidenceKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get directionConfidenceLevel => $composableBuilder(
    column: $table.directionConfidenceLevel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get dateConfidenceKind => $composableBuilder(
    column: $table.dateConfidenceKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dateConfidenceLevel => $composableBuilder(
    column: $table.dateConfidenceLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get rawOcrText => $composableBuilder(
    column: $table.rawOcrText,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get editedAt =>
      $composableBuilder(column: $table.editedAt, builder: (column) => column);

  $$OcrScansTableAnnotationComposer get scanId {
    final $$OcrScansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.ocrScans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OcrScansTableAnnotationComposer(
            $db: $db,
            $table: $db.ocrScans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableAnnotationComposer get matchedPersonId {
    final $$PeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.matchedPersonId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CandidateEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CandidateEntriesTable,
          CandidateEntry,
          $$CandidateEntriesTableFilterComposer,
          $$CandidateEntriesTableOrderingComposer,
          $$CandidateEntriesTableAnnotationComposer,
          $$CandidateEntriesTableCreateCompanionBuilder,
          $$CandidateEntriesTableUpdateCompanionBuilder,
          (CandidateEntry, $$CandidateEntriesTableReferences),
          CandidateEntry,
          PrefetchHooks Function({bool scanId, bool matchedPersonId})
        > {
  $$CandidateEntriesTableTableManager(
    _$AppDatabase db,
    $CandidateEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CandidateEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CandidateEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CandidateEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> scanId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> personName = const Value.absent(),
                Value<String> personNameConfidenceKind = const Value.absent(),
                Value<String> personNameConfidenceLevel = const Value.absent(),
                Value<String?> matchedPersonId = const Value.absent(),
                Value<int?> amountMinorUnits = const Value.absent(),
                Value<String> amountConfidenceKind = const Value.absent(),
                Value<String> amountConfidenceLevel = const Value.absent(),
                Value<String?> direction = const Value.absent(),
                Value<String> directionConfidenceKind = const Value.absent(),
                Value<String> directionConfidenceLevel = const Value.absent(),
                Value<int?> date = const Value.absent(),
                Value<String> dateConfidenceKind = const Value.absent(),
                Value<String> dateConfidenceLevel = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> rawOcrText = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> editedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CandidateEntriesCompanion(
                id: id,
                scanId: scanId,
                status: status,
                personName: personName,
                personNameConfidenceKind: personNameConfidenceKind,
                personNameConfidenceLevel: personNameConfidenceLevel,
                matchedPersonId: matchedPersonId,
                amountMinorUnits: amountMinorUnits,
                amountConfidenceKind: amountConfidenceKind,
                amountConfidenceLevel: amountConfidenceLevel,
                direction: direction,
                directionConfidenceKind: directionConfidenceKind,
                directionConfidenceLevel: directionConfidenceLevel,
                date: date,
                dateConfidenceKind: dateConfidenceKind,
                dateConfidenceLevel: dateConfidenceLevel,
                notes: notes,
                rawOcrText: rawOcrText,
                createdAt: createdAt,
                editedAt: editedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String scanId,
                Value<String> status = const Value.absent(),
                required String personName,
                required String personNameConfidenceKind,
                required String personNameConfidenceLevel,
                Value<String?> matchedPersonId = const Value.absent(),
                Value<int?> amountMinorUnits = const Value.absent(),
                required String amountConfidenceKind,
                required String amountConfidenceLevel,
                Value<String?> direction = const Value.absent(),
                required String directionConfidenceKind,
                required String directionConfidenceLevel,
                Value<int?> date = const Value.absent(),
                required String dateConfidenceKind,
                required String dateConfidenceLevel,
                Value<String?> notes = const Value.absent(),
                required String rawOcrText,
                required int createdAt,
                Value<int?> editedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CandidateEntriesCompanion.insert(
                id: id,
                scanId: scanId,
                status: status,
                personName: personName,
                personNameConfidenceKind: personNameConfidenceKind,
                personNameConfidenceLevel: personNameConfidenceLevel,
                matchedPersonId: matchedPersonId,
                amountMinorUnits: amountMinorUnits,
                amountConfidenceKind: amountConfidenceKind,
                amountConfidenceLevel: amountConfidenceLevel,
                direction: direction,
                directionConfidenceKind: directionConfidenceKind,
                directionConfidenceLevel: directionConfidenceLevel,
                date: date,
                dateConfidenceKind: dateConfidenceKind,
                dateConfidenceLevel: dateConfidenceLevel,
                notes: notes,
                rawOcrText: rawOcrText,
                createdAt: createdAt,
                editedAt: editedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CandidateEntriesTable, CandidateEntry>(table),
                  $$CandidateEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scanId = false, matchedPersonId = false}) {
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
                    if (scanId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.scanId,
                                referencedTable:
                                    $$CandidateEntriesTableReferences
                                        ._scanIdTable(db),
                                referencedColumn:
                                    $$CandidateEntriesTableReferences
                                        ._scanIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (matchedPersonId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.matchedPersonId,
                                referencedTable:
                                    $$CandidateEntriesTableReferences
                                        ._matchedPersonIdTable(db),
                                referencedColumn:
                                    $$CandidateEntriesTableReferences
                                        ._matchedPersonIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$CandidateEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CandidateEntriesTable,
      CandidateEntry,
      $$CandidateEntriesTableFilterComposer,
      $$CandidateEntriesTableOrderingComposer,
      $$CandidateEntriesTableAnnotationComposer,
      $$CandidateEntriesTableCreateCompanionBuilder,
      $$CandidateEntriesTableUpdateCompanionBuilder,
      (CandidateEntry, $$CandidateEntriesTableReferences),
      CandidateEntry,
      PrefetchHooks Function({bool scanId, bool matchedPersonId})
    >;
typedef $$BudgetsTableCreateCompanionBuilder =
    BudgetsCompanion Function({
      required String id,
      required String idempotencyKey,
      required String month,
      Value<int?> expectedIncomeMinorUnits,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });
typedef $$BudgetsTableUpdateCompanionBuilder =
    BudgetsCompanion Function({
      Value<String> id,
      Value<String> idempotencyKey,
      Value<String> month,
      Value<int?> expectedIncomeMinorUnits,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });

final class $$BudgetsTableReferences
    extends BaseReferences<_$AppDatabase, $BudgetsTable, Budget> {
  $$BudgetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $BudgetCategoryAllocationsTable,
    List<BudgetCategoryAllocation>
  >
  _budgetCategoryAllocationsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.budgetCategoryAllocations,
        aliasName: 'budgets__id__budget_category_allocations__budget_id',
      );

  $$BudgetCategoryAllocationsTableProcessedTableManager
  get budgetCategoryAllocationsRefs {
    final manager = $$BudgetCategoryAllocationsTableTableManager(
      $_db,
      $_db.budgetCategoryAllocations,
    ).filter((f) => f.budgetId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _budgetCategoryAllocationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expectedIncomeMinorUnits => $composableBuilder(
    column: $table.expectedIncomeMinorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> budgetCategoryAllocationsRefs(
    Expression<bool> Function($$BudgetCategoryAllocationsTableFilterComposer f)
    f,
  ) {
    final $$BudgetCategoryAllocationsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.budgetCategoryAllocations,
          getReferencedColumn: (t) => t.budgetId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BudgetCategoryAllocationsTableFilterComposer(
                $db: $db,
                $table: $db.budgetCategoryAllocations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$BudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expectedIncomeMinorUnits => $composableBuilder(
    column: $table.expectedIncomeMinorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get expectedIncomeMinorUnits => $composableBuilder(
    column: $table.expectedIncomeMinorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> budgetCategoryAllocationsRefs<T extends Object>(
    Expression<T> Function($$BudgetCategoryAllocationsTableAnnotationComposer a)
    f,
  ) {
    final $$BudgetCategoryAllocationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.budgetCategoryAllocations,
          getReferencedColumn: (t) => t.budgetId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BudgetCategoryAllocationsTableAnnotationComposer(
                $db: $db,
                $table: $db.budgetCategoryAllocations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$BudgetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetsTable,
          Budget,
          $$BudgetsTableFilterComposer,
          $$BudgetsTableOrderingComposer,
          $$BudgetsTableAnnotationComposer,
          $$BudgetsTableCreateCompanionBuilder,
          $$BudgetsTableUpdateCompanionBuilder,
          (Budget, $$BudgetsTableReferences),
          Budget,
          PrefetchHooks Function({bool budgetCategoryAllocationsRefs})
        > {
  $$BudgetsTableTableManager(_$AppDatabase db, $BudgetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String> month = const Value.absent(),
                Value<int?> expectedIncomeMinorUnits = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCompanion(
                id: id,
                idempotencyKey: idempotencyKey,
                month: month,
                expectedIncomeMinorUnits: expectedIncomeMinorUnits,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String idempotencyKey,
                required String month,
                Value<int?> expectedIncomeMinorUnits = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCompanion.insert(
                id: id,
                idempotencyKey: idempotencyKey,
                month: month,
                expectedIncomeMinorUnits: expectedIncomeMinorUnits,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BudgetsTable, Budget>(table),
                  $$BudgetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({budgetCategoryAllocationsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (budgetCategoryAllocationsRefs) db.budgetCategoryAllocations,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (budgetCategoryAllocationsRefs)
                    await $_getPrefetchedData<
                      Budget,
                      $BudgetsTable,
                      BudgetCategoryAllocation
                    >(
                      currentTable: table,
                      referencedTable: $$BudgetsTableReferences
                          ._budgetCategoryAllocationsRefsTable(db),
                      managerFromTypedResult: (p0) => $$BudgetsTableReferences(
                        db,
                        table,
                        p0,
                      ).budgetCategoryAllocationsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.budgetId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$BudgetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetsTable,
      Budget,
      $$BudgetsTableFilterComposer,
      $$BudgetsTableOrderingComposer,
      $$BudgetsTableAnnotationComposer,
      $$BudgetsTableCreateCompanionBuilder,
      $$BudgetsTableUpdateCompanionBuilder,
      (Budget, $$BudgetsTableReferences),
      Budget,
      PrefetchHooks Function({bool budgetCategoryAllocationsRefs})
    >;
typedef $$BudgetCategoryAllocationsTableCreateCompanionBuilder =
    BudgetCategoryAllocationsCompanion Function({
      required String id,
      required String idempotencyKey,
      required String budgetId,
      required String categoryId,
      required int plannedAmountMinorUnits,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$BudgetCategoryAllocationsTableUpdateCompanionBuilder =
    BudgetCategoryAllocationsCompanion Function({
      Value<String> id,
      Value<String> idempotencyKey,
      Value<String> budgetId,
      Value<String> categoryId,
      Value<int> plannedAmountMinorUnits,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$BudgetCategoryAllocationsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $BudgetCategoryAllocationsTable,
          BudgetCategoryAllocation
        > {
  $$BudgetCategoryAllocationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BudgetsTable _budgetIdTable(_$AppDatabase db) => db.budgets
      .createAlias('budget_category_allocations__budget_id__budgets__id');

  $$BudgetsTableProcessedTableManager get budgetId {
    final $_column = $_itemColumn<String>('budget_id')!;

    final manager = $$BudgetsTableTableManager(
      $_db,
      $_db.budgets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_budgetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $FinanceCategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.financeCategories.createAlias(
        'budget_category_allocations__category_id__finance_categories__id',
      );

  $$FinanceCategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<String>('category_id')!;

    final manager = $$FinanceCategoriesTableTableManager(
      $_db,
      $_db.financeCategories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BudgetCategoryAllocationsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetCategoryAllocationsTable> {
  $$BudgetCategoryAllocationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plannedAmountMinorUnits => $composableBuilder(
    column: $table.plannedAmountMinorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BudgetsTableFilterComposer get budgetId {
    final $$BudgetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.budgetId,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetsTableFilterComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FinanceCategoriesTableFilterComposer get categoryId {
    final $$FinanceCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.financeCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinanceCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.financeCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetCategoryAllocationsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetCategoryAllocationsTable> {
  $$BudgetCategoryAllocationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plannedAmountMinorUnits => $composableBuilder(
    column: $table.plannedAmountMinorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BudgetsTableOrderingComposer get budgetId {
    final $$BudgetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.budgetId,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetsTableOrderingComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FinanceCategoriesTableOrderingComposer get categoryId {
    final $$FinanceCategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.financeCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinanceCategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.financeCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetCategoryAllocationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetCategoryAllocationsTable> {
  $$BudgetCategoryAllocationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get plannedAmountMinorUnits => $composableBuilder(
    column: $table.plannedAmountMinorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BudgetsTableAnnotationComposer get budgetId {
    final $$BudgetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.budgetId,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetsTableAnnotationComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FinanceCategoriesTableAnnotationComposer get categoryId {
    final $$FinanceCategoriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.categoryId,
          referencedTable: $db.financeCategories,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FinanceCategoriesTableAnnotationComposer(
                $db: $db,
                $table: $db.financeCategories,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$BudgetCategoryAllocationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetCategoryAllocationsTable,
          BudgetCategoryAllocation,
          $$BudgetCategoryAllocationsTableFilterComposer,
          $$BudgetCategoryAllocationsTableOrderingComposer,
          $$BudgetCategoryAllocationsTableAnnotationComposer,
          $$BudgetCategoryAllocationsTableCreateCompanionBuilder,
          $$BudgetCategoryAllocationsTableUpdateCompanionBuilder,
          (
            BudgetCategoryAllocation,
            $$BudgetCategoryAllocationsTableReferences,
          ),
          BudgetCategoryAllocation,
          PrefetchHooks Function({bool budgetId, bool categoryId})
        > {
  $$BudgetCategoryAllocationsTableTableManager(
    _$AppDatabase db,
    $BudgetCategoryAllocationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetCategoryAllocationsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$BudgetCategoryAllocationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$BudgetCategoryAllocationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String> budgetId = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<int> plannedAmountMinorUnits = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetCategoryAllocationsCompanion(
                id: id,
                idempotencyKey: idempotencyKey,
                budgetId: budgetId,
                categoryId: categoryId,
                plannedAmountMinorUnits: plannedAmountMinorUnits,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String idempotencyKey,
                required String budgetId,
                required String categoryId,
                required int plannedAmountMinorUnits,
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => BudgetCategoryAllocationsCompanion.insert(
                id: id,
                idempotencyKey: idempotencyKey,
                budgetId: budgetId,
                categoryId: categoryId,
                plannedAmountMinorUnits: plannedAmountMinorUnits,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $BudgetCategoryAllocationsTable,
                    BudgetCategoryAllocation
                  >(table),
                  $$BudgetCategoryAllocationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({budgetId = false, categoryId = false}) {
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
                    if (budgetId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.budgetId,
                                referencedTable:
                                    $$BudgetCategoryAllocationsTableReferences
                                        ._budgetIdTable(db),
                                referencedColumn:
                                    $$BudgetCategoryAllocationsTableReferences
                                        ._budgetIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (categoryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.categoryId,
                                referencedTable:
                                    $$BudgetCategoryAllocationsTableReferences
                                        ._categoryIdTable(db),
                                referencedColumn:
                                    $$BudgetCategoryAllocationsTableReferences
                                        ._categoryIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$BudgetCategoryAllocationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetCategoryAllocationsTable,
      BudgetCategoryAllocation,
      $$BudgetCategoryAllocationsTableFilterComposer,
      $$BudgetCategoryAllocationsTableOrderingComposer,
      $$BudgetCategoryAllocationsTableAnnotationComposer,
      $$BudgetCategoryAllocationsTableCreateCompanionBuilder,
      $$BudgetCategoryAllocationsTableUpdateCompanionBuilder,
      (BudgetCategoryAllocation, $$BudgetCategoryAllocationsTableReferences),
      BudgetCategoryAllocation,
      PrefetchHooks Function({bool budgetId, bool categoryId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PeopleTableTableManager get people =>
      $$PeopleTableTableManager(_db, _db.people);
  $$OccasionsTableTableManager get occasions =>
      $$OccasionsTableTableManager(_db, _db.occasions);
  $$MoneyTransactionsTableTableManager get moneyTransactions =>
      $$MoneyTransactionsTableTableManager(_db, _db.moneyTransactions);
  $$TransactionAuditEntriesTableTableManager get transactionAuditEntries =>
      $$TransactionAuditEntriesTableTableManager(
        _db,
        _db.transactionAuditEntries,
      );
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$OnboardingStatusTableTableManager get onboardingStatus =>
      $$OnboardingStatusTableTableManager(_db, _db.onboardingStatus);
  $$FinanceCategoriesTableTableManager get financeCategories =>
      $$FinanceCategoriesTableTableManager(_db, _db.financeCategories);
  $$FinanceEntriesTableTableManager get financeEntries =>
      $$FinanceEntriesTableTableManager(_db, _db.financeEntries);
  $$OccasionAttachmentsTableTableManager get occasionAttachments =>
      $$OccasionAttachmentsTableTableManager(_db, _db.occasionAttachments);
  $$OcrScansTableTableManager get ocrScans =>
      $$OcrScansTableTableManager(_db, _db.ocrScans);
  $$CandidateEntriesTableTableManager get candidateEntries =>
      $$CandidateEntriesTableTableManager(_db, _db.candidateEntries);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db, _db.budgets);
  $$BudgetCategoryAllocationsTableTableManager get budgetCategoryAllocations =>
      $$BudgetCategoryAllocationsTableTableManager(
        _db,
        _db.budgetCategoryAllocations,
      );
}
