import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../domain/entities/overview_summary.dart';
import '../cubit/overview_cubit.dart';
import '../cubit/overview_state.dart';
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
                children: [
                  SizedBox(
                    height: 480,
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
                OverviewSummaryCard(
                  totalOwedToUser: summary.totalOwedToUser,
                  totalUserOwes: summary.totalUserOwes,
                ),
                if (summary.peopleTheyOweYou.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SectionHeader(title: l10n.overviewSectionTheyOweYou),
                  ...summary.peopleTheyOweYou.map(
                    (p) => _PersonSummaryRow(summary: p),
                  ),
                ],
                if (summary.peopleYouOweThem.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SectionHeader(title: l10n.overviewSectionYouOweThem),
                  ...summary.peopleYouOweThem.map(
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
  const _PersonSummaryRow({required this.summary});

  final PersonSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formatter = EgpFormatter(
      locale: Localizations.localeOf(context).languageCode,
    );
    final color = summary.net.isPositive
        ? context.financeColors.positive
        : context.financeColors.negative;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        title: Text(summary.name),
        subtitle: summary.isArchived ? Text(l10n.archivedLabel) : null,
        trailing: Text(
          formatter.formatWithSymbol(summary.net.abs()),
          style: AppTypography.body.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: () => context.push('/people/${summary.personId}'),
      ),
    );
  }
}
