import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/app_startup_cubit.dart';
import '../cubit/app_startup_state.dart';
import 'splash_mark.dart';
import 'splash_view.dart';

/// Shows the splash until startup is ready *and* the intro has played, then
/// mounts [child] — the app's `Router` — beneath the splash and fades the
/// splash out (research Decisions 2 and 5).
///
/// Sits in `MaterialApp.router(builder:)`, so the Router is simply not in the
/// tree before hand-off: GoRouter parses nothing and runs no `redirect` until
/// the onboarding gate has settled, and the destination is still chosen only
/// by the router (FR-013). `_handedOff` is a one-way latch, so the Router
/// mounts exactly once (FR-014); theme, language and lifecycle changes rebuild
/// this widget but never reset it, so the splash never replays (FR-017).
class AppStartupGate extends StatefulWidget {
  const AppStartupGate({required this.child, super.key});

  final Widget child;

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: SplashTimeline.introDuration,
  )..addStatusListener(_onIntroStatus);

  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: SplashTimeline.exitDuration,
  )..addStatusListener(_onExitStatus);

  bool _introStarted = false;
  bool _introDone = false;
  bool _handedOff = false;
  bool _splashRemoved = false;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_handedOff) return;
    if (!_introDone && context.read<AppStartupCubit>().state.isFailed) {
      // Startup already failed before the first frame: no story to tell,
      // rest in the settled state behind the error (FR-016).
      _settleIntro();
    }
    if (_reduceMotion) {
      // FR-009: show the settled composition with no movement. Flags are set
      // directly — this runs inside the build phase, and build runs next.
      _settleIntro();
      if (context.read<AppStartupCubit>().state.isReady) {
        _handedOff = true;
        _splashRemoved = true;
      }
    } else if (!_introStarted) {
      _introStarted = true;
      _introTicker.start();
    }
  }

  /// Drives [_intro] instead of `forward()`: the first frames after launch
  /// are the slowest (engine warm-up, shader compilation), and a time-based
  /// animation would skip half the story in one long frame. Each frame
  /// advances the story by real time but at most [_maxIntroStep], so it
  /// always plays through; [_introWallClockCap] still bounds the wait on a
  /// very slow device (SC-002).
  late final Ticker _introTicker = createTicker(_onIntroTick);
  Duration _lastIntroTick = Duration.zero;

  static const Duration _maxIntroStep = Duration(milliseconds: 50);
  static const Duration _introWallClockCap = Duration(milliseconds: 1600);

  void _onIntroTick(Duration elapsed) {
    final step = elapsed - _lastIntroTick;
    _lastIntroTick = elapsed;
    final advance =
        (step > _maxIntroStep ? _maxIntroStep : step).inMicroseconds /
        SplashTimeline.introDuration.inMicroseconds;
    final next = elapsed >= _introWallClockCap ? 1.0 : _intro.value + advance;
    if (next >= 1.0) _introTicker.stop();
    // Reaching 1.0 completes the controller, which fires _onIntroStatus.
    _intro.value = next.clamp(0.0, 1.0);
  }

  /// Rests the mark in its settled state and stops the story clock.
  void _settleIntro() {
    _introDone = true;
    _introTicker.stop();
    _intro.value = 1.0;
  }

  void _onIntroStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _introDone) return;
    _introDone = true;
    _maybeHandOff();
  }

  void _onExitStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _splashRemoved = true);
    }
  }

  /// Hands off at the later of intro-end and readiness — never twice.
  void _maybeHandOff() {
    if (!mounted || _handedOff || !_introDone) return;
    if (!context.read<AppStartupCubit>().state.isReady) return;
    setState(() {
      _handedOff = true;
      if (_reduceMotion) _splashRemoved = true;
    });
    if (!_reduceMotion) _exit.forward();
  }

  void _onStartupChanged(BuildContext context, AppStartupState state) {
    if (state.isFailed && !_introDone) {
      // FR-016: stop moving and rest in the settled state behind the error.
      _settleIntro();
    }
    _maybeHandOff();
  }

  @override
  void dispose() {
    _introTicker.dispose();
    _intro.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppStartupCubit, AppStartupState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _onStartupChanged,
      builder: (context, state) {
        final showError = state.isFailed || (state.isRetry && !state.isReady);
        // Both children are keyed so the Router keeps its element (and thus
        // its navigation state) when the splash above it is removed.
        return Stack(
          fit: StackFit.expand,
          children: [
            if (_handedOff)
              KeyedSubtree(key: const ValueKey('app'), child: widget.child),
            if (!_splashRemoved)
              KeyedSubtree(
                key: const ValueKey('splash'),
                child: IgnorePointer(
                  ignoring: _handedOff,
                  child: ExcludeSemantics(
                    excluding: _handedOff,
                    child: FadeTransition(
                      opacity: ReverseAnimation(_exit),
                      child: SplashView(
                        intro: _intro,
                        appearanceResolved: state.appearanceResolved,
                        mode: showError ? SplashMode.error : SplashMode.brand,
                        onRetry: context.read<AppStartupCubit>().retry,
                        retrying: state.status == AppStartupStatus.preparing,
                      ),
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
