import 'package:equatable/equatable.dart';

/// The structured, minimal return value of one financial query tool call
/// (014 data-model.md, contracts/financial_query_tools.md). Ephemeral: it
/// exists only for one `AskFinancialQuestion` execution and is never
/// persisted on its own — its provenance survives only as
/// `AIMessage.groundingRefsJson`.
class ToolResult extends Equatable {
  const ToolResult({
    required this.toolName,
    required this.sourceUseCase,
    required this.data,
    required this.foundData,
  });

  /// Which tool produced this (an `AIToolNames` value).
  final String toolName;

  /// The existing use case whose return value [data] is a direct,
  /// unmodified projection of (e.g. `GetCategoryBreakdown`).
  final String sourceUseCase;

  /// Only the fields the question needs (FR-007) — never the wrapped use
  /// case's full return object. Money values stay integer minor units,
  /// exactly as the source use case returned them.
  final Map<String, Object?> data;

  /// `false` when the wrapped use case legitimately found nothing (no such
  /// person, no budget for the month, ...). Lets the model answer honestly
  /// instead of narrating an empty result as a real zero (User Story 3).
  final bool foundData;

  @override
  List<Object?> get props => [toolName, sourceUseCase, data, foundData];
}
