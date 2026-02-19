package com.desenrolaai.app.keyboard.accessibility.parsers

import android.graphics.Rect
import android.view.accessibility.AccessibilityNodeInfo
import com.desenrolaai.app.keyboard.accessibility.AppMessageParser
import com.desenrolaai.app.keyboard.accessibility.NodeTreeHelper
import com.desenrolaai.app.keyboard.accessibility.ParsedConversation
import com.desenrolaai.app.keyboard.accessibility.ParsedMessage

class BumbleParser : AppMessageParser {

    companion object {
        private const val PLATFORM = "bumble"
        private const val MAX_MESSAGES = 30

        // Bumble may use Jetpack Compose, which exposes content descriptions
        // instead of standard resource IDs. The toolbar region is typically
        // in the upper ~12% of the screen.
        private const val TOOLBAR_MAX_Y_FRACTION = 0.12
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
     * Bumble may use Compose, so contact name might appear as:
     * 1. A content-description on a header/toolbar node
     * 2. A text node in the toolbar area
     * 3. A text node in the top portion of the screen
     */
    private fun findContactName(root: AccessibilityNodeInfo, screenHeight: Int): String? {
        // Strategy 1: Toolbar text
        val toolbarName = findTextInToolbar(root, 0)
        if (toolbarName != null) return toolbarName

        // Strategy 2: Content description in top region (Compose puts text there)
        val maxY = (screenHeight * TOOLBAR_MAX_Y_FRACTION).toInt()
        val descName = findContentDescriptionInRegion(root, maxY)
        if (descName != null) return descName

        // Strategy 3: Any text in top region
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

        // Check text first
        val text = node.text?.toString()?.trim()
        if (!text.isNullOrEmpty() && text.length >= 2 && !isSystemText(text)) {
            val isOutgoing = NodeTreeHelper.isRightAligned(node, screenWidth)
            messages.add(ParsedMessage(text = text, isFromUser = isOutgoing))
            return // Avoid recursing to prevent duplicates
        }

        // For Compose: check content description as fallback for message content
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
            className.contains("ScrollView") ||
            className.contains("LazyColumn", ignoreCase = true)
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
               lower == "write a message" ||
               lower == "write a message..." ||
               lower.startsWith("you matched") ||
               lower.contains("made the first move") ||
               lower.contains("has expired") ||
               lower.contains("extend") ||
               lower.matches(Regex("""\d+\s*(new )?(messages?|msgs?)""")) ||
               lower.matches(Regex("""\d+h\s*left""")) ||
               lower.length < 2
    }
}
