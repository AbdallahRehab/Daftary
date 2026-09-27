import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../cloud_sync/presentation/pages/sync_settings_page.dart';
import '../../../cloud_sync/presentation/widgets/sync_status_subtitle.dart';
import '../../../currency/presentation/pages/currency_settings_page.dart';
import '../../../insights_notifications/presentation/pages/notification_settings_page.dart';
import '../../domain/entities/app_language.dart';
import '../../domain/entities/app_theme_mode.dart';
import '../../domain/entities/glass_appearance.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';
import '../widgets/glass_level_selector.dart';
import '../widgets/glass_preview.dart';

/// A language picker, structured as a `ListView` of sections so future
/// settings entries can be appended below the language switch without
/// rework (spec Assumptions). `SettingsCubit` is root-scoped and already
/// provided above `MaterialApp.router` (main.dart), so this page reads it
/// directly rather than providing its own instance.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      appBar: AppTopBar(title: Text(l10n.settingsTitle)),
      body: BlocConsumer<SettingsCubit, SettingsState>(
        listenWhen: (previous, current) =>
            (!previous.isPersistFailing && current.isPersistFailing) ||
            (!previous.isThemeModePersistFailing &&
                current.isThemeModePersistFailing) ||
            (!previous.isGlassPersistFailing && current.isGlassPersistFailing),
        listener: (context, state) {
          // Priority when several fail at once: glass, then theme, then
          // language.
          final message = state.isGlassPersistFailing
              ? l10n.glassSaveFailed
              : state.isThemeModePersistFailing
              ? l10n.themeSaveFailed
              : l10n.settingsSaveFailed;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        },
        // Only the language and theme groups read the state here; the
        // Appearance group selects its own slice, so glass changes rebuild
        // just that group.
        buildWhen: (previous, current) =>
            previous.language != current.language ||
            previous.themeMode != current.themeMode,
        builder: (context, state) {
          return ListView(
            padding:
                const EdgeInsets.all(AppSpacing.md) +
                AppGlassInsets.of(context),
            children: [
              _SettingsSection(
                icon: Icons.translate_outlined,
                title: l10n.languageSectionTitle,
                child: RadioGroup<AppLanguage>(
                  groupValue: state.language,
                  onChanged: (language) => language == null
                      ? null
                      : context.read<SettingsCubit>().changeLanguage(language),
                  child: Column(
                    children: [
                      RadioListTile<AppLanguage>(
                        title: Text(l10n.languageEnglish),
                        value: AppLanguage.english,
                      ),
                      const Divider(height: 1, indent: AppSpacing.md),
                      RadioListTile<AppLanguage>(
                        title: Text(l10n.languageArabic),
                        value: AppLanguage.arabic,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SettingsSection(
                icon: Icons.dark_mode_outlined,
                title: l10n.themeSectionTitle,
                child: RadioGroup<AppThemeMode>(
                  groupValue: state.themeMode,
                  onChanged: (mode) => mode == null
                      ? null
                      : context.read<SettingsCubit>().changeThemeMode(mode),
                  child: Column(
                    children: [
                      RadioListTile<AppThemeMode>(
                        title: Text(l10n.themeLight),
                        value: AppThemeMode.light,
                      ),
                      const Divider(height: 1, indent: AppSpacing.md),
                      RadioListTile<AppThemeMode>(
                        title: Text(l10n.themeDark),
                        value: AppThemeMode.dark,
                      ),
                      const Divider(height: 1, indent: AppSpacing.md),
                      RadioListTile<AppThemeMode>(
                        title: Text(l10n.themeSystemDefault),
                        value: AppThemeMode.system,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _AppearanceSection(),
              const SizedBox(height: AppSpacing.lg),
              // Currency entry point (018): primary currency + the manual
              // exchange rates, on their own screens.
              _SettingsSection(
                icon: Icons.payments_outlined,
                title: l10n.currencySettingsTitle,
                child: ListTile(
                  key: const Key('settings_currency_entry'),
                  leading: const Icon(Icons.currency_exchange_outlined),
                  title: Text(l10n.currencySettingsTitle),
                  subtitle: Text(l10n.currencySettingsEntrySubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(CurrencyRoutes.settings),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Cloud backup and sync entry point (021 US6): its own
              // screen, subtitled with the live sync status.
              _SettingsSection(
                icon: Icons.cloud_outlined,
                title: l10n.syncSettingsTitle,
                child: ListTile(
                  key: const Key('settings_sync_entry'),
                  leading: const Icon(Icons.cloud_sync_outlined),
                  title: Text(l10n.syncSettingsTitle),
                  subtitle: const SyncStatusSubtitle(),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(SyncSettingsRoutes.settings),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Notifications entry point (017): its own screen, since it
              // holds a master switch, two categories and quiet hours.
              _SettingsSection(
                icon: Icons.notifications_outlined,
                title: l10n.notificationSettingsTitle,
                child: ListTile(
                  key: const Key('settings_notifications_entry'),
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: Text(l10n.notificationSettingsTitle),
                  subtitle: Text(l10n.notificationSettingsEntrySubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      context.push(NotificationSettingsRoutes.settings),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Financial Education entry point (016, research.md Decision
              // 5): a secondary, non-daily feature, so a Settings row rather
              // than a bottom-nav tab.
              _SettingsSection(
                icon: Icons.school_outlined,
                title: l10n.finEduSettingsSectionTitle,
                child: ListTile(
                  key: const Key('settings_financial_education_entry'),
                  leading: const Icon(Icons.menu_book_outlined),
                  title: Text(l10n.finEduTitle),
                  subtitle: Text(l10n.finEduSettingsEntrySubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/financial-education'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The Appearance group (020, research Decision 14): the Liquid Glass switch
/// and, only while glass is ON, the transparency and intensity pickers and a
/// live preview. It selects just [GlassAppearance], so it alone rebuilds when
/// the glass preference changes.
class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<SettingsCubit>();
    return BlocSelector<SettingsCubit, SettingsState, GlassAppearance>(
      selector: (state) => state.glassAppearance,
      builder: (context, glass) {
        return _SettingsSection(
          icon: Icons.blur_on_outlined,
          title: l10n.appearanceSectionTitle,
          child: Column(
            children: [
              SwitchListTile(
                key: const Key('settings_liquid_glass_switch'),
                title: Text(l10n.liquidGlassTitle),
                subtitle: Text(l10n.liquidGlassSubtitle),
                value: glass.enabled,
                onChanged: cubit.setGlassEnabled,
              ),
              AnimatedSize(
                duration: kThemeAnimationDuration,
                alignment: AlignmentDirectional.topCenter,
                child: glass.enabled
                    ? Column(
                        children: [
                          const Divider(height: 1, indent: AppSpacing.md),
                          GlassLevelSelector(
                            key: const Key('settings_glass_transparency'),
                            title: l10n.glassTransparencyTitle,
                            value: glass.transparency,
                            onChanged: cubit.setGlassTransparency,
                          ),
                          const Divider(height: 1, indent: AppSpacing.md),
                          GlassLevelSelector(
                            key: const Key('settings_glass_intensity'),
                            title: l10n.glassIntensityTitle,
                            value: glass.intensity,
                            onChanged: cubit.setGlassIntensity,
                          ),
                          const Padding(
                            padding: EdgeInsets.all(AppSpacing.md),
                            child: GlassPreview(
                              key: Key('settings_glass_preview'),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A titled, icon-led group of related settings controls, sharing one
/// [AppCard] surface — the same grouping language used for every other
/// multi-item surface in the app (Overview, the duplicate-match picker).
class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            bottom: AppSpacing.xs,
            left: AppSpacing.xs,
            right: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: onSurfaceVariant),
              const SizedBox(width: AppSpacing.xs),
              Text(
                title,
                style: AppTypography.label.copyWith(color: onSurfaceVariant),
              ),
            ],
          ),
        ),
        AppCard(padding: EdgeInsets.zero, child: child),
      ],
    );
  }
}
