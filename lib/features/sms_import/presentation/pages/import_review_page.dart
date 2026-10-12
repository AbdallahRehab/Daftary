import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_confirm_dialog.dart';
import '../../../../core/design_system/app_date_field.dart';
import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/design_system/confidence_indicator.dart';
import '../../../../core/design_system/currency_picker.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/failure_message.dart';
import '../../../../core/l10n/numeral_locale.dart';
import '../../../../core/money/money.dart';
import '../../../../core/money/numeral_parser.dart';
import '../../../finance/domain/entities/finance_entry_type.dart';
import '../../../finance/presentation/widgets/category_picker_field.dart';
import '../../../people/domain/usecases/find_possible_duplicate_person.dart';
import '../../../transactions/presentation/widgets/duplicate_warning_sheet.dart';
import '../../../transactions/presentation/widgets/person_picker_field.dart';
import '../../domain/entities/parse_confidence.dart';
import '../../domain/entities/pending_sms_import.dart';
import '../../domain/entities/review_draft.dart';
import '../../domain/entities/sms_import_enums.dart';
import '../../domain/entities/sms_value_types.dart';
import '../cubit/import_review_cubit.dart';
import '../cubit/import_review_state.dart';
import '../routes.dart';
import '../widgets/bidi_text.dart';
import '../widgets/duplicate_comparison_card.dart';
import '../widgets/import_type_selector.dart';
import '../widgets/probable_duplicate_sheet.dart';
import '../widgets/sms_import_labels.dart';

/// The dedicated review of one pending import (T082, ui-contract §3.4).
///
/// It never opens or modifies the manual transaction forms (FR-044): it is
/// built from the design-system fields and the shared category/person
/// pickers, and its only write is the explicit Add, through
/// `AddImportedTransaction`. Reached by id only; the route carries no
/// content.
class ImportReviewPage extends StatelessWidget {
  const ImportReviewPage({required this.importId, super.key, this.cubit});

  final String importId;

  /// Tests inject a cubit; the app resolves it from DI.
  final ImportReviewCubit? cubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => (cubit ?? getIt<ImportReviewCubit>())..load(importId),
      child: const _ReviewView(),
    );
  }
}

