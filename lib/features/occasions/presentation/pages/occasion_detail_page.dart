import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_confirm_dialog.dart';
import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/media/attachment_picker_service.dart';
import '../cubit/occasion_detail_cubit.dart';
import '../cubit/occasion_detail_state.dart';
import '../widgets/occasion_attachment_gallery.dart';
import '../widgets/occasion_totals_card.dart';
import '../widgets/occasion_type_chip.dart';
import '../widgets/participant_row.dart';
import '../widgets/settlement_status_badge.dart';

/// One occasion in full: its totals and settlement status (FR-007/FR-008),
/// its participant list (FR-016), and its photos (FR-017).
class OccasionDetailPage extends StatelessWidget {
  const OccasionDetailPage({required this.occasionId, super.key});

  final String occasionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OccasionDetailCubit>()..load(occasionId),
      child: const _OccasionDetailView(),
    );
  }
}

class _OccasionDetailView extends StatelessWidget {
  const _OccasionDetailView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<OccasionDetailCubit, OccasionDetailState>(
      listener: (context, state) {
        if (state.isDeleted) {
          context.pop(true);
          return;
        }
        final attachmentFailure = state.attachmentFailure;
        if (attachmentFailure != null) {
          _explainAttachmentFailure(context, l10n, attachmentFailure);
          context.read<OccasionDetailCubit>().attachmentFailureShown();
        }
        final failure = state.failure;
        if (failure != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(failure.message)));
        }
      },
      builder: (context, state) {
        final cubit = context.read<OccasionDetailCubit>();
        final detail = state.detail;

        if (state.isLoading && detail == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (detail == null) {
          return Scaffold(
            appBar: AppBar(),
            body: AppEmptyView(
              icon: Icons.error_outline,
              title: l10n.occasionsEmptyTitle,
              message: state.failure?.message ?? l10n.occasionsEmptyMessage,
            ),
          );
        }

        final occasion = detail.occasion;
        return Scaffold(
          appBar: AppBar(
            title: Text(occasion.name),
            actions: [
              IconButton(
                tooltip: l10n.occasionEditAction,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  final changed = await context.push<bool>(
                    '/occasions/${occasion.id}/edit',
                  );
                  if (!context.mounted) return;
                  // The edit screen owns archive and delete too, so a
                  // `true` here may mean this occasion no longer exists.
                  if (changed ?? false) {
                    context.pop(true);
                  }
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              await context.push('/occasions/${occasion.id}/participants/new');
              if (context.mounted) unawaited(cubit.reload());
            },
            icon: const Icon(Icons.person_add_alt),
            label: Text(l10n.occasionAddParticipantAction),
          ),
          body: RefreshIndicator(
            onRefresh: cubit.reload,
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl * 2),
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          OccasionTypeChip(type: occasion.type),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: SettlementStatusBadge(
                              status: detail.summary.settlementStatus,
                              outstanding: detail.summary.outstanding,
                              dense: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      OccasionTotalsCard(summary: detail.summary),
                      if (occasion.notes != null &&
                          occasion.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(occasion.notes!, style: AppTypography.body),
                      ],
                    ],
                  ),
                ),
                _SectionHeader(title: l10n.occasionParticipantsHeader),
                if (!state.hasParticipants)
                  AppEmptyView(
                    icon: Icons.group_outlined,
                    title: l10n.occasionParticipantsEmptyTitle,
                    message: l10n.occasionParticipantsEmptyMessage,
                  )
                else
                  for (final row in detail.participants)
                    ParticipantRow(
                      row: row,
                      onTap: () async {
                        await context.push(
                          '/occasions/${occasion.id}/participants/'
                          '${row.transactionId}/edit',
                        );
                        if (context.mounted) unawaited(cubit.reload());
                      },
                      onRemove: () =>
                          _removeParticipant(context, l10n, row.transactionId),
                    ),
                _SectionHeader(
                  title: l10n.occasionAttachmentsHeader,
                  action: TextButton.icon(
                    onPressed: state.isAttachmentBusy
                        ? null
                        : () => _chooseAttachmentSource(context, l10n, cubit),
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(l10n.occasionAttachPhotoAction),
                  ),
                ),
                if (detail.attachments.isEmpty)
                  AppEmptyView(
                    icon: Icons.photo_library_outlined,
                    title: l10n.occasionAttachmentsEmptyTitle,
                    message: l10n.occasionAttachmentsEmptyMessage,
                  )
                else
                  OccasionAttachmentGallery(
                    attachments: detail.attachments,
                    onRemove: (attachment) =>
                        cubit.removeAttachment(attachment.id),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _removeParticipant(
    BuildContext context,
    AppLocalizations l10n,
    String transactionId,
  ) async {
    final cubit = context.read<OccasionDetailCubit>();
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.occasionRemoveParticipantConfirmTitle,
      message: l10n.occasionRemoveParticipantConfirmMessage,
      confirmLabel: l10n.occasionRemoveParticipantAction,
      isDestructive: true,
    );
    if (confirmed) await cubit.removeParticipant(transactionId);
  }

  Future<void> _chooseAttachmentSource(
    BuildContext context,
    AppLocalizations l10n,
    OccasionDetailCubit cubit,
  ) async {
    final fromCamera = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.occasionAttachFromCameraAction),
              onTap: () => Navigator.of(sheetContext).pop(true),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.occasionAttachFromGalleryAction),
              onTap: () => Navigator.of(sheetContext).pop(false),
            ),
          ],
        ),
      ),
    );
    if (fromCamera == null) return;
    await (fromCamera ? cubit.attachFromCamera() : cubit.attachFromGallery());
  }

  /// A denied permission gets a dialog rather than a snackbar: it is the one
  /// attachment outcome the user has to go elsewhere to fix, and the
  /// occasion stays entirely usable without the photo (FR-017 Edge Cases).
  void _explainAttachmentFailure(
    BuildContext context,
    AppLocalizations l10n,
    Failure failure,
  ) {
    if (failure is! PermissionDeniedFailure) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }
    // The message names the camera specifically when that is what was
    // refused, because "allow access" is a different switch in Settings.
    final isCamera = failure.message.toLowerCase().contains('camera');
    unawaited(
      showAppConfirmDialog(
        context,
        title: isCamera
            ? l10n.occasionCameraPermissionDeniedTitle
            : l10n.occasionPhotoLibraryPermissionDeniedTitle,
        message: isCamera
            ? l10n.occasionCameraPermissionDeniedMessage
            : l10n.occasionPhotoLibraryPermissionDeniedMessage,
        confirmLabel: l10n.occasionOpenSettingsAction,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.md,
        end: AppSpacing.sm,
        top: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTypography.title)),
          ?action,
        ],
      ),
    );
  }
}
