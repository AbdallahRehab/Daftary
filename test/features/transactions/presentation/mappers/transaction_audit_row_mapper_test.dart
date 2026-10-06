import 'dart:convert';

import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/entities/transaction_audit_entry.dart';
import 'package:daftary/features/transactions/presentation/mappers/transaction_audit_row_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  final date = DateTime(2026, 1, 1);
  final l10n = lookupAppLocalizations(const Locale('en'));
  late TransactionAuditRowMapper mapper;

  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar_u_nu_latn');
  });
  setUp(() => mapper = TransactionAuditRowMapper(l10n: l10n, locale: 'en'));

  MoneyTransaction current({
    int minor = 80000,
    String? note,
    TransactionDirection direction = TransactionDirection.given,
  }) => MoneyTransaction(
    id: 't',
    idempotencyKey: 'k',
    personId: 'p',
    amount: Money.fromMinorUnits(minor, Currency.egp),
    direction: direction,
    kind: TransactionKind.initialExchange,
    date: date,
    createdAt: date,
    note: note,
  );

  String before({
    int minor = 100000,
    String code = 'EGP',
    String direction = 'given',
    String? note,
  }) => jsonEncode({
    'amountMinorUnits': minor,
    'currencyCode': code,
    'direction': direction,
    'date': date.millisecondsSinceEpoch,
    'note': note,
  });

  TransactionAuditEntry entry(
    String id,
    AuditChangeType type,
    int day, {
    String? json,
  }) => TransactionAuditEntry(
    id: id,
    transactionId: 't',
    changeType: type,
    changedAt: DateTime(2026, 1, day, 10),
    previousValuesJson: json,
  );

  test('edit 1,000 -> 800 shows only the amount, old -> new', () {
    final rows = mapper.rows([
      entry('1', AuditChangeType.created, 1),
      entry('2', AuditChangeType.edited, 2, json: before()),
    ], current());

    expect(rows[1].label, l10n.changeHistoryEdited);
    expect(rows[1].fields, hasLength(1));
    expect(rows[1].fields.single.label, isEmpty);
    expect(
      rows[1].fields.single.value,
      l10n.changeHistoryChange(l10n.amountLabel, '1,000.00 EGP', '800.00 EGP'),
    );
  });

  test('created row shows the initial values', () {
    final rows = mapper.rows([
      entry('1', AuditChangeType.created, 1),
      entry('2', AuditChangeType.edited, 2, json: before(note: 'rent')),
    ], current(note: 'rent'));

    final values = rows.first.fields.map((f) => f.value);
    expect(values, contains('1,000.00 EGP'));
    expect(values, contains('rent'));
  });

  test('the after of an edit is the next entry\'s before-image', () {
    final rows = mapper.rows([
      entry('1', AuditChangeType.created, 1),
      entry('2', AuditChangeType.edited, 2, json: before()),
      entry('3', AuditChangeType.edited, 3, json: before(minor: 90000)),
    ], current());

    expect(
      rows[1].fields.single.value,
      l10n.changeHistoryChange(l10n.amountLabel, '1,000.00 EGP', '900.00 EGP'),
    );
    expect(
      rows[2].fields.single.value,
      l10n.changeHistoryChange(l10n.amountLabel, '900.00 EGP', '800.00 EGP'),
    );
  });

  test('delete row shows the values at deletion, not "before the edit"', () {
    final rows = mapper.rows([
      entry('1', AuditChangeType.created, 1),
      entry('2', AuditChangeType.deleted, 2, json: before()),
    ], current(minor: 100000));

    final fields = rows[1].fields;
    expect(
      fields.first.label,
      l10n.changeHistoryValueAtDeletion(l10n.amountLabel),
    );
    expect(fields.first.value, '1,000.00 EGP');
    expect(fields.map((f) => f.label), isNot(contains(contains('Previous'))));
  });

  test('a changed direction and note are shown; unchanged fields are not', () {
    final rows = mapper.rows(
      [
        entry('1', AuditChangeType.created, 1),
        entry('2', AuditChangeType.edited, 2, json: before(note: 'a')),
      ],
      current(
        minor: 100000,
        note: 'b',
        direction: TransactionDirection.received,
      ),
    );

    final text = rows[1].fields.map((f) => f.value).join('|');
    expect(text, contains(l10n.directionGiven));
    expect(text, contains(l10n.directionReceived));
    expect(text, contains('a'));
    expect(text, contains('b'));
    expect(text, isNot(contains('EGP')));
  });

  test('an unknown currency code does not fail the sheet', () {
    final rows = mapper.rows([
      entry('1', AuditChangeType.created, 1),
      entry('2', AuditChangeType.edited, 2, json: before(code: 'ZZZ')),
    ], current());

    expect(rows, hasLength(2));
    expect(rows[1].fields.single.value, contains('ZZZ'));
  });

  test('malformed JSON yields a row with no fields', () {
    final rows = mapper.rows([
      entry('2', AuditChangeType.edited, 2, json: '{nope'),
    ], current());
    expect(rows.single.fields, isEmpty);
  });

  test('a cleared or newly added note shows the (none) placeholder', () {
    final cleared = mapper.rows([
      entry(
        '2',
        AuditChangeType.edited,
        2,
        json: before(minor: 80000, note: 'a'),
      ),
    ], current());
    expect(
      cleared[0].fields.single.value,
      l10n.changeHistoryChange(
        l10n.changeHistoryNoteField,
        'a',
        l10n.changeHistoryNoValue,
      ),
    );
    final added = mapper.rows([
      entry('2', AuditChangeType.edited, 2, json: before(minor: 80000)),
    ], current(note: 'b'));
    expect(
      added[0].fields.single.value,
      l10n.changeHistoryChange(
        l10n.changeHistoryNoteField,
        l10n.changeHistoryNoValue,
        'b',
      ),
    );
  });

  test('Arabic wraps Latin values in first-strong isolates', () {
    final ar = lookupAppLocalizations(const Locale('ar'));
    final arMapper = TransactionAuditRowMapper(l10n: ar, locale: 'ar');
    final rows = arMapper.rows([
      entry(
        '2',
        AuditChangeType.edited,
        2,
        json: before(minor: 80000, note: 'rent'),
      ),
    ], current(note: 'food'));
    final value = rows[0].fields.single.value;
    expect(value, contains('\u2068rent\u2069 \u2190 \u2068food\u2069'));
  });
}
