import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../cubit/doubling_time_calculator_cubit.dart';
import '../cubit/doubling_time_calculator_state.dart';
import '../widgets/calculator_input_field.dart';
import '../widgets/calculator_result_card.dart';
import '../widgets/education_page_scaffold.dart';

/// "Roughly how long until money doubles?" — the rule of 72, clearly
/// labeled as an approximation (US3, FR-011).
class DoublingTimeCalculatorPage extends StatelessWidget {
  const DoublingTimeCalculatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DoublingTimeCalculatorCubit>(),
      child: const _DoublingTimeCalculatorView(),
    );
  }
}

class _DoublingTimeCalculatorView extends StatelessWidget {
  const _DoublingTimeCalculatorView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EducationPageScaffold(
      title: l10n.finEduCalcDoublingTitle,
      body:
          BlocBuilder<DoublingTimeCalculatorCubit, DoublingTimeCalculatorState>(
            builder: (context, state) {
              final cubit = context.read<DoublingTimeCalculatorCubit>();
              final result = state.result;
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Text(
                    l10n.finEduCalcDoublingIntro,
                    style: AppTypography.body.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CalculatorInputField(
                    label: l10n.finEduCalcAnnualRateLabel,
                    value: state.annualRateInput,
                    textInputAction: TextInputAction.done,
                    onChanged: cubit.annualRateChanged,
                    errorText: calculatorFieldErrorText(
                      l10n,
                      state.annualRateError,
                      mustBePositive: l10n.finEduCalcErrorRatePositive,
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
                        label: l10n.finEduCalcResultDoublingYears,
                        value: l10n.finEduCalcYearsValue(
                          formatCalculatorDecimal(
                            context,
                            result.approximateDoublingYears,
                          ),
                        ),
                      ),
                      notes: [l10n.finEduCalcRuleOf72Note],
                    ),
                  ],
                ],
              );
            },
          ),
    );
  }
}
