package com.daftary.daftary

import android.Manifest
import android.app.Activity
import android.app.Application
import android.content.Context
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Telephony
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException

/**
 * 023 Bank SMS Import: the in-app plugin of sms-platform-channel.md
 * (research Decision 1, 14). Registered next to [SecurityPlugin] in every
 * Android build, with or without the READ_SMS capability: sharing needs
 * no permission (FR-001, FR-011).
 *
 * - `getCapabilities` -> `{readSmsDeclared, sdkInt, isStoreInstall}`, where
 *   `readSmsDeclared` is whether READ_SMS is among the installed package's
 *   requested permissions (§2.1). Never throws.
 * - `getPermissionState` -> `{granted, shouldShowRationale}` (§2.2). Never
 *   prompts.
 * - `requestPermission` -> `{granted, shouldShowRationale, dialogShown,
 *   sdkInt, installSource}` (§2.3). Requests READ_SMS only, request code
 *   [REQUEST_CODE], one request in flight. `dialogShown` is true when the
 *   activity paused between the request and the result (the system dialog
 *   is a separate activity).
 * - `queryInbox` -> one keyset page of allow-listed inbox rows (§2.4). The
 *   sender filter is inside the SQL selection, so a body from any other
 *   sender is never read (FR-020). Runs on one background thread.
 * - `getInitialSharedText` -> `{text, truncated, seq}` once, then null
 *   (§2.5), and the shared-text `EventChannel` (§2.6).
 *
 * In a build without READ_SMS every inbox and permission method answers
 * the typed `unavailable` code before touching the OS (§3).
 *
 * Thin: OS calls and argument shaping only; every decision is in Dart.
 * Error replies carry a code and nothing else. No logging of any kind.
 */
class SmsPlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler, PluginRegistry.RequestPermissionsResultListener {

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var context: Context? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var queryExecutor: ExecutorService? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    /** The one in-flight `requestPermission` call, if any. */
    private var pendingRequest: MethodChannel.Result? = null