class _ReviewView extends StatelessWidget {
  const _ReviewView();

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(BankMessagesRoutes.hub);
    }
  }

  /// "Stop suggesting from this sender": confirms first, stating that the
  /// sender's pending items are removed (FR-065).
  Future<void> _confirmMute(
    BuildContext context,
    ImportReviewState state,
  ) async {
    final sender = state.item?.senderId;
    if (sender == null) return;
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ImportReviewCubit>();
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.smsImportMuteConfirmTitle,
      message: l10n.smsImportMuteConfirmMessage(BidiIsolate.ltr(sender)),
      confirmLabel: l10n.smsImportMuteConfirm,
      cancelLabel: MaterialLocalizations.of(context).cancelButtonLabel,
      isDestructive: true,
    );
    if (confirmed) await cubit.muteSender();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ImportReviewCubit>();
    return BlocConsumer<ImportReviewCubit, ImportReviewState>(
      listenWhen: (p, c) =>
          p.status != c.status ||
          p.duplicateRequest != c.duplicateRequest ||
          p.requiresDiscardConfirmation != c.requiresDiscardConfirmation ||
          p.leaveApproved != c.leaveApproved ||
          p.personDuplicateMatches.isEmpty != c.personDuplicateMatches.isEmpty,
      listener: (context, state) async {
        final direction = Directionality.of(context);
        final view = View.of(context);
        void announce(String message, {bool assertive = false}) =>
            SemanticsService.sendAnnouncement(
              view,
              message,
              direction,
              assertiveness: assertive
                  ? Assertiveness.assertive
                  : Assertiveness.polite,
            );
        if (state.status == ImportReviewStatus.submitting) {
          announce(l10n.smsImportReviewSaving);
        }
        if (state.status == ImportReviewStatus.success ||
            state.status == ImportReviewStatus.closedAsDuplicate ||
            state.status == ImportReviewStatus.ignored ||
            state.status == ImportReviewStatus.senderMuted) {
          final message = switch (state.status) {
            ImportReviewStatus.success => l10n.smsImportReviewAdded,
            ImportReviewStatus.ignored => l10n.smsImportReviewIgnored,
            ImportReviewStatus.senderMuted => l10n.smsImportMuteDone(
              state.mutedRemovedCount,
            ),
            _ => l10n.smsImportDuplicateClosed,
          };
          announce(message);
          ScaffoldMessenger.maybeOf(
            context,
          )?.showSnackBar(SnackBar(content: Text(message)));
          final next = state.nextImportId;
          if (next != null) {
            context.pushReplacement(BankMessagesRoutes.review(next));
          } else {
            _leave(context);
          }
          return;
        }
        if (state.leaveApproved) {
          _leave(context);
          return;
        }
        if (state.requiresDiscardConfirmation) {
          final discard = await showAppConfirmDialog(
            context,
            title: l10n.smsImportReviewDiscardTitle,
            message: l10n.smsImportReviewDiscardMessage,
            confirmLabel: l10n.smsImportReviewDiscardConfirm,
            cancelLabel: l10n.smsImportReviewKeepEditing,
            isDestructive: true,
          );
          discard ? cubit.confirmDiscard() : cubit.keepEditing();
          return;
        }
        if (state.duplicateRequest case final finding?) {
          cubit.consumeDuplicateRequest();
          // The sheet announces "Possible duplicate found" itself.
          final comparison = _DuplicateComparison.of(context, state, finding);
          final choice = await showProbableDuplicateSheet(
            context,
            existing: comparison.existing,
            incoming: comparison.incoming,
            phrases: comparison.phrases,
            // An incomplete draft cannot be added, so it is not offered.
            canAddAnyway: state.canAdd,
          );
          switch (choice) {
            case ProbableDuplicateChoice.same:
              await cubit.closeAsDuplicate();
            case ProbableDuplicateChoice.addAnyway:
              await cubit.add(duplicateOverride: true);
            case null:
              // Dismissed: back to review, the item stays pending.
              break;
          }
          return;
        }
        if (state.personDuplicateMatches.isNotEmpty) {
          await showDuplicateWarningSheet(
            context,
            matches: state.personDuplicateMatches,
            onPickExisting: cubit.personSelected,
            onCreateNewAnyway: cubit.confirmCreatePersonDespiteDuplicate,
          );
          cubit.dismissPersonDuplicates();
        }
      },
      builder: (context, state) {
        return PopScope(
          canPop: state.isSettled || !state.isDirty,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) cubit.requestLeave();
          },
          child: AppScaffold(
            appBar: AppTopBar(
              title: Text(l10n.smsImportReviewTitle),
              actions: [
                if (state.status == ImportReviewStatus.ready &&
                    cubit.canMuteSender)
                  PopupMenuButton<_ReviewMenu>(
                    key: const ValueKey('import_review_overflow'),
                    tooltip: l10n.smsImportReviewMoreActions,
                    onSelected: (choice) => switch (choice) {
                      _ReviewMenu.muteSender => _confirmMute(context, state),
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        key: const ValueKey('import_review_mute_sender'),
                        value: _ReviewMenu.muteSender,
                        child: Text(l10n.smsImportMuteAction),
                      ),
                    ],
                  ),
              ],
            ),
            body: SafeArea(
              top: false,
              bottom: false,
              child: switch (state.status) {
                ImportReviewStatus.initial ||
                ImportReviewStatus.loading => const _Skeleton(),
                ImportReviewStatus.alreadyHandled => AppEmptyView(
                  title: l10n.smsImportReviewAlreadyHandledTitle,
                  message: l10n.smsImportReviewAlreadyHandledMessage,
                  icon: Icons.task_alt,
                  actionLabel: l10n.smsImportReviewBackToList,
                  onAction: () => context.go(BankMessagesRoutes.hub),
                ),
                ImportReviewStatus.loadFailure => AppEmptyView(
                  title: l10n.smsImportReviewLoadErrorTitle,
                  message: l10n.messageFor(state.failure),
                  icon: Icons.error_outline,
                  actionLabel: l10n.smsImportPendingRetry,
                  onAction: () => cubit.load(state.pendingId),
                ),
                _ => _Form(state: state, cubit: cubit),
              },
            ),
          ),
        );
      },
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({required this.state, required this.cubit});

  final ImportReviewState state;
  final ImportReviewCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final item = state.item!;
    final draft = state.draft!;
    final enabled = state.status == ImportReviewStatus.ready;
    final missing = state.missing;
    final type = draft.type;
    final showErrors = state.isDirty || state.failure != null;

    String? errorFor(ReviewField field) => missing.contains(field) && showErrors
        ? SmsImportLabels.field(l10n, field)
        : null;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md) + AppGlassInsets.of(context),
      children: [
        _Header(state: state, cubit: cubit),
        const SizedBox(height: AppSpacing.md),
        if (state.finding?.isProbable ?? false) ...[
          _Banner(
            icon: Icons.content_copy_outlined,
            text: l10n.smsImportDuplicateBanner,
            actionLabel: l10n.smsImportDuplicateCompare,
            onAction: enabled ? cubit.compareDuplicate : null,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ImportTypeSelector(
                value: type,
                enabled: enabled,
                onChanged: cubit.typeChanged,
              ),
              if (_suggestHintType(state) case final hint?) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.smsImportSuggestHint(hint.name),
                  key: const ValueKey('import_review_suggest_hint'),
                  style: AppTypography.bodyMuted,
                ),
              ],
              if (_offerSimilarPeople(state)) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.smsImportSuggestSeveralPeople(
                    state.similarPeople.length,
                    BidiIsolate.auto(item.counterparty!.trim()),
                  ),
                  style: AppTypography.bodyMuted,
                ),
                const SizedBox(height: AppSpacing.xs),
                ActionChip(
                  key: const ValueKey('import_review_choose_person'),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  avatar: const Icon(Icons.people_outline, size: 18),
                  label: Text(
                    l10n.smsImportSuggestChoosePerson(
                      item.direction == SmsDirection.credit
                          ? 'received'
                          : 'given',
                    ),
                  ),
                  onPressed: enabled ? cubit.chooseFromSimilarPeople : null,
                ),
              ],
              if (_offerSuggestedPerson(state)) ...[
                const SizedBox(height: AppSpacing.sm),
                ActionChip(
                  key: const ValueKey('import_review_suggested_person'),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  avatar: const Icon(Icons.person_outline, size: 18),
                  label: Text(
                    // The name is isolated so its script never reorders
                    // the sentence (FR-091).
                    item.direction == SmsDirection.credit
                        ? l10n.smsImportReviewRecordAsReceived(
                            BidiIsolate.auto(item.counterparty!.trim()),
                          )
                        : l10n.smsImportReviewRecordAsGiven(
                            BidiIsolate.auto(item.counterparty!.trim()),
                          ),
                  ),
                  onPressed: enabled ? cubit.acceptSuggestedPerson : null,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _AmountSection(state: state, cubit: cubit, enabled: enabled),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppDateField(
                key: const ValueKey('import_review_date'),
                label: l10n.smsImportReviewDateLabel,
                date: draft.date,
                emptyText: l10n.smsImportReviewChooseDate,
                errorText: errorFor(ReviewField.date),
                onDateChanged: cubit.dateChanged,
              ),
              // Below the field, not beside it, so 200% text never
              // squeezes the field (ui-contract §7.6).
              if (item.confidence[SmsField.date] case final c?) ...[
                const SizedBox(height: AppSpacing.xs),
                ConfidenceIndicator(confidence: c),
              ],
              if (item.timeMinutes case final minutes?) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.smsImportReviewMessageTime(_time(context, minutes)),
                  style: AppTypography.bodyMuted,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (type != null && type.isFinanceEntry)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CategoryPickerField(
                  categories: state.categories,
                  type: type == SuggestedRecordType.income
                      ? FinanceEntryType.income
                      : FinanceEntryType.expense,
                  selectedCategoryId: draft.categoryId,
                  isLoading: state.categoriesLoading,
                  errorText: errorFor(ReviewField.category),
                  onCategorySelected: cubit.categorySelected,
                  onManageCategories: () => context.push('/finance/categories'),
                ),
                if (!state.categoriesLoading && state.categories.isEmpty)
                  Text(
                    l10n.smsImportReviewNoCategories,
                    style: AppTypography.bodyMuted,
                  ),
              ],
            ),
          ),
        if (type != null && type.isPersonTransaction)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PersonPickerField(
                  query: state.personQuery,
                  results: state.personResults,
                  selectedPerson: state.selectedPerson,
                  onQueryChanged: cubit.personQueryChanged,
                  onPersonSelected: cubit.personSelected,
                  onCreateNew: cubit.createPerson,
                  errorText: errorFor(ReviewField.person),
                ),
                if (_counterpartyNotInPeople(state) case final name?) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.smsImportSuggestPersonNotInList(
                      BidiIsolate.auto(name),
                    ),
                    key: const ValueKey('import_review_person_not_in_list'),
                    style: AppTypography.bodyMuted,
                  ),
                ],
              ],
            ),
          ),
        if (type != null) const SizedBox(height: AppSpacing.md),
        _NoteSection(state: state, cubit: cubit, enabled: enabled),
        const SizedBox(height: AppSpacing.md),
        _OriginalSection(state: state, cubit: cubit),
        const SizedBox(height: AppSpacing.lg),
        _Actions(state: state, cubit: cubit),
      ],
    );
  }

  /// The hint under the type selector, while no type is chosen and the
  /// suggestion is Ignore (ATM with the preference off, refund, reversal,
  /// own-account move, FR-051a/c) or no type (FR-033).
  static SuggestedRecordType? _suggestHintType(ImportReviewState state) {
    final suggested = state.suggestedType;
    if (state.draft?.type != null || suggested == null) return null;
    return suggested == SuggestedRecordType.ignore ||
            suggested == SuggestedRecordType.unset
        ? suggested
        : null;
  }

  /// "Choose the person": a named transfer several people could match
  /// (FR-054), until a person is chosen.
  static bool _offerSimilarPeople(ImportReviewState state) =>
      state.similarPeople.length > 1 &&
      (state.item?.counterparty?.trim().isNotEmpty ?? false) &&
      state.selectedPerson == null;

  /// The counterparty's name while Given/Received has no person and no one
  /// in People has that name: a reminder that nothing is created without
  /// the user's tap (FR-054, US7-2).
  static String? _counterpartyNotInPeople(ImportReviewState state) {
    final name = state.item?.counterparty?.trim() ?? '';
    if (name.isEmpty || state.selectedPerson != null) return null;
    if (state.item?.suggestedPersonId != null) return null;
    if (state.similarPeople.isNotEmpty) return null;
    final normalized = FindPossibleDuplicatePerson.normalize(name);
    final known = state.personResults.any(
      (p) => FindPossibleDuplicatePerson.normalize(p.name) == normalized,
    );
    return known ? null : name;
  }

  static bool _offerSuggestedPerson(ImportReviewState state) {
    final item = state.item!;
    final type = state.draft?.type;
    return item.suggestedPersonId != null &&
        (item.counterparty?.isNotEmpty ?? false) &&
        !(type?.isPersonTransaction ?? false);
  }

  /// "10:15", Western digits in both languages (FR-090).
  static String _time(BuildContext context, int minutes) {
    final locale = Localizations.localeOf(context).languageCode;
    final at = DateTime(2000, 1, 1, minutes ~/ 60, minutes % 60);
    return NumeralParser.toWesternDigits(
      DateFormat.jm(numeralLocaleFor(locale)).format(at),
    );
  }
}

