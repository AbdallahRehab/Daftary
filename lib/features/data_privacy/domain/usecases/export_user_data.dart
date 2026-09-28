import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;

import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../../../finance/domain/entities/category.dart';
import '../../../finance/domain/entities/finance_entry.dart';
import '../../../finance/domain/entities/finance_entry_type.dart';
import '../../../finance/domain/repositories/category_repository.dart';
import '../../../finance/domain/repositories/finance_repository.dart';
import '../../../people/domain/entities/person.dart';
import '../../../people/domain/repositories/people_repository.dart';
import '../../../settings/domain/entities/app_language.dart';
import '../../../settings/domain/entities/app_theme_mode.dart';
import '../../../settings/domain/repositories/settings_repository.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../../../transactions/domain/repositories/transactions_repository.dart';
import '../entities/export_result.dart';
import '../services/export_directory_provider.dart';

/// Composes every existing repository read (research.md Decision 2) into
/// one section-delimited CSV file (Decision 4) in the app's sandboxed temp
/// directory (contracts/export_user_data.md).
///
/// Read-only, and never transmits anything (FR-012): this only produces a
/// local file — sharing it is a separate, explicit user action through
/// `ShareService`. Adds no repository method of its own.
@injectable
class ExportUserData {
  const ExportUserData(
    this._peopleRepository,
    this._transactionsRepository,
    this._financeRepository,
    this._categoryRepository,
    this._settingsRepository,
    this._exportDirectory,
  );

  final PeopleRepository _peopleRepository;
  final TransactionsRepository _transactionsRepository;
  final FinanceRepository _financeRepository;
  final CategoryRepository _categoryRepository;
  final SettingsRepository _settingsRepository;
  final ExportDirectoryProvider _exportDirectory;

  /// Page size used to read finance history to completion.
  static const financePageSize = 500;

  /// Every read happens before anything touches disk, so a failing read
  /// leaves no file at all. The file itself is written under a `.part`
  /// name and only renamed to its final `.csv` name once complete, so a
  /// failed or interrupted write (e.g. low storage) never leaves anything
  /// that could be mistaken for a finished export (FR-011).
  Future<Either<Failure, ExportResult>> call() async {
    return switch (await _readEverything()) {
      Left(value: final failure) => Left(failure),
      Right(value: final data) => await _write(data),
    };
  }

  /// Stops at the first failing read and returns its failure unchanged.
  Future<Either<Failure, _ExportData>> _readEverything() async {
    final active = await _peopleRepository.searchActivePeople();
    if (active case Left(value: final failure)) return Left(failure);
    final archived = await _peopleRepository.searchArchivedPeople();
    if (archived case Left(value: final failure)) return Left(failure);
    final people = [..._rows(active), ..._rows(archived)];

    // Every transaction is reachable through some still-existing person: a
    // person with any transaction can only be archived, never deleted
    // (research.md Decision 2).
    final transactions = <MoneyTransaction>[];
    for (final person in people) {
      final history = await _transactionsRepository.getPersonHistory(person.id);
      if (history case Left(value: final failure)) return Left(failure);
      transactions.addAll(_rows(history));
    }

    final entries = <FinanceEntry>[];
    while (true) {
      final page = await _financeRepository.getHistory(
        limit: financePageSize,
        offset: entries.length,
      );
      if (page case Left(value: final failure)) return Left(failure);
      final rows = _rows(page);
      entries.addAll(rows);
      if (rows.length < financePageSize) break;
    }

    final categories = <Category>[];
    for (final type in FinanceEntryType.values) {
      final result = await _categoryRepository.getCategories(
        type: type,
        includeArchived: true,
      );
      if (result case Left(value: final failure)) return Left(failure);
      categories.addAll(_rows(result));
    }

    final language = await _settingsRepository.getLanguagePreference();
    if (language case Left(value: final failure)) return Left(failure);
    final themeMode = await _settingsRepository.getThemeModePreference();
    if (themeMode case Left(value: final failure)) return Left(failure);

    return Right(
      _ExportData(
        people: people,
        transactions: transactions,
        entries: entries,
        categories: categories,
        language: language.toNullable(),
        themeMode: themeMode.toNullable(),
      ),
    );
  }

  /// The rows of a result already known to be a [Right].
  static List<T> _rows<T>(Either<Failure, List<T>> result) =>
      result.getOrElse((_) => const []);

  Future<Either<Failure, ExportResult>> _write(_ExportData data) async {
    final generatedAt = DateTime.now();
    File? partial;
    try {
      final directory = await _exportDirectory.resolve();
      final finalPath = p.join(
        directory.path,
        'daftary-export-${_fileStamp(generatedAt)}.csv',
      );
      partial = File('$finalPath.part');
      final (content, counts) = _serialize(data);
      await partial.writeAsString(content, flush: true);
      final file = await partial.rename(finalPath);
      return Right(
        ExportResult(
          filePath: file.path,
          generatedAt: generatedAt,
          sectionCounts: counts,
        ),
      );
    } catch (e) {
      try {
        if (partial != null && partial.existsSync()) partial.deleteSync();
      } catch (_) {
        // Best effort — the `.part` suffix already marks it incomplete.
      }
      return Left(CacheFailure('Could not write the export file: $e'));
    }
  }

