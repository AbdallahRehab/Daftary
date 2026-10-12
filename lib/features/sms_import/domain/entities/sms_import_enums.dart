/// Enums of the bank-message import domain (023 data-model §2).
///
/// Every enum that is stored has an explicit `dbValue` and a total
/// `fromDb` that never throws. An unknown stored string maps to the most
/// conservative value, documented on each `fromDb`.
library;

/// Where a message entered the pipeline (data-model §2.1).
enum SmsSource {
  /// User-initiated inbox scan (FR-006).
  inboxScan('scan'),

  /// Automatic foreground catch-up (FR-013).
  catchUpScan('catchup'),

  /// Paste screen, clipboard or text field (FR-015).
  paste('paste'),

  /// Android `ACTION_SEND text/plain` (FR-016).
  share('share');

  const SmsSource(this.dbValue);

  /// The stored `origin` column value.
  final String dbValue;

  /// Only inbox reads know the sender.
  bool get hasSender => this == inboxScan || this == catchUpScan;

  /// Only inbox reads know the provider receipt time.
  bool get hasReceivedAt => hasSender;

  /// Paste and share have no trusted sender, so their confidence is capped
  /// at Medium (FR-020).
  bool get capsConfidenceAtMedium => this == paste || this == share;

  /// Unknown or null -> [paste]: the most restrictive source (no sender, no
  /// receipt time, confidence capped at Medium).
  static SmsSource fromDb(String? value) {
    for (final source in values) {
      if (source.dbValue == value) return source;
    }
    return paste;
  }
}

/// Lifecycle status of a pending import (data-model §2.2, §6).
enum SmsImportStatus {
  pending('pending'),
  added('added'),
  ignored('ignored'),

  /// "It's the same, don't add" (FR-061).
  duplicateClosed('duplicate'),
  expired('expired');

  const SmsImportStatus(this.dbValue);

  final String dbValue;

  bool get isTerminal => this != pending;

  /// Shown in the 30-day Undo list (FR-061, FR-067).
  bool get isUndoable => this == ignored || this == expired;

  /// Unknown or null -> [duplicateClosed]: terminal (so Add is impossible),
  /// not in the Undo list, and purged like any decided row. Mapping an
  /// unknown value to [pending] could let a decided row be added again.
  static SmsImportStatus fromDb(String? value) {
    for (final status in values) {
      if (status.dbValue == value) return status;
    }
    return duplicateClosed;
  }
}

/// What a message describes (data-model §2.3).
enum SmsKind {
  cardPurchase('card_purchase'),
  atmWithdrawal('atm_withdrawal'),

  /// Credit-card payment, installment debit or conversion notice, own-card
  /// or loan settlement.
  cardOrLoanSettlement('card_or_loan_settlement'),
  billPayment('bill_payment'),
  fee('fee'),
  salary('salary'),
  otherDeposit('other_deposit'),
  transferOut('transfer_out'),
  transferIn('transfer_in'),
  refund('refund'),

  /// A cancelled authorization; Ignore is suggested (FR-024b).
  authorizationReversal('authorization_reversal'),
  ownAccountTransfer('own_account_transfer'),
  unknown('unknown');

  const SmsKind(this.dbValue);

  final String dbValue;

  /// Unknown or null -> [unknown].
  static SmsKind fromDb(String? value) {
    for (final kind in values) {
      if (kind.dbValue == value) return kind;
    }
    return unknown;
  }
}

/// Which way the money moved, as far as the message says (data-model §2.4).
enum SmsDirection {
  debit('debit'),
  credit('credit'),

  /// Amount present, nature not determinable (FR-033).
  unknown('unknown');

  const SmsDirection(this.dbValue);

  final String dbValue;

  /// Unknown or null -> [unknown].
  static SmsDirection fromDb(String? value) {
    for (final direction in values) {
      if (direction.dbValue == value) return direction;
    }
    return unknown;
  }
}

/// The suggested record type: a suggestion, never a decision
/// (data-model §2.5). Repayment and occasion contribution are never values
/// (NG8, FR-048).
enum SuggestedRecordType {
  /// A `FinanceEntry` of type expense.
  expense('expense'),

  /// A `FinanceEntry` of type income.
  income('income'),

  /// A `MoneyTransaction` given, kind `initialExchange`.
  given('given'),

