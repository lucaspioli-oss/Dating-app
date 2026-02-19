package com.desenrolaai.app.keyboard.accessibility

import android.view.accessibility.AccessibilityNodeInfo

interface AppMessageParser {
    fun parse(rootNode: AccessibilityNodeInfo, eventType: Int): ParsedConversation?
}