  (String, Map<String, int>) _serialize(_ExportData data) {
    final categoryNames = {for (final c in data.categories) c.id: c.name};
    final settingsRows = [
      if (data.language case final AppLanguage language)
        ['language', language.code],
      if (data.themeMode case final AppThemeMode mode)
        ['theme_mode', mode.value],
    ];

    final sections = <ExportSection, (List<String>, List<List<Object?>>)>{
      ExportSection.people: (
        const [
          'id',
          'name',
          'phone_number',
          'relationship_tag',
          'notes',
          'avatar_path',
          'is_archived',
          'created_at',
          'updated_at',
        ],
        [
          for (final person in data.people)
            [
              person.id,
              person.name,
              person.phoneNumber,
              person.relationshipTag,
              person.notes,
              person.avatarPath,
              person.isArchived,
              person.createdAt,
              person.updatedAt,
            ],
        ],
      ),
      ExportSection.transactions: (
        const [
          'id',
          'person_id',
          'amount_minor_units',
          'amount',
          'currency_code',
          'direction',
          'kind',
          'date',
          'note',
          'occasion_id',
          'counts_toward_balance',
          'source',
          'ocr_scan_id',
          'created_at',
          'edited_at',
        ],
        [
          for (final tx in data.transactions)
            [
              tx.id,
              tx.personId,
              tx.amount.minorUnits,
              _majorUnits(tx.amount),
              tx.amount.currency.code,
              tx.direction.name,
              tx.kind.name,
              tx.date,
              tx.note,
              tx.occasionId,
              tx.countsTowardBalance,
              tx.source.name,
              tx.ocrScanId,
              tx.createdAt,
              tx.editedAt,
            ],
        ],
      ),
      ExportSection.financeEntries: (
        const [
          'id',
          'type',
          'category_id',
          'category_name',
          'amount_minor_units',
          'amount',
          'currency_code',
          'date',
          'note',
          'created_at',
          'edited_at',
        ],
        [
          for (final entry in data.entries)
            [
              entry.id,
              entry.type.dbValue,
              entry.categoryId,
              categoryNames[entry.categoryId],
              entry.amount.minorUnits,
              _majorUnits(entry.amount),
              entry.amount.currency.code,
              entry.date,
              entry.note,
              entry.createdAt,
              entry.editedAt,
            ],
        ],
      ),
      ExportSection.categories: (
        const [
          'id',
          'name',
          'type',
          'icon',
          'is_default',
          'is_archived',
          'created_at',
          'updated_at',
        ],
        [
          for (final category in data.categories)
            [
              category.id,
              category.name,
              category.type.dbValue,
              category.icon,
              category.isDefault,
              category.isArchived,
              category.createdAt,
              category.updatedAt,
            ],
        ],
      ),
      ExportSection.settings: (const ['key', 'value'], settingsRows),
    };

    // A byte-order mark so spreadsheet tools open Arabic text as UTF-8.
    final buffer = StringBuffer('﻿');
    final counts = <String, int>{};
    for (final section in ExportSection.values) {
      final (header, rows) = sections[section]!;
      if (section != ExportSection.values.first) buffer.write(_eol);
      buffer
        ..write('## ${section.marker}$_eol')
        ..write(_row(header));
      rows.map(_row).forEach(buffer.write);
      counts[section.key] = rows.length;
    }
    return (buffer.toString(), counts);
  }

  static const _eol = '\r\n';

  static String _row(List<Object?> values) =>
      '${values.map(_cell).join(',')}$_eol';

  /// RFC 4180: a value containing a comma, quote, or line break is quoted,
  /// with inner quotes doubled. `null` is an empty cell; dates are ISO 8601.
  static String _cell(Object? value) {
    final text = switch (value) {
      null => '',
      DateTime date => date.toIso8601String(),
      _ => value.toString(),
    };
    if (text.contains(RegExp(r'[",\r\n]'))) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }

  /// Exact two-decimal major units from integer minor units — no floating
  /// point anywhere (constitution Principle VIII). Every catalog currency
  /// has 100 minor units per major (018); the row's `currency_code` column
  /// says which currency it is.
  static String _majorUnits(Money amount) {
    final minor = amount.minorUnits;
    final sign = minor < 0 ? '-' : '';
    final abs = minor.abs();
    final major = abs ~/ Money.minorUnitsPerMajorUnit;
    final fraction = (abs % Money.minorUnitsPerMajorUnit).toString().padLeft(
      2,
      '0',
    );
    return '$sign$major.$fraction';
  }

  static String _fileStamp(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}${two(t.month)}${two(t.day)}-'
        '${two(t.hour)}${two(t.minute)}${two(t.second)}';
  }
}

/// Everything read for one export, gathered before anything is written.
class _ExportData {
  const _ExportData({
    required this.people,
    required this.transactions,
    required this.entries,
    required this.categories,
    required this.language,
    required this.themeMode,
  });

  final List<Person> people;
  final List<MoneyTransaction> transactions;
  final List<FinanceEntry> entries;
  final List<Category> categories;
  final AppLanguage? language;
  final AppThemeMode? themeMode;
}