/// Bank, masked card, source, kind, overall confidence and the warning
/// lines (FR-043, FR-024a/b, FR-030a, FR-051d).
class _Header extends StatelessWidget {
  const _Header({required this.state, required this.cubit});

  final ImportReviewState state;
  final ImportReviewCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final item = state.item!;
    final finding = state.finding;
    final ownTransfer =
        (finding?.possibleOwnTransfer ?? false) ||
        item.warnings.contains(SmsWarning.possibleOwnTransfer);
    final warnings = [
      for (final w in SmsWarning.values)
        if (item.warnings.contains(w) &&
            w != SmsWarning.possibleDuplicate &&
            w != SmsWarning.possibleOwnTransfer &&
            // The ATM link below states the preference instead.
            w != SmsWarning.atmIgnoredByDefault)
          w,
    ];
    final matched = item.kind == SmsKind.authorizationReversal
        ? finding?.matchedRecord
        : null;
    final parent = state.parent;
    final last4 = item.cardLast4;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                SmsImportLabels.bank(l10n, item.bankId),
                style: AppTypography.title,
              ),
              if (last4 != null)
                Semantics(
                  label: l10n.smsImportSemanticsCardEnding(last4),
                  excludeSemantics: true,
                  child: Text(
                    SmsImportLabels.maskedCard(last4),
                    style: AppTypography.bodyMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            [
              SmsImportLabels.kind(l10n, item.kind),
              l10n.smsImportReviewSourceLabel(item.source.name),
            ].join(l10n.smsImportReviewListSeparator),
            style: AppTypography.bodyMuted,
          ),
          if (item.merchant ?? item.counterparty case final name?) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(BidiIsolate.auto(name), style: AppTypography.body),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n.smsImportReviewOverallConfidence,
                style: AppTypography.label,
              ),
              ConfidenceIndicator(
                confidence: SmsImportLabels.overall(item.confidence.overall),
              ),
            ],
          ),
          for (final w in warnings)
            _Line(
              icon: Icons.info_outline,
              text: SmsImportLabels.warning(l10n, w),
            ),
          if (item.kind == SmsKind.atmWithdrawal)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  key: const ValueKey('import_review_cash_link'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(
                      AppSizes.minTouchTarget,
                      AppSizes.minTouchTarget,
                    ),
                  ),
                  icon: const Icon(Icons.tune),
                  label: Text(
                    l10n.smsImportSuggestCashLink(
                      (state.countCashWithdrawals ??
                              item.suggestedType == SuggestedRecordType.expense)
                          ? 'on'
                          : 'off',
                    ),
                  ),
                  onPressed: () async {
                    await context.push(BankMessagesRoutes.settings);
                    await cubit.refreshCashPreference();
                  },
                ),
              ),
            ),
          if (ownTransfer)
            _Line(
              icon: Icons.swap_horiz,
              text: SmsImportLabels.warning(
                l10n,
                SmsWarning.possibleOwnTransfer,
              ),
            ),
          if (matched != null) _MatchedRecord(record: matched),
          if (item.parentImportId != null && parent != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  minimumSize: const Size(
                    AppSizes.minTouchTarget,
                    AppSizes.minTouchTarget,
                  ),
                ),
                icon: const Icon(Icons.link),
                label: Text(
                  parent.occurredOn == null
                      ? l10n.smsImportReviewFeeFromParentNoDate
                      : l10n.smsImportReviewFeeFromParent(
                          SmsImportLabels.date(context, parent.occurredOn!),
                        ),
                ),
                onPressed: () =>
                    context.push(BankMessagesRoutes.review(parent.id)),
              ),
            ),
        ],
      ),
    );
  }
}

