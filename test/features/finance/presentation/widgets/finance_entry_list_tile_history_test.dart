import 'dart:convert';

import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_audit.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/repositories/finance_repository.dart';
import 'package:daftary/features/finance/domain/usecases/watch_entry_audit_history.dart';
import 'package:daftary/features/finance/presentation/widgets/finance_entry_change_history.dart';
import 'package:daftary/features/finance/presentation/widgets/finance_entry_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockFinanceRepository extends Mock implements FinanceRepository {}

/// 022 T069 (D2): the "Edited" marker of an income or expense row opens the
/// change-history sheet.
void main() {
  final edited = FinanceEntry(
    id: 'e1',
    idempotencyKey: 'k',
    categoryId: 'food',
    type: FinanceEntryType.expense,
    amount: const Money.egp(45000),
    date: DateTime(2026, 1, 1),
    createdAt: DateTime(2026, 1, 1),
    editedAt: DateTime(2026, 2, 1),
  );

  Widget app(Locale locale, Widget child) => MaterialApp(
    theme: buildLightTheme(),
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  Widget tile({VoidCallback? onEditedTap}) => FinanceEntryListTile(
    entry: edited,
    categoryName: 'Food',
    categoryIconKey: 'groceries',
    onEditedTap: onEditedTap,
  );

  testWidgets('no handler: the marker is plain text', (tester) async {
    await tester.pumpWidget(app(const Locale('en'), tile()));
    expect(find.text('(Edited)'), findsOneWidget);
    expect(find.byKey(const ValueKey('edited-marker')), findsNothing);
  });

  testWidgets('tapping the marker calls onEditedTap; target >= 48dp', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      app(const Locale('en'), tile(onEditedTap: () => taps++)),
    );
    final size = tester.getSize(find.byKey(const ValueKey('edited-marker')));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(size.width, greaterThanOrEqualTo(48));
    await tester.tap(find.text('(Edited)'));
    expect(taps, 1);
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('marker opens the sheet with the earlier amount, type and '
        'category (${locale.languageCode})', (tester) async {
      final repository = MockFinanceRepository();
      when(() => repository.watchEntryAuditHistory('e1')).thenAnswer(
        (_) => Stream.value(
          Right([
            FinanceEntryAudit(
              id: 'a1',
              financeEntryId: 'e1',
              changeType: FinanceAuditChange.created,
              changedAt: DateTime(2026, 1, 1),
            ),
            FinanceEntryAudit(
              id: 'a2',
              financeEntryId: 'e1',
              changeType: FinanceAuditChange.edited,
              changedAt: DateTime(2026, 2, 1),
              previousValuesJson: jsonEncode({
                'amountMinorUnits': 30000,
                'currencyCode': 'EGP',
                'type': 'income',
                'categoryId': 'salary',
                'date': DateTime(2026, 1, 1).millisecondsSinceEpoch,
                'note': null,
              }),
            ),
          ]),
        ),
      );
      final l10n = lookupAppLocalizations(locale);
      await tester.pumpWidget(
        app(
          locale,
          Builder(
            builder: (context) => FinanceEntryListTile(
              entry: edited,
              categoryName: 'Food',
              categoryIconKey: 'groceries',
              onEditedTap: () => showFinanceEntryChangeHistory(
                context,
                edited,
                categoryNames: const {'food': 'Food', 'salary': 'Salary'},
                watch: WatchEntryAuditHistory(repository),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('(${l10n.editedLabel})'));
      await tester.pumpAndSettle();

      expect(find.text(l10n.changeHistoryTitle), findsOneWidget);
      expect(find.text(l10n.changeHistoryCreated), findsOneWidget);
      expect(find.text(l10n.changeHistoryEdited), findsOneWidget);
      if (locale.languageCode == 'en') {
        expect(
          find.text(
            l10n.changeHistoryChange(
              l10n.amountLabel,
              '300.00 EGP',
              '450.00 EGP',
            ),
          ),
          findsOneWidget,
        );
      }
      expect(
        find.text(
          l10n.changeHistoryChange(
            l10n.changeHistoryTypeField,
            l10n.financeTypeIncome,
            l10n.financeTypeExpense,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          l10n.changeHistoryChange(l10n.financeCategoryLabel, 'Salary', 'Food'),
        ),
        findsOneWidget,
      );
    });
  }

  testWidgets('a failing history shows the error state', (tester) async {
    final repository = MockFinanceRepository();
    when(
      () => repository.watchEntryAuditHistory('e1'),
    ).thenAnswer((_) => Stream.value(const Left(CacheFailure('boom'))));
    await tester.pumpWidget(
      app(
        const Locale('en'),
        Builder(
          builder: (context) => FinanceEntryListTile(
            entry: edited,
            categoryName: 'Food',
            categoryIconKey: 'groceries',
            onEditedTap: () => showFinanceEntryChangeHistory(
              context,
              edited,
              categoryNames: const {},
              watch: WatchEntryAuditHistory(repository),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('(Edited)'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        lookupAppLocalizations(const Locale('en')).changeHistoryLoadError,
      ),
      findsOneWidget,
    );
  });
}
