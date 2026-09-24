import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../cubit/category_cubit.dart';
import '../cubit/category_state.dart';
import '../widgets/article_list_tile.dart';
import '../widgets/education_page_scaffold.dart';
import 'content_library_home_page.dart';

/// One category's articles, each shown by title and short description
/// (FR-003).
class CategoryPage extends StatelessWidget {
  const CategoryPage({required this.categoryId, super.key});

  final String categoryId;

  @override
  Widget build(BuildContext context) {
    // Resolved here, not inside `create`: the content language follows the
    // active app locale, which `create` must not subscribe to.
    final languageCode = Localizations.localeOf(context).languageCode;
    return BlocProvider(
      create: (_) => getIt<CategoryCubit>()..load(categoryId, languageCode),
      child: _CategoryView(categoryId: categoryId),
    );
  }
}

class _CategoryView extends StatelessWidget {
  const _CategoryView({required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        return EducationPageScaffold(
          title: state.category?.title ?? l10n.finEduTitle,
          body: switch (state.status) {
            CategoryStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            CategoryStatus.failure => EducationLoadErrorView(
              onRetry: () => context.read<CategoryCubit>().load(
                categoryId,
                Localizations.localeOf(context).languageCode,
              ),
            ),
            CategoryStatus.success when state.articles.isEmpty => AppEmptyView(
              icon: Icons.menu_book_outlined,
              title: l10n.finEduEmptyCategoryTitle,
              message: l10n.finEduEmptyCategoryMessage,
            ),
            CategoryStatus.success => ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (state.category != null) ...[
                  Text(
                    state.category!.shortDescription,
                    style: AppTypography.body.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                for (final article in state.articles)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ArticleListTile(
                      key: ValueKey('fin_edu_article_${article.id}'),
                      title: article.title,
                      shortDescription: article.shortDescription,
                      onTap: () => context.push(
                        FinancialEducationRoutes.article(
                          categoryId,
                          article.id,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          },
        );
      },
    );
  }
}
