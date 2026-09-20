import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../transactions/domain/entities/person_balance.dart';
import '../cubit/person_list_cubit.dart';
import '../cubit/person_list_state.dart';
import '../widgets/person_list_tile.dart';

/// Searchable/filterable list of active people (FR-019) — the app's home/
/// landing screen (US5, T093).
class PeopleListPage extends StatelessWidget {
  const PeopleListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PersonListCubit>()..load(),
      child: const _PeopleListView(),
    );
  }
}

class _PeopleListView extends StatelessWidget {
  const _PeopleListView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.peopleListTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: l10n.addPersonAction,
            onPressed: () => _addPerson(context),
          ),
          IconButton(
            icon: const Icon(Icons.pie_chart_outline),
            onPressed: () => context.push('/overview'),
          ),
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: l10n.archivedPeopleAction,
            onPressed: () => context.push('/people/archived'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: AppTextField(
              label: l10n.searchPeopleHint,
              suffixIcon: const Icon(Icons.search),
              onChanged: (query) =>
                  context.read<PersonListCubit>().nameQueryChanged(query),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child:
                BlocSelector<
                  PersonListCubit,
                  PersonListState,
                  RelationshipStatus?
                >(
                  selector: (state) => state.statusFilter,
                  builder: (context, selectedFilter) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: l10n.filterAll,
                          selected: selectedFilter == null,
                          onSelected: () => context
                              .read<PersonListCubit>()
                              .statusFilterChanged(null),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _FilterChip(
                          label: l10n.filterTheyOweYou,
                          selected:
                              selectedFilter == RelationshipStatus.theyOweYou,
                          onSelected: () => context
                              .read<PersonListCubit>()
                              .statusFilterChanged(
                                RelationshipStatus.theyOweYou,
                              ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _FilterChip(
                          label: l10n.filterYouOweThem,
                          selected:
                              selectedFilter == RelationshipStatus.youOweThem,
                          onSelected: () => context
                              .read<PersonListCubit>()
                              .statusFilterChanged(
                                RelationshipStatus.youOweThem,
                              ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _FilterChip(
                          label: l10n.filterSettled,
                          selected:
                              selectedFilter == RelationshipStatus.settled,
                          onSelected: () => context
                              .read<PersonListCubit>()
                              .statusFilterChanged(RelationshipStatus.settled),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: BlocBuilder<PersonListCubit, PersonListState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == PersonListStatus.failure) {
                  return AppEmptyView(
                    icon: Icons.error_outline,
                    title: l10n.commonError,
                    message: state.errorMessage ?? l10n.errorUnknown,
                    actionLabel: l10n.commonRetry,
                    onAction: () => context.read<PersonListCubit>().load(),
                  );
                }
                if (state.items.isEmpty) {
                  return AppEmptyView(
                    title: l10n.emptyPeopleTitle,
                    message: l10n.emptyPeopleMessage,
                    actionLabel: l10n.addPersonAction,
                    onAction: () => _addPerson(context),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => context.read<PersonListCubit>().load(),
                  child: ListView.builder(
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return PersonListTile(
                        person: item.person,
                        balance: item.balance,
                        onTap: () => context.push('/people/${item.person.id}'),
                        onArchive: () => _archive(context, item.person.id),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // The MVP action (US1: record a transaction against a new or
      // existing person, via the form's own inline "create new person"
      // affordance — FR-002) is the primary FAB; creating a person with no
      // transaction yet stays reachable via the AppBar action above and
      // the empty-state action below.
      floatingActionButton: FloatingActionButton(
        onPressed: () => _recordTransaction(context),
        tooltip: l10n.recordTransactionAction,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addPerson(BuildContext context) async {
    await context.push('/people/new');
    if (context.mounted) {
      await context.read<PersonListCubit>().load();
    }
  }

  Future<void> _recordTransaction(BuildContext context) async {
    await context.push('/transactions/new');
    if (context.mounted) {
      await context.read<PersonListCubit>().load();
    }
  }

  Future<void> _archive(BuildContext context, String personId) {
    return context.read<PersonListCubit>().archive(personId);
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}
