import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_date_field.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/design_system/currency_picker.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/failure_message.dart';
import '../../../../core/design_system/app_confirm_dialog.dart';
import '../../../../core/money/egp_formatter.dart';
import '../widgets/balance_amount_text.dart';
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
      create: (_) => getIt<RepaymentFormCubit>(param1: personId)
        ..loadDefaultCurrency()
        ..subscribe(),
      child: const _RepaymentFormView(),
    );
  }
}

class _RepaymentFormView extends StatelessWidget {
  const _RepaymentFormView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      appBar: AppTopBar(title: Text(l10n.repaymentFormTitle)),
      body: BlocListener<RepaymentFormCubit, RepaymentFormState>(
        // Asking for the flip confirmation is its own event: it must not
        // re-run the saved/failed handling below.
        listenWhen: (previous, current) =>
            !previous.needsFlipConfirmation && current.needsFlipConfirmation,
        listener: (context, state) => unawaited(_confirmFlip(context, state)),
        child: BlocConsumer<RepaymentFormCubit, RepaymentFormState>(
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
                  SnackBar(content: Text(l10n.messageFor(state.failure))),
                );
            }
          },
          builder: (context, state) {
            final cubit = context.read<RepaymentFormCubit>();
            return SingleChildScrollView(
              padding:
                  const EdgeInsets.all(AppSpacing.md) +
                  AppGlassInsets.of(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BalanceSummary(state: state),
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
                  CurrencyPicker(
                    key: ValueKey(state.currency),
                    value: state.currency,
                    onChanged: cubit.currencyChanged,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppDateField(
                    label: l10n.dateLabel,
                    date: state.date,
                    onDateChanged: cubit.dateChanged,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: l10n.noteLabel,
                    maxLength: 500,
                    maxLines: 3,
                    onChanged: cubit.noteChanged,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: l10n.commonSave,
                    isLoading: state.isSubmitting,
                    // Saving waits for the balance and rates, so the flip check
                    // is never skipped (022 A2).
                    onPressed: state.balanceLoaded ? cubit.submit : null,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

Future<void> _confirmFlip(
  BuildContext context,
  RepaymentFormState state,
) async {
  final l10n = AppLocalizations.of(context)!;
  final cubit = context.read<RepaymentFormCubit>();
  final locale = Localizations.localeOf(context).languageCode;
  final resulting = state.preview?.resulting;
  if (resulting == null) {
    cubit.cancelFlip();
    return;
  }
  final confirmed = await showAppConfirmDialog(
    context,
    title: l10n.repaymentFlipConfirmTitle,
    message: l10n.repaymentFlipConfirmMessage(
      resulting.isNegative ? 'owe' : 'owed',
      state.personName ?? l10n.personLabel,
      EgpFormatter(locale: locale).formatWithSymbol(resulting.abs()),
    ),
    confirmLabel: l10n.commonSave,
    cancelLabel: l10n.commonCancel,
  );
  if (confirmed) {
    await cubit.confirmFlip();
  } else {
    cubit.cancelFlip();
  }
}

/// What is outstanding now, and what the typed amount would leave (022 A2).
class _BalanceSummary extends StatelessWidget {
  const _BalanceSummary({required this.state});

  final RepaymentFormState state;

  @override
  Widget build(BuildContext context) {
    final balance = state.balance;
    if (balance == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final formatter = EgpFormatter(locale: locale);
    final net = balance.net;
    // Opposite-direction currencies with a missing rate: summing their
    // magnitudes would be meaningless, so no "remaining" number is shown.
    final outstanding = net != null
        ? formatter.formatWithSymbol(net.abs())
        : balance.status == null
        ? null
        : formatNativeNets(balance.nativeNets, locale: locale);
    final preview = state.preview;
    final name = state.personName ?? l10n.personLabel;
    String? previewText;
    if (preview != null) {
      final resulting = preview.resulting;
      if (preview.blocked || resulting == null) {
        previewText = l10n.repaymentPreviewUnavailable;
      } else {
        final amountText = formatter.formatWithSymbol(resulting.abs());
        previewText = switch (resulting.minorUnits.sign) {
          1 => l10n.personDetailTheyOweYou(name, amountText),
          -1 => l10n.personDetailYouOweThem(name, amountText),
          _ => l10n.personDetailSettled,
        };
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            outstanding == null
                ? l10n.repaymentPreviewUnavailable
                : l10n.repaymentOutstanding(outstanding),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (previewText != null)
            Text(previewText, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
