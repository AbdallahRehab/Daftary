import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'splash_mark.dart';

/// What the splash is currently telling the user: the brand moment, or that
/// startup failed and can be retried (FR-016).
enum SplashMode { brand, error }

/// The splash's full-screen surface (contracts/splash_ui.md): the brand
/// field, the Daftary mark, and either the wordmark or the error block.
///
/// Uses `Material`, not `Scaffold`, so a snackbar queued during startup (e.g.
/// a tapped notification whose target is gone) waits for the first real
/// screen's `Scaffold` instead of appearing on the splash.
class SplashView extends StatelessWidget {
  const SplashView({
    required this.intro,
    this.appearanceResolved = true,
    this.mode = SplashMode.brand,
    this.onRetry,
    this.retrying = false,
    super.key,
  });

  /// The gate's 0→1 intro progress; drives the mark and the wordmark.
  final Animation<double> intro;

  /// Whether the saved language/theme are known. The wordmark stays hidden
  /// until then so its language never visibly flips (research Decision 10).
  final bool appearanceResolved;

  final SplashMode mode;
  final VoidCallback? onRetry;

  /// A retry is in flight: the error action is disabled (no double taps).
  final bool retrying;

  /// Light icons on transparent bars — the field draws edge to edge behind
  /// them, matching the native launch screens.
  static const SystemUiOverlayStyle _overlayStyle = SystemUiOverlayStyle(
    statusBarColor: Color(0x00000000),
    systemNavigationBarColor: Color(0x00000000),
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );

  /// Field crossfade when the in-app theme differs from the device's (the
  /// native launch screen can only follow the device).
  static const Duration _fieldCrossfade = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _overlayStyle,
      child: Material(
        type: MaterialType.transparency,
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : _fieldCrossfade,
          color: isDark ? AppBrandColors.fieldDeep : AppBrandColors.field,
          child: switch (mode) {
            SplashMode.brand => _BrandLayout(
              intro: intro,
              appearanceResolved: appearanceResolved,
            ),
            SplashMode.error => _ErrorLayout(
              onRetry: onRetry,
              retrying: retrying,
            ),
          },
        ),
      ),
    );
  }
}

/// The mark centred on the *full* screen (the native launch screens centre on
/// the whole window, so a safe-area centre would jump), with the wordmark
/// below it inside the safe area.
class _BrandLayout extends StatelessWidget {
  const _BrandLayout({required this.intro, required this.appearanceResolved});

  final Animation<double> intro;
  final bool appearanceResolved;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final wordmarkTop =
            (height / 2 + SplashGeometry.contentBottom + AppSpacing.xl).clamp(
              0.0,
              height,
            );
        return Stack(
          children: [
            Center(child: SplashMark(intro: intro)),
            Positioned(
              top: wordmarkTop,
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    // Very short (landscape) screens and large text scale the
                    // wordmark down instead of overflowing.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _SplashWordmark(
                        intro: intro,
                        appearanceResolved: appearanceResolved,
                      ),
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

/// App name + tagline, rising in over the intro's last beat.
class _SplashWordmark extends StatelessWidget {
  const _SplashWordmark({
    required this.intro,
    required this.appearanceResolved,
  });

  final Animation<double> intro;
  final bool appearanceResolved;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    return AnimatedBuilder(
      animation: intro,
      builder: (context, child) {
        final t = appearanceResolved
            ? SplashTimeline.wordmark.transform(intro.value)
            : 0.0;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * SplashGeometry.wordmarkRise),
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.appTitle,
              style: textTheme.headlineSmall!.copyWith(
                color: AppBrandColors.onField,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.splashTagline,
            style: textTheme.bodyMedium!.copyWith(
              color: AppBrandColors.onField,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Startup failed or timed out: the settled mark, a plain-language message,
/// and one way forward (FR-016, FR-020).
class _ErrorLayout extends StatelessWidget {
  const _ErrorLayout({required this.onRetry, required this.retrying});

  final VoidCallback? onRetry;
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxReadingWidth,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SplashMark(intro: AlwaysStoppedAnimation(1.0)),
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.splashErrorMessage,
                    style: textTheme.bodyLarge!.copyWith(
                      color: AppBrandColors.onField,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: retrying ? null : onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppBrandColors.onField,
                    foregroundColor: AppBrandColors.field,
                    minimumSize: const Size(48, 48),
                  ),
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