/// The saved record matching an authorization reversal (FR-024b):
/// read-only, with "Open it". It never blocks and is not a duplicate.
class _MatchedRecord extends StatelessWidget {
  const _MatchedRecord({required this.record});

  final DuplicateRecordRef record;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
      child: Container(
        key: const ValueKey('import_review_matched_record'),
        padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.smsImportReviewMatchedRecord, style: AppTypography.label),
            const SizedBox(height: AppSpacing.xs),
            Text(
              [
                SmsImportLabels.type(l10n, record.type),
                SmsImportLabels.money(context, record.amount),
                SmsImportLabels.date(context, record.date),
              ].join(l10n.smsImportReviewListSeparator),
              style: AppTypography.body,
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(
                    AppSizes.minTouchTarget,
                    AppSizes.minTouchTarget,
                  ),
                ),
                onPressed: () => context.push(
                  record.recordType == SavedRecordType.financeEntry
                      ? '/finance/entries/${record.id}/edit'
                      : '/transactions/${record.id}/edit',
                ),
                child: Text(l10n.smsImportReviewOpenRecord),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountSection extends StatefulWidget {
  const _AmountSection({
    required this.state,
    required this.cubit,
    required this.enabled,
  });

  final ImportReviewState state;
  final ImportReviewCubit cubit;
  final bool enabled;

  @override
  State<_AmountSection> createState() => _AmountSectionState();
}

class _AmountSectionState extends State<_AmountSection> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.state.amountInput,
  );

  @override
  void didUpdateWidget(covariant _AmountSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = widget.state.amountInput;
    if (text != _controller.text) {
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// A candidate amount as shown on its chip: with the currency through
  /// `CurrencyFormatter` when one is known, else the bare decimal.
  String _candidateLabel(BuildContext context, int minor) {
    final currency = widget.state.draft?.currency;
    return currency == null
        ? ImportReviewCubit.formatMinor(minor)
        : SmsImportLabels.money(context, Money.fromMinorUnits(minor, currency));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = widget.state;
    final item = state.item!;
    final draft = state.draft!;
    final missing = state.missing;
    final candidates = item.amountCandidates;
    final amountInvalid =
        missing.contains(ReviewField.amount) &&
        (state.amountInput.trim().isNotEmpty || state.isDirty);
    final currencyNeeded = draft.currency == null;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (candidates.length >= 2) ...[
            Text(l10n.smsImportReviewWhichAmount, style: AppTypography.label),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final minor in candidates)
                  Semantics(
                    // The same formatted amount the chip shows (FR-090).
                    label: l10n.smsImportReviewUseAmount(
                      _candidateLabel(context, minor),
                    ),
                    excludeSemantics: true,
                    child: ChoiceChip(
                      key: ValueKey('import_review_candidate_$minor'),
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      label: Text(_candidateLabel(context, minor)),
                      selected: draft.amountMinorUnits == minor,
                      onSelected: widget.enabled
                          ? (_) => widget.cubit.amountCandidateChosen(minor)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          AppTextField(
            key: const ValueKey('import_review_amount'),
            label: l10n.smsImportReviewAmountLabel,
            controller: _controller,
            enabled: widget.enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textDirection: TextDirection.ltr,
            errorText: amountInvalid ? l10n.smsImportReviewAmountInvalid : null,
            onChanged: widget.cubit.amountChanged,
          ),
          if (item.confidence[SmsField.amount] case final c?) ...[
            const SizedBox(height: AppSpacing.xs),
            ConfidenceIndicator(confidence: c),
          ],
          const SizedBox(height: AppSpacing.sm),
          CurrencyPicker.optional(
            key: const ValueKey('import_review_currency'),
            selected: draft.currency,
            enabled: widget.enabled,
            hint: l10n.smsImportReviewChooseCurrency,
            errorText: currencyNeeded
                ? l10n.smsImportReviewCurrencyNeeded
                : null,
            onChanged: widget.cubit.currencyChanged,
          ),
          if (item.foreignAmountText case final foreign?) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.smsImportReviewOriginalAmount(BidiIsolate.ltr(foreign)),
              style: AppTypography.bodyMuted,
            ),
          ],
        ],
      ),
    );
  }
}