    /** Set by the activity's `onPause` while a request is in flight. */
    private var dialogShown = false
    private var pauseWatcher: Application.ActivityLifecycleCallbacks? = null
    private var pauseWatcherApp: Application? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        queryExecutor = Executors.newSingleThreadExecutor()
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
        // Cancels a queued or running page; its reply is dropped.
        queryExecutor?.shutdownNow()
        queryExecutor = null
        failPendingRequest(ERROR_NO_ACTIVITY)
        context = null
        // A text not yet delivered stays in the holder until read or
        // process death; the stream listener is gone with the engine.
        SharedTextHolder.detach()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getCapabilities" -> result.success(capabilities())
            "getInitialSharedText" -> result.success(SharedTextHolder.takePending())
            "getPermissionState" -> permissionState(result)
            "requestPermission" -> requestPermission(result)
            "queryInbox" -> queryInbox(call, result)
            else -> result.notImplemented()
        }
    }

    // ---------------------------------------------------------------- §2.1

    private fun capabilities(): Map<String, Any?> = mapOf(
        "readSmsDeclared" to readSmsDeclared(),
        "sdkInt" to Build.VERSION.SDK_INT,
        "isStoreInstall" to when (installSource()) {
            INSTALL_STORE -> true
            INSTALL_NOT_STORE -> false
            else -> null
        },
    )

    /** READ_SMS among the installed package's requested permissions. */
    private fun readSmsDeclared(): Boolean {
        val ctx = context ?: return false
        return try {
            val info = packageInfo(ctx)
            info.requestedPermissions?.contains(Manifest.permission.READ_SMS) == true
        } catch (_: Exception) {
            false
        }
    }

    @Suppress("DEPRECATION")
    private fun packageInfo(ctx: Context): PackageInfo {
        val pm = ctx.packageManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getPackageInfo(
                ctx.packageName,
                PackageManager.PackageInfoFlags.of(PackageManager.GET_PERMISSIONS.toLong()),
            )
        } else {
            pm.getPackageInfo(ctx.packageName, PackageManager.GET_PERMISSIONS)
        }
    }

    /**
     * How this package was installed (§2.3): `store`, `notStore` or
     * `unknown`. API 33+ reads `packageSource`; API 30+ falls back to the
     * installer package against [STORE_INSTALLERS]; below API 30 (or on
     * any failure) it is `unknown`.
     */
    private fun installSource(): String {
        val ctx = context ?: return INSTALL_UNKNOWN
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return INSTALL_UNKNOWN
        return try {
            val info = ctx.packageManager.getInstallSourceInfo(ctx.packageName)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                when (info.packageSource) {
                    PackageInstallerSource.STORE -> return INSTALL_STORE
                    PackageInstallerSource.DOWNLOADED_FILE,
                    PackageInstallerSource.LOCAL_FILE,
                    PackageInstallerSource.OTHER,
                    -> return INSTALL_NOT_STORE
                }
            }
            val installer = info.installingPackageName ?: return INSTALL_UNKNOWN
            if (installer in STORE_INSTALLERS) INSTALL_STORE else INSTALL_NOT_STORE
        } catch (_: Exception) {
            INSTALL_UNKNOWN
        }
    }

    // ---------------------------------------------------------------- §2.2

    private fun permissionState(result: MethodChannel.Result) {
        if (!readSmsDeclared()) {
            result.error(ERROR_UNAVAILABLE, null, null)
            return
        }
        result.success(
            mapOf(
                "granted" to isGranted(),
                "shouldShowRationale" to shouldShowRationale(),
            ),
        )
    }

    private fun isGranted(): Boolean {
        val ctx = context ?: return false
        return ctx.checkSelfPermission(Manifest.permission.READ_SMS) ==
            PackageManager.PERMISSION_GRANTED
    }

    /** False when no activity is attached (§2.2). */
    private fun shouldShowRationale(): Boolean {
        val activity = activityBinding?.activity ?: return false
        return activity.shouldShowRequestPermissionRationale(Manifest.permission.READ_SMS)
    }

    // ---------------------------------------------------------------- §2.3

    private fun requestPermission(result: MethodChannel.Result) {
        if (!readSmsDeclared()) {
            result.error(ERROR_UNAVAILABLE, null, null)
            return
        }
        val activity = activityBinding?.activity
        if (activity == null) {
            result.error(ERROR_NO_ACTIVITY, null, null)
            return
        }
        if (pendingRequest != null) {
            result.error(ERROR_REQUEST_IN_PROGRESS, null, null)
            return
        }
        if (isGranted()) {
            // Nothing to ask; no system activity is started.
            result.success(requestReply(granted = true, shown = false))
            return
        }
        pendingRequest = result
        dialogShown = false
        watchPause(activity)
        try {
            // Only READ_SMS, ever (FR-069, FR-073). Platform API (minSdk 24):
            // FlutterFragmentActivity forwards the result to this listener.
            activity.requestPermissions(arrayOf(Manifest.permission.READ_SMS), REQUEST_CODE)
        } catch (_: Exception) {
            failPendingRequest(ERROR_NO_ACTIVITY)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val result = pendingRequest ?: return true
        pendingRequest = null
        stopWatchingPause()
        // An interrupted request delivers empty arrays; the live check is
        // the source of truth either way.
        result.success(requestReply(granted = isGranted(), shown = dialogShown))
        return true
    }

    private fun requestReply(granted: Boolean, shown: Boolean): Map<String, Any> = mapOf(
        "granted" to granted,
        "shouldShowRationale" to shouldShowRationale(),
        "dialogShown" to shown,
        "sdkInt" to Build.VERSION.SDK_INT,
        "installSource" to installSource(),
    )

    /**
     * Records `onPause` of [activity] while a request is in flight: the
     * system permission dialog is its own activity, so the requesting one
     * pauses exactly when the dialog is shown.
     */
    private fun watchPause(activity: Activity) {
        stopWatchingPause()
        val watcher = object : Application.ActivityLifecycleCallbacks {
            override fun onActivityPaused(a: Activity) {
                if (a === activity) dialogShown = true
            }

            override fun onActivityCreated(a: Activity, savedInstanceState: Bundle?) {}
            override fun onActivityStarted(a: Activity) {}
            override fun onActivityResumed(a: Activity) {}
            override fun onActivityStopped(a: Activity) {}
            override fun onActivitySaveInstanceState(a: Activity, outState: Bundle) {}
            override fun onActivityDestroyed(a: Activity) {}
        }
        val app = activity.application
        app.registerActivityLifecycleCallbacks(watcher)
        pauseWatcher = watcher
        pauseWatcherApp = app
    }

    private fun stopWatchingPause() {
        val watcher = pauseWatcher ?: return
        pauseWatcherApp?.unregisterActivityLifecycleCallbacks(watcher)
        pauseWatcher = null
        pauseWatcherApp = null
    }

    private fun failPendingRequest(code: String) {
        val result = pendingRequest ?: return
        pendingRequest = null
        stopWatchingPause()
        result.error(code, null, null)
    }

    // ---------------------------------------------------------------- §2.4

    private fun queryInbox(call: MethodCall, result: MethodChannel.Result) {
        if (!readSmsDeclared()) {
            result.error(ERROR_UNAVAILABLE, null, null)
            return
        }
        val args = InboxArgs.parse(call)
        if (args == null) {
            result.error(ERROR_INVALID_ARGS, null, null)
            return
        }
        if (!isGranted()) {
            result.error(ERROR_PERMISSION_DENIED, null, null)
            return
        }
        val ctx = context
        val executor = queryExecutor
        if (ctx == null || executor == null) {
            result.error(ERROR_QUERY_FAILED, null, null)
            return
        }
        try {
            executor.execute {
                val reply = readPage(ctx, args)
                mainHandler.post {
                    when (reply) {
                        is PageReply.Rows -> result.success(reply.rows)
                        is PageReply.Error -> result.error(reply.code, null, null)
                    }
                }
            }
        } catch (_: RejectedExecutionException) {
            result.error(ERROR_QUERY_FAILED, null, null)
        }
    }

    /**
     * One keyset page. Every value is a bind argument; the sender filter
     * is part of the selection, so the provider never returns (and this
     * never reads) a body from a sender outside [InboxArgs.senders].
     * Reads at most `limit` rows with a body; rows without a body (MMS
     * only) are skipped and reported only as absence.
     */
    private fun readPage(ctx: Context, args: InboxArgs): PageReply {
        val placeholders = args.senders.joinToString(",") { "?" }
        // Senders arrive canonical (no spaces, upper-case; Dart
        // canonicalSmsSenderId), so the stored address is normalised the
        // same way: "QNB ALAHLI" must match QNBALAHLI.
        val canonicalAddress = "REPLACE(UPPER(address), ' ', '')"
        val selection: String
        val selectionArgs: Array<String>
        if (args.afterId == null) {
            selection = "$canonicalAddress IN ($placeholders) AND date > ?"
            selectionArgs = (args.senders + args.afterDate.toString()).toTypedArray()
        } else {
            selection =
                "$canonicalAddress IN ($placeholders) AND (date > ? OR (date = ? AND _id > ?))"
            selectionArgs = (
                args.senders + listOf(
                    args.afterDate.toString(),
                    args.afterDate.toString(),
                    args.afterId.toString(),
                )
                ).toTypedArray()
        }
        return try {
            val cursor = ctx.contentResolver.query(
                Telephony.Sms.Inbox.CONTENT_URI,
                PROJECTION,
                selection,
                selectionArgs,
                "date ASC, _id ASC",
            ) ?: return PageReply.Error(ERROR_QUERY_FAILED)
            cursor.use { c ->
                val idCol = c.getColumnIndexOrThrow("_id")
                val addressCol = c.getColumnIndexOrThrow("address")
                val dateCol = c.getColumnIndexOrThrow("date")
                val bodyCol = c.getColumnIndexOrThrow("body")
                val rows = ArrayList<Map<String, Any>>(minOf(args.limit, 32))
                while (rows.size < args.limit && c.moveToNext()) {
                    if (Thread.currentThread().isInterrupted) {
                        return PageReply.Error(ERROR_QUERY_FAILED)
                    }
                    if (c.isNull(bodyCol) || c.isNull(addressCol)) continue
                    val body = c.getString(bodyCol) ?: continue
                    val address = c.getString(addressCol) ?: continue
                    val truncated = body.length > MAX_BODY_CHARS
                    rows.add(
                        mapOf(
                            "id" to c.getLong(idCol),
                            "address" to address,
                            "date" to c.getLong(dateCol),
                            "body" to if (truncated) truncate(body) else body,
                            "truncated" to truncated,
                        ),
                    )
                }
                PageReply.Rows(rows)
            }
        } catch (_: SecurityException) {
            PageReply.Error(ERROR_PERMISSION_DENIED)
        } catch (_: Exception) {
            PageReply.Error(ERROR_QUERY_FAILED)
        }
    }

    /** Cuts at [MAX_BODY_CHARS] without splitting a surrogate pair. */
    private fun truncate(body: String): String {
        var end = MAX_BODY_CHARS
        if (Character.isHighSurrogate(body[end - 1])) end -= 1
        return body.substring(0, end)
    }

    private sealed class PageReply {
        class Rows(val rows: List<Map<String, Any>>) : PageReply()
        class Error(val code: String) : PageReply()
    }

    /** The validated `queryInbox` arguments (§2.4); null on any violation. */
    private class InboxArgs(
        val senders: List<String>,
        val afterDate: Long,
        val afterId: Long?,
        val limit: Int,
    ) {
        companion object {
            fun parse(call: MethodCall): InboxArgs? {
                val rawSenders = call.argument<Any?>("senders") as? List<*> ?: return null
                if (rawSenders.isEmpty() || rawSenders.size > MAX_SENDERS) return null
                val senders = ArrayList<String>(rawSenders.size)
                for (raw in rawSenders) {
                    val sender = raw as? String ?: return null
                    if (sender.isEmpty() || sender.length > MAX_SENDER_CHARS) return null
                    if (sender != sender.uppercase() || sender.any { it.isWhitespace() }) {
                        return null
                    }
                    senders.add(sender)
                }
                val afterDate = (call.argument<Any?>("afterDate") as? Number)?.toLong()
                    ?: return null
                if (afterDate < 0) return null
                val rawAfterId = call.argument<Any?>("afterId")
                val afterId = when (rawAfterId) {
                    null -> null
                    is Number -> rawAfterId.toLong()
                    else -> return null
                }
                if (afterId != null && afterId < 0) return null
                val limit = (call.argument<Any?>("limit") as? Number)?.toLong() ?: return null
                if (limit < 1 || limit > MAX_LIMIT) return null
                return InboxArgs(senders, afterDate, afterId, limit.toInt())
            }
        }
    }

    // ------------------------------------------------------------ §2.5/2.6

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        val sink = events ?: return
        SharedTextHolder.attach { payload -> sink.success(payload) }
    }

    override fun onCancel(arguments: Any?) {
        SharedTextHolder.detach()
    }

    // ------------------------------------------------------------ activity

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        attach(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        // A pending request survives a configuration change: the result is
        // delivered to the recreated activity, which re-attaches below.
        stopWatchingPause()
        detach()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        attach(binding)
    }

    override fun onDetachedFromActivity() {
        detach()
        failPendingRequest(ERROR_NO_ACTIVITY)
    }

    private fun attach(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    private fun detach() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
    }

    /** `PackageInstaller.PACKAGE_SOURCE_*` (API 33). */
    private object PackageInstallerSource {
        const val OTHER = 1
        const val STORE = 2
        const val LOCAL_FILE = 3
        const val DOWNLOADED_FILE = 4
    }

    companion object {
        const val METHOD_CHANNEL = "com.daftary.daftary/sms"
        const val EVENT_CHANNEL = "com.daftary.daftary/sms/shared_text"

        /** Below 16 bits, as `FragmentActivity` requires (§2.3). */
        private const val REQUEST_CODE = 0x5A11

        private const val ERROR_UNAVAILABLE = "unavailable"
        private const val ERROR_NO_ACTIVITY = "no_activity"
        private const val ERROR_REQUEST_IN_PROGRESS = "request_in_progress"
        private const val ERROR_PERMISSION_DENIED = "permission_denied"
        private const val ERROR_QUERY_FAILED = "query_failed"
        private const val ERROR_INVALID_ARGS = "invalid_args"

        private const val INSTALL_STORE = "store"
        private const val INSTALL_NOT_STORE = "notStore"
        private const val INSTALL_UNKNOWN = "unknown"

        /** Installer packages treated as an app store (research Decision 2). */
        private val STORE_INSTALLERS = setOf(
            "com.android.vending",
            "com.sec.android.app.samsungapps",
            "com.huawei.appmarket",
            "com.xiaomi.market",
        )

        private val PROJECTION = arrayOf("_id", "address", "date", "body")
        private const val MAX_SENDERS = 200
        private const val MAX_SENDER_CHARS = 32
        private const val MAX_LIMIT = 200L

        /** Bodies are cut here with `truncated = true` (FR-098). */
        private const val MAX_BODY_CHARS = 4_000
    }
}
