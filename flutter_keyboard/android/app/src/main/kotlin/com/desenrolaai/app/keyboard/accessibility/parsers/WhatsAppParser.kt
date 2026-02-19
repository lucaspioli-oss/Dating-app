package com.desenrolaai.app.keyboard.accessibility.parsers

import android.graphics.Rect
import android.view.accessibility.AccessibilityNodeInfo
import com.desenrolaai.app.keyboard.accessibility.AppMessageParser
import com.desenrolaai.app.keyboard.accessibility.NodeTreeHelper
import com.desenrolaai.app.keyboard.accessibility.ParsedConversation
import com.desenrolaai.app.keyboard.accessibility.ParsedMessage

class WhatsAppParser : AppMessageParser {

    companion object {
        private const val PLATFORM = "whatsapp"
        private const val MAX_MESSAGES = 30

        // Well-known WhatsApp resource IDs
        private const val RES_CONTACT_NAME = "com.whatsapp:id/conversation_contact_name"
        private const val RES_MESSAGE_LIST = "com.whatsapp:id/message_list"

        // Alternative resource IDs (WhatsApp Business and newer versions)
        private const val RES_CONTACT_NAME_ALT = "com.whatsapp.w4b:id/conversation_contact_name"
        private const val RES_MESSAGE_LIST_ALT = "com.whatsapp.w4b:id/message_list"
    }

    override fun parse(rootNode: AccessibilityNodeInfo, eventType: Int): ParsedConversation? {
        return try {
            val contactName = findContactName(rootNode) ?: return null
            val messages = extractMessages(rootNode)
            if (messages.isEmpty()) return null

            ParsedConversation(
                contactName = contactName,
                platform = PLATFORM,
                messages = messages.takeLast(MAX_MESSAGES)
            )
        } catch (_: Exception) {
            null
        }
    }

    private fun findContactName(root: AccessibilityNodeInfo): String? {
        // Try primary WhatsApp resource ID
        val node = NodeTreeHelper.findByResourceId(root, RES_CONTACT_NAME)
            ?: NodeTreeHelper.findByResourceId(root, RES_CONTACT_NAME_ALT)

        val name = node?.text?.toString()?.trim()
        if (!name.isNullOrEmpty() && name.length >= 2) return name

        // Fallback: look for text in toolbar / action bar area
        return findNameFromToolbar(root)
    }

    private fun findNameFromToolbar(root: AccessibilityNodeInfo): String? {
        return try {
            findToolbarText(root, 0)
        } catch (_: Exception) {
            null
        }
    }

    private fun findToolbarText(node: AccessibilityNodeInfo, depth: Int): String? {
        if (depth > 6) return null

        val className = node.className?.toString() ?: ""
        val isToolbar = className.contains("Toolbar", ignoreCase = true) ||
                        className.contains("ActionBar", ignoreCase = true)

        if (isToolbar) {
            // Find the first substantial text child inside the toolbar
            return findFirstText(node)
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val result = findToolbarText(child, depth + 1)
            if (result != null) return result
        }
        return null
    }

