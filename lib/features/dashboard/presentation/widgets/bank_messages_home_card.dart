import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../sms_import/domain/usecases/get_sms_capability.dart';
import '../../../sms_import/presentation/cubit/bank_messages_home_cubit.dart';
import '../../../sms_import/presentation/routes.dart';

/// Home's bank-messages card (023 T122/T129, ui-contract §2), two
/// variants:
///
/// - The count variant (T129, FR-050): rendered only while items wait for
///   review. It shows the count only ("3 bank transactions to review"),
///   never a merchant, an amount or message text, and opens the hub. No
///   tab badge.
/// - The FR-004 onboarding variant (below).
///
/// - Gated by [kBankMessageImportFeatureEnabled]: its cubit is created only
///   when the flag is on. The count variant shows on every platform, since
///   paste-only platforms hold pending items too (CHK036); the onboarding
///   variant also needs the runtime SMS capability. The dashboard cubit is
///   untouched.
/// - The onboarding variant is shown while the import is off and the card
///   was never dismissed.
///   "Set up" opens the enable flow (which explains before any prompt);
///   "Dismiss" is permanent.
/// - It never prompts and never shows message content (FR-002, FR-050).
class BankMessagesHomeCard extends StatefulWidget {
  const BankMessagesHomeCard({
    super.key,
    this.enabled = kBankMessageImportFeatureEnabled,
    this.capabilityAvailable,
    this.createCubit,
    this.onReturn,
  });

  /// The feature flag.
  final bool enabled;

  /// Whether the SMS inbox can be read here. Defaults to
  /// `GetSmsCapability` from DI, or `false` when it is not registered.
  final Future<bool> Function()? capabilityAvailable;

  /// Defaults to the DI cubit.
  final BankMessagesHomeCubit Function()? createCubit;

  /// Called after the enable flow pops, so Home can refresh.
  final VoidCallback? onReturn;

  @override
  State<BankMessagesHomeCard> createState() => _BankMessagesHomeCardState();
}

class _BankMessagesHomeCardState extends State<BankMessagesHomeCard> {
  BankMessagesHomeCubit? _cubit;

  /// Whether the SMS inbox can be read here; gates the onboarding variant.
  bool _available = false;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _resolve();
  }

  Future<void> _resolve() async {
    final available = await (widget.capabilityAvailable ?? _fromDi)();
    if (!mounted) return;
    final create =
        widget.createCubit ??
        (getIt.isRegistered<BankMessagesHomeCubit>()
            ? () => getIt<BankMessagesHomeCubit>()
            : null);
    if (create == null) return;
    setState(() {
      _available = available;
      _cubit = create()..open();
    });
  }

  static Future<bool> _fromDi() async {
    if (!getIt.isRegistered<GetSmsCapability>()) return false;
    return (await getIt<GetSmsCapability>()()).available;
  }

  @override
  void dispose() {
    _cubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    if (cubit == null) return const SizedBox.shrink();
    return BlocBuilder<BankMessagesHomeCubit, BankMessagesHomeState>(
      bloc: cubit,
      builder: (context, state) {
        final showOnboarding = _available && state.showOnboarding;
        if (!state.showCount && !showOnboarding) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.showCount)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: AppSpacing.lg),
                child: _CountCard(
                  count: state.pendingCount,
                  onOpen: () async {
                    await context.push(BankMessagesRoutes.hub);
                    widget.onReturn?.call();
                  },
                ),
              ),
            if (showOnboarding)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: AppSpacing.lg),
                child: _OnboardingCard(
                  dismissing: state.dismissing,
                  onSetUp: () async {
                    await context.push(BankMessagesRoutes.enable);
                    widget.onReturn?.call();
                  },
                  onDismiss: cubit.dismiss,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// "N bank transactions to review": a count only (FR-050); tap opens the
/// hub. One screen-reader button.
class _CountCard extends StatelessWidget {
  const _CountCard({required this.count, required this.onOpen});

  final int count;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = l10n.smsImportHomeCardCount(count);
    return Semantics(
      container: true,
      button: true,
      label: text,
      hint: l10n.smsImportHomeCardHint,
      excludeSemantics: true,
      child: AppCard(
        key: const ValueKey('bank_messages_home_count'),
        onTap: onOpen,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          child: Row(
            children: [
              Icon(Icons.sms_outlined, color: scheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(text, style: AppTypography.title)),
              // `chevron_right` matches the text direction.
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({
    required this.dismissing,
    required this.onSetUp,
    required this.onDismiss,
  });

  final bool dismissing;
  final VoidCallback onSetUp;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      key: const ValueKey('bank_messages_home_onboarding'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.sms_outlined, color: scheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.smsImportHomeOnboardingTitle,
                      style: AppTypography.title,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.smsImportHomeOnboardingText,
                      style: AppTypography.body,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.sm,
            children: [
              TextButton(
                key: const ValueKey('bank_messages_home_dismiss'),
                onPressed: dismissing ? null : onDismiss,
                child: Text(l10n.smsImportHomeOnboardingDismiss),
              ),
              FilledButton(
                key: const ValueKey('bank_messages_home_set_up'),
                onPressed: dismissing ? null : onSetUp,
                child: Text(l10n.smsImportHomeOnboardingSetUp),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
