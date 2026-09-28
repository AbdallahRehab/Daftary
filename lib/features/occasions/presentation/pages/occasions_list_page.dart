import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/design_system/glass/app_fab.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
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
///
/// 021: live — returning from a create, edit or detail screen needs no
/// reload, and a change applied by sync shows while the page is open
/// (FR-031).
class OccasionsListPage extends StatelessWidget {
  const OccasionsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OccasionsListCubit>()..subscribe(),
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

    return AppScaffold(
      appBar: AppTopBar(
        title: Text(l10n.occasionsTitle),
        actions: [
          IconButton(
            tooltip: l10n.occasionArchivedAction,
            icon: const Icon(Icons.archive_outlined),
            onPressed: () => context.push('/occasions/archived'),
          ),
        ],
      ),
      floatingActionButton: AppFab.extended(
        onPressed: () => context.push('/occasions/new'),
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
              onAction: () => context.push('/occasions/new'),
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
                        onRefresh: cubit.resubscribe,
                        // `builder`, never a Column of every row: the
                        // stated ceiling is ~2,000 occasions, and only the
                        // visible handful should ever be built.
                        child: ListView.builder(
                          // Clears the FAB so the last occasion is never
                          // hidden underneath it; under glass the filters
                          // above took the top inset, the list takes the
                          // bottom one.
                          padding:
                              const EdgeInsets.only(bottom: 88) +
                              AppGlassInsets.of(context).copyWith(top: 0),
                          itemCount: state.occasions.length,
                          itemBuilder: (context, index) {
                            final occasion = state.occasions[index];
                            return OccasionListTile(
                              occasion: occasion,
                              onTap: () =>
                                  context.push('/occasions/${occasion.id}'),
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
      // Under glass the body starts behind the app bar, so the filters take
      // the top inset (read below the scaffold).
      padding:
          const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ) +
          AppGlassInsets.of(context).copyWith(bottom: 0),
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
