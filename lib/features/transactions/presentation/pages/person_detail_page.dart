import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/glass/app_fab.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/failure_message.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../../currency/presentation/widgets/rate_needed_banner.dart';
import '../../../people/domain/entities/person.dart';
import '../../domain/entities/money_transaction.dart';
import '../../domain/entities/person_balance.dart';
import '../cubit/person_detail_cubit.dart';
import '../cubit/person_detail_state.dart';
import '../widgets/balance_amount_text.dart';
import '../widgets/balance_status_badge.dart';
import '../widgets/delete_transaction_confirm_dialog.dart';
import '../widgets/transaction_list_tile.dart';
import 'transaction_edit_page.dart';

/// Opening a person shows their current balance/status and full
/// chronological history (User Story 2).
class PersonDetailPage extends StatelessWidget {
  const PersonDetailPage({required this.personId, super.key});

  final String personId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PersonDetailCubit>()..load(personId),
      child: _PersonDetailView(personId: personId),
    );
  }
}

class _PersonDetailView extends StatelessWidget {
  const _PersonDetailView({required this.personId});

  final String personId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      appBar: AppTopBar(
        // The global-FAB "record transaction" flow (`PeopleListPage`) can
        // land here via `context.push('/people/$id')` after the form pops
        // with no bound personId, which is always poppable — but this page
        // can in principle be reached with nothing to pop back to, so the
        // fallback keeps a user from being stranded. When something IS
        // poppable (e.g. reached by tapping a row in `PeopleListPage`/
        // `OverviewPage`), the default back button still applies so "back"
        // returns to that originating screen.
        leading: Navigator.canPop(context)
            ? null
            : IconButton(
                icon: const BackButtonIcon(),
                tooltip: l10n.peopleListTitle,
                onPressed: () => context.go('/people'),
              ),
        title: BlocSelector<PersonDetailCubit, PersonDetailState, String>(
          selector: (state) => state.person?.name ?? '',
          builder: (context, name) => Text(name),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.commonEdit,
            onPressed: () => _editPerson(context),
          ),
        ],
      ),
      body: BlocConsumer<PersonDetailCubit, PersonDetailState>(
        listenWhen: (previous, current) =>
            current.status == PersonDetailStatus.success &&
            current.failure != null &&
            previous.failure != current.failure,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(l10n.messageFor(state.failure))),
            );
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == PersonDetailStatus.failure ||
              state.person == null ||
              state.balance == null) {
            return AppEmptyView(
              icon: Icons.error_outline,
              title: l10n.errorLoadTitle,
              message: l10n.messageFor(state.failure),
              actionLabel: l10n.commonRetry,
              onAction: () => context.read<PersonDetailCubit>().load(personId),
            );
          }

          final person = state.person!;
          final balance = state.balance!;
          final locale = Localizations.localeOf(context).languageCode;
          final formatter = EgpFormatter(locale: locale);
          final net = balance.net;
          // 018: a blocked balance (a currency with no exchange rate) has
          // no primary-currency net; its per-currency amounts are shown in
          // their own currencies instead (FR-009/FR-010).
          final amountText = net != null
              ? formatter.formatWithSymbol(net.abs())
              : formatNativeNets(balance.nativeNets, locale: locale);
          final status = balance.status;
          final headline = switch (status) {
            RelationshipStatus.theyOweYou => l10n.personDetailTheyOweYou(
              person.name,
              amountText,
            ),
            RelationshipStatus.youOweThem => l10n.personDetailYouOweThem(
              person.name,
              amountText,
            ),
            RelationshipStatus.settled => l10n.personDetailSettled,
            // Opposite-direction currencies with a missing rate: the
            // direction itself is unknown until a rate is set.
            null => person.name,
          };
          // The headline is the single most important number on this
          // screen — color it the same way its amount is colored
          // everywhere else (Overview rows, the balance badge, transaction
          // amounts) instead of leaving it in the default text color.
          final headlineColor = switch (status) {
            RelationshipStatus.theyOweYou => context.financeColors.positive,
            RelationshipStatus.youOweThem => context.financeColors.negative,
            RelationshipStatus.settled || null => null,
          };

          // One scroll view for the header and the history, so a long name,
          // a rate-needed banner, landscape, or a large system font can
          // never squeeze the history out or overflow the screen.
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  // CustomScrollView has no padding of its own: under glass
                  // the header takes the top inset, the history the bottom.
                  padding:
                      const EdgeInsets.all(AppSpacing.md) +
                      AppGlassInsets.of(context).copyWith(bottom: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headline,
                        style: AppTypography.headline.copyWith(
                          color: headlineColor,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Wraps rather than overflowing when the badge and the
                      // repayment action don't fit on one line.
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          if (status != null)
                            BalanceStatusBadge(status: status),
                          if (status != RelationshipStatus.settled)
                            TextButton.icon(
                              onPressed: () => _recordRepayment(context),
                              icon: const Icon(Icons.undo),
                              label: Text(l10n.recordRepaymentAction),
                            ),
                        ],
                      ),
                      if (balance.isBlocked) ...[
                        const SizedBox(height: AppSpacing.sm),
                        RateNeededBanner(
                          missingRatesFor: balance.missingRatesFor,
                          onSetRate: () => openExchangeRateSettings(context),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: Divider(height: 1)),
              if (state.history.isEmpty)
                SliverFillRemaining(
                  child: AppEmptyView(
                    title: l10n.historyEmptyTitle,
                    message: l10n.historyEmptyMessage(person.name),
                    actionLabel: l10n.recordTransactionAction,
                    onAction: () => _recordTransaction(context),
                  ),
                )
              else
                SliverPadding(
                  // Clears the FAB so the last row's amount and delete
                  // action are never hidden underneath it.
                  padding:
                      const EdgeInsets.only(bottom: 88) +
                      AppGlassInsets.of(context).copyWith(top: 0),
                  sliver: SliverList.separated(
                    // Oldest first — FR-010 and US2's acceptance scenarios
                    // both require chronological order.
                    itemCount: state.history.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      indent: AppSpacing.md,
                      endIndent: AppSpacing.md,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    itemBuilder: (context, index) {
                      final transaction = state.history[index];
                      return TransactionListTile(
                        transaction: transaction,
                        primaryCurrency: state.primaryCurrency,
                        onTap: () =>
                            _editTransaction(context, transaction, person),
                        onDelete: () =>
                            _deleteTransaction(context, transaction.id),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: AppFab(
        onPressed: () => _recordTransaction(context),
        tooltip: l10n.recordTransactionAction,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _recordTransaction(BuildContext context) async {
    await context.push<MoneyTransaction?>(
      '/transactions/new?personId=$personId',
    );
    if (context.mounted) {
      await context.read<PersonDetailCubit>().refresh();
    }
  }

  Future<void> _recordRepayment(BuildContext context) async {
    await context.push('/people/$personId/repayment');
    if (context.mounted) {
      await context.read<PersonDetailCubit>().refresh();
    }
  }

  Future<void> _editPerson(BuildContext context) async {
    await context.push('/people/$personId/edit');
    if (context.mounted) {
      await context.read<PersonDetailCubit>().refresh();
    }
  }

  Future<void> _editTransaction(
    BuildContext context,
    MoneyTransaction transaction,
    Person person,
  ) async {
    await context.push<MoneyTransaction?>(
      '/transactions/${transaction.id}/edit',
      extra: TransactionEditArgs(transaction: transaction, person: person),
    );
    if (context.mounted) {
      await context.read<PersonDetailCubit>().refresh();
    }
  }

  Future<void> _deleteTransaction(
    BuildContext context,
    String transactionId,
  ) async {
    final confirmed = await showDeleteTransactionConfirmDialog(context);
    if (confirmed && context.mounted) {
      await context.read<PersonDetailCubit>().deleteTransaction(transactionId);
    }
  }
}
