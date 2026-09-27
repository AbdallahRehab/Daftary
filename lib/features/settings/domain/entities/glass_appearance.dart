import 'package:equatable/equatable.dart';

import 'glass_level.dart';

/// The user's Liquid Glass preference (Domain, Flutter-free per
/// constitution Principle I; data-model.md).
///
/// Validation rules: an unknown or NULL field falls back to that field's
/// default only — the other fields keep their stored values. No values
/// outside `GlassLevel` are representable, and there is no numeric input
/// path, which is how the readability floors are enforced (FR-008).
///
/// Disabling keeps [transparency] and [intensity] unchanged, so they are
/// restored when the user re-enables (data-model.md State transitions).
class GlassAppearance extends Equatable {
  const GlassAppearance({
    this.enabled = true,
    this.transparency = GlassLevel.medium,
    this.intensity = GlassLevel.medium,
  });

  /// The first-launch / never-set value: glass ON, medium transparency and
  /// medium intensity (spec Assumptions).
  static const defaults = GlassAppearance();

  final bool enabled;

  /// Selects the surface tint alpha — `high` is the most see-through, and
  /// is itself the readability floor.
  final GlassLevel transparency;

  /// Selects the blur strength — `high` is the strongest blur.
  final GlassLevel intensity;

  GlassAppearance copyWith({
    bool? enabled,
    GlassLevel? transparency,
    GlassLevel? intensity,
  }) {
    return GlassAppearance(
      enabled: enabled ?? this.enabled,
      transparency: transparency ?? this.transparency,
      intensity: intensity ?? this.intensity,
    );
  }

  @override
  List<Object?> get props => [enabled, transparency, intensity];
}
