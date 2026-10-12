package com.daftary.daftary

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * 015 App Lock: a [FlutterFragmentActivity] (not a plain `FlutterActivity`)
 * because `local_auth` hosts the BiometricPrompt in a Fragment.
 */
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 019: Android 12+ always shows the system SplashScreen and, by
        // default, reveals the app with a fade once Flutter draws. Flutter's
        // first frame is the same field and notebook as the system splash,
        // so remove it instantly instead — a fade would dim the mark mid-way.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { view -> view.remove() }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // In-app plugin (research.md Decision 1): FLAG_SECURE toggling for
        // the always-on screenshot/recording protection (FR-020/FR-021).
        flutterEngine.plugins.add(SecurityPlugin())
        // 023: bank SMS import. Registered in every build: sharing needs no
        // permission, and without READ_SMS the inbox/permission methods
        // answer `unavailable` (sms-platform-channel.md).
        flutterEngine.plugins.add(SmsPlugin())
    }
}
