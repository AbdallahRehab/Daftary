import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/category.dart';
import '../entities/finance_entry_type.dart';

/// Domain/Data boundary for [Category] — the vocabulary both this feature
/// and, later, Budgets (V2) read from.
abstract class CategoryRepository {
  /// Creates a custom category (FR-007). Returns a
  /// `DuplicateCategoryFailure` instead of inserting when an existing
  /// *active* category of the same [type] has an identical normalized name
  /// (FR-008, research.md Decision 5) — never silently merges into or
  /// renames the existing one.
  Future<Either<Failure, Category>> createCategory({
    required String name,
    required CategoryType type,
    required String icon,
  });

  /// Renames and/or re-icons an existing category, default or custom
  /// (FR-009). Every entry referencing it reflects the change immediately,
  /// since entries store a `categoryId` and not a name snapshot. `type` is
  /// absent by design — it is immutable after creation (data-model.md).
  Future<Either<Failure, Category>> editCategory({
    required String categoryId,
    required String name,
    required String icon,
  });

  /// Removes a category (FR-010, research.md Decision 4): hard-deletes it
  /// if it has zero referencing entries (soft-deleted ones included),
  /// otherwise archives it. The caller neither chooses nor needs to know
  /// which branch applied.
  Future<Either<Failure, Unit>> removeCategory(String categoryId);

  /// All categories of [type]. [includeArchived] `false` (the default) is
  /// what the entry-creation picker uses (FR-011); the management screen
  /// passes `true` to also show archived ones.
  Future<Either<Failure, List<Category>>> getCategories({
    required CategoryType type,
    bool includeArchived = false,
  });

  /// One category by id, archived or not — what an entry being edited uses
  /// to resolve a category that has since been archived (FR-011).
  Future<Either<Failure, Category>> getCategoryById(String categoryId);
}