class _NoteSection extends StatefulWidget {
  const _NoteSection({
    required this.state,
    required this.cubit,
    required this.enabled,
  });

  final ImportReviewState state;
  final ImportReviewCubit cubit;
  final bool enabled;

  @override
  State<_NoteSection> createState() => _NoteSectionState();
}

class _NoteSectionState extends State<_NoteSection> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.state.draft?.note ?? '',
  );

  @override
  void didUpdateWidget(covariant _NoteSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = widget.state.draft?.note ?? '';
    if (text != _controller.text) {
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final item = widget.state.item!;
    final name = item.merchant ?? item.counterparty;
    final tooLong = widget.state.missing.contains(ReviewField.note);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            key: const ValueKey('import_review_note'),
            label: l10n.smsImportReviewNoteLabel,
            controller: _controller,
            enabled: widget.enabled,
            maxLines: 3,
            maxLength: ReviewDraft.maxNoteLength,
            errorText: tooLong ? l10n.smsImportReviewFieldNote : null,
            onChanged: widget.cubit.noteChanged,
          ),
          if (name != null && name.isNotEmpty)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(
                    AppSizes.minTouchTarget,
                    AppSizes.minTouchTarget,
                  ),
                ),
                onPressed: widget.enabled
                    ? widget.cubit.useMerchantAsNote
                    : null,
                child: Text(l10n.smsImportReviewUseMerchant),
              ),
            ),
        ],
      ),
    );
  }
}

