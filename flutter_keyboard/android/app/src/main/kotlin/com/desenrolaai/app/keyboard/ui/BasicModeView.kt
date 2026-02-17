package com.desenrolaai.app.keyboard.ui

import android.content.Context
import android.graphics.Typeface
import android.util.TypedValue
import android.view.Gravity
import android.widget.*
import com.desenrolaai.app.keyboard.Theme
import com.desenrolaai.app.keyboard.data.availableObjectives
import com.desenrolaai.app.keyboard.data.availableTones
import com.desenrolaai.app.keyboard.ui.components.GradientButton
import com.desenrolaai.app.keyboard.ui.components.HeaderBar
import com.desenrolaai.app.keyboard.ui.components.PillButton
import com.desenrolaai.app.keyboard.ui.components.SuggestionCard

class BasicModeView(
    private val context: Context,
    private val container: FrameLayout,
    private val clipboardText: String?,
    private val suggestions: List<String>,
    private val isLoading: Boolean,
    private val selectedObjectiveIndex: Int,
    private val selectedToneIndex: Int,
    private val hasAuth: Boolean,
    private val onPaste: () -> Unit,
    private val onGenerate: () -> Unit,
    private val onSuggestionTap: (String) -> Unit,
    private val onRegenerate: () -> Unit,
    private val onObjectiveTap: () -> Unit,
    private val onToneTap: () -> Unit,
    private val onBack: () -> Unit,
    private val onSwitchKeyboard: () -> Unit
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

        // Header
        val header = HeaderBar.create(
            context, "⚡ Modo Rápido",
            showBack = hasAuth, onBack = { onBack() },
            showGlobe = true, onGlobe = onSwitchKeyboard
        )
        root.addView(header)

        // Clipboard text preview
        if (!clipboardText.isNullOrEmpty()) {
            val preview = clipboardText.take(80)
            val clipPreview = TextView(context).apply {
                text = "\uD83D\uDCCB $preview"
                setTextColor(Theme.clipText)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
                maxLines = 2
                setPadding((16 * density).toInt(), (2 * density).toInt(), (16 * density).toInt(), (2 * density).toInt())
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
            }
            root.addView(clipPreview)
        }

        if (clipboardText.isNullOrEmpty()) {
            // No clipboard - show paste instruction
            val pasteLabel = TextView(context).apply {
                text = "\uD83D\uDCCB Copie uma mensagem primeiro"
                setTextColor(Theme.textSecondary)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f
                )
            }
            root.addView(pasteLabel)

            // Pills
            root.addView(makePillsRow())

            // Paste button
            val pasteBtn = GradientButton.create(context, "\uD83D\uDCCB Colar Mensagem", heightDp = 40) { onPaste() }
            root.addView(pasteBtn)

        } else if (isLoading) {
            // Loading
            root.addView(makePillsRow())

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

        } else if (suggestions.isEmpty()) {
            // Has clipboard but no suggestions yet
            root.addView(makePillsRow())

            val genBtn = GradientButton.create(context, "✨ Sugerir Resposta", heightDp = 40) { onGenerate() }
            root.addView(genBtn)

            // Spacer
            root.addView(android.view.View(context).apply {
                layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f)
            })

        } else {
            // Suggestions available
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

            // Bottom bar: regenerate + pills
            val toolbar = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                setPadding((12 * density).toInt(), (4 * density).toInt(), (12 * density).toInt(), (6 * density).toInt())
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
            }

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

            toolbar.addView(android.view.View(context).apply {
                layoutParams = LinearLayout.LayoutParams(0, 0, 1f)
            })

            val obj = availableObjectives[selectedObjectiveIndex]
            toolbar.addView(PillButton.create(context, "${obj.emoji} ▾", compact = true) { onObjectiveTap() })

            val tone = availableTones[selectedToneIndex]
            toolbar.addView(PillButton.create(context, "${tone.emoji} ▾", compact = true) { onToneTap() })

            root.addView(toolbar)
        }

        container.addView(root)
    }

    private fun makePillsRow(): LinearLayout {
        val pillsRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding((12 * density).toInt(), (4 * density).toInt(), (12 * density).toInt(), (4 * density).toInt())
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }

        val obj = availableObjectives[selectedObjectiveIndex]
        pillsRow.addView(PillButton.create(context, "${obj.emoji} ${obj.title} ▾") { onObjectiveTap() })

        val tone = availableTones[selectedToneIndex]
        pillsRow.addView(PillButton.create(context, "${tone.emoji} ${tone.label} ▾") { onToneTap() })

        return pillsRow
    }
}
