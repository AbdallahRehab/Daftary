package com.daftary.daftary

import android.app.Activity
import android.content.Intent
import android.os.Bundle

/**
 * 023 Bank SMS Import (FR-016, sms-platform-channel §2.5): the Android
 * text share target.
 *
 * A translucent, `noHistory`, `excludeFromRecents` trampoline. It never
 * sets a content view and never renders the text (this window is not
 * covered by FLAG_SECURE). In `onCreate` it copies `EXTRA_TEXT` of an
 * `ACTION_SEND text/plain` intent into the in-process [SharedTextHolder]
 * (never into another Intent), starts [MainActivity] with
 * `NEW_TASK | CLEAR_TOP | SINGLE_TOP` so the running instance receives it
 * (no second app instance, no second Flutter engine), and finishes.
 * `MainActivity` and its launch mode are untouched.
 *
 * No logging of any kind.
 */
class ShareTargetActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // A restored instance (process death) never replays a share.
        if (savedInstanceState == null) {
            readSharedText(intent)?.let { SharedTextHolder.offer(it) }
        }
        val launch = Intent(this, MainActivity::class.java).addFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP,
        )
        startActivity(launch)
        finish()
    }

    /** `EXTRA_TEXT` of an `ACTION_SEND text/plain` intent, else null. */
    private fun readSharedText(intent: Intent?): CharSequence? {
        if (intent == null || intent.action != Intent.ACTION_SEND) return null
        val type = intent.type ?: return null
        if (!type.startsWith("text/plain")) return null
        return try {
            intent.getCharSequenceExtra(Intent.EXTRA_TEXT)
        } catch (_: Exception) {
            // A malformed extra from another app is dropped, never inspected.
            null
        }
    }
}