/// The masked original, read-only, in its own direction (FR-045, FR-091).
class _OriginalSection extends StatelessWidget {
  const _OriginalSection({required this.state, required this.cubit});

  final ImportReviewState state;
  final ImportReviewCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final original = state.original;
    // No readable original (decided, expired, or the key was lost after a
    // restore or reinstall, FR-062/FR-074a): "Show original" stays visible
    // but disabled, with the reason; the fields above are enough to add.
    if (!(state.item?.hasRawText ?? false) ||
        state.originalSection == OriginalSection.unavailable) {
      return AppCard(
        padding: EdgeInsetsDirectional.zero,
        child: ListTile(
          key: const ValueKey('import_review_original_unavailable'),
          enabled: false,
          leading: const Icon(Icons.visibility_off_outlined),
          title: Text(l10n.smsImportReviewShowOriginal),
          subtitle: Text(l10n.smsImportErrorOriginalUnavailable),
        ),
      );
    }
    return AppCard(
      padding: EdgeInsetsDirectional.zero,
      child: ExpansionTile(
        key: const ValueKey('import_review_original'),
        title: Text(l10n.smsImportReviewShowOriginal),
        initiallyExpanded: state.originalSection != OriginalSection.collapsed,
        onExpansionChanged: (_) => cubit.toggleOriginal(),
        childrenPadding: const EdgeInsetsDirectional.all(AppSpacing.md),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          switch (state.originalSection) {
            OriginalSection.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            OriginalSection.shown when original != null => Directionality(
              textDirection: original.direction == TextDirectionHint.rtl
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  original.text,
                  key: const ValueKey('import_review_original_text'),
                  textAlign: TextAlign.start,
                  style: AppTypography.body,
                ),
              ),
            ),
            _ => const SizedBox.shrink(),
          },
        ],
      ),
    );
  }
}

