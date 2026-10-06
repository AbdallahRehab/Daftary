import 'dart:convert';

import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/savings/domain/entities/savings_contribution.dart';
import 'package:daftary/features/savings/domain/entities/savings_contribution_audit.dart';
import 'package:daftary/features/savings/domain/usecases/watch_contribution_audit_history.dart';
import 'package:daftary/features/savings/presentation/widgets/contribution_change_history.dart';
import 'package:daftary/features/savings/presentation/widgets/contribution_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/savings_test_data.dart';

/// 022 T062 (C3): the contribution tile's "Edited" marker opens the sheet.
void main() {
  final edited = SavingsContribution(
    id: 'c1',
    idempotencyKey: 'k',
    goalId: 'g',
    type: ContributionType.contribution,
    amountMinorUnits: 80000,
    enteredAmountMinorUnits: 80000,
    enteredCurrency: Currency.egp,
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

  testWidgets('no handler: the marker stays inline text', (tester) async {
    await tester.pumpWidget(
      app(
        const Locale('en'),
        ContributionListTile(
          entry: edited,
          goalCurrency: Currency.egp,
          onAction: (_) {},
        ),
      ),
    );
    expect(find.textContaining('Edited'), findsOneWidget);
    expect(find.byKey(const ValueKey('edited-marker')), findsNothing);
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('marker opens the sheet with the earlier amount, kind, date '
        'and note (${locale.languageCode})', (tester) async {
      final repository = MockSavingsRepository();
      when(() => repository.watchContributionAuditHistory('c1')).thenAnswer(
        (_) => Stream.value(
          Right([
            SavingsContributionAudit(
              id: 'a1',
              contributionId: 'c1',
              changeType: ContributionAuditChange.edited,
              previousValuesJson: jsonEncode({
                'amountMinorUnits': 100000,
                'enteredAmountMinorUnits': 100000,
                'enteredCurrencyCode': 'EGP',
                'date': DateTime(2026, 1, 1).millisecondsSinceEpoch,
                'note': 'salary',
              }),
              changedAt: DateTime(2026, 2, 1),
            ),
          ]),
        ),
      );
      final l10n = lookupAppLocalizations(locale);
      await tester.pumpWidget(
        app(
          locale,
          Builder(
            builder: (context) => ContributionListTile(
              entry: edited,
              goalCurrency: Currency.egp,
              onAction: (_) {},
              onEditedTap: () => showContributionChangeHistory(
                context,
                edited,
                watch: WatchContributionAuditHistory(repository),
              ),
            ),
          ),
        ),
      );

      final marker = find.text(l10n.savingsEntryEditedLabel);
      final target = tester.getSize(
        find.byKey(const ValueKey('edited-marker')),
      );
      expect(target.height, greaterThanOrEqualTo(48));
      await tester.tap(marker);
      await tester.pumpAndSettle();

      expect(find.text(l10n.changeHistoryTitle), findsOneWidget);
      expect(find.text(l10n.changeHistoryEdited), findsWidgets); // marker + row
      expect(
        find.textContaining(RegExp(r'1,?000\.00.*800\.00')),
        findsOneWidget,
      );
      expect(find.text(l10n.changeHistoryCreated), findsOneWidget);
      expect(find.textContaining('salary'), findsWidgets);
    });
  }
}
