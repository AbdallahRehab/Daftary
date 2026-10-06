import 'dart:convert';
import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;

import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../../../budgets/domain/entities/budget.dart';
import '../../../budgets/domain/entities/budget_category_allocation.dart';
import '../../../budgets/domain/repositories/budgets_repository.dart';
import '../../../currency/domain/entities/exchange_rate.dart';
import '../../../currency/domain/repositories/currency_repository.dart';
import '../../../finance/domain/entities/category.dart';
import '../../../finance/domain/entities/finance_entry.dart';
import '../../../finance/domain/entities/finance_entry_audit.dart';
import '../../../finance/domain/entities/finance_entry_type.dart';
import '../../../finance/domain/repositories/category_repository.dart';
import '../../../finance/domain/repositories/finance_repository.dart';
import '../../../occasions/domain/entities/occasion.dart';
import '../../../occasions/domain/repositories/occasions_repository.dart';
import '../../../people/domain/entities/person.dart';
import '../../../people/domain/repositories/people_repository.dart';
import '../../../savings/domain/entities/savings_contribution_audit.dart';
import '../../../savings/domain/entities/savings_goal_with_contributions.dart';
import '../../../savings/domain/repositories/savings_repository.dart';
import '../../../settings/domain/entities/app_language.dart';
import '../../../settings/domain/entities/app_theme_mode.dart';
import '../../../settings/domain/repositories/settings_repository.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../../../transactions/domain/entities/transaction_audit_entry.dart';
import '../../../transactions/domain/repositories/transactions_repository.dart';
import '../entities/export_result.dart';
import '../services/export_directory_provider.dart';

/// Composes repository reads (research.md Decision 2) into one
/// section-delimited CSV file (Decision 4) in the app's sandboxed temp
/// directory (contracts/export_user_data.md).
///
/// Read-only, and never transmits anything (FR-012): this only produces a
/// local file — sharing it is a separate, explicit user action through
/// `ShareService`. Adds no repository method of its own.
///
/// 022 D1: after the original five sections it appends occasions (archived
/// included), the occasion contributions (by reference, from the
/// transactions already read), budgets and their allocations, savings goals
/// (archived included) and their entries, exchange rates, and the change
/// history of transactions, savings entries and income/expense entries.
/// Soft-deleted records are left out everywhere, as in the original
/// sections; change history is complete.
@injectable
class ExportUserData {
  const ExportUserData(
    this._peopleRepository,
    this._transactionsRepository,
    this._financeRepository,
    this._categoryRepository,
    this._settingsRepository,
    this._exportDirectory,
    this._occasionsRepository,
    this._budgetsRepository,
    this._savingsRepository,
    this._currencyRepository,
  );

  final PeopleRepository _peopleRepository;
  final TransactionsRepository _transactionsRepository;
  final FinanceRepository _financeRepository;
  final CategoryRepository _categoryRepository;
  final SettingsRepository _settingsRepository;
  final ExportDirectoryProvider _exportDirectory;
  final OccasionsRepository _occasionsRepository;
  final BudgetsRepository _budgetsRepository;
  final SavingsRepository _savingsRepository;
  final CurrencyRepository _currencyRepository;

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

    // 022 D1: the sections appended after the original five.
    final occasionsResult = await _occasionsRepository.getOccasionsList(
      includeArchived: true,
    );
    if (occasionsResult case Left(value: final failure)) return Left(failure);
    final budgetsResult = await _budgetsRepository.getAllBudgets();
    if (budgetsResult case Left(value: final failure)) return Left(failure);
    final allocationsResult = await _budgetsRepository.getAllAllocations();
    if (allocationsResult case Left(value: final failure)) {
      return Left(failure);
    }
    final goalsResult = await _savingsRepository.getAllGoalsWithContributions();
    if (goalsResult case Left(value: final failure)) return Left(failure);
    final ratesResult = await _currencyRepository.getExchangeRates();
    if (ratesResult case Left(value: final failure)) return Left(failure);
    final transactionChanges = await _transactionsRepository
        .getAllAuditEntries();
    if (transactionChanges case Left(value: final failure)) {
      return Left(failure);
    }
    final savingsChanges = await _savingsRepository.getAllContributionAudits();
    if (savingsChanges case Left(value: final failure)) return Left(failure);
    final entryChanges = await _financeRepository.getAllEntryAudits();
    if (entryChanges case Left(value: final failure)) return Left(failure);

