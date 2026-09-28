import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../cubit/image_prep_cubit.dart';
import '../cubit/image_prep_state.dart';
import '../widgets/direction_default_toggle.dart';
import '../widgets/scan_processing_overlay.dart';
import '../widgets/scan_failure_state.dart';

/// Crop, rotate, enhance, then read the paper (FR-002, FR-003, FR-005).
///
/// Every step here is repeatable without going back to the camera, which
/// is the single most useful recovery when a first pass reads badly
/// (FR-002, User Story 4).
class ImagePrepPage extends StatelessWidget {
  const ImagePrepPage({required this.imagePath, super.key});

  /// The app-owned copy produced by the capture step.
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ImagePrepCubit>()..initialize(imagePath),
      child: const _ImagePrepView(),
    );
  }
}

class _ImagePrepView extends StatefulWidget {
  const _ImagePrepView();

  @override
  State<_ImagePrepView> createState() => _ImagePrepViewState();
}

class _ImagePrepViewState extends State<_ImagePrepView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// FR-017/T059: coming back from the background must never leave the
  /// user staring at a spinner with nothing behind it — the cubit decides
  /// between "still working" and "interrupted, try again".
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<ImagePrepCubit>().onResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      appBar: AppTopBar(title: Text(l10n.ocrPrepTitle)),
      body: BlocConsumer<ImagePrepCubit, ImagePrepState>(
        listenWhen: (previous, current) => current.isReadyForReview,
        listener: (context, state) {
          final scanId = state.scanId;
          if (scanId == null) return;
          // Replaces the preparation screen: the review screen is the only
          // gate to real money (Principle X), and backing out of it should
          // land on the capture entry point, not on a stale crop UI.
          context.go('/ocr/scan/review?scanId=$scanId');
        },
        builder: (context, state) {
          final cubit = context.read<ImagePrepCubit>();

          if (state.status == ImagePrepStatus.failure &&
              state.failure != null) {
            return ScanFailureState(
              failure: state.failure!,
              onRetakePhoto: () => context.pop(),
              onRecrop: cubit.crop,
              onEnterManually: () => context.go('/transactions/new'),
            );
          }

          return Stack(
            children: [
              _PrepBody(state: state, cubit: cubit),
              if (state.isProcessing)
                Positioned.fill(
                  child: ScanProcessingOverlay(onCancel: cubit.cancel),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PrepBody extends StatelessWidget {
  const _PrepBody({required this.state, required this.cubit});

  final ImagePrepState state;
  final ImagePrepCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md) + AppGlassInsets.of(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.imagePath.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Image.file(
                File(state.imagePath),
                // The key forces a reload when crop or enhance writes a
                // new file: the widget would otherwise keep the decoded
                // bytes of the previous path-identical image.
                key: ValueKey('${state.imagePath}:${state.isEnhanced}'),
                height: 260,
                fit: BoxFit.contain,
                errorBuilder: (context, _, _) => SizedBox(
                  height: 260,
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.ocrPrepHint,
            style: AppTypography.bodyMuted.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppSecondaryButton(
                  label: state.hasCropped
                      ? l10n.ocrPrepRecrop
                      : l10n.ocrPrepCropRotate,
                  onPressed: state.isBusy ? null : cubit.crop,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppSecondaryButton(
                  label: state.isEnhanced
                      ? l10n.ocrPrepEnhanceAgain
                      : l10n.ocrPrepEnhance,
                  onPressed: state.isBusy ? null : cubit.enhance,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DirectionDefaultToggle(
            value: state.defaultDirection,
            enabled: !state.isBusy,
            onChanged: cubit.setDefaultDirection,
          ),
          if (state.status == ImagePrepStatus.interrupted) ...[
            const SizedBox(height: AppSpacing.md),
            _InterruptedNotice(onRetry: cubit.process),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: l10n.ocrPrepProcess,
            icon: Icons.text_snippet_outlined,
            isLoading: state.isBusy,
            onPressed: cubit.process,
          ),
        ],
      ),
    );
  }
}

/// An honest "that stopped without finishing" panel, offered instead of a
/// spinner that would never resolve (T059).
class _InterruptedNotice extends StatelessWidget {
  const _InterruptedNotice({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.ocrPrepInterruptedTitle, style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.ocrPrepInterruptedMessage,
            style: AppTypography.bodyMuted.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppSecondaryButton(label: l10n.ocrPrepRetry, onPressed: onRetry),
        ],
      ),
    );
  }
}
