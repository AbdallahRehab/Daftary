# Contract: CategoryRepository

Same local-only Domain/Data boundary as `finance_repository.md`. All methods return `Either<Failure, T>`.

```dart
abstract class CategoryRepository {
  /// Creates a custom category (FR-007). Returns [DuplicateCategoryFailure]
  /// instead of inserting when an existing *active* category of the same
  /// [type] has an identical normalized name (FR-008, research.md
  /// Decision 5) — never silently merges or renames the existing one.
  Future<Either<Failure, Category>> createCategory({
    required String name,
    required CategoryType type,
    required String icon,
  });

  /// Renames and/or re-icons an existing category, default or custom
  /// (FR-009). Every FinanceEntry referencing it reflects the change
  /// immediately since entries store a categoryId, not a name snapshot
  /// (data-model.md). [type] cannot be changed here (immutable after
  /// creation, data-model.md).
  Future<Either<Failure, Category>> editCategory({
    required String categoryId,
    required String name,
    required String icon,
  });

  /// Removes a category (FR-010, research.md Decision 4): hard-deletes if
  /// it has zero referencing FinanceEntries (including soft-deleted ones);
  /// otherwise sets isArchived = true and preserves it. The caller does not
  /// need to know or choose which branch applies.
  Future<Either<Failure, Unit>> removeCategory(String categoryId);

  /// All categories of [type]. [includeArchived] = false (the default) is
  /// what the entry-creation picker uses (FR-011); the category management
  /// screen passes true to also show archived ones for editing/visibility.
  Future<Either<Failure, List<Category>>> getCategories({
    required CategoryType type,
    bool includeArchived = false,
  });
}
```
