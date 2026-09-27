import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/date/app_date_formatter.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/failure_message.dart';
import '../../../../core/l10n/numeral_locale.dart';
import '../../../../core/money/numeral_parser.dart';
import '../../domain/entities/sync_conflict_item.dart';
import '../../domain/entities/sync_failed_item.dart';
import '../../domain/entities/sync_runtime_status.dart';
import '../../domain/entities/sync_status.dart';
import '../cubit/email_link_state.dart';
import '../cubit/sync_conflicts_cubit.dart';
import '../cubit/sync_conflicts_state.dart';
import '../cubit/sync_settings_cubit.dart';
import '../cubit/sync_settings_state.dart';
import '../widgets/conflict_resolution_sheet.dart';
import '../widgets/email_link_sheet.dart';
import '../widgets/sync_status_line.dart';

/// Route paths of the cloud sync settings.
abstract final class SyncSettingsRoutes {
  static const settings = '/settings/sync';
}

/// 021 T080: cloud backup and sync (contracts/dart-interfaces.md §5): the
/// status, the counts, "Sync now", the switch, the account, the open
/// conflicts and the failed changes.
class SyncSettingsPage extends StatelessWidget {
  const SyncSettingsPage({super.key});

  static const syncNowKey = Key('sync_now_button');
  static const enabledSwitchKey = Key('sync_enabled_switch');
  static const linkEmailKey = Key('sync_link_email');
  static const signInKey = Key('sync_sign_in');
  static const linkedEmailKey = Key('sync_linked_email');
  static const retryKey = Key('sync_retry_failed');
  static const problemKey = Key('sync_problem_message');

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Eager, so both lists are read while the status is still loading.
        BlocProvider(
          lazy: false,
          create: (_) => getIt<SyncSettingsCubit>()..subscribe(),
        ),
        BlocProvider(
          lazy: false,
          create: (_) => getIt<SyncConflictsCubit>()..subscribe(),
        ),
      ],
      child: const _SyncSettingsView(),
    );
  }
}

