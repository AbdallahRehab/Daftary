import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../../currency/presentation/widgets/rate_needed_banner.dart';
import '../../../finance/presentation/widgets/finance_month_summary_card.dart';
import '../../domain/entities/overview_summary.dart';
import '../cubit/overview_cubit.dart';
import '../cubit/overview_state.dart';
import '../widgets/balance_amount_text.dart';
import '../widgets/overview_summary_card.dart';

/// A single screen that totals and groups every person into "owes me," "I
/// owe," and "settled" (User Story 4).
class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OverviewCubit>()..load(),
      child: const _OverviewView(),
    );
  }
}

class _OverviewView extends StatelessWidget {
  const _OverviewView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.overviewTitle)),
      body: BlocBuilder<OverviewCubit, OverviewState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == OverviewStatus.failure || state.summary == null) {
            return AppEmptyView(
              icon: Icons.error_outline,
              title: l10n.commonError,
              message: state.errorMessage ?? l10n.errorUnknown,
              actionLabel: l10n.commonRetry,
              onAction: () => context.read<OverviewCubit>().load(),
            );
          }

          final summary = state.summary!;
          if (state.isAllSettled) {
            return RefreshIndicator(
              onRefresh: () => context.read<OverviewCubit>().load(),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // Settled balances do not mean nothing happened this
                  // month, so the finance link stays visible here.
                  const FinanceMonthSummaryCard(),
                  SizedBox(
                    height: 420,
                    child: AppEmptyView(
                      icon: Icons.check_circle_outline,
                      title: l10n.overviewAllSettledTitle,
                      message: l10n.overviewAllSettledMessage,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<OverviewCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // 018 FR-009: a total that depends on a currency with no
                // exchange rate is shown as blocked, naming the currencies.
                if (summary.isBlocked) ...[
                  RateNeededBanner(
                    missingRatesFor: summary.missingRatesFor,
                    onSetRate: () => openExchangeRateSettings(context),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                OverviewSummaryCard(
                  totalOwedToUser: summary.totalOwedToUser,
                  totalUserOwes: summary.totalUserOwes,
                ),
                const SizedBox(height: AppSpacing.md),
                // The finance section's entry point (research.md
                // Decision 9). It brings its own Cubit, so nothing about
                // OverviewCubit's existing behavior changes.
                const FinanceMonthSummaryCard(),
                if (summary.peopleTheyOweYou.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SectionHeader(title: l10n.overviewSectionTheyOweYou),
                  ...summary.peopleTheyOweYou.map(
                    (p) => _PersonSummaryRow(
                      summary: p,
                      color: context.financeColors.positive,
                    ),
                  ),
                ],
                if (summary.peopleYouOweThem.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SectionHeader(title: l10n.overviewSectionYouOweThem),
                  ...summary.peopleYouOweThem.map(
                    (p) => _PersonSummaryRow(
                      summary: p,
                      color: context.financeColors.negative,
                    ),
                  ),
                ],
                // Blocked balances whose currencies point in opposite
                // directions: neither "owes you" nor "you owe" is knowable
                // until a rate is set.
                if (summary.peopleRateNeeded.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SectionHeader(title: l10n.rateNeededTitle),
                  ...summary.peopleRateNeeded.map(
                    (p) => _PersonSummaryRow(summary: p),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(title, style: AppTypography.title),
    );
  }
}

class _PersonSummaryRow extends StatelessWidget {
  const _PersonSummaryRow({required this.summary, this.color});

  final PersonSummary summary;

  /// The amount's color; `null` for a row whose direction is unknown.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final net = summary.net;
    final amountText = net != null
        ? EgpFormatter(locale: locale).formatWithSymbol(net.abs())
        : formatNativeNets(summary.nativeNets, locale: locale);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: () => context.push('/people/${summary.personId}'),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(summary.name, style: AppTypography.body),
                  if (summary.isArchived)
                    Text(
                      l10n.archivedLabel,
                      style: AppTypography.bodyMuted.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (summary.isBlocked) ...[
              Icon(
                Icons.currency_exchange,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                semanticLabel: l10n.rateNeededTitle,
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            // Only a blocked row's multi-currency text can grow long, so
            // only it is allowed to shrink/wrap — single-amount rows keep
            // their intrinsic width exactly as before 018.
            if (summary.isBlocked)
              Flexible(child: _amount(amountText))
            else
              _amount(amountText),
          ],
        ),
      ),
    );
  }

  Widget _amount(String text) => Text(
    text,
    textAlign: TextAlign.end,
    style: AppTypography.body.copyWith(
      color: color,
      fontWeight: FontWeight.w600,
    ),
  );
}
