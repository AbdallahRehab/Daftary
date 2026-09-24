import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../cubit/content_library_cubit.dart';
import '../cubit/content_library_state.dart';
import '../widgets/article_list_tile.dart';
import '../widgets/education_page_scaffold.dart';

/// Route paths for this feature, kept beside the pages that navigate them.
abstract final class FinancialEducationRoutes {
  static const String home = '/financial-education';
  static const String compoundGrowth =
      '/financial-education/calculators/compound-growth';
  static const String doublingTime =
      '/financial-education/calculators/doubling-time';
  static const String savingsRate =
      '/financial-education/calculators/savings-rate';

  static String category(String categoryId) => '$home/$categoryId';
  static String article(String categoryId, String articleId) =>
      '$home/$categoryId/$articleId';
}

/// The Financial Education entry screen: the bundled content categories
/// (FR-001) followed by the three illustrative calculators.
class ContentLibraryHomePage extends StatelessWidget {
  const ContentLibraryHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Resolved here, not inside `create`: the content language follows the
    // active app locale, which `create` must not subscribe to.
    final languageCode = Localizations.localeOf(context).languageCode;
    return BlocProvider(
      create: (_) => getIt<ContentLibraryCubit>()..load(languageCode),
      child: const _ContentLibraryHomeView(),
    );
  }
}

class _ContentLibraryHomeView extends StatelessWidget {
  const _ContentLibraryHomeView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EducationPageScaffold(
      title: l10n.finEduTitle,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _SectionHeader(title: l10n.finEduTopicsSectionTitle),
          BlocBuilder<ContentLibraryCubit, ContentLibraryState>(
            builder: (context, state) => switch (state.status) {
              ContentLibraryStatus.loading => const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              ),
              ContentLibraryStatus.failure => SizedBox(
                height: 320,
                child: EducationLoadErrorView(
                  onRetry: () => context.read<ContentLibraryCubit>().load(
                    Localizations.localeOf(context).languageCode,
                  ),
                ),
              ),
              ContentLibraryStatus.success => Column(
                children: [
                  for (final category in state.categories)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ArticleListTile(
                        key: ValueKey('fin_edu_category_${category.id}'),
                        icon: _categoryIcon(category.id),
                        title: category.title,
                        shortDescription: category.shortDescription,
                        onTap: () => context.push(
                          FinancialEducationRoutes.category(category.id),
                        ),
                      ),
                    ),
                ],
              ),
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionHeader(title: l10n.finEduToolsSectionTitle),
          ..._calculatorTiles(context, l10n),
        ],
      ),
    );
  }

  List<Widget> _calculatorTiles(BuildContext context, AppLocalizations l10n) {
    final tiles = [
      (
        Icons.trending_up,
        l10n.finEduCompoundGrowthTileTitle,
        l10n.finEduCompoundGrowthTileSubtitle,
        FinancialEducationRoutes.compoundGrowth,
      ),
      (
        Icons.hourglass_bottom_outlined,
        l10n.finEduDoublingTimeTileTitle,
        l10n.finEduDoublingTimeTileSubtitle,
        FinancialEducationRoutes.doublingTime,
      ),
      (
        Icons.percent,
        l10n.finEduSavingsRateTileTitle,
        l10n.finEduSavingsRateTileSubtitle,
        FinancialEducationRoutes.savingsRate,
      ),
    ];
    return [
      for (final (icon, title, subtitle, route) in tiles)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ArticleListTile(
            key: ValueKey('fin_edu_calculator_$route'),
            icon: icon,
            title: title,
            shortDescription: subtitle,
            onTap: () => context.push(route),
          ),
        ),
    ];
  }

  static IconData _categoryIcon(String categoryId) => switch (categoryId) {
    'budgeting_basics' => Icons.account_balance_wallet_outlined,
    'saving_strategies' => Icons.savings_outlined,
    'understanding_investment_concepts' => Icons.show_chart,
    _ => Icons.menu_book_outlined,
  };
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.sm,
        left: AppSpacing.xs,
        right: AppSpacing.xs,
      ),
      child: Text(
        title,
        style: AppTypography.label.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
