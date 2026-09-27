/// 021 Offline-First Cloud Sync: build-time cloud configuration (research.md
/// Decision 12).
///
/// Values come from `--dart-define-from-file=config/supabase.<env>.json`. The
/// real files are git-ignored; only `config/supabase.example.json` is
/// committed. Only the publishable key ever reaches the client — never the
/// service-role key (constitution XII). This is the only place in `lib/`
/// that reads them.
class CloudConfig {
  const CloudConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// True only when both values were supplied at build time. When false the
  /// app runs fully local and sync reports `disabled`.
  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
