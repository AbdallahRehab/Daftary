package com.daftary.daftary

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * 015 App Lock: a [FlutterFragmentActivity] (not a plain `FlutterActivity`)
 * because `local_auth` hosts the BiometricPrompt in a Fragment.
 */
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // In-app plugin (research.md Decision 1): FLAG_SECURE toggling for
        // the always-on screenshot/recording protection (FR-020/FR-021).
        flutterEngine.plugins.add(SecurityPlugin())
    }
}
