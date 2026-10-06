import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/transactions/presentation/widgets/delete_transaction_confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool? result;

  Future<void> open(
    WidgetTester tester, {
    String locale = 'en',
    int laterRepayments = 0,
    Money? resultingNet = const Money.egp(0),
  }) async {
    result = null;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showDeleteTransactionConfirmDialog(
                  context,
                  personName: 'Ahmed',
                  laterRepaymentCount: laterRepayments,
                  resultingNet: resultingNet,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('with no later repayments the dialog is unchanged', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('Delete this transaction?'), findsOneWidget);
    expect(find.textContaining('recorded after this one'), findsNothing);
  });

  testWidgets('one later repayment shows the count and the resulting '
      'balance', (tester) async {
    await open(
      tester,
      laterRepayments: 1,
      resultingNet: const Money.egp(-40000),
    );

    expect(
      find.textContaining('1 repayment was recorded after this one'),
      findsOneWidget,
    );
    expect(find.textContaining('You owe Ahmed 400.00'), findsOneWidget);
    // The original message is still there; the warning only adds to it.
    expect(
      find.textContaining("It will be removed from this person's history"),
      findsOneWidget,
    );
  });

  testWidgets('several later repayments use the plural form', (tester) async {
    await open(
      tester,
      laterRepayments: 3,
      resultingNet: const Money.egp(25000),
    );

    expect(
      find.textContaining('3 repayments were recorded after this one'),
      findsOneWidget,
    );
    expect(find.textContaining('Ahmed owes you 250.00'), findsOneWidget);
  });

  testWidgets('an unknown resulting balance still warns', (tester) async {
    await open(tester, laterRepayments: 2, resultingNet: null);

    expect(
      find.textContaining('2 repayments were recorded after this one'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Unavailable until an exchange rate is set'),
      findsOneWidget,
    );
  });

  testWidgets('the warning never blocks deletion: confirm returns true', (
    tester,
  ) async {
    await open(
      tester,
      laterRepayments: 1,
      resultingNet: const Money.egp(-40000),
    );

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('cancel returns false', (tester) async {
    await open(tester, laterRepayments: 1);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets('Arabic renders the warning in RTL', (tester) async {
    await open(
      tester,
      locale: 'ar',
      laterRepayments: 1,
      resultingNet: const Money.egp(-40000),
    );

    expect(find.textContaining('فيه سداد واحد'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(AlertDialog))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('dialog buttons are at least 48dp tall and labelled', (
    tester,
  ) async {
    await open(tester, laterRepayments: 1);

    for (final label in ['Cancel', 'Delete']) {
      final button = find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      );
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      expect(tester.getSemantics(button).label, contains(label));
    }
  });
}
