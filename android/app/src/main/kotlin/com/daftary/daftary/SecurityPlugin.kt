package com.daftary.daftary

import android.app.Activity
import android.view.WindowManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * 015 screenshot/recording protection (research.md Decision 1).
 *
 * Android's single primitive is `FLAG_SECURE` on the activity window: it
 * blocks screenshots, screen recording and the app-switcher thumbnail in one
 * flag, so there is no separate "recording detected" signal to raise — the
 * recording event stream only ever reports `false` on this platform.
 *
 * The same flag is the app-switcher placeholder (FR-020): the recents entry
 * becomes a blank surface under the launcher's own app icon and label. The
 * Dart-side owner of that definition is `lib/core/security/app_switcher_placeholder.dart`.
 *
 * FR-022 — screenshots vs. the app's own data output. FLAG_SECURE only stops
 * *pixels of this window* from being captured by the OS (screenshot,
 * screen recording, casting, recents thumbnail). It has no effect on data the
 * app deliberately hands to another app:
 * - the CSV export (`SharePlusService`, `share_plus`) sends a *file* through
 *   an ACTION_SEND intent — the chooser and the receiving app render their
 *   own windows, which are not flagged, and no screenshot of Daftary is
 *   involved;
 * - the camera/gallery picker (`AttachmentPickerServiceImpl`) and the OCR
 *   cropper (`ImagePreparationServiceImpl`) likewise run in other activities
 *   and return files to the app.
 * None of these flows is, or is ever registered as, a screen capture from
 * the platform's perspective, so none is blocked (verified by code review
 * and quickstart.md Scenario 5, step 4). Any future export must keep that
 * shape — share a generated file, never a capture of this window. Because
 * those flows pause this activity, the Dart side runs them inside
 * `AppLifecycleObserver.runExternalActivity` so they don't trigger App Lock
 * (FR-010).
 */
class SecurityPlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var activity: Activity? = null

    /** Desired state, re-applied whenever the activity is (re)attached. */
    private var protectionEnabled = false

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL).also {
            it.setMethodCallHandler(this)
        }
        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL).also {
            it.setStreamHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        methodChannel = null
        eventChannel = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "enable" -> {
                protectionEnabled = true
                applyFlag()
                result.success(null)
            }
            "disable" -> {
                protectionEnabled = false
                applyFlag()
                result.success(null)
            }
            "isCaptured" -> result.success(false)
            else -> result.notImplemented()
        }
    }

    private fun applyFlag() {
        val window = activity?.window ?: return
        if (protectionEnabled) {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        events?.success(false)
    }

    override fun onCancel(arguments: Any?) {}

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        applyFlag()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        applyFlag()
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    companion object {
        const val METHOD_CHANNEL = "com.daftary.daftary/security"
        const val EVENT_CHANNEL = "com.daftary.daftary/security/recording"
    }
}
