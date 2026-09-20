import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/app_language.dart';
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
            !previous.isPersistFailing && current.isPersistFailing,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l10n.settingsSaveFailed)));
        },
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: Text(
                  l10n.languageSectionTitle,
                  style: AppTypography.label,
                ),
              ),
              RadioGroup<AppLanguage>(
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
                    RadioListTile<AppLanguage>(
                      title: Text(l10n.languageArabic),
                      value: AppLanguage.arabic,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
