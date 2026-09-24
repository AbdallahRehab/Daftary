import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/egp_formatter.dart';
import 'package:daftary/features/financial_education/domain/services/compound_growth_calculator.dart';
import 'package:daftary/features/financial_education/domain/services/doubling_time_calculator.dart';
import 'package:daftary/features/financial_education/domain/services/savings_rate_calculator.dart';
import 'package:daftary/features/financial_education/domain/usecases/calculate_compound_growth.dart';
import 'package:daftary/features/financial_education/domain/usecases/calculate_doubling_time.dart';
import 'package:daftary/features/financial_education/domain/usecases/calculate_savings_rate.dart';
import 'package:daftary/features/financial_education/domain/usecases/get_prefillable_savings_goal_amount.dart';
import 'package:daftary/features/financial_education/presentation/cubit/compound_growth_calculator_cubit.dart';
import 'package:daftary/features/financial_education/presentation/cubit/doubling_time_calculator_cubit.dart';
import 'package:daftary/features/financial_education/presentation/cubit/savings_rate_calculator_cubit.dart';
import 'package:daftary/features/financial_education/presentation/pages/compound_growth_calculator_page.dart';
import 'package:daftary/features/financial_education/presentation/pages/doubling_time_calculator_page.dart';
import 'package:daftary/features/financial_education/presentation/pages/savings_rate_calculator_page.dart';
import 'package:daftary/features/financial_education/presentation/widgets/calculator_result_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget coverage of the three calculator pages' result rendering and
/// inline validation (US2/US3). Disclaimer presence on these pages is
/// covered by the consolidated suite in
/// `financial_education_disclaimer_test.dart` (T048).
void main() {
  setUp(() async {
    await getIt.reset();
    // The real, pure calculators behind the real use cases — exactly what
    // the generated DI config wires, minus the rest of the app.
    getIt
      ..registerFactory<CompoundGrowthCalculatorCubit>(
        () => CompoundGrowthCalculatorCubit(
          const CalculateCompoundGrowth(CompoundGrowthCalculatorImpl()),
          const GetPrefillableSavingsGoalAmount(),
          EgpFormatter(),
        ),
      )
      ..registerFactory<DoublingTimeCalculatorCubit>(
        () => DoublingTimeCalculatorCubit(
          const CalculateDoublingTime(DoublingTimeCalculatorImpl()),
          EgpFormatter(),
        ),
      )
      ..registerFactory<SavingsRateCalculatorCubit>(
        () => SavingsRateCalculatorCubit(
          const CalculateSavingsRate(SavingsRateCalculatorImpl()),
          EgpFormatter(),
        ),
      );
  });

  tearDown(() async => getIt.reset());

  Widget app(Widget page) => MaterialApp(
    theme: buildLightTheme(),
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: page,
  );

  testWidgets(
    'compound growth: result card with breakdown, notes; no pre-fill button',
    (tester) async {
      await tester.pumpWidget(app(const CompoundGrowthCalculatorPage()));
      await tester.pumpAndSettle();

      // 011 is absent in this build → the pre-fill action is hidden.
      expect(find.byIcon(Icons.savings_outlined), findsNothing);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '1000');
      await tester.enterText(fields.at(1), '31');
      await tester.enterText(fields.at(2), '10');
      await tester.tap(find.text('Calculate'));
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorResultCard), findsOneWidget);
      expect(find.text('Projected total'), findsOneWidget);
      expect(find.text('Total contributed'), findsOneWidget);
      expect(find.text('120,000.00 EGP'), findsOneWidget);
      expect(
        find.byKey(CalculatorResultCard.illustrativeNoteKey),
        findsOneWidget,
      );
      expect(find.byKey(CalculatorResultCard.highRateNoteKey), findsOneWidget);
    },
  );

  testWidgets('compound growth: invalid input shows an inline error', (
    tester,
  ) async {
    await tester.pumpWidget(app(const CompoundGrowthCalculatorPage()));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '0');
    await tester.enterText(fields.at(1), '-2');
    await tester.enterText(fields.at(2), '5');
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();

    expect(find.text('Enter an amount greater than zero'), findsOneWidget);
    expect(find.byType(CalculatorResultCard), findsNothing);
  });

  testWidgets('doubling time: 8% → 9 years, labeled as an approximation', (
    tester,
  ) async {
    await tester.pumpWidget(app(const DoublingTimeCalculatorPage()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '8');
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();

    expect(find.text('9 years'), findsOneWidget);
    expect(find.textContaining('rule of 72'), findsWidgets);
  });

  testWidgets('savings rate: >100% is shown unclamped', (tester) async {
    await tester.pumpWidget(app(const SavingsRateCalculatorPage()));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '20000');
    await tester.enterText(fields.at(1), '25000');
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();

    expect(find.text('125%'), findsOneWidget);
    expect(
      find.text(
        'The amount saved is higher than the income entered, so the rate is '
        'above 100%.',
      ),
      findsOneWidget,
    );
  });
}
