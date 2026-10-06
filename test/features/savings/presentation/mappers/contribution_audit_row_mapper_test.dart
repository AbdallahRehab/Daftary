import 'dart:convert';

import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/savings/domain/entities/savings_contribution.dart';
import 'package:daftary/features/savings/domain/entities/savings_contribution_audit.dart';
import 'package:daftary/features/savings/presentation/mappers/contribution_audit_row_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  final date = DateTime(2026, 1, 1);
  final l10n = lookupAppLocalizations(const Locale('en'));
  late ContributionAuditRowMapper mapper;

  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar_u_nu_latn');
  });
  setUp(() => mapper = ContributionAuditRowMapper(l10n: l10n, locale: 'en'));

  SavingsContribution current({int minor = 80000, String? note}) =>
      SavingsContribution(
        id: 'c',
        idempotencyKey: 'k',
        goalId: 'g',
        type: ContributionType.contribution,
        amountMinorUnits: minor,
        enteredAmountMinorUnits: minor,
        enteredCurrency: Currency.egp,
        date: date,
        createdAt: DateTime(2025, 12, 31, 9),
        note: note,
      );

  String before({int minor = 100000, String code = 'EGP', String? note}) =>
      jsonEncode({
        'amountMinorUnits': minor,
        'enteredAmountMinorUnits': minor,
        'enteredCurrencyCode': code,
        'date': date.millisecondsSinceEpoch,
        'note': note,
      });

  SavingsContributionAudit audit(
    String id,
    ContributionAuditChange type,
    int day,
    String json,
  ) => SavingsContributionAudit(
    id: id,
    contributionId: 'c',
    changeType: type,
    previousValuesJson: json,
    changedAt: DateTime(2026, 1, day, 10),
  );

  test('a synthetic Created row from createdAt comes first, with initial '
      'values', () {
    final rows = mapper.rows([
      audit('1', ContributionAuditChange.edited, 2, before()),
    ], current());

    expect(rows, hasLength(2));
    expect(rows.first.label, l10n.changeHistoryCreated);
    expect(rows.first.timestamp, DateTime(2025, 12, 31, 9));
    expect(rows.first.fields.map((f) => f.value), contains('1,000.00 EGP'));
  });

  test('with no audits there is just the Created row', () {
    final rows = mapper.rows(const [], current());
    expect(rows.single.label, l10n.changeHistoryCreated);
  });

  test('edit 1,000 -> 800 shows only the amount; no direction field', () {
    final rows = mapper.rows([
      audit('1', ContributionAuditChange.edited, 2, before()),
    ], current());

    expect(rows[1].fields, hasLength(1));
    expect(
      rows[1].fields.single.value,
      l10n.changeHistoryChange(l10n.amountLabel, '1,000.00 EGP', '800.00 EGP'),
    );
    final all = rows.expand((r) => r.fields).map((f) => f.label);
    expect(all, isNot(contains(l10n.changeHistoryDirectionField)));
  });

  test('delete row shows values at deletion', () {
    final rows = mapper.rows([
      audit('1', ContributionAuditChange.deleted, 2, before()),
    ], current(minor: 100000));

    expect(rows[1].label, l10n.changeHistoryDeleted);
    expect(
      rows[1].fields.first.label,
      l10n.changeHistoryValueAtDeletion(l10n.amountLabel),
    );
  });

  test('chained edits use the next before-image as the after', () {
    final rows = mapper.rows([
      audit('1', ContributionAuditChange.edited, 2, before()),
      audit('2', ContributionAuditChange.edited, 3, before(minor: 90000)),
    ], current());

    expect(
      rows[1].fields.single.value,
      l10n.changeHistoryChange(l10n.amountLabel, '1,000.00 EGP', '900.00 EGP'),
    );
  });

  test('an unknown currency code does not fail the sheet', () {
    final rows = mapper.rows([
      audit('1', ContributionAuditChange.edited, 2, before(code: 'ZZZ')),
    ], current());
    expect(rows, hasLength(2));
    expect(rows[1].fields.single.value, contains('ZZZ'));
  });
}
