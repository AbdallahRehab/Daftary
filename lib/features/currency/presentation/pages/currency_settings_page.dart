import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/currency.dart';
import '../cubit/primary_currency_cubit.dart';
import '../cubit/primary_currency_state.dart';
import '../cubit/rate_input.dart';

/// Route paths for the currency settings screens (T051), kept beside the
/// entry page. `/settings/currency/rates` is also pushed by every feature's
/// "rate needed" banner (FR-009).
abstract final class CurrencyRoutes {
  static const String settings = '/settings/currency';
  static const String rates = '/settings/currency/rates';
  static const String newRate = '/settings/currency/rates/new';

  /// Add-rate form, optionally preselecting [currencyCode].
  static String newRateFor(String? currencyCode) => currencyCode == null
      ? newRate
      : Uri(path: newRate, queryParameters: {'code': currencyCode}).toString();

  /// Edit form for the stored pair ([currencyCode] → [relativeToCode]);
  /// [relativeToCode] defaults to the current primary currency.
  static String editRate(String currencyCode, {String? relativeToCode}) {
    final path = '/settings/currency/rates/$currencyCode/edit';
    return relativeToCode == null
        ? path
        : Uri(path: path, queryParameters: {'to': relativeToCode}).toString();
  }
}

/// Currency settings (US3): the primary currency and a link to the
/// exchange-rate list. Provides its own [PrimaryCurrencyCubit].
class CurrencySettingsPage extends StatelessWidget {
  const CurrencySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PrimaryCurrencyCubit>()..load(),
      child: const CurrencySettingsView(),
    );
  }
}

class CurrencySettingsView extends StatelessWidget {
  const CurrencySettingsView({super.key});

  static const Key changeButtonKey = Key('primary_currency_change');
  static const Key ratesEntryKey = Key('currency_rates_entry');
  static const Key primaryTileKey = Key('primary_currency_tile');

  Future<void> _pickPrimary(BuildContext context, Currency current) async {
    final cubit = context.read<PrimaryCurrencyCubit>();
    final picked = await showDialog<Currency>(
      context: context,
      builder: (_) => _CurrencyChoiceDialog(current: current),
    );
    if (picked != null) await cubit.changePrimary(picked);
  }

  Future<void> _promptForRate(
    BuildContext context,
    PrimaryCurrencyState state,
  ) async {
    final cubit = context.read<PrimaryCurrencyCubit>();
    final text = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SwitchRateDialog(
        previous: state.rateRequiredFor!,
        next: state.pendingTarget!,
      ),
    );
    if (text == null) {
      cubit.cancelPendingSwitch();
    } else {
      await cubit.confirmSwitchWithRate(text);
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.currencySettingsTitle)),
      body: BlocConsumer<PrimaryCurrencyCubit, PrimaryCurrencyState>(
        listenWhen: (previous, current) =>
            previous.outcome != current.outcome ||
            previous.isRatePromptPending != current.isRatePromptPending,
        listener: (context, state) {
          switch (state.outcome) {
            case PrimaryCurrencyChangeOutcome.changed:
              _showSnack(context, l10n.primaryCurrencyChanged);
            case PrimaryCurrencyChangeOutcome.failed:
              _showSnack(context, l10n.primaryCurrencyChangeFailed);
            case PrimaryCurrencyChangeOutcome.invalidRate:
              _showSnack(context, l10n.exchangeRateInvalid);
            case PrimaryCurrencyChangeOutcome.none:
              break;
          }
          if (state.isRatePromptPending && !state.isSubmitting) {
            _promptForRate(context, state);
          }
        },
        builder: (context, state) => switch (state.status) {
          PrimaryCurrencyStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          PrimaryCurrencyStatus.loadFailure => _LoadFailureView(
            onRetry: () => context.read<PrimaryCurrencyCubit>().load(),
          ),
          PrimaryCurrencyStatus.ready => _buildReady(context, state),
        },
      ),
    );
  }

  Widget _buildReady(BuildContext context, PrimaryCurrencyState state) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final languageCode = Localizations.localeOf(context).languageCode;
    final primary = state.primary;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            key: primaryTileKey,
            leading: Icon(Icons.payments_outlined, color: colorScheme.primary),
            title: Text(l10n.primaryCurrencyLabel),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${primary.displayName(languageCode)} (${primary.code})',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.primaryCurrencyDescription,
                  style: AppTypography.bodyMuted.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            isThreeLine: true,
            trailing: TextButton(
              key: changeButtonKey,
              onPressed: state.isSubmitting
                  ? null
                  : () => _pickPrimary(context, primary),
              child: Text(l10n.primaryCurrencyChange),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            key: ratesEntryKey,
            leading: Icon(
              Icons.currency_exchange_outlined,
              color: colorScheme.primary,
            ),
            title: Text(l10n.exchangeRatesTitle),
            subtitle: Text(l10n.exchangeRatesManualDisclosure),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(CurrencyRoutes.rates),
          ),
        ),
      ],
    );
  }
}

/// Lists the catalog; returns the chosen [Currency], or null on dismiss.
class _CurrencyChoiceDialog extends StatelessWidget {
  const _CurrencyChoiceDialog({required this.current});

  final Currency current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    return SimpleDialog(
      title: Text(l10n.primaryCurrencyLabel),
      children: [
        RadioGroup<Currency>(
          groupValue: current,
          onChanged: (currency) => Navigator.of(context).pop(currency),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final currency in Currency.catalog)
                RadioListTile<Currency>(
                  key: Key('primary_currency_option_${currency.code}'),
                  value: currency,
                  title: Text(
                    '${currency.displayName(languageCode)} (${currency.code})',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// FR-012's forced-rate prompt: asks how many [next] one [previous] is
/// worth. Returns the entered text once it parses to a positive rate, or
/// null when cancelled.
class SwitchRateDialog extends StatefulWidget {
  const SwitchRateDialog({
    required this.previous,
    required this.next,
    super.key,
  });

  static const Key rateFieldKey = Key('switch_rate_field');
  static const Key confirmKey = Key('switch_rate_confirm');

  final Currency previous;
  final Currency next;

  @override
  State<SwitchRateDialog> createState() => _SwitchRateDialogState();
}

class _SwitchRateDialogState extends State<SwitchRateDialog> {
  final _controller = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (RateInput.parse(_controller.text) == null) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.primaryCurrencySwitchRateTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.primaryCurrencySwitchRateMessage(
              widget.previous.code,
              widget.next.code,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: SwitchRateDialog.rateFieldKey,
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onChanged: (_) {
              if (_showError) setState(() => _showError = false);
            },
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: l10n.exchangeRateValueLabel(
                widget.previous.code,
                widget.next.code,
              ),
              errorText: _showError ? l10n.exchangeRateInvalid : null,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: SwitchRateDialog.confirmKey,
          onPressed: _submit,
          child: Text(l10n.exchangeRateSave),
        ),
      ],
    );
  }
}

class _LoadFailureView extends StatelessWidget {
  const _LoadFailureView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.currencySettingsLoadFailed,
              textAlign: TextAlign.center,
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
          ],
        ),
      ),
    );
  }
}
