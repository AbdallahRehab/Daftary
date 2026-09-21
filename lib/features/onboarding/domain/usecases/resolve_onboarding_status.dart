import 'dart:developer' as developer;

import 'package:injectable/injectable.dart';

import '../../../people/domain/repositories/people_repository.dart';
import '../../../transactions/domain/repositories/transactions_repository.dart';
import '../repositories/onboarding_repository.dart';

/// Domain-layer result of [ResolveOnboardingStatus.call] — distinct from
/// the presentation-layer `OnboardingLoadStatus`, which also has a
/// `resolving` value with no equivalent here (this always resolves
/// synchronously against already-awaited repository calls).
enum OnboardingGateStatus { showOnboarding, mainApp }

/// Coordinates [OnboardingRepository], [PeopleRepository], and
/// [TransactionsRepository] to answer one question at startup: should this
/// launch show onboarding, or go straight to the main app?
///
/// FR-001/FR-009/FR-010a decision logic:
/// 1. If onboarding is already marked complete -> mainApp.
/// 2. Else, if any Person or MoneyTransaction record already exists
///    (active or archived people; including soft-deleted transactions) ->
///    auto-complete onboarding, then -> mainApp.
/// 3. Else -> showOnboarding (nothing is persisted yet).
///
/// On any Failure from step 1 or 2, fails open to mainApp rather than
/// blocking startup (research.md Decision 7) — never returns a Failure
/// itself; the caller (`OnboardingCubit`) always gets a definite status.
@injectable
class ResolveOnboardingStatus {
  ResolveOnboardingStatus(
    this._onboardingRepository,
    this._peopleRepository,
    this._transactionsRepository,
  );

  final OnboardingRepository _onboardingRepository;
  final PeopleRepository _peopleRepository;
  final TransactionsRepository _transactionsRepository;

  Future<OnboardingGateStatus> call() async {
    final completeResult = await _onboardingRepository.isOnboardingComplete();
    final alreadyComplete = completeResult.match((failure) {
      developer.log(
        'ResolveOnboardingStatus: isOnboardingComplete failed, failing '
        'open to mainApp: ${failure.message}',
        name: 'onboarding',
      );
      return null;
    }, (isComplete) => isComplete);

    if (alreadyComplete == null) {
      return OnboardingGateStatus.mainApp;
    }
    if (alreadyComplete) {
      return OnboardingGateStatus.mainApp;
    }

    final hasPersonResult = await _peopleRepository.hasAnyPerson();
    final hasTransactionResult = await _transactionsRepository
        .hasAnyTransaction();

    final hasPerson = hasPersonResult.match((failure) {
      developer.log(
        'ResolveOnboardingStatus: hasAnyPerson failed, failing open to '
        'mainApp: ${failure.message}',
        name: 'onboarding',
      );
      return null;
    }, (value) => value);
    final hasTransaction = hasTransactionResult.match((failure) {
      developer.log(
        'ResolveOnboardingStatus: hasAnyTransaction failed, failing open '
        'to mainApp: ${failure.message}',
        name: 'onboarding',
      );
      return null;
    }, (value) => value);

    if (hasPerson == null || hasTransaction == null) {
      return OnboardingGateStatus.mainApp;
    }

    if (hasPerson || hasTransaction) {
      await _onboardingRepository.completeOnboarding();
      return OnboardingGateStatus.mainApp;
    }

    return OnboardingGateStatus.showOnboarding;
  }
}
