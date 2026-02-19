package com.desenrolaai.app.keyboard.accessibility.parsers

import android.graphics.Rect
import android.view.accessibility.AccessibilityNodeInfo
import com.desenrolaai.app.keyboard.accessibility.AppMessageParser
import com.desenrolaai.app.keyboard.accessibility.NodeTreeHelper
import com.desenrolaai.app.keyboard.accessibility.ParsedConversation
import com.desenrolaai.app.keyboard.accessibility.ParsedMessage

class HingeParser : AppMessageParser {

    companion object {
        private const val PLATFORM = "hinge"
        private const val MAX_MESSAGES = 30

        // Hinge header is typically in the top ~12% of screen
        private const val HEADER_MAX_Y_FRACTION = 0.12
    }

    override fun parse(rootNode: AccessibilityNodeInfo, eventType: Int): ParsedConversation? {
        return try {
            val screenWidth = getScreenWidth(rootNode)
            val screenHeight = getScreenHeight(rootNode)

            val contactName = findContactName(rootNode, screenHeight) ?: return null
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
     * Hinge shows the contact name in a header at the top of the chat screen.
     * We search for it using toolbar detection first, then fall back to
     * positional heuristics in the top region of the screen.
     */
    private fun findContactName(root: AccessibilityNodeInfo, screenHeight: Int): String? {
        // Strategy 1: Look in toolbar/action bar
        val toolbarName = findTextInToolbar(root, 0)
        if (toolbarName != null) return toolbarName

        // Strategy 2: Content description in header region
        val maxY = (screenHeight * HEADER_MAX_Y_FRACTION).toInt()
        val descName = findContentDescriptionInRegion(root, maxY)
        if (descName != null) return descName

        // Strategy 3: First text in header region
        return findFirstTextInRegion(root, maxY)
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

    private fun findContentDescriptionInRegion(
        node: AccessibilityNodeInfo,
        maxY: Int
    ): String? {
        val rect = Rect()
        node.getBoundsInScreen(rect)
        if (rect.top > maxY) return null

        val desc = node.contentDescription?.toString()?.trim()
        if (!desc.isNullOrEmpty() && desc.length >= 2 && !isSystemText(desc) && isLikelyName(desc)) {
            return desc
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val result = findContentDescriptionInRegion(child, maxY)
            if (result != null) return result
        }
        return null
    }

    private fun findFirstTextInRegion(node: AccessibilityNodeInfo, maxY: Int): String? {
        val rect = Rect()
        node.getBoundsInScreen(rect)
        if (rect.top > maxY) return null

        val text = node.text?.toString()?.trim()
        if (!text.isNullOrEmpty() && text.length >= 2 && !isSystemText(text) && isLikelyName(text)) {
            return text
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val result = findFirstTextInRegion(child, maxY)
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
        val scrollable = findScrollableContainer(root) ?: return emptyList()
        val messages = mutableListOf<ParsedMessage>()
        collectTextNodes(scrollable, messages, screenWidth, 0)
        return messages
    }

    private fun collectTextNodes(
        node: AccessibilityNodeInfo,
        messages: MutableList<ParsedMessage>,
        screenWidth: Int,
        depth: Int
    ) {
        if (depth > 20) return

        val text = node.text?.toString()?.trim()
        if (!text.isNullOrEmpty() && text.length >= 2 && !isSystemText(text)) {
            val isOutgoing = NodeTreeHelper.isRightAligned(node, screenWidth)
            messages.add(ParsedMessage(text = text, isFromUser = isOutgoing))
            return
        }

        // Also check content description for Compose-based layouts
        val desc = node.contentDescription?.toString()?.trim()
        if (!desc.isNullOrEmpty() && desc.length >= 2 && !isSystemText(desc) && !isLikelyName(desc)) {
            val isOutgoing = NodeTreeHelper.isRightAligned(node, screenWidth)
            messages.add(ParsedMessage(text = desc, isFromUser = isOutgoing))
            return
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            try {
                collectTextNodes(child, messages, screenWidth, depth + 1)
            } catch (_: Exception) {
                // Stale node
            }
        }
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

    private fun getScreenHeight(root: AccessibilityNodeInfo): Int {
        val rect = Rect()
        root.getBoundsInScreen(rect)
        return if (rect.height() > 0) rect.height() else 2400
    }

    private fun isLikelyName(text: String): Boolean {
        val words = text.split("\\s+".toRegex())
        if (words.size > 5) return false
        if (words.isEmpty()) return false
        val first = words.first()
        if (first.isEmpty() || !first[0].isUpperCase()) return false
        val digitRatio = text.count { it.isDigit() }.toFloat() / text.length
        return digitRatio < 0.3
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
               lower == "type a message" ||
               lower == "type a message..." ||
               lower == "send a message" ||
               lower.startsWith("you matched") ||
               lower.contains("liked your") ||
               lower.contains("commented on your") ||
               lower.contains("invited you") ||
               lower == "your turn" ||
               lower.contains("rose") ||
               lower.matches(Regex("""\d+\s*(new )?(messages?|msgs?)""")) ||
               lower.length < 2
    }
}
