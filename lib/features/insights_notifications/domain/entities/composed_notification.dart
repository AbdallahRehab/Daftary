import 'package:equatable/equatable.dart';

import 'notification_source_type.dart';

/// Where tapping a notification leads (FR-014). Round-trips through the
/// platform notification payload as a plain string via [encode]/[decode].
class NotificationDeepLinkTarget extends Equatable {
  const NotificationDeepLinkTarget({
    required this.type,
    required this.id,
    this.applicablePeriod,
  });

  final NotificationSourceType type;

  /// The category id (010) or savings goal id (011).
  final String id;

  /// The budget month (`'YYYY-MM'`) a [NotificationSourceType.budgetCategory]
  /// target belongs to — a category is only budgeted within a given month,
  /// so the id alone cannot resolve it. Always `null` for savings goals.
  final String? applicablePeriod;

  static final RegExp _period = RegExp(r'^\d{4}-\d{2}$');

  /// `'<type>:<id>'`, with `'@<YYYY-MM>'` appended when
  /// [applicablePeriod] is set — e.g. `'budgetCategory:abc@2026-09'`,
  /// `'savingsGoal:xyz'`.
  String encode() {
    final base = '${type.name}:$id';
    return applicablePeriod == null ? base : '$base@$applicablePeriod';
  }

  /// The inverse of [encode]. Returns `null` for a missing or unrecognized
  /// payload (e.g. one written by an older app version) rather than
  /// throwing, so a tap on it can fall back to opening the app normally.
  static NotificationDeepLinkTarget? decode(String? payload) {
    if (payload == null) return null;
    final separator = payload.indexOf(':');
    if (separator <= 0) return null;

    final typeName = payload.substring(0, separator);
    final type = NotificationSourceType.values
        .where((t) => t.name == typeName)
        .firstOrNull;
    if (type == null) return null;

    var id = payload.substring(separator + 1);
    String? period;
    final at = id.lastIndexOf('@');
    if (at >= 0 && _period.hasMatch(id.substring(at + 1))) {
      period = id.substring(at + 1);
      id = id.substring(0, at);
    }
    if (id.isEmpty) return null;

    return NotificationDeepLinkTarget(
      type: type,
      id: id,
      applicablePeriod: period,
    );
  }

  @override
  List<Object?> get props => [type, id, applicablePeriod];
}

/// A fully worded, ready-to-deliver notification (data-model.md). Built from
/// real 010/011 values through `gen_l10n` templates before any phrasing
/// service ever sees it (research.md Decision 3). Ephemeral — not persisted.
class ComposedNotification extends Equatable {
  const ComposedNotification({
    required this.title,
    required this.body,
    required this.deepLinkTarget,
  });

  final String title;
  final String body;
  final NotificationDeepLinkTarget deepLinkTarget;

  @override
  List<Object?> get props => [title, body, deepLinkTarget];
}
