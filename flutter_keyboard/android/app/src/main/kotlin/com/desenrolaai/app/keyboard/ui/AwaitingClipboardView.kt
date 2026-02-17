package com.desenrolaai.app.keyboard.ui

import android.content.Context
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.util.TypedValue
import android.view.Gravity
import android.widget.*
import com.desenrolaai.app.keyboard.Theme
import com.desenrolaai.app.keyboard.data.ConversationContext
import com.desenrolaai.app.keyboard.data.availableObjectives
import com.desenrolaai.app.keyboard.data.availableTones
import com.desenrolaai.app.keyboard.ui.components.HeaderBar
import com.desenrolaai.app.keyboard.ui.components.PillButton

class AwaitingClipboardView(
    private val context: Context,
    private val container: FrameLayout,
    private val conversation: ConversationContext,
    private val selectedObjectiveIndex: Int,
    private val selectedToneIndex: Int,
    private val onBack: () -> Unit,
    private val onPaste: () -> Unit,
    private val onObjectiveTap: () -> Unit,
    private val onToneTap: () -> Unit,
    private val onSwitchKeyboard: () -> Unit,
    private val onScreenshot: () -> Unit,
    private val onStartConversation: () -> Unit
) {
    private val density = context.resources.displayMetrics.density

    fun render() {
        val root = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }

        // Header: back + "👤 matchName (platform)"
        val header = HeaderBar.create(
            context,
            "\uD83D\uDC64 ${conversation.matchName} (${conversation.platform})",
            showBack = true, onBack = onBack,
            showGlobe = true, onGlobe = onSwitchKeyboard
        )
        root.addView(header)

        // Pills row (objective + tone)
        val pillsRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding((12 * density).toInt(), (8 * density).toInt(), (12 * density).toInt(), (8 * density).toInt())
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }

        val obj = availableObjectives[selectedObjectiveIndex]
        val objectivePill = PillButton.create(context, "${obj.emoji} ${obj.title} ▾") { onObjectiveTap() }
        pillsRow.addView(objectivePill)

        val tone = availableTones[selectedToneIndex]
        val tonePill = PillButton.create(context, "${tone.emoji} ${tone.label} ▾") { onToneTap() }
        pillsRow.addView(tonePill)

        root.addView(pillsRow)

        // Paste box
        val pasteBox = FrameLayout(context).apply {
            val bg = GradientDrawable().apply {
                setColor(Theme.cardBg)
                cornerRadius = 12 * density
                setStroke((1 * density).toInt(), Theme.withAlpha(Theme.rose, 0.3f))
            }
            background = bg
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, (48 * density).toInt()
            ).apply {
                setMargins((16 * density).toInt(), (12 * density).toInt(), (16 * density).toInt(), (8 * density).toInt())
            }
            setOnClickListener { onPaste() }
        }

        val pasteContent = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }

        val clipIcon = TextView(context).apply {
            text = "\uD83D\uDCCB"  // 📋
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
            setPadding(0, 0, (8 * density).toInt(), 0)
        }
        pasteContent.addView(clipIcon)

        val pasteLabel = TextView(context).apply {
            text = "Cole a mensagem dela aqui"
            setTextColor(Theme.textSecondary)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
        }
        pasteContent.addView(pasteLabel)

        pasteBox.addView(pasteContent)
        root.addView(pasteBox)

        // Hint
        val hint = TextView(context).apply {
            text = "Copie a mensagem no app de conversa e toque aqui"
            setTextColor(Theme.textSecondary)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                topMargin = (8 * density).toInt()
            }
        }
        root.addView(hint)

        // Divider
        val divider = android.view.View(context).apply {
            setBackgroundColor(Theme.withAlpha(Theme.textSecondary, 0.2f))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, (1 * density).toInt()
            ).apply {
                setMargins((16 * density).toInt(), (8 * density).toInt(), (16 * density).toInt(), (8 * density).toInt())
            }
        }
        root.addView(divider)

        // Links row
        val linksRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }

        val screenshotLink = TextView(context).apply {
            text = "\uD83D\uDCF8 Analisar Screenshot"
            setTextColor(Theme.rose)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            setPadding((12 * density).toInt(), (6 * density).toInt(), (12 * density).toInt(), (6 * density).toInt())
            setOnClickListener { onScreenshot() }
        }
        linksRow.addView(screenshotLink)

        val startConvLink = TextView(context).apply {
            text = "\uD83D\uDE80 Iniciar Conversa"
            setTextColor(Theme.rose)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            setPadding((12 * density).toInt(), (6 * density).toInt(), (12 * density).toInt(), (6 * density).toInt())
            setOnClickListener { onStartConversation() }
        }
        linksRow.addView(startConvLink)

        root.addView(linksRow)

        container.addView(root)
    }
}
