import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../cubit/savings_rate_calculator_cubit.dart';
import '../cubit/savings_rate_calculator_state.dart';
import '../widgets/calculator_input_field.dart';
import '../widgets/calculator_result_card.dart';
import '../widgets/education_page_scaffold.dart';

/// "What share of an income is being saved?" from two manually entered
/// figures (US3, FR-012/FR-013). A rate above 100% is shown as-is.
class SavingsRateCalculatorPage extends StatelessWidget {
  const SavingsRateCalculatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SavingsRateCalculatorCubit>(),
      child: const _SavingsRateCalculatorView(),
    );
  }
}

class _SavingsRateCalculatorView extends StatelessWidget {
  const _SavingsRateCalculatorView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EducationPageScaffold(
      title: l10n.finEduCalcSavingsRateTitle,
      body: BlocBuilder<SavingsRateCalculatorCubit, SavingsRateCalculatorState>(
        builder: (context, state) {
          final cubit = context.read<SavingsRateCalculatorCubit>();
          final result = state.result;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                l10n.finEduCalcSavingsRateIntro,
                style: AppTypography.body.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              CalculatorInputField(
                label: l10n.finEduCalcIncomeLabel,
                value: state.incomeInput,
                onChanged: cubit.incomeChanged,
                errorText: calculatorFieldErrorText(
                  l10n,
                  state.incomeError,
                  mustBePositive: l10n.finEduCalcErrorIncomePositive,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              CalculatorInputField(
                label: l10n.finEduCalcSavingsAmountLabel,
                value: state.savingsAmountInput,
                textInputAction: TextInputAction.done,
                onChanged: cubit.savingsAmountChanged,
                errorText: calculatorFieldErrorText(
                  l10n,
                  state.savingsAmountError,
                  mustBePositive: l10n.finEduCalcErrorSavingsNegative,
                  mustNotBeNegative: l10n.finEduCalcErrorSavingsNegative,
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
              if (result != null) ...[
                const SizedBox(height: AppSpacing.lg),
                CalculatorResultCard(
                  headline: CalculatorResultLine(
                    label: l10n.finEduCalcResultSavingsRate,
                    value: l10n.finEduCalcPercentValue(
                      formatCalculatorDecimal(
                        context,
                        result.savingsRatePercent,
                      ),
                    ),
                  ),
                  // Not a rate-based projection, so the constant-rate note
                  // does not apply; the persistent banner still does.
                  showIllustrativeNote: false,
                  notes: [
                    if (result.savingsRatePercent > 100)
                      l10n.finEduCalcSavingsAboveIncomeNote,
                    l10n.finEduCalcSavingsRateNote,
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
