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
import '../cubit/scan_capture_cubit.dart';
import '../cubit/scan_capture_state.dart';
import '../widgets/scan_failure_state.dart';

/// The scan entry point: take a photo of the paper, or pick one that was
/// already taken (FR-001).
///
/// Availability is checked as the screen opens rather than when the camera
/// button is tapped, so a device that cannot run on-device recognition says
/// so up front and points at manual entry instead of opening a camera whose
/// photo it could never read (spec Edge Cases, T060).
class ScanCapturePage extends StatelessWidget {
  const ScanCapturePage({super.key, this.onOpenAppSettings});

  /// Hook for opening the OS app-settings screen after a permission denial
  /// (FR-016). Injected rather than called directly because the app has no
  /// settings-opening dependency yet; when absent, the denial is still
  /// explained and manual entry is still offered.
  final VoidCallback? onOpenAppSettings;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ScanCaptureCubit>()..checkAvailability(),
      child: _ScanCaptureView(onOpenAppSettings: onOpenAppSettings),
    );
  }
}

class _ScanCaptureView extends StatelessWidget {
  const _ScanCaptureView({this.onOpenAppSettings});

  final VoidCallback? onOpenAppSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      appBar: AppTopBar(title: Text(l10n.ocrCaptureTitle)),
      body: BlocConsumer<ScanCaptureCubit, ScanCaptureState>(
        listenWhen: (previous, current) => current.isPicked,
        listener: (context, state) {
          final imagePath = state.imagePath;
          if (imagePath == null) return;
          // Reset first: coming back from preparation should land on a
          // fresh capture screen, not on the previous photo's "picked"
          // state that would immediately push again.
          context.read<ScanCaptureCubit>().reset();
          context.push('/ocr/scan/prepare', extra: imagePath);
        },
        builder: (context, state) {
          final cubit = context.read<ScanCaptureCubit>();

          if (state.status == ScanCaptureStatus.checkingAvailability) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.isUnsupported) {
            return _UnsupportedDeviceView(
              onEnterManually: () => context.push('/transactions/new'),
            );
          }

          final failure = state.failure;
          if (failure != null) {
            return ScanFailureState(
              failure: failure,
              onRetakePhoto: cubit.captureFromCamera,
              onEnterManually: () => context.push('/transactions/new'),
              onOpenSettings: state.isPermissionDenied
                  ? onOpenAppSettings
                  : null,
            );
          }

          return _CaptureChoices(isBusy: state.isBusy, cubit: cubit);
        },
      ),
    );
  }
}

class _CaptureChoices extends StatelessWidget {
  const _CaptureChoices({required this.isBusy, required this.cubit});

  final bool isBusy;
  final ScanCaptureCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg) + AppGlassInsets.of(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Icon(
            Icons.document_scanner_outlined,
            size: 64,
            color: colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.ocrCaptureHeadline,
            style: AppTypography.title,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.ocrCaptureMessage,
            style: AppTypography.bodyMuted.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: l10n.ocrCaptureTakePhoto,
            icon: Icons.photo_camera_outlined,
            isLoading: isBusy,
            onPressed: cubit.captureFromCamera,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSecondaryButton(
            label: l10n.ocrCaptureChooseFromGallery,
            onPressed: isBusy ? null : cubit.pickFromGallery,
          ),
        ],
      ),
    );
  }
}

/// T060: an honest dead end. No retry is offered, because nothing about
/// this device is going to change between taps.
class _UnsupportedDeviceView extends StatelessWidget {
  const _UnsupportedDeviceView({required this.onEnterManually});

  final VoidCallback onEnterManually;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.all(AppSpacing.xl) + AppGlassInsets.of(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.phonelink_erase_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.ocrCaptureUnsupportedTitle,
              style: AppTypography.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.ocrCaptureUnsupportedMessage,
              style: AppTypography.bodyMuted.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: l10n.ocrCaptureEnterManually,
                onPressed: onEnterManually,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
