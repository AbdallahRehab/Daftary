import 'dart:io';

import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/currency.dart';
import 'package:daftary/features/financial_education/domain/usecases/get_prefillable_savings_goal_amount.dart';
import 'package:daftary/features/savings/domain/entities/savings_goal.dart';
import 'package:daftary/features/savings/domain/entities/savings_overview.dart';
import 'package:daftary/features/savings/domain/usecases/get_savings_overview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../savings/helpers/savings_test_data.dart';

class MockGetSavingsOverview extends Mock implements GetSavingsOverview {}

SavingsGoal _goal(
  String id,
  DateTime createdAt, {
  Currency currency = Currency.egp,
  bool isArchived = false,
}) => SavingsGoal(
  id: id,
  idempotencyKey: 'k-$id',
  name: 'Goal $id',
  currency: currency,
  targetAmountMinorUnits: 10000000,
  isArchived: isArchived,
  createdAt: createdAt,
  updatedAt: createdAt,
);

/// T030 — FR-014's optional pre-fill, read from Savings Goals (011) through
/// its Domain use case `GetSavingsOverview`.
void main() {
  late MockGetSavingsOverview getSavingsOverview;
  late GetPrefillableSavingsGoalAmount useCase;

  setUp(() {
    getSavingsOverview = MockGetSavingsOverview();
    useCase = GetPrefillableSavingsGoalAmount(getSavingsOverview);
  });

  void stubGoals(List<GoalOverviewLine> lines) {
    when(() => getSavingsOverview()).thenAnswer(
      (_) async =>
          Right(SavingsOverview(goals: lines, primaryCurrency: Currency.egp)),
    );
  }

  test('offers the most recently created active goal\'s saved amount, '
      'exactly as 011 reports it', () async {
    final older = testOverviewLine(_goal('a', DateTime(2026, 1)), saved: 5000);
    final newest = testOverviewLine(
      _goal('b', DateTime(2026, 6)),
      saved: 123456,
    );
    final middle = testOverviewLine(_goal('c', DateTime(2026, 3)), saved: 700);
    stubGoals([older, newest, middle]);

    expect(await useCase(), newest.progress.currentAmountMinorUnits);
    expect(await useCase(), 123456);
  });

  test(
    'null when the user has no active goal (the action stays hidden)',
    () async {
      stubGoals([]);

      expect(await useCase(), isNull);
    },
  );

  test('null when the newest goal has nothing saved yet', () async {
    stubGoals([testOverviewLine(_goal('a', DateTime(2026)))]);

    expect(await useCase(), isNull);
  });

  test('null when the newest goal is in another currency — the EGP '
      'calculator never relabels or converts it', () async {
    stubGoals([
      testOverviewLine(_goal('a', DateTime(2026)), saved: 5000),
      testOverviewLine(
        _goal('b', DateTime(2026, 6), currency: Currency.usd),
        saved: 9999,
        converted: 480000,
      ),
    ]);

    expect(await useCase(), isNull);
  });

  test('ignores an archived line even if the overview returned one', () async {
    stubGoals([
      testOverviewLine(_goal('a', DateTime(2026)), saved: 5000),
      testOverviewLine(
        _goal('b', DateTime(2026, 6), isArchived: true),
        saved: 9999,
      ),
    ]);

    expect(await useCase(), 5000);
  });

  test('reads active goals only, once, and nothing else', () async {
    stubGoals([]);

    await useCase();

    verify(() => getSavingsOverview()).called(1);
    verifyNoMoreInteractions(getSavingsOverview);
  });

  test('a failed read or a throw degrades to null, never an error', () async {
    when(
      () => getSavingsOverview(),
    ).thenAnswer((_) async => const Left(CacheFailure('db')));
    expect(await useCase(), isNull);

    when(() => getSavingsOverview()).thenThrow(StateError('boom'));
    expect(await useCase(), isNull);
  });

  test('reads 011 only through its Domain layer — no repository, data '
      'layer, database or write use case', () {
    final source = File(
      'lib/features/financial_education/domain/usecases/'
      'get_prefillable_savings_goal_amount.dart',
    ).readAsStringSync();
    final imports = RegExp(
      r'^import .*;$',
      multiLine: true,
    ).allMatches(source).map((m) => m.group(0)!).toList();
    for (final line in imports) {
      expect(line, isNot(contains('repositor')));
      expect(line, isNot(contains('/data/')));
      expect(line, isNot(contains('database')));
      expect(line, isNot(contains('drift')));
      expect(line, isNot(contains('presentation')));
    }
    final savingsImports = imports.where((l) => l.contains('/savings/'));
    expect(savingsImports, isNotEmpty);
    for (final line in savingsImports) {
      expect(
        line,
        anyOf(
          contains('/savings/domain/entities/'),
          contains('/savings/domain/usecases/get_savings_overview.dart'),
        ),
      );
    }
  });
}
