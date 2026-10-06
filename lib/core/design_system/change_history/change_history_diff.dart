import 'change_history_row.dart';

/// Pure helpers turning "state before" / "state after" snapshots (each a
/// list of labelled, already formatted values in a fixed field order) into
/// the [ChangeHistoryField]s of a history row (022 C3). Shared by every
/// feature's audit mapper.
abstract final class ChangeHistoryDiff {
  /// Only the fields whose value differs, each as one line built by
  /// [line] (`field`, `from`, `to`). The line carries its own label, so
  /// the returned field's label is empty. A missing or empty side is shown
  /// as [empty] (the caller's localized "(none)").
  static List<ChangeHistoryField> changed(
    List<ChangeHistoryField> before,
    List<ChangeHistoryField> after,
    String Function(String field, String from, String to) line, {
    String empty = '',
  }) {
    final afterByLabel = {for (final f in after) f.label: f.value};
    final beforeByLabel = {for (final f in before) f.label: f.value};
    final labels = [
      ...before.map((f) => f.label),
      ...after.map((f) => f.label).where((l) => !beforeByLabel.containsKey(l)),
    ];
    return [
      for (final label in labels)
        if ((beforeByLabel[label] ?? '') != (afterByLabel[label] ?? ''))
          ChangeHistoryField(
            label: '',
            value: line(
              label,
              _orEmpty(beforeByLabel[label], empty),
              _orEmpty(afterByLabel[label], empty),
            ),
          ),
    ];
  }

  static String _orEmpty(String? value, String empty) =>
      (value == null || value.isEmpty) ? empty : value;

  /// Every present value, relabelled through [relabel] (identity for a
  /// created row, "… when deleted" for a delete row).
  static List<ChangeHistoryField> all(
    List<ChangeHistoryField> snapshot, [
    String Function(String label)? relabel,
  ]) => [
    for (final f in snapshot)
      ChangeHistoryField(
        label: relabel == null ? f.label : relabel(f.label),
        value: f.value,
      ),
  ];
}
