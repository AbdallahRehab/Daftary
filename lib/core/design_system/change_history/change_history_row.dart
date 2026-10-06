import 'package:equatable/equatable.dart';

/// One labelled value inside a [ChangeHistoryRow], already formatted for
/// display (for example "Previous amount" / "1000.00 EGP").
class ChangeHistoryField extends Equatable {
  const ChangeHistoryField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  List<Object?> get props => [label, value];
}

/// A feature-neutral line of a record's change history (022 C3): what
/// happened ([label]), when ([timestamp]) and the earlier values
/// ([fields]). Features map their own audit entries to this, so one
/// cubit and one sheet serve transactions, savings and finance entries.
class ChangeHistoryRow extends Equatable {
  const ChangeHistoryRow({
    required this.label,
    required this.timestamp,
    this.fields = const [],
  });

  final String label;
  final DateTime timestamp;
  final List<ChangeHistoryField> fields;

  @override
  List<Object?> get props => [label, timestamp, fields];
}
