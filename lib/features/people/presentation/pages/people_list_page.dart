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
import '../../../../core/l10n/failure_message.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../../../transactions/domain/entities/person_balance.dart';
import '../../domain/entities/person.dart';
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
      create: (_) => getIt<PersonListCubit>()..subscribe(),
      child: const _PeopleListView(),
    );
  }
}

class _PeopleListView extends StatefulWidget {
  const _PeopleListView();

  @override
  State<_PeopleListView> createState() => _PeopleListViewState();
}

class _PeopleListViewState extends State<_PeopleListView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<PersonListCubit, PersonListState>(
      // Archive is one tap from the row, so it always reports back: an Undo
      // snackbar on success, or the failure while the list stays on screen.
      listenWhen: (previous, current) =>
          (current.lastArchived != null &&
              previous.lastArchived != current.lastArchived) ||
          (current.failure != null &&
              current.status != PersonListStatus.failure &&
              previous.failure != current.failure),
      listener: (context, state) {
        final archived = state.lastArchived;
        final cubit = context.read<PersonListCubit>();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            archived != null
                ? SnackBar(
                    content: Text(l10n.personArchivedMessage(archived.name)),
                    action: SnackBarAction(
                      label: l10n.commonUndo,
                      onPressed: () => cubit.undoArchive(archived.id),
                    ),
                  )
                : SnackBar(content: Text(l10n.messageFor(state.failure))),
          );
      },
      child: _buildScaffold(context, l10n),
    );
  }

  Widget _buildScaffold(BuildContext context, AppLocalizations l10n) {
    return AppScaffold(
      appBar: AppTopBar(
        title: Text(l10n.peopleListTitle),
        // Overview already has its own bottom-navigation destination, so
        // surfacing it again here would just be a second path to the same
        // screen — this app bar keeps only the actions unique to People.
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: l10n.addPersonAction,
            onPressed: () => _addPerson(context),
          ),
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: l10n.archivedPeopleAction,
            onPressed: () => _openArchivedList(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Builder(
            builder: (context) => Padding(
              // Under glass the body starts behind the app bar: the header
              // takes the top inset (read below the scaffold, via Builder),
              // the list below takes the bottom one.
              padding:
                  const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ) +
                  AppGlassInsets.of(context).copyWith(bottom: 0),
              child: AppTextField(
                controller: _searchController,
                label: l10n.searchPeopleHint,
                suffixIcon: const Icon(Icons.search),
                onChanged: (query) =>
                    context.read<PersonListCubit>().nameQueryChanged(query),
              ),
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
                    title: l10n.errorLoadTitle,
                    message: l10n.messageFor(state.failure),
                    actionLabel: l10n.commonRetry,
                    onAction: () =>
                        context.read<PersonListCubit>().resubscribe(),
                  );
                }
                if (state.items.isEmpty &&
                    (state.nameQuery.trim().isNotEmpty ||
                        state.statusFilter != null)) {
                  // 022 E7: a search or filter is active and nothing matches —
                  // not the same as having no people yet.
                  return AppEmptyView(
                    icon: Icons.search_off,
                    title: l10n.peopleNoMatchTitle,
                    message: l10n.peopleNoMatchMessage,
                    actionLabel: l10n.peopleClearFiltersAction,
                    onAction: () {
                      _searchController.clear();
                      context.read<PersonListCubit>().clearFilters();
                    },
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
                  onRefresh: () =>
                      context.read<PersonListCubit>().resubscribe(),
                  child: ListView.separated(
                    // Clears the FAB so the last row's archive action is
                    // never hidden underneath it.
                    padding:
                        const EdgeInsets.only(bottom: 88) +
                        AppGlassInsets.of(context).copyWith(top: 0),
                    itemCount: state.items.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      indent: AppSpacing.md,
                      endIndent: AppSpacing.md,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return BlocSelector<
                        PersonListCubit,
                        PersonListState,
                        String?
                      >(
                        selector: (state) => state.processingPersonId,
                        builder: (context, processingPersonId) {
                          return PersonListTile(
                            person: item.person,
                            balance: item.balance,
                            isArchiving: processingPersonId == item.person.id,
                            onTap: () =>
                                _openPersonDetail(context, item.person.id),
                            onArchive: () => _archive(context, item.person.id),
                          );
                        },
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
      // transaction yet stays reachable via the app bar action above and
      // the empty-state action below.
      floatingActionButton: AppFab(
        onPressed: () => _recordTransaction(context),
        tooltip: l10n.recordTransactionAction,
        child: const Icon(Icons.add),
      ),
    );
  }

  // 021: no reload on return — the list is a live subscription, so a
  // change made on any pushed screen is already reflected here (this
  // replaces the 005-archive-state-refresh reload-on-return convention).
  Future<void> _addPerson(BuildContext context) async {
    final result = await context.push<Person?>('/people/new');
    if (result != null && context.mounted) {
      await context.push('/people/${result.id}');
    }
  }

  Future<void> _recordTransaction(BuildContext context) async {
    final result = await context.push<MoneyTransaction?>('/transactions/new');
    if (result != null && context.mounted) {
      await context.push('/people/${result.personId}');
    }
  }

  // 005-archive-state-refresh Decision 1 (an unarchive in the archived
  // list, or an archive/edit in Person Detail, must show here on return)
  // is now met by the live subscription.
  Future<void> _openArchivedList(BuildContext context) =>
      context.push('/people/archived');

  Future<void> _openPersonDetail(BuildContext context, String personId) =>
      context.push('/people/$personId');

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
