import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../cubit/export_cubit.dart';
import '../cubit/export_state.dart';

/// Settings → Export my data (013 US2): explains what the export contains,
/// generates the file on an explicit tap, then offers the OS share sheet
/// (FR-007–FR-011). Served at `/settings/export`.
class DataExportPage extends StatelessWidget {
  const DataExportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ExportCubit>(),
      child: const DataExportView(),
    );
  }
}

/// The export screen's content, reading the nearest [ExportCubit] — split
/// from [DataExportPage] so tests can provide a cubit of their own.
class DataExportView extends StatelessWidget {
  const DataExportView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      appBar: AppTopBar(title: Text(l10n.exportTitle)),
      body: BlocBuilder<ExportCubit, ExportState>(
        builder: (context, state) {
          final cubit = context.read<ExportCubit>();
          return switch (state.status) {
            ExportStatus.idle => _IdleBody(onGenerate: cubit.generate),
            ExportStatus.generating => const _GeneratingBody(),
            ExportStatus.ready => _ReadyBody(state: state),
            ExportStatus.error => AppEmptyView(
              icon: Icons.error_outline,
              title: l10n.commonError,
              message: l10n.exportError,
              actionLabel: l10n.retry,
              onAction: cubit.retry,
            ),
          };
        },
      ),
    );
  }
}

class _IdleBody extends StatelessWidget {
  const _IdleBody({required this.onGenerate});

  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg) + AppGlassInsets.of(context),
      children: [
        Icon(Icons.file_download_outlined, size: 48, color: onSurfaceVariant),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.exportDescription, style: AppTypography.body),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: l10n.exportGenerateAction,
          icon: Icons.description_outlined,
          onPressed: onGenerate,
        ),
      ],
    );
  }
}

/// The in-progress state (FR-009) — announced to screen readers as it
/// appears.
class _GeneratingBody extends StatelessWidget {
  const _GeneratingBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Semantics(
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.exportGenerating,
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadyBody extends StatelessWidget {
  const _ReadyBody({required this.state});

  final ExportState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ExportCubit>();
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg) + AppGlassInsets.of(context),
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 48,
          color: context.financeColors.positive,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.exportReadyTitle,
          style: AppTypography.title,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.exportReadyMessage(state.result?.totalRecords ?? 0),
          style: AppTypography.bodyMuted.copyWith(
            color: colors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: l10n.exportShareAction,
          icon: Icons.share_outlined,
          isLoading: state.isSharing,
          onPressed: () => cubit.share(subject: l10n.exportTitle),
        ),
        if (state.shareFailed) ...[
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.exportShareError,
              style: AppTypography.bodyMuted.copyWith(color: colors.error),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        AppSecondaryButton(
          label: l10n.exportRegenerateAction,
          onPressed: state.isSharing ? null : cubit.generate,
        ),
      ],
    );
  }
}
