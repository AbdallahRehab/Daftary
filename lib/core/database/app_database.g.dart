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
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('EGP'),
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
    currencyCode,
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
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
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
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
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

  /// 018: ISO 4217 code of [amountMinorUnits]. Pre-018 rows are backfilled
  /// to explicit `'EGP'` by the v7 migration (FR-002).
  final String currencyCode;
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
    required this.currencyCode,
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
    map['currency_code'] = Variable<String>(currencyCode);
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
      currencyCode: Value(currencyCode),
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
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
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
      'currencyCode': serializer.toJson<String>(currencyCode),
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
    String? currencyCode,
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
    currencyCode: currencyCode ?? this.currencyCode,
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
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
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
          ..write('currencyCode: $currencyCode, ')
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
    currencyCode,
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
          other.currencyCode == this.currencyCode &&
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
  final Value<String> currencyCode;
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
    this.currencyCode = const Value.absent(),
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
    this.currencyCode = const Value.absent(),
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
    Expression<String>? currencyCode,
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
      if (currencyCode != null) 'currency_code': currencyCode,
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
    Value<String>? currencyCode,
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
      currencyCode: currencyCode ?? this.currencyCode,
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
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
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
          ..write('currencyCode: $currencyCode, ')
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
  static const VerificationMeta _glassEnabledMeta = const VerificationMeta(
    'glassEnabled',
  );
  @override
  late final GeneratedColumn<bool> glassEnabled = GeneratedColumn<bool>(
    'glass_enabled',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("glass_enabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _glassTransparencyMeta = const VerificationMeta(
    'glassTransparency',
  );
  @override
  late final GeneratedColumn<String> glassTransparency =
      GeneratedColumn<String>(
        'glass_transparency',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _glassIntensityMeta = const VerificationMeta(
    'glassIntensity',
  );
  @override
  late final GeneratedColumn<String> glassIntensity = GeneratedColumn<String>(
    'glass_intensity',
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
    glassEnabled,
    glassTransparency,
    glassIntensity,
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
    if (data.containsKey('glass_enabled')) {
      context.handle(
        _glassEnabledMeta,
        glassEnabled.isAcceptableOrUnknown(
          data['glass_enabled']!,
          _glassEnabledMeta,
        ),
      );
    }
    if (data.containsKey('glass_transparency')) {
      context.handle(
        _glassTransparencyMeta,
        glassTransparency.isAcceptableOrUnknown(
          data['glass_transparency']!,
          _glassTransparencyMeta,
        ),
      );
    }
    if (data.containsKey('glass_intensity')) {
      context.handle(
        _glassIntensityMeta,
        glassIntensity.isAcceptableOrUnknown(
          data['glass_intensity']!,
          _glassIntensityMeta,
        ),
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
      glassEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}glass_enabled'],
      ),
      glassTransparency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}glass_transparency'],
      ),
      glassIntensity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}glass_intensity'],
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

  /// 020: NULL = never set → default (data-model.md).
  final bool? glassEnabled;

  /// 020: a `GlassLevel.value`. NULL = never set → default (data-model.md).
  final String? glassTransparency;

  /// 020: a `GlassLevel.value`. NULL = never set → default (data-model.md).
  final String? glassIntensity;
  final int updatedAt;
  const AppSetting({
    required this.id,
    required this.languageCode,
    this.themeMode,
    this.glassEnabled,
    this.glassTransparency,
    this.glassIntensity,
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
    if (!nullToAbsent || glassEnabled != null) {
      map['glass_enabled'] = Variable<bool>(glassEnabled);
    }
    if (!nullToAbsent || glassTransparency != null) {
      map['glass_transparency'] = Variable<String>(glassTransparency);
    }
    if (!nullToAbsent || glassIntensity != null) {
      map['glass_intensity'] = Variable<String>(glassIntensity);
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
      glassEnabled: glassEnabled == null && nullToAbsent
          ? const Value.absent()
          : Value(glassEnabled),
      glassTransparency: glassTransparency == null && nullToAbsent
          ? const Value.absent()
          : Value(glassTransparency),
      glassIntensity: glassIntensity == null && nullToAbsent
          ? const Value.absent()
          : Value(glassIntensity),
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
      glassEnabled: serializer.fromJson<bool?>(json['glassEnabled']),
      glassTransparency: serializer.fromJson<String?>(
        json['glassTransparency'],
      ),
      glassIntensity: serializer.fromJson<String?>(json['glassIntensity']),
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
      'glassEnabled': serializer.toJson<bool?>(glassEnabled),
      'glassTransparency': serializer.toJson<String?>(glassTransparency),
      'glassIntensity': serializer.toJson<String?>(glassIntensity),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  AppSetting copyWith({
    String? id,
    String? languageCode,
    Value<String?> themeMode = const Value.absent(),
    Value<bool?> glassEnabled = const Value.absent(),
    Value<String?> glassTransparency = const Value.absent(),
    Value<String?> glassIntensity = const Value.absent(),
    int? updatedAt,
  }) => AppSetting(
    id: id ?? this.id,
    languageCode: languageCode ?? this.languageCode,
    themeMode: themeMode.present ? themeMode.value : this.themeMode,
    glassEnabled: glassEnabled.present ? glassEnabled.value : this.glassEnabled,
    glassTransparency: glassTransparency.present
        ? glassTransparency.value
        : this.glassTransparency,
    glassIntensity: glassIntensity.present
        ? glassIntensity.value
        : this.glassIntensity,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      languageCode: data.languageCode.present
          ? data.languageCode.value
          : this.languageCode,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      glassEnabled: data.glassEnabled.present
          ? data.glassEnabled.value
          : this.glassEnabled,
      glassTransparency: data.glassTransparency.present
          ? data.glassTransparency.value
          : this.glassTransparency,
      glassIntensity: data.glassIntensity.present
          ? data.glassIntensity.value
          : this.glassIntensity,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('languageCode: $languageCode, ')
          ..write('themeMode: $themeMode, ')
          ..write('glassEnabled: $glassEnabled, ')
          ..write('glassTransparency: $glassTransparency, ')
          ..write('glassIntensity: $glassIntensity, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    languageCode,
    themeMode,
    glassEnabled,
    glassTransparency,
    glassIntensity,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.languageCode == this.languageCode &&
          other.themeMode == this.themeMode &&
          other.glassEnabled == this.glassEnabled &&
          other.glassTransparency == this.glassTransparency &&
          other.glassIntensity == this.glassIntensity &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> id;
  final Value<String> languageCode;
  final Value<String?> themeMode;
  final Value<bool?> glassEnabled;
  final Value<String?> glassTransparency;
  final Value<String?> glassIntensity;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.languageCode = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.glassEnabled = const Value.absent(),
    this.glassTransparency = const Value.absent(),
    this.glassIntensity = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String id,
    required String languageCode,
    this.themeMode = const Value.absent(),
    this.glassEnabled = const Value.absent(),
    this.glassTransparency = const Value.absent(),
    this.glassIntensity = const Value.absent(),
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       languageCode = Value(languageCode),
       updatedAt = Value(updatedAt);
  static Insertable<AppSetting> custom({
    Expression<String>? id,
    Expression<String>? languageCode,
    Expression<String>? themeMode,
    Expression<bool>? glassEnabled,
    Expression<String>? glassTransparency,
    Expression<String>? glassIntensity,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (languageCode != null) 'language_code': languageCode,
      if (themeMode != null) 'theme_mode': themeMode,
      if (glassEnabled != null) 'glass_enabled': glassEnabled,
      if (glassTransparency != null) 'glass_transparency': glassTransparency,
      if (glassIntensity != null) 'glass_intensity': glassIntensity,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? id,
    Value<String>? languageCode,
    Value<String?>? themeMode,
    Value<bool?>? glassEnabled,
    Value<String?>? glassTransparency,
    Value<String?>? glassIntensity,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      languageCode: languageCode ?? this.languageCode,
      themeMode: themeMode ?? this.themeMode,
      glassEnabled: glassEnabled ?? this.glassEnabled,
      glassTransparency: glassTransparency ?? this.glassTransparency,
      glassIntensity: glassIntensity ?? this.glassIntensity,
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
    if (glassEnabled.present) {
      map['glass_enabled'] = Variable<bool>(glassEnabled.value);
    }
    if (glassTransparency.present) {
      map['glass_transparency'] = Variable<String>(glassTransparency.value);
    }
    if (glassIntensity.present) {
      map['glass_intensity'] = Variable<String>(glassIntensity.value);
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
          ..write('glassEnabled: $glassEnabled, ')
          ..write('glassTransparency: $glassTransparency, ')
          ..write('glassIntensity: $glassIntensity, ')
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
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('EGP'),
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
    currencyCode,
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
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
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
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
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

  /// 018: ISO 4217 code of [amountMinorUnits] (backfilled to `'EGP'`).
  final String currencyCode;
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
    required this.currencyCode,
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
    map['currency_code'] = Variable<String>(currencyCode);
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
      currencyCode: Value(currencyCode),
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
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
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
      'currencyCode': serializer.toJson<String>(currencyCode),
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
    String? currencyCode,
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
    currencyCode: currencyCode ?? this.currencyCode,
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
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
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
          ..write('currencyCode: $currencyCode, ')
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
    currencyCode,
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
          other.currencyCode == this.currencyCode &&
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
  final Value<String> currencyCode;
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
    this.currencyCode = const Value.absent(),
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
    this.currencyCode = const Value.absent(),
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
    Expression<String>? currencyCode,
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
      if (currencyCode != null) 'currency_code': currencyCode,
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
    Value<String>? currencyCode,
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
      currencyCode: currencyCode ?? this.currencyCode,
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
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
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
          ..write('currencyCode: $currencyCode, ')
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

class $NotificationPreferencesTable extends NotificationPreferences
    with TableInfo<$NotificationPreferencesTable, NotificationPreference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationPreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _budgetWarningsEnabledMeta =
      const VerificationMeta('budgetWarningsEnabled');
  @override
  late final GeneratedColumn<bool> budgetWarningsEnabled =
      GeneratedColumn<bool>(
        'budget_warnings_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("budget_warnings_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _savingsCheckInsEnabledMeta =
      const VerificationMeta('savingsCheckInsEnabled');
  @override
  late final GeneratedColumn<bool> savingsCheckInsEnabled =
      GeneratedColumn<bool>(
        'savings_check_ins_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("savings_check_ins_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _quietHoursStartMinutesMeta =
      const VerificationMeta('quietHoursStartMinutes');
  @override
  late final GeneratedColumn<int> quietHoursStartMinutes = GeneratedColumn<int>(
    'quiet_hours_start_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quietHoursEndMinutesMeta =
      const VerificationMeta('quietHoursEndMinutes');
  @override
  late final GeneratedColumn<int> quietHoursEndMinutes = GeneratedColumn<int>(
    'quiet_hours_end_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _osPermissionGrantedMeta =
      const VerificationMeta('osPermissionGranted');
  @override
  late final GeneratedColumn<bool> osPermissionGranted = GeneratedColumn<bool>(
    'os_permission_granted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("os_permission_granted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    isEnabled,
    budgetWarningsEnabled,
    savingsCheckInsEnabled,
    quietHoursStartMinutes,
    quietHoursEndMinutes,
    osPermissionGranted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notification_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotificationPreference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    if (data.containsKey('budget_warnings_enabled')) {
      context.handle(
        _budgetWarningsEnabledMeta,
        budgetWarningsEnabled.isAcceptableOrUnknown(
          data['budget_warnings_enabled']!,
          _budgetWarningsEnabledMeta,
        ),
      );
    }
    if (data.containsKey('savings_check_ins_enabled')) {
      context.handle(
        _savingsCheckInsEnabledMeta,
        savingsCheckInsEnabled.isAcceptableOrUnknown(
          data['savings_check_ins_enabled']!,
          _savingsCheckInsEnabledMeta,
        ),
      );
    }
    if (data.containsKey('quiet_hours_start_minutes')) {
      context.handle(
        _quietHoursStartMinutesMeta,
        quietHoursStartMinutes.isAcceptableOrUnknown(
          data['quiet_hours_start_minutes']!,
          _quietHoursStartMinutesMeta,
        ),
      );
    }
    if (data.containsKey('quiet_hours_end_minutes')) {
      context.handle(
        _quietHoursEndMinutesMeta,
        quietHoursEndMinutes.isAcceptableOrUnknown(
          data['quiet_hours_end_minutes']!,
          _quietHoursEndMinutesMeta,
        ),
      );
    }
    if (data.containsKey('os_permission_granted')) {
      context.handle(
        _osPermissionGrantedMeta,
        osPermissionGranted.isAcceptableOrUnknown(
          data['os_permission_granted']!,
          _osPermissionGrantedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotificationPreference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationPreference(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
      budgetWarningsEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}budget_warnings_enabled'],
      )!,
      savingsCheckInsEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}savings_check_ins_enabled'],
      )!,
      quietHoursStartMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quiet_hours_start_minutes'],
      ),
      quietHoursEndMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quiet_hours_end_minutes'],
      ),
      osPermissionGranted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}os_permission_granted'],
      )!,
    );
  }

  @override
  $NotificationPreferencesTable createAlias(String alias) {
    return $NotificationPreferencesTable(attachedDatabase, alias);
  }
}

class NotificationPreference extends DataClass
    implements Insertable<NotificationPreference> {
  final String id;
  final bool isEnabled;
  final bool budgetWarningsEnabled;
  final bool savingsCheckInsEnabled;
  final int? quietHoursStartMinutes;
  final int? quietHoursEndMinutes;
  final bool osPermissionGranted;
  const NotificationPreference({
    required this.id,
    required this.isEnabled,
    required this.budgetWarningsEnabled,
    required this.savingsCheckInsEnabled,
    this.quietHoursStartMinutes,
    this.quietHoursEndMinutes,
    required this.osPermissionGranted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['is_enabled'] = Variable<bool>(isEnabled);
    map['budget_warnings_enabled'] = Variable<bool>(budgetWarningsEnabled);
    map['savings_check_ins_enabled'] = Variable<bool>(savingsCheckInsEnabled);
    if (!nullToAbsent || quietHoursStartMinutes != null) {
      map['quiet_hours_start_minutes'] = Variable<int>(quietHoursStartMinutes);
    }
    if (!nullToAbsent || quietHoursEndMinutes != null) {
      map['quiet_hours_end_minutes'] = Variable<int>(quietHoursEndMinutes);
    }
    map['os_permission_granted'] = Variable<bool>(osPermissionGranted);
    return map;
  }

  NotificationPreferencesCompanion toCompanion(bool nullToAbsent) {
    return NotificationPreferencesCompanion(
      id: Value(id),
      isEnabled: Value(isEnabled),
      budgetWarningsEnabled: Value(budgetWarningsEnabled),
      savingsCheckInsEnabled: Value(savingsCheckInsEnabled),
      quietHoursStartMinutes: quietHoursStartMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(quietHoursStartMinutes),
      quietHoursEndMinutes: quietHoursEndMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(quietHoursEndMinutes),
      osPermissionGranted: Value(osPermissionGranted),
    );
  }

  factory NotificationPreference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationPreference(
      id: serializer.fromJson<String>(json['id']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      budgetWarningsEnabled: serializer.fromJson<bool>(
        json['budgetWarningsEnabled'],
      ),
      savingsCheckInsEnabled: serializer.fromJson<bool>(
        json['savingsCheckInsEnabled'],
      ),
      quietHoursStartMinutes: serializer.fromJson<int?>(
        json['quietHoursStartMinutes'],
      ),
      quietHoursEndMinutes: serializer.fromJson<int?>(
        json['quietHoursEndMinutes'],
      ),
      osPermissionGranted: serializer.fromJson<bool>(
        json['osPermissionGranted'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'budgetWarningsEnabled': serializer.toJson<bool>(budgetWarningsEnabled),
      'savingsCheckInsEnabled': serializer.toJson<bool>(savingsCheckInsEnabled),
      'quietHoursStartMinutes': serializer.toJson<int?>(quietHoursStartMinutes),
      'quietHoursEndMinutes': serializer.toJson<int?>(quietHoursEndMinutes),
      'osPermissionGranted': serializer.toJson<bool>(osPermissionGranted),
    };
  }

  NotificationPreference copyWith({
    String? id,
    bool? isEnabled,
    bool? budgetWarningsEnabled,
    bool? savingsCheckInsEnabled,
    Value<int?> quietHoursStartMinutes = const Value.absent(),
    Value<int?> quietHoursEndMinutes = const Value.absent(),
    bool? osPermissionGranted,
  }) => NotificationPreference(
    id: id ?? this.id,
    isEnabled: isEnabled ?? this.isEnabled,
    budgetWarningsEnabled: budgetWarningsEnabled ?? this.budgetWarningsEnabled,
    savingsCheckInsEnabled:
        savingsCheckInsEnabled ?? this.savingsCheckInsEnabled,
    quietHoursStartMinutes: quietHoursStartMinutes.present
        ? quietHoursStartMinutes.value
        : this.quietHoursStartMinutes,
    quietHoursEndMinutes: quietHoursEndMinutes.present
        ? quietHoursEndMinutes.value
        : this.quietHoursEndMinutes,
    osPermissionGranted: osPermissionGranted ?? this.osPermissionGranted,
  );
  NotificationPreference copyWithCompanion(
    NotificationPreferencesCompanion data,
  ) {
    return NotificationPreference(
      id: data.id.present ? data.id.value : this.id,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      budgetWarningsEnabled: data.budgetWarningsEnabled.present
          ? data.budgetWarningsEnabled.value
          : this.budgetWarningsEnabled,
      savingsCheckInsEnabled: data.savingsCheckInsEnabled.present
          ? data.savingsCheckInsEnabled.value
          : this.savingsCheckInsEnabled,
      quietHoursStartMinutes: data.quietHoursStartMinutes.present
          ? data.quietHoursStartMinutes.value
          : this.quietHoursStartMinutes,
      quietHoursEndMinutes: data.quietHoursEndMinutes.present
          ? data.quietHoursEndMinutes.value
          : this.quietHoursEndMinutes,
      osPermissionGranted: data.osPermissionGranted.present
          ? data.osPermissionGranted.value
          : this.osPermissionGranted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationPreference(')
          ..write('id: $id, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('budgetWarningsEnabled: $budgetWarningsEnabled, ')
          ..write('savingsCheckInsEnabled: $savingsCheckInsEnabled, ')
          ..write('quietHoursStartMinutes: $quietHoursStartMinutes, ')
          ..write('quietHoursEndMinutes: $quietHoursEndMinutes, ')
          ..write('osPermissionGranted: $osPermissionGranted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    isEnabled,
    budgetWarningsEnabled,
    savingsCheckInsEnabled,
    quietHoursStartMinutes,
    quietHoursEndMinutes,
    osPermissionGranted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationPreference &&
          other.id == this.id &&
          other.isEnabled == this.isEnabled &&
          other.budgetWarningsEnabled == this.budgetWarningsEnabled &&
          other.savingsCheckInsEnabled == this.savingsCheckInsEnabled &&
          other.quietHoursStartMinutes == this.quietHoursStartMinutes &&
          other.quietHoursEndMinutes == this.quietHoursEndMinutes &&
          other.osPermissionGranted == this.osPermissionGranted);
}

class NotificationPreferencesCompanion
    extends UpdateCompanion<NotificationPreference> {
  final Value<String> id;
  final Value<bool> isEnabled;
  final Value<bool> budgetWarningsEnabled;
  final Value<bool> savingsCheckInsEnabled;
  final Value<int?> quietHoursStartMinutes;
  final Value<int?> quietHoursEndMinutes;
  final Value<bool> osPermissionGranted;
  final Value<int> rowid;
  const NotificationPreferencesCompanion({
    this.id = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.budgetWarningsEnabled = const Value.absent(),
    this.savingsCheckInsEnabled = const Value.absent(),
    this.quietHoursStartMinutes = const Value.absent(),
    this.quietHoursEndMinutes = const Value.absent(),
    this.osPermissionGranted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotificationPreferencesCompanion.insert({
    required String id,
    this.isEnabled = const Value.absent(),
    this.budgetWarningsEnabled = const Value.absent(),
    this.savingsCheckInsEnabled = const Value.absent(),
    this.quietHoursStartMinutes = const Value.absent(),
    this.quietHoursEndMinutes = const Value.absent(),
    this.osPermissionGranted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<NotificationPreference> custom({
    Expression<String>? id,
    Expression<bool>? isEnabled,
    Expression<bool>? budgetWarningsEnabled,
    Expression<bool>? savingsCheckInsEnabled,
    Expression<int>? quietHoursStartMinutes,
    Expression<int>? quietHoursEndMinutes,
    Expression<bool>? osPermissionGranted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (budgetWarningsEnabled != null)
        'budget_warnings_enabled': budgetWarningsEnabled,
      if (savingsCheckInsEnabled != null)
        'savings_check_ins_enabled': savingsCheckInsEnabled,
      if (quietHoursStartMinutes != null)
        'quiet_hours_start_minutes': quietHoursStartMinutes,
      if (quietHoursEndMinutes != null)
        'quiet_hours_end_minutes': quietHoursEndMinutes,
      if (osPermissionGranted != null)
        'os_permission_granted': osPermissionGranted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotificationPreferencesCompanion copyWith({
    Value<String>? id,
    Value<bool>? isEnabled,
    Value<bool>? budgetWarningsEnabled,
    Value<bool>? savingsCheckInsEnabled,
    Value<int?>? quietHoursStartMinutes,
    Value<int?>? quietHoursEndMinutes,
    Value<bool>? osPermissionGranted,
    Value<int>? rowid,
  }) {
    return NotificationPreferencesCompanion(
      id: id ?? this.id,
      isEnabled: isEnabled ?? this.isEnabled,
      budgetWarningsEnabled:
          budgetWarningsEnabled ?? this.budgetWarningsEnabled,
      savingsCheckInsEnabled:
          savingsCheckInsEnabled ?? this.savingsCheckInsEnabled,
      quietHoursStartMinutes:
          quietHoursStartMinutes ?? this.quietHoursStartMinutes,
      quietHoursEndMinutes: quietHoursEndMinutes ?? this.quietHoursEndMinutes,
      osPermissionGranted: osPermissionGranted ?? this.osPermissionGranted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (budgetWarningsEnabled.present) {
      map['budget_warnings_enabled'] = Variable<bool>(
        budgetWarningsEnabled.value,
      );
    }
    if (savingsCheckInsEnabled.present) {
      map['savings_check_ins_enabled'] = Variable<bool>(
        savingsCheckInsEnabled.value,
      );
    }
    if (quietHoursStartMinutes.present) {
      map['quiet_hours_start_minutes'] = Variable<int>(
        quietHoursStartMinutes.value,
      );
    }
    if (quietHoursEndMinutes.present) {
      map['quiet_hours_end_minutes'] = Variable<int>(
        quietHoursEndMinutes.value,
      );
    }
    if (osPermissionGranted.present) {
      map['os_permission_granted'] = Variable<bool>(osPermissionGranted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationPreferencesCompanion(')
          ..write('id: $id, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('budgetWarningsEnabled: $budgetWarningsEnabled, ')
          ..write('savingsCheckInsEnabled: $savingsCheckInsEnabled, ')
          ..write('quietHoursStartMinutes: $quietHoursStartMinutes, ')
          ..write('quietHoursEndMinutes: $quietHoursEndMinutes, ')
          ..write('osPermissionGranted: $osPermissionGranted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotificationHistoryTable extends NotificationHistory
    with TableInfo<$NotificationHistoryTable, NotificationHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _applicablePeriodMeta = const VerificationMeta(
    'applicablePeriod',
  );
  @override
  late final GeneratedColumn<String> applicablePeriod = GeneratedColumn<String>(
    'applicable_period',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastNotifiedBandMeta = const VerificationMeta(
    'lastNotifiedBand',
  );
  @override
  late final GeneratedColumn<String> lastNotifiedBand = GeneratedColumn<String>(
    'last_notified_band',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastNotifiedAtMeta = const VerificationMeta(
    'lastNotifiedAt',
  );
  @override
  late final GeneratedColumn<int> lastNotifiedAt = GeneratedColumn<int>(
    'last_notified_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceType,
    sourceId,
    applicablePeriod,
    lastNotifiedBand,
    lastNotifiedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notification_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotificationHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('applicable_period')) {
      context.handle(
        _applicablePeriodMeta,
        applicablePeriod.isAcceptableOrUnknown(
          data['applicable_period']!,
          _applicablePeriodMeta,
        ),
      );
    }
    if (data.containsKey('last_notified_band')) {
      context.handle(
        _lastNotifiedBandMeta,
        lastNotifiedBand.isAcceptableOrUnknown(
          data['last_notified_band']!,
          _lastNotifiedBandMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastNotifiedBandMeta);
    }
    if (data.containsKey('last_notified_at')) {
      context.handle(
        _lastNotifiedAtMeta,
        lastNotifiedAt.isAcceptableOrUnknown(
          data['last_notified_at']!,
          _lastNotifiedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastNotifiedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotificationHistoryData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      applicablePeriod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}applicable_period'],
      ),
      lastNotifiedBand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_notified_band'],
      )!,
      lastNotifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_notified_at'],
      )!,
    );
  }

  @override
  $NotificationHistoryTable createAlias(String alias) {
    return $NotificationHistoryTable(attachedDatabase, alias);
  }
}

class NotificationHistoryData extends DataClass
    implements Insertable<NotificationHistoryData> {
  final String id;

  /// `'budgetCategory'` | `'savingsGoal'`.
  final String sourceType;
  final String sourceId;

  /// `'YYYY-MM'` for budget categories, null for savings goals.
  final String? applicablePeriod;

  /// A `ThresholdBand` name.
  final String lastNotifiedBand;
  final int lastNotifiedAt;
  const NotificationHistoryData({
    required this.id,
    required this.sourceType,
    required this.sourceId,
    this.applicablePeriod,
    required this.lastNotifiedBand,
    required this.lastNotifiedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_type'] = Variable<String>(sourceType);
    map['source_id'] = Variable<String>(sourceId);
    if (!nullToAbsent || applicablePeriod != null) {
      map['applicable_period'] = Variable<String>(applicablePeriod);
    }
    map['last_notified_band'] = Variable<String>(lastNotifiedBand);
    map['last_notified_at'] = Variable<int>(lastNotifiedAt);
    return map;
  }

  NotificationHistoryCompanion toCompanion(bool nullToAbsent) {
    return NotificationHistoryCompanion(
      id: Value(id),
      sourceType: Value(sourceType),
      sourceId: Value(sourceId),
      applicablePeriod: applicablePeriod == null && nullToAbsent
          ? const Value.absent()
          : Value(applicablePeriod),
      lastNotifiedBand: Value(lastNotifiedBand),
      lastNotifiedAt: Value(lastNotifiedAt),
    );
  }

  factory NotificationHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationHistoryData(
      id: serializer.fromJson<String>(json['id']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      applicablePeriod: serializer.fromJson<String?>(json['applicablePeriod']),
      lastNotifiedBand: serializer.fromJson<String>(json['lastNotifiedBand']),
      lastNotifiedAt: serializer.fromJson<int>(json['lastNotifiedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceType': serializer.toJson<String>(sourceType),
      'sourceId': serializer.toJson<String>(sourceId),
      'applicablePeriod': serializer.toJson<String?>(applicablePeriod),
      'lastNotifiedBand': serializer.toJson<String>(lastNotifiedBand),
      'lastNotifiedAt': serializer.toJson<int>(lastNotifiedAt),
    };
  }

  NotificationHistoryData copyWith({
    String? id,
    String? sourceType,
    String? sourceId,
    Value<String?> applicablePeriod = const Value.absent(),
    String? lastNotifiedBand,
    int? lastNotifiedAt,
  }) => NotificationHistoryData(
    id: id ?? this.id,
    sourceType: sourceType ?? this.sourceType,
    sourceId: sourceId ?? this.sourceId,
    applicablePeriod: applicablePeriod.present
        ? applicablePeriod.value
        : this.applicablePeriod,
    lastNotifiedBand: lastNotifiedBand ?? this.lastNotifiedBand,
    lastNotifiedAt: lastNotifiedAt ?? this.lastNotifiedAt,
  );
  NotificationHistoryData copyWithCompanion(NotificationHistoryCompanion data) {
    return NotificationHistoryData(
      id: data.id.present ? data.id.value : this.id,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      applicablePeriod: data.applicablePeriod.present
          ? data.applicablePeriod.value
          : this.applicablePeriod,
      lastNotifiedBand: data.lastNotifiedBand.present
          ? data.lastNotifiedBand.value
          : this.lastNotifiedBand,
      lastNotifiedAt: data.lastNotifiedAt.present
          ? data.lastNotifiedAt.value
          : this.lastNotifiedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationHistoryData(')
          ..write('id: $id, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
          ..write('applicablePeriod: $applicablePeriod, ')
          ..write('lastNotifiedBand: $lastNotifiedBand, ')
          ..write('lastNotifiedAt: $lastNotifiedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceType,
    sourceId,
    applicablePeriod,
    lastNotifiedBand,
    lastNotifiedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationHistoryData &&
          other.id == this.id &&
          other.sourceType == this.sourceType &&
          other.sourceId == this.sourceId &&
          other.applicablePeriod == this.applicablePeriod &&
          other.lastNotifiedBand == this.lastNotifiedBand &&
          other.lastNotifiedAt == this.lastNotifiedAt);
}

class NotificationHistoryCompanion
    extends UpdateCompanion<NotificationHistoryData> {
  final Value<String> id;
  final Value<String> sourceType;
  final Value<String> sourceId;
  final Value<String?> applicablePeriod;
  final Value<String> lastNotifiedBand;
  final Value<int> lastNotifiedAt;
  final Value<int> rowid;
  const NotificationHistoryCompanion({
    this.id = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.applicablePeriod = const Value.absent(),
    this.lastNotifiedBand = const Value.absent(),
    this.lastNotifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotificationHistoryCompanion.insert({
    required String id,
    required String sourceType,
    required String sourceId,
    this.applicablePeriod = const Value.absent(),
    required String lastNotifiedBand,
    required int lastNotifiedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceType = Value(sourceType),
       sourceId = Value(sourceId),
       lastNotifiedBand = Value(lastNotifiedBand),
       lastNotifiedAt = Value(lastNotifiedAt);
  static Insertable<NotificationHistoryData> custom({
    Expression<String>? id,
    Expression<String>? sourceType,
    Expression<String>? sourceId,
    Expression<String>? applicablePeriod,
    Expression<String>? lastNotifiedBand,
    Expression<int>? lastNotifiedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceId != null) 'source_id': sourceId,
      if (applicablePeriod != null) 'applicable_period': applicablePeriod,
      if (lastNotifiedBand != null) 'last_notified_band': lastNotifiedBand,
      if (lastNotifiedAt != null) 'last_notified_at': lastNotifiedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotificationHistoryCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceType,
    Value<String>? sourceId,
    Value<String?>? applicablePeriod,
    Value<String>? lastNotifiedBand,
    Value<int>? lastNotifiedAt,
    Value<int>? rowid,
  }) {
    return NotificationHistoryCompanion(
      id: id ?? this.id,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      applicablePeriod: applicablePeriod ?? this.applicablePeriod,
      lastNotifiedBand: lastNotifiedBand ?? this.lastNotifiedBand,
      lastNotifiedAt: lastNotifiedAt ?? this.lastNotifiedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (applicablePeriod.present) {
      map['applicable_period'] = Variable<String>(applicablePeriod.value);
    }
    if (lastNotifiedBand.present) {
      map['last_notified_band'] = Variable<String>(lastNotifiedBand.value);
    }
    if (lastNotifiedAt.present) {
      map['last_notified_at'] = Variable<int>(lastNotifiedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationHistoryCompanion(')
          ..write('id: $id, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
          ..write('applicablePeriod: $applicablePeriod, ')
          ..write('lastNotifiedBand: $lastNotifiedBand, ')
          ..write('lastNotifiedAt: $lastNotifiedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PrimaryCurrencySettingsTable extends PrimaryCurrencySettings
    with TableInfo<$PrimaryCurrencySettingsTable, PrimaryCurrencySetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrimaryCurrencySettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('EGP'),
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
  List<GeneratedColumn> get $columns => [id, currencyCode, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'primary_currency_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrimaryCurrencySetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
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
  PrimaryCurrencySetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrimaryCurrencySetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PrimaryCurrencySettingsTable createAlias(String alias) {
    return $PrimaryCurrencySettingsTable(attachedDatabase, alias);
  }
}

class PrimaryCurrencySetting extends DataClass
    implements Insertable<PrimaryCurrencySetting> {
  final String id;
  final String currencyCode;
  final int updatedAt;
  const PrimaryCurrencySetting({
    required this.id,
    required this.currencyCode,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['currency_code'] = Variable<String>(currencyCode);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  PrimaryCurrencySettingsCompanion toCompanion(bool nullToAbsent) {
    return PrimaryCurrencySettingsCompanion(
      id: Value(id),
      currencyCode: Value(currencyCode),
      updatedAt: Value(updatedAt),
    );
  }

  factory PrimaryCurrencySetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrimaryCurrencySetting(
      id: serializer.fromJson<String>(json['id']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  PrimaryCurrencySetting copyWith({
    String? id,
    String? currencyCode,
    int? updatedAt,
  }) => PrimaryCurrencySetting(
    id: id ?? this.id,
    currencyCode: currencyCode ?? this.currencyCode,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PrimaryCurrencySetting copyWithCompanion(
    PrimaryCurrencySettingsCompanion data,
  ) {
    return PrimaryCurrencySetting(
      id: data.id.present ? data.id.value : this.id,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrimaryCurrencySetting(')
          ..write('id: $id, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, currencyCode, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrimaryCurrencySetting &&
          other.id == this.id &&
          other.currencyCode == this.currencyCode &&
          other.updatedAt == this.updatedAt);
}

class PrimaryCurrencySettingsCompanion
    extends UpdateCompanion<PrimaryCurrencySetting> {
  final Value<String> id;
  final Value<String> currencyCode;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const PrimaryCurrencySettingsCompanion({
    this.id = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrimaryCurrencySettingsCompanion.insert({
    required String id,
    this.currencyCode = const Value.absent(),
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt);
  static Insertable<PrimaryCurrencySetting> custom({
    Expression<String>? id,
    Expression<String>? currencyCode,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrimaryCurrencySettingsCompanion copyWith({
    Value<String>? id,
    Value<String>? currencyCode,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return PrimaryCurrencySettingsCompanion(
      id: id ?? this.id,
      currencyCode: currencyCode ?? this.currencyCode,
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
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
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
    return (StringBuffer('PrimaryCurrencySettingsCompanion(')
          ..write('id: $id, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExchangeRatesTable extends ExchangeRates
    with TableInfo<$ExchangeRatesTable, ExchangeRate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExchangeRatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relativeToCurrencyCodeMeta =
      const VerificationMeta('relativeToCurrencyCode');
  @override
  late final GeneratedColumn<String> relativeToCurrencyCode =
      GeneratedColumn<String>(
        'relative_to_currency_code',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _rateMicrosMeta = const VerificationMeta(
    'rateMicros',
  );
  @override
  late final GeneratedColumn<int> rateMicros = GeneratedColumn<int>(
    'rate_micros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastUpdatedAtMeta = const VerificationMeta(
    'lastUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> lastUpdatedAt = GeneratedColumn<int>(
    'last_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    currencyCode,
    relativeToCurrencyCode,
    rateMicros,
    lastUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exchange_rates';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExchangeRate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('relative_to_currency_code')) {
      context.handle(
        _relativeToCurrencyCodeMeta,
        relativeToCurrencyCode.isAcceptableOrUnknown(
          data['relative_to_currency_code']!,
          _relativeToCurrencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relativeToCurrencyCodeMeta);
    }
    if (data.containsKey('rate_micros')) {
      context.handle(
        _rateMicrosMeta,
        rateMicros.isAcceptableOrUnknown(data['rate_micros']!, _rateMicrosMeta),
      );
    } else if (isInserting) {
      context.missing(_rateMicrosMeta);
    }
    if (data.containsKey('last_updated_at')) {
      context.handle(
        _lastUpdatedAtMeta,
        lastUpdatedAt.isAcceptableOrUnknown(
          data['last_updated_at']!,
          _lastUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUpdatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExchangeRate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExchangeRate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      relativeToCurrencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_to_currency_code'],
      )!,
      rateMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rate_micros'],
      )!,
      lastUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_updated_at'],
      )!,
    );
  }

  @override
  $ExchangeRatesTable createAlias(String alias) {
    return $ExchangeRatesTable(attachedDatabase, alias);
  }
}

class ExchangeRate extends DataClass implements Insertable<ExchangeRate> {
  final String id;
  final String currencyCode;
  final String relativeToCurrencyCode;
  final int rateMicros;
  final int lastUpdatedAt;
  const ExchangeRate({
    required this.id,
    required this.currencyCode,
    required this.relativeToCurrencyCode,
    required this.rateMicros,
    required this.lastUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['currency_code'] = Variable<String>(currencyCode);
    map['relative_to_currency_code'] = Variable<String>(relativeToCurrencyCode);
    map['rate_micros'] = Variable<int>(rateMicros);
    map['last_updated_at'] = Variable<int>(lastUpdatedAt);
    return map;
  }

  ExchangeRatesCompanion toCompanion(bool nullToAbsent) {
    return ExchangeRatesCompanion(
      id: Value(id),
      currencyCode: Value(currencyCode),
      relativeToCurrencyCode: Value(relativeToCurrencyCode),
      rateMicros: Value(rateMicros),
      lastUpdatedAt: Value(lastUpdatedAt),
    );
  }

  factory ExchangeRate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExchangeRate(
      id: serializer.fromJson<String>(json['id']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      relativeToCurrencyCode: serializer.fromJson<String>(
        json['relativeToCurrencyCode'],
      ),
      rateMicros: serializer.fromJson<int>(json['rateMicros']),
      lastUpdatedAt: serializer.fromJson<int>(json['lastUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'relativeToCurrencyCode': serializer.toJson<String>(
        relativeToCurrencyCode,
      ),
      'rateMicros': serializer.toJson<int>(rateMicros),
      'lastUpdatedAt': serializer.toJson<int>(lastUpdatedAt),
    };
  }

  ExchangeRate copyWith({
    String? id,
    String? currencyCode,
    String? relativeToCurrencyCode,
    int? rateMicros,
    int? lastUpdatedAt,
  }) => ExchangeRate(
    id: id ?? this.id,
    currencyCode: currencyCode ?? this.currencyCode,
    relativeToCurrencyCode:
        relativeToCurrencyCode ?? this.relativeToCurrencyCode,
    rateMicros: rateMicros ?? this.rateMicros,
    lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
  );
  ExchangeRate copyWithCompanion(ExchangeRatesCompanion data) {
    return ExchangeRate(
      id: data.id.present ? data.id.value : this.id,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      relativeToCurrencyCode: data.relativeToCurrencyCode.present
          ? data.relativeToCurrencyCode.value
          : this.relativeToCurrencyCode,
      rateMicros: data.rateMicros.present
          ? data.rateMicros.value
          : this.rateMicros,
      lastUpdatedAt: data.lastUpdatedAt.present
          ? data.lastUpdatedAt.value
          : this.lastUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExchangeRate(')
          ..write('id: $id, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('relativeToCurrencyCode: $relativeToCurrencyCode, ')
          ..write('rateMicros: $rateMicros, ')
          ..write('lastUpdatedAt: $lastUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    currencyCode,
    relativeToCurrencyCode,
    rateMicros,
    lastUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExchangeRate &&
          other.id == this.id &&
          other.currencyCode == this.currencyCode &&
          other.relativeToCurrencyCode == this.relativeToCurrencyCode &&
          other.rateMicros == this.rateMicros &&
          other.lastUpdatedAt == this.lastUpdatedAt);
}

class ExchangeRatesCompanion extends UpdateCompanion<ExchangeRate> {
  final Value<String> id;
  final Value<String> currencyCode;
  final Value<String> relativeToCurrencyCode;
  final Value<int> rateMicros;
  final Value<int> lastUpdatedAt;
  final Value<int> rowid;
  const ExchangeRatesCompanion({
    this.id = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.relativeToCurrencyCode = const Value.absent(),
    this.rateMicros = const Value.absent(),
    this.lastUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExchangeRatesCompanion.insert({
    required String id,
    required String currencyCode,
    required String relativeToCurrencyCode,
    required int rateMicros,
    required int lastUpdatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       currencyCode = Value(currencyCode),
       relativeToCurrencyCode = Value(relativeToCurrencyCode),
       rateMicros = Value(rateMicros),
       lastUpdatedAt = Value(lastUpdatedAt);
  static Insertable<ExchangeRate> custom({
    Expression<String>? id,
    Expression<String>? currencyCode,
    Expression<String>? relativeToCurrencyCode,
    Expression<int>? rateMicros,
    Expression<int>? lastUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (relativeToCurrencyCode != null)
        'relative_to_currency_code': relativeToCurrencyCode,
      if (rateMicros != null) 'rate_micros': rateMicros,
      if (lastUpdatedAt != null) 'last_updated_at': lastUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExchangeRatesCompanion copyWith({
    Value<String>? id,
    Value<String>? currencyCode,
    Value<String>? relativeToCurrencyCode,
    Value<int>? rateMicros,
    Value<int>? lastUpdatedAt,
    Value<int>? rowid,
  }) {
    return ExchangeRatesCompanion(
      id: id ?? this.id,
      currencyCode: currencyCode ?? this.currencyCode,
      relativeToCurrencyCode:
          relativeToCurrencyCode ?? this.relativeToCurrencyCode,
      rateMicros: rateMicros ?? this.rateMicros,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (relativeToCurrencyCode.present) {
      map['relative_to_currency_code'] = Variable<String>(
        relativeToCurrencyCode.value,
      );
    }
    if (rateMicros.present) {
      map['rate_micros'] = Variable<int>(rateMicros.value);
    }
    if (lastUpdatedAt.present) {
      map['last_updated_at'] = Variable<int>(lastUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExchangeRatesCompanion(')
          ..write('id: $id, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('relativeToCurrencyCode: $relativeToCurrencyCode, ')
          ..write('rateMicros: $rateMicros, ')
          ..write('lastUpdatedAt: $lastUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncOutboxEntriesTable extends SyncOutboxEntries
    with TableInfo<$SyncOutboxEntriesTable, SyncOutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOutboxEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _opIdMeta = const VerificationMeta('opId');
  @override
  late final GeneratedColumn<String> opId = GeneratedColumn<String>(
    'op_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _opTypeMeta = const VerificationMeta('opType');
  @override
  late final GeneratedColumn<String> opType = GeneratedColumn<String>(
    'op_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseRevisionMeta = const VerificationMeta(
    'baseRevision',
  );
  @override
  late final GeneratedColumn<int> baseRevision = GeneratedColumn<int>(
    'base_revision',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dependsOnRankMeta = const VerificationMeta(
    'dependsOnRank',
  );
  @override
  late final GeneratedColumn<int> dependsOnRank = GeneratedColumn<int>(
    'depends_on_rank',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<int> lastAttemptAt = GeneratedColumn<int>(
    'last_attempt_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<int> nextAttemptAt = GeneratedColumn<int>(
    'next_attempt_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorCodeMeta = const VerificationMeta(
    'errorCode',
  );
  @override
  late final GeneratedColumn<String> errorCode = GeneratedColumn<String>(
    'error_code',
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
    opId,
    entityType,
    entityId,
    opType,
    payloadJson,
    baseRevision,
    dependsOnRank,
    status,
    attemptCount,
    lastAttemptAt,
    nextAttemptAt,
    errorCode,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncOutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('op_id')) {
      context.handle(
        _opIdMeta,
        opId.isAcceptableOrUnknown(data['op_id']!, _opIdMeta),
      );
    } else if (isInserting) {
      context.missing(_opIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('op_type')) {
      context.handle(
        _opTypeMeta,
        opType.isAcceptableOrUnknown(data['op_type']!, _opTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_opTypeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('base_revision')) {
      context.handle(
        _baseRevisionMeta,
        baseRevision.isAcceptableOrUnknown(
          data['base_revision']!,
          _baseRevisionMeta,
        ),
      );
    }
    if (data.containsKey('depends_on_rank')) {
      context.handle(
        _dependsOnRankMeta,
        dependsOnRank.isAcceptableOrUnknown(
          data['depends_on_rank']!,
          _dependsOnRankMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dependsOnRankMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('error_code')) {
      context.handle(
        _errorCodeMeta,
        errorCode.isAcceptableOrUnknown(data['error_code']!, _errorCodeMeta),
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
  Set<GeneratedColumn> get $primaryKey => {opId};
  @override
  SyncOutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOutboxRow(
      opId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      opType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op_type'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      baseRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_revision'],
      ),
      dependsOnRank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}depends_on_rank'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_attempt_at'],
      ),
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_attempt_at'],
      ),
      errorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_code'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SyncOutboxEntriesTable createAlias(String alias) {
    return $SyncOutboxEntriesTable(attachedDatabase, alias);
  }
}

class SyncOutboxRow extends DataClass implements Insertable<SyncOutboxRow> {
  /// UUID v4 generated at enqueue; the idempotency key sent to the server.
  final String opId;

  /// A `SyncEntityType.wire` value.
  final String entityType;
  final String entityId;

  /// `upsert` | `delete`.
  final String opType;

  /// The full record snapshot in the wire shape (contracts/sync-rpc.md §1).
  final String payloadJson;

  /// The server revision the change was made against; null = never synced.
  final int? baseRevision;

  /// `SyncEntityType.rank`: parents upload before children.
  final int dependsOnRank;
  final String status;
  final int attemptCount;
  final int? lastAttemptAt;

  /// Null = eligible now.
  final int? nextAttemptAt;

  /// A code only (e.g. `network`); never record contents.
  final String? errorCode;

  /// FIFO order within a rank.
  final int createdAt;
  const SyncOutboxRow({
    required this.opId,
    required this.entityType,
    required this.entityId,
    required this.opType,
    required this.payloadJson,
    this.baseRevision,
    required this.dependsOnRank,
    required this.status,
    required this.attemptCount,
    this.lastAttemptAt,
    this.nextAttemptAt,
    this.errorCode,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['op_id'] = Variable<String>(opId);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['op_type'] = Variable<String>(opType);
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || baseRevision != null) {
      map['base_revision'] = Variable<int>(baseRevision);
    }
    map['depends_on_rank'] = Variable<int>(dependsOnRank);
    map['status'] = Variable<String>(status);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<int>(lastAttemptAt);
    }
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<int>(nextAttemptAt);
    }
    if (!nullToAbsent || errorCode != null) {
      map['error_code'] = Variable<String>(errorCode);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  SyncOutboxEntriesCompanion toCompanion(bool nullToAbsent) {
    return SyncOutboxEntriesCompanion(
      opId: Value(opId),
      entityType: Value(entityType),
      entityId: Value(entityId),
      opType: Value(opType),
      payloadJson: Value(payloadJson),
      baseRevision: baseRevision == null && nullToAbsent
          ? const Value.absent()
          : Value(baseRevision),
      dependsOnRank: Value(dependsOnRank),
      status: Value(status),
      attemptCount: Value(attemptCount),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      errorCode: errorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(errorCode),
      createdAt: Value(createdAt),
    );
  }

  factory SyncOutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOutboxRow(
      opId: serializer.fromJson<String>(json['opId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      opType: serializer.fromJson<String>(json['opType']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      baseRevision: serializer.fromJson<int?>(json['baseRevision']),
      dependsOnRank: serializer.fromJson<int>(json['dependsOnRank']),
      status: serializer.fromJson<String>(json['status']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      lastAttemptAt: serializer.fromJson<int?>(json['lastAttemptAt']),
      nextAttemptAt: serializer.fromJson<int?>(json['nextAttemptAt']),
      errorCode: serializer.fromJson<String?>(json['errorCode']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'opId': serializer.toJson<String>(opId),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'opType': serializer.toJson<String>(opType),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'baseRevision': serializer.toJson<int?>(baseRevision),
      'dependsOnRank': serializer.toJson<int>(dependsOnRank),
      'status': serializer.toJson<String>(status),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'lastAttemptAt': serializer.toJson<int?>(lastAttemptAt),
      'nextAttemptAt': serializer.toJson<int?>(nextAttemptAt),
      'errorCode': serializer.toJson<String?>(errorCode),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  SyncOutboxRow copyWith({
    String? opId,
    String? entityType,
    String? entityId,
    String? opType,
    String? payloadJson,
    Value<int?> baseRevision = const Value.absent(),
    int? dependsOnRank,
    String? status,
    int? attemptCount,
    Value<int?> lastAttemptAt = const Value.absent(),
    Value<int?> nextAttemptAt = const Value.absent(),
    Value<String?> errorCode = const Value.absent(),
    int? createdAt,
  }) => SyncOutboxRow(
    opId: opId ?? this.opId,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    opType: opType ?? this.opType,
    payloadJson: payloadJson ?? this.payloadJson,
    baseRevision: baseRevision.present ? baseRevision.value : this.baseRevision,
    dependsOnRank: dependsOnRank ?? this.dependsOnRank,
    status: status ?? this.status,
    attemptCount: attemptCount ?? this.attemptCount,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    errorCode: errorCode.present ? errorCode.value : this.errorCode,
    createdAt: createdAt ?? this.createdAt,
  );
  SyncOutboxRow copyWithCompanion(SyncOutboxEntriesCompanion data) {
    return SyncOutboxRow(
      opId: data.opId.present ? data.opId.value : this.opId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      opType: data.opType.present ? data.opType.value : this.opType,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      baseRevision: data.baseRevision.present
          ? data.baseRevision.value
          : this.baseRevision,
      dependsOnRank: data.dependsOnRank.present
          ? data.dependsOnRank.value
          : this.dependsOnRank,
      status: data.status.present ? data.status.value : this.status,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      errorCode: data.errorCode.present ? data.errorCode.value : this.errorCode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxRow(')
          ..write('opId: $opId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('opType: $opType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('baseRevision: $baseRevision, ')
          ..write('dependsOnRank: $dependsOnRank, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('errorCode: $errorCode, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    opId,
    entityType,
    entityId,
    opType,
    payloadJson,
    baseRevision,
    dependsOnRank,
    status,
    attemptCount,
    lastAttemptAt,
    nextAttemptAt,
    errorCode,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOutboxRow &&
          other.opId == this.opId &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.opType == this.opType &&
          other.payloadJson == this.payloadJson &&
          other.baseRevision == this.baseRevision &&
          other.dependsOnRank == this.dependsOnRank &&
          other.status == this.status &&
          other.attemptCount == this.attemptCount &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.errorCode == this.errorCode &&
          other.createdAt == this.createdAt);
}

class SyncOutboxEntriesCompanion extends UpdateCompanion<SyncOutboxRow> {
  final Value<String> opId;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> opType;
  final Value<String> payloadJson;
  final Value<int?> baseRevision;
  final Value<int> dependsOnRank;
  final Value<String> status;
  final Value<int> attemptCount;
  final Value<int?> lastAttemptAt;
  final Value<int?> nextAttemptAt;
  final Value<String?> errorCode;
  final Value<int> createdAt;
  final Value<int> rowid;
  const SyncOutboxEntriesCompanion({
    this.opId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.opType = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.baseRevision = const Value.absent(),
    this.dependsOnRank = const Value.absent(),
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncOutboxEntriesCompanion.insert({
    required String opId,
    required String entityType,
    required String entityId,
    required String opType,
    required String payloadJson,
    this.baseRevision = const Value.absent(),
    required int dependsOnRank,
    required String status,
    this.attemptCount = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.errorCode = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : opId = Value(opId),
       entityType = Value(entityType),
       entityId = Value(entityId),
       opType = Value(opType),
       payloadJson = Value(payloadJson),
       dependsOnRank = Value(dependsOnRank),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<SyncOutboxRow> custom({
    Expression<String>? opId,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? opType,
    Expression<String>? payloadJson,
    Expression<int>? baseRevision,
    Expression<int>? dependsOnRank,
    Expression<String>? status,
    Expression<int>? attemptCount,
    Expression<int>? lastAttemptAt,
    Expression<int>? nextAttemptAt,
    Expression<String>? errorCode,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (opId != null) 'op_id': opId,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (opType != null) 'op_type': opType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (baseRevision != null) 'base_revision': baseRevision,
      if (dependsOnRank != null) 'depends_on_rank': dependsOnRank,
      if (status != null) 'status': status,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (errorCode != null) 'error_code': errorCode,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncOutboxEntriesCompanion copyWith({
    Value<String>? opId,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? opType,
    Value<String>? payloadJson,
    Value<int?>? baseRevision,
    Value<int>? dependsOnRank,
    Value<String>? status,
    Value<int>? attemptCount,
    Value<int?>? lastAttemptAt,
    Value<int?>? nextAttemptAt,
    Value<String?>? errorCode,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return SyncOutboxEntriesCompanion(
      opId: opId ?? this.opId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      opType: opType ?? this.opType,
      payloadJson: payloadJson ?? this.payloadJson,
      baseRevision: baseRevision ?? this.baseRevision,
      dependsOnRank: dependsOnRank ?? this.dependsOnRank,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      errorCode: errorCode ?? this.errorCode,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (opId.present) {
      map['op_id'] = Variable<String>(opId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (opType.present) {
      map['op_type'] = Variable<String>(opType.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (baseRevision.present) {
      map['base_revision'] = Variable<int>(baseRevision.value);
    }
    if (dependsOnRank.present) {
      map['depends_on_rank'] = Variable<int>(dependsOnRank.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<int>(lastAttemptAt.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<int>(nextAttemptAt.value);
    }
    if (errorCode.present) {
      map['error_code'] = Variable<String>(errorCode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxEntriesCompanion(')
          ..write('opId: $opId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('opType: $opType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('baseRevision: $baseRevision, ')
          ..write('dependsOnRank: $dependsOnRank, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('errorCode: $errorCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncRecordMetaTable extends SyncRecordMeta
    with TableInfo<$SyncRecordMetaTable, SyncRecordMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncRecordMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverRevisionMeta = const VerificationMeta(
    'serverRevision',
  );
  @override
  late final GeneratedColumn<int> serverRevision = GeneratedColumn<int>(
    'server_revision',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<int> lastSyncedAt = GeneratedColumn<int>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    entityType,
    entityId,
    serverRevision,
    state,
    lastSyncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_record_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncRecordMetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('server_revision')) {
      context.handle(
        _serverRevisionMeta,
        serverRevision.isAcceptableOrUnknown(
          data['server_revision']!,
          _serverRevisionMeta,
        ),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entityType, entityId};
  @override
  SyncRecordMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncRecordMetaRow(
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      serverRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_revision'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_synced_at'],
      ),
    );
  }

  @override
  $SyncRecordMetaTable createAlias(String alias) {
    return $SyncRecordMetaTable(attachedDatabase, alias);
  }
}

class SyncRecordMetaRow extends DataClass
    implements Insertable<SyncRecordMetaRow> {
  final String entityType;
  final String entityId;

  /// The last revision the server confirmed.
  final int? serverRevision;
  final String state;
  final int? lastSyncedAt;
  const SyncRecordMetaRow({
    required this.entityType,
    required this.entityId,
    this.serverRevision,
    required this.state,
    this.lastSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    if (!nullToAbsent || serverRevision != null) {
      map['server_revision'] = Variable<int>(serverRevision);
    }
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt);
    }
    return map;
  }

  SyncRecordMetaCompanion toCompanion(bool nullToAbsent) {
    return SyncRecordMetaCompanion(
      entityType: Value(entityType),
      entityId: Value(entityId),
      serverRevision: serverRevision == null && nullToAbsent
          ? const Value.absent()
          : Value(serverRevision),
      state: Value(state),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory SyncRecordMetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncRecordMetaRow(
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      serverRevision: serializer.fromJson<int?>(json['serverRevision']),
      state: serializer.fromJson<String>(json['state']),
      lastSyncedAt: serializer.fromJson<int?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'serverRevision': serializer.toJson<int?>(serverRevision),
      'state': serializer.toJson<String>(state),
      'lastSyncedAt': serializer.toJson<int?>(lastSyncedAt),
    };
  }

  SyncRecordMetaRow copyWith({
    String? entityType,
    String? entityId,
    Value<int?> serverRevision = const Value.absent(),
    String? state,
    Value<int?> lastSyncedAt = const Value.absent(),
  }) => SyncRecordMetaRow(
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    serverRevision: serverRevision.present
        ? serverRevision.value
        : this.serverRevision,
    state: state ?? this.state,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
  );
  SyncRecordMetaRow copyWithCompanion(SyncRecordMetaCompanion data) {
    return SyncRecordMetaRow(
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      serverRevision: data.serverRevision.present
          ? data.serverRevision.value
          : this.serverRevision,
      state: data.state.present ? data.state.value : this.state,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncRecordMetaRow(')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('serverRevision: $serverRevision, ')
          ..write('state: $state, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(entityType, entityId, serverRevision, state, lastSyncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncRecordMetaRow &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.serverRevision == this.serverRevision &&
          other.state == this.state &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class SyncRecordMetaCompanion extends UpdateCompanion<SyncRecordMetaRow> {
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<int?> serverRevision;
  final Value<String> state;
  final Value<int?> lastSyncedAt;
  final Value<int> rowid;
  const SyncRecordMetaCompanion({
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.serverRevision = const Value.absent(),
    this.state = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncRecordMetaCompanion.insert({
    required String entityType,
    required String entityId,
    this.serverRevision = const Value.absent(),
    required String state,
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : entityType = Value(entityType),
       entityId = Value(entityId),
       state = Value(state);
  static Insertable<SyncRecordMetaRow> custom({
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<int>? serverRevision,
    Expression<String>? state,
    Expression<int>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (serverRevision != null) 'server_revision': serverRevision,
      if (state != null) 'state': state,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncRecordMetaCompanion copyWith({
    Value<String>? entityType,
    Value<String>? entityId,
    Value<int?>? serverRevision,
    Value<String>? state,
    Value<int?>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return SyncRecordMetaCompanion(
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      serverRevision: serverRevision ?? this.serverRevision,
      state: state ?? this.state,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (serverRevision.present) {
      map['server_revision'] = Variable<int>(serverRevision.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncRecordMetaCompanion(')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('serverRevision: $serverRevision, ')
          ..write('state: $state, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncConflictsTable extends SyncConflicts
    with TableInfo<$SyncConflictsTable, SyncConflictRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncConflictsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPayloadJsonMeta = const VerificationMeta(
    'localPayloadJson',
  );
  @override
  late final GeneratedColumn<String> localPayloadJson = GeneratedColumn<String>(
    'local_payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverPayloadJsonMeta = const VerificationMeta(
    'serverPayloadJson',
  );
  @override
  late final GeneratedColumn<String> serverPayloadJson =
      GeneratedColumn<String>(
        'server_payload_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _serverRevisionMeta = const VerificationMeta(
    'serverRevision',
  );
  @override
  late final GeneratedColumn<int> serverRevision = GeneratedColumn<int>(
    'server_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detectedAtMeta = const VerificationMeta(
    'detectedAt',
  );
  @override
  late final GeneratedColumn<int> detectedAt = GeneratedColumn<int>(
    'detected_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  @override
  late final GeneratedColumn<int> resolvedAt = GeneratedColumn<int>(
    'resolved_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    entityId,
    localPayloadJson,
    serverPayloadJson,
    serverRevision,
    detectedAt,
    resolvedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_conflicts';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncConflictRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('local_payload_json')) {
      context.handle(
        _localPayloadJsonMeta,
        localPayloadJson.isAcceptableOrUnknown(
          data['local_payload_json']!,
          _localPayloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localPayloadJsonMeta);
    }
    if (data.containsKey('server_payload_json')) {
      context.handle(
        _serverPayloadJsonMeta,
        serverPayloadJson.isAcceptableOrUnknown(
          data['server_payload_json']!,
          _serverPayloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_serverPayloadJsonMeta);
    }
    if (data.containsKey('server_revision')) {
      context.handle(
        _serverRevisionMeta,
        serverRevision.isAcceptableOrUnknown(
          data['server_revision']!,
          _serverRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_serverRevisionMeta);
    }
    if (data.containsKey('detected_at')) {
      context.handle(
        _detectedAtMeta,
        detectedAt.isAcceptableOrUnknown(data['detected_at']!, _detectedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_detectedAtMeta);
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncConflictRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncConflictRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      localPayloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_payload_json'],
      )!,
      serverPayloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_payload_json'],
      )!,
      serverRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_revision'],
      )!,
      detectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}detected_at'],
      )!,
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resolved_at'],
      ),
    );
  }

  @override
  $SyncConflictsTable createAlias(String alias) {
    return $SyncConflictsTable(attachedDatabase, alias);
  }
}

class SyncConflictRow extends DataClass implements Insertable<SyncConflictRow> {
  final String id;
  final String entityType;
  final String entityId;

  /// The local version the user edited.
  final String localPayloadJson;

  /// The server row returned by `sync_push`.
  final String serverPayloadJson;

  /// The base revision to use for "keep mine".
  final int serverRevision;
  final int detectedAt;
  final int? resolvedAt;
  const SyncConflictRow({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.localPayloadJson,
    required this.serverPayloadJson,
    required this.serverRevision,
    required this.detectedAt,
    this.resolvedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['local_payload_json'] = Variable<String>(localPayloadJson);
    map['server_payload_json'] = Variable<String>(serverPayloadJson);
    map['server_revision'] = Variable<int>(serverRevision);
    map['detected_at'] = Variable<int>(detectedAt);
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<int>(resolvedAt);
    }
    return map;
  }

  SyncConflictsCompanion toCompanion(bool nullToAbsent) {
    return SyncConflictsCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      localPayloadJson: Value(localPayloadJson),
      serverPayloadJson: Value(serverPayloadJson),
      serverRevision: Value(serverRevision),
      detectedAt: Value(detectedAt),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
    );
  }

  factory SyncConflictRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncConflictRow(
      id: serializer.fromJson<String>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      localPayloadJson: serializer.fromJson<String>(json['localPayloadJson']),
      serverPayloadJson: serializer.fromJson<String>(json['serverPayloadJson']),
      serverRevision: serializer.fromJson<int>(json['serverRevision']),
      detectedAt: serializer.fromJson<int>(json['detectedAt']),
      resolvedAt: serializer.fromJson<int?>(json['resolvedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'localPayloadJson': serializer.toJson<String>(localPayloadJson),
      'serverPayloadJson': serializer.toJson<String>(serverPayloadJson),
      'serverRevision': serializer.toJson<int>(serverRevision),
      'detectedAt': serializer.toJson<int>(detectedAt),
      'resolvedAt': serializer.toJson<int?>(resolvedAt),
    };
  }

  SyncConflictRow copyWith({
    String? id,
    String? entityType,
    String? entityId,
    String? localPayloadJson,
    String? serverPayloadJson,
    int? serverRevision,
    int? detectedAt,
    Value<int?> resolvedAt = const Value.absent(),
  }) => SyncConflictRow(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    localPayloadJson: localPayloadJson ?? this.localPayloadJson,
    serverPayloadJson: serverPayloadJson ?? this.serverPayloadJson,
    serverRevision: serverRevision ?? this.serverRevision,
    detectedAt: detectedAt ?? this.detectedAt,
    resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
  );
  SyncConflictRow copyWithCompanion(SyncConflictsCompanion data) {
    return SyncConflictRow(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      localPayloadJson: data.localPayloadJson.present
          ? data.localPayloadJson.value
          : this.localPayloadJson,
      serverPayloadJson: data.serverPayloadJson.present
          ? data.serverPayloadJson.value
          : this.serverPayloadJson,
      serverRevision: data.serverRevision.present
          ? data.serverRevision.value
          : this.serverRevision,
      detectedAt: data.detectedAt.present
          ? data.detectedAt.value
          : this.detectedAt,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncConflictRow(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('localPayloadJson: $localPayloadJson, ')
          ..write('serverPayloadJson: $serverPayloadJson, ')
          ..write('serverRevision: $serverRevision, ')
          ..write('detectedAt: $detectedAt, ')
          ..write('resolvedAt: $resolvedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entityId,
    localPayloadJson,
    serverPayloadJson,
    serverRevision,
    detectedAt,
    resolvedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncConflictRow &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.localPayloadJson == this.localPayloadJson &&
          other.serverPayloadJson == this.serverPayloadJson &&
          other.serverRevision == this.serverRevision &&
          other.detectedAt == this.detectedAt &&
          other.resolvedAt == this.resolvedAt);
}

class SyncConflictsCompanion extends UpdateCompanion<SyncConflictRow> {
  final Value<String> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> localPayloadJson;
  final Value<String> serverPayloadJson;
  final Value<int> serverRevision;
  final Value<int> detectedAt;
  final Value<int?> resolvedAt;
  final Value<int> rowid;
  const SyncConflictsCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.localPayloadJson = const Value.absent(),
    this.serverPayloadJson = const Value.absent(),
    this.serverRevision = const Value.absent(),
    this.detectedAt = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncConflictsCompanion.insert({
    required String id,
    required String entityType,
    required String entityId,
    required String localPayloadJson,
    required String serverPayloadJson,
    required int serverRevision,
    required int detectedAt,
    this.resolvedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityType = Value(entityType),
       entityId = Value(entityId),
       localPayloadJson = Value(localPayloadJson),
       serverPayloadJson = Value(serverPayloadJson),
       serverRevision = Value(serverRevision),
       detectedAt = Value(detectedAt);
  static Insertable<SyncConflictRow> custom({
    Expression<String>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? localPayloadJson,
    Expression<String>? serverPayloadJson,
    Expression<int>? serverRevision,
    Expression<int>? detectedAt,
    Expression<int>? resolvedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (localPayloadJson != null) 'local_payload_json': localPayloadJson,
      if (serverPayloadJson != null) 'server_payload_json': serverPayloadJson,
      if (serverRevision != null) 'server_revision': serverRevision,
      if (detectedAt != null) 'detected_at': detectedAt,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncConflictsCompanion copyWith({
    Value<String>? id,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? localPayloadJson,
    Value<String>? serverPayloadJson,
    Value<int>? serverRevision,
    Value<int>? detectedAt,
    Value<int?>? resolvedAt,
    Value<int>? rowid,
  }) {
    return SyncConflictsCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      localPayloadJson: localPayloadJson ?? this.localPayloadJson,
      serverPayloadJson: serverPayloadJson ?? this.serverPayloadJson,
      serverRevision: serverRevision ?? this.serverRevision,
      detectedAt: detectedAt ?? this.detectedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (localPayloadJson.present) {
      map['local_payload_json'] = Variable<String>(localPayloadJson.value);
    }
    if (serverPayloadJson.present) {
      map['server_payload_json'] = Variable<String>(serverPayloadJson.value);
    }
    if (serverRevision.present) {
      map['server_revision'] = Variable<int>(serverRevision.value);
    }
    if (detectedAt.present) {
      map['detected_at'] = Variable<int>(detectedAt.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<int>(resolvedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncConflictsCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('localPayloadJson: $localPayloadJson, ')
          ..write('serverPayloadJson: $serverPayloadJson, ')
          ..write('serverRevision: $serverRevision, ')
          ..write('detectedAt: $detectedAt, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConflictResolutionsTable extends ConflictResolutions
    with TableInfo<$ConflictResolutionsTable, ConflictResolutionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConflictResolutionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chosenSideMeta = const VerificationMeta(
    'chosenSide',
  );
  @override
  late final GeneratedColumn<String> chosenSide = GeneratedColumn<String>(
    'chosen_side',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discardedValuesJsonMeta =
      const VerificationMeta('discardedValuesJson');
  @override
  late final GeneratedColumn<String> discardedValuesJson =
      GeneratedColumn<String>(
        'discarded_values_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  @override
  late final GeneratedColumn<int> resolvedAt = GeneratedColumn<int>(
    'resolved_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    entityId,
    chosenSide,
    discardedValuesJson,
    resolvedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conflict_resolutions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConflictResolutionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('chosen_side')) {
      context.handle(
        _chosenSideMeta,
        chosenSide.isAcceptableOrUnknown(data['chosen_side']!, _chosenSideMeta),
      );
    } else if (isInserting) {
      context.missing(_chosenSideMeta);
    }
    if (data.containsKey('discarded_values_json')) {
      context.handle(
        _discardedValuesJsonMeta,
        discardedValuesJson.isAcceptableOrUnknown(
          data['discarded_values_json']!,
          _discardedValuesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_discardedValuesJsonMeta);
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_resolvedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConflictResolutionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConflictResolutionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      chosenSide: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chosen_side'],
      )!,
      discardedValuesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discarded_values_json'],
      )!,
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resolved_at'],
      )!,
    );
  }

  @override
  $ConflictResolutionsTable createAlias(String alias) {
    return $ConflictResolutionsTable(attachedDatabase, alias);
  }
}

class ConflictResolutionRow extends DataClass
    implements Insertable<ConflictResolutionRow> {
  final String id;

  /// `money_transaction` | `finance_entry`.
  final String entityType;
  final String entityId;

  /// `local` | `server`.
  final String chosenSide;
  final String discardedValuesJson;
  final int resolvedAt;
  const ConflictResolutionRow({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.chosenSide,
    required this.discardedValuesJson,
    required this.resolvedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['chosen_side'] = Variable<String>(chosenSide);
    map['discarded_values_json'] = Variable<String>(discardedValuesJson);
    map['resolved_at'] = Variable<int>(resolvedAt);
    return map;
  }

  ConflictResolutionsCompanion toCompanion(bool nullToAbsent) {
    return ConflictResolutionsCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      chosenSide: Value(chosenSide),
      discardedValuesJson: Value(discardedValuesJson),
      resolvedAt: Value(resolvedAt),
    );
  }

  factory ConflictResolutionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConflictResolutionRow(
      id: serializer.fromJson<String>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      chosenSide: serializer.fromJson<String>(json['chosenSide']),
      discardedValuesJson: serializer.fromJson<String>(
        json['discardedValuesJson'],
      ),
      resolvedAt: serializer.fromJson<int>(json['resolvedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'chosenSide': serializer.toJson<String>(chosenSide),
      'discardedValuesJson': serializer.toJson<String>(discardedValuesJson),
      'resolvedAt': serializer.toJson<int>(resolvedAt),
    };
  }

  ConflictResolutionRow copyWith({
    String? id,
    String? entityType,
    String? entityId,
    String? chosenSide,
    String? discardedValuesJson,
    int? resolvedAt,
  }) => ConflictResolutionRow(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    chosenSide: chosenSide ?? this.chosenSide,
    discardedValuesJson: discardedValuesJson ?? this.discardedValuesJson,
    resolvedAt: resolvedAt ?? this.resolvedAt,
  );
  ConflictResolutionRow copyWithCompanion(ConflictResolutionsCompanion data) {
    return ConflictResolutionRow(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      chosenSide: data.chosenSide.present
          ? data.chosenSide.value
          : this.chosenSide,
      discardedValuesJson: data.discardedValuesJson.present
          ? data.discardedValuesJson.value
          : this.discardedValuesJson,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConflictResolutionRow(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('chosenSide: $chosenSide, ')
          ..write('discardedValuesJson: $discardedValuesJson, ')
          ..write('resolvedAt: $resolvedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entityId,
    chosenSide,
    discardedValuesJson,
    resolvedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConflictResolutionRow &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.chosenSide == this.chosenSide &&
          other.discardedValuesJson == this.discardedValuesJson &&
          other.resolvedAt == this.resolvedAt);
}

class ConflictResolutionsCompanion
    extends UpdateCompanion<ConflictResolutionRow> {
  final Value<String> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> chosenSide;
  final Value<String> discardedValuesJson;
  final Value<int> resolvedAt;
  final Value<int> rowid;
  const ConflictResolutionsCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.chosenSide = const Value.absent(),
    this.discardedValuesJson = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConflictResolutionsCompanion.insert({
    required String id,
    required String entityType,
    required String entityId,
    required String chosenSide,
    required String discardedValuesJson,
    required int resolvedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityType = Value(entityType),
       entityId = Value(entityId),
       chosenSide = Value(chosenSide),
       discardedValuesJson = Value(discardedValuesJson),
       resolvedAt = Value(resolvedAt);
  static Insertable<ConflictResolutionRow> custom({
    Expression<String>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? chosenSide,
    Expression<String>? discardedValuesJson,
    Expression<int>? resolvedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (chosenSide != null) 'chosen_side': chosenSide,
      if (discardedValuesJson != null)
        'discarded_values_json': discardedValuesJson,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConflictResolutionsCompanion copyWith({
    Value<String>? id,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? chosenSide,
    Value<String>? discardedValuesJson,
    Value<int>? resolvedAt,
    Value<int>? rowid,
  }) {
    return ConflictResolutionsCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      chosenSide: chosenSide ?? this.chosenSide,
      discardedValuesJson: discardedValuesJson ?? this.discardedValuesJson,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (chosenSide.present) {
      map['chosen_side'] = Variable<String>(chosenSide.value);
    }
    if (discardedValuesJson.present) {
      map['discarded_values_json'] = Variable<String>(
        discardedValuesJson.value,
      );
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<int>(resolvedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConflictResolutionsCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('chosenSide: $chosenSide, ')
          ..write('discardedValuesJson: $discardedValuesJson, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _noticeShownMeta = const VerificationMeta(
    'noticeShown',
  );
  @override
  late final GeneratedColumn<bool> noticeShown = GeneratedColumn<bool>(
    'notice_shown',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notice_shown" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastPulledRevisionMeta =
      const VerificationMeta('lastPulledRevision');
  @override
  late final GeneratedColumn<int> lastPulledRevision = GeneratedColumn<int>(
    'last_pulled_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _bootstrapEnqueuedMeta = const VerificationMeta(
    'bootstrapEnqueued',
  );
  @override
  late final GeneratedColumn<bool> bootstrapEnqueued = GeneratedColumn<bool>(
    'bootstrap_enqueued',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("bootstrap_enqueued" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _initialUploadDoneMeta = const VerificationMeta(
    'initialUploadDone',
  );
  @override
  late final GeneratedColumn<bool> initialUploadDone = GeneratedColumn<bool>(
    'initial_upload_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("initial_upload_done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _b1RepullDoneMeta = const VerificationMeta(
    'b1RepullDone',
  );
  @override
  late final GeneratedColumn<bool> b1RepullDone = GeneratedColumn<bool>(
    'b1_repull_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("b1_repull_done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<int> lastAttemptAt = GeneratedColumn<int>(
    'last_attempt_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSuccessAtMeta = const VerificationMeta(
    'lastSuccessAt',
  );
  @override
  late final GeneratedColumn<int> lastSuccessAt = GeneratedColumn<int>(
    'last_success_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _consecutiveFailuresMeta =
      const VerificationMeta('consecutiveFailures');
  @override
  late final GeneratedColumn<int> consecutiveFailures = GeneratedColumn<int>(
    'consecutive_failures',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorCodeMeta = const VerificationMeta(
    'lastErrorCode',
  );
  @override
  late final GeneratedColumn<String> lastErrorCode = GeneratedColumn<String>(
    'last_error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    enabled,
    noticeShown,
    ownerId,
    deviceId,
    lastPulledRevision,
    bootstrapEnqueued,
    initialUploadDone,
    b1RepullDone,
    lastAttemptAt,
    lastSuccessAt,
    consecutiveFailures,
    lastErrorCode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('notice_shown')) {
      context.handle(
        _noticeShownMeta,
        noticeShown.isAcceptableOrUnknown(
          data['notice_shown']!,
          _noticeShownMeta,
        ),
      );
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('last_pulled_revision')) {
      context.handle(
        _lastPulledRevisionMeta,
        lastPulledRevision.isAcceptableOrUnknown(
          data['last_pulled_revision']!,
          _lastPulledRevisionMeta,
        ),
      );
    }
    if (data.containsKey('bootstrap_enqueued')) {
      context.handle(
        _bootstrapEnqueuedMeta,
        bootstrapEnqueued.isAcceptableOrUnknown(
          data['bootstrap_enqueued']!,
          _bootstrapEnqueuedMeta,
        ),
      );
    }
    if (data.containsKey('initial_upload_done')) {
      context.handle(
        _initialUploadDoneMeta,
        initialUploadDone.isAcceptableOrUnknown(
          data['initial_upload_done']!,
          _initialUploadDoneMeta,
        ),
      );
    }
    if (data.containsKey('b1_repull_done')) {
      context.handle(
        _b1RepullDoneMeta,
        b1RepullDone.isAcceptableOrUnknown(
          data['b1_repull_done']!,
          _b1RepullDoneMeta,
        ),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_success_at')) {
      context.handle(
        _lastSuccessAtMeta,
        lastSuccessAt.isAcceptableOrUnknown(
          data['last_success_at']!,
          _lastSuccessAtMeta,
        ),
      );
    }
    if (data.containsKey('consecutive_failures')) {
      context.handle(
        _consecutiveFailuresMeta,
        consecutiveFailures.isAcceptableOrUnknown(
          data['consecutive_failures']!,
          _consecutiveFailuresMeta,
        ),
      );
    }
    if (data.containsKey('last_error_code')) {
      context.handle(
        _lastErrorCodeMeta,
        lastErrorCode.isAcceptableOrUnknown(
          data['last_error_code']!,
          _lastErrorCodeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      noticeShown: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notice_shown'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      lastPulledRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_pulled_revision'],
      )!,
      bootstrapEnqueued: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}bootstrap_enqueued'],
      )!,
      initialUploadDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}initial_upload_done'],
      )!,
      b1RepullDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}b1_repull_done'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_attempt_at'],
      ),
      lastSuccessAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_success_at'],
      ),
      consecutiveFailures: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}consecutive_failures'],
      )!,
      lastErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_code'],
      ),
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateRow extends DataClass implements Insertable<SyncStateRow> {
  final String id;

  /// FR-041: sync is on by default.
  final bool enabled;

  /// Whether the one-time sync notice has been shown (Q2).
  final bool noticeShown;

  /// The `auth.uid()` the download cursor belongs to; null = adopt the first.
  final String? ownerId;

  /// A UUID generated on first run.
  final String deviceId;

  /// The single download cursor.
  final int lastPulledRevision;

  /// Set in the same transaction that enqueues the pre-existing data; the
  /// only guard against a second bootstrap (data-model.md §3).
  final bool bootstrapEnqueued;
  final bool initialUploadDone;

  /// 022 B1 repair (research R7): set, together with a reset of
  /// [lastPulledRevision] to 0, the first time the fixed app syncs, so every
  /// server row is re-applied once through the corrected date mapping.
  final bool b1RepullDone;
  final int? lastAttemptAt;
  final int? lastSuccessAt;

  /// Drives backoff; persists across triggers.
  final int consecutiveFailures;
  final String? lastErrorCode;
  const SyncStateRow({
    required this.id,
    required this.enabled,
    required this.noticeShown,
    this.ownerId,
    required this.deviceId,
    required this.lastPulledRevision,
    required this.bootstrapEnqueued,
    required this.initialUploadDone,
    required this.b1RepullDone,
    this.lastAttemptAt,
    this.lastSuccessAt,
    required this.consecutiveFailures,
    this.lastErrorCode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['enabled'] = Variable<bool>(enabled);
    map['notice_shown'] = Variable<bool>(noticeShown);
    if (!nullToAbsent || ownerId != null) {
      map['owner_id'] = Variable<String>(ownerId);
    }
    map['device_id'] = Variable<String>(deviceId);
    map['last_pulled_revision'] = Variable<int>(lastPulledRevision);
    map['bootstrap_enqueued'] = Variable<bool>(bootstrapEnqueued);
    map['initial_upload_done'] = Variable<bool>(initialUploadDone);
    map['b1_repull_done'] = Variable<bool>(b1RepullDone);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<int>(lastAttemptAt);
    }
    if (!nullToAbsent || lastSuccessAt != null) {
      map['last_success_at'] = Variable<int>(lastSuccessAt);
    }
    map['consecutive_failures'] = Variable<int>(consecutiveFailures);
    if (!nullToAbsent || lastErrorCode != null) {
      map['last_error_code'] = Variable<String>(lastErrorCode);
    }
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(
      id: Value(id),
      enabled: Value(enabled),
      noticeShown: Value(noticeShown),
      ownerId: ownerId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerId),
      deviceId: Value(deviceId),
      lastPulledRevision: Value(lastPulledRevision),
      bootstrapEnqueued: Value(bootstrapEnqueued),
      initialUploadDone: Value(initialUploadDone),
      b1RepullDone: Value(b1RepullDone),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      lastSuccessAt: lastSuccessAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSuccessAt),
      consecutiveFailures: Value(consecutiveFailures),
      lastErrorCode: lastErrorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorCode),
    );
  }

  factory SyncStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateRow(
      id: serializer.fromJson<String>(json['id']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      noticeShown: serializer.fromJson<bool>(json['noticeShown']),
      ownerId: serializer.fromJson<String?>(json['ownerId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      lastPulledRevision: serializer.fromJson<int>(json['lastPulledRevision']),
      bootstrapEnqueued: serializer.fromJson<bool>(json['bootstrapEnqueued']),
      initialUploadDone: serializer.fromJson<bool>(json['initialUploadDone']),
      b1RepullDone: serializer.fromJson<bool>(json['b1RepullDone']),
      lastAttemptAt: serializer.fromJson<int?>(json['lastAttemptAt']),
      lastSuccessAt: serializer.fromJson<int?>(json['lastSuccessAt']),
      consecutiveFailures: serializer.fromJson<int>(
        json['consecutiveFailures'],
      ),
      lastErrorCode: serializer.fromJson<String?>(json['lastErrorCode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'enabled': serializer.toJson<bool>(enabled),
      'noticeShown': serializer.toJson<bool>(noticeShown),
      'ownerId': serializer.toJson<String?>(ownerId),
      'deviceId': serializer.toJson<String>(deviceId),
      'lastPulledRevision': serializer.toJson<int>(lastPulledRevision),
      'bootstrapEnqueued': serializer.toJson<bool>(bootstrapEnqueued),
      'initialUploadDone': serializer.toJson<bool>(initialUploadDone),
      'b1RepullDone': serializer.toJson<bool>(b1RepullDone),
      'lastAttemptAt': serializer.toJson<int?>(lastAttemptAt),
      'lastSuccessAt': serializer.toJson<int?>(lastSuccessAt),
      'consecutiveFailures': serializer.toJson<int>(consecutiveFailures),
      'lastErrorCode': serializer.toJson<String?>(lastErrorCode),
    };
  }

  SyncStateRow copyWith({
    String? id,
    bool? enabled,
    bool? noticeShown,
    Value<String?> ownerId = const Value.absent(),
    String? deviceId,
    int? lastPulledRevision,
    bool? bootstrapEnqueued,
    bool? initialUploadDone,
    bool? b1RepullDone,
    Value<int?> lastAttemptAt = const Value.absent(),
    Value<int?> lastSuccessAt = const Value.absent(),
    int? consecutiveFailures,
    Value<String?> lastErrorCode = const Value.absent(),
  }) => SyncStateRow(
    id: id ?? this.id,
    enabled: enabled ?? this.enabled,
    noticeShown: noticeShown ?? this.noticeShown,
    ownerId: ownerId.present ? ownerId.value : this.ownerId,
    deviceId: deviceId ?? this.deviceId,
    lastPulledRevision: lastPulledRevision ?? this.lastPulledRevision,
    bootstrapEnqueued: bootstrapEnqueued ?? this.bootstrapEnqueued,
    initialUploadDone: initialUploadDone ?? this.initialUploadDone,
    b1RepullDone: b1RepullDone ?? this.b1RepullDone,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    lastSuccessAt: lastSuccessAt.present
        ? lastSuccessAt.value
        : this.lastSuccessAt,
    consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
    lastErrorCode: lastErrorCode.present
        ? lastErrorCode.value
        : this.lastErrorCode,
  );
  SyncStateRow copyWithCompanion(SyncStateCompanion data) {
    return SyncStateRow(
      id: data.id.present ? data.id.value : this.id,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      noticeShown: data.noticeShown.present
          ? data.noticeShown.value
          : this.noticeShown,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      lastPulledRevision: data.lastPulledRevision.present
          ? data.lastPulledRevision.value
          : this.lastPulledRevision,
      bootstrapEnqueued: data.bootstrapEnqueued.present
          ? data.bootstrapEnqueued.value
          : this.bootstrapEnqueued,
      initialUploadDone: data.initialUploadDone.present
          ? data.initialUploadDone.value
          : this.initialUploadDone,
      b1RepullDone: data.b1RepullDone.present
          ? data.b1RepullDone.value
          : this.b1RepullDone,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      lastSuccessAt: data.lastSuccessAt.present
          ? data.lastSuccessAt.value
          : this.lastSuccessAt,
      consecutiveFailures: data.consecutiveFailures.present
          ? data.consecutiveFailures.value
          : this.consecutiveFailures,
      lastErrorCode: data.lastErrorCode.present
          ? data.lastErrorCode.value
          : this.lastErrorCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateRow(')
          ..write('id: $id, ')
          ..write('enabled: $enabled, ')
          ..write('noticeShown: $noticeShown, ')
          ..write('ownerId: $ownerId, ')
          ..write('deviceId: $deviceId, ')
          ..write('lastPulledRevision: $lastPulledRevision, ')
          ..write('bootstrapEnqueued: $bootstrapEnqueued, ')
          ..write('initialUploadDone: $initialUploadDone, ')
          ..write('b1RepullDone: $b1RepullDone, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastSuccessAt: $lastSuccessAt, ')
          ..write('consecutiveFailures: $consecutiveFailures, ')
          ..write('lastErrorCode: $lastErrorCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    enabled,
    noticeShown,
    ownerId,
    deviceId,
    lastPulledRevision,
    bootstrapEnqueued,
    initialUploadDone,
    b1RepullDone,
    lastAttemptAt,
    lastSuccessAt,
    consecutiveFailures,
    lastErrorCode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateRow &&
          other.id == this.id &&
          other.enabled == this.enabled &&
          other.noticeShown == this.noticeShown &&
          other.ownerId == this.ownerId &&
          other.deviceId == this.deviceId &&
          other.lastPulledRevision == this.lastPulledRevision &&
          other.bootstrapEnqueued == this.bootstrapEnqueued &&
          other.initialUploadDone == this.initialUploadDone &&
          other.b1RepullDone == this.b1RepullDone &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.lastSuccessAt == this.lastSuccessAt &&
          other.consecutiveFailures == this.consecutiveFailures &&
          other.lastErrorCode == this.lastErrorCode);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateRow> {
  final Value<String> id;
  final Value<bool> enabled;
  final Value<bool> noticeShown;
  final Value<String?> ownerId;
  final Value<String> deviceId;
  final Value<int> lastPulledRevision;
  final Value<bool> bootstrapEnqueued;
  final Value<bool> initialUploadDone;
  final Value<bool> b1RepullDone;
  final Value<int?> lastAttemptAt;
  final Value<int?> lastSuccessAt;
  final Value<int> consecutiveFailures;
  final Value<String?> lastErrorCode;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.id = const Value.absent(),
    this.enabled = const Value.absent(),
    this.noticeShown = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.lastPulledRevision = const Value.absent(),
    this.bootstrapEnqueued = const Value.absent(),
    this.initialUploadDone = const Value.absent(),
    this.b1RepullDone = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.lastSuccessAt = const Value.absent(),
    this.consecutiveFailures = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    required String id,
    this.enabled = const Value.absent(),
    this.noticeShown = const Value.absent(),
    this.ownerId = const Value.absent(),
    required String deviceId,
    this.lastPulledRevision = const Value.absent(),
    this.bootstrapEnqueued = const Value.absent(),
    this.initialUploadDone = const Value.absent(),
    this.b1RepullDone = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.lastSuccessAt = const Value.absent(),
    this.consecutiveFailures = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       deviceId = Value(deviceId);
  static Insertable<SyncStateRow> custom({
    Expression<String>? id,
    Expression<bool>? enabled,
    Expression<bool>? noticeShown,
    Expression<String>? ownerId,
    Expression<String>? deviceId,
    Expression<int>? lastPulledRevision,
    Expression<bool>? bootstrapEnqueued,
    Expression<bool>? initialUploadDone,
    Expression<bool>? b1RepullDone,
    Expression<int>? lastAttemptAt,
    Expression<int>? lastSuccessAt,
    Expression<int>? consecutiveFailures,
    Expression<String>? lastErrorCode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (enabled != null) 'enabled': enabled,
      if (noticeShown != null) 'notice_shown': noticeShown,
      if (ownerId != null) 'owner_id': ownerId,
      if (deviceId != null) 'device_id': deviceId,
      if (lastPulledRevision != null)
        'last_pulled_revision': lastPulledRevision,
      if (bootstrapEnqueued != null) 'bootstrap_enqueued': bootstrapEnqueued,
      if (initialUploadDone != null) 'initial_upload_done': initialUploadDone,
      if (b1RepullDone != null) 'b1_repull_done': b1RepullDone,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (lastSuccessAt != null) 'last_success_at': lastSuccessAt,
      if (consecutiveFailures != null)
        'consecutive_failures': consecutiveFailures,
      if (lastErrorCode != null) 'last_error_code': lastErrorCode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateCompanion copyWith({
    Value<String>? id,
    Value<bool>? enabled,
    Value<bool>? noticeShown,
    Value<String?>? ownerId,
    Value<String>? deviceId,
    Value<int>? lastPulledRevision,
    Value<bool>? bootstrapEnqueued,
    Value<bool>? initialUploadDone,
    Value<bool>? b1RepullDone,
    Value<int?>? lastAttemptAt,
    Value<int?>? lastSuccessAt,
    Value<int>? consecutiveFailures,
    Value<String?>? lastErrorCode,
    Value<int>? rowid,
  }) {
    return SyncStateCompanion(
      id: id ?? this.id,
      enabled: enabled ?? this.enabled,
      noticeShown: noticeShown ?? this.noticeShown,
      ownerId: ownerId ?? this.ownerId,
      deviceId: deviceId ?? this.deviceId,
      lastPulledRevision: lastPulledRevision ?? this.lastPulledRevision,
      bootstrapEnqueued: bootstrapEnqueued ?? this.bootstrapEnqueued,
      initialUploadDone: initialUploadDone ?? this.initialUploadDone,
      b1RepullDone: b1RepullDone ?? this.b1RepullDone,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (noticeShown.present) {
      map['notice_shown'] = Variable<bool>(noticeShown.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (lastPulledRevision.present) {
      map['last_pulled_revision'] = Variable<int>(lastPulledRevision.value);
    }
    if (bootstrapEnqueued.present) {
      map['bootstrap_enqueued'] = Variable<bool>(bootstrapEnqueued.value);
    }
    if (initialUploadDone.present) {
      map['initial_upload_done'] = Variable<bool>(initialUploadDone.value);
    }
    if (b1RepullDone.present) {
      map['b1_repull_done'] = Variable<bool>(b1RepullDone.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<int>(lastAttemptAt.value);
    }
    if (lastSuccessAt.present) {
      map['last_success_at'] = Variable<int>(lastSuccessAt.value);
    }
    if (consecutiveFailures.present) {
      map['consecutive_failures'] = Variable<int>(consecutiveFailures.value);
    }
    if (lastErrorCode.present) {
      map['last_error_code'] = Variable<String>(lastErrorCode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('id: $id, ')
          ..write('enabled: $enabled, ')
          ..write('noticeShown: $noticeShown, ')
          ..write('ownerId: $ownerId, ')
          ..write('deviceId: $deviceId, ')
          ..write('lastPulledRevision: $lastPulledRevision, ')
          ..write('bootstrapEnqueued: $bootstrapEnqueued, ')
          ..write('initialUploadDone: $initialUploadDone, ')
          ..write('b1RepullDone: $b1RepullDone, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastSuccessAt: $lastSuccessAt, ')
          ..write('consecutiveFailures: $consecutiveFailures, ')
          ..write('lastErrorCode: $lastErrorCode, ')
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
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('EGP'),
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
    currencyCode,
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
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
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
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
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

  /// 018: the ISO 4217 code every amount read off this page is recorded in
  /// — the primary currency when the scan started, so review and confirm
  /// agree even if the primary currency changes in between.
  final String currencyCode;
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
    required this.currencyCode,
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
    map['currency_code'] = Variable<String>(currencyCode);
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
      currencyCode: Value(currencyCode),
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
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
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
      'currencyCode': serializer.toJson<String>(currencyCode),
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
    String? currencyCode,
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
    currencyCode: currencyCode ?? this.currencyCode,
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
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
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
          ..write('currencyCode: $currencyCode, ')
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
    currencyCode,
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
          other.currencyCode == this.currencyCode &&
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
  final Value<String> currencyCode;
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
    this.currencyCode = const Value.absent(),
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
    this.currencyCode = const Value.absent(),
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
    Expression<String>? currencyCode,
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
      if (currencyCode != null) 'currency_code': currencyCode,
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
    Value<String>? currencyCode,
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
      currencyCode: currencyCode ?? this.currencyCode,
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
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
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
          ..write('currencyCode: $currencyCode, ')
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
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('EGP'),
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
    currencyCode,
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
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
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
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
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

  /// 018: the ISO 4217 code every planned figure of this budget (and its
  /// allocations) is in — the primary currency when the budget was
  /// created, so switching the primary currency later never reinterprets a
  /// plan. Actual spend is converted into it at read time.
  final String currencyCode;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const Budget({
    required this.id,
    required this.idempotencyKey,
    required this.month,
    this.expectedIncomeMinorUnits,
    required this.currencyCode,
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
    map['currency_code'] = Variable<String>(currencyCode);
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
      currencyCode: Value(currencyCode),
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
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
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
      'currencyCode': serializer.toJson<String>(currencyCode),
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
    String? currencyCode,
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
    currencyCode: currencyCode ?? this.currencyCode,
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
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
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
          ..write('currencyCode: $currencyCode, ')
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
    currencyCode,
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
          other.currencyCode == this.currencyCode &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class BudgetsCompanion extends UpdateCompanion<Budget> {
  final Value<String> id;
  final Value<String> idempotencyKey;
  final Value<String> month;
  final Value<int?> expectedIncomeMinorUnits;
  final Value<String> currencyCode;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const BudgetsCompanion({
    this.id = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.month = const Value.absent(),
    this.expectedIncomeMinorUnits = const Value.absent(),
    this.currencyCode = const Value.absent(),
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
    this.currencyCode = const Value.absent(),
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
    Expression<String>? currencyCode,
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
      if (currencyCode != null) 'currency_code': currencyCode,
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
    Value<String>? currencyCode,
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
      currencyCode: currencyCode ?? this.currencyCode,
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
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
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
          ..write('currencyCode: $currencyCode, ')
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

class $AiConversationsTable extends AiConversations
    with TableInfo<$AiConversationsTable, AiConversationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _lastActivityAtMeta = const VerificationMeta(
    'lastActivityAt',
  );
  @override
  late final GeneratedColumn<int> lastActivityAt = GeneratedColumn<int>(
    'last_activity_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, createdAt, lastActivityAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_conversations';
  @override
  VerificationContext validateIntegrity(
    Insertable<AiConversationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_activity_at')) {
      context.handle(
        _lastActivityAtMeta,
        lastActivityAt.isAcceptableOrUnknown(
          data['last_activity_at']!,
          _lastActivityAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastActivityAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AiConversationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiConversationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      lastActivityAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_activity_at'],
      )!,
    );
  }

  @override
  $AiConversationsTable createAlias(String alias) {
    return $AiConversationsTable(attachedDatabase, alias);
  }
}

class AiConversationRow extends DataClass
    implements Insertable<AiConversationRow> {
  final String id;
  final int createdAt;
  final int lastActivityAt;
  const AiConversationRow({
    required this.id,
    required this.createdAt,
    required this.lastActivityAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['last_activity_at'] = Variable<int>(lastActivityAt);
    return map;
  }

  AiConversationsCompanion toCompanion(bool nullToAbsent) {
    return AiConversationsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      lastActivityAt: Value(lastActivityAt),
    );
  }

  factory AiConversationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiConversationRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      lastActivityAt: serializer.fromJson<int>(json['lastActivityAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'lastActivityAt': serializer.toJson<int>(lastActivityAt),
    };
  }

  AiConversationRow copyWith({
    String? id,
    int? createdAt,
    int? lastActivityAt,
  }) => AiConversationRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    lastActivityAt: lastActivityAt ?? this.lastActivityAt,
  );
  AiConversationRow copyWithCompanion(AiConversationsCompanion data) {
    return AiConversationRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastActivityAt: data.lastActivityAt.present
          ? data.lastActivityAt.value
          : this.lastActivityAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiConversationRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastActivityAt: $lastActivityAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, lastActivityAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiConversationRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.lastActivityAt == this.lastActivityAt);
}

class AiConversationsCompanion extends UpdateCompanion<AiConversationRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> lastActivityAt;
  final Value<int> rowid;
  const AiConversationsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastActivityAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AiConversationsCompanion.insert({
    required String id,
    required int createdAt,
    required int lastActivityAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       lastActivityAt = Value(lastActivityAt);
  static Insertable<AiConversationRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? lastActivityAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (lastActivityAt != null) 'last_activity_at': lastActivityAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AiConversationsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? lastActivityAt,
    Value<int>? rowid,
  }) {
    return AiConversationsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (lastActivityAt.present) {
      map['last_activity_at'] = Variable<int>(lastActivityAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiConversationsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastActivityAt: $lastActivityAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AiMessagesTable extends AiMessages
    with TableInfo<$AiMessagesTable, AiMessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ai_conversations (id)',
    ),
  );
  static const VerificationMeta _senderMeta = const VerificationMeta('sender');
  @override
  late final GeneratedColumn<String> sender = GeneratedColumn<String>(
    'sender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
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
  static const VerificationMeta _failureReasonMeta = const VerificationMeta(
    'failureReason',
  );
  @override
  late final GeneratedColumn<String> failureReason = GeneratedColumn<String>(
    'failure_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groundingRefsJsonMeta = const VerificationMeta(
    'groundingRefsJson',
  );
  @override
  late final GeneratedColumn<String> groundingRefsJson =
      GeneratedColumn<String>(
        'grounding_refs_json',
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
    conversationId,
    sender,
    content,
    status,
    failureReason,
    groundingRefsJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<AiMessageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('sender')) {
      context.handle(
        _senderMeta,
        sender.isAcceptableOrUnknown(data['sender']!, _senderMeta),
      );
    } else if (isInserting) {
      context.missing(_senderMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('failure_reason')) {
      context.handle(
        _failureReasonMeta,
        failureReason.isAcceptableOrUnknown(
          data['failure_reason']!,
          _failureReasonMeta,
        ),
      );
    }
    if (data.containsKey('grounding_refs_json')) {
      context.handle(
        _groundingRefsJsonMeta,
        groundingRefsJson.isAcceptableOrUnknown(
          data['grounding_refs_json']!,
          _groundingRefsJsonMeta,
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
  AiMessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiMessageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      sender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      failureReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}failure_reason'],
      ),
      groundingRefsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grounding_refs_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AiMessagesTable createAlias(String alias) {
    return $AiMessagesTable(attachedDatabase, alias);
  }
}

class AiMessageRow extends DataClass implements Insertable<AiMessageRow> {
  final String id;
  final String conversationId;

  /// `'user'|'assistant'`.
  final String sender;
  final String content;

  /// `'sent'|'answered'|'failed'`.
  final String status;

  /// Set only when [status] is `'failed'`: `'invalidApiKey'|'rateLimited'|
  /// 'network'|'providerError'|'unrecognizedResponse'`.
  final String? failureReason;

  /// Which tool/use-case pairs grounded an assistant answer's figures.
  final String? groundingRefsJson;
  final int createdAt;
  const AiMessageRow({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.content,
    required this.status,
    this.failureReason,
    this.groundingRefsJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['conversation_id'] = Variable<String>(conversationId);
    map['sender'] = Variable<String>(sender);
    map['content'] = Variable<String>(content);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || failureReason != null) {
      map['failure_reason'] = Variable<String>(failureReason);
    }
    if (!nullToAbsent || groundingRefsJson != null) {
      map['grounding_refs_json'] = Variable<String>(groundingRefsJson);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  AiMessagesCompanion toCompanion(bool nullToAbsent) {
    return AiMessagesCompanion(
      id: Value(id),
      conversationId: Value(conversationId),
      sender: Value(sender),
      content: Value(content),
      status: Value(status),
      failureReason: failureReason == null && nullToAbsent
          ? const Value.absent()
          : Value(failureReason),
      groundingRefsJson: groundingRefsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(groundingRefsJson),
      createdAt: Value(createdAt),
    );
  }

  factory AiMessageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiMessageRow(
      id: serializer.fromJson<String>(json['id']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      sender: serializer.fromJson<String>(json['sender']),
      content: serializer.fromJson<String>(json['content']),
      status: serializer.fromJson<String>(json['status']),
      failureReason: serializer.fromJson<String?>(json['failureReason']),
      groundingRefsJson: serializer.fromJson<String?>(
        json['groundingRefsJson'],
      ),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'conversationId': serializer.toJson<String>(conversationId),
      'sender': serializer.toJson<String>(sender),
      'content': serializer.toJson<String>(content),
      'status': serializer.toJson<String>(status),
      'failureReason': serializer.toJson<String?>(failureReason),
      'groundingRefsJson': serializer.toJson<String?>(groundingRefsJson),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  AiMessageRow copyWith({
    String? id,
    String? conversationId,
    String? sender,
    String? content,
    String? status,
    Value<String?> failureReason = const Value.absent(),
    Value<String?> groundingRefsJson = const Value.absent(),
    int? createdAt,
  }) => AiMessageRow(
    id: id ?? this.id,
    conversationId: conversationId ?? this.conversationId,
    sender: sender ?? this.sender,
    content: content ?? this.content,
    status: status ?? this.status,
    failureReason: failureReason.present
        ? failureReason.value
        : this.failureReason,
    groundingRefsJson: groundingRefsJson.present
        ? groundingRefsJson.value
        : this.groundingRefsJson,
    createdAt: createdAt ?? this.createdAt,
  );
  AiMessageRow copyWithCompanion(AiMessagesCompanion data) {
    return AiMessageRow(
      id: data.id.present ? data.id.value : this.id,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      sender: data.sender.present ? data.sender.value : this.sender,
      content: data.content.present ? data.content.value : this.content,
      status: data.status.present ? data.status.value : this.status,
      failureReason: data.failureReason.present
          ? data.failureReason.value
          : this.failureReason,
      groundingRefsJson: data.groundingRefsJson.present
          ? data.groundingRefsJson.value
          : this.groundingRefsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiMessageRow(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('sender: $sender, ')
          ..write('content: $content, ')
          ..write('status: $status, ')
          ..write('failureReason: $failureReason, ')
          ..write('groundingRefsJson: $groundingRefsJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    conversationId,
    sender,
    content,
    status,
    failureReason,
    groundingRefsJson,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiMessageRow &&
          other.id == this.id &&
          other.conversationId == this.conversationId &&
          other.sender == this.sender &&
          other.content == this.content &&
          other.status == this.status &&
          other.failureReason == this.failureReason &&
          other.groundingRefsJson == this.groundingRefsJson &&
          other.createdAt == this.createdAt);
}

class AiMessagesCompanion extends UpdateCompanion<AiMessageRow> {
  final Value<String> id;
  final Value<String> conversationId;
  final Value<String> sender;
  final Value<String> content;
  final Value<String> status;
  final Value<String?> failureReason;
  final Value<String?> groundingRefsJson;
  final Value<int> createdAt;
  final Value<int> rowid;
  const AiMessagesCompanion({
    this.id = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.sender = const Value.absent(),
    this.content = const Value.absent(),
    this.status = const Value.absent(),
    this.failureReason = const Value.absent(),
    this.groundingRefsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AiMessagesCompanion.insert({
    required String id,
    required String conversationId,
    required String sender,
    required String content,
    required String status,
    this.failureReason = const Value.absent(),
    this.groundingRefsJson = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       conversationId = Value(conversationId),
       sender = Value(sender),
       content = Value(content),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<AiMessageRow> custom({
    Expression<String>? id,
    Expression<String>? conversationId,
    Expression<String>? sender,
    Expression<String>? content,
    Expression<String>? status,
    Expression<String>? failureReason,
    Expression<String>? groundingRefsJson,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (conversationId != null) 'conversation_id': conversationId,
      if (sender != null) 'sender': sender,
      if (content != null) 'content': content,
      if (status != null) 'status': status,
      if (failureReason != null) 'failure_reason': failureReason,
      if (groundingRefsJson != null) 'grounding_refs_json': groundingRefsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AiMessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? conversationId,
    Value<String>? sender,
    Value<String>? content,
    Value<String>? status,
    Value<String?>? failureReason,
    Value<String?>? groundingRefsJson,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return AiMessagesCompanion(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      status: status ?? this.status,
      failureReason: failureReason ?? this.failureReason,
      groundingRefsJson: groundingRefsJson ?? this.groundingRefsJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (sender.present) {
      map['sender'] = Variable<String>(sender.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (failureReason.present) {
      map['failure_reason'] = Variable<String>(failureReason.value);
    }
    if (groundingRefsJson.present) {
      map['grounding_refs_json'] = Variable<String>(groundingRefsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiMessagesCompanion(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('sender: $sender, ')
          ..write('content: $content, ')
          ..write('status: $status, ')
          ..write('failureReason: $failureReason, ')
          ..write('groundingRefsJson: $groundingRefsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AiSettingsTable extends AiSettings
    with TableInfo<$AiSettingsTable, AiSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasStoredCredentialMeta =
      const VerificationMeta('hasStoredCredential');
  @override
  late final GeneratedColumn<bool> hasStoredCredential = GeneratedColumn<bool>(
    'has_stored_credential',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_stored_credential" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _consentAcceptedAtMeta = const VerificationMeta(
    'consentAcceptedAt',
  );
  @override
  late final GeneratedColumn<int> consentAcceptedAt = GeneratedColumn<int>(
    'consent_accepted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
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
  static const VerificationMeta _lastObservationKeyMeta =
      const VerificationMeta('lastObservationKey');
  @override
  late final GeneratedColumn<String> lastObservationKey =
      GeneratedColumn<String>(
        'last_observation_key',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    isEnabled,
    providerId,
    hasStoredCredential,
    consentAcceptedAt,
    updatedAt,
    lastObservationKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AiSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    }
    if (data.containsKey('has_stored_credential')) {
      context.handle(
        _hasStoredCredentialMeta,
        hasStoredCredential.isAcceptableOrUnknown(
          data['has_stored_credential']!,
          _hasStoredCredentialMeta,
        ),
      );
    }
    if (data.containsKey('consent_accepted_at')) {
      context.handle(
        _consentAcceptedAtMeta,
        consentAcceptedAt.isAcceptableOrUnknown(
          data['consent_accepted_at']!,
          _consentAcceptedAtMeta,
        ),
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
    if (data.containsKey('last_observation_key')) {
      context.handle(
        _lastObservationKeyMeta,
        lastObservationKey.isAcceptableOrUnknown(
          data['last_observation_key']!,
          _lastObservationKeyMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AiSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiSettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      ),
      hasStoredCredential: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_stored_credential'],
      )!,
      consentAcceptedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}consent_accepted_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      lastObservationKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_observation_key'],
      ),
    );
  }

  @override
  $AiSettingsTable createAlias(String alias) {
    return $AiSettingsTable(attachedDatabase, alias);
  }
}

class AiSettingsRow extends DataClass implements Insertable<AiSettingsRow> {
  final String id;
  final bool isEnabled;
  final String? providerId;
  final bool hasStoredCredential;
  final int? consentAcceptedAt;
  final int updatedAt;

  /// The `observationKey` of the last proactive observation surfaced in the
  /// conversation (User Story 7 AC3 / FR-020 no-repeat rule), or `null`
  /// when none was ever surfaced. Not user data in its own right — only a
  /// de-duplication marker; written only after the observation was
  /// successfully narrated and persisted.
  final String? lastObservationKey;
  const AiSettingsRow({
    required this.id,
    required this.isEnabled,
    this.providerId,
    required this.hasStoredCredential,
    this.consentAcceptedAt,
    required this.updatedAt,
    this.lastObservationKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['is_enabled'] = Variable<bool>(isEnabled);
    if (!nullToAbsent || providerId != null) {
      map['provider_id'] = Variable<String>(providerId);
    }
    map['has_stored_credential'] = Variable<bool>(hasStoredCredential);
    if (!nullToAbsent || consentAcceptedAt != null) {
      map['consent_accepted_at'] = Variable<int>(consentAcceptedAt);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || lastObservationKey != null) {
      map['last_observation_key'] = Variable<String>(lastObservationKey);
    }
    return map;
  }

  AiSettingsCompanion toCompanion(bool nullToAbsent) {
    return AiSettingsCompanion(
      id: Value(id),
      isEnabled: Value(isEnabled),
      providerId: providerId == null && nullToAbsent
          ? const Value.absent()
          : Value(providerId),
      hasStoredCredential: Value(hasStoredCredential),
      consentAcceptedAt: consentAcceptedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(consentAcceptedAt),
      updatedAt: Value(updatedAt),
      lastObservationKey: lastObservationKey == null && nullToAbsent
          ? const Value.absent()
          : Value(lastObservationKey),
    );
  }

  factory AiSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiSettingsRow(
      id: serializer.fromJson<String>(json['id']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      providerId: serializer.fromJson<String?>(json['providerId']),
      hasStoredCredential: serializer.fromJson<bool>(
        json['hasStoredCredential'],
      ),
      consentAcceptedAt: serializer.fromJson<int?>(json['consentAcceptedAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      lastObservationKey: serializer.fromJson<String?>(
        json['lastObservationKey'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'providerId': serializer.toJson<String?>(providerId),
      'hasStoredCredential': serializer.toJson<bool>(hasStoredCredential),
      'consentAcceptedAt': serializer.toJson<int?>(consentAcceptedAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'lastObservationKey': serializer.toJson<String?>(lastObservationKey),
    };
  }

  AiSettingsRow copyWith({
    String? id,
    bool? isEnabled,
    Value<String?> providerId = const Value.absent(),
    bool? hasStoredCredential,
    Value<int?> consentAcceptedAt = const Value.absent(),
    int? updatedAt,
    Value<String?> lastObservationKey = const Value.absent(),
  }) => AiSettingsRow(
    id: id ?? this.id,
    isEnabled: isEnabled ?? this.isEnabled,
    providerId: providerId.present ? providerId.value : this.providerId,
    hasStoredCredential: hasStoredCredential ?? this.hasStoredCredential,
    consentAcceptedAt: consentAcceptedAt.present
        ? consentAcceptedAt.value
        : this.consentAcceptedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastObservationKey: lastObservationKey.present
        ? lastObservationKey.value
        : this.lastObservationKey,
  );
  AiSettingsRow copyWithCompanion(AiSettingsCompanion data) {
    return AiSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      hasStoredCredential: data.hasStoredCredential.present
          ? data.hasStoredCredential.value
          : this.hasStoredCredential,
      consentAcceptedAt: data.consentAcceptedAt.present
          ? data.consentAcceptedAt.value
          : this.consentAcceptedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastObservationKey: data.lastObservationKey.present
          ? data.lastObservationKey.value
          : this.lastObservationKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiSettingsRow(')
          ..write('id: $id, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('providerId: $providerId, ')
          ..write('hasStoredCredential: $hasStoredCredential, ')
          ..write('consentAcceptedAt: $consentAcceptedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastObservationKey: $lastObservationKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    isEnabled,
    providerId,
    hasStoredCredential,
    consentAcceptedAt,
    updatedAt,
    lastObservationKey,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiSettingsRow &&
          other.id == this.id &&
          other.isEnabled == this.isEnabled &&
          other.providerId == this.providerId &&
          other.hasStoredCredential == this.hasStoredCredential &&
          other.consentAcceptedAt == this.consentAcceptedAt &&
          other.updatedAt == this.updatedAt &&
          other.lastObservationKey == this.lastObservationKey);
}

class AiSettingsCompanion extends UpdateCompanion<AiSettingsRow> {
  final Value<String> id;
  final Value<bool> isEnabled;
  final Value<String?> providerId;
  final Value<bool> hasStoredCredential;
  final Value<int?> consentAcceptedAt;
  final Value<int> updatedAt;
  final Value<String?> lastObservationKey;
  final Value<int> rowid;
  const AiSettingsCompanion({
    this.id = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.providerId = const Value.absent(),
    this.hasStoredCredential = const Value.absent(),
    this.consentAcceptedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastObservationKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AiSettingsCompanion.insert({
    required String id,
    this.isEnabled = const Value.absent(),
    this.providerId = const Value.absent(),
    this.hasStoredCredential = const Value.absent(),
    this.consentAcceptedAt = const Value.absent(),
    required int updatedAt,
    this.lastObservationKey = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt);
  static Insertable<AiSettingsRow> custom({
    Expression<String>? id,
    Expression<bool>? isEnabled,
    Expression<String>? providerId,
    Expression<bool>? hasStoredCredential,
    Expression<int>? consentAcceptedAt,
    Expression<int>? updatedAt,
    Expression<String>? lastObservationKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (providerId != null) 'provider_id': providerId,
      if (hasStoredCredential != null)
        'has_stored_credential': hasStoredCredential,
      if (consentAcceptedAt != null) 'consent_accepted_at': consentAcceptedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastObservationKey != null)
        'last_observation_key': lastObservationKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AiSettingsCompanion copyWith({
    Value<String>? id,
    Value<bool>? isEnabled,
    Value<String?>? providerId,
    Value<bool>? hasStoredCredential,
    Value<int?>? consentAcceptedAt,
    Value<int>? updatedAt,
    Value<String?>? lastObservationKey,
    Value<int>? rowid,
  }) {
    return AiSettingsCompanion(
      id: id ?? this.id,
      isEnabled: isEnabled ?? this.isEnabled,
      providerId: providerId ?? this.providerId,
      hasStoredCredential: hasStoredCredential ?? this.hasStoredCredential,
      consentAcceptedAt: consentAcceptedAt ?? this.consentAcceptedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastObservationKey: lastObservationKey ?? this.lastObservationKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (hasStoredCredential.present) {
      map['has_stored_credential'] = Variable<bool>(hasStoredCredential.value);
    }
    if (consentAcceptedAt.present) {
      map['consent_accepted_at'] = Variable<int>(consentAcceptedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (lastObservationKey.present) {
      map['last_observation_key'] = Variable<String>(lastObservationKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiSettingsCompanion(')
          ..write('id: $id, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('providerId: $providerId, ')
          ..write('hasStoredCredential: $hasStoredCredential, ')
          ..write('consentAcceptedAt: $consentAcceptedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastObservationKey: $lastObservationKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavingsGoalsTable extends SavingsGoals
    with TableInfo<$SavingsGoalsTable, SavingsGoal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavingsGoalsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('EGP'),
  );
  static const VerificationMeta _targetAmountMinorUnitsMeta =
      const VerificationMeta('targetAmountMinorUnits');
  @override
  late final GeneratedColumn<int> targetAmountMinorUnits = GeneratedColumn<int>(
    'target_amount_minor_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthlyContributionMinorUnitsMeta =
      const VerificationMeta('monthlyContributionMinorUnits');
  @override
  late final GeneratedColumn<int> monthlyContributionMinorUnits =
      GeneratedColumn<int>(
        'monthly_contribution_minor_units',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<int> targetDate = GeneratedColumn<int>(
    'target_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
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
    type,
    currencyCode,
    targetAmountMinorUnits,
    monthlyContributionMinorUnits,
    targetDate,
    isArchived,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'savings_goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavingsGoal> instance, {
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
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('target_amount_minor_units')) {
      context.handle(
        _targetAmountMinorUnitsMeta,
        targetAmountMinorUnits.isAcceptableOrUnknown(
          data['target_amount_minor_units']!,
          _targetAmountMinorUnitsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetAmountMinorUnitsMeta);
    }
    if (data.containsKey('monthly_contribution_minor_units')) {
      context.handle(
        _monthlyContributionMinorUnitsMeta,
        monthlyContributionMinorUnits.isAcceptableOrUnknown(
          data['monthly_contribution_minor_units']!,
          _monthlyContributionMinorUnitsMeta,
        ),
      );
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
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
  SavingsGoal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavingsGoal(
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
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      ),
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      targetAmountMinorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_amount_minor_units'],
      )!,
      monthlyContributionMinorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}monthly_contribution_minor_units'],
      ),
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_date'],
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
  $SavingsGoalsTable createAlias(String alias) {
    return $SavingsGoalsTable(attachedDatabase, alias);
  }
}

class SavingsGoal extends DataClass implements Insertable<SavingsGoal> {
  final String id;
  final String idempotencyKey;
  final String name;

  /// A standard `SavingsGoalType` value, or `null` for a plain custom-named
  /// goal — cosmetic only, same open-set pattern as [Occasions.type].
  final String? type;

  /// 018: the ISO 4217 code every amount of this goal (and every
  /// [SavingsContributions.amountMinorUnits] under it) is in. Set at
  /// creation and never edited (011 FR-027).
  final String currencyCode;

  /// `> 0` (011 FR-002).
  final int targetAmountMinorUnits;

  /// `> 0` when present; `null` means no contribution plan.
  final int? monthlyContributionMinorUnits;

  /// Epoch millis, date-only.
  final int? targetDate;
  final bool isArchived;
  final int createdAt;
  final int updatedAt;

  /// Tombstone of a goal deleted with no history (011 FR-021), kept so the
  /// delete syncs.
  final int? deletedAt;
  const SavingsGoal({
    required this.id,
    required this.idempotencyKey,
    required this.name,
    this.type,
    required this.currencyCode,
    required this.targetAmountMinorUnits,
    this.monthlyContributionMinorUnits,
    this.targetDate,
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
    if (!nullToAbsent || type != null) {
      map['type'] = Variable<String>(type);
    }
    map['currency_code'] = Variable<String>(currencyCode);
    map['target_amount_minor_units'] = Variable<int>(targetAmountMinorUnits);
    if (!nullToAbsent || monthlyContributionMinorUnits != null) {
      map['monthly_contribution_minor_units'] = Variable<int>(
        monthlyContributionMinorUnits,
      );
    }
    if (!nullToAbsent || targetDate != null) {
      map['target_date'] = Variable<int>(targetDate);
    }
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  SavingsGoalsCompanion toCompanion(bool nullToAbsent) {
    return SavingsGoalsCompanion(
      id: Value(id),
      idempotencyKey: Value(idempotencyKey),
      name: Value(name),
      type: type == null && nullToAbsent ? const Value.absent() : Value(type),
      currencyCode: Value(currencyCode),
      targetAmountMinorUnits: Value(targetAmountMinorUnits),
      monthlyContributionMinorUnits:
          monthlyContributionMinorUnits == null && nullToAbsent
          ? const Value.absent()
          : Value(monthlyContributionMinorUnits),
      targetDate: targetDate == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDate),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory SavingsGoal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavingsGoal(
      id: serializer.fromJson<String>(json['id']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String?>(json['type']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      targetAmountMinorUnits: serializer.fromJson<int>(
        json['targetAmountMinorUnits'],
      ),
      monthlyContributionMinorUnits: serializer.fromJson<int?>(
        json['monthlyContributionMinorUnits'],
      ),
      targetDate: serializer.fromJson<int?>(json['targetDate']),
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
      'type': serializer.toJson<String?>(type),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'targetAmountMinorUnits': serializer.toJson<int>(targetAmountMinorUnits),
      'monthlyContributionMinorUnits': serializer.toJson<int?>(
        monthlyContributionMinorUnits,
      ),
      'targetDate': serializer.toJson<int?>(targetDate),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  SavingsGoal copyWith({
    String? id,
    String? idempotencyKey,
    String? name,
    Value<String?> type = const Value.absent(),
    String? currencyCode,
    int? targetAmountMinorUnits,
    Value<int?> monthlyContributionMinorUnits = const Value.absent(),
    Value<int?> targetDate = const Value.absent(),
    bool? isArchived,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
  }) => SavingsGoal(
    id: id ?? this.id,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    name: name ?? this.name,
    type: type.present ? type.value : this.type,
    currencyCode: currencyCode ?? this.currencyCode,
    targetAmountMinorUnits:
        targetAmountMinorUnits ?? this.targetAmountMinorUnits,
    monthlyContributionMinorUnits: monthlyContributionMinorUnits.present
        ? monthlyContributionMinorUnits.value
        : this.monthlyContributionMinorUnits,
    targetDate: targetDate.present ? targetDate.value : this.targetDate,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  SavingsGoal copyWithCompanion(SavingsGoalsCompanion data) {
    return SavingsGoal(
      id: data.id.present ? data.id.value : this.id,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      targetAmountMinorUnits: data.targetAmountMinorUnits.present
          ? data.targetAmountMinorUnits.value
          : this.targetAmountMinorUnits,
      monthlyContributionMinorUnits: data.monthlyContributionMinorUnits.present
          ? data.monthlyContributionMinorUnits.value
          : this.monthlyContributionMinorUnits,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
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
    return (StringBuffer('SavingsGoal(')
          ..write('id: $id, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('targetAmountMinorUnits: $targetAmountMinorUnits, ')
          ..write(
            'monthlyContributionMinorUnits: $monthlyContributionMinorUnits, ',
          )
          ..write('targetDate: $targetDate, ')
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
    type,
    currencyCode,
    targetAmountMinorUnits,
    monthlyContributionMinorUnits,
    targetDate,
    isArchived,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavingsGoal &&
          other.id == this.id &&
          other.idempotencyKey == this.idempotencyKey &&
          other.name == this.name &&
          other.type == this.type &&
          other.currencyCode == this.currencyCode &&
          other.targetAmountMinorUnits == this.targetAmountMinorUnits &&
          other.monthlyContributionMinorUnits ==
              this.monthlyContributionMinorUnits &&
          other.targetDate == this.targetDate &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class SavingsGoalsCompanion extends UpdateCompanion<SavingsGoal> {
  final Value<String> id;
  final Value<String> idempotencyKey;
  final Value<String> name;
  final Value<String?> type;
  final Value<String> currencyCode;
  final Value<int> targetAmountMinorUnits;
  final Value<int?> monthlyContributionMinorUnits;
  final Value<int?> targetDate;
  final Value<bool> isArchived;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const SavingsGoalsCompanion({
    this.id = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.targetAmountMinorUnits = const Value.absent(),
    this.monthlyContributionMinorUnits = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavingsGoalsCompanion.insert({
    required String id,
    required String idempotencyKey,
    required String name,
    this.type = const Value.absent(),
    this.currencyCode = const Value.absent(),
    required int targetAmountMinorUnits,
    this.monthlyContributionMinorUnits = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.isArchived = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       idempotencyKey = Value(idempotencyKey),
       name = Value(name),
       targetAmountMinorUnits = Value(targetAmountMinorUnits),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SavingsGoal> custom({
    Expression<String>? id,
    Expression<String>? idempotencyKey,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? currencyCode,
    Expression<int>? targetAmountMinorUnits,
    Expression<int>? monthlyContributionMinorUnits,
    Expression<int>? targetDate,
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
      if (type != null) 'type': type,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (targetAmountMinorUnits != null)
        'target_amount_minor_units': targetAmountMinorUnits,
      if (monthlyContributionMinorUnits != null)
        'monthly_contribution_minor_units': monthlyContributionMinorUnits,
      if (targetDate != null) 'target_date': targetDate,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavingsGoalsCompanion copyWith({
    Value<String>? id,
    Value<String>? idempotencyKey,
    Value<String>? name,
    Value<String?>? type,
    Value<String>? currencyCode,
    Value<int>? targetAmountMinorUnits,
    Value<int?>? monthlyContributionMinorUnits,
    Value<int?>? targetDate,
    Value<bool>? isArchived,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return SavingsGoalsCompanion(
      id: id ?? this.id,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      name: name ?? this.name,
      type: type ?? this.type,
      currencyCode: currencyCode ?? this.currencyCode,
      targetAmountMinorUnits:
          targetAmountMinorUnits ?? this.targetAmountMinorUnits,
      monthlyContributionMinorUnits:
          monthlyContributionMinorUnits ?? this.monthlyContributionMinorUnits,
      targetDate: targetDate ?? this.targetDate,
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
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (targetAmountMinorUnits.present) {
      map['target_amount_minor_units'] = Variable<int>(
        targetAmountMinorUnits.value,
      );
    }
    if (monthlyContributionMinorUnits.present) {
      map['monthly_contribution_minor_units'] = Variable<int>(
        monthlyContributionMinorUnits.value,
      );
    }
    if (targetDate.present) {
      map['target_date'] = Variable<int>(targetDate.value);
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
    return (StringBuffer('SavingsGoalsCompanion(')
          ..write('id: $id, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('targetAmountMinorUnits: $targetAmountMinorUnits, ')
          ..write(
            'monthlyContributionMinorUnits: $monthlyContributionMinorUnits, ',
          )
          ..write('targetDate: $targetDate, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavingsContributionsTable extends SavingsContributions
    with TableInfo<$SavingsContributionsTable, SavingsContribution> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavingsContributionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<String> goalId = GeneratedColumn<String>(
    'goal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES savings_goals (id)',
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
  static const VerificationMeta _enteredAmountMinorUnitsMeta =
      const VerificationMeta('enteredAmountMinorUnits');
  @override
  late final GeneratedColumn<int> enteredAmountMinorUnits =
      GeneratedColumn<int>(
        'entered_amount_minor_units',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _enteredCurrencyCodeMeta =
      const VerificationMeta('enteredCurrencyCode');
  @override
  late final GeneratedColumn<String> enteredCurrencyCode =
      GeneratedColumn<String>(
        'entered_currency_code',
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
    goalId,
    type,
    amountMinorUnits,
    enteredAmountMinorUnits,
    enteredCurrencyCode,
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
  static const String $name = 'savings_contributions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavingsContribution> instance, {
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
    if (data.containsKey('goal_id')) {
      context.handle(
        _goalIdMeta,
        goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_goalIdMeta);
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
    if (data.containsKey('entered_amount_minor_units')) {
      context.handle(
        _enteredAmountMinorUnitsMeta,
        enteredAmountMinorUnits.isAcceptableOrUnknown(
          data['entered_amount_minor_units']!,
          _enteredAmountMinorUnitsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_enteredAmountMinorUnitsMeta);
    }
    if (data.containsKey('entered_currency_code')) {
      context.handle(
        _enteredCurrencyCodeMeta,
        enteredCurrencyCode.isAcceptableOrUnknown(
          data['entered_currency_code']!,
          _enteredCurrencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_enteredCurrencyCodeMeta);
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
  SavingsContribution map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavingsContribution(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      amountMinorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor_units'],
      )!,
      enteredAmountMinorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entered_amount_minor_units'],
      )!,
      enteredCurrencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entered_currency_code'],
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
  $SavingsContributionsTable createAlias(String alias) {
    return $SavingsContributionsTable(attachedDatabase, alias);
  }
}

class SavingsContribution extends DataClass
    implements Insertable<SavingsContribution> {
  final String id;
  final String idempotencyKey;
  final String goalId;

  /// `'contribution'` | `'withdrawal'`. Immutable after creation.
  final String type;

  /// In the goal's currency — the only figure progress sums.
  final int amountMinorUnits;

  /// What the user typed, in [enteredCurrencyCode] (018, 011 FR-028); equal
  /// to [amountMinorUnits] when that is the goal's currency, otherwise
  /// converted once at log/edit time.
  final int enteredAmountMinorUnits;
  final String enteredCurrencyCode;

  /// Epoch millis, date-only.
  final int date;
  final String? note;
  final int createdAt;
  final int? editedAt;
  final int? deletedAt;
  const SavingsContribution({
    required this.id,
    required this.idempotencyKey,
    required this.goalId,
    required this.type,
    required this.amountMinorUnits,
    required this.enteredAmountMinorUnits,
    required this.enteredCurrencyCode,
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
    map['goal_id'] = Variable<String>(goalId);
    map['type'] = Variable<String>(type);
    map['amount_minor_units'] = Variable<int>(amountMinorUnits);
    map['entered_amount_minor_units'] = Variable<int>(enteredAmountMinorUnits);
    map['entered_currency_code'] = Variable<String>(enteredCurrencyCode);
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

  SavingsContributionsCompanion toCompanion(bool nullToAbsent) {
    return SavingsContributionsCompanion(
      id: Value(id),
      idempotencyKey: Value(idempotencyKey),
      goalId: Value(goalId),
      type: Value(type),
      amountMinorUnits: Value(amountMinorUnits),
      enteredAmountMinorUnits: Value(enteredAmountMinorUnits),
      enteredCurrencyCode: Value(enteredCurrencyCode),
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

  factory SavingsContribution.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavingsContribution(
      id: serializer.fromJson<String>(json['id']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      goalId: serializer.fromJson<String>(json['goalId']),
      type: serializer.fromJson<String>(json['type']),
      amountMinorUnits: serializer.fromJson<int>(json['amountMinorUnits']),
      enteredAmountMinorUnits: serializer.fromJson<int>(
        json['enteredAmountMinorUnits'],
      ),
      enteredCurrencyCode: serializer.fromJson<String>(
        json['enteredCurrencyCode'],
      ),
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
      'goalId': serializer.toJson<String>(goalId),
      'type': serializer.toJson<String>(type),
      'amountMinorUnits': serializer.toJson<int>(amountMinorUnits),
      'enteredAmountMinorUnits': serializer.toJson<int>(
        enteredAmountMinorUnits,
      ),
      'enteredCurrencyCode': serializer.toJson<String>(enteredCurrencyCode),
      'date': serializer.toJson<int>(date),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<int>(createdAt),
      'editedAt': serializer.toJson<int?>(editedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  SavingsContribution copyWith({
    String? id,
    String? idempotencyKey,
    String? goalId,
    String? type,
    int? amountMinorUnits,
    int? enteredAmountMinorUnits,
    String? enteredCurrencyCode,
    int? date,
    Value<String?> note = const Value.absent(),
    int? createdAt,
    Value<int?> editedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
  }) => SavingsContribution(
    id: id ?? this.id,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    goalId: goalId ?? this.goalId,
    type: type ?? this.type,
    amountMinorUnits: amountMinorUnits ?? this.amountMinorUnits,
    enteredAmountMinorUnits:
        enteredAmountMinorUnits ?? this.enteredAmountMinorUnits,
    enteredCurrencyCode: enteredCurrencyCode ?? this.enteredCurrencyCode,
    date: date ?? this.date,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    editedAt: editedAt.present ? editedAt.value : this.editedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  SavingsContribution copyWithCompanion(SavingsContributionsCompanion data) {
    return SavingsContribution(
      id: data.id.present ? data.id.value : this.id,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      type: data.type.present ? data.type.value : this.type,
      amountMinorUnits: data.amountMinorUnits.present
          ? data.amountMinorUnits.value
          : this.amountMinorUnits,
      enteredAmountMinorUnits: data.enteredAmountMinorUnits.present
          ? data.enteredAmountMinorUnits.value
          : this.enteredAmountMinorUnits,
      enteredCurrencyCode: data.enteredCurrencyCode.present
          ? data.enteredCurrencyCode.value
          : this.enteredCurrencyCode,
      date: data.date.present ? data.date.value : this.date,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavingsContribution(')
          ..write('id: $id, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('goalId: $goalId, ')
          ..write('type: $type, ')
          ..write('amountMinorUnits: $amountMinorUnits, ')
          ..write('enteredAmountMinorUnits: $enteredAmountMinorUnits, ')
          ..write('enteredCurrencyCode: $enteredCurrencyCode, ')
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
    goalId,
    type,
    amountMinorUnits,
    enteredAmountMinorUnits,
    enteredCurrencyCode,
    date,
    note,
    createdAt,
    editedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavingsContribution &&
          other.id == this.id &&
          other.idempotencyKey == this.idempotencyKey &&
          other.goalId == this.goalId &&
          other.type == this.type &&
          other.amountMinorUnits == this.amountMinorUnits &&
          other.enteredAmountMinorUnits == this.enteredAmountMinorUnits &&
          other.enteredCurrencyCode == this.enteredCurrencyCode &&
          other.date == this.date &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.editedAt == this.editedAt &&
          other.deletedAt == this.deletedAt);
}

class SavingsContributionsCompanion
    extends UpdateCompanion<SavingsContribution> {
  final Value<String> id;
  final Value<String> idempotencyKey;
  final Value<String> goalId;
  final Value<String> type;
  final Value<int> amountMinorUnits;
  final Value<int> enteredAmountMinorUnits;
  final Value<String> enteredCurrencyCode;
  final Value<int> date;
  final Value<String?> note;
  final Value<int> createdAt;
  final Value<int?> editedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const SavingsContributionsCompanion({
    this.id = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.goalId = const Value.absent(),
    this.type = const Value.absent(),
    this.amountMinorUnits = const Value.absent(),
    this.enteredAmountMinorUnits = const Value.absent(),
    this.enteredCurrencyCode = const Value.absent(),
    this.date = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavingsContributionsCompanion.insert({
    required String id,
    required String idempotencyKey,
    required String goalId,
    required String type,
    required int amountMinorUnits,
    required int enteredAmountMinorUnits,
    required String enteredCurrencyCode,
    required int date,
    this.note = const Value.absent(),
    required int createdAt,
    this.editedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       idempotencyKey = Value(idempotencyKey),
       goalId = Value(goalId),
       type = Value(type),
       amountMinorUnits = Value(amountMinorUnits),
       enteredAmountMinorUnits = Value(enteredAmountMinorUnits),
       enteredCurrencyCode = Value(enteredCurrencyCode),
       date = Value(date),
       createdAt = Value(createdAt);
  static Insertable<SavingsContribution> custom({
    Expression<String>? id,
    Expression<String>? idempotencyKey,
    Expression<String>? goalId,
    Expression<String>? type,
    Expression<int>? amountMinorUnits,
    Expression<int>? enteredAmountMinorUnits,
    Expression<String>? enteredCurrencyCode,
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
      if (goalId != null) 'goal_id': goalId,
      if (type != null) 'type': type,
      if (amountMinorUnits != null) 'amount_minor_units': amountMinorUnits,
      if (enteredAmountMinorUnits != null)
        'entered_amount_minor_units': enteredAmountMinorUnits,
      if (enteredCurrencyCode != null)
        'entered_currency_code': enteredCurrencyCode,
      if (date != null) 'date': date,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (editedAt != null) 'edited_at': editedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavingsContributionsCompanion copyWith({
    Value<String>? id,
    Value<String>? idempotencyKey,
    Value<String>? goalId,
    Value<String>? type,
    Value<int>? amountMinorUnits,
    Value<int>? enteredAmountMinorUnits,
    Value<String>? enteredCurrencyCode,
    Value<int>? date,
    Value<String?>? note,
    Value<int>? createdAt,
    Value<int?>? editedAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return SavingsContributionsCompanion(
      id: id ?? this.id,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      goalId: goalId ?? this.goalId,
      type: type ?? this.type,
      amountMinorUnits: amountMinorUnits ?? this.amountMinorUnits,
      enteredAmountMinorUnits:
          enteredAmountMinorUnits ?? this.enteredAmountMinorUnits,
      enteredCurrencyCode: enteredCurrencyCode ?? this.enteredCurrencyCode,
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
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amountMinorUnits.present) {
      map['amount_minor_units'] = Variable<int>(amountMinorUnits.value);
    }
    if (enteredAmountMinorUnits.present) {
      map['entered_amount_minor_units'] = Variable<int>(
        enteredAmountMinorUnits.value,
      );
    }
    if (enteredCurrencyCode.present) {
      map['entered_currency_code'] = Variable<String>(
        enteredCurrencyCode.value,
      );
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
    return (StringBuffer('SavingsContributionsCompanion(')
          ..write('id: $id, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('goalId: $goalId, ')
          ..write('type: $type, ')
          ..write('amountMinorUnits: $amountMinorUnits, ')
          ..write('enteredAmountMinorUnits: $enteredAmountMinorUnits, ')
          ..write('enteredCurrencyCode: $enteredCurrencyCode, ')
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

class $SavingsContributionAuditsTable extends SavingsContributionAudits
    with TableInfo<$SavingsContributionAuditsTable, SavingsContributionAudit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavingsContributionAuditsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contributionIdMeta = const VerificationMeta(
    'contributionId',
  );
  @override
  late final GeneratedColumn<String> contributionId = GeneratedColumn<String>(
    'contribution_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES savings_contributions (id)',
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
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
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
    contributionId,
    changeType,
    previousValuesJson,
    changedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'savings_contribution_audits';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavingsContributionAudit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('contribution_id')) {
      context.handle(
        _contributionIdMeta,
        contributionId.isAcceptableOrUnknown(
          data['contribution_id']!,
          _contributionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contributionIdMeta);
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
    } else if (isInserting) {
      context.missing(_previousValuesJsonMeta);
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
  SavingsContributionAudit map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavingsContributionAudit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      contributionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contribution_id'],
      )!,
      changeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}change_type'],
      )!,
      previousValuesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous_values_json'],
      )!,
      changedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}changed_at'],
      )!,
    );
  }

  @override
  $SavingsContributionAuditsTable createAlias(String alias) {
    return $SavingsContributionAuditsTable(attachedDatabase, alias);
  }
}

class SavingsContributionAudit extends DataClass
    implements Insertable<SavingsContributionAudit> {
  final String id;
  final String contributionId;

  /// `'edited'` | `'deleted'`.
  final String changeType;

  /// JSON of the row before the change.
  final String previousValuesJson;
  final int changedAt;
  const SavingsContributionAudit({
    required this.id,
    required this.contributionId,
    required this.changeType,
    required this.previousValuesJson,
    required this.changedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['contribution_id'] = Variable<String>(contributionId);
    map['change_type'] = Variable<String>(changeType);
    map['previous_values_json'] = Variable<String>(previousValuesJson);
    map['changed_at'] = Variable<int>(changedAt);
    return map;
  }

  SavingsContributionAuditsCompanion toCompanion(bool nullToAbsent) {
    return SavingsContributionAuditsCompanion(
      id: Value(id),
      contributionId: Value(contributionId),
      changeType: Value(changeType),
      previousValuesJson: Value(previousValuesJson),
      changedAt: Value(changedAt),
    );
  }

  factory SavingsContributionAudit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavingsContributionAudit(
      id: serializer.fromJson<String>(json['id']),
      contributionId: serializer.fromJson<String>(json['contributionId']),
      changeType: serializer.fromJson<String>(json['changeType']),
      previousValuesJson: serializer.fromJson<String>(
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
      'contributionId': serializer.toJson<String>(contributionId),
      'changeType': serializer.toJson<String>(changeType),
      'previousValuesJson': serializer.toJson<String>(previousValuesJson),
      'changedAt': serializer.toJson<int>(changedAt),
    };
  }

  SavingsContributionAudit copyWith({
    String? id,
    String? contributionId,
    String? changeType,
    String? previousValuesJson,
    int? changedAt,
  }) => SavingsContributionAudit(
    id: id ?? this.id,
    contributionId: contributionId ?? this.contributionId,
    changeType: changeType ?? this.changeType,
    previousValuesJson: previousValuesJson ?? this.previousValuesJson,
    changedAt: changedAt ?? this.changedAt,
  );
  SavingsContributionAudit copyWithCompanion(
    SavingsContributionAuditsCompanion data,
  ) {
    return SavingsContributionAudit(
      id: data.id.present ? data.id.value : this.id,
      contributionId: data.contributionId.present
          ? data.contributionId.value
          : this.contributionId,
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
    return (StringBuffer('SavingsContributionAudit(')
          ..write('id: $id, ')
          ..write('contributionId: $contributionId, ')
          ..write('changeType: $changeType, ')
          ..write('previousValuesJson: $previousValuesJson, ')
          ..write('changedAt: $changedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    contributionId,
    changeType,
    previousValuesJson,
    changedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavingsContributionAudit &&
          other.id == this.id &&
          other.contributionId == this.contributionId &&
          other.changeType == this.changeType &&
          other.previousValuesJson == this.previousValuesJson &&
          other.changedAt == this.changedAt);
}

class SavingsContributionAuditsCompanion
    extends UpdateCompanion<SavingsContributionAudit> {
  final Value<String> id;
  final Value<String> contributionId;
  final Value<String> changeType;
  final Value<String> previousValuesJson;
  final Value<int> changedAt;
  final Value<int> rowid;
  const SavingsContributionAuditsCompanion({
    this.id = const Value.absent(),
    this.contributionId = const Value.absent(),
    this.changeType = const Value.absent(),
    this.previousValuesJson = const Value.absent(),
    this.changedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavingsContributionAuditsCompanion.insert({
    required String id,
    required String contributionId,
    required String changeType,
    required String previousValuesJson,
    required int changedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       contributionId = Value(contributionId),
       changeType = Value(changeType),
       previousValuesJson = Value(previousValuesJson),
       changedAt = Value(changedAt);
  static Insertable<SavingsContributionAudit> custom({
    Expression<String>? id,
    Expression<String>? contributionId,
    Expression<String>? changeType,
    Expression<String>? previousValuesJson,
    Expression<int>? changedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contributionId != null) 'contribution_id': contributionId,
      if (changeType != null) 'change_type': changeType,
      if (previousValuesJson != null)
        'previous_values_json': previousValuesJson,
      if (changedAt != null) 'changed_at': changedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavingsContributionAuditsCompanion copyWith({
    Value<String>? id,
    Value<String>? contributionId,
    Value<String>? changeType,
    Value<String>? previousValuesJson,
    Value<int>? changedAt,
    Value<int>? rowid,
  }) {
    return SavingsContributionAuditsCompanion(
      id: id ?? this.id,
      contributionId: contributionId ?? this.contributionId,
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
    if (contributionId.present) {
      map['contribution_id'] = Variable<String>(contributionId.value);
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
    return (StringBuffer('SavingsContributionAuditsCompanion(')
          ..write('id: $id, ')
          ..write('contributionId: $contributionId, ')
          ..write('changeType: $changeType, ')
          ..write('previousValuesJson: $previousValuesJson, ')
          ..write('changedAt: $changedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FinanceEntryAuditsTable extends FinanceEntryAudits
    with TableInfo<$FinanceEntryAuditsTable, FinanceEntryAudit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinanceEntryAuditsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _financeEntryIdMeta = const VerificationMeta(
    'financeEntryId',
  );
  @override
  late final GeneratedColumn<String> financeEntryId = GeneratedColumn<String>(
    'finance_entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES finance_entries (id)',
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
    financeEntryId,
    changeType,
    previousValuesJson,
    changedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'finance_entry_audits';
  @override
  VerificationContext validateIntegrity(
    Insertable<FinanceEntryAudit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('finance_entry_id')) {
      context.handle(
        _financeEntryIdMeta,
        financeEntryId.isAcceptableOrUnknown(
          data['finance_entry_id']!,
          _financeEntryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_financeEntryIdMeta);
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
  FinanceEntryAudit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FinanceEntryAudit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      financeEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}finance_entry_id'],
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
  $FinanceEntryAuditsTable createAlias(String alias) {
    return $FinanceEntryAuditsTable(attachedDatabase, alias);
  }
}

class FinanceEntryAudit extends DataClass
    implements Insertable<FinanceEntryAudit> {
  final String id;
  final String financeEntryId;
  final String changeType;
  final String? previousValuesJson;
  final int changedAt;
  const FinanceEntryAudit({
    required this.id,
    required this.financeEntryId,
    required this.changeType,
    this.previousValuesJson,
    required this.changedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['finance_entry_id'] = Variable<String>(financeEntryId);
    map['change_type'] = Variable<String>(changeType);
    if (!nullToAbsent || previousValuesJson != null) {
      map['previous_values_json'] = Variable<String>(previousValuesJson);
    }
    map['changed_at'] = Variable<int>(changedAt);
    return map;
  }

  FinanceEntryAuditsCompanion toCompanion(bool nullToAbsent) {
    return FinanceEntryAuditsCompanion(
      id: Value(id),
      financeEntryId: Value(financeEntryId),
      changeType: Value(changeType),
      previousValuesJson: previousValuesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(previousValuesJson),
      changedAt: Value(changedAt),
    );
  }

  factory FinanceEntryAudit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FinanceEntryAudit(
      id: serializer.fromJson<String>(json['id']),
      financeEntryId: serializer.fromJson<String>(json['financeEntryId']),
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
      'financeEntryId': serializer.toJson<String>(financeEntryId),
      'changeType': serializer.toJson<String>(changeType),
      'previousValuesJson': serializer.toJson<String?>(previousValuesJson),
      'changedAt': serializer.toJson<int>(changedAt),
    };
  }

  FinanceEntryAudit copyWith({
    String? id,
    String? financeEntryId,
    String? changeType,
    Value<String?> previousValuesJson = const Value.absent(),
    int? changedAt,
  }) => FinanceEntryAudit(
    id: id ?? this.id,
    financeEntryId: financeEntryId ?? this.financeEntryId,
    changeType: changeType ?? this.changeType,
    previousValuesJson: previousValuesJson.present
        ? previousValuesJson.value
        : this.previousValuesJson,
    changedAt: changedAt ?? this.changedAt,
  );
  FinanceEntryAudit copyWithCompanion(FinanceEntryAuditsCompanion data) {
    return FinanceEntryAudit(
      id: data.id.present ? data.id.value : this.id,
      financeEntryId: data.financeEntryId.present
          ? data.financeEntryId.value
          : this.financeEntryId,
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
    return (StringBuffer('FinanceEntryAudit(')
          ..write('id: $id, ')
          ..write('financeEntryId: $financeEntryId, ')
          ..write('changeType: $changeType, ')
          ..write('previousValuesJson: $previousValuesJson, ')
          ..write('changedAt: $changedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    financeEntryId,
    changeType,
    previousValuesJson,
    changedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinanceEntryAudit &&
          other.id == this.id &&
          other.financeEntryId == this.financeEntryId &&
          other.changeType == this.changeType &&
          other.previousValuesJson == this.previousValuesJson &&
          other.changedAt == this.changedAt);
}

class FinanceEntryAuditsCompanion extends UpdateCompanion<FinanceEntryAudit> {
  final Value<String> id;
  final Value<String> financeEntryId;
  final Value<String> changeType;
  final Value<String?> previousValuesJson;
  final Value<int> changedAt;
  final Value<int> rowid;
  const FinanceEntryAuditsCompanion({
    this.id = const Value.absent(),
    this.financeEntryId = const Value.absent(),
    this.changeType = const Value.absent(),
    this.previousValuesJson = const Value.absent(),
    this.changedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FinanceEntryAuditsCompanion.insert({
    required String id,
    required String financeEntryId,
    required String changeType,
    this.previousValuesJson = const Value.absent(),
    required int changedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       financeEntryId = Value(financeEntryId),
       changeType = Value(changeType),
       changedAt = Value(changedAt);
  static Insertable<FinanceEntryAudit> custom({
    Expression<String>? id,
    Expression<String>? financeEntryId,
    Expression<String>? changeType,
    Expression<String>? previousValuesJson,
    Expression<int>? changedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (financeEntryId != null) 'finance_entry_id': financeEntryId,
      if (changeType != null) 'change_type': changeType,
      if (previousValuesJson != null)
        'previous_values_json': previousValuesJson,
      if (changedAt != null) 'changed_at': changedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FinanceEntryAuditsCompanion copyWith({
    Value<String>? id,
    Value<String>? financeEntryId,
    Value<String>? changeType,
    Value<String?>? previousValuesJson,
    Value<int>? changedAt,
    Value<int>? rowid,
  }) {
    return FinanceEntryAuditsCompanion(
      id: id ?? this.id,
      financeEntryId: financeEntryId ?? this.financeEntryId,
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
    if (financeEntryId.present) {
      map['finance_entry_id'] = Variable<String>(financeEntryId.value);
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
    return (StringBuffer('FinanceEntryAuditsCompanion(')
          ..write('id: $id, ')
          ..write('financeEntryId: $financeEntryId, ')
          ..write('changeType: $changeType, ')
          ..write('previousValuesJson: $previousValuesJson, ')
          ..write('changedAt: $changedAt, ')
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
  late final $NotificationPreferencesTable notificationPreferences =
      $NotificationPreferencesTable(this);
  late final $NotificationHistoryTable notificationHistory =
      $NotificationHistoryTable(this);
  late final $PrimaryCurrencySettingsTable primaryCurrencySettings =
      $PrimaryCurrencySettingsTable(this);
  late final $ExchangeRatesTable exchangeRates = $ExchangeRatesTable(this);
  late final $SyncOutboxEntriesTable syncOutboxEntries =
      $SyncOutboxEntriesTable(this);
  late final $SyncRecordMetaTable syncRecordMeta = $SyncRecordMetaTable(this);
  late final $SyncConflictsTable syncConflicts = $SyncConflictsTable(this);
  late final $ConflictResolutionsTable conflictResolutions =
      $ConflictResolutionsTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  late final $OccasionAttachmentsTable occasionAttachments =
      $OccasionAttachmentsTable(this);
  late final $OcrScansTable ocrScans = $OcrScansTable(this);
  late final $CandidateEntriesTable candidateEntries = $CandidateEntriesTable(
    this,
  );
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $BudgetCategoryAllocationsTable budgetCategoryAllocations =
      $BudgetCategoryAllocationsTable(this);
  late final $AiConversationsTable aiConversations = $AiConversationsTable(
    this,
  );
  late final $AiMessagesTable aiMessages = $AiMessagesTable(this);
  late final $AiSettingsTable aiSettings = $AiSettingsTable(this);
  late final $SavingsGoalsTable savingsGoals = $SavingsGoalsTable(this);
  late final $SavingsContributionsTable savingsContributions =
      $SavingsContributionsTable(this);
  late final $SavingsContributionAuditsTable savingsContributionAudits =
      $SavingsContributionAuditsTable(this);
  late final $FinanceEntryAuditsTable financeEntryAudits =
      $FinanceEntryAuditsTable(this);
  late final Index idxPeopleNormalizedName = Index(
    'idx_people_normalized_name',
    'CREATE INDEX idx_people_normalized_name ON people (normalized_name)',
  );
  late final Index idxPeopleArchived = Index(
    'idx_people_archived',
    'CREATE INDEX idx_people_archived ON people (is_archived, normalized_name)',
  );
  late final Index idxTransactionsPersonId = Index(
    'idx_transactions_person_id',
    'CREATE INDEX idx_transactions_person_id ON money_transactions (person_id, deleted_at)',
  );
  late final Index idxTransactionsDate = Index(
    'idx_transactions_date',
    'CREATE INDEX idx_transactions_date ON money_transactions (date, deleted_at)',
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
  late final Index idxNotificationHistorySource = Index(
    'idx_notification_history_source',
    'CREATE UNIQUE INDEX idx_notification_history_source ON notification_history (source_type, source_id, COALESCE(applicable_period, \'\'))',
  );
  late final Index idxExchangeRatesPair = Index(
    'idx_exchange_rates_pair',
    'CREATE UNIQUE INDEX idx_exchange_rates_pair ON exchange_rates (currency_code, relative_to_currency_code)',
  );
  late final Index idxOutboxReady = Index(
    'idx_outbox_ready',
    'CREATE INDEX idx_outbox_ready ON sync_outbox (status, depends_on_rank, created_at)',
  );
  late final Index idxOutboxEntity = Index(
    'idx_outbox_entity',
    'CREATE INDEX idx_outbox_entity ON sync_outbox (entity_type, entity_id, status)',
  );
  late final Index idxMetaState = Index(
    'idx_meta_state',
    'CREATE INDEX idx_meta_state ON sync_record_meta (state)',
  );
  late final Index idxConflictsOpen = Index(
    'idx_conflicts_open',
    'CREATE UNIQUE INDEX idx_conflicts_open ON sync_conflicts (entity_type, entity_id) WHERE resolved_at IS NULL',
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
  late final Index idxAiMessagesConversationCreated = Index(
    'idx_ai_messages_conversation_created',
    'CREATE INDEX idx_ai_messages_conversation_created ON ai_messages (conversation_id, created_at)',
  );
  late final Index idxSavingsGoalsIdempotencyKey = Index(
    'idx_savings_goals_idempotency_key',
    'CREATE UNIQUE INDEX idx_savings_goals_idempotency_key ON savings_goals (idempotency_key)',
  );
  late final Index idxSavingsContributionsIdempotencyKey = Index(
    'idx_savings_contributions_idempotency_key',
    'CREATE UNIQUE INDEX idx_savings_contributions_idempotency_key ON savings_contributions (idempotency_key)',
  );
  late final Index idxSavingsContributionsGoalId = Index(
    'idx_savings_contributions_goal_id',
    'CREATE INDEX idx_savings_contributions_goal_id ON savings_contributions (goal_id, deleted_at)',
  );
  late final Index idxSavingsContributionAuditsContributionId = Index(
    'idx_savings_contribution_audits_contribution_id',
    'CREATE INDEX idx_savings_contribution_audits_contribution_id ON savings_contribution_audits (contribution_id)',
  );
  late final Index idxFinanceAuditEntryId = Index(
    'idx_finance_audit_entry_id',
    'CREATE INDEX idx_finance_audit_entry_id ON finance_entry_audits (finance_entry_id)',
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
    notificationPreferences,
    notificationHistory,
    primaryCurrencySettings,
    exchangeRates,
    syncOutboxEntries,
    syncRecordMeta,
    syncConflicts,
    conflictResolutions,
    syncState,
    occasionAttachments,
    ocrScans,
    candidateEntries,
    budgets,
    budgetCategoryAllocations,
    aiConversations,
    aiMessages,
    aiSettings,
    savingsGoals,
    savingsContributions,
    savingsContributionAudits,
    financeEntryAudits,
    idxPeopleNormalizedName,
    idxPeopleArchived,
    idxTransactionsPersonId,
    idxTransactionsDate,
    idxTransactionsOccasionId,
    idxTransactionsOcrScanId,
    idxAuditTransactionId,
    idxFinanceCategoriesNormalizedName,
    idxFinanceEntriesCategoryId,
    idxFinanceEntriesDate,
    idxNotificationHistorySource,
    idxExchangeRatesPair,
    idxOutboxReady,
    idxOutboxEntity,
    idxMetaState,
    idxConflictsOpen,
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
    idxAiMessagesConversationCreated,
    idxSavingsGoalsIdempotencyKey,
    idxSavingsContributionsIdempotencyKey,
    idxSavingsContributionsGoalId,
    idxSavingsContributionAuditsContributionId,
    idxFinanceAuditEntryId,
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
      Value<String> currencyCode,
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
      Value<String> currencyCode,
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

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
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

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
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

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
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
                Value<String> currencyCode = const Value.absent(),
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
                currencyCode: currencyCode,
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
                Value<String> currencyCode = const Value.absent(),
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
                currencyCode: currencyCode,
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
      Value<bool?> glassEnabled,
      Value<String?> glassTransparency,
      Value<String?> glassIntensity,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> id,
      Value<String> languageCode,
      Value<String?> themeMode,
      Value<bool?> glassEnabled,
      Value<String?> glassTransparency,
      Value<String?> glassIntensity,
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

  ColumnFilters<bool> get glassEnabled => $composableBuilder(
    column: $table.glassEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get glassTransparency => $composableBuilder(
    column: $table.glassTransparency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get glassIntensity => $composableBuilder(
    column: $table.glassIntensity,
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

  ColumnOrderings<bool> get glassEnabled => $composableBuilder(
    column: $table.glassEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get glassTransparency => $composableBuilder(
    column: $table.glassTransparency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get glassIntensity => $composableBuilder(
    column: $table.glassIntensity,
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

  GeneratedColumn<bool> get glassEnabled => $composableBuilder(
    column: $table.glassEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get glassTransparency => $composableBuilder(
    column: $table.glassTransparency,
    builder: (column) => column,
  );

  GeneratedColumn<String> get glassIntensity => $composableBuilder(
    column: $table.glassIntensity,
    builder: (column) => column,
  );

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
                Value<bool?> glassEnabled = const Value.absent(),
                Value<String?> glassTransparency = const Value.absent(),
                Value<String?> glassIntensity = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                languageCode: languageCode,
                themeMode: themeMode,
                glassEnabled: glassEnabled,
                glassTransparency: glassTransparency,
                glassIntensity: glassIntensity,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String languageCode,
                Value<String?> themeMode = const Value.absent(),
                Value<bool?> glassEnabled = const Value.absent(),
                Value<String?> glassTransparency = const Value.absent(),
                Value<String?> glassIntensity = const Value.absent(),
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                languageCode: languageCode,
                themeMode: themeMode,
                glassEnabled: glassEnabled,
                glassTransparency: glassTransparency,
                glassIntensity: glassIntensity,
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
      Value<String> currencyCode,
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
      Value<String> currencyCode,
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

  static MultiTypedResultKey<$FinanceEntryAuditsTable, List<FinanceEntryAudit>>
  _financeEntryAuditsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.financeEntryAudits,
        aliasName:
            'finance_entries__id__finance_entry_audits__finance_entry_id',
      );

  $$FinanceEntryAuditsTableProcessedTableManager get financeEntryAuditsRefs {
    final manager = $$FinanceEntryAuditsTableTableManager(
      $_db,
      $_db.financeEntryAudits,
    ).filter((f) => f.financeEntryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _financeEntryAuditsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
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

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
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

  Expression<bool> financeEntryAuditsRefs(
    Expression<bool> Function($$FinanceEntryAuditsTableFilterComposer f) f,
  ) {
    final $$FinanceEntryAuditsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.financeEntryAudits,
      getReferencedColumn: (t) => t.financeEntryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinanceEntryAuditsTableFilterComposer(
            $db: $db,
            $table: $db.financeEntryAudits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
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

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
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

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
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

  Expression<T> financeEntryAuditsRefs<T extends Object>(
    Expression<T> Function($$FinanceEntryAuditsTableAnnotationComposer a) f,
  ) {
    final $$FinanceEntryAuditsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.financeEntryAudits,
          getReferencedColumn: (t) => t.financeEntryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FinanceEntryAuditsTableAnnotationComposer(
                $db: $db,
                $table: $db.financeEntryAudits,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
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
          PrefetchHooks Function({bool categoryId, bool financeEntryAuditsRefs})
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
                Value<String> currencyCode = const Value.absent(),
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
                currencyCode: currencyCode,
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
                Value<String> currencyCode = const Value.absent(),
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
                currencyCode: currencyCode,
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
          prefetchHooksCallback:
              ({categoryId = false, financeEntryAuditsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (financeEntryAuditsRefs) db.financeEntryAudits,
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
                        if (categoryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.categoryId,
                                    referencedTable:
                                        $$FinanceEntriesTableReferences
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
                    return [
                      if (financeEntryAuditsRefs)
                        await $_getPrefetchedData<
                          FinanceEntry,
                          $FinanceEntriesTable,
                          FinanceEntryAudit
                        >(
                          currentTable: table,
                          referencedTable: $$FinanceEntriesTableReferences
                              ._financeEntryAuditsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FinanceEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).financeEntryAuditsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.financeEntryId == item.id,
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
      PrefetchHooks Function({bool categoryId, bool financeEntryAuditsRefs})
    >;
typedef $$NotificationPreferencesTableCreateCompanionBuilder =
    NotificationPreferencesCompanion Function({
      required String id,
      Value<bool> isEnabled,
      Value<bool> budgetWarningsEnabled,
      Value<bool> savingsCheckInsEnabled,
      Value<int?> quietHoursStartMinutes,
      Value<int?> quietHoursEndMinutes,
      Value<bool> osPermissionGranted,
      Value<int> rowid,
    });
typedef $$NotificationPreferencesTableUpdateCompanionBuilder =
    NotificationPreferencesCompanion Function({
      Value<String> id,
      Value<bool> isEnabled,
      Value<bool> budgetWarningsEnabled,
      Value<bool> savingsCheckInsEnabled,
      Value<int?> quietHoursStartMinutes,
      Value<int?> quietHoursEndMinutes,
      Value<bool> osPermissionGranted,
      Value<int> rowid,
    });

class $$NotificationPreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationPreferencesTable> {
  $$NotificationPreferencesTableFilterComposer({
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

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get budgetWarningsEnabled => $composableBuilder(
    column: $table.budgetWarningsEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get savingsCheckInsEnabled => $composableBuilder(
    column: $table.savingsCheckInsEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quietHoursStartMinutes => $composableBuilder(
    column: $table.quietHoursStartMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quietHoursEndMinutes => $composableBuilder(
    column: $table.quietHoursEndMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get osPermissionGranted => $composableBuilder(
    column: $table.osPermissionGranted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotificationPreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationPreferencesTable> {
  $$NotificationPreferencesTableOrderingComposer({
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

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get budgetWarningsEnabled => $composableBuilder(
    column: $table.budgetWarningsEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get savingsCheckInsEnabled => $composableBuilder(
    column: $table.savingsCheckInsEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quietHoursStartMinutes => $composableBuilder(
    column: $table.quietHoursStartMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quietHoursEndMinutes => $composableBuilder(
    column: $table.quietHoursEndMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get osPermissionGranted => $composableBuilder(
    column: $table.osPermissionGranted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotificationPreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationPreferencesTable> {
  $$NotificationPreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<bool> get budgetWarningsEnabled => $composableBuilder(
    column: $table.budgetWarningsEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get savingsCheckInsEnabled => $composableBuilder(
    column: $table.savingsCheckInsEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quietHoursStartMinutes => $composableBuilder(
    column: $table.quietHoursStartMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quietHoursEndMinutes => $composableBuilder(
    column: $table.quietHoursEndMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get osPermissionGranted => $composableBuilder(
    column: $table.osPermissionGranted,
    builder: (column) => column,
  );
}

class $$NotificationPreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotificationPreferencesTable,
          NotificationPreference,
          $$NotificationPreferencesTableFilterComposer,
          $$NotificationPreferencesTableOrderingComposer,
          $$NotificationPreferencesTableAnnotationComposer,
          $$NotificationPreferencesTableCreateCompanionBuilder,
          $$NotificationPreferencesTableUpdateCompanionBuilder,
          (
            NotificationPreference,
            BaseReferences<
              _$AppDatabase,
              $NotificationPreferencesTable,
              NotificationPreference
            >,
          ),
          NotificationPreference,
          PrefetchHooks Function()
        > {
  $$NotificationPreferencesTableTableManager(
    _$AppDatabase db,
    $NotificationPreferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationPreferencesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$NotificationPreferencesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$NotificationPreferencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<bool> budgetWarningsEnabled = const Value.absent(),
                Value<bool> savingsCheckInsEnabled = const Value.absent(),
                Value<int?> quietHoursStartMinutes = const Value.absent(),
                Value<int?> quietHoursEndMinutes = const Value.absent(),
                Value<bool> osPermissionGranted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificationPreferencesCompanion(
                id: id,
                isEnabled: isEnabled,
                budgetWarningsEnabled: budgetWarningsEnabled,
                savingsCheckInsEnabled: savingsCheckInsEnabled,
                quietHoursStartMinutes: quietHoursStartMinutes,
                quietHoursEndMinutes: quietHoursEndMinutes,
                osPermissionGranted: osPermissionGranted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<bool> isEnabled = const Value.absent(),
                Value<bool> budgetWarningsEnabled = const Value.absent(),
                Value<bool> savingsCheckInsEnabled = const Value.absent(),
                Value<int?> quietHoursStartMinutes = const Value.absent(),
                Value<int?> quietHoursEndMinutes = const Value.absent(),
                Value<bool> osPermissionGranted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificationPreferencesCompanion.insert(
                id: id,
                isEnabled: isEnabled,
                budgetWarningsEnabled: budgetWarningsEnabled,
                savingsCheckInsEnabled: savingsCheckInsEnabled,
                quietHoursStartMinutes: quietHoursStartMinutes,
                quietHoursEndMinutes: quietHoursEndMinutes,
                osPermissionGranted: osPermissionGranted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $NotificationPreferencesTable,
                    NotificationPreference
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $NotificationPreferencesTable,
                    NotificationPreference
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotificationPreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotificationPreferencesTable,
      NotificationPreference,
      $$NotificationPreferencesTableFilterComposer,
      $$NotificationPreferencesTableOrderingComposer,
      $$NotificationPreferencesTableAnnotationComposer,
      $$NotificationPreferencesTableCreateCompanionBuilder,
      $$NotificationPreferencesTableUpdateCompanionBuilder,
      (
        NotificationPreference,
        BaseReferences<
          _$AppDatabase,
          $NotificationPreferencesTable,
          NotificationPreference
        >,
      ),
      NotificationPreference,
      PrefetchHooks Function()
    >;
typedef $$NotificationHistoryTableCreateCompanionBuilder =
    NotificationHistoryCompanion Function({
      required String id,
      required String sourceType,
      required String sourceId,
      Value<String?> applicablePeriod,
      required String lastNotifiedBand,
      required int lastNotifiedAt,
      Value<int> rowid,
    });
typedef $$NotificationHistoryTableUpdateCompanionBuilder =
    NotificationHistoryCompanion Function({
      Value<String> id,
      Value<String> sourceType,
      Value<String> sourceId,
      Value<String?> applicablePeriod,
      Value<String> lastNotifiedBand,
      Value<int> lastNotifiedAt,
      Value<int> rowid,
    });

class $$NotificationHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationHistoryTable> {
  $$NotificationHistoryTableFilterComposer({
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

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get applicablePeriod => $composableBuilder(
    column: $table.applicablePeriod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastNotifiedBand => $composableBuilder(
    column: $table.lastNotifiedBand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastNotifiedAt => $composableBuilder(
    column: $table.lastNotifiedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotificationHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationHistoryTable> {
  $$NotificationHistoryTableOrderingComposer({
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

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get applicablePeriod => $composableBuilder(
    column: $table.applicablePeriod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastNotifiedBand => $composableBuilder(
    column: $table.lastNotifiedBand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastNotifiedAt => $composableBuilder(
    column: $table.lastNotifiedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotificationHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationHistoryTable> {
  $$NotificationHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get applicablePeriod => $composableBuilder(
    column: $table.applicablePeriod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastNotifiedBand => $composableBuilder(
    column: $table.lastNotifiedBand,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastNotifiedAt => $composableBuilder(
    column: $table.lastNotifiedAt,
    builder: (column) => column,
  );
}

class $$NotificationHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotificationHistoryTable,
          NotificationHistoryData,
          $$NotificationHistoryTableFilterComposer,
          $$NotificationHistoryTableOrderingComposer,
          $$NotificationHistoryTableAnnotationComposer,
          $$NotificationHistoryTableCreateCompanionBuilder,
          $$NotificationHistoryTableUpdateCompanionBuilder,
          (
            NotificationHistoryData,
            BaseReferences<
              _$AppDatabase,
              $NotificationHistoryTable,
              NotificationHistoryData
            >,
          ),
          NotificationHistoryData,
          PrefetchHooks Function()
        > {
  $$NotificationHistoryTableTableManager(
    _$AppDatabase db,
    $NotificationHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotificationHistoryTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$NotificationHistoryTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String?> applicablePeriod = const Value.absent(),
                Value<String> lastNotifiedBand = const Value.absent(),
                Value<int> lastNotifiedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificationHistoryCompanion(
                id: id,
                sourceType: sourceType,
                sourceId: sourceId,
                applicablePeriod: applicablePeriod,
                lastNotifiedBand: lastNotifiedBand,
                lastNotifiedAt: lastNotifiedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceType,
                required String sourceId,
                Value<String?> applicablePeriod = const Value.absent(),
                required String lastNotifiedBand,
                required int lastNotifiedAt,
                Value<int> rowid = const Value.absent(),
              }) => NotificationHistoryCompanion.insert(
                id: id,
                sourceType: sourceType,
                sourceId: sourceId,
                applicablePeriod: applicablePeriod,
                lastNotifiedBand: lastNotifiedBand,
                lastNotifiedAt: lastNotifiedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $NotificationHistoryTable,
                    NotificationHistoryData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $NotificationHistoryTable,
                    NotificationHistoryData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotificationHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotificationHistoryTable,
      NotificationHistoryData,
      $$NotificationHistoryTableFilterComposer,
      $$NotificationHistoryTableOrderingComposer,
      $$NotificationHistoryTableAnnotationComposer,
      $$NotificationHistoryTableCreateCompanionBuilder,
      $$NotificationHistoryTableUpdateCompanionBuilder,
      (
        NotificationHistoryData,
        BaseReferences<
          _$AppDatabase,
          $NotificationHistoryTable,
          NotificationHistoryData
        >,
      ),
      NotificationHistoryData,
      PrefetchHooks Function()
    >;
typedef $$PrimaryCurrencySettingsTableCreateCompanionBuilder =
    PrimaryCurrencySettingsCompanion Function({
      required String id,
      Value<String> currencyCode,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$PrimaryCurrencySettingsTableUpdateCompanionBuilder =
    PrimaryCurrencySettingsCompanion Function({
      Value<String> id,
      Value<String> currencyCode,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$PrimaryCurrencySettingsTableFilterComposer
    extends Composer<_$AppDatabase, $PrimaryCurrencySettingsTable> {
  $$PrimaryCurrencySettingsTableFilterComposer({
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

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PrimaryCurrencySettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $PrimaryCurrencySettingsTable> {
  $$PrimaryCurrencySettingsTableOrderingComposer({
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

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrimaryCurrencySettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrimaryCurrencySettingsTable> {
  $$PrimaryCurrencySettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PrimaryCurrencySettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrimaryCurrencySettingsTable,
          PrimaryCurrencySetting,
          $$PrimaryCurrencySettingsTableFilterComposer,
          $$PrimaryCurrencySettingsTableOrderingComposer,
          $$PrimaryCurrencySettingsTableAnnotationComposer,
          $$PrimaryCurrencySettingsTableCreateCompanionBuilder,
          $$PrimaryCurrencySettingsTableUpdateCompanionBuilder,
          (
            PrimaryCurrencySetting,
            BaseReferences<
              _$AppDatabase,
              $PrimaryCurrencySettingsTable,
              PrimaryCurrencySetting
            >,
          ),
          PrimaryCurrencySetting,
          PrefetchHooks Function()
        > {
  $$PrimaryCurrencySettingsTableTableManager(
    _$AppDatabase db,
    $PrimaryCurrencySettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrimaryCurrencySettingsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PrimaryCurrencySettingsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PrimaryCurrencySettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrimaryCurrencySettingsCompanion(
                id: id,
                currencyCode: currencyCode,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> currencyCode = const Value.absent(),
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PrimaryCurrencySettingsCompanion.insert(
                id: id,
                currencyCode: currencyCode,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $PrimaryCurrencySettingsTable,
                    PrimaryCurrencySetting
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PrimaryCurrencySettingsTable,
                    PrimaryCurrencySetting
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrimaryCurrencySettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrimaryCurrencySettingsTable,
      PrimaryCurrencySetting,
      $$PrimaryCurrencySettingsTableFilterComposer,
      $$PrimaryCurrencySettingsTableOrderingComposer,
      $$PrimaryCurrencySettingsTableAnnotationComposer,
      $$PrimaryCurrencySettingsTableCreateCompanionBuilder,
      $$PrimaryCurrencySettingsTableUpdateCompanionBuilder,
      (
        PrimaryCurrencySetting,
        BaseReferences<
          _$AppDatabase,
          $PrimaryCurrencySettingsTable,
          PrimaryCurrencySetting
        >,
      ),
      PrimaryCurrencySetting,
      PrefetchHooks Function()
    >;
typedef $$ExchangeRatesTableCreateCompanionBuilder =
    ExchangeRatesCompanion Function({
      required String id,
      required String currencyCode,
      required String relativeToCurrencyCode,
      required int rateMicros,
      required int lastUpdatedAt,
      Value<int> rowid,
    });
typedef $$ExchangeRatesTableUpdateCompanionBuilder =
    ExchangeRatesCompanion Function({
      Value<String> id,
      Value<String> currencyCode,
      Value<String> relativeToCurrencyCode,
      Value<int> rateMicros,
      Value<int> lastUpdatedAt,
      Value<int> rowid,
    });

class $$ExchangeRatesTableFilterComposer
    extends Composer<_$AppDatabase, $ExchangeRatesTable> {
  $$ExchangeRatesTableFilterComposer({
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

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relativeToCurrencyCode => $composableBuilder(
    column: $table.relativeToCurrencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rateMicros => $composableBuilder(
    column: $table.rateMicros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExchangeRatesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExchangeRatesTable> {
  $$ExchangeRatesTableOrderingComposer({
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

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relativeToCurrencyCode => $composableBuilder(
    column: $table.relativeToCurrencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rateMicros => $composableBuilder(
    column: $table.rateMicros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExchangeRatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExchangeRatesTable> {
  $$ExchangeRatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relativeToCurrencyCode => $composableBuilder(
    column: $table.relativeToCurrencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rateMicros => $composableBuilder(
    column: $table.rateMicros,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => column,
  );
}

class $$ExchangeRatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExchangeRatesTable,
          ExchangeRate,
          $$ExchangeRatesTableFilterComposer,
          $$ExchangeRatesTableOrderingComposer,
          $$ExchangeRatesTableAnnotationComposer,
          $$ExchangeRatesTableCreateCompanionBuilder,
          $$ExchangeRatesTableUpdateCompanionBuilder,
          (
            ExchangeRate,
            BaseReferences<_$AppDatabase, $ExchangeRatesTable, ExchangeRate>,
          ),
          ExchangeRate,
          PrefetchHooks Function()
        > {
  $$ExchangeRatesTableTableManager(_$AppDatabase db, $ExchangeRatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExchangeRatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExchangeRatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExchangeRatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String> relativeToCurrencyCode = const Value.absent(),
                Value<int> rateMicros = const Value.absent(),
                Value<int> lastUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExchangeRatesCompanion(
                id: id,
                currencyCode: currencyCode,
                relativeToCurrencyCode: relativeToCurrencyCode,
                rateMicros: rateMicros,
                lastUpdatedAt: lastUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String currencyCode,
                required String relativeToCurrencyCode,
                required int rateMicros,
                required int lastUpdatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ExchangeRatesCompanion.insert(
                id: id,
                currencyCode: currencyCode,
                relativeToCurrencyCode: relativeToCurrencyCode,
                rateMicros: rateMicros,
                lastUpdatedAt: lastUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExchangeRatesTable, ExchangeRate>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ExchangeRatesTable,
                    ExchangeRate
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExchangeRatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExchangeRatesTable,
      ExchangeRate,
      $$ExchangeRatesTableFilterComposer,
      $$ExchangeRatesTableOrderingComposer,
      $$ExchangeRatesTableAnnotationComposer,
      $$ExchangeRatesTableCreateCompanionBuilder,
      $$ExchangeRatesTableUpdateCompanionBuilder,
      (
        ExchangeRate,
        BaseReferences<_$AppDatabase, $ExchangeRatesTable, ExchangeRate>,
      ),
      ExchangeRate,
      PrefetchHooks Function()
    >;
typedef $$SyncOutboxEntriesTableCreateCompanionBuilder =
    SyncOutboxEntriesCompanion Function({
      required String opId,
      required String entityType,
      required String entityId,
      required String opType,
      required String payloadJson,
      Value<int?> baseRevision,
      required int dependsOnRank,
      required String status,
      Value<int> attemptCount,
      Value<int?> lastAttemptAt,
      Value<int?> nextAttemptAt,
      Value<String?> errorCode,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$SyncOutboxEntriesTableUpdateCompanionBuilder =
    SyncOutboxEntriesCompanion Function({
      Value<String> opId,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> opType,
      Value<String> payloadJson,
      Value<int?> baseRevision,
      Value<int> dependsOnRank,
      Value<String> status,
      Value<int> attemptCount,
      Value<int?> lastAttemptAt,
      Value<int?> nextAttemptAt,
      Value<String?> errorCode,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$SyncOutboxEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncOutboxEntriesTable> {
  $$SyncOutboxEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get opType => $composableBuilder(
    column: $table.opType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dependsOnRank => $composableBuilder(
    column: $table.dependsOnRank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncOutboxEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncOutboxEntriesTable> {
  $$SyncOutboxEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get opType => $composableBuilder(
    column: $table.opType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dependsOnRank => $composableBuilder(
    column: $table.dependsOnRank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncOutboxEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncOutboxEntriesTable> {
  $$SyncOutboxEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get opId =>
      $composableBuilder(column: $table.opId, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get opType =>
      $composableBuilder(column: $table.opType, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dependsOnRank => $composableBuilder(
    column: $table.dependsOnRank,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorCode =>
      $composableBuilder(column: $table.errorCode, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncOutboxEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncOutboxEntriesTable,
          SyncOutboxRow,
          $$SyncOutboxEntriesTableFilterComposer,
          $$SyncOutboxEntriesTableOrderingComposer,
          $$SyncOutboxEntriesTableAnnotationComposer,
          $$SyncOutboxEntriesTableCreateCompanionBuilder,
          $$SyncOutboxEntriesTableUpdateCompanionBuilder,
          (
            SyncOutboxRow,
            BaseReferences<
              _$AppDatabase,
              $SyncOutboxEntriesTable,
              SyncOutboxRow
            >,
          ),
          SyncOutboxRow,
          PrefetchHooks Function()
        > {
  $$SyncOutboxEntriesTableTableManager(
    _$AppDatabase db,
    $SyncOutboxEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncOutboxEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncOutboxEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncOutboxEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> opId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> opType = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int?> baseRevision = const Value.absent(),
                Value<int> dependsOnRank = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<int?> lastAttemptAt = const Value.absent(),
                Value<int?> nextAttemptAt = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncOutboxEntriesCompanion(
                opId: opId,
                entityType: entityType,
                entityId: entityId,
                opType: opType,
                payloadJson: payloadJson,
                baseRevision: baseRevision,
                dependsOnRank: dependsOnRank,
                status: status,
                attemptCount: attemptCount,
                lastAttemptAt: lastAttemptAt,
                nextAttemptAt: nextAttemptAt,
                errorCode: errorCode,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String opId,
                required String entityType,
                required String entityId,
                required String opType,
                required String payloadJson,
                Value<int?> baseRevision = const Value.absent(),
                required int dependsOnRank,
                required String status,
                Value<int> attemptCount = const Value.absent(),
                Value<int?> lastAttemptAt = const Value.absent(),
                Value<int?> nextAttemptAt = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncOutboxEntriesCompanion.insert(
                opId: opId,
                entityType: entityType,
                entityId: entityId,
                opType: opType,
                payloadJson: payloadJson,
                baseRevision: baseRevision,
                dependsOnRank: dependsOnRank,
                status: status,
                attemptCount: attemptCount,
                lastAttemptAt: lastAttemptAt,
                nextAttemptAt: nextAttemptAt,
                errorCode: errorCode,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncOutboxEntriesTable, SyncOutboxRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncOutboxEntriesTable,
                    SyncOutboxRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncOutboxEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncOutboxEntriesTable,
      SyncOutboxRow,
      $$SyncOutboxEntriesTableFilterComposer,
      $$SyncOutboxEntriesTableOrderingComposer,
      $$SyncOutboxEntriesTableAnnotationComposer,
      $$SyncOutboxEntriesTableCreateCompanionBuilder,
      $$SyncOutboxEntriesTableUpdateCompanionBuilder,
      (
        SyncOutboxRow,
        BaseReferences<_$AppDatabase, $SyncOutboxEntriesTable, SyncOutboxRow>,
      ),
      SyncOutboxRow,
      PrefetchHooks Function()
    >;
typedef $$SyncRecordMetaTableCreateCompanionBuilder =
    SyncRecordMetaCompanion Function({
      required String entityType,
      required String entityId,
      Value<int?> serverRevision,
      required String state,
      Value<int?> lastSyncedAt,
      Value<int> rowid,
    });
typedef $$SyncRecordMetaTableUpdateCompanionBuilder =
    SyncRecordMetaCompanion Function({
      Value<String> entityType,
      Value<String> entityId,
      Value<int?> serverRevision,
      Value<String> state,
      Value<int?> lastSyncedAt,
      Value<int> rowid,
    });

class $$SyncRecordMetaTableFilterComposer
    extends Composer<_$AppDatabase, $SyncRecordMetaTable> {
  $$SyncRecordMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverRevision => $composableBuilder(
    column: $table.serverRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncRecordMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncRecordMetaTable> {
  $$SyncRecordMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverRevision => $composableBuilder(
    column: $table.serverRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncRecordMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncRecordMetaTable> {
  $$SyncRecordMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<int> get serverRevision => $composableBuilder(
    column: $table.serverRevision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );
}

class $$SyncRecordMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncRecordMetaTable,
          SyncRecordMetaRow,
          $$SyncRecordMetaTableFilterComposer,
          $$SyncRecordMetaTableOrderingComposer,
          $$SyncRecordMetaTableAnnotationComposer,
          $$SyncRecordMetaTableCreateCompanionBuilder,
          $$SyncRecordMetaTableUpdateCompanionBuilder,
          (
            SyncRecordMetaRow,
            BaseReferences<
              _$AppDatabase,
              $SyncRecordMetaTable,
              SyncRecordMetaRow
            >,
          ),
          SyncRecordMetaRow,
          PrefetchHooks Function()
        > {
  $$SyncRecordMetaTableTableManager(
    _$AppDatabase db,
    $SyncRecordMetaTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncRecordMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncRecordMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncRecordMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<int?> serverRevision = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncRecordMetaCompanion(
                entityType: entityType,
                entityId: entityId,
                serverRevision: serverRevision,
                state: state,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entityType,
                required String entityId,
                Value<int?> serverRevision = const Value.absent(),
                required String state,
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncRecordMetaCompanion.insert(
                entityType: entityType,
                entityId: entityId,
                serverRevision: serverRevision,
                state: state,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncRecordMetaTable, SyncRecordMetaRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncRecordMetaTable,
                    SyncRecordMetaRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncRecordMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncRecordMetaTable,
      SyncRecordMetaRow,
      $$SyncRecordMetaTableFilterComposer,
      $$SyncRecordMetaTableOrderingComposer,
      $$SyncRecordMetaTableAnnotationComposer,
      $$SyncRecordMetaTableCreateCompanionBuilder,
      $$SyncRecordMetaTableUpdateCompanionBuilder,
      (
        SyncRecordMetaRow,
        BaseReferences<_$AppDatabase, $SyncRecordMetaTable, SyncRecordMetaRow>,
      ),
      SyncRecordMetaRow,
      PrefetchHooks Function()
    >;
typedef $$SyncConflictsTableCreateCompanionBuilder =
    SyncConflictsCompanion Function({
      required String id,
      required String entityType,
      required String entityId,
      required String localPayloadJson,
      required String serverPayloadJson,
      required int serverRevision,
      required int detectedAt,
      Value<int?> resolvedAt,
      Value<int> rowid,
    });
typedef $$SyncConflictsTableUpdateCompanionBuilder =
    SyncConflictsCompanion Function({
      Value<String> id,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> localPayloadJson,
      Value<String> serverPayloadJson,
      Value<int> serverRevision,
      Value<int> detectedAt,
      Value<int?> resolvedAt,
      Value<int> rowid,
    });

class $$SyncConflictsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncConflictsTable> {
  $$SyncConflictsTableFilterComposer({
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

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPayloadJson => $composableBuilder(
    column: $table.localPayloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverPayloadJson => $composableBuilder(
    column: $table.serverPayloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverRevision => $composableBuilder(
    column: $table.serverRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get detectedAt => $composableBuilder(
    column: $table.detectedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncConflictsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncConflictsTable> {
  $$SyncConflictsTableOrderingComposer({
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

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPayloadJson => $composableBuilder(
    column: $table.localPayloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverPayloadJson => $composableBuilder(
    column: $table.serverPayloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverRevision => $composableBuilder(
    column: $table.serverRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get detectedAt => $composableBuilder(
    column: $table.detectedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncConflictsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncConflictsTable> {
  $$SyncConflictsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get localPayloadJson => $composableBuilder(
    column: $table.localPayloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverPayloadJson => $composableBuilder(
    column: $table.serverPayloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverRevision => $composableBuilder(
    column: $table.serverRevision,
    builder: (column) => column,
  );

  GeneratedColumn<int> get detectedAt => $composableBuilder(
    column: $table.detectedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => column,
  );
}

class $$SyncConflictsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncConflictsTable,
          SyncConflictRow,
          $$SyncConflictsTableFilterComposer,
          $$SyncConflictsTableOrderingComposer,
          $$SyncConflictsTableAnnotationComposer,
          $$SyncConflictsTableCreateCompanionBuilder,
          $$SyncConflictsTableUpdateCompanionBuilder,
          (
            SyncConflictRow,
            BaseReferences<_$AppDatabase, $SyncConflictsTable, SyncConflictRow>,
          ),
          SyncConflictRow,
          PrefetchHooks Function()
        > {
  $$SyncConflictsTableTableManager(_$AppDatabase db, $SyncConflictsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncConflictsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncConflictsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncConflictsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> localPayloadJson = const Value.absent(),
                Value<String> serverPayloadJson = const Value.absent(),
                Value<int> serverRevision = const Value.absent(),
                Value<int> detectedAt = const Value.absent(),
                Value<int?> resolvedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncConflictsCompanion(
                id: id,
                entityType: entityType,
                entityId: entityId,
                localPayloadJson: localPayloadJson,
                serverPayloadJson: serverPayloadJson,
                serverRevision: serverRevision,
                detectedAt: detectedAt,
                resolvedAt: resolvedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entityType,
                required String entityId,
                required String localPayloadJson,
                required String serverPayloadJson,
                required int serverRevision,
                required int detectedAt,
                Value<int?> resolvedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncConflictsCompanion.insert(
                id: id,
                entityType: entityType,
                entityId: entityId,
                localPayloadJson: localPayloadJson,
                serverPayloadJson: serverPayloadJson,
                serverRevision: serverRevision,
                detectedAt: detectedAt,
                resolvedAt: resolvedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncConflictsTable, SyncConflictRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncConflictsTable,
                    SyncConflictRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncConflictsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncConflictsTable,
      SyncConflictRow,
      $$SyncConflictsTableFilterComposer,
      $$SyncConflictsTableOrderingComposer,
      $$SyncConflictsTableAnnotationComposer,
      $$SyncConflictsTableCreateCompanionBuilder,
      $$SyncConflictsTableUpdateCompanionBuilder,
      (
        SyncConflictRow,
        BaseReferences<_$AppDatabase, $SyncConflictsTable, SyncConflictRow>,
      ),
      SyncConflictRow,
      PrefetchHooks Function()
    >;
typedef $$ConflictResolutionsTableCreateCompanionBuilder =
    ConflictResolutionsCompanion Function({
      required String id,
      required String entityType,
      required String entityId,
      required String chosenSide,
      required String discardedValuesJson,
      required int resolvedAt,
      Value<int> rowid,
    });
typedef $$ConflictResolutionsTableUpdateCompanionBuilder =
    ConflictResolutionsCompanion Function({
      Value<String> id,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> chosenSide,
      Value<String> discardedValuesJson,
      Value<int> resolvedAt,
      Value<int> rowid,
    });

class $$ConflictResolutionsTableFilterComposer
    extends Composer<_$AppDatabase, $ConflictResolutionsTable> {
  $$ConflictResolutionsTableFilterComposer({
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

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chosenSide => $composableBuilder(
    column: $table.chosenSide,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get discardedValuesJson => $composableBuilder(
    column: $table.discardedValuesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConflictResolutionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConflictResolutionsTable> {
  $$ConflictResolutionsTableOrderingComposer({
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

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chosenSide => $composableBuilder(
    column: $table.chosenSide,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discardedValuesJson => $composableBuilder(
    column: $table.discardedValuesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConflictResolutionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConflictResolutionsTable> {
  $$ConflictResolutionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get chosenSide => $composableBuilder(
    column: $table.chosenSide,
    builder: (column) => column,
  );

  GeneratedColumn<String> get discardedValuesJson => $composableBuilder(
    column: $table.discardedValuesJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => column,
  );
}

class $$ConflictResolutionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConflictResolutionsTable,
          ConflictResolutionRow,
          $$ConflictResolutionsTableFilterComposer,
          $$ConflictResolutionsTableOrderingComposer,
          $$ConflictResolutionsTableAnnotationComposer,
          $$ConflictResolutionsTableCreateCompanionBuilder,
          $$ConflictResolutionsTableUpdateCompanionBuilder,
          (
            ConflictResolutionRow,
            BaseReferences<
              _$AppDatabase,
              $ConflictResolutionsTable,
              ConflictResolutionRow
            >,
          ),
          ConflictResolutionRow,
          PrefetchHooks Function()
        > {
  $$ConflictResolutionsTableTableManager(
    _$AppDatabase db,
    $ConflictResolutionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConflictResolutionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConflictResolutionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ConflictResolutionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> chosenSide = const Value.absent(),
                Value<String> discardedValuesJson = const Value.absent(),
                Value<int> resolvedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConflictResolutionsCompanion(
                id: id,
                entityType: entityType,
                entityId: entityId,
                chosenSide: chosenSide,
                discardedValuesJson: discardedValuesJson,
                resolvedAt: resolvedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entityType,
                required String entityId,
                required String chosenSide,
                required String discardedValuesJson,
                required int resolvedAt,
                Value<int> rowid = const Value.absent(),
              }) => ConflictResolutionsCompanion.insert(
                id: id,
                entityType: entityType,
                entityId: entityId,
                chosenSide: chosenSide,
                discardedValuesJson: discardedValuesJson,
                resolvedAt: resolvedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ConflictResolutionsTable, ConflictResolutionRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $ConflictResolutionsTable,
                    ConflictResolutionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConflictResolutionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConflictResolutionsTable,
      ConflictResolutionRow,
      $$ConflictResolutionsTableFilterComposer,
      $$ConflictResolutionsTableOrderingComposer,
      $$ConflictResolutionsTableAnnotationComposer,
      $$ConflictResolutionsTableCreateCompanionBuilder,
      $$ConflictResolutionsTableUpdateCompanionBuilder,
      (
        ConflictResolutionRow,
        BaseReferences<
          _$AppDatabase,
          $ConflictResolutionsTable,
          ConflictResolutionRow
        >,
      ),
      ConflictResolutionRow,
      PrefetchHooks Function()
    >;
typedef $$SyncStateTableCreateCompanionBuilder =
    SyncStateCompanion Function({
      required String id,
      Value<bool> enabled,
      Value<bool> noticeShown,
      Value<String?> ownerId,
      required String deviceId,
      Value<int> lastPulledRevision,
      Value<bool> bootstrapEnqueued,
      Value<bool> initialUploadDone,
      Value<bool> b1RepullDone,
      Value<int?> lastAttemptAt,
      Value<int?> lastSuccessAt,
      Value<int> consecutiveFailures,
      Value<String?> lastErrorCode,
      Value<int> rowid,
    });
typedef $$SyncStateTableUpdateCompanionBuilder =
    SyncStateCompanion Function({
      Value<String> id,
      Value<bool> enabled,
      Value<bool> noticeShown,
      Value<String?> ownerId,
      Value<String> deviceId,
      Value<int> lastPulledRevision,
      Value<bool> bootstrapEnqueued,
      Value<bool> initialUploadDone,
      Value<bool> b1RepullDone,
      Value<int?> lastAttemptAt,
      Value<int?> lastSuccessAt,
      Value<int> consecutiveFailures,
      Value<String?> lastErrorCode,
      Value<int> rowid,
    });

class $$SyncStateTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
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

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get noticeShown => $composableBuilder(
    column: $table.noticeShown,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastPulledRevision => $composableBuilder(
    column: $table.lastPulledRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get bootstrapEnqueued => $composableBuilder(
    column: $table.bootstrapEnqueued,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get initialUploadDone => $composableBuilder(
    column: $table.initialUploadDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get b1RepullDone => $composableBuilder(
    column: $table.b1RepullDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSuccessAt => $composableBuilder(
    column: $table.lastSuccessAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get consecutiveFailures => $composableBuilder(
    column: $table.consecutiveFailures,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
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

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get noticeShown => $composableBuilder(
    column: $table.noticeShown,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastPulledRevision => $composableBuilder(
    column: $table.lastPulledRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get bootstrapEnqueued => $composableBuilder(
    column: $table.bootstrapEnqueued,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get initialUploadDone => $composableBuilder(
    column: $table.initialUploadDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get b1RepullDone => $composableBuilder(
    column: $table.b1RepullDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSuccessAt => $composableBuilder(
    column: $table.lastSuccessAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get consecutiveFailures => $composableBuilder(
    column: $table.consecutiveFailures,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<bool> get noticeShown => $composableBuilder(
    column: $table.noticeShown,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get lastPulledRevision => $composableBuilder(
    column: $table.lastPulledRevision,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get bootstrapEnqueued => $composableBuilder(
    column: $table.bootstrapEnqueued,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get initialUploadDone => $composableBuilder(
    column: $table.initialUploadDone,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get b1RepullDone => $composableBuilder(
    column: $table.b1RepullDone,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSuccessAt => $composableBuilder(
    column: $table.lastSuccessAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get consecutiveFailures => $composableBuilder(
    column: $table.consecutiveFailures,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => column,
  );
}

class $$SyncStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStateTable,
          SyncStateRow,
          $$SyncStateTableFilterComposer,
          $$SyncStateTableOrderingComposer,
          $$SyncStateTableAnnotationComposer,
          $$SyncStateTableCreateCompanionBuilder,
          $$SyncStateTableUpdateCompanionBuilder,
          (
            SyncStateRow,
            BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateRow>,
          ),
          SyncStateRow,
          PrefetchHooks Function()
        > {
  $$SyncStateTableTableManager(_$AppDatabase db, $SyncStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<bool> noticeShown = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> lastPulledRevision = const Value.absent(),
                Value<bool> bootstrapEnqueued = const Value.absent(),
                Value<bool> initialUploadDone = const Value.absent(),
                Value<bool> b1RepullDone = const Value.absent(),
                Value<int?> lastAttemptAt = const Value.absent(),
                Value<int?> lastSuccessAt = const Value.absent(),
                Value<int> consecutiveFailures = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion(
                id: id,
                enabled: enabled,
                noticeShown: noticeShown,
                ownerId: ownerId,
                deviceId: deviceId,
                lastPulledRevision: lastPulledRevision,
                bootstrapEnqueued: bootstrapEnqueued,
                initialUploadDone: initialUploadDone,
                b1RepullDone: b1RepullDone,
                lastAttemptAt: lastAttemptAt,
                lastSuccessAt: lastSuccessAt,
                consecutiveFailures: consecutiveFailures,
                lastErrorCode: lastErrorCode,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<bool> enabled = const Value.absent(),
                Value<bool> noticeShown = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                required String deviceId,
                Value<int> lastPulledRevision = const Value.absent(),
                Value<bool> bootstrapEnqueued = const Value.absent(),
                Value<bool> initialUploadDone = const Value.absent(),
                Value<bool> b1RepullDone = const Value.absent(),
                Value<int?> lastAttemptAt = const Value.absent(),
                Value<int?> lastSuccessAt = const Value.absent(),
                Value<int> consecutiveFailures = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion.insert(
                id: id,
                enabled: enabled,
                noticeShown: noticeShown,
                ownerId: ownerId,
                deviceId: deviceId,
                lastPulledRevision: lastPulledRevision,
                bootstrapEnqueued: bootstrapEnqueued,
                initialUploadDone: initialUploadDone,
                b1RepullDone: b1RepullDone,
                lastAttemptAt: lastAttemptAt,
                lastSuccessAt: lastSuccessAt,
                consecutiveFailures: consecutiveFailures,
                lastErrorCode: lastErrorCode,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncStateTable, SyncStateRow>(table),
                  BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateRow>(
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

typedef $$SyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStateTable,
      SyncStateRow,
      $$SyncStateTableFilterComposer,
      $$SyncStateTableOrderingComposer,
      $$SyncStateTableAnnotationComposer,
      $$SyncStateTableCreateCompanionBuilder,
      $$SyncStateTableUpdateCompanionBuilder,
      (
        SyncStateRow,
        BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateRow>,
      ),
      SyncStateRow,
      PrefetchHooks Function()
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
      Value<String> currencyCode,
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
      Value<String> currencyCode,
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

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
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

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
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

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
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
                Value<String> currencyCode = const Value.absent(),
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
                currencyCode: currencyCode,
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
                Value<String> currencyCode = const Value.absent(),
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
                currencyCode: currencyCode,
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
      Value<String> currencyCode,
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
      Value<String> currencyCode,
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

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
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

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
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

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
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
                Value<String> currencyCode = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCompanion(
                id: id,
                idempotencyKey: idempotencyKey,
                month: month,
                expectedIncomeMinorUnits: expectedIncomeMinorUnits,
                currencyCode: currencyCode,
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
                Value<String> currencyCode = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCompanion.insert(
                id: id,
                idempotencyKey: idempotencyKey,
                month: month,
                expectedIncomeMinorUnits: expectedIncomeMinorUnits,
                currencyCode: currencyCode,
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
typedef $$AiConversationsTableCreateCompanionBuilder =
    AiConversationsCompanion Function({
      required String id,
      required int createdAt,
      required int lastActivityAt,
      Value<int> rowid,
    });
typedef $$AiConversationsTableUpdateCompanionBuilder =
    AiConversationsCompanion Function({
      Value<String> id,
      Value<int> createdAt,
      Value<int> lastActivityAt,
      Value<int> rowid,
    });

final class $$AiConversationsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AiConversationsTable,
          AiConversationRow
        > {
  $$AiConversationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$AiMessagesTable, List<AiMessageRow>>
  _aiMessagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.aiMessages,
    aliasName: 'ai_conversations__id__ai_messages__conversation_id',
  );

  $$AiMessagesTableProcessedTableManager get aiMessagesRefs {
    final manager = $$AiMessagesTableTableManager(
      $_db,
      $_db.aiMessages,
    ).filter((f) => f.conversationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_aiMessagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AiConversationsTableFilterComposer
    extends Composer<_$AppDatabase, $AiConversationsTable> {
  $$AiConversationsTableFilterComposer({
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

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastActivityAt => $composableBuilder(
    column: $table.lastActivityAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> aiMessagesRefs(
    Expression<bool> Function($$AiMessagesTableFilterComposer f) f,
  ) {
    final $$AiMessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.aiMessages,
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AiMessagesTableFilterComposer(
            $db: $db,
            $table: $db.aiMessages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AiConversationsTableOrderingComposer
    extends Composer<_$AppDatabase, $AiConversationsTable> {
  $$AiConversationsTableOrderingComposer({
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

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastActivityAt => $composableBuilder(
    column: $table.lastActivityAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AiConversationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiConversationsTable> {
  $$AiConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get lastActivityAt => $composableBuilder(
    column: $table.lastActivityAt,
    builder: (column) => column,
  );

  Expression<T> aiMessagesRefs<T extends Object>(
    Expression<T> Function($$AiMessagesTableAnnotationComposer a) f,
  ) {
    final $$AiMessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.aiMessages,
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AiMessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.aiMessages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AiConversationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AiConversationsTable,
          AiConversationRow,
          $$AiConversationsTableFilterComposer,
          $$AiConversationsTableOrderingComposer,
          $$AiConversationsTableAnnotationComposer,
          $$AiConversationsTableCreateCompanionBuilder,
          $$AiConversationsTableUpdateCompanionBuilder,
          (AiConversationRow, $$AiConversationsTableReferences),
          AiConversationRow,
          PrefetchHooks Function({bool aiMessagesRefs})
        > {
  $$AiConversationsTableTableManager(
    _$AppDatabase db,
    $AiConversationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiConversationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> lastActivityAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AiConversationsCompanion(
                id: id,
                createdAt: createdAt,
                lastActivityAt: lastActivityAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int createdAt,
                required int lastActivityAt,
                Value<int> rowid = const Value.absent(),
              }) => AiConversationsCompanion.insert(
                id: id,
                createdAt: createdAt,
                lastActivityAt: lastActivityAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AiConversationsTable, AiConversationRow>(table),
                  $$AiConversationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({aiMessagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (aiMessagesRefs) db.aiMessages],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (aiMessagesRefs)
                    await $_getPrefetchedData<
                      AiConversationRow,
                      $AiConversationsTable,
                      AiMessageRow
                    >(
                      currentTable: table,
                      referencedTable: $$AiConversationsTableReferences
                          ._aiMessagesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$AiConversationsTableReferences(
                            db,
                            table,
                            p0,
                          ).aiMessagesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.conversationId == item.id,
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

typedef $$AiConversationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AiConversationsTable,
      AiConversationRow,
      $$AiConversationsTableFilterComposer,
      $$AiConversationsTableOrderingComposer,
      $$AiConversationsTableAnnotationComposer,
      $$AiConversationsTableCreateCompanionBuilder,
      $$AiConversationsTableUpdateCompanionBuilder,
      (AiConversationRow, $$AiConversationsTableReferences),
      AiConversationRow,
      PrefetchHooks Function({bool aiMessagesRefs})
    >;
typedef $$AiMessagesTableCreateCompanionBuilder =
    AiMessagesCompanion Function({
      required String id,
      required String conversationId,
      required String sender,
      required String content,
      required String status,
      Value<String?> failureReason,
      Value<String?> groundingRefsJson,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$AiMessagesTableUpdateCompanionBuilder =
    AiMessagesCompanion Function({
      Value<String> id,
      Value<String> conversationId,
      Value<String> sender,
      Value<String> content,
      Value<String> status,
      Value<String?> failureReason,
      Value<String?> groundingRefsJson,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$AiMessagesTableReferences
    extends BaseReferences<_$AppDatabase, $AiMessagesTable, AiMessageRow> {
  $$AiMessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AiConversationsTable _conversationIdTable(_$AppDatabase db) => db
      .aiConversations
      .createAlias('ai_messages__conversation_id__ai_conversations__id');

  $$AiConversationsTableProcessedTableManager get conversationId {
    final $_column = $_itemColumn<String>('conversation_id')!;

    final manager = $$AiConversationsTableTableManager(
      $_db,
      $_db.aiConversations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_conversationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AiMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $AiMessagesTable> {
  $$AiMessagesTableFilterComposer({
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

  ColumnFilters<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get failureReason => $composableBuilder(
    column: $table.failureReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groundingRefsJson => $composableBuilder(
    column: $table.groundingRefsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AiConversationsTableFilterComposer get conversationId {
    final $$AiConversationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.aiConversations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AiConversationsTableFilterComposer(
            $db: $db,
            $table: $db.aiConversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AiMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $AiMessagesTable> {
  $$AiMessagesTableOrderingComposer({
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

  ColumnOrderings<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failureReason => $composableBuilder(
    column: $table.failureReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groundingRefsJson => $composableBuilder(
    column: $table.groundingRefsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AiConversationsTableOrderingComposer get conversationId {
    final $$AiConversationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.aiConversations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AiConversationsTableOrderingComposer(
            $db: $db,
            $table: $db.aiConversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AiMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiMessagesTable> {
  $$AiMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sender =>
      $composableBuilder(column: $table.sender, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get failureReason => $composableBuilder(
    column: $table.failureReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get groundingRefsJson => $composableBuilder(
    column: $table.groundingRefsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$AiConversationsTableAnnotationComposer get conversationId {
    final $$AiConversationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.aiConversations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AiConversationsTableAnnotationComposer(
            $db: $db,
            $table: $db.aiConversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AiMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AiMessagesTable,
          AiMessageRow,
          $$AiMessagesTableFilterComposer,
          $$AiMessagesTableOrderingComposer,
          $$AiMessagesTableAnnotationComposer,
          $$AiMessagesTableCreateCompanionBuilder,
          $$AiMessagesTableUpdateCompanionBuilder,
          (AiMessageRow, $$AiMessagesTableReferences),
          AiMessageRow,
          PrefetchHooks Function({bool conversationId})
        > {
  $$AiMessagesTableTableManager(_$AppDatabase db, $AiMessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<String> sender = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> failureReason = const Value.absent(),
                Value<String?> groundingRefsJson = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AiMessagesCompanion(
                id: id,
                conversationId: conversationId,
                sender: sender,
                content: content,
                status: status,
                failureReason: failureReason,
                groundingRefsJson: groundingRefsJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String conversationId,
                required String sender,
                required String content,
                required String status,
                Value<String?> failureReason = const Value.absent(),
                Value<String?> groundingRefsJson = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AiMessagesCompanion.insert(
                id: id,
                conversationId: conversationId,
                sender: sender,
                content: content,
                status: status,
                failureReason: failureReason,
                groundingRefsJson: groundingRefsJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AiMessagesTable, AiMessageRow>(table),
                  $$AiMessagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({conversationId = false}) {
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
                    if (conversationId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.conversationId,
                                referencedTable: $$AiMessagesTableReferences
                                    ._conversationIdTable(db),
                                referencedColumn: $$AiMessagesTableReferences
                                    ._conversationIdTable(db)
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

typedef $$AiMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AiMessagesTable,
      AiMessageRow,
      $$AiMessagesTableFilterComposer,
      $$AiMessagesTableOrderingComposer,
      $$AiMessagesTableAnnotationComposer,
      $$AiMessagesTableCreateCompanionBuilder,
      $$AiMessagesTableUpdateCompanionBuilder,
      (AiMessageRow, $$AiMessagesTableReferences),
      AiMessageRow,
      PrefetchHooks Function({bool conversationId})
    >;
typedef $$AiSettingsTableCreateCompanionBuilder =
    AiSettingsCompanion Function({
      required String id,
      Value<bool> isEnabled,
      Value<String?> providerId,
      Value<bool> hasStoredCredential,
      Value<int?> consentAcceptedAt,
      required int updatedAt,
      Value<String?> lastObservationKey,
      Value<int> rowid,
    });
typedef $$AiSettingsTableUpdateCompanionBuilder =
    AiSettingsCompanion Function({
      Value<String> id,
      Value<bool> isEnabled,
      Value<String?> providerId,
      Value<bool> hasStoredCredential,
      Value<int?> consentAcceptedAt,
      Value<int> updatedAt,
      Value<String?> lastObservationKey,
      Value<int> rowid,
    });

class $$AiSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AiSettingsTable> {
  $$AiSettingsTableFilterComposer({
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

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasStoredCredential => $composableBuilder(
    column: $table.hasStoredCredential,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get consentAcceptedAt => $composableBuilder(
    column: $table.consentAcceptedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastObservationKey => $composableBuilder(
    column: $table.lastObservationKey,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AiSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AiSettingsTable> {
  $$AiSettingsTableOrderingComposer({
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

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasStoredCredential => $composableBuilder(
    column: $table.hasStoredCredential,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get consentAcceptedAt => $composableBuilder(
    column: $table.consentAcceptedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastObservationKey => $composableBuilder(
    column: $table.lastObservationKey,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AiSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiSettingsTable> {
  $$AiSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasStoredCredential => $composableBuilder(
    column: $table.hasStoredCredential,
    builder: (column) => column,
  );

  GeneratedColumn<int> get consentAcceptedAt => $composableBuilder(
    column: $table.consentAcceptedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get lastObservationKey => $composableBuilder(
    column: $table.lastObservationKey,
    builder: (column) => column,
  );
}

class $$AiSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AiSettingsTable,
          AiSettingsRow,
          $$AiSettingsTableFilterComposer,
          $$AiSettingsTableOrderingComposer,
          $$AiSettingsTableAnnotationComposer,
          $$AiSettingsTableCreateCompanionBuilder,
          $$AiSettingsTableUpdateCompanionBuilder,
          (
            AiSettingsRow,
            BaseReferences<_$AppDatabase, $AiSettingsTable, AiSettingsRow>,
          ),
          AiSettingsRow,
          PrefetchHooks Function()
        > {
  $$AiSettingsTableTableManager(_$AppDatabase db, $AiSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<String?> providerId = const Value.absent(),
                Value<bool> hasStoredCredential = const Value.absent(),
                Value<int?> consentAcceptedAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String?> lastObservationKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AiSettingsCompanion(
                id: id,
                isEnabled: isEnabled,
                providerId: providerId,
                hasStoredCredential: hasStoredCredential,
                consentAcceptedAt: consentAcceptedAt,
                updatedAt: updatedAt,
                lastObservationKey: lastObservationKey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<bool> isEnabled = const Value.absent(),
                Value<String?> providerId = const Value.absent(),
                Value<bool> hasStoredCredential = const Value.absent(),
                Value<int?> consentAcceptedAt = const Value.absent(),
                required int updatedAt,
                Value<String?> lastObservationKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AiSettingsCompanion.insert(
                id: id,
                isEnabled: isEnabled,
                providerId: providerId,
                hasStoredCredential: hasStoredCredential,
                consentAcceptedAt: consentAcceptedAt,
                updatedAt: updatedAt,
                lastObservationKey: lastObservationKey,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AiSettingsTable, AiSettingsRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AiSettingsTable,
                    AiSettingsRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AiSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AiSettingsTable,
      AiSettingsRow,
      $$AiSettingsTableFilterComposer,
      $$AiSettingsTableOrderingComposer,
      $$AiSettingsTableAnnotationComposer,
      $$AiSettingsTableCreateCompanionBuilder,
      $$AiSettingsTableUpdateCompanionBuilder,
      (
        AiSettingsRow,
        BaseReferences<_$AppDatabase, $AiSettingsTable, AiSettingsRow>,
      ),
      AiSettingsRow,
      PrefetchHooks Function()
    >;
typedef $$SavingsGoalsTableCreateCompanionBuilder =
    SavingsGoalsCompanion Function({
      required String id,
      required String idempotencyKey,
      required String name,
      Value<String?> type,
      Value<String> currencyCode,
      required int targetAmountMinorUnits,
      Value<int?> monthlyContributionMinorUnits,
      Value<int?> targetDate,
      Value<bool> isArchived,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });
typedef $$SavingsGoalsTableUpdateCompanionBuilder =
    SavingsGoalsCompanion Function({
      Value<String> id,
      Value<String> idempotencyKey,
      Value<String> name,
      Value<String?> type,
      Value<String> currencyCode,
      Value<int> targetAmountMinorUnits,
      Value<int?> monthlyContributionMinorUnits,
      Value<int?> targetDate,
      Value<bool> isArchived,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });

final class $$SavingsGoalsTableReferences
    extends BaseReferences<_$AppDatabase, $SavingsGoalsTable, SavingsGoal> {
  $$SavingsGoalsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $SavingsContributionsTable,
    List<SavingsContribution>
  >
  _savingsContributionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.savingsContributions,
        aliasName: 'savings_goals__id__savings_contributions__goal_id',
      );

  $$SavingsContributionsTableProcessedTableManager
  get savingsContributionsRefs {
    final manager = $$SavingsContributionsTableTableManager(
      $_db,
      $_db.savingsContributions,
    ).filter((f) => f.goalId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _savingsContributionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SavingsGoalsTableFilterComposer
    extends Composer<_$AppDatabase, $SavingsGoalsTable> {
  $$SavingsGoalsTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetAmountMinorUnits => $composableBuilder(
    column: $table.targetAmountMinorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get monthlyContributionMinorUnits => $composableBuilder(
    column: $table.monthlyContributionMinorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetDate => $composableBuilder(
    column: $table.targetDate,
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

  Expression<bool> savingsContributionsRefs(
    Expression<bool> Function($$SavingsContributionsTableFilterComposer f) f,
  ) {
    final $$SavingsContributionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.savingsContributions,
      getReferencedColumn: (t) => t.goalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavingsContributionsTableFilterComposer(
            $db: $db,
            $table: $db.savingsContributions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SavingsGoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavingsGoalsTable> {
  $$SavingsGoalsTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetAmountMinorUnits => $composableBuilder(
    column: $table.targetAmountMinorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get monthlyContributionMinorUnits => $composableBuilder(
    column: $table.monthlyContributionMinorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetDate => $composableBuilder(
    column: $table.targetDate,
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

class $$SavingsGoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavingsGoalsTable> {
  $$SavingsGoalsTableAnnotationComposer({
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

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetAmountMinorUnits => $composableBuilder(
    column: $table.targetAmountMinorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<int> get monthlyContributionMinorUnits => $composableBuilder(
    column: $table.monthlyContributionMinorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => column,
  );

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

  Expression<T> savingsContributionsRefs<T extends Object>(
    Expression<T> Function($$SavingsContributionsTableAnnotationComposer a) f,
  ) {
    final $$SavingsContributionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.savingsContributions,
          getReferencedColumn: (t) => t.goalId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SavingsContributionsTableAnnotationComposer(
                $db: $db,
                $table: $db.savingsContributions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SavingsGoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavingsGoalsTable,
          SavingsGoal,
          $$SavingsGoalsTableFilterComposer,
          $$SavingsGoalsTableOrderingComposer,
          $$SavingsGoalsTableAnnotationComposer,
          $$SavingsGoalsTableCreateCompanionBuilder,
          $$SavingsGoalsTableUpdateCompanionBuilder,
          (SavingsGoal, $$SavingsGoalsTableReferences),
          SavingsGoal,
          PrefetchHooks Function({bool savingsContributionsRefs})
        > {
  $$SavingsGoalsTableTableManager(_$AppDatabase db, $SavingsGoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavingsGoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavingsGoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavingsGoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> type = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<int> targetAmountMinorUnits = const Value.absent(),
                Value<int?> monthlyContributionMinorUnits =
                    const Value.absent(),
                Value<int?> targetDate = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavingsGoalsCompanion(
                id: id,
                idempotencyKey: idempotencyKey,
                name: name,
                type: type,
                currencyCode: currencyCode,
                targetAmountMinorUnits: targetAmountMinorUnits,
                monthlyContributionMinorUnits: monthlyContributionMinorUnits,
                targetDate: targetDate,
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
                Value<String?> type = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                required int targetAmountMinorUnits,
                Value<int?> monthlyContributionMinorUnits =
                    const Value.absent(),
                Value<int?> targetDate = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavingsGoalsCompanion.insert(
                id: id,
                idempotencyKey: idempotencyKey,
                name: name,
                type: type,
                currencyCode: currencyCode,
                targetAmountMinorUnits: targetAmountMinorUnits,
                monthlyContributionMinorUnits: monthlyContributionMinorUnits,
                targetDate: targetDate,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SavingsGoalsTable, SavingsGoal>(table),
                  $$SavingsGoalsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({savingsContributionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (savingsContributionsRefs) db.savingsContributions,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (savingsContributionsRefs)
                    await $_getPrefetchedData<
                      SavingsGoal,
                      $SavingsGoalsTable,
                      SavingsContribution
                    >(
                      currentTable: table,
                      referencedTable: $$SavingsGoalsTableReferences
                          ._savingsContributionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SavingsGoalsTableReferences(
                            db,
                            table,
                            p0,
                          ).savingsContributionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.goalId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SavingsGoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavingsGoalsTable,
      SavingsGoal,
      $$SavingsGoalsTableFilterComposer,
      $$SavingsGoalsTableOrderingComposer,
      $$SavingsGoalsTableAnnotationComposer,
      $$SavingsGoalsTableCreateCompanionBuilder,
      $$SavingsGoalsTableUpdateCompanionBuilder,
      (SavingsGoal, $$SavingsGoalsTableReferences),
      SavingsGoal,
      PrefetchHooks Function({bool savingsContributionsRefs})
    >;
typedef $$SavingsContributionsTableCreateCompanionBuilder =
    SavingsContributionsCompanion Function({
      required String id,
      required String idempotencyKey,
      required String goalId,
      required String type,
      required int amountMinorUnits,
      required int enteredAmountMinorUnits,
      required String enteredCurrencyCode,
      required int date,
      Value<String?> note,
      required int createdAt,
      Value<int?> editedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });
typedef $$SavingsContributionsTableUpdateCompanionBuilder =
    SavingsContributionsCompanion Function({
      Value<String> id,
      Value<String> idempotencyKey,
      Value<String> goalId,
      Value<String> type,
      Value<int> amountMinorUnits,
      Value<int> enteredAmountMinorUnits,
      Value<String> enteredCurrencyCode,
      Value<int> date,
      Value<String?> note,
      Value<int> createdAt,
      Value<int?> editedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });

final class $$SavingsContributionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SavingsContributionsTable,
          SavingsContribution
        > {
  $$SavingsContributionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SavingsGoalsTable _goalIdTable(_$AppDatabase db) => db.savingsGoals
      .createAlias('savings_contributions__goal_id__savings_goals__id');

  $$SavingsGoalsTableProcessedTableManager get goalId {
    final $_column = $_itemColumn<String>('goal_id')!;

    final manager = $$SavingsGoalsTableTableManager(
      $_db,
      $_db.savingsGoals,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_goalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $SavingsContributionAuditsTable,
    List<SavingsContributionAudit>
  >
  _savingsContributionAuditsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.savingsContributionAudits,
    aliasName:
        'savings_contributions__id__savings_contribution_audits__contribution_id',
  );

  $$SavingsContributionAuditsTableProcessedTableManager
  get savingsContributionAuditsRefs {
    final manager = $$SavingsContributionAuditsTableTableManager(
      $_db,
      $_db.savingsContributionAudits,
    ).filter((f) => f.contributionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _savingsContributionAuditsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SavingsContributionsTableFilterComposer
    extends Composer<_$AppDatabase, $SavingsContributionsTable> {
  $$SavingsContributionsTableFilterComposer({
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

  ColumnFilters<int> get enteredAmountMinorUnits => $composableBuilder(
    column: $table.enteredAmountMinorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get enteredCurrencyCode => $composableBuilder(
    column: $table.enteredCurrencyCode,
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

  $$SavingsGoalsTableFilterComposer get goalId {
    final $$SavingsGoalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.savingsGoals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavingsGoalsTableFilterComposer(
            $db: $db,
            $table: $db.savingsGoals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> savingsContributionAuditsRefs(
    Expression<bool> Function($$SavingsContributionAuditsTableFilterComposer f)
    f,
  ) {
    final $$SavingsContributionAuditsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.savingsContributionAudits,
          getReferencedColumn: (t) => t.contributionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SavingsContributionAuditsTableFilterComposer(
                $db: $db,
                $table: $db.savingsContributionAudits,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SavingsContributionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavingsContributionsTable> {
  $$SavingsContributionsTableOrderingComposer({
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

  ColumnOrderings<int> get enteredAmountMinorUnits => $composableBuilder(
    column: $table.enteredAmountMinorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enteredCurrencyCode => $composableBuilder(
    column: $table.enteredCurrencyCode,
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

  $$SavingsGoalsTableOrderingComposer get goalId {
    final $$SavingsGoalsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.savingsGoals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavingsGoalsTableOrderingComposer(
            $db: $db,
            $table: $db.savingsGoals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SavingsContributionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavingsContributionsTable> {
  $$SavingsContributionsTableAnnotationComposer({
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

  GeneratedColumn<int> get enteredAmountMinorUnits => $composableBuilder(
    column: $table.enteredAmountMinorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get enteredCurrencyCode => $composableBuilder(
    column: $table.enteredCurrencyCode,
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

  $$SavingsGoalsTableAnnotationComposer get goalId {
    final $$SavingsGoalsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.savingsGoals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavingsGoalsTableAnnotationComposer(
            $db: $db,
            $table: $db.savingsGoals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> savingsContributionAuditsRefs<T extends Object>(
    Expression<T> Function($$SavingsContributionAuditsTableAnnotationComposer a)
    f,
  ) {
    final $$SavingsContributionAuditsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.savingsContributionAudits,
          getReferencedColumn: (t) => t.contributionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SavingsContributionAuditsTableAnnotationComposer(
                $db: $db,
                $table: $db.savingsContributionAudits,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SavingsContributionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavingsContributionsTable,
          SavingsContribution,
          $$SavingsContributionsTableFilterComposer,
          $$SavingsContributionsTableOrderingComposer,
          $$SavingsContributionsTableAnnotationComposer,
          $$SavingsContributionsTableCreateCompanionBuilder,
          $$SavingsContributionsTableUpdateCompanionBuilder,
          (SavingsContribution, $$SavingsContributionsTableReferences),
          SavingsContribution,
          PrefetchHooks Function({
            bool goalId,
            bool savingsContributionAuditsRefs,
          })
        > {
  $$SavingsContributionsTableTableManager(
    _$AppDatabase db,
    $SavingsContributionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavingsContributionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavingsContributionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SavingsContributionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String> goalId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> amountMinorUnits = const Value.absent(),
                Value<int> enteredAmountMinorUnits = const Value.absent(),
                Value<String> enteredCurrencyCode = const Value.absent(),
                Value<int> date = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> editedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavingsContributionsCompanion(
                id: id,
                idempotencyKey: idempotencyKey,
                goalId: goalId,
                type: type,
                amountMinorUnits: amountMinorUnits,
                enteredAmountMinorUnits: enteredAmountMinorUnits,
                enteredCurrencyCode: enteredCurrencyCode,
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
                required String goalId,
                required String type,
                required int amountMinorUnits,
                required int enteredAmountMinorUnits,
                required String enteredCurrencyCode,
                required int date,
                Value<String?> note = const Value.absent(),
                required int createdAt,
                Value<int?> editedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavingsContributionsCompanion.insert(
                id: id,
                idempotencyKey: idempotencyKey,
                goalId: goalId,
                type: type,
                amountMinorUnits: amountMinorUnits,
                enteredAmountMinorUnits: enteredAmountMinorUnits,
                enteredCurrencyCode: enteredCurrencyCode,
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
                  e.readTable<$SavingsContributionsTable, SavingsContribution>(
                    table,
                  ),
                  $$SavingsContributionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({goalId = false, savingsContributionAuditsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (savingsContributionAuditsRefs)
                      db.savingsContributionAudits,
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
                        if (goalId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.goalId,
                                    referencedTable:
                                        $$SavingsContributionsTableReferences
                                            ._goalIdTable(db),
                                    referencedColumn:
                                        $$SavingsContributionsTableReferences
                                            ._goalIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (savingsContributionAuditsRefs)
                        await $_getPrefetchedData<
                          SavingsContribution,
                          $SavingsContributionsTable,
                          SavingsContributionAudit
                        >(
                          currentTable: table,
                          referencedTable: $$SavingsContributionsTableReferences
                              ._savingsContributionAuditsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SavingsContributionsTableReferences(
                                db,
                                table,
                                p0,
                              ).savingsContributionAuditsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.contributionId == item.id,
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

typedef $$SavingsContributionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavingsContributionsTable,
      SavingsContribution,
      $$SavingsContributionsTableFilterComposer,
      $$SavingsContributionsTableOrderingComposer,
      $$SavingsContributionsTableAnnotationComposer,
      $$SavingsContributionsTableCreateCompanionBuilder,
      $$SavingsContributionsTableUpdateCompanionBuilder,
      (SavingsContribution, $$SavingsContributionsTableReferences),
      SavingsContribution,
      PrefetchHooks Function({bool goalId, bool savingsContributionAuditsRefs})
    >;
typedef $$SavingsContributionAuditsTableCreateCompanionBuilder =
    SavingsContributionAuditsCompanion Function({
      required String id,
      required String contributionId,
      required String changeType,
      required String previousValuesJson,
      required int changedAt,
      Value<int> rowid,
    });
typedef $$SavingsContributionAuditsTableUpdateCompanionBuilder =
    SavingsContributionAuditsCompanion Function({
      Value<String> id,
      Value<String> contributionId,
      Value<String> changeType,
      Value<String> previousValuesJson,
      Value<int> changedAt,
      Value<int> rowid,
    });

final class $$SavingsContributionAuditsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SavingsContributionAuditsTable,
          SavingsContributionAudit
        > {
  $$SavingsContributionAuditsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SavingsContributionsTable _contributionIdTable(
    _$AppDatabase db,
  ) => db.savingsContributions.createAlias(
    'savings_contribution_audits__contribution_id__savings_contributions__id',
  );

  $$SavingsContributionsTableProcessedTableManager get contributionId {
    final $_column = $_itemColumn<String>('contribution_id')!;

    final manager = $$SavingsContributionsTableTableManager(
      $_db,
      $_db.savingsContributions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contributionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SavingsContributionAuditsTableFilterComposer
    extends Composer<_$AppDatabase, $SavingsContributionAuditsTable> {
  $$SavingsContributionAuditsTableFilterComposer({
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

  $$SavingsContributionsTableFilterComposer get contributionId {
    final $$SavingsContributionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contributionId,
      referencedTable: $db.savingsContributions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavingsContributionsTableFilterComposer(
            $db: $db,
            $table: $db.savingsContributions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SavingsContributionAuditsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavingsContributionAuditsTable> {
  $$SavingsContributionAuditsTableOrderingComposer({
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

  $$SavingsContributionsTableOrderingComposer get contributionId {
    final $$SavingsContributionsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.contributionId,
          referencedTable: $db.savingsContributions,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SavingsContributionsTableOrderingComposer(
                $db: $db,
                $table: $db.savingsContributions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$SavingsContributionAuditsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavingsContributionAuditsTable> {
  $$SavingsContributionAuditsTableAnnotationComposer({
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

  $$SavingsContributionsTableAnnotationComposer get contributionId {
    final $$SavingsContributionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.contributionId,
          referencedTable: $db.savingsContributions,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SavingsContributionsTableAnnotationComposer(
                $db: $db,
                $table: $db.savingsContributions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$SavingsContributionAuditsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavingsContributionAuditsTable,
          SavingsContributionAudit,
          $$SavingsContributionAuditsTableFilterComposer,
          $$SavingsContributionAuditsTableOrderingComposer,
          $$SavingsContributionAuditsTableAnnotationComposer,
          $$SavingsContributionAuditsTableCreateCompanionBuilder,
          $$SavingsContributionAuditsTableUpdateCompanionBuilder,
          (
            SavingsContributionAudit,
            $$SavingsContributionAuditsTableReferences,
          ),
          SavingsContributionAudit,
          PrefetchHooks Function({bool contributionId})
        > {
  $$SavingsContributionAuditsTableTableManager(
    _$AppDatabase db,
    $SavingsContributionAuditsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavingsContributionAuditsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$SavingsContributionAuditsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SavingsContributionAuditsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> contributionId = const Value.absent(),
                Value<String> changeType = const Value.absent(),
                Value<String> previousValuesJson = const Value.absent(),
                Value<int> changedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavingsContributionAuditsCompanion(
                id: id,
                contributionId: contributionId,
                changeType: changeType,
                previousValuesJson: previousValuesJson,
                changedAt: changedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String contributionId,
                required String changeType,
                required String previousValuesJson,
                required int changedAt,
                Value<int> rowid = const Value.absent(),
              }) => SavingsContributionAuditsCompanion.insert(
                id: id,
                contributionId: contributionId,
                changeType: changeType,
                previousValuesJson: previousValuesJson,
                changedAt: changedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $SavingsContributionAuditsTable,
                    SavingsContributionAudit
                  >(table),
                  $$SavingsContributionAuditsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({contributionId = false}) {
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
                    if (contributionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.contributionId,
                                referencedTable:
                                    $$SavingsContributionAuditsTableReferences
                                        ._contributionIdTable(db),
                                referencedColumn:
                                    $$SavingsContributionAuditsTableReferences
                                        ._contributionIdTable(db)
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

typedef $$SavingsContributionAuditsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavingsContributionAuditsTable,
      SavingsContributionAudit,
      $$SavingsContributionAuditsTableFilterComposer,
      $$SavingsContributionAuditsTableOrderingComposer,
      $$SavingsContributionAuditsTableAnnotationComposer,
      $$SavingsContributionAuditsTableCreateCompanionBuilder,
      $$SavingsContributionAuditsTableUpdateCompanionBuilder,
      (SavingsContributionAudit, $$SavingsContributionAuditsTableReferences),
      SavingsContributionAudit,
      PrefetchHooks Function({bool contributionId})
    >;
typedef $$FinanceEntryAuditsTableCreateCompanionBuilder =
    FinanceEntryAuditsCompanion Function({
      required String id,
      required String financeEntryId,
      required String changeType,
      Value<String?> previousValuesJson,
      required int changedAt,
      Value<int> rowid,
    });
typedef $$FinanceEntryAuditsTableUpdateCompanionBuilder =
    FinanceEntryAuditsCompanion Function({
      Value<String> id,
      Value<String> financeEntryId,
      Value<String> changeType,
      Value<String?> previousValuesJson,
      Value<int> changedAt,
      Value<int> rowid,
    });

final class $$FinanceEntryAuditsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $FinanceEntryAuditsTable,
          FinanceEntryAudit
        > {
  $$FinanceEntryAuditsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FinanceEntriesTable _financeEntryIdTable(_$AppDatabase db) =>
      db.financeEntries.createAlias(
        'finance_entry_audits__finance_entry_id__finance_entries__id',
      );

  $$FinanceEntriesTableProcessedTableManager get financeEntryId {
    final $_column = $_itemColumn<String>('finance_entry_id')!;

    final manager = $$FinanceEntriesTableTableManager(
      $_db,
      $_db.financeEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_financeEntryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FinanceEntryAuditsTableFilterComposer
    extends Composer<_$AppDatabase, $FinanceEntryAuditsTable> {
  $$FinanceEntryAuditsTableFilterComposer({
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

  $$FinanceEntriesTableFilterComposer get financeEntryId {
    final $$FinanceEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.financeEntryId,
      referencedTable: $db.financeEntries,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }
}

class $$FinanceEntryAuditsTableOrderingComposer
    extends Composer<_$AppDatabase, $FinanceEntryAuditsTable> {
  $$FinanceEntryAuditsTableOrderingComposer({
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

  $$FinanceEntriesTableOrderingComposer get financeEntryId {
    final $$FinanceEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.financeEntryId,
      referencedTable: $db.financeEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinanceEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.financeEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FinanceEntryAuditsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FinanceEntryAuditsTable> {
  $$FinanceEntryAuditsTableAnnotationComposer({
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

  $$FinanceEntriesTableAnnotationComposer get financeEntryId {
    final $$FinanceEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.financeEntryId,
      referencedTable: $db.financeEntries,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }
}

class $$FinanceEntryAuditsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FinanceEntryAuditsTable,
          FinanceEntryAudit,
          $$FinanceEntryAuditsTableFilterComposer,
          $$FinanceEntryAuditsTableOrderingComposer,
          $$FinanceEntryAuditsTableAnnotationComposer,
          $$FinanceEntryAuditsTableCreateCompanionBuilder,
          $$FinanceEntryAuditsTableUpdateCompanionBuilder,
          (FinanceEntryAudit, $$FinanceEntryAuditsTableReferences),
          FinanceEntryAudit,
          PrefetchHooks Function({bool financeEntryId})
        > {
  $$FinanceEntryAuditsTableTableManager(
    _$AppDatabase db,
    $FinanceEntryAuditsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FinanceEntryAuditsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FinanceEntryAuditsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FinanceEntryAuditsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> financeEntryId = const Value.absent(),
                Value<String> changeType = const Value.absent(),
                Value<String?> previousValuesJson = const Value.absent(),
                Value<int> changedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FinanceEntryAuditsCompanion(
                id: id,
                financeEntryId: financeEntryId,
                changeType: changeType,
                previousValuesJson: previousValuesJson,
                changedAt: changedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String financeEntryId,
                required String changeType,
                Value<String?> previousValuesJson = const Value.absent(),
                required int changedAt,
                Value<int> rowid = const Value.absent(),
              }) => FinanceEntryAuditsCompanion.insert(
                id: id,
                financeEntryId: financeEntryId,
                changeType: changeType,
                previousValuesJson: previousValuesJson,
                changedAt: changedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FinanceEntryAuditsTable, FinanceEntryAudit>(
                    table,
                  ),
                  $$FinanceEntryAuditsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({financeEntryId = false}) {
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
                    if (financeEntryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.financeEntryId,
                                referencedTable:
                                    $$FinanceEntryAuditsTableReferences
                                        ._financeEntryIdTable(db),
                                referencedColumn:
                                    $$FinanceEntryAuditsTableReferences
                                        ._financeEntryIdTable(db)
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

typedef $$FinanceEntryAuditsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FinanceEntryAuditsTable,
      FinanceEntryAudit,
      $$FinanceEntryAuditsTableFilterComposer,
      $$FinanceEntryAuditsTableOrderingComposer,
      $$FinanceEntryAuditsTableAnnotationComposer,
      $$FinanceEntryAuditsTableCreateCompanionBuilder,
      $$FinanceEntryAuditsTableUpdateCompanionBuilder,
      (FinanceEntryAudit, $$FinanceEntryAuditsTableReferences),
      FinanceEntryAudit,
      PrefetchHooks Function({bool financeEntryId})
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
  $$NotificationPreferencesTableTableManager get notificationPreferences =>
      $$NotificationPreferencesTableTableManager(
        _db,
        _db.notificationPreferences,
      );
  $$NotificationHistoryTableTableManager get notificationHistory =>
      $$NotificationHistoryTableTableManager(_db, _db.notificationHistory);
  $$PrimaryCurrencySettingsTableTableManager get primaryCurrencySettings =>
      $$PrimaryCurrencySettingsTableTableManager(
        _db,
        _db.primaryCurrencySettings,
      );
  $$ExchangeRatesTableTableManager get exchangeRates =>
      $$ExchangeRatesTableTableManager(_db, _db.exchangeRates);
  $$SyncOutboxEntriesTableTableManager get syncOutboxEntries =>
      $$SyncOutboxEntriesTableTableManager(_db, _db.syncOutboxEntries);
  $$SyncRecordMetaTableTableManager get syncRecordMeta =>
      $$SyncRecordMetaTableTableManager(_db, _db.syncRecordMeta);
  $$SyncConflictsTableTableManager get syncConflicts =>
      $$SyncConflictsTableTableManager(_db, _db.syncConflicts);
  $$ConflictResolutionsTableTableManager get conflictResolutions =>
      $$ConflictResolutionsTableTableManager(_db, _db.conflictResolutions);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
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
  $$AiConversationsTableTableManager get aiConversations =>
      $$AiConversationsTableTableManager(_db, _db.aiConversations);
  $$AiMessagesTableTableManager get aiMessages =>
      $$AiMessagesTableTableManager(_db, _db.aiMessages);
  $$AiSettingsTableTableManager get aiSettings =>
      $$AiSettingsTableTableManager(_db, _db.aiSettings);
  $$SavingsGoalsTableTableManager get savingsGoals =>
      $$SavingsGoalsTableTableManager(_db, _db.savingsGoals);
  $$SavingsContributionsTableTableManager get savingsContributions =>
      $$SavingsContributionsTableTableManager(_db, _db.savingsContributions);
  $$SavingsContributionAuditsTableTableManager get savingsContributionAudits =>
      $$SavingsContributionAuditsTableTableManager(
        _db,
        _db.savingsContributionAudits,
      );
  $$FinanceEntryAuditsTableTableManager get financeEntryAudits =>
      $$FinanceEntryAuditsTableTableManager(_db, _db.financeEntryAudits);
}
