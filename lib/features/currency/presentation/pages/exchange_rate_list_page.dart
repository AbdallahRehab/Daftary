import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/date/app_date_formatter.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_confirm_dialog.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/exchange_rate.dart';
import '../cubit/exchange_rate_list_cubit.dart';
import '../cubit/exchange_rate_list_state.dart';
import '../cubit/rate_input.dart';
import 'currency_settings_page.dart';

/// The manually-maintained exchange rates (US3, FR-006/FR-007): each rate
/// as "1 USD = 50.25 EGP" with its last-updated date, under a persistent
/// "entered by you, never fetched" disclosure.
class ExchangeRateListPage extends StatelessWidget {
  const ExchangeRateListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ExchangeRateListCubit>()..load(),
      child: const ExchangeRateListView(),
    );
  }
}

class ExchangeRateListView extends StatelessWidget {
  const ExchangeRateListView({super.key});

  static const Key addButtonKey = Key('exchange_rate_add');
  static const Key disclosureKey = Key('exchange_rate_disclosure');

  Future<void> _open(BuildContext context, String location) async {
    final cubit = context.read<ExchangeRateListCubit>();
    await context.push<void>(location);
    // Reload whatever the form did — including nothing.
    if (!cubit.isClosed) await cubit.load();
  }

  Future<void> _confirmRemove(BuildContext context, ExchangeRate rate) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ExchangeRateListCubit>();
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.exchangeRateRemove,
      message: l10n.exchangeRateRemoveConfirm,
      confirmLabel: l10n.exchangeRateRemove,
      isDestructive: true,
    );
    if (confirmed) await cubit.remove(rate.currency.code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.exchangeRatesTitle)),
      floatingActionButton:
          BlocBuilder<ExchangeRateListCubit, ExchangeRateListState>(
            buildWhen: (p, c) => p.status != c.status,
            builder: (context, state) =>
                state.status == ExchangeRateListStatus.ready
                ? FloatingActionButton.extended(
                    key: addButtonKey,
                    onPressed: () => _open(context, CurrencyRoutes.newRate),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.exchangeRateAdd),
                  )
                : const SizedBox.shrink(),
          ),
      body: BlocConsumer<ExchangeRateListCubit, ExchangeRateListState>(
        listenWhen: (previous, current) =>
            !previous.isRemoveFailing && current.isRemoveFailing,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(l10n.exchangeRateSaveFailed)),
            );
        },
        builder: (context, state) => switch (state.status) {
          ExchangeRateListStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          ExchangeRateListStatus.loadFailure => Center(
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
                  TextButton(
                    onPressed: () =>
                        context.read<ExchangeRateListCubit>().load(),
                    child: Text(l10n.commonRetry),
                  ),
                ],
              ),
            ),
          ),
          ExchangeRateListStatus.ready => _buildReady(context, state),
        },
      ),
    );
  }

  Widget _buildReady(BuildContext context, ExchangeRateListState state) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormatter = AppDateFormatter(
      locale: Localizations.localeOf(context).languageCode,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxl + AppSpacing.xl,
      ),
      children: [
        // FR-007: persistent, never dismissible.
        Container(
          key: disclosureKey,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.exchangeRatesManualDisclosure,
                  style: AppTypography.bodyMuted.copyWith(
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.rates.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            child: Column(
              key: const Key('exchange_rates_empty'),
              children: [
                Icon(
                  Icons.currency_exchange_outlined,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.exchangeRatesEmpty,
                  textAlign: TextAlign.center,
                  style: AppTypography.title,
                ),
              ],
            ),
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (index, rate) in state.rates.indexed) ...[
                  if (index > 0) const Divider(height: 1),
                  _RateTile(
                    rate: rate,
                    lastUpdated: l10n.exchangeRateLastUpdated(
                      dateFormatter.format(rate.lastUpdatedAt),
                    ),
                    enabled: !state.isRemoving,
                    onTap: () => _open(
                      context,
                      CurrencyRoutes.editRate(
                        rate.currency.code,
                        relativeToCode: rate.relativeTo == state.primary
                            ? null
                            : rate.relativeTo.code,
                      ),
                    ),
                    onRemove: () => _confirmRemove(context, rate),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _RateTile extends StatelessWidget {
  const _RateTile({
    required this.rate,
    required this.lastUpdated,
    required this.enabled,
    required this.onTap,
    required this.onRemove,
  });

  final ExchangeRate rate;
  final String lastUpdated;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final code = rate.currency.code;
    return ListTile(
      key: Key('exchange_rate_tile_${code}_${rate.relativeTo.code}'),
      enabled: enabled,
      onTap: onTap,
      // Codes and digits are Latin: keep "1 USD = 50.25 EGP" reading
      // left-to-right under RTL too.
      title: Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            '1 $code = ${RateInput.format(rate.rateMicros)} '
            '${rate.relativeTo.code}',
            style: AppTypography.figure,
          ),
        ),
      ),
      subtitle: Text(
        lastUpdated,
        style: AppTypography.bodyMuted.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: IconButton(
        key: Key('exchange_rate_remove_$code'),
        tooltip: l10n.exchangeRateRemove,
        icon: Icon(Icons.delete_outline, color: colorScheme.error),
        onPressed: enabled ? onRemove : null,
      ),
    );
  }
}
