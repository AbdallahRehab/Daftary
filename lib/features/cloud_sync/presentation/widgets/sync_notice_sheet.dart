import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/cloud_config.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/glass/app_modal_sheet.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../cubit/sync_notice_cubit.dart';
import '../cubit/sync_notice_state.dart';
import '../pages/sync_settings_page.dart';

/// What the user chose in the notice.
enum SyncNoticeAction { openSettings, dismiss }

/// 021 T081: the one-time, dismissible notice that explains cloud backup
/// and links to the sync settings.
class SyncNoticeSheet extends StatelessWidget {
  const SyncNoticeSheet({super.key});

  static const openSettingsKey = Key('sync_notice_open_settings');
  static const dismissKey = Key('sync_notice_dismiss');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.cloud_done_outlined, size: 40, color: colors.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.syncNoticeTitle,
              style: AppTypography.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.syncNoticeMessage,
              style: AppTypography.bodyMuted.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              key: openSettingsKey,
              label: l10n.syncNoticeOpenSettings,
              onPressed: () =>
                  Navigator.of(context).pop(SyncNoticeAction.openSettings),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              key: dismissKey,
              label: l10n.syncNoticeDismiss,
              onPressed: () =>
                  Navigator.of(context).pop(SyncNoticeAction.dismiss),
            ),
          ],
        ),
      ),
    );
  }
}

/// 021 T081: shows [SyncNoticeSheet] once, after startup is ready (it lives
/// in the main shell, which mounts only then), and only when cloud sync is
/// configured and the notice was never acknowledged. However the sheet
/// closes, it is acknowledged, so it never shows again.
class SyncNoticeHost extends StatefulWidget {
  const SyncNoticeHost({
    required this.child,
    super.key,
    this.configured,
    this.createCubit,
  });

  final Widget child;

  /// Defaults to [CloudConfig.isConfigured]; overridable for tests.
  final bool? configured;

  /// Defaults to the injected [SyncNoticeCubit].
  final SyncNoticeCubit Function()? createCubit;

  @override
  State<SyncNoticeHost> createState() => _SyncNoticeHostState();
}

class _SyncNoticeHostState extends State<SyncNoticeHost> {
  SyncNoticeCubit? _cubit;
  StreamSubscription<SyncNoticeState>? _sub;
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    if (!(widget.configured ?? CloudConfig.isConfigured)) return;
    final cubit = widget.createCubit?.call() ?? getIt<SyncNoticeCubit>();
    _cubit = cubit;
    _sub = cubit.stream.listen(_onState);
    unawaited(cubit.check());
  }

  void _onState(SyncNoticeState state) {
    if (_shown || state.visibility != SyncNoticeVisibility.show) return;
    _shown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _show());
  }

  Future<void> _show() async {
    if (!mounted) return;
    final action = await showAppModalSheet<SyncNoticeAction>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const SyncNoticeSheet(),
    );
    await _cubit?.acknowledge();
    if (action == SyncNoticeAction.openSettings && mounted) {
      unawaited(GoRouter.of(context).push(SyncSettingsRoutes.settings));
    }
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    unawaited(_cubit?.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
