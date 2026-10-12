import 'package:equatable/equatable.dart';

import '../../../finance/domain/entities/finance_entry_type.dart';

/// A learned merchant -> category suggestion (FR-056, data-model §3.4).
///
/// The primary key is [merchantKey] + [entryType]. [categoryId] is plain
/// text with no foreign key, so deleting a category never blocks; a mapping
/// whose category is archived or missing is skipped at suggestion time and
/// left in place.
class MerchantCategoryMapping extends Equatable {
  const MerchantCategoryMapping({
    required this.merchantKey,
    required this.entryType,
    required this.categoryId,
    required this.updatedAt,
  });

  /// Normalized merchant text (digit and punctuation free).
  final String merchantKey;
  final FinanceEntryType entryType;
  final String categoryId;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [merchantKey, entryType, categoryId, updatedAt];

  /// Redacted: the merchant key is user data.
  @override
  String toString() => 'MerchantCategoryMapping(type: ${entryType.name})';
}
