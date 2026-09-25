import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_confirm_dialog.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/failure_message.dart';
import '../../../transactions/presentation/widgets/duplicate_warning_sheet.dart';
import '../../domain/entities/person.dart';
import '../cubit/person_form_cubit.dart';
import '../cubit/person_form_state.dart';
import '../widgets/relationship_tag_chip.dart';

/// Full create/edit form for a [Person]: name, phone, relationship tag,
/// notes (US1, US5). In edit mode, also offers archive and delete (with an
/// "archive instead?" fallback when delete is blocked — FR-017).
class PersonFormPage extends StatelessWidget {
  const PersonFormPage({super.key, this.editingPerson});

  /// When provided, the form opens in edit mode prefilled from this person.
  final Person? editingPerson;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = getIt<PersonFormCubit>();
        final person = editingPerson;
        if (person != null) cubit.loadForEdit(person);
        return cubit;
      },
      child: const _PersonFormView(),
    );
  }
}

class _PersonFormView extends StatelessWidget {
  const _PersonFormView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: BlocSelector<PersonFormCubit, PersonFormState, bool>(
          selector: (state) => state.isEditMode,
          builder: (context, isEditMode) => Text(
            isEditMode ? l10n.personFormEditTitle : l10n.personFormCreateTitle,
          ),
        ),
        actions: [
          BlocSelector<PersonFormCubit, PersonFormState, bool>(
            selector: (state) => state.isEditMode,
            builder: (context, isEditMode) => isEditMode
                ? IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l10n.deletePersonAction,
                    onPressed: () => _confirmDelete(context),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: BlocConsumer<PersonFormCubit, PersonFormState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.duplicateMatches.isEmpty !=
                current.duplicateMatches.isEmpty,
        listener: (context, state) async {
          if (state.duplicateMatches.isNotEmpty) {
            await showDuplicateWarningSheet(
              context,
              matches: state.duplicateMatches,
              onPickExisting: (person) {
                context.read<PersonFormCubit>().dismissDuplicateWarning();
                if (context.canPop()) {
                  Navigator.of(context).pop(person);
                } else {
                  context.go('/people/${person.id}');
                }
              },
              onCreateNewAnyway: () => context
                  .read<PersonFormCubit>()
                  .confirmCreateDespiteDuplicate(),
            );
            return;
          }
          switch (state.status) {
            case PersonFormStatus.success:
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(l10n.savedConfirmation)));
              final saved = state.savedPerson;
              // 004-transaction-state-refresh research.md documented this
              // same context.go()-vs-push() defect here too; fixed by
              // 005-archive-state-refresh the same way: pop with a result
              // (mirroring transaction_form_page.dart) so the caller's own
              // `await push(...); refresh();` idiom reliably fires,
              // falling back to go() only when there is nothing to pop.
              if (context.canPop()) {
                Navigator.of(context).pop(saved);
              } else if (saved != null) {
                context.go('/people/${saved.id}');
              }
            case PersonFormStatus.deleted:
            case PersonFormStatus.archived:
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/people');
              }
            case PersonFormStatus.deleteBlocked:
              await _offerArchiveInstead(context);
            case PersonFormStatus.failure:
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(l10n.messageFor(state.failure))),
                );
            case PersonFormStatus.idle:
            case PersonFormStatus.submitting:
              break;
          }
        },
        builder: (context, state) {
          final cubit = context.read<PersonFormCubit>();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: l10n.nameLabel,
                  maxLength: 60,
                  autofocus: !state.isEditMode,
                  errorText: state.nameInvalid ? l10n.nameRequiredError : null,
                  onChanged: cubit.nameChanged,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: l10n.phoneLabel,
                  maxLength: 20,
                  keyboardType: TextInputType.phone,
                  onChanged: cubit.phoneNumberChanged,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.relationshipTagLabel,
                  style: AppTypography.bodyMuted.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final tag in predefinedRelationshipTags)
                      ChoiceChip(
                        label: Text(relationshipTagLabel(l10n, tag)),
                        selected: state.relationshipTag == tag,
                        onSelected: (selected) =>
                            cubit.relationshipTagChanged(selected ? tag : null),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: l10n.notesLabel,
                  maxLength: 500,
                  maxLines: 3,
                  onChanged: cubit.notesChanged,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: l10n.commonSave,
                  isLoading: state.isSubmitting,
                  onPressed: cubit.submit,
                ),
                if (state.isEditMode) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppSecondaryButton(
                    label: l10n.commonArchive,
                    onPressed: cubit.archive,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.deletePersonAction,
      message: l10n.deleteTransactionConfirmMessage,
      confirmLabel: l10n.commonDelete,
      isDestructive: true,
    );
    if (confirmed && context.mounted) {
      await context.read<PersonFormCubit>().delete();
    }
  }

  Future<void> _offerArchiveInstead(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.deleteBlockedTitle,
      message: l10n.deleteBlockedMessage,
      confirmLabel: l10n.archiveInsteadAction,
      cancelLabel: l10n.commonCancel,
    );
    if (confirmed && context.mounted) {
      await context.read<PersonFormCubit>().archive();
    }
  }
}
