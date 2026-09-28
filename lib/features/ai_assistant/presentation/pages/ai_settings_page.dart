import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/date/app_date_formatter.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_confirm_dialog.dart';
import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../cubit/ai_settings_cubit.dart';
import '../cubit/ai_settings_state.dart';
import '../widgets/consent_disclosure_sheet.dart';

/// AI assistant setup (014 User Story 1): provider preset chips plus a
/// custom-entry fallback (research.md Decision 7), a masked API key field,
/// the consent disclosure gating enable, and — once enabled — change-key
/// and turn-off actions. Opens in the disabled/setup state on a fresh
/// install (FR-001).
class AISettingsPage extends StatelessWidget {
  const AISettingsPage({super.key});

  static const String location = '/ai-assistant/settings';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AISettingsCubit>()..load(),
      child: const AISettingsView(),
    );
  }
}

/// The page's content, reading the nearest [AISettingsCubit] — split from
/// [AISettingsPage] so tests can provide a cubit of their own.
class AISettingsView extends StatefulWidget {
  const AISettingsView({super.key});

  @override
  State<AISettingsView> createState() => _AISettingsViewState();
}

class _AISettingsViewState extends State<AISettingsView> {
  // The key lives only in this controller and the cubit's private draft.
  // It is cleared after every save/cancel, and the stored key is never
  // read back into it — once saved, it is never redisplayed (FR-004).
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _modelController = TextEditingController();

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _resetFields(AISettingsState state) {
    _apiKeyController.clear();
    _baseUrlController.text = state.customBaseUrl;
    _modelController.text = state.customModel;
  }

