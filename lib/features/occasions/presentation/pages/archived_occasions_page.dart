import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../cubit/archived_occasions_cubit.dart';
import '../cubit/archived_occasions_state.dart';
import '../widgets/occasion_list_tile.dart';

/// Archived occasions, with a restore action (FR-014). Mirrors
/// `ArchivedPeoplePage` — archiving hides an occasion from the default
/// list without touching its contributions or anyone's balance, so this
/// screen is a shelf, not a bin.
///
/// 021: live — an archive or restore made anywhere, or applied by sync,
/// shows here with no reload (FR-031).
class ArchivedOccasionsPage extends StatelessWidget {
  const ArchivedOccasionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ArchivedOccasionsCubit>()..subscribe(),
      child: const _ArchivedOccasionsView(),
    );
  }
}

class _ArchivedOccasionsView extends StatelessWidget {
  const _ArchivedOccasionsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ArchivedOccasionsCubit>();

    return AppScaffold(
      appBar: AppTopBar(title: Text(l10n.occasionArchivedTitle)),
      body: BlocBuilder<ArchivedOccasionsCubit, ArchivedOccasionsState>(
        builder: (context, state) {
          if (state.isLoading && state.occasions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.isEmpty) {
            return AppEmptyView(
              icon: Icons.archive_outlined,
              title: l10n.occasionArchivedEmptyTitle,
              message: l10n.occasionArchivedEmptyMessage,
            );
          }
          // No explicit padding: the list takes the scaffold's insets itself,
          // which under glass keeps the first and last rows clear of the
          // bars (and is zero with glass OFF).
          return ListView.builder(
            itemCount: state.occasions.length,
            itemBuilder: (context, index) {
              final occasion = state.occasions[index];
              return Row(
                children: [
                  Expanded(child: OccasionListTile(occasion: occasion)),
                  TextButton(
                    onPressed: state.processingOccasionId == occasion.id
                        ? null
                        : () => cubit.restore(occasion.id),
                    child: Text(l10n.occasionRestoreAction),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
