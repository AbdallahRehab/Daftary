import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../currency/presentation/pages/currency_settings_page.dart';
import '../../../insights_notifications/presentation/pages/notification_settings_page.dart';
import '../../domain/entities/app_language.dart';
import '../../domain/entities/app_theme_mode.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';

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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: BlocConsumer<SettingsCubit, SettingsState>(
        listenWhen: (previous, current) =>
            (!previous.isPersistFailing && current.isPersistFailing) ||
            (!previous.isThemeModePersistFailing &&
                current.isThemeModePersistFailing),
        listener: (context, state) {
          final message = state.isThemeModePersistFailing
              ? l10n.themeSaveFailed
              : l10n.settingsSaveFailed;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        },
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
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
