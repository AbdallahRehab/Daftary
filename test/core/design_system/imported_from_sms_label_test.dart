import 'package:daftary/core/design_system/imported_from_sms_label.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/core/provenance/import_provenance.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/presentation/widgets/finance_entry_list_tile.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/presentation/widgets/transaction_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// T083/T084 — "Imported from a bank message" (FR-057, US1-9): the label,
/// its screen-reader text, and its presence only on SMS-sourced rows.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Locale locale = const Locale('en'),
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        theme: theme ?? buildLightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ListView(children: [child])),
      ),
    );
    await tester.pumpAndSettle();
  }

  MoneyTransaction transaction({ImportProvenance? importSource}) =>
      MoneyTransaction(
        id: 't1',
        idempotencyKey: 'k1',
        personId: 'p1',
        amount: const Money.egp(12550),
        direction: TransactionDirection.given,
        kind: TransactionKind.initialExchange,
        date: DateTime(2026, 3, 4),
        createdAt: DateTime(2026, 3, 4),
        importSource: importSource,
      );

  FinanceEntry entry({ImportProvenance? importSource}) => FinanceEntry(
    id: 'e1',
    idempotencyKey: 'k1',
    categoryId: 'seed_groceries',
    type: FinanceEntryType.expense,
    amount: const Money.egp(12550),
    date: DateTime(2026, 3, 4),
    createdAt: DateTime(2026, 3, 4),
    importSource: importSource,
  );

  for (final (lang, text) in [
    ('en', 'Imported from a bank message'),
    ('ar', 'مستورد من رسالة بنكية'),
  ]) {
    testWidgets('label text and screen-reader label ($lang)', (tester) async {
      final handle = tester.ensureSemantics();
      final locale = Locale(lang);
      await pump(tester, const ImportedFromSmsLabel(), locale: locale);
      expect(find.text(text), findsOneWidget);
      expect(find.byIcon(Icons.sms_outlined), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          lookupAppLocalizations(locale).smsImportProvenanceSemantics,
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  }

  testWidgets('transaction tile: present only for an SMS import', (
    tester,
  ) async {
    await pump(
      tester,
      TransactionListTile(
        transaction: transaction(importSource: ImportProvenance.sms),
      ),
    );
    expect(find.byType(ImportedFromSmsLabel), findsOneWidget);
    await pump(tester, TransactionListTile(transaction: transaction()));
    expect(find.byType(ImportedFromSmsLabel), findsNothing);
    await pump(
      tester,
      TransactionListTile(
        transaction: transaction(
          importSource: ImportProvenance.fromWire('wallet'),
        ),
      ),
    );
    expect(find.byType(ImportedFromSmsLabel), findsNothing);
  });

  testWidgets('finance tile: present only for an SMS import', (tester) async {
    await pump(
      tester,
      FinanceEntryListTile(
        entry: entry(importSource: ImportProvenance.sms),
        categoryName: 'Groceries',
        categoryIconKey: 'groceries',
      ),
    );
    expect(find.byType(ImportedFromSmsLabel), findsOneWidget);
    await pump(
      tester,
      FinanceEntryListTile(
        entry: entry(),
        categoryName: 'Groceries',
        categoryIconKey: 'groceries',
      ),
    );
    expect(find.byType(ImportedFromSmsLabel), findsNothing);
  });

  for (final theme in [buildLightTheme(), buildDarkTheme()]) {
    for (final lang in ['en', 'ar']) {
      testWidgets('tiles render with the label ($lang, '
          '${theme.brightness.name})', (tester) async {
        await pump(
          tester,
          Column(
            children: [
              TransactionListTile(
                transaction: transaction(importSource: ImportProvenance.sms),
              ),
              FinanceEntryListTile(
                entry: entry(importSource: ImportProvenance.sms),
                categoryName: 'Groceries',
                categoryIconKey: 'groceries',
              ),
            ],
          ),
          locale: Locale(lang),
          theme: theme,
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(ImportedFromSmsLabel), findsNWidgets(2));
      });
    }
  }
}
