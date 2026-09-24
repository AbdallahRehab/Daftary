import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/numeral_locale.dart';
import '../../../../core/money/numeral_parser.dart';
import '../../domain/entities/ai_message.dart';

/// One chat turn — the user's question or the assistant's answer
/// (T042, FR-021).
///
/// Alignment follows the reading direction via [AlignmentDirectional]:
/// the user's own messages sit at the *end* edge and the assistant's at
/// the *start* edge, so the layout mirrors correctly under RTL without
/// any hardcoded left/right. Colors come only from the theme's
/// `ColorScheme` (constitution Principle XV).
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    required this.text,
    required this.isFromUser,
    super.key,
    this.isFailed = false,
    this.timestamp,
    this.isObservation = false,
    this.isInterrupted = false,
  });

  /// Builds a bubble straight from a persisted [AIMessage].
  ChatBubble.fromMessage(
    AIMessage message, {
    Key? key,
    bool isObservation = false,
    bool isInterrupted = false,
  }) : this(
         key: key,
         text: message.content,
         isFromUser: message.isFromUser,
         isFailed: message.isFailed,
         timestamp: message.createdAt,
         isObservation: isObservation,
         isInterrupted: isInterrupted,
       );

  final String text;
  final bool isFromUser;

  /// A user question that got no answer (FR-018) — marked with an icon and
  /// a text label, never color alone. The retry affordance itself is the
  /// separate `AIFailureBanner` shown beneath it.
  final bool isFailed;
  final DateTime? timestamp;

  /// Assistant-only: frames the message as a proactive observation
  /// (User Story 7) with a labelled chip above the text.
  final bool isObservation;

  /// The assistant was turned off while this question was in flight.
  final bool isInterrupted;

  static final Map<String, DateFormat> _timeFormats = {};

  String _formatTime(BuildContext context, DateTime time) {
    final locale = numeralLocaleFor(
      Localizations.localeOf(context).languageCode,
    );
    final format = _timeFormats.putIfAbsent(
      locale,
      () => DateFormat.jm(locale),
    );
    return NumeralParser.toWesternDigits(format.format(time));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final background = isFromUser
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHigh;
    final foreground = isFromUser
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;
    const corner = Radius.circular(AppRadius.lg);
    const tail = Radius.circular(AppRadius.sm / 2);
    final radius = BorderRadiusDirectional.only(
      topStart: corner,
      topEnd: corner,
      bottomStart: isFromUser ? corner : tail,
      bottomEnd: isFromUser ? tail : corner,
    );
    final showFailure = isFailed || isInterrupted;
    final failureText = isInterrupted
        ? l10n.aiChatInterruptedLabel
        : l10n.aiChatMessageFailedLabel;
    final muted = AppTypography.label.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Align(
          alignment: isFromUser
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.82),
            child: Column(
              crossAxisAlignment: isFromUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  container: true,
                  label: isFromUser
                      ? l10n.aiChatYouLabel
                      : l10n.aiChatAssistantLabel,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: radius,
                      border: showFailure
                          ? Border.all(color: colorScheme.error)
                          : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm + 2,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isObservation && !isFromUser) ...[
                            _ObservationChip(
                              label: l10n.aiObservationLabel,
                              semanticLabel: l10n.aiObservationSemanticLabel,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          SelectableText(
                            text,
                            style: AppTypography.body.copyWith(
                              color: foreground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (showFailure || timestamp != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (showFailure) ...[
                          Icon(
                            Icons.error_outline,
                            size: 14,
                            color: colorScheme.error,
                          ),
                          Text(
                            failureText,
                            style: AppTypography.label.copyWith(
                              color: colorScheme.error,
                            ),
                          ),
                        ],
                        if (showFailure && timestamp != null)
                          const SizedBox(width: AppSpacing.xs),
                        if (timestamp != null)
                          Text(_formatTime(context, timestamp!), style: muted),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ObservationChip extends StatelessWidget {
  const _ObservationChip({required this.label, required this.semanticLabel});

  final String label;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insights_outlined,
                size: 14,
                color: colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.label.copyWith(
                  color: colorScheme.onTertiaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
