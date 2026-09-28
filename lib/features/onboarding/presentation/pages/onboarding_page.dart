import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/tokens.dart';
import '../../domain/entities/onboarding_topic.dart';
import '../cubit/onboarding_cubit.dart';
import '../onboarding_content.dart';
import '../widgets/onboarding_controls.dart';
import '../widgets/onboarding_progress_indicator.dart';
import '../widgets/onboarding_screen_view.dart';

/// The 5-screen onboarding sequence (FR-002), a `PageView.builder` over
/// [OnboardingTopic.values] (research.md Decision 4). The current step
/// index is held as local widget state via [PageController]/
/// `onPageChanged` (research.md Decision 5 — not [OnboardingCubit] state).
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => OnboardingPageState();
}

class OnboardingPageState extends State<OnboardingPage> {
  final PageController pageController = PageController();
  int currentStep = 0;

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void goToStep(int index) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      pageController.jumpToPage(index);
    } else {
      pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> completeOnboarding() async {
    await context.read<OnboardingCubit>().completeOnboarding();
    if (mounted) context.go('/');
  }

  Future<void> skipOnboarding() async {
    await context.read<OnboardingCubit>().skipOnboarding();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // Capped so tablets and landscape screens get a readable column
        // (and reachable controls) instead of text spanning the display.
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxReadingWidth,
            ),
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: pageController,
                    itemCount: OnboardingTopic.values.length,
                    onPageChanged: (index) =>
                        setState(() => currentStep = index),
                    // The copy is resolved in each page's own `Builder`, so
                    // that element depends on the localizations and a live
                    // language switch re-renders the visible page. Resolved
                    // from the item builder's context, the pages kept the
                    // old language until they were rebuilt for another
                    // reason.
                    itemBuilder: (context, index) => Builder(
                      builder: (context) => OnboardingScreenView(
                        content: onboardingContentFor(
                          context,
                          OnboardingTopic.values[index],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: OnboardingProgressIndicator(
                    currentStep: currentStep,
                    totalSteps: OnboardingTopic.values.length,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: OnboardingControls(
                    isFirstStep: currentStep == 0,
                    isLastStep:
                        currentStep == OnboardingTopic.values.length - 1,
                    onNext: () {
                      if (currentStep == OnboardingTopic.values.length - 1) {
                        completeOnboarding();
                      } else {
                        goToStep(currentStep + 1);
                      }
                    },
                    onBack: () => goToStep(currentStep - 1),
                    onSkip: skipOnboarding,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
