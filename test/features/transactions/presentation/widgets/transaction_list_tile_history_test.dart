import 'dart:convert';

import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/entities/transaction_audit_entry.dart';
import 'package:daftary/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:daftary/features/transactions/domain/usecases/watch_transaction_audit_history.dart';
import 'package:daftary/features/transactions/presentation/widgets/transaction_change_history.dart';
import 'package:daftary/features/transactions/presentation/widgets/transaction_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

/// 022 T062 (C3): the "Edited" marker opens the change-history sheet.
void main() {
  final edited = MoneyTransaction(
    id: 't1',
    idempotencyKey: 'k',
    personId: 'p',
    amount: const Money.egp(80000),
    direction: TransactionDirection.given,
    kind: TransactionKind.initialExchange,
    date: DateTime(2026, 1, 1),
    createdAt: DateTime(2026, 1, 1),
    editedAt: DateTime(2026, 2, 1),
  );

  Widget app(Locale locale, Widget child, {ThemeData? theme}) => MaterialApp(
    theme: theme ?? buildLightTheme(),
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  testWidgets('no handler: the marker is plain text', (tester) async {
    await tester.pumpWidget(
      app(const Locale('en'), TransactionListTile(transaction: edited)),
    );
    expect(find.text('(Edited)'), findsOneWidget);
    expect(find.byKey(const ValueKey('edited-marker')), findsNothing);
  });

  testWidgets('tapping the marker calls onEditedTap; target >= 48dp', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      app(
        const Locale('en'),
        TransactionListTile(transaction: edited, onEditedTap: () => taps++),
      ),
    );
    final size = tester.getSize(find.byKey(const ValueKey('edited-marker')));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(size.width, greaterThanOrEqualTo(48));
    await tester.tap(find.text('(Edited)'));
    expect(taps, 1);
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('marker opens the sheet with earlier amount, direction, date '
        'and note (${locale.languageCode})', (tester) async {
      final repository = MockTransactionsRepository();
      when(() => repository.watchAuditHistory('t1')).thenAnswer(
        (_) => Stream.value(
          Right([
            TransactionAuditEntry(
              id: 'a1',
              transactionId: 't1',
              changeType: AuditChangeType.created,
              changedAt: DateTime(2026, 1, 1),
            ),
            TransactionAuditEntry(
              id: 'a2',
              transactionId: 't1',
              changeType: AuditChangeType.edited,
              changedAt: DateTime(2026, 2, 1),
              previousValuesJson: jsonEncode({
                'amountMinorUnits': 100000,
                'currencyCode': 'EGP',
                'direction': 'received',
                'date': DateTime(2026, 1, 1).millisecondsSinceEpoch,
                'note': 'rent',
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
            builder: (context) => TransactionListTile(
              transaction: edited,
              onEditedTap: () => showTransactionChangeHistory(
                context,
                edited,
                watch: WatchTransactionAuditHistory(repository),
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
      expect(
        find.textContaining(RegExp(r'1,?000\.00.*800\.00')),
        findsOneWidget,
      );
      expect(find.textContaining(l10n.directionReceived), findsWidgets);
      expect(find.textContaining('rent'), findsWidgets);
    });
  }

  testWidgets('a failing history shows the error state', (tester) async {
    final repository = MockTransactionsRepository();
    when(
      () => repository.watchAuditHistory('t1'),
    ).thenAnswer((_) => Stream.value(const Left(CacheFailure('boom'))));
    await tester.pumpWidget(
      app(
        const Locale('en'),
        Builder(
          builder: (context) => TransactionListTile(
            transaction: edited,
            onEditedTap: () => showTransactionChangeHistory(
              context,
              edited,
              watch: WatchTransactionAuditHistory(repository),
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
