package com.desenrolaai.app.keyboard.ui

import android.content.Context
import android.graphics.Typeface
import android.util.TypedValue
import android.view.Gravity
import android.widget.*
import com.desenrolaai.app.keyboard.Theme
import com.desenrolaai.app.keyboard.data.ConversationContext
import com.desenrolaai.app.keyboard.data.availableObjectives
import com.desenrolaai.app.keyboard.data.availableTones
import com.desenrolaai.app.keyboard.ui.components.PillButton
import com.desenrolaai.app.keyboard.ui.components.SuggestionCard

class SuggestionsView(
    private val context: Context,
    private val container: FrameLayout,
    private val conversation: ConversationContext?,
    private val clipboardText: String?,
    private val suggestions: List<String>,
    private val isLoading: Boolean,
    private val selectedObjectiveIndex: Int,
    private val selectedToneIndex: Int,
    private val onSuggestionTap: (String) -> Unit,
    private val onWriteOwn: () -> Unit,
    private val onRegenerate: () -> Unit,
    private val onObjectiveTap: () -> Unit,
    private val onToneTap: () -> Unit,
    private val onBack: () -> Unit
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

        // Compact header: "👤 matchName"
        val matchName = conversation?.matchName ?: "Modo Rápido"
        val headerRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding((12 * density).toInt(), (4 * density).toInt(), (12 * density).toInt(), 0)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }

        val headerLabel = TextView(context).apply {
            text = "\uD83D\uDC64 $matchName"
            setTextColor(0xFFFFFFFF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            typeface = Typeface.DEFAULT_BOLD
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        }
        headerRow.addView(headerLabel)

        // Clipboard preview
        if (clipboardText != null) {
            val preview = clipboardText.take(50)
            val clipLabel = TextView(context).apply {
                text = "\uD83D\uDCAC \"$preview\""
                setTextColor(Theme.clipText)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 10f)
                maxLines = 1
            }
            headerRow.addView(clipLabel)
        }
        root.addView(headerRow)

        // Loading or suggestions
        if (isLoading) {
            val loadingRow = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f
                )
            }
            val spinner = ProgressBar(context).apply {
                layoutParams = LinearLayout.LayoutParams((20 * density).toInt(), (20 * density).toInt())
            }
            loadingRow.addView(spinner)
            val loadLabel = TextView(context).apply {
                text = "  Gerando sugestões..."
                setTextColor(Theme.textSecondary)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            }
            loadingRow.addView(loadLabel)
            root.addView(loadingRow)
        } else {
            // Scrollable suggestions
            val scroll = ScrollView(context).apply {
                isVerticalScrollBarEnabled = false
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f
                )
            }
            val cardColumn = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(0, (4 * density).toInt(), 0, (4 * density).toInt())
            }

            for (suggestion in suggestions) {
                val card = SuggestionCard.create(context, suggestion) {
                    onSuggestionTap(suggestion)
                }
                cardColumn.addView(card)
            }

            scroll.addView(cardColumn)
            root.addView(scroll)
        }

        // Bottom toolbar
        val toolbar = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding((12 * density).toInt(), (4 * density).toInt(), (12 * density).toInt(), (6 * density).toInt())
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }

        // Back button
        val backBtn = TextView(context).apply {
            text = "←"
            setTextColor(Theme.rose)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            typeface = Typeface.DEFAULT_BOLD
            setPadding(0, 0, (8 * density).toInt(), 0)
            setOnClickListener { onBack() }
        }
        toolbar.addView(backBtn)

        // Styled write-own input bar
        val writeBar = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            val bg = android.graphics.drawable.GradientDrawable().apply {
                setColor(Theme.cardBg)
                cornerRadius = 8 * density
                setStroke((0.5 * density).toInt(), Theme.roseAlpha30)
            }
            background = bg
            setPadding((8 * density).toInt(), (4 * density).toInt(), (8 * density).toInt(), (4 * density).toInt())
            layoutParams = LinearLayout.LayoutParams(0, (28 * density).toInt(), 1f).apply {
                marginEnd = (6 * density).toInt()
            }
            setOnClickListener { onWriteOwn() }
        }
        val writeIcon = TextView(context).apply {
            text = "✎"
            setTextColor(Theme.textSecondary)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
            setPadding(0, 0, (4 * density).toInt(), 0)
        }
        writeBar.addView(writeIcon)
        val writeLabel = TextView(context).apply {
            text = "Escrever resposta..."
            setTextColor(Theme.textSecondary)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
        }
        writeBar.addView(writeLabel)
        toolbar.addView(writeBar)

        // Styled regenerate button
        val regenBtn = TextView(context).apply {
            text = "↻"
            setTextColor(0xFFFFFFFF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            val bg = android.graphics.drawable.GradientDrawable().apply {
                setColor(Theme.roseAlpha25)
                cornerRadius = 8 * density
            }
            background = bg
            layoutParams = LinearLayout.LayoutParams((32 * density).toInt(), (28 * density).toInt()).apply {
                marginEnd = (6 * density).toInt()
            }
            setOnClickListener { onRegenerate() }
        }
        toolbar.addView(regenBtn)

        // Compact pills
        val obj = availableObjectives[selectedObjectiveIndex]
        val objPill = PillButton.create(context, "${obj.emoji} ▾", compact = true) { onObjectiveTap() }
        toolbar.addView(objPill)

        val tone = availableTones[selectedToneIndex]
        val tonePill = PillButton.create(context, "${tone.emoji} ▾", compact = true) { onToneTap() }
        toolbar.addView(tonePill)

        root.addView(toolbar)
        container.addView(root)
    }
}
