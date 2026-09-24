import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/education_article.dart';
import '../cubit/article_cubit.dart';
import '../cubit/article_state.dart';
import '../widgets/education_page_scaffold.dart';

/// The article reader: title, then each body section's optional heading and
/// its paragraphs, in authored order (FR-003).
class ArticlePage extends StatelessWidget {
  const ArticlePage({
    required this.categoryId,
    required this.articleId,
    super.key,
  });

  /// Carried for navigation context only (the route is nested under its
  /// category); the article itself is resolved by [articleId] alone.
  final String categoryId;
  final String articleId;

  @override
  Widget build(BuildContext context) {
    // Resolved here, not inside `create`: the content language follows the
    // active app locale, which `create` must not subscribe to.
    final languageCode = Localizations.localeOf(context).languageCode;
    return BlocProvider(
      create: (_) => getIt<ArticleCubit>()..load(articleId, languageCode),
      child: _ArticleView(articleId: articleId),
    );
  }
}

class _ArticleView extends StatelessWidget {
  const _ArticleView({required this.articleId});

  final String articleId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<ArticleCubit, ArticleState>(
      builder: (context, state) {
        final article = state.article;
        return EducationPageScaffold(
          title: l10n.finEduTitle,
          body: switch (state.status) {
            ArticleStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            ArticleStatus.failure => EducationLoadErrorView(
              onRetry: () => context.read<ArticleCubit>().load(
                articleId,
                Localizations.localeOf(context).languageCode,
              ),
            ),
            ArticleStatus.success when article != null => _ArticleBody(
              article: article,
            ),
            ArticleStatus.success => const SizedBox.shrink(),
          },
        );
      },
    );
  }
}

class _ArticleBody extends StatelessWidget {
  const _ArticleBody({required this.article});

  final EducationArticle article;

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return SelectionArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          Text(article.title, style: AppTypography.headline),
          const SizedBox(height: AppSpacing.xs),
          Text(
            article.shortDescription,
            style: AppTypography.body.copyWith(color: onSurfaceVariant),
          ),
          for (final section in article.bodySections) ...[
            const SizedBox(height: AppSpacing.lg),
            if (section.heading case final heading?) ...[
              Text(heading, style: AppTypography.title),
              const SizedBox(height: AppSpacing.sm),
            ],
            for (final paragraph in section.paragraphs)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  paragraph,
                  style: AppTypography.body.copyWith(height: 1.6),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
