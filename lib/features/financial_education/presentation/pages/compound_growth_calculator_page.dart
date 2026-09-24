import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../../../core/money/money.dart';
import '../cubit/compound_growth_calculator_cubit.dart';
import '../cubit/compound_growth_calculator_state.dart';
import '../widgets/calculator_input_field.dart';
import '../widgets/calculator_result_card.dart';
import '../widgets/education_page_scaffold.dart';

/// "What could a fixed monthly amount grow to?" (US2, FR-007..FR-010,
/// FR-014). Every input is typed by the user; the optional pre-fill button
/// appears only when a savings-goal amount is actually available.
class CompoundGrowthCalculatorPage extends StatelessWidget {
  const CompoundGrowthCalculatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = getIt<CompoundGrowthCalculatorCubit>();
        unawaited(cubit.loadPrefillAvailability());
        return cubit;
      },
      child: const _CompoundGrowthCalculatorView(),
    );
  }
}

class _CompoundGrowthCalculatorView extends StatelessWidget {
  const _CompoundGrowthCalculatorView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formatter = EgpFormatter(
      locale: Localizations.localeOf(context).languageCode,
    );
    String money(int minorUnits) =>
        formatter.formatWithSymbol(Money.fromMinorUnits(minorUnits));

    return EducationPageScaffold(
      title: l10n.finEduCalcCompoundTitle,
      body:
          BlocBuilder<
            CompoundGrowthCalculatorCubit,
            CompoundGrowthCalculatorState
          >(
            builder: (context, state) {
              final cubit = context.read<CompoundGrowthCalculatorCubit>();
              final result = state.result;
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Text(
                    l10n.finEduCalcCompoundIntro,
                    style: AppTypography.body.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CalculatorInputField(
                    label: l10n.finEduCalcMonthlyContributionLabel,
                    value: state.monthlyContributionInput,
                    onChanged: cubit.monthlyContributionChanged,
                    errorText: calculatorFieldErrorText(
                      l10n,
                      state.monthlyContributionError,
                      mustBePositive: l10n.finEduCalcErrorAmountPositive,
                    ),
                  ),
                  if (state.isPrefillAvailable) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: cubit.applyPrefill,
                        icon: const Icon(Icons.savings_outlined, size: 18),
                        label: Text(l10n.finEduCalcPrefillFromSavingsGoal),
                      ),
                    ),
                    Text(
                      l10n.finEduCalcPrefillHint,
                      style: AppTypography.bodyMuted.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  CalculatorInputField(
                    label: l10n.finEduCalcAnnualRateLabel,
                    value: state.annualRateInput,
                    onChanged: cubit.annualRateChanged,
                    errorText: calculatorFieldErrorText(
                      l10n,
                      state.annualRateError,
                      mustBePositive: l10n.finEduCalcErrorRateNegative,
                      mustNotBeNegative: l10n.finEduCalcErrorRateNegative,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CalculatorInputField(
                    label: l10n.finEduCalcYearsLabel,
                    value: state.yearsInput,
                    allowDecimal: false,
                    textInputAction: TextInputAction.done,
                    onChanged: cubit.yearsChanged,
                    errorText: calculatorFieldErrorText(
                      l10n,
                      state.yearsError,
                      mustBePositive: l10n.finEduCalcErrorYearsPositive,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: l10n.finEduCalcCalculate,
                    icon: Icons.calculate_outlined,
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      cubit.calculate();
                    },
                  ),
                  if (state.isResultTooLarge) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.finEduCalcErrorResultTooLarge,
                      style: AppTypography.body.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  if (result != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    CalculatorResultCard(
                      headline: CalculatorResultLine(
                        label: l10n.finEduCalcResultFutureValue,
                        value: money(result.futureValueMinorUnits),
                      ),
                      breakdown: [
                        CalculatorResultLine(
                          label: l10n.finEduCalcResultTotalContributed,
                          value: money(result.totalContributedMinorUnits),
                        ),
                        CalculatorResultLine(
                          label: l10n.finEduCalcResultTotalGrowth,
                          value: money(result.totalGrowthMinorUnits),
                        ),
                      ],
                      showHighRateNote: result.isHighRateWarningShown,
                    ),
                  ],
                ],
              );
            },
          ),
    );
  }
}
