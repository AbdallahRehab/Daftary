import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/occasion_type.dart';
import '../cubit/occasions_list_cubit.dart';
import '../cubit/occasions_list_state.dart';
import '../widgets/occasion_list_tile.dart';
import '../widgets/occasion_type_chip.dart';

/// The occasions section's home: every active occasion, most recent first,
/// narrowable by name, type and date range (FR-015).
class OccasionsListPage extends StatelessWidget {
  const OccasionsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OccasionsListCubit>()..load(),
      child: const _OccasionsListView(),
    );
  }
}

class _OccasionsListView extends StatelessWidget {
  const _OccasionsListView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<OccasionsListCubit>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.occasionsTitle),
        actions: [
          IconButton(
            tooltip: l10n.occasionArchivedAction,
            icon: const Icon(Icons.archive_outlined),
            onPressed: () async {
              await context.push('/occasions/archived');
              if (context.mounted) unawaited(cubit.load());
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/occasions/new');
          if (context.mounted) unawaited(cubit.load());
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.occasionAddAction),
      ),
      body: BlocBuilder<OccasionsListCubit, OccasionsListState>(
        builder: (context, state) {
          if (state.isLoading && state.occasions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // The first-run state replaces the whole screen, filters
          // included: there is nothing yet to filter, so offering the
          // controls would be noise around the one action that matters.
          if (state.isEmptyOverall) {
            return AppEmptyView(
              icon: Icons.celebration_outlined,
              title: l10n.occasionsEmptyTitle,
              message: l10n.occasionsEmptyMessage,
              actionLabel: l10n.occasionAddFirstAction,
              onAction: () async {
                await context.push('/occasions/new');
                if (context.mounted) unawaited(cubit.load());
              },
            );
          }

          return Column(
            children: [
              _Filters(state: state),
              Expanded(
                child: state.isEmptyForFilter
                    ? AppEmptyView(
                        icon: Icons.search_off,
                        title: l10n.occasionNoMatchTitle,
                        message: l10n.occasionNoMatchMessage,
                        actionLabel: l10n.occasionClearFiltersAction,
                        onAction: cubit.clearFilters,
                      )
                    : RefreshIndicator(
                        onRefresh: cubit.load,
                        // `builder`, never a Column of every row: the
                        // stated ceiling is ~2,000 occasions, and only the
                        // visible handful should ever be built.
                        child: ListView.builder(
                          itemCount: state.occasions.length,
                          itemBuilder: (context, index) {
                            final occasion = state.occasions[index];
                            return OccasionListTile(
                              occasion: occasion,
                              onTap: () async {
                                await context.push('/occasions/${occasion.id}');
                                if (context.mounted) unawaited(cubit.load());
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.state});

  final OccasionsListState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<OccasionsListCubit>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: l10n.occasionSearchHint,
            onChanged: cubit.searchChanged,
            suffixIcon: const Icon(Icons.search),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(l10n.occasionFilterAllTypes),
                  selected: state.filter.type == null,
                  onSelected: (_) => cubit.typeChanged(null),
                ),
                for (final type in OccasionType.standardValues) ...[
                  const SizedBox(width: AppSpacing.xs),
                  ChoiceChip(
                    label: Text(occasionTypeLabel(l10n, type)),
                    selected: state.filter.type == type,
                    onSelected: (selected) =>
                        cubit.typeChanged(selected ? type : null),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