    return Right(
      _ExportData(
        occasions: _rows(occasionsResult),
        budgets: _rows(budgetsResult),
        allocations: _rows(allocationsResult),
        goals: _rows(goalsResult),
        rates: _rows(ratesResult),
        transactionChanges: _rows(transactionChanges),
        savingsChanges: _rows(savingsChanges),
        entryChanges: _rows(entryChanges),
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
      ..._appendedSections(data, categoryNames),
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

  /// The sections 022 D1 appends after the original five. Money is written
  /// as exact minor units plus a two-decimal major-unit column, like the
  /// original sections.
  Map<ExportSection, (List<String>, List<List<Object?>>)> _appendedSections(
    _ExportData data,
    Map<String, String> categoryNames,
  ) {
    final goalCurrency = {
      for (final g in data.goals) g.goal.id: g.goal.currency.code,
    };
    String major(int? minor) => minor == null
        ? ''
        : _majorUnits(Money.fromMinorUnits(minor, Currency.egp));
    return {
      ExportSection.occasions: (
        const [
          'id',
          'name',
          'date',
          'type',
          'notes',
          'is_archived',
          'created_at',
          'updated_at',
        ],
        [
          for (final o in data.occasions)
            [
              o.id,
              o.name,
              o.date,
              o.type,
              o.notes,
              o.isArchived,
              o.createdAt,
              o.updatedAt,
            ],
        ],
      ),
      ExportSection.occasionContributions: (
        const [
          'transaction_id',
          'occasion_id',
          'person_id',
          'counts_toward_balance',
        ],
        [
          for (final tx in data.transactions)
            if (tx.occasionId != null)
              [tx.id, tx.occasionId, tx.personId, tx.countsTowardBalance],
        ],
      ),
      ExportSection.budgets: (
        const [
          'id',
          'month',
          'expected_income_minor_units',
          'expected_income',
          'currency_code',
          'created_at',
          'updated_at',
        ],
        [
          for (final b in data.budgets)
            [
              b.id,
              b.month,
              b.expectedIncomeMinorUnits,
              major(b.expectedIncomeMinorUnits),
              b.currency.code,
              b.createdAt,
              b.updatedAt,
            ],
        ],
      ),
      ExportSection.budgetAllocations: (
        const [
          'id',
          'budget_id',
          'category_id',
          'category_name',
          'planned_amount_minor_units',
          'planned_amount',
          'currency_code',
          'created_at',
          'updated_at',
        ],
        [
          for (final a in data.allocations)
            [
              a.id,
              a.budgetId,
              a.categoryId,
              categoryNames[a.categoryId],
              a.plannedAmountMinorUnits,
              major(a.plannedAmountMinorUnits),
              a.currency.code,
              a.createdAt,
              a.updatedAt,
            ],
        ],
      ),
      ExportSection.savingsGoals: (
        const [
          'id',
          'name',
          'type',
          'currency_code',
          'target_amount_minor_units',
          'target_amount',
          'monthly_contribution_minor_units',
          'monthly_contribution',
          'target_date',
          'is_archived',
          'created_at',
          'updated_at',
        ],
        [
          for (final g in data.goals.map((g) => g.goal))
            [
              g.id,
              g.name,
              g.type,
              g.currency.code,
              g.targetAmountMinorUnits,
              major(g.targetAmountMinorUnits),
              g.monthlyContributionMinorUnits,
              major(g.monthlyContributionMinorUnits),
              g.targetDate,
              g.isArchived,
              g.createdAt,
              g.updatedAt,
            ],
        ],
      ),
      ExportSection.savingsContributions: (
        const [
          'id',
          'goal_id',
          'type',
          'amount_minor_units',
          'amount',
          'currency_code',
          'entered_amount_minor_units',
          'entered_amount',
          'entered_currency_code',
          'date',
          'note',
          'created_at',
          'edited_at',
        ],
        [
          for (final g in data.goals)
            for (final c in g.contributions)
              [
                c.id,
                c.goalId,
                c.type.value,
                c.amountMinorUnits,
                major(c.amountMinorUnits),
                goalCurrency[c.goalId],
                c.enteredAmountMinorUnits,
                major(c.enteredAmountMinorUnits),
                c.enteredCurrency.code,
                c.date,
                c.note,
                c.createdAt,
                c.editedAt,
              ],
        ],
      ),
      ExportSection.exchangeRates: (
        const [
          'currency_code',
          'relative_to_currency_code',
          'rate_micros',
          'last_updated_at',
        ],
        [
          for (final r in data.rates)
            [r.currency.code, r.relativeTo.code, r.rateMicros, r.lastUpdatedAt],
        ],
      ),
      ExportSection.transactionChanges: (
        _changeHeader('transaction_id'),
        [
          for (final c in data.transactionChanges)
            [
              c.id,
              c.transactionId,
              c.changeType.name,
              _canonicalJson(c.previousValuesJson),
              c.changedAt,
            ],
        ],
      ),
      ExportSection.savingsContributionChanges: (
        _changeHeader('contribution_id'),
        [
          for (final c in data.savingsChanges)
            [
              c.id,
              c.contributionId,
              c.changeType.value,
              _canonicalJson(c.previousValuesJson),
              c.changedAt,
            ],
        ],
      ),
      ExportSection.financeEntryChanges: (
        _changeHeader('finance_entry_id'),
        [
          for (final c in data.entryChanges)
            [
              c.id,
              c.financeEntryId,
              c.changeType.value,
              _canonicalJson(c.previousValuesJson),
              c.changedAt,
            ],
        ],
      ),
    };
  }

  /// Re-encodes a stored JSON object with its keys sorted, so the same
  /// change exports identically whichever device wrote it. Anything that is
  /// not valid JSON is written as it was stored.
  static String? _canonicalJson(String? json) {
    if (json == null) return null;
    try {
      return jsonEncode(_sorted(jsonDecode(json)));
    } on FormatException {
      return json;
    }
  }

  static Object? _sorted(Object? value) => switch (value) {
    Map() => {
      for (final key in (value.keys.cast<String>().toList()..sort()))
        key: _sorted(value[key]),
    },
    List() => [for (final item in value) _sorted(item)],
    _ => value,
  };

  static List<String> _changeHeader(String recordColumn) => [
    'id',
    recordColumn,
    'change_type',
    'previous_values_json',
    'changed_at',
  ];

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
    required this.occasions,
    required this.budgets,
    required this.allocations,
    required this.goals,
    required this.rates,
    required this.transactionChanges,
    required this.savingsChanges,
    required this.entryChanges,
    required this.people,
    required this.transactions,
    required this.entries,
    required this.categories,
    required this.language,
    required this.themeMode,
  });

  final List<Occasion> occasions;
  final List<Budget> budgets;
  final List<BudgetCategoryAllocation> allocations;
  final List<SavingsGoalWithContributions> goals;
  final List<ExchangeRate> rates;
  final List<TransactionAuditEntry> transactionChanges;
  final List<SavingsContributionAudit> savingsChanges;
  final List<FinanceEntryAudit> entryChanges;
  final List<Person> people;
  final List<MoneyTransaction> transactions;
  final List<FinanceEntry> entries;
  final List<Category> categories;
  final AppLanguage? language;
  final AppThemeMode? themeMode;
}
