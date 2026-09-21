import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../../people/domain/entities/person.dart';
import '../../domain/entities/money_transaction.dart';
import '../../domain/entities/person_balance.dart';
import '../cubit/person_detail_cubit.dart';
import '../cubit/person_detail_state.dart';
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
    return Scaffold(
      appBar: AppBar(
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
            current.errorMessage != null &&
            previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
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
              title: l10n.commonError,
              message: state.errorMessage ?? l10n.errorUnknown,
              actionLabel: l10n.commonRetry,
              onAction: () => context.read<PersonDetailCubit>().load(personId),
            );
          }

          final person = state.person!;
          final balance = state.balance!;
          final formatter = EgpFormatter(
            locale: Localizations.localeOf(context).languageCode,
          );
          final headline = switch (balance.status) {
            RelationshipStatus.theyOweYou => l10n.personDetailTheyOweYou(
              person.name,
              formatter.formatWithSymbol(balance.net),
            ),
            RelationshipStatus.youOweThem => l10n.personDetailYouOweThem(
              person.name,
              formatter.formatWithSymbol(balance.net.abs()),
            ),
            RelationshipStatus.settled => l10n.personDetailSettled,
          };

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(headline, style: AppTypography.headline),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        BalanceStatusBadge(status: balance.status),
                        const Spacer(),
                        if (balance.status != RelationshipStatus.settled)
                          TextButton.icon(
                            onPressed: () => _recordRepayment(context),
                            icon: const Icon(Icons.undo),
                            label: Text(l10n.recordRepaymentAction),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: state.history.isEmpty
                    ? AppEmptyView(
                        title: l10n.historyEmptyTitle,
                        message: l10n.historyEmptyMessage(person.name),
                        actionLabel: l10n.recordTransactionAction,
                        onAction: () => _recordTransaction(context),
                      )
                    : ListView.builder(
                        // Oldest first — FR-010 and US2's acceptance
                        // scenarios both require chronological order.
                        itemCount: state.history.length,
                        itemBuilder: (context, index) {
                          final transaction = state.history[index];
                          return TransactionListTile(
                            transaction: transaction,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _recordTransaction(context),
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
