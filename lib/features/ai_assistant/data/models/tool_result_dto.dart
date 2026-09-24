import 'dart:convert';

import '../../domain/entities/tool_result.dart';

/// Wire form of a [ToolResult] sent back to the provider as a tool-call
/// result. Every adapter serializes a result through this one DTO so the
/// model always sees the same, minimal shape:
///
/// `{"toolName": ..., "foundData": true|false, "data": {...}}`
///
/// `data` is passed through unchanged (money stays integer minor units);
/// `sourceUseCase` is internal provenance and is never sent (FR-007).
class ToolResultDto {
  const ToolResultDto({
    required this.toolName,
    required this.foundData,
    required this.data,
  });

  factory ToolResultDto.fromEntity(ToolResult result) => ToolResultDto(
    toolName: result.toolName,
    foundData: result.foundData,
    data: result.data,
  );

  final String toolName;
  final bool foundData;
  final Map<String, Object?> data;

  Map<String, Object?> toJson() => {
    'toolName': toolName,
    'foundData': foundData,
    'data': data,
  };

  /// The JSON string placed in the provider's tool-result content slot.
  String toJsonString() => jsonEncode(toJson());
}