class _SyncSettingsView extends StatelessWidget {
  const _SyncSettingsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      appBar: AppTopBar(title: Text(l10n.syncSettingsTitle)),
      body: BlocConsumer<SyncSettingsCubit, SyncSettingsState>(
        listenWhen: (previous, current) =>
            current.actionFailure != null &&
            previous.actionFailure != current.actionFailure,
        listener: (context, state) => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(l10n.messageFor(state.actionFailure))),
          ),
        builder: (context, state) {
          final status = state.status;
          if (status == null) {
            return state.loadStatus == SyncSettingsLoadStatus.failure
                ? Center(child: Text(l10n.messageFor(state.actionFailure)))
                : const Center(child: CircularProgressIndicator());
          }
          final active = status.available && status.enabled;
          return ListView(
            padding:
                const EdgeInsets.all(AppSpacing.md) +
                AppGlassInsets.of(context),
            children: [
              _StatusCard(state: state, status: status),
              if (status.available) ...[
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: SwitchListTile(
                    key: SyncSettingsPage.enabledSwitchKey,
                    title: Text(l10n.syncEnabledTitle),
                    subtitle: Text(l10n.syncEnabledSubtitle),
                    value: status.enabled,
                    onChanged: state.isTogglingEnabled
                        ? null
                        : context.read<SyncSettingsCubit>().setEnabled,
                  ),
                ),
              ],
              if (active) ...[
                const SizedBox(height: AppSpacing.lg),
                _Section(
                  icon: Icons.person_outline,
                  title: l10n.syncAccountSectionTitle,
                  child: _AccountTiles(status: status),
                ),
              ],
              const _ConflictsSection(),
              if (state.failedItems.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _FailedSection(state: state, enabled: active),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state, required this.status});

  final SyncSettingsState state;
  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final muted = AppTypography.bodyMuted.copyWith(
      color: colors.onSurfaceVariant,
    );
    final lastSuccessAt = status.lastSuccessAt;
    final locale = Localizations.localeOf(context).languageCode;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SyncStatusLine(status: status),
          if (status.available) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              lastSuccessAt == null
                  ? l10n.syncNeverSynced
                  : l10n.syncLastSynced(_dateTime(lastSuccessAt, locale)),
              style: muted,
            ),
          ],
          if (status.problem == SyncProblem.unreadableCloudData &&
              status.enabled) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.syncProblemUnreadableMessage,
              key: SyncSettingsPage.problemKey,
              style: muted,
            ),
          ],
          if (status.available) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _Count(label: l10n.syncCountPending, value: status.pending),
                _Count(label: l10n.syncCountFailed, value: status.failed),
                _Count(label: l10n.syncCountConflicts, value: status.conflicts),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              key: SyncSettingsPage.syncNowKey,
              label: l10n.syncNowButton,
              icon: Icons.sync,
              isLoading:
                  status.runtime == SyncRuntimeStatus.syncing ||
                  state.isRequestingSync,
              onPressed: state.canSyncNow
                  ? context.read<SyncSettingsCubit>().syncNow
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  static String _dateTime(DateTime at, String locale) {
    final date = AppDateFormatter(locale: locale).format(at);
    final time = NumeralParser.toWesternDigits(
      DateFormat.jm(numeralLocaleFor(locale)).format(at),
    );
    return '$date $time';
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: AppTypography.title.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            style: AppTypography.label.copyWith(color: muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AccountTiles extends StatelessWidget {
  const _AccountTiles({required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final masked = status.linkedEmailMasked;
    if (!status.isAnonymous && masked != null) {
      return ListTile(
        key: SyncSettingsPage.linkedEmailKey,
        leading: const Icon(Icons.verified_user_outlined),
        // An address reads left to right in both languages.
        title: Text(l10n.syncLinkedAs('\u2066$masked\u2069')),
      );
    }
    return Column(
      children: [
        ListTile(
          key: SyncSettingsPage.linkEmailKey,
          leading: const Icon(Icons.alternate_email),
          title: Text(l10n.syncLinkEmailTitle),
          subtitle: Text(l10n.syncLinkEmailSubtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showEmailLinkSheet(context, EmailLinkMode.link),
        ),
        const Divider(height: 1),
        ListTile(
          key: SyncSettingsPage.signInKey,
          leading: const Icon(Icons.login),
          title: Text(l10n.syncSignInTitle),
          subtitle: Text(l10n.syncSignInSubtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showEmailLinkSheet(context, EmailLinkMode.signIn),
        ),
      ],
    );
  }
}

class _ConflictsSection extends StatelessWidget {
  const _ConflictsSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    return BlocBuilder<SyncConflictsCubit, SyncConflictsState>(
      buildWhen: (previous, current) => previous.items != current.items,
      builder: (context, state) {
        if (state.items.isEmpty) return const SizedBox.shrink();
        final formatter = AppDateFormatter(locale: locale);
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg),
          child: _Section(
            icon: Icons.sync_problem,
            title: l10n.syncConflictsSectionTitle,
            child: Column(
              children: [
                for (final item in state.items)
                  ListTile(
                    key: Key('sync_conflict_${item.entityId}'),
                    leading: const Icon(Icons.sync_problem),
                    title: Text(switch (item.entityType) {
                      ConflictEntityType.moneyTransaction =>
                        l10n.syncKindTransaction,
                      ConflictEntityType.financeEntry =>
                        l10n.syncKindFinanceEntry,
                    }),
                    subtitle: Text(
                      l10n.syncConflictItemSubtitle(
                        formatter.format(item.detectedAt),
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showConflictResolutionSheet(context, item),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FailedSection extends StatelessWidget {
  const _FailedSection({required this.state, required this.enabled});

  final SyncSettingsState state;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _Section(
      icon: Icons.error_outline,
      title: l10n.syncFailedSectionTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in state.failedItems)
            ListTile(
              leading: const Icon(Icons.cloud_off_outlined),
              title: Text(_kind(l10n, item.kind)),
              subtitle: Text(_reason(l10n, item.reason)),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppSecondaryButton(
              key: SyncSettingsPage.retryKey,
              label: l10n.syncRetryButton,
              onPressed: enabled && !state.isRetrying
                  ? context.read<SyncSettingsCubit>().retryFailed
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  static String _kind(AppLocalizations l10n, SyncItemKind kind) =>
      switch (kind) {
        SyncItemKind.person => l10n.syncKindPerson,
        SyncItemKind.transaction => l10n.syncKindTransaction,
        SyncItemKind.transactionHistory => l10n.syncKindTransactionHistory,
        SyncItemKind.financeCategory => l10n.syncKindFinanceCategory,
        SyncItemKind.financeEntry => l10n.syncKindFinanceEntry,
        SyncItemKind.exchangeRate => l10n.syncKindExchangeRate,
        SyncItemKind.primaryCurrency => l10n.syncKindPrimaryCurrency,
        SyncItemKind.conflictResolution => l10n.syncKindConflictResolution,
      };

  static String _reason(AppLocalizations l10n, SyncFailedReason reason) =>
      switch (reason) {
        SyncFailedReason.personHasTransactions =>
          l10n.syncFailedReasonPersonHasTransactions,
        SyncFailedReason.categoryTypeMismatch =>
          l10n.syncFailedReasonCategoryTypeMismatch,
        SyncFailedReason.invalid => l10n.syncFailedReasonInvalid,
        SyncFailedReason.other => l10n.syncFailedReasonOther,
      };
}

/// A titled group on an [AppCard], like the Settings page's sections.
class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            bottom: AppSpacing.xs,
            left: AppSpacing.xs,
            right: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: muted),
              const SizedBox(width: AppSpacing.xs),
              Text(title, style: AppTypography.label.copyWith(color: muted)),
            ],
          ),
        ),
        AppCard(padding: EdgeInsets.zero, child: child),
      ],
    );
  }
}
