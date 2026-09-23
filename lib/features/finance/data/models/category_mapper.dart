import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/category.dart' as domain;
import '../../domain/entities/finance_entry_type.dart';

/// Maps `finance_categories` rows to the domain [domain.Category]. `type` is
/// a plain text column, so this extension is the single place the string ⇄
/// enum conversion happens (same shape as `transaction_mapper.dart`).
extension FinanceCategoryMapper on db.FinanceCategory {
  domain.Category toDomain() => domain.Category(
    id: id,
    name: name,
    type: financeEntryTypeFromDb(type),
    icon: icon,
    isDefault: isDefault,
    isArchived: isArchived,
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
  );
}

/// Trim, collapse internal whitespace, lowercase — the normalization the
/// FR-008 duplicate check compares on, mirroring `People.normalizedName`.
String normalizeCategoryName(String name) =>
    name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
