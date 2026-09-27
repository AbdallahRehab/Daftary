import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/design_system/currency_picker.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../cubit/exchange_rate_form_cubit.dart';
import '../cubit/exchange_rate_form_state.dart';

/// Add or edit one exchange rate (US3, FR-006): "1 [currency] = x
/// [primary]". With [editingCode] the currency is fixed and the stored
/// rate is prefilled; otherwise the picker offers every currency except
/// the primary, optionally starting on [initialCode].
class ExchangeRateFormPage extends StatelessWidget {
  const ExchangeRateFormPage({
    this.editingCode,
    this.relativeToCode,
    this.initialCode,
    super.key,
  });

  final String? editingCode;
  final String? relativeToCode;
  final String? initialCode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ExchangeRateFormCubit>()
        ..load(
          editingCode: editingCode,
          relativeToCode: relativeToCode,
          initialCode: initialCode,
        ),
      child: const ExchangeRateFormView(),
    );
  }
}

class ExchangeRateFormView extends StatefulWidget {
  const ExchangeRateFormView({super.key});

  static const Key rateFieldKey = Key('exchange_rate_value_field');
  static const Key saveButtonKey = Key('exchange_rate_save');

  @override
  State<ExchangeRateFormView> createState() => _ExchangeRateFormViewState();
}

class _ExchangeRateFormViewState extends State<ExchangeRateFormView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      appBar: AppTopBar(title: Text(l10n.exchangeRateEditTitle)),
      body: BlocConsumer<ExchangeRateFormCubit, ExchangeRateFormState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            (!previous.isSaved && current.isSaved) ||
            (!previous.isSaveFailing && current.isSaveFailing),
        listener: (context, state) {
          if (state.isSaved) {
            if (context.canPop()) context.pop();
            return;
          }
          if (state.isSaveFailing) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(l10n.exchangeRateSaveFailed)),
              );
            return;
          }
          if (state.status == ExchangeRateFormStatus.ready &&
              _controller.text != state.rateText) {
            _controller.text = state.rateText;
          }
        },
        builder: (context, state) => switch (state.status) {
          ExchangeRateFormStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          ExchangeRateFormStatus.loadFailure => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                l10n.currencySettingsLoadFailed,
                textAlign: TextAlign.center,
                style: AppTypography.body,
              ),
            ),
          ),
          ExchangeRateFormStatus.ready => _buildReady(context, state),
        },
      ),
    );
  }

  Widget _buildReady(BuildContext context, ExchangeRateFormState state) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ExchangeRateFormCubit>();
    final currency = state.currency;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md) + AppGlassInsets.of(context),
      children: [
        if (currency != null)
          CurrencyPicker(
            value: currency,
            currencies: state.availableCurrencies,
            enabled: !state.isEditing && !state.isSubmitting,
            onChanged: cubit.selectCurrency,
          ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          key: ExchangeRateFormView.rateFieldKey,
          controller: _controller,
          label: l10n.exchangeRateValueLabel(
            currency?.code ?? '',
            state.relativeTo.code,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          textDirection: TextDirection.ltr,
          autofocus: !state.isEditing,
          errorText: state.showRateError ? l10n.exchangeRateInvalid : null,
          onChanged: cubit.rateChanged,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.exchangeRatesManualDisclosure,
          style: AppTypography.bodyMuted.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          key: ExchangeRateFormView.saveButtonKey,
          label: l10n.exchangeRateSave,
          isLoading: state.isSubmitting,
          onPressed: state.canSave ? cubit.save : null,
        ),
      ],
    );
  }
}
