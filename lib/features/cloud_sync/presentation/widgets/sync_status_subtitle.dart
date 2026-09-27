import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/cloud_config.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../cubit/sync_settings_cubit.dart';
import '../cubit/sync_settings_state.dart';
import 'sync_status_line.dart';

/// 021 T080: the live sync status, as the subtitle of the Settings entry.
/// A build without cloud configuration never touches the sync machinery.
class SyncStatusSubtitle extends StatelessWidget {
  const SyncStatusSubtitle({super.key, this.configured});

  /// Defaults to [CloudConfig.isConfigured]; overridable for tests.
  final bool? configured;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!(configured ?? CloudConfig.isConfigured)) {
      return Text(l10n.syncStatusUnavailable);
    }
    return BlocProvider(
      create: (_) => getIt<SyncSettingsCubit>()..subscribe(),
      child: BlocBuilder<SyncSettingsCubit, SyncSettingsState>(
        buildWhen: (previous, current) => previous.status != current.status,
        builder: (context, state) {
          final status = state.status;
          return Text(
            status == null ? '' : syncStatusText(l10n, status),
            key: const Key('settings_sync_status'),
          );
        },
      ),
    );
  }
}
