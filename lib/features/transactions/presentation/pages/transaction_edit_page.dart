import 'package:flutter/material.dart';

import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../people/domain/entities/person.dart';
import '../../domain/entities/money_transaction.dart';
import 'transaction_form_page.dart';

/// Arguments passed via `GoRouterState.extra` when navigating to
/// `/transactions/:id/edit` — the caller (a transaction's own list tile)
/// already holds both in memory, so no extra DB round-trip is needed
/// (`TransactionsRepository` has no `getTransactionById`; see
/// `contracts/transactions_repository.md`).
class TransactionEditArgs {
  const TransactionEditArgs({required this.transaction, required this.person});

  final MoneyTransaction transaction;
  final Person person;
}

/// Router entry point for editing a transaction (T103 — US6). Requires
/// [TransactionEditArgs] via `extra`; falls back to an error view if a
/// route is reached without them (e.g. a deep link, which this feature
/// doesn't support).
class TransactionEditPage extends StatelessWidget {
  const TransactionEditPage({
    required this.transactionId,
    super.key,
    this.args,
  });

  final String transactionId;
  final TransactionEditArgs? args;

  @override
  Widget build(BuildContext context) {
    final currentArgs = args;
    if (currentArgs == null) {
      final l10n = AppLocalizations.of(context)!;
      return Scaffold(
        body: AppEmptyView(
          icon: Icons.error_outline,
          title: l10n.errorLoadTitle,
          message: l10n.errorNotFound,
        ),
      );
    }
    return TransactionFormPage(
      editingTransaction: currentArgs.transaction,
      editingPerson: currentArgs.person,
    );
  }
}