  /// A `MoneyTransaction` received, kind `initialExchange`.
  received('received'),

  /// Ignore is the suggested action.
  ignore('ignore'),

  /// No default; the user must choose (FR-033).
  unset('unset');

  const SuggestedRecordType(this.dbValue);

  final String dbValue;

  /// The four types an import can be saved as.
  bool get isSavable => isFinanceEntry || isPersonTransaction;

  /// Saved as a `FinanceEntry` (needs a category).
  bool get isFinanceEntry => this == expense || this == income;

  /// Saved as a people-ledger `MoneyTransaction` (needs a person).
  bool get isPersonTransaction => this == given || this == received;

  /// Unknown or null -> [unset]: no default, the user must choose.
  static SuggestedRecordType fromDb(String? value) {
    for (final type in values) {
      if (type.dbValue == value) return type;
    }
    return unset;
  }
}

/// Which table an Add wrote to.
enum SavedRecordType {
  moneyTransaction('moneyTransaction'),
  financeEntry('financeEntry');

  const SavedRecordType(this.dbValue);

  final String dbValue;

  /// Unknown or null -> `null`: no saved-record reference is claimed.
  static SavedRecordType? fromDb(String? value) {
    for (final type in values) {
      if (type.dbValue == value) return type;
    }
    return null;
  }
}

/// The decision a tombstone remembers (data-model §3.2).
enum TombstoneOutcome {
  added('added'),
  ignored('ignored'),
  duplicate('duplicate'),
  expired('expired');

  const TombstoneOutcome(this.dbValue);

  final String dbValue;

  /// Unknown or null -> [duplicate]: it still blocks the message from
  /// resurfacing and claims no saved record.
  static TombstoneOutcome fromDb(String? value) {
    for (final outcome in values) {
      if (outcome.dbValue == value) return outcome;
    }
    return duplicate;
  }
}

/// Informational flags on a pending import (data-model §3.1).
enum SmsWarning {
  atmIgnoredByDefault('atm_ignored_by_default'),

  /// FR-024a.
  refundHint('refund_hint'),
  ownAccountSuggestedIgnore('own_account_suggested_ignore'),
  cardSettlementSuggestedIgnore('card_settlement_suggested_ignore'),
  genericParser('generic_parser'),

  /// The bank profile was built from synthetic samples and is not yet
  /// verified on real ones: overall confidence is capped at Medium
  /// (orchestrator decision on OQ2/OQ3).
  unverifiedProfile('unverified_profile'),
  ambiguousAmount('ambiguous_amount'),
  unsupportedCurrency('unsupported_currency'),
  dateInferred('date_inferred'),
  currencyInferred('currency_inferred'),
  foreignCurrencyBilledAmount('foreign_currency_billed_amount'),
  feeSeparateItem('fee_separate_item'),

  /// A fee split from its parent message (FR-030a).
  feeFromMessage('fee_from_message'),

  /// FR-024b.
  reversalHint('reversal_hint'),
  maskedReference('masked_reference'),

  /// Informational, recomputed by `CheckDuplicates`.
  possibleDuplicate('possible_duplicate'),

  /// Informational, recomputed by `CheckDuplicates` (FR-051d).
  possibleOwnTransfer('possible_own_transfer');

  const SmsWarning(this.dbValue);

  final String dbValue;

  /// Unknown or null -> `null`: an unknown warning is dropped, never
  /// reinterpreted as a different one.
  static SmsWarning? fromDb(String? value) {
    for (final warning in values) {
      if (warning.dbValue == value) return warning;
    }
    return null;
  }
}

/// How far back an explicit scan reads (FR-006). Never above 90 days.
enum ScanWindow {
  days7(7),
  days30(30),
  days90(90);

  const ScanWindow(this.days);

  /// The stored `scan_window_days` value.
  final int days;

  static const ScanWindow defaultWindow = days30;

  /// Unknown or null -> [days30], the default.
  static ScanWindow fromDays(int? days) {
    for (final window in values) {
      if (window.days == days) return window;
    }
    return defaultWindow;
  }
}

/// Which kind of scan holds the `ScanCoordinator` (FR-013).
enum ScanKind {
  /// User-initiated `RunInboxScan`.
  explicit,

  /// Automatic `RunCatchUpScan`.
  catchUp,
}
