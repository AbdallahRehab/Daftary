import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/date/app_date_formatter.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../cubit/repayment_form_cubit.dart';
import '../cubit/repayment_form_state.dart';

/// Records a repayment against an existing balance (FR-011/FR-012),
/// pre-bound to [personId].
class RepaymentFormPage extends StatelessWidget {
  const RepaymentFormPage({required this.personId, super.key});

  final String personId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RepaymentFormCubit>(param1: personId),
      child: const _RepaymentFormView(),
    );
  }
}

class _RepaymentFormView extends StatelessWidget {
  const _RepaymentFormView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.repaymentFormTitle)),
      body: BlocConsumer<RepaymentFormCubit, RepaymentFormState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == RepaymentFormStatus.success) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(l10n.savedConfirmation)));
            Navigator.of(context).pop(true);
          } else if (state.status == RepaymentFormStatus.failure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? l10n.errorUnknown),
                ),
              );
          }
        },
        builder: (context, state) {
          final cubit = context.read<RepaymentFormCubit>();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: l10n.amountLabel,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  errorText: state.amountInvalid
                      ? l10n.amountInvalidError
                      : null,
                  onChanged: cubit.amountChanged,
                ),
                const SizedBox(height: AppSpacing.md),
                _DateField(date: state.date, onDateChanged: cubit.dateChanged),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: l10n.noteLabel,
                  maxLines: 3,
                  onChanged: cubit.noteChanged,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: l10n.commonSave,
                  isLoading: state.isSubmitting,
                  onPressed: cubit.submit,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onDateChanged});

  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        if (picked != null) onDateChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.dateLabel,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: Text(
          AppDateFormatter(
            locale: Localizations.localeOf(context).languageCode,
          ).format(date),
        ),
      ),
    );
  }
}
