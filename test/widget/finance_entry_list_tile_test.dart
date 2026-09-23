import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/presentation/widgets/finance_entry_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FinanceEntry buildEntry({required FinanceEntryType type}) {
    return FinanceEntry(
      id: 'e1',
      idempotencyKey: 'k1',
      categoryId: 'c1',
      type: type,
      amount: const Money.fromMinorUnits(15050),
      date: DateTime(2026, 1, 1),
      createdAt: DateTime(2026, 1, 1),
    );
  }

  // Deliberately identical for both rows: the test then proves the
  // income/expense distinction does not rest on the category name (FR-005).
  const sharedCategoryName = 'Other';
  const sharedIconKey = 'other';

  Widget wrap(ThemeData theme, FinanceEntry entry) {
    return MaterialApp(
      theme: theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: FinanceEntryListTile(
          entry: entry,
          categoryName: sharedCategoryName,
          categoryIconKey: sharedIconKey,
        ),
      ),
    );
  }

  Color amountColor(WidgetTester tester) {
    final text = tester.widget<Text>(
      find.textContaining('150.50', findRichText: false),
    );
    return text.style!.color!;
  }

  for (final theme in {
    'Light': buildLightTheme(),
    'Dark': buildDarkTheme(),
  }.entries) {
    group('under ${theme.key} theme', () {
      testWidgets(
        'income and expense rows differ by icon and color, not just by the '
        'category name (FR-005)',
        (tester) async {
          await tester.pumpWidget(
            wrap(theme.value, buildEntry(type: FinanceEntryType.income)),
          );
          expect(find.text(sharedCategoryName), findsOneWidget);
          expect(find.byIcon(Icons.south_west), findsOneWidget);
          expect(find.byIcon(Icons.north_east), findsNothing);
          expect(find.textContaining('+'), findsOneWidget);
          final incomeColor = amountColor(tester);

          await tester.pumpWidget(
            wrap(theme.value, buildEntry(type: FinanceEntryType.expense)),
          );
          expect(find.text(sharedCategoryName), findsOneWidget);
          expect(find.byIcon(Icons.north_east), findsOneWidget);
          expect(find.byIcon(Icons.south_west), findsNothing);
          expect(find.textContaining('-'), findsOneWidget);
          final expenseColor = amountColor(tester);

          expect(incomeColor, isNot(equals(expenseColor)));
        },
      );

      testWidgets('an edited entry shows the edited marker', (tester) async {
        final edited = FinanceEntry(
          id: 'e2',
          idempotencyKey: 'k2',
          categoryId: 'c1',
          type: FinanceEntryType.expense,
          amount: const Money.fromMinorUnits(15050),
          date: DateTime(2026, 1, 1),
          createdAt: DateTime(2026, 1, 1),
          editedAt: DateTime(2026, 1, 2),
        );

        await tester.pumpWidget(wrap(theme.value, edited));

        expect(find.textContaining('('), findsOneWidget);
      });
    });
  }
}