    private fun findFirstText(node: AccessibilityNodeInfo): String? {
        val text = node.text?.toString()?.trim()
        if (!text.isNullOrEmpty() && text.length >= 2 && !isSystemText(text)) {
            return text
        }
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val result = findFirstText(child)
            if (result != null) return result
        }
        return null
    }

    private fun extractMessages(root: AccessibilityNodeInfo): List<ParsedMessage> {
        val messageList = NodeTreeHelper.findByResourceId(root, RES_MESSAGE_LIST)
            ?: NodeTreeHelper.findByResourceId(root, RES_MESSAGE_LIST_ALT)
            ?: findScrollableContainer(root)
            ?: return emptyList()

        val screenWidth = getScreenWidth(root)
        val messages = mutableListOf<ParsedMessage>()

        traverseMessageNodes(messageList, messages, screenWidth, 0)
        return messages
    }

    private fun traverseMessageNodes(
        node: AccessibilityNodeInfo,
        messages: MutableList<ParsedMessage>,
        screenWidth: Int,
        depth: Int
    ) {
        if (depth > 15) return

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            try {
                val messageText = extractMessageText(child)
                if (messageText != null && messageText.length >= 2 && !isSystemText(messageText)) {
                    val isOutgoing = determineDirection(child, screenWidth)
                    messages.add(ParsedMessage(text = messageText, isFromUser = isOutgoing))
                } else if (child.childCount > 0) {
                    // Only recurse if this node itself didn't yield a message
                    // to avoid duplicating text from parent+child
                    traverseMessageNodes(child, messages, screenWidth, depth + 1)
                }
            } catch (_: Exception) {
                // Node may have become stale, skip it
            }
        }
    }

    private fun extractMessageText(node: AccessibilityNodeInfo): String? {
        // First check if this node directly contains text
        val directText = node.text?.toString()?.trim()
        if (!directText.isNullOrEmpty() && directText.length >= 2) {
            return directText
        }

        // For compound message bubbles, aggregate child text
        val allText = NodeTreeHelper.extractAllText(node).trim()
        if (allText.length >= 2) {
            // Strip trailing timestamp patterns (e.g., "10:45 AM", "14:30")
            return stripTrailingTimestamp(allText)
        }
        return null
    }

    private fun determineDirection(node: AccessibilityNodeInfo, screenWidth: Int): Boolean {
        // Strategy 1: Check ancestors for resource IDs containing "out" or "in"
        val directionFromId = checkAncestorResourceIds(node)
        if (directionFromId != null) return directionFromId

        // Strategy 2: Positional heuristic
        return NodeTreeHelper.isRightAligned(node, screenWidth)
    }

    private fun checkAncestorResourceIds(node: AccessibilityNodeInfo): Boolean? {
        var current: AccessibilityNodeInfo? = node
        var depth = 0
        while (current != null && depth < 8) {
            val resId = current.viewIdResourceName?.lowercase() ?: ""
            if (resId.contains("message_out") || resId.contains("outgoing") ||
                resId.contains("sent") || resId.contains("_out")) {
                return true
            }
            if (resId.contains("message_in") || resId.contains("incoming") ||
                resId.contains("received") || resId.contains("_in")) {
                return false
            }
            current = current.parent
            depth++
        }
        return null
    }

    private fun findScrollableContainer(root: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        return findScrollableRecursive(root, 0)
    }

    private fun findScrollableRecursive(
        node: AccessibilityNodeInfo,
        depth: Int
    ): AccessibilityNodeInfo? {
        if (depth > 10) return null

        val className = node.className?.toString() ?: ""
        if (node.isScrollable ||
            className.contains("ListView") ||
            className.contains("RecyclerView") ||
            className.contains("ScrollView")
        ) {
            return node
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val result = findScrollableRecursive(child, depth + 1)
            if (result != null) return result
        }
        return null
    }

    private fun getScreenWidth(root: AccessibilityNodeInfo): Int {
        val rect = Rect()
        root.getBoundsInScreen(rect)
        return if (rect.width() > 0) rect.width() else 1080
    }

    private fun stripTrailingTimestamp(text: String): String {
        // Remove trailing timestamps like " 10:45 AM", " 14:30", " 2:05 PM"
        val pattern = Regex("""[\s,]*\d{1,2}:\d{2}(\s*[AaPp][Mm])?\s*$""")
        val stripped = text.replace(pattern, "").trim()
        return stripped.ifEmpty { text.trim() }
    }

    private fun isSystemText(text: String): Boolean {
        val lower = text.lowercase().trim()
        return lower.matches(Regex("""\d{1,2}:\d{2}(\s*[ap]m)?""")) ||
               lower.matches(Regex("""\d{1,2}/\d{1,2}/\d{2,4}""")) ||
               lower.matches(Regex("""(today|yesterday|monday|tuesday|wednesday|thursday|friday|saturday|sunday)""")) ||
               lower == "online" ||
               lower == "offline" ||
               lower == "typing..." ||
               lower == "typing" ||
               lower.startsWith("last seen") ||
               lower == "read" ||
               lower == "delivered" ||
               lower == "sent" ||
               lower.matches(Regex("""\d+\s*(new )?(messages?|msgs?)""")) ||
               lower == "end-to-end encrypted" ||
               lower.contains("messages and calls are end-to-end encrypted") ||
               lower == "tap for more info" ||
               lower.length < 2
    }
}
