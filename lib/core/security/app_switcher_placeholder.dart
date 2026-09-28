/// What the OS app-switcher / recents view shows instead of Daftary's last
/// screen (015 FR-020, research.md Decision 1).
///
/// The placeholder is drawn **natively** by `SecurityPlugin`, not by a
/// Flutter widget: the app-switcher snapshot is taken by the OS after the
/// app stops rendering frames, so a Dart widget pushed on `inactive` can
/// arrive too late to be captured. This file is the single Dart-side owner
/// of that placeholder's definition, so the Dart and native layers cannot
/// drift apart unnoticed (`test/core/security/app_switcher_placeholder_test.dart`
/// checks both native sources against the values below).
///
/// Per platform:
/// - **iOS** (`ios/Runner/SecurityPlugin.swift`): while protection is
///   enabled, a full-window `UIVisualEffectView` using [iosBlurStyle] covers
///   the key window from `willResignActive` until `didBecomeActive`, so the
///   snapshot is an opaque, theme-adaptive (light/dark) material with no
///   readable content. The OS frames it with Daftary's own app icon and
///   name, which is what makes the neutral surface a *branded* placeholder.
///   The same cover is raised for the whole of a screen recording/mirroring
///   session (FR-021).
/// - **Android** (`android/.../SecurityPlugin.kt`): [androidWindowFlag] on
///   the activity window makes the recents entry a blank surface, again
///   labelled with the app's icon and name by the launcher. The same flag
///   blocks screenshots and recordings.
///
/// There are deliberately no asset files: the placeholder carries no data,
/// no images of app content, and nothing that needs localizing.
abstract final class AppSwitcherPlaceholder {
  /// The `UIBlurEffect.Style` of the iOS privacy cover. `systemMaterial`
  /// follows the system light/dark appearance and is opaque enough to hide
  /// all text beneath it.
  static const String iosBlurStyle = 'systemMaterial';

  /// The Android `WindowManager.LayoutParams` flag that blanks the recents
  /// thumbnail (and blocks screenshots/recordings).
  static const String androidWindowFlag = 'FLAG_SECURE';
}
