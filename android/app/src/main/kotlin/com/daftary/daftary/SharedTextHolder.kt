package com.daftary.daftary

/**
 * 023 (sms-platform-channel §2.5, §2.6): holds at most one shared text in
 * process memory between [ShareTargetActivity] and [SmsPlugin].
 *
 * - When the plugin has a stream listener, [offer] pushes the text to it
 *   at once (warm start).
 * - Otherwise it keeps one pending payload (a newer share replaces an
 *   older one) until a listener subscribes or [takePending] drains it
 *   (cold start). Either way a share is delivered once and then cleared.
 *
 * Payload: `{text, truncated, seq}`. Text over [MAX_CHARS] is cut to
 * [MAX_CHARS] with `truncated = true`, so Dart can report "too long"
 * precisely (FR-017). `seq` is monotonic, so Dart drops a repeat.
 *
 * Main thread only (activity `onCreate` and channel callbacks). Never
 * logged, never written anywhere.
 */
internal object SharedTextHolder {
    /** The 10,000 bound of FR-017 plus one. */
    const val MAX_CHARS = 10_001

    private var pending: Map<String, Any>? = null
    private var listener: ((Map<String, Any>) -> Unit)? = null
    private var seq = 0L

    fun offer(text: CharSequence) {
        if (text.isEmpty()) return
        val truncated = text.length > MAX_CHARS
        val body = if (truncated) text.subSequence(0, MAX_CHARS) else text
        seq += 1
        val payload = mapOf<String, Any>(
            "text" to body.toString(),
            "truncated" to truncated,
            "seq" to seq,
        )
        val current = listener
        if (current != null) {
            pending = null
            current(payload)
        } else {
            pending = payload
        }
    }

    /** Returns the pending payload once and clears it. */
    fun takePending(): Map<String, Any>? {
        val payload = pending
        pending = null
        return payload
    }

    /** Sets the stream listener and delivers a pending payload to it once. */
    fun attach(sink: (Map<String, Any>) -> Unit) {
        listener = sink
        takePending()?.let(sink)
    }

    fun detach() {
        listener = null
    }
}
