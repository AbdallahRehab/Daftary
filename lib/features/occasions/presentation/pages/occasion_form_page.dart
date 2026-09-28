import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_confirm_dialog.dart';
import '../../../../core/design_system/app_date_field.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/repositories/occasions_repository.dart';
import '../cubit/occasion_detail_cubit.dart';
import '../cubit/occasion_form_cubit.dart';
import '../cubit/occasion_form_state.dart';
import '../widgets/occasion_type_picker.dart';

/// Create, or correct, one occasion: name, date, type and optional notes
/// (FR-001/FR-002, and edit mode for FR-012).
class OccasionFormPage extends StatelessWidget {
  const OccasionFormPage({super.key, this.editingOccasionId});

  /// When provided, the form opens in edit mode prefilled from that
  /// occasion, and gains its archive/delete actions (FR-012/FR-013/FR-014).
  final String? editingOccasionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = getIt<OccasionFormCubit>();
        final id = editingOccasionId;
        if (id != null) unawaited(_loadForEdit(cubit, id));
        return cubit;
      },
      child: _OccasionFormView(editingOccasionId: editingOccasionId),
    );
  }

  static Future<void> _loadForEdit(OccasionFormCubit cubit, String id) async {
    final result = await getIt<OccasionsRepository>().getOccasionDetail(id);
    result.match((_) {}, (detail) => cubit.loadForEdit(detail.occasion));
  }
}

class _OccasionFormView extends StatefulWidget {
  const _OccasionFormView({this.editingOccasionId});

  final String? editingOccasionId;

  @override
  State<_OccasionFormView> createState() => _OccasionFormViewState();
}

class _OccasionFormViewState extends State<_OccasionFormView> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  /// Set once the prefill has been copied into the controllers. Without it,
  /// the async `loadForEdit` would overwrite whatever the user had already
  /// started typing when it finally resolves.
  bool _prefilled = false;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.editingOccasionId != null;

    return BlocConsumer<OccasionFormCubit, OccasionFormState>(
      listener: (context, state) {
        if (state.isEditMode && !_prefilled) {
          _nameController.text = state.name;
          _notesController.text = state.notes ?? '';
          _prefilled = true;
        }
        if (state.isSuccess) context.pop(true);
        final failure = state.failure;
        if (failure != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(failure.message)));
        }
      },
      builder: (context, state) {
        final cubit = context.read<OccasionFormCubit>();
        return AppScaffold(
          appBar: AppTopBar(
            title: Text(
              isEdit
                  ? l10n.occasionFormEditTitle
                  : l10n.occasionFormCreateTitle,
            ),
            actions: isEdit
                ? [
                    IconButton(
                      tooltip: l10n.occasionArchiveAction,
                      icon: const Icon(Icons.archive_outlined),
                      onPressed: () => _archive(context, l10n),
                    ),
                    IconButton(
                      tooltip: l10n.occasionDeleteAction,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(context, l10n),
                    ),
                  ]
                : null,
          ),
          // Builder: the glass insets are read below the scaffold, where
          // they include the bars the body extends behind.
          body: Builder(
            builder: (context) => ListView(
              padding:
                  const EdgeInsets.all(AppSpacing.md) +
                  AppGlassInsets.of(context),
              children: [
                AppTextField(
                  label: l10n.occasionNameLabel,
                  controller: _nameController,
                  onChanged: cubit.nameChanged,
                  autofocus: !isEdit,
                  errorText: state.nameInvalid
                      ? l10n.occasionNameRequiredError
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppDateField(
                  label: l10n.occasionDateLabel,
                  date: state.date,
                  onDateChanged: cubit.dateChanged,
                  // Deliberately open-ended forward: an occasion can be
                  // recorded before it happens (spec Edge Cases).
                  lastDate: DateTime(DateTime.now().year + 5),
                ),
                const SizedBox(height: AppSpacing.md),
                OccasionTypePicker(
                  selectedType: state.type,
                  onTypeSelected: (type) => cubit.typeChanged(type ?? ''),
                  errorText: state.typeInvalid
                      ? l10n.occasionTypeRequiredError
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: l10n.occasionNotesLabel,
                  controller: _notesController,
                  onChanged: cubit.notesChanged,
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: isEdit
                      ? l10n.occasionUpdateAction
                      : l10n.occasionCreateAction,
                  isLoading: state.isSubmitting,
                  onPressed: cubit.submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _archive(BuildContext context, AppLocalizations l10n) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.occasionArchiveConfirmTitle,
      message: l10n.occasionArchiveConfirmMessage,
      confirmLabel: l10n.occasionArchiveAction,
    );
    if (!confirmed || !context.mounted) return;
    final cubit = getIt<OccasionDetailCubit>();
    await cubit.subscribe(widget.editingOccasionId!);
    final ok = await cubit.archive();
    await cubit.close();
    if (ok && context.mounted) context.pop(true);
  }

  Future<void> _delete(BuildContext context, AppLocalizations l10n) async {
    // The count is read before the dialog so the confirmation can name what
    // it is about to take with it (FR-013) — a bare "are you sure?" would
    // hide the part that actually matters.
    final cubit = getIt<OccasionDetailCubit>();
    await cubit.subscribe(widget.editingOccasionId!);
    if (!context.mounted) {
      await cubit.close();
      return;
    }
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.occasionDeleteConfirmTitle,
      message: l10n.occasionDeleteConfirmMessage(cubit.state.participantCount),
      confirmLabel: l10n.occasionDeleteAction,
      isDestructive: true,
    );
    if (!confirmed) {
      await cubit.close();
      return;
    }
    final ok = await cubit.delete();
    await cubit.close();
    if (ok && context.mounted) context.pop(true);
  }
}
