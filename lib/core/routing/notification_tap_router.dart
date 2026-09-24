import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

import '../../features/insights_notifications/domain/entities/composed_notification.dart';
import '../../features/insights_notifications/domain/entities/notification_source_type.dart';
import '../../features/insights_notifications/domain/services/notification_scheduler.dart';
import '../../features/insights_notifications/domain/usecases/handle_notification_tap.dart';
import '../l10n/app_localizations.dart';

/// Key handed to `MaterialApp.router` so a tapped notification whose source
/// has since been deleted can say so without a widget context of its own.
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>(debugLabel: 'appScaffoldMessenger');

/// Route paths reserved by 010's and 011's own plans (`/budgets/:month`,
/// `/savings/:goalId`). Those features aren't implemented yet, so their
/// placeholder insight sources report nothing as existing and every tap
/// currently resolves to [SourceNoLongerExists] — these paths only become
/// reachable once 010/011 register them.
String budgetMonthPath(String month) => '/budgets/$month';
String savingsGoalPath(String goalId) => '/savings/$goalId';

/// Wires [NotificationScheduler]'s tap events — both warm taps and the tap
/// that cold-started the app — through [HandleNotificationTap] onto the
/// app's router (FR-014, T028/T034).
@lazySingleton
class NotificationTapRouter {
  NotificationTapRouter(this._scheduler, this._handleTap);

  final NotificationScheduler _scheduler;
  final HandleNotificationTap _handleTap;
  StreamSubscription<NotificationDeepLinkTarget>? _subscription;

  /// Starts listening; idempotent. [router] is the app's [GoRouter].
  Future<void> start(GoRouter router) async {
    if (_subscription != null) return;
    _subscription = _scheduler.taps.listen((target) => _open(router, target));
    final launch = await _scheduler.launchTarget();
    if (launch != null) await _open(router, launch);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _open(GoRouter router, NotificationDeepLinkTarget target) async {
    final destination = await _handleTap(target);
    switch (destination) {
      case BudgetCategoryDestination(:final month):
        router.go(budgetMonthPath(month));
      case SavingsGoalDestination(:final goalId):
        router.go(savingsGoalPath(goalId));
      case SourceNoLongerExists(:final sourceType):
        _showNoLongerExists(sourceType);
    }
  }

  void _showNoLongerExists(NotificationSourceType sourceType) {
    final messenger = appScaffoldMessengerKey.currentState;
    final context = appScaffoldMessengerKey.currentContext;
    if (messenger == null || context == null) return;
    final l10n = AppLocalizations.of(context)!;
    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (sourceType) {
          NotificationSourceType.budgetCategory =>
            l10n.notificationBudgetNoLongerExists,
          NotificationSourceType.savingsGoal =>
            l10n.notificationSavingsGoalNoLongerExists,
        }),
      ),
    );
  }
}