  Future<void> _askForConsent(BuildContext context, AISettingsState _) async {
    final cubit = context.read<AISettingsCubit>();
    final accepted = await showConsentDisclosureSheet(
      context,
      providerName: _providerLabel(context, cubit.draftProviderId ?? ''),
    );
    if (accepted) {
      await cubit.acceptConsent();
    } else {
      cubit.declineConsent();
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmDisable(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<AISettingsCubit>();
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.aiSettingsDisableConfirmTitle,
      message: l10n.aiSettingsDisableConfirmMessage,
      confirmLabel: l10n.aiSettingsDisableConfirmAction,
      isDestructive: true,
    );
    if (confirmed) await cubit.disable();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      appBar: AppTopBar(title: Text(l10n.aiSettingsTitle)),
      body: MultiBlocListener(
        listeners: [
          // FR-003: a validated provider + key only ever leads to the
          // disclosure; enabling happens only if it is accepted.
          BlocListener<AISettingsCubit, AISettingsState>(
            listenWhen: (previous, current) =>
                !previous.isAwaitingConsent && current.isAwaitingConsent,
            listener: _askForConsent,
          ),
          BlocListener<AISettingsCubit, AISettingsState>(
            listenWhen: (previous, current) =>
                previous.isEditingCredentials != current.isEditingCredentials,
            listener: (_, state) => _resetFields(state),
          ),
          BlocListener<AISettingsCubit, AISettingsState>(
            listenWhen: (_, current) => current.outcome != null,
            listener: (context, state) {
              final l10n = AppLocalizations.of(context)!;
              _resetFields(state);
              _showSnackBar(context, switch (state.outcome!) {
                AISettingsOutcome.enabled => l10n.aiSettingsEnabledMessage,
                AISettingsOutcome.credentialsUpdated =>
                  l10n.aiSettingsCredentialsUpdatedMessage,
                AISettingsOutcome.disabled => l10n.aiSettingsDisabledMessage,
              });
            },
          ),
          BlocListener<AISettingsCubit, AISettingsState>(
            listenWhen: (previous, current) =>
                current.status == AISettingsStatus.ready &&
                current.failure != null &&
                current.failure != previous.failure,
            listener: (context, _) => _showSnackBar(
              context,
              AppLocalizations.of(context)!.aiSettingsSaveFailed,
            ),
          ),
        ],
        child: BlocBuilder<AISettingsCubit, AISettingsState>(
          builder: (context, state) {
            final cubit = context.read<AISettingsCubit>();
            switch (state.status) {
              case AISettingsStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case AISettingsStatus.loadFailure:
                return AppEmptyView(
                  icon: Icons.error_outline,
                  title: l10n.commonError,
                  message: l10n.aiSettingsLoadFailed,
                  actionLabel: l10n.commonRetry,
                  onAction: cubit.load,
                );
              case AISettingsStatus.ready:
              case AISettingsStatus.awaitingConsent:
              case AISettingsStatus.submitting:
                break;
            }
            return ListView(
              padding:
                  const EdgeInsets.all(AppSpacing.md) +
                  AppGlassInsets.of(context),
              children: [
                if (state.isEnabled)
                  _EnabledSummary(state: state)
                else
                  _DisabledIntro(),
                const SizedBox(height: AppSpacing.lg),
                if (state.showsCredentialForm)
                  _CredentialForm(
                    state: state,
                    apiKeyController: _apiKeyController,
                    baseUrlController: _baseUrlController,
                    modelController: _modelController,
                  )
                else
                  AppSecondaryButton(
                    label: l10n.aiSettingsChangeCredentialsAction,
                    onPressed: state.isSubmitting
                        ? null
                        : cubit.startEditingCredentials,
                  ),
                if (state.isEnabled) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _DisableButton(
                    onPressed: state.isSubmitting
                        ? null
                        : () => _confirmDisable(context),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DisabledIntro extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.aiSettingsIntroTitle,
                    style: AppTypography.title,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.aiSettingsIntroMessage, style: AppTypography.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EnabledSummary extends StatelessWidget {
  const _EnabledSummary({required this.state});

  final AISettingsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = state.settings!;
    final consent = settings.consentAcceptedAt;
    final muted = AppTypography.bodyMuted.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final dateFormatter = AppDateFormatter(
      locale: Localizations.localeOf(context).languageCode,
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: context.financeColors.positive,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.aiSettingsEnabledTitle,
                    style: AppTypography.title,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.aiSettingsEnabledProvider(
              _providerLabel(context, settings.providerId!),
            ),
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.xs),
          // Only the fact that a key exists — the value is never read back.
          Text(l10n.aiSettingsApiKeySaved, style: AppTypography.body),
          if (consent != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.aiSettingsConsentAcceptedOn(dateFormatter.format(consent)),
              style: muted,
            ),
          ],
        ],
      ),
    );
  }
}

class _CredentialForm extends StatelessWidget {
  const _CredentialForm({
    required this.state,
    required this.apiKeyController,
    required this.baseUrlController,
    required this.modelController,
  });

  final AISettingsState state;
  final TextEditingController apiKeyController;
  final TextEditingController baseUrlController;
  final TextEditingController modelController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<AISettingsCubit>();
    final busy = state.isSubmitting || state.isAwaitingConsent;
    final muted = AppTypography.bodyMuted.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final errorStyle = AppTypography.bodyMuted.copyWith(
      color: Theme.of(context).colorScheme.error,
    );
    final providerError = switch (state.providerError) {
      AIProviderInputError.required => l10n.aiSettingsProviderRequired,
      _ => null,
    };
    final apiKeyError = switch (state.apiKeyError) {
      AIApiKeyInputError.required => l10n.aiSettingsApiKeyRequired,
      AIApiKeyInputError.malformed => l10n.aiSettingsApiKeyMalformed,
      null => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.isEditingCredentials) ...[
          Semantics(
            header: true,
            child: Text(
              l10n.aiSettingsChangeCredentialsTitle,
              style: AppTypography.title,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.aiSettingsChangeCredentialsMessage, style: muted),
          const SizedBox(height: AppSpacing.md),
        ],
        Semantics(
          header: true,
          child: Text(
            l10n.aiSettingsProviderSectionTitle,
            style: AppTypography.label,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final preset in state.presets)
              ChoiceChip(
                label: Text(preset.displayName),
                selected:
                    !state.isCustomSelected &&
                    state.selectedPresetId == preset.id,
                onSelected: busy
                    ? null
                    : (_) => cubit.presetSelected(preset.id),
              ),
            ChoiceChip(
              label: Text(l10n.aiSettingsProviderCustom),
              selected: state.isCustomSelected,
              onSelected: busy ? null : (_) => cubit.customProviderSelected(),
            ),
          ],
        ),
        if (providerError != null) ...[
          const SizedBox(height: AppSpacing.xs),
          // Announced when it appears; the text itself says what is wrong,
          // so the error color is never the only signal.
          Semantics(
            liveRegion: true,
            child: Text(providerError, style: errorStyle),
          ),
        ],
        if (state.isCustomSelected) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.aiSettingsCustomProviderHint, style: muted),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: l10n.aiSettingsCustomBaseUrlLabel,
            controller: baseUrlController,
            onChanged: cubit.customBaseUrlChanged,
            keyboardType: TextInputType.url,
            // URLs and model ids read left-to-right in both locales.
            textDirection: TextDirection.ltr,
            enabled: !busy,
            errorText:
                state.providerError == AIProviderInputError.invalidBaseUrl
                ? l10n.aiSettingsCustomBaseUrlInvalid
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: l10n.aiSettingsCustomModelLabel,
            controller: modelController,
            onChanged: cubit.customModelChanged,
            textDirection: TextDirection.ltr,
            enabled: !busy,
            errorText: state.providerError == AIProviderInputError.modelRequired
                ? l10n.aiSettingsCustomModelRequired
                : null,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Semantics(
          header: true,
          child: Text(
            l10n.aiSettingsApiKeySectionTitle,
            style: AppTypography.label,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: l10n.aiSettingsApiKeyLabel,
          controller: apiKeyController,
          onChanged: cubit.apiKeyChanged,
          obscureText: true,
          keyboardType: TextInputType.visiblePassword,
          textDirection: TextDirection.ltr,
          enabled: !busy,
          errorText: apiKeyError,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.aiSettingsApiKeyNote, style: muted),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: state.isEditingCredentials
              ? l10n.aiSettingsSaveCredentialsAction
              : l10n.aiSettingsContinueAction,
          // Spins only while a save is really in flight; while the
          // disclosure is open it is merely disabled.
          isLoading: state.isSubmitting,
          onPressed: state.isAwaitingConsent
              ? null
              : state.isEditingCredentials
              ? cubit.submitCredentialsUpdate
              : cubit.requestEnable,
        ),
        if (state.isEditingCredentials) ...[
          const SizedBox(height: AppSpacing.sm),
          AppSecondaryButton(
            label: l10n.aiSettingsCancelAction,
            onPressed: busy ? null : cubit.cancelEditingCredentials,
          ),
        ],
      ],
    );
  }
}

class _DisableButton extends StatelessWidget {
  const _DisableButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final error = Theme.of(context).colorScheme.error;
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.power_settings_new),
        label: Text(l10n.aiSettingsDisableAction),
        style: OutlinedButton.styleFrom(
          foregroundColor: error,
          side: BorderSide(color: error),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
    );
  }
}

/// The user-facing name of [providerId]: a preset's brand name, or the
/// localized "your custom provider (host)". Never anything secret —
/// provider ids never contain the key.
String _providerLabel(BuildContext context, String providerId) {
  final l10n = AppLocalizations.of(context)!;
  final described = context.read<AISettingsCubit>().describeProvider(
    providerId,
  );
  return described.isCustom
      ? l10n.aiSettingsCustomProviderName(described.name)
      : described.name;
}
