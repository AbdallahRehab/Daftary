import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../domain/entities/onboarding_topic.dart';

/// One onboarding screen's display content — title, description, and an
/// icon styled via `core/design_system` tokens at the call site (no
/// hardcoded colors here). Presentation layer only, since it needs
/// [AppLocalizations]/[BuildContext] (data-model.md).
class OnboardingContent {
  const OnboardingContent({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

/// Looks up the display content for [topic] from the ambient
/// [AppLocalizations], in the exact declaration order of
/// [OnboardingTopic.values] (FR-002).
OnboardingContent onboardingContentFor(
  BuildContext context,
  OnboardingTopic topic,
) {
  final l10n = AppLocalizations.of(context)!;
  return switch (topic) {
    OnboardingTopic.understandingMoney => OnboardingContent(
      title: l10n.onboardingUnderstandingMoneyTitle,
      description: l10n.onboardingUnderstandingMoneyDescription,
      icon: Icons.insights_outlined,
    ),
    OnboardingTopic.moneyBetweenPeople => OnboardingContent(
      title: l10n.onboardingMoneyBetweenPeopleTitle,
      description: l10n.onboardingMoneyBetweenPeopleDescription,
      icon: Icons.people_outline,
    ),
    OnboardingTopic.socialOccasions => OnboardingContent(
      title: l10n.onboardingSocialOccasionsTitle,
      description: l10n.onboardingSocialOccasionsDescription,
      icon: Icons.celebration_outlined,
    ),
    OnboardingTopic.scanningRecords => OnboardingContent(
      title: l10n.onboardingScanningRecordsTitle,
      description: l10n.onboardingScanningRecordsDescription,
      icon: Icons.history_outlined,
    ),
    OnboardingTopic.incomeExpense => OnboardingContent(
      title: l10n.onboardingIncomeExpenseTitle,
      description: l10n.onboardingIncomeExpenseDescription,
      icon: Icons.account_balance_wallet_outlined,
    ),
  };
}
