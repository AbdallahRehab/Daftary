import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/failure_message.dart';
import '../cubit/archived_people_cubit.dart';
import '../cubit/archived_people_state.dart';
import '../widgets/relationship_tag_chip.dart';

/// Searchable list of archived people with a "Restore" action per person,
/// linking into their full history (FR-018, Acceptance Scenario 4).
class ArchivedPeoplePage extends StatelessWidget {
  const ArchivedPeoplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ArchivedPeopleCubit>()..subscribe(),
      child: const _ArchivedPeopleView(),
    );
  }
}

class _ArchivedPeopleView extends StatelessWidget {
  const _ArchivedPeopleView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      appBar: AppTopBar(title: Text(l10n.archivedPeopleTitle)),
      body: Column(
        children: [
          Builder(
            builder: (context) => Padding(
              // Under glass the body starts behind the app bar, so the header
              // takes the top inset (read below the scaffold, via Builder).
              padding:
                  const EdgeInsets.all(AppSpacing.md) +
                  AppGlassInsets.of(context).copyWith(bottom: 0),
              child: AppTextField(
                label: l10n.searchPeopleHint,
                suffixIcon: const Icon(Icons.search),
                onChanged: (query) =>
                    context.read<ArchivedPeopleCubit>().nameQueryChanged(query),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<ArchivedPeopleCubit, ArchivedPeopleState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == ArchivedPeopleStatus.failure) {
                  return AppEmptyView(
                    icon: Icons.error_outline,
                    title: l10n.errorLoadTitle,
                    message: l10n.messageFor(state.failure),
                    actionLabel: l10n.commonRetry,
                    onAction: () =>
                        context.read<ArchivedPeopleCubit>().resubscribe(),
                  );
                }
                if (state.people.isEmpty) {
                  return AppEmptyView(
                    icon: Icons.inventory_2_outlined,
                    title: l10n.archivedEmptyTitle,
                    message: l10n.archivedEmptyMessage,
                  );
                }
                // The header above already took the top inset under glass; don't
                // add it again (a no-op with glass OFF).
                return MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: ListView.separated(
                    itemCount: state.people.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      indent: AppSpacing.md,
                      endIndent: AppSpacing.md,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    itemBuilder: (context, index) {
                      final person = state.people[index];
                      final tag = person.relationshipTag;
                      return BlocSelector<
                        ArchivedPeopleCubit,
                        ArchivedPeopleState,
                        String?
                      >(
                        selector: (state) => state.processingPersonId,
                        builder: (context, processingPersonId) {
                          final isRestoring = processingPersonId == person.id;
                          return ListTile(
                            title: Text(person.name),
                            subtitle: tag != null && tag.trim().isNotEmpty
                                ? Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: RelationshipTagChip(tag: tag),
                                  )
                                : null,
                            // 005-archive-state-refresh Decision 1: a change
                            // made in Person Detail shows here on return —
                            // 021: through the live subscription.
                            onTap: () => _openPersonDetail(context, person.id),
                            trailing: TextButton(
                              onPressed: isRestoring
                                  ? null
                                  : () => context
                                        .read<ArchivedPeopleCubit>()
                                        .restore(person.id),
                              child: Text(l10n.restoreAction),
                            ),
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
    );
  }

  Future<void> _openPersonDetail(BuildContext context, String personId) =>
      context.push('/people/$personId');
}
