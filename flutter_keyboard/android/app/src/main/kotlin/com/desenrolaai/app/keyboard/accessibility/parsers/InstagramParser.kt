package com.desenrolaai.app.keyboard.accessibility.parsers

import android.graphics.Rect
import android.view.accessibility.AccessibilityNodeInfo
import com.desenrolaai.app.keyboard.accessibility.AppMessageParser
import com.desenrolaai.app.keyboard.accessibility.NodeTreeHelper
import com.desenrolaai.app.keyboard.accessibility.ParsedConversation
import com.desenrolaai.app.keyboard.accessibility.ParsedMessage

class InstagramParser : AppMessageParser {

    companion object {
        private const val PLATFORM = "instagram"
        private const val MAX_MESSAGES = 30

        // Instagram DM-specific resource IDs
        private const val RES_THREAD_TITLE = "com.instagram.android:id/thread_title"
        private const val RES_MESSAGE_LIST = "com.instagram.android:id/message_list"
        private const val RES_MESSAGE_CONTENT = "com.instagram.android:id/message_content"
        private const val RES_DIRECT_TEXT = "com.instagram.android:id/direct_text_message_text_view"
        private const val RES_ROW_THREAD = "com.instagram.android:id/row_thread_composer_edittext"

        // Additional DM indicators (presence of these confirms we are on a DM screen)
        private val DM_INDICATOR_IDS = setOf(
            "com.instagram.android:id/thread_title",
            "com.instagram.android:id/row_thread_composer_edittext",
            "com.instagram.android:id/message_list",
            "com.instagram.android:id/direct_thread_recycler_view"
        )
    }