/// The missing-fields line, the save failure, and Add (FR-043a, FR-046).
class _Actions extends StatelessWidget {
  const _Actions({required this.state, required this.cubit});

  final ImportReviewState state;
  final ImportReviewCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final missing = state.missing;
    final missingText = SmsImportLabels.missingList(l10n, missing);
    final failure = state.failure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (missing.isNotEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
            child: Text(
              l10n.smsImportReviewMissing(missingText),
              key: const ValueKey('import_review_missing'),
              style: AppTypography.body.copyWith(color: scheme.error),
            ),
          ),
        if (failure != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
            child: Semantics(
              liveRegion: true,
              child: Text(
                l10n.messageFor(failure),
                key: const ValueKey('import_review_failure'),
                style: AppTypography.body.copyWith(color: scheme.error),
              ),
            ),
          ),
        Semantics(
          label: missing.isEmpty
              ? null
              : l10n.smsImportSemanticsAddUnavailable(missingText),
          child: AppButton(
            key: const ValueKey('import_review_add'),
            label: l10n.smsImportReviewAdd,
            icon: Icons.check,
            isLoading: state.isSubmitting,
            onPressed: state.canAdd ? cubit.add : null,
          ),
        ),
        if (cubit.canIgnore) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            key: const ValueKey('import_review_ignore'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(AppSizes.minTouchTarget),
            ),
            onPressed: state.status == ImportReviewStatus.ready
                ? cubit.ignore
                : null,
            icon: const Icon(Icons.visibility_off_outlined),
            label: Text(l10n.smsImportReviewIgnore),
          ),
        ],
      ],
    );
  }
}

