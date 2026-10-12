import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/parse_result.dart';
import '../entities/pending_sms_import.dart';
import '../entities/sms_import_failures.dart';
import '../entities/sms_value_types.dart';
import '../repositories/sms_import_repository.dart';
import '../repositories/sms_import_settings_repository.dart';
import '../services/review_lease_registry.dart';
import '../services/sms_message_parser.dart';
import 'load_parser_options.dart';
import 'parse_messages.dart';

/// Re-parses pending items with updated parser rules (FR-026, research
/// Decisions 7 and 8, domain-interfaces §5.4). Returns how many items got
/// new fields.
///
/// Runs only when the parser's `currentVersions` differ from the stored
/// `rulesSeen`. For each pending item whose rule version is out of date:
///
/// - an item open in a review (leased) is skipped, so a re-parse never
///   replaces fields under the user; `rulesSeen` is then NOT updated, so
///   the item is retried on the next run;
/// - the masked original is opened and parsed with the item's own source,
///   sender and receipt time, then [SmsImportRepository.replaceParsedFields]
///   replaces only the parsed-field columns. The fingerprint and reference
///   hashes are never recomputed (they came from the unmasked text);
/// - the item keeps its fields when the original cannot be opened (key
///   loss, FR-074a), when the re-parse is not a transaction, has no amount,
///   names another bank (the hashes are keyed by bank), or reads an amount
///   that differs from the stored one in a text that carries a mask: a
///   masked amount is unreadable, never a different value (research
///   Decision 7);
/// - a fee item split from its parent (FR-030a) keeps its fields: its
///   values come from the parent message's fee, not from its own parse.
///
/// Saved records are never read or touched. A store failure stops the run
/// with that failure and leaves `rulesSeen` unchanged, so it is retried.
/// Every failure is content-free.
@injectable
class ReparsePending {
  ReparsePending(
    this._repository,
    this._settings,
    this._parser,
    this._parseMessages,
    this._loadOptions,
    this._leases,
  );

  final SmsImportRepository _repository;
  final SmsImportSettingsRepository _settings;
  final SmsMessageParser _parser;
  final ParseMessages _parseMessages;
  final LoadParserOptions _loadOptions;
  final ReviewLeaseRegistry _leases;

  /// The masker's replacement character (U+2022).
  static const String maskChar = '•';

  Future<Either<Failure, int>> call() async {
    final current = Map<String, int>.of(_parser.currentVersions);
    final settings = await _settings.getSettings();
    if (settings case Left(:final value)) return Left(value);
    final seen = settings.getOrElse((_) => throw StateError('unreachable'));
    if (_sameVersions(seen.rulesSeen, current)) return const Right(0);

    final candidates = await _repository.pendingNeedingReparse(current);
    if (candidates case Left(:final value)) return Left(value);
    final due = candidates.getOrElse((_) => const []);

    var reparsed = 0;
    var deferred = false;
    if (due.isNotEmpty) {
      final options = await _loadOptions();
      if (options case Left(:final value)) return Left(value);
      final parserOptions = options.getOrElse((_) => const ParserOptions());

      for (final candidate in due) {
        if (_leases.isLeased(candidate.id)) {
          deferred = true;
          continue;
        }
        final loaded = await _repository.getById(candidate.id);
        if (loaded case Left(:final value)) {
          if (value is NotFoundFailure) continue; // decided or deleted
          return Left(value);
        }
        final item = loaded.getOrElse((_) => throw StateError('unreachable'));
        if (!item.isPending || item.parentImportId != null) continue;

        final original = await _repository.openOriginal(candidate.id);
        if (original case Left(:final value)) {
          if (value is OriginalUnavailableFailure) continue; // keep fields
          return Left(value);
        }
        final text = original.getOrElse((_) => '');
        final result = _parseMessages.parseOne(
          RawIncoming(
            text: text,
            sender: item.senderId,
            receivedAt: item.receivedAt,
          ),
          source: item.source,
          options: parserOptions,
        );
        final fields = fieldsFor(item, result, maskedText: text);
        if (fields == null) continue;

        // The review may have opened while this item was parsed.
        if (_leases.isLeased(candidate.id)) {
          deferred = true;
          continue;
        }
        final replaced = await _repository.replaceParsedFields(
          candidate.id,
          fields,
        );
        if (replaced case Left(:final value)) {
          if (value is NotFoundFailure ||
              value is ImportAlreadyDecidedFailure ||
              value is ValidationFailure) {
            continue; // decided meanwhile, or the new parse breaks a rule
          }
          return Left(value);
        }
        reparsed++;
      }
    }

    if (!deferred) {
      final saved = await _settings.setRulesSeen(current);
      if (saved case Left(:final value)) return Left(value);
    }
    return Right(reparsed);
  }

  /// The fields a re-parse may write for [item], or `null` when [item]
  /// keeps its fields (see the class doc).
  static ReparsedFields? fieldsFor(
    PendingSmsImport item,
    ParseResult result, {
    required String maskedText,
  }) {
    if (result is! ParsedTransaction) return null;
    if (result.bankId != item.bankId) return null;
    if (result.amount == null && result.amountCandidatesMinor.isEmpty) {
      return null;
    }
    if (maskedText.contains(maskChar) && result.amount != item.amount) {
      return null;
    }
    return ReparsedFields(
      parserId: result.parserId,
      ruleVersion: result.ruleVersion,
      kind: result.kind,
      direction: result.direction,
      suggestedType: result.suggestedType,
      confidence: result.confidence,
      amount: result.amount,
      amountCandidates: result.amountCandidatesMinor,
      foreignAmountText: result.foreignAmountText,
      foreignAmount: result.foreignAmount,
      occurredOn: result.occurredOn,
      timeMinutes: result.timeMinutes,
      merchant: result.merchant,
      merchantKey: result.merchantKey,
      counterparty: result.counterparty,
      cardLast4: result.cardLast4,
      suggestedCategoryId: result.suggestedCategoryKeyOrId,
      suggestedPersonId: result.suggestedPersonId,
      warnings: result.warnings,
    );
  }

  static bool _sameVersions(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