    override fun parse(rootNode: AccessibilityNodeInfo, eventType: Int): ParsedConversation? {
        return try {
            // Instagram has many screens (feed, stories, reels, explore, etc.).
            // Only parse the DM conversation screen.
            if (!isDmScreen(rootNode)) return null

            val contactName = findContactName(rootNode) ?: return null
            val screenWidth = getScreenWidth(rootNode)
            val messages = extractMessages(rootNode, screenWidth)
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

    /**
     * Verifies this is an Instagram DM screen by checking for DM-specific
     * resource IDs. Returns false for feed, stories, reels, explore, etc.
     */
    private fun isDmScreen(root: AccessibilityNodeInfo): Boolean {
        for (resId in DM_INDICATOR_IDS) {
            val node = NodeTreeHelper.findByResourceId(root, resId)
            if (node != null) return true
        }
        return false
    }

    private fun findContactName(root: AccessibilityNodeInfo): String? {
        // Primary: use the thread_title resource ID
        val titleNode = NodeTreeHelper.findByResourceId(root, RES_THREAD_TITLE)
        val titleText = titleNode?.text?.toString()?.trim()
        if (!titleText.isNullOrEmpty() && titleText.length >= 2) {
            return titleText
        }

        // Fallback: content description on the title node
        val titleDesc = titleNode?.contentDescription?.toString()?.trim()
        if (!titleDesc.isNullOrEmpty() && titleDesc.length >= 2) {
            return titleDesc
        }

        // Fallback: look for text in toolbar area
        return findTextInToolbar(root, 0)
    }

    private fun findTextInToolbar(node: AccessibilityNodeInfo, depth: Int): String? {
        if (depth > 8) return null

        val className = node.className?.toString() ?: ""
        val isToolbar = className.contains("Toolbar", ignoreCase = true) ||
                        className.contains("ActionBar", ignoreCase = true)

        if (isToolbar) {
            return findFirstSubstantialText(node)
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val result = findTextInToolbar(child, depth + 1)
            if (result != null) return result
        }
        return null
    }

    private fun findFirstSubstantialText(node: AccessibilityNodeInfo): String? {
        val text = node.text?.toString()?.trim()
        if (!text.isNullOrEmpty() && text.length >= 2 && !isSystemText(text)) {
            return text
        }

        val desc = node.contentDescription?.toString()?.trim()
        if (!desc.isNullOrEmpty() && desc.length >= 2 && !isSystemText(desc)) {
            return desc
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val result = findFirstSubstantialText(child)
            if (result != null) return result
        }
        return null
    }

    private fun extractMessages(root: AccessibilityNodeInfo, screenWidth: Int): List<ParsedMessage> {
        // Try well-known DM message list resource IDs
        val messageContainer = NodeTreeHelper.findByResourceId(root, RES_MESSAGE_LIST)
            ?: NodeTreeHelper.findByResourceId(root, "com.instagram.android:id/direct_thread_recycler_view")
            ?: findScrollableContainer(root)
            ?: return emptyList()

        val messages = mutableListOf<ParsedMessage>()
        collectDmMessages(messageContainer, messages, screenWidth, 0)
        return messages
    }

    private fun collectDmMessages(
        node: AccessibilityNodeInfo,
        messages: MutableList<ParsedMessage>,
        screenWidth: Int,
        depth: Int
    ) {
        if (depth > 20) return

        // Check for Instagram-specific message text views first
        val resId = node.viewIdResourceName ?: ""
        if (resId == RES_DIRECT_TEXT || resId == RES_MESSAGE_CONTENT) {
            val text = node.text?.toString()?.trim()
            if (!text.isNullOrEmpty() && text.length >= 2 && !isSystemText(text)) {
                val isOutgoing = NodeTreeHelper.isRightAligned(node, screenWidth)
                messages.add(ParsedMessage(text = text, isFromUser = isOutgoing))
                return
            }
        }

        // Generic text extraction
        val text = node.text?.toString()?.trim()
        if (!text.isNullOrEmpty() && text.length >= 2 && !isSystemText(text) && isMessageLike(node)) {
            val isOutgoing = NodeTreeHelper.isRightAligned(node, screenWidth)
            messages.add(ParsedMessage(text = text, isFromUser = isOutgoing))
            return
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            try {
                collectDmMessages(child, messages, screenWidth, depth + 1)
            } catch (_: Exception) {
                // Stale node
            }
        }
    }

    /**
     * Heuristic to determine if a text node is likely a message rather than
     * a UI label. Messages are typically TextView nodes with non-trivial text
     * that sit inside the message list area.
     */
    private fun isMessageLike(node: AccessibilityNodeInfo): Boolean {
        val className = node.className?.toString() ?: ""
        // Must be a text-displaying view
        if (!className.contains("TextView") &&
            !className.contains("Text", ignoreCase = true)) {
            return false
        }

        // Exclude if this is an input field (the composer)
        if (node.isEditable) return false

        // Exclude if resource ID suggests it's a label/button
        val resId = node.viewIdResourceName?.lowercase() ?: ""
        if (resId.contains("button") || resId.contains("label") ||
            resId.contains("tab") || resId.contains("title") ||
            resId.contains("header") || resId.contains("composer") ||
            resId.contains("edittext")) {
            return false
        }

        return true
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
            className.contains("RecyclerView") ||
            className.contains("ListView") ||
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

    private fun isSystemText(text: String): Boolean {
        val lower = text.lowercase().trim()
        return lower.matches(Regex("""\d{1,2}:\d{2}(\s*[ap]m)?""")) ||
               lower.matches(Regex("""\d{1,2}/\d{1,2}/\d{2,4}""")) ||
               lower.matches(Regex("""(today|yesterday|monday|tuesday|wednesday|thursday|friday|saturday|sunday)""")) ||
               lower == "online" ||
               lower == "offline" ||
               lower == "active now" ||
               lower.startsWith("active ") ||
               lower == "typing..." ||
               lower == "typing" ||
               lower == "seen" ||
               lower == "delivered" ||
               lower == "sent" ||
               lower == "message..." ||
               lower == "message" ||
               lower == "send" ||
               lower == "send message" ||
               lower.startsWith("liked a message") ||
               lower.startsWith("reacted") ||
               lower.contains("sent an attachment") ||
               lower.contains("shared a post") ||
               lower.contains("shared a story") ||
               lower.contains("shared a reel") ||
               lower.contains("sent a photo") ||
               lower.contains("sent a video") ||
               lower.contains("sent a voice message") ||
               lower == "photo" ||
               lower == "video" ||
               lower == "reel" ||
               lower.matches(Regex("""\d+\s*(new )?(messages?|msgs?)""")) ||
               lower.length < 2
    }
}
