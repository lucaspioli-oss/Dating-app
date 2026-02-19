package com.desenrolaai.app.keyboard.accessibility

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.view.accessibility.AccessibilityEvent
import com.desenrolaai.app.keyboard.accessibility.parsers.*

class DesenrolaAccessibilityService : AccessibilityService() {

    companion object {
        val TARGET_PACKAGES = setOf(
            "com.whatsapp",
            "com.whatsapp.w4b",
            "com.tinder",
            "com.bumble.app",
            "co.hinge.app",
            "com.instagram.android"
        )
        private const val DEBOUNCE_MS = 500L
    }

    private val lastProcessedTime = mutableMapOf<String, Long>()
    private val parsers = mutableMapOf<String, AppMessageParser>()

    override fun onServiceConnected() {
        super.onServiceConnected()
        ConversationStore.init(applicationContext)

        parsers["com.whatsapp"] = WhatsAppParser()
        parsers["com.whatsapp.w4b"] = WhatsAppParser()
        parsers["com.tinder"] = TinderParser()
        parsers["com.bumble.app"] = BumbleParser()
        parsers["co.hinge.app"] = HingeParser()
        parsers["com.instagram.android"] = InstagramParser()

        serviceInfo = serviceInfo?.apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                         AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = flags or
                    AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS or
                    AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS
            notificationTimeout = 300
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val evt = event ?: return
        val pkg = evt.packageName?.toString() ?: return
        if (pkg !in TARGET_PACKAGES) return

        val now = System.currentTimeMillis()
        val last = lastProcessedTime[pkg] ?: 0
        if (now - last < DEBOUNCE_MS) return
        lastProcessedTime[pkg] = now

        val rootNode = rootInActiveWindow ?: return
        try {
            val parser = parsers[pkg] ?: return
            val result = parser.parse(rootNode, evt.eventType)
            if (result != null && result.messages.isNotEmpty()) {
                ConversationStore.updateConversation(pkg, result)
            }
        } catch (_: Exception) {
            // Silently ignore parsing errors to avoid crashing the service
        } finally {
            rootNode.recycle()
        }
    }

    override fun onInterrupt() {}
}
