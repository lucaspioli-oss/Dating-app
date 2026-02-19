package com.desenrolaai.app.keyboard.accessibility

import android.graphics.Rect
import android.util.Log
import android.view.accessibility.AccessibilityNodeInfo
import android.content.pm.ApplicationInfo

object NodeTreeHelper {

    /**
     * Finds a single node by its fully-qualified resource ID
     * (e.g. "com.whatsapp:id/conversation_contact_name").
     * Returns the first match or null.
     */
    fun findByResourceId(
        root: AccessibilityNodeInfo,
        resourceId: String
    ): AccessibilityNodeInfo? {
        val nodes = root.findAccessibilityNodeInfosByViewId(resourceId)
        return nodes?.firstOrNull()
    }

    /**
     * Finds all nodes whose text or content-description contains [text].
     */
    fun findByText(
        root: AccessibilityNodeInfo,
        text: String
    ): List<AccessibilityNodeInfo> {
        return root.findAccessibilityNodeInfosByText(text) ?: emptyList()
    }

    /**
     * Recursively extracts all text (text + contentDescription) from a node
     * and its entire subtree, concatenated with spaces.
     */
    fun extractAllText(node: AccessibilityNodeInfo): String {
        val builder = StringBuilder()
        extractAllTextRecursive(node, builder)
        return builder.toString().trim()
    }

    private fun extractAllTextRecursive(
        node: AccessibilityNodeInfo,
        builder: StringBuilder
    ) {
        node.text?.let {
            if (it.isNotEmpty()) {
                if (builder.isNotEmpty()) builder.append(" ")
                builder.append(it)
            }
        }
        node.contentDescription?.let {
            if (it.isNotEmpty()) {
                if (builder.isNotEmpty()) builder.append(" ")
                builder.append(it)
            }
        }
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            extractAllTextRecursive(child, builder)
        }
    }

    /**
     * Returns true if the horizontal center of [node] is past the midpoint
     * of the screen, indicating a right-aligned (sent) message bubble.
     */
    fun isRightAligned(node: AccessibilityNodeInfo, screenWidth: Int): Boolean {
        val rect = Rect()
        node.getBoundsInScreen(rect)
        val centerX = (rect.left + rect.right) / 2
        return centerX > screenWidth / 2
    }

    /**
     * Debug helper: logs the entire accessibility node tree starting from [node].
     * Only runs in debug builds to avoid leaking conversation data in production.
     */
    fun dumpTree(
        node: AccessibilityNodeInfo,
        depth: Int = 0,
        tag: String = "A11yDump"
    ) {
        // Only dump in debug builds
        return

        val indent = " ".repeat(depth * 2)
        val rect = Rect()
        node.getBoundsInScreen(rect)

        Log.d(
            tag,
            "${indent}[${node.className}] " +
                "text=\"${node.text}\" " +
                "desc=\"${node.contentDescription}\" " +
                "id=${node.viewIdResourceName} " +
                "bounds=$rect"
        )

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            dumpTree(child, depth + 1, tag)
        }
    }
}
