import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../core/error/failure.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/finance_entry_type.dart';
import '../../domain/entities/finance_failures.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/finance_dao.dart';
import '../models/category_mapper.dart';

@LazySingleton(as: CategoryRepository)
class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._dao);

  final FinanceDao _dao;
  static const _uuid = Uuid();

  @override
  Future<Either<Failure, Category>> createCategory({
    required String name,
    required CategoryType type,
    required String icon,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Left(ValidationFailure('Category name is required'));
    }
    try {
      final normalized = normalizeCategoryName(trimmed);
      // Scoped to (normalizedName, type) among active rows only: "Gift" can
      // exist as both an income and an expense category, and a name freed
      // by archiving can be taken again (research.md Decision 5).
      final existing = await _dao.findActiveCategoryByNormalizedName(
        normalizedName: normalized,
        type: type,
      );
      if (existing != null) {
        return Left(
          DuplicateCategoryFailure(
            'A category named "${existing.name}" already exists',
            existing: existing.toDomain(),
          ),
        );
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final row = await _dao.insertCategory(
        db.FinanceCategoriesCompanion.insert(
          id: _uuid.v4(),
          name: trimmed,
          normalizedName: normalized,
          type: type.dbValue,
          icon: icon,
          createdAt: now,
          updatedAt: now,
        ),
      );
      return Right(row.toDomain());
    } catch (e) {
      return Left(CacheFailure('Failed to create category: $e'));
    }
  }

  @override
  Future<Either<Failure, Category>> editCategory({
    required String categoryId,
    required String name,
    required String icon,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Left(ValidationFailure('Category name is required'));
    }
    try {
      final existing = await _dao.getCategoryById(categoryId);
      if (existing == null) {
        return const Left(NotFoundFailure('Category not found'));
      }

      final normalized = normalizeCategoryName(trimmed);
      final clash = await _dao.findActiveCategoryByNormalizedName(
        normalizedName: normalized,
        type: financeEntryTypeFromDb(existing.type),
      );
      // A rename that lands on another active category's name is the same
      // collision as creating one; renaming a category to its own current
      // name (e.g. only the icon changed) is not.
      if (clash != null && clash.id != categoryId) {
        return Left(
          DuplicateCategoryFailure(
            'A category named "${clash.name}" already exists',
            existing: clash.toDomain(),
          ),
        );
      }

      final updated = await _dao.updateCategory(
        categoryId,
        db.FinanceCategoriesCompanion(
          name: db.Value(trimmed),
          normalizedName: db.Value(normalized),
          icon: db.Value(icon),
          updatedAt: db.Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
      return Right(updated.toDomain());
    } catch (e) {
      return Left(CacheFailure('Failed to edit category: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeCategory(String categoryId) async {
    try {
      final existing = await _dao.getCategoryById(categoryId);
      if (existing == null) {
        return const Left(NotFoundFailure('Category not found'));
      }
      final references = await _dao.countEntriesForCategory(categoryId);
      if (references == 0) {
        await _dao.deleteCategory(categoryId);
      } else {
        // Never deleted while entries point at it — archiving is what keeps
        // FR-010's "history is never orphaned" promise (research.md
        // Decision 4). Soft-deleted entries count, since restoring one has
        // to find its category again.
        await _dao.archiveCategory(categoryId, DateTime.now());
      }
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to remove category: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getCategories({
    required CategoryType type,
    bool includeArchived = false,
  }) async {
    try {
      final rows = await _dao.getCategoriesByType(
        type,
        includeArchived: includeArchived,
      );
      return Right([for (final row in rows) row.toDomain()]);
    } catch (e) {
      return Left(CacheFailure('Failed to load categories: $e'));
    }
  }

  @override
  Future<Either<Failure, Category>> getCategoryById(String categoryId) async {
    try {
      final row = await _dao.getCategoryById(categoryId);
      if (row == null) {
        return const Left(NotFoundFailure('Category not found'));
      }
      return Right(row.toDomain());
    } catch (e) {
      return Left(CacheFailure('Failed to load category: $e'));
    }
  }
}
