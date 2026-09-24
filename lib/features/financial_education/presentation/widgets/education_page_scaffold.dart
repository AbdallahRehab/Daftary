import 'package:flutter/material.dart';

import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'persistent_disclaimer_banner.dart';

/// The shared frame of every content screen in this feature: an app bar,
/// the [PersistentDisclaimerBanner] pinned above the body (outside any
/// scrollable, so it can never scroll out of view or depend on the body's
/// load state), and the screen's own [body] below it.
class EducationPageScaffold extends StatelessWidget {
  const EducationPageScaffold({
    required this.title,
    required this.body,
    super.key,
  });

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: PersistentDisclaimerBanner(),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

/// The feature's load-failure state: explains what failed and offers a
/// retry, rather than a bare error string (constitution: complete UI
/// states).
class EducationLoadErrorView extends StatelessWidget {
  const EducationLoadErrorView({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppEmptyView(
      icon: Icons.error_outline,
      title: l10n.finEduLoadErrorTitle,
      message: l10n.finEduLoadErrorMessage,
      actionLabel: l10n.finEduRetry,
      onAction: onRetry,
    );
  }
}
