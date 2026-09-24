import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_lifecycle_observer.dart';

/// The single, app-wide lock interception point (015 research.md
/// Decision 5), installed as `MaterialApp.router`'s `builder` so it sits
/// above the router's `Navigator` — every current and future route is gated
/// without any per-screen guard.
///
/// While [AppLifecycleObserver.isLocked] is `true`, the routed [child] stays
/// mounted (navigation position and form state survive an unlock) but is
/// offstage: not painted, not hit-testable, not in the semantics tree, and
/// its tickers are paused. The lock screen from [lockScreenBuilder] is shown
/// in its own `Navigator`, so it can use dialogs, overlays and text fields.
///
/// **System back while locked.** Android's back button/gesture is delivered
/// to `WidgetsBindingObserver`s in registration order, and would normally
/// reach the router's back-button dispatcher, which pops the (hidden)
/// routed page underneath the lock screen. The gate registers its own
/// observer in `initState` — before the `Router` below it registers — and
/// while locked it claims every back event: it pops the lock screen's own
/// `Navigator` if something is pushed on it (e.g. Forgot PIN), and
/// otherwise sends the app to the background, exactly like back on any
/// root screen. The routed stack is never touched.
///
/// [lockScreenBuilder] is supplied by the composition root (`main.dart`) so
/// `core/` never imports the `app_lock` feature (constitution Principle II).
class AppLockGate extends StatefulWidget {
  const AppLockGate({
    super.key,
    required this.observer,
    required this.lockScreenBuilder,
    required this.child,
  });

  final AppLifecycleObserver observer;
  final WidgetBuilder lockScreenBuilder;
  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _lockNavigatorKey = GlobalKey();

  bool get _isLocked => widget.observer.isLocked.value;

  @override
  void initState() {
    super.initState();
    // Registered before the Router below us mounts, so this observer is
    // asked about back events before the router's back-button dispatcher.
    WidgetsBinding.instance.addObserver(this);
    widget.observer.isLocked.addListener(_onLockChanged);
    if (_isLocked) _claimSystemBack();
  }

  @override
  void didUpdateWidget(covariant AppLockGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.observer != widget.observer) {
      oldWidget.observer.isLocked.removeListener(_onLockChanged);
      widget.observer.isLocked.addListener(_onLockChanged);
    }
  }

  @override
  void dispose() {
    widget.observer.isLocked.removeListener(_onLockChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onLockChanged() {
    if (_isLocked) _claimSystemBack();
  }

  /// Make sure Android routes back events to the framework while locked
  /// (the routed stack may have told it the framework can't handle back),
  /// so they reach [didPopRoute] below rather than being handled natively.
  /// Leaving it claimed after unlocking is harmless: an unhandled back in
  /// the framework ends in the same `SystemNavigator.pop()`.
  void _claimSystemBack() {
    SystemNavigator.setFrameworkHandlesBack(true);
  }

  @override
  Future<bool> didPopRoute() async {
    if (!_isLocked) return false;
    final navigator = _lockNavigatorKey.currentState;
    if (navigator == null || !await navigator.maybePop()) {
      // Nothing to pop on the lock screen: leave the app, as back on any
      // root screen does — never reveal or pop what's underneath.
      await SystemNavigator.pop();
    }
    return true;
  }

  // Android predictive back: claim the gesture while locked so no routed
  // page underneath starts (and on commit, completes) its pop animation.
  // Committing is then handled like a plain back press.
  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) => _isLocked;

  @override
  void handleCommitBackGesture() {
    didPopRoute();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.observer.isLocked,
      child: widget.child,
      builder: (context, locked, routedChild) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Offstage(
              offstage: locked,
              child: TickerMode(enabled: !locked, child: routedChild!),
            ),
            if (locked)
              // MaterialApp's HeroController already belongs to the router's
              // Navigator; a second Navigator must not share it.
              HeroControllerScope.none(
                child: NotificationListener<NavigationNotification>(
                  // The lock screen's Navigator must never tell the platform
                  // that the framework can't handle back — that would let
                  // Android handle it natively and bypass [didPopRoute].
                  // `true` notifications (something pushed) pass through.
                  onNotification: (notification) => !notification.canHandlePop,
                  child: Navigator(
                    key: _lockNavigatorKey,
                    onGenerateRoute: (settings) => MaterialPageRoute<void>(
                      settings: settings,
                      builder: widget.lockScreenBuilder,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
