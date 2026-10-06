import 'dart:convert';

import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_audit.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/presentation/mappers/finance_entry_audit_row_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  final date = DateTime(2026, 1, 1);
  final l10n = lookupAppLocalizations(const Locale('en'));
  late FinanceEntryAuditRowMapper mapper;

  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar_u_nu_latn');
  });
  setUp(
    () => mapper = FinanceEntryAuditRowMapper(
      l10n: l10n,
      locale: 'en',
      categoryNames: const {'food': 'Food', 'salary': 'Salary'},
    ),
  );

  FinanceEntry current({
    int minor = 45000,
    FinanceEntryType type = FinanceEntryType.expense,
    String categoryId = 'food',
    String? note,
  }) => FinanceEntry(
    id: 'e',
    idempotencyKey: 'k',
    categoryId: categoryId,
    type: type,
    amount: Money.fromMinorUnits(minor, Currency.egp),
    date: date,
    createdAt: date,
    note: note,
  );

  String before({
    Object? dateValue,
    int minor = 30000,
    String code = 'EGP',
    String type = 'expense',
    String categoryId = 'food',
    String? note,
  }) => jsonEncode({
    'amountMinorUnits': minor,
    'currencyCode': code,
    'type': type,
    'categoryId': categoryId,
    'date': dateValue ?? '2026-01-01',
    'note': note,
  });

  FinanceEntryAudit audit(
    String id,
    FinanceAuditChange type,
    int day, {
    String? json,
  }) => FinanceEntryAudit(
    id: id,
    financeEntryId: 'e',
    changeType: type,
    changedAt: DateTime(2026, 1, day, 10),
    previousValuesJson: json,
  );

  test('edit 300 -> 450 shows only the amount, old -> new', () {
    final rows = mapper.rows([
      audit('1', FinanceAuditChange.created, 1),
      audit('2', FinanceAuditChange.edited, 2, json: before()),
    ], current());

    expect(rows[1].label, l10n.changeHistoryEdited);
    expect(rows[1].fields, hasLength(1));
    expect(
      rows[1].fields.single.value,
      l10n.changeHistoryChange(l10n.amountLabel, '300.00 EGP', '450.00 EGP'),
    );
  });

  test('an expense edited into income shows the type and category change '
      '(RF-08)', () {
    final rows = mapper.rows([
      audit('1', FinanceAuditChange.created, 1),
      audit('2', FinanceAuditChange.edited, 2, json: before(minor: 45000)),
    ], current(type: FinanceEntryType.income, categoryId: 'salary'));

    final values = rows[1].fields.map((f) => f.value).toList();
    expect(
      values,
      contains(
        l10n.changeHistoryChange(
          l10n.changeHistoryTypeField,
          l10n.financeTypeExpense,
          l10n.financeTypeIncome,
        ),
      ),
    );
    expect(
      values,
      contains(
        l10n.changeHistoryChange(l10n.financeCategoryLabel, 'Food', 'Salary'),
      ),
    );
    expect(values, hasLength(2));
  });

  test('created shows the initial values; deleted and restored carry none', () {
    final rows = mapper.rows([
      audit('1', FinanceAuditChange.created, 1),
      audit('2', FinanceAuditChange.edited, 2, json: before(note: 'weekly')),
      audit('3', FinanceAuditChange.deleted, 3),
      audit('4', FinanceAuditChange.restored, 4),
    ], current(note: 'weekly'));

    expect(rows.map((r) => r.label), [
      l10n.changeHistoryCreated,
      l10n.changeHistoryEdited,
      l10n.changeHistoryDeleted,
      l10n.changeHistoryRestored,
    ]);
    final created = rows.first.fields.map((f) => f.value);
    expect(created, contains('300.00 EGP'));
    expect(created, contains(l10n.financeTypeExpense));
    expect(created, contains('Food'));
    expect(created, contains('weekly'));
    expect(rows[2].fields, isEmpty);
    expect(rows[3].fields, isEmpty);
  });

  test('the after of an edit is the next edit\'s before-image', () {
    final rows = mapper.rows([
      audit('1', FinanceAuditChange.created, 1),
      audit('2', FinanceAuditChange.edited, 2, json: before()),
      audit('3', FinanceAuditChange.deleted, 3),
      audit('4', FinanceAuditChange.edited, 4, json: before(minor: 40000)),
    ], current());

    expect(
      rows[1].fields.single.value,
      l10n.changeHistoryChange(l10n.amountLabel, '300.00 EGP', '400.00 EGP'),
    );
    expect(
      rows[3].fields.single.value,
      l10n.changeHistoryChange(l10n.amountLabel, '400.00 EGP', '450.00 EGP'),
    );
  });

  test('an unknown category or currency does not fail the sheet', () {
    final rows = mapper.rows([
      audit(
        '2',
        FinanceAuditChange.edited,
        2,
        json: before(code: 'ZZZ', categoryId: 'gone'),
      ),
    ], current());

    final values = rows.single.fields.map((f) => f.value).join('|');
    expect(values, contains('ZZZ'));
    expect(values, contains(l10n.financeCategoryOther));
  });

  test('malformed JSON yields a row with no fields', () {
    final rows = mapper.rows([
      audit('2', FinanceAuditChange.edited, 2, json: '{nope'),
    ], current());
    expect(rows.single.fields, isEmpty);
  });

  test('the previous date reads as a calendar day, and the old epoch '
      'format still reads', () {
    final other = DateTime(2026, 3, 9);
    for (final stored in <Object>['2026-01-01', date.millisecondsSinceEpoch]) {
      final rows = mapper.rows([
        audit(
          '2',
          FinanceAuditChange.edited,
          2,
          json: before(dateValue: stored, minor: 45000),
        ),
      ], current().copyWithDate(other));
      final value = rows.single.fields.single.value;
      expect(value, contains('2026'), reason: '$stored');
      expect(value, contains('→'), reason: '$stored');
    }
  });
}

extension on FinanceEntry {
  FinanceEntry copyWithDate(DateTime d) => FinanceEntry(
    id: id,
    idempotencyKey: idempotencyKey,
    categoryId: categoryId,
    type: type,
    amount: amount,
    date: d,
    createdAt: createdAt,
    note: note,
  );
}
