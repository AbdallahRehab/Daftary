package com.daftary.daftary

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
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
}
