import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../cubit/archived_occasions_cubit.dart';
import '../cubit/archived_occasions_state.dart';
import '../widgets/occasion_list_tile.dart';

/// Archived occasions, with a restore action (FR-014). Mirrors
/// `ArchivedPeoplePage` — archiving hides an occasion from the default
/// list without touching its contributions or anyone's balance, so this
/// screen is a shelf, not a bin.
class ArchivedOccasionsPage extends StatelessWidget {
  const ArchivedOccasionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ArchivedOccasionsCubit>()..load(),
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.occasionArchivedTitle)),
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
