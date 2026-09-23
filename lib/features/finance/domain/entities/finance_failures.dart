import '../../../../core/error/failure.dart';
import 'category.dart';

/// An active category of the same type already carries this normalized name
/// (FR-008, research.md Decision 5). Carries [existing] so the form can
/// point the user at the category they already have instead of only telling
/// them the name is taken.
class DuplicateCategoryFailure extends Failure {
  const DuplicateCategoryFailure(super.message, {required this.existing});

  final Category existing;

  @override
  List<Object?> get props => [message, existing];
}

/// Informational: a removal was resolved as an archive because the category
/// still has [referenceCount] entries pointing at it.
///
/// This never blocks the removal — `removeCategory` succeeds either way
/// (data-model.md's archive-instead-of-block semantics). It exists so a
/// caller that wants to explain *why* the category is still listed (now as
/// archived) has the reason available rather than inferring it.
class CategoryInUseFailure extends Failure {
  const CategoryInUseFailure(super.message, {required this.referenceCount});

  final int referenceCount;

  @override
  List<Object?> get props => [message, referenceCount];
}
