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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PeopleTable people = $PeopleTable(this);
  late final $MoneyTransactionsTable moneyTransactions =
      $MoneyTransactionsTable(this);
  late final $TransactionAuditEntriesTable transactionAuditEntries =
      $TransactionAuditEntriesTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $OnboardingStatusTable onboardingStatus = $OnboardingStatusTable(
    this,
  );
  late final Index idxPeopleNormalizedName = Index(
    'idx_people_normalized_name',
    'CREATE INDEX idx_people_normalized_name ON people (normalized_name)',
  );
  late final Index idxTransactionsPersonId = Index(
    'idx_transactions_person_id',
    'CREATE INDEX idx_transactions_person_id ON money_transactions (person_id, deleted_at)',
  );
  late final Index idxAuditTransactionId = Index(
    'idx_audit_transaction_id',
    'CREATE INDEX idx_audit_transaction_id ON transaction_audit_entries (transaction_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    people,
    moneyTransactions,
    transactionAuditEntries,
    appSettings,
    onboardingStatus,
    idxPeopleNormalizedName,
    idxTransactionsPersonId,
    idxAuditTransactionId,
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
        aliasName: $_aliasNameGenerator(
          db.people.id,
          db.moneyTransactions.personId,
        ),
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
          PrefetchHooks Function({bool moneyTransactionsRefs})
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
                (e) =>
                    (e.readTable(table), $$PeopleTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({moneyTransactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (moneyTransactionsRefs) db.moneyTransactions,
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
                      managerFromTypedResult: (p0) => $$PeopleTableReferences(
                        db,
                        table,
                        p0,
                      ).moneyTransactionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.personId == item.id),
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
      PrefetchHooks Function({bool moneyTransactionsRefs})
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

  static $PeopleTable _personIdTable(_$AppDatabase db) => db.people.createAlias(
    $_aliasNameGenerator(db.moneyTransactions.personId, db.people.id),
  );

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

  static MultiTypedResultKey<
    $TransactionAuditEntriesTable,
    List<TransactionAuditEntry>
  >
  _transactionAuditEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.transactionAuditEntries,
        aliasName: $_aliasNameGenerator(
          db.moneyTransactions.id,
          db.transactionAuditEntries.transactionId,
        ),
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
                createdAt: createdAt,
                editedAt: editedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MoneyTransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({personId = false, transactionAuditEntriesRefs = false}) {
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
      PrefetchHooks Function({bool personId, bool transactionAuditEntriesRefs})
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
        $_aliasNameGenerator(
          db.transactionAuditEntries.transactionId,
          db.moneyTransactions.id,
        ),
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
                  e.readTable(table),
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
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
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
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PeopleTableTableManager get people =>
      $$PeopleTableTableManager(_db, _db.people);
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
}
