import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'tool_result.dart';

/// One entry of `AIMessage.groundingRefsJson` (data-model.md): which tool
/// produced a figure the answer may state, and which existing use case
/// that tool's data is an unmodified projection of.
class GroundingRef extends Equatable {
  const GroundingRef({required this.toolName, required this.sourceUseCase});

  final String toolName;
  final String sourceUseCase;

  static const String toolNameKey = 'toolName';
  static const String sourceUseCaseKey = 'sourceUseCase';

  Map<String, String> toJson() => {
    toolNameKey: toolName,
    sourceUseCaseKey: sourceUseCase,
  };

  @override
  List<Object?> get props => [toolName, sourceUseCase];
}

/// Encodes/decodes `AIMessage.groundingRefsJson`: a JSON list of
/// `{"toolName": ..., "sourceUseCase": ...}` objects, one per distinct
/// tool/use-case pair, in order of first use.
///
/// Populated only from real [ToolResult]s produced by local dispatch —
/// never from anything the model said (data-model.md validation rule).
abstract final class GroundingRefsCodec {
  /// `null` when [results] is empty: an answer that used no tool is never
  /// marked as grounded (User Story 3, T047).
  static String? encode(Iterable<ToolResult> results) {
    final refs = <GroundingRef>{
      for (final r in results)
        GroundingRef(toolName: r.toolName, sourceUseCase: r.sourceUseCase),
    };
    if (refs.isEmpty) return null;
    return jsonEncode([for (final ref in refs) ref.toJson()]);
  }

  /// The refs in [json]; empty for `null` or anything malformed.
  static List<GroundingRef> decode(String? json) {
    if (json == null) return const [];
    try {
      final list = jsonDecode(json);
      if (list is! List) return const [];
      return [
        for (final e in list)
          if (e is Map &&
              e[GroundingRef.toolNameKey] is String &&
              e[GroundingRef.sourceUseCaseKey] is String)
            GroundingRef(
              toolName: e[GroundingRef.toolNameKey] as String,
              sourceUseCase: e[GroundingRef.sourceUseCaseKey] as String,
            ),
      ];
    } on FormatException {
      return const [];
    }
  }
}