/// The review's overflow menu entries.
enum _ReviewMenu { muteSender }

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: muted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTypography.body)),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final finance = context.financeColors;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const ValueKey('import_review_duplicate_banner'),
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: finance.warningSurface,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(icon, color: finance.warning),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: AppTypography.body.copyWith(color: finance.warning),
              ),
            ),
            if (actionLabel case final label?)
              TextButton(
                key: const ValueKey('import_review_duplicate_compare'),
                style: TextButton.styleFrom(
                  foregroundColor: finance.warning,
                  minimumSize: const Size(
                    AppSizes.minTouchTarget,
                    AppSizes.minTouchTarget,
                  ),
                ),
                onPressed: onAction,
                child: Text(label),
              ),
          ],
        ),
      ),
    );
  }
}

/// The two sides and the comparison phrases of the probable-duplicate
/// sheet: the saved record (or the other pending message) against the
/// draft's CURRENT values (FR-060).
class _DuplicateComparison {
  const _DuplicateComparison(this.existing, this.incoming, this.phrases);

  factory _DuplicateComparison.of(
    BuildContext context,
    ImportReviewState state,
    DuplicateFinding finding,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final item = state.item!;
    final draft = state.draft;
    final record = finding.matchedRecord;
    final other = state.duplicatePending;

    final DuplicateSide existing;
    if (record != null) {
      existing = DuplicateSide(
        title: l10n.smsImportDuplicateExisting,
        typeLabel: SmsImportLabels.type(l10n, record.type),
        amount: record.amount,
        date: record.date,
        note: record.note,
        importedFromSms: record.importProvenance?.isSms ?? false,
      );
    } else {
      existing = DuplicateSide(
        title: l10n.smsImportDuplicateOtherPending,
        typeLabel: other == null ? null : _typeLabel(l10n, other),
        amount: other?.amount,
        date: other?.occurredOn,
        sourceLabel: other == null
            ? null
            : l10n.smsImportReviewSourceLabel(other.source.name),
      );
    }

    final type = draft?.type;
    final incoming = DuplicateSide(
      title: l10n.smsImportDuplicateIncoming,
      typeLabel: type != null
          ? SmsImportLabels.type(l10n, type)
          : _typeLabel(l10n, item),
      amount: draft?.money ?? item.amount,
      date: draft?.date ?? item.occurredOn,
      sourceLabel: l10n.smsImportReviewSourceLabel(item.source.name),
    );
    return _DuplicateComparison(
      existing,
      incoming,
      duplicateComparisonPhrases(
        l10n,
        existing: existing,
        incoming: incoming,
        statedOriginalAmount: item.foreignAmount,
      ),
    );
  }

  final DuplicateSide existing;
  final DuplicateSide incoming;
  final List<String> phrases;

  static String _typeLabel(AppLocalizations l10n, PendingSmsImport item) =>
      item.suggestedType.isSavable
      ? SmsImportLabels.type(l10n, item.suggestedType)
      : SmsImportLabels.kind(l10n, item.kind);
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ExcludeSemantics(
      child: ListView(
        key: const ValueKey('import_review_skeleton'),
        padding:
            const EdgeInsets.all(AppSpacing.md) + AppGlassInsets.of(context),
        children: [
          for (final height in const [96.0, 64.0, 120.0, 64.0])
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
