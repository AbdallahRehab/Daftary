import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/design_system/glass/app_modal_sheet.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/failure_message.dart';
import '../../domain/email_mask.dart';
import '../cubit/email_link_cubit.dart';
import '../cubit/email_link_state.dart';

/// 021 T080: the email and one-time-code form, for linking an email or
/// signing in to an existing account. The address is shown back masked.
class EmailLinkSheet extends StatefulWidget {
  const EmailLinkSheet({super.key});

  static const emailFieldKey = Key('email_link_email_field');
  static const codeFieldKey = Key('email_link_code_field');
  static const sendKey = Key('email_link_send');
  static const confirmKey = Key('email_link_confirm');

  @override
  State<EmailLinkSheet> createState() => _EmailLinkSheetState();
}

class _EmailLinkSheetState extends State<EmailLinkSheet> {
  final _email = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: BlocConsumer<EmailLinkCubit, EmailLinkState>(
          listenWhen: (previous, current) =>
              previous.step != current.step &&
              current.step == EmailLinkStep.success,
          listener: (context, state) {
            final message = state.mode == EmailLinkMode.link
                ? l10n.syncEmailLinkSuccess
                : l10n.syncEmailSignInSuccess;
            ScaffoldMessenger.maybeOf(
              context,
            )?.showSnackBar(SnackBar(content: Text(message)));
            Navigator.of(context).maybePop();
          },
          builder: (context, state) {
            final cubit = context.read<EmailLinkCubit>();
            final link = state.mode == EmailLinkMode.link;
            final error = state.step == EmailLinkStep.failure
                ? l10n.messageFor(state.failure)
                : null;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  link ? l10n.syncEmailLinkTitle : l10n.syncEmailSignInTitle,
                  style: AppTypography.title,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  link
                      ? l10n.syncEmailLinkMessage
                      : l10n.syncEmailSignInMessage,
                  style: AppTypography.bodyMuted.copyWith(color: muted),
                ),
                const SizedBox(height: AppSpacing.md),
                if (!state.codeSent) ...[
                  AppTextField(
                    key: EmailLinkSheet.emailFieldKey,
                    label: l10n.syncEmailFieldLabel,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    // An address reads left to right in both languages.
                    textDirection: TextDirection.ltr,
                    maxLength: 254,
                    errorText: error,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    key: EmailLinkSheet.sendKey,
                    label: l10n.syncEmailSendCode,
                    isLoading: state.step == EmailLinkStep.sending,
                    onPressed: () => cubit.requestCode(_email.text),
                  ),
                ] else ...[
                  Text(
                    l10n.syncEmailCodeSent(maskEmail(state.email)),
                    style: AppTypography.body,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    key: EmailLinkSheet.codeFieldKey,
                    label: l10n.syncEmailCodeFieldLabel,
                    controller: _code,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    textDirection: TextDirection.ltr,
                    maxLength: 10,
                    errorText: error,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    key: EmailLinkSheet.confirmKey,
                    label: l10n.syncEmailConfirm,
                    isLoading: state.step == EmailLinkStep.verifying,
                    onPressed: () => cubit.confirmCode(_code.text),
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

/// Opens the email sheet in [mode], with its own [EmailLinkCubit].
Future<void> showEmailLinkSheet(BuildContext context, EmailLinkMode mode) {
  return showAppModalSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider(
      create: (_) => getIt<EmailLinkCubit>()..start(mode),
      child: const EmailLinkSheet(),
    ),
  );
}
