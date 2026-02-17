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

class StartConversationView(
    private val context: Context,
    private val container: FrameLayout,
    private val conversation: ConversationContext?,
    private val suggestions: List<String>,
    private val isLoading: Boolean,
    private val selectedObjectiveIndex: Int,
    private val selectedToneIndex: Int,
    private val onSuggestionTap: (String) -> Unit,
    private val onWriteOwn: () -> Unit,
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

        val matchName = conversation?.matchName ?: ""

        // Header: back + "rocket matchName" + pills + globe
        val headerRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding((10 * density).toInt(), (6 * density).toInt(), (10 * density).toInt(), (4 * density).toInt())
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }

        // Back button
        val backBtn = TextView(context).apply {
            text = "\u2190"
            setTextColor(Theme.rose)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
            typeface = Typeface.DEFAULT_BOLD
            setPadding((4 * density).toInt(), 0, (8 * density).toInt(), 0)
            setOnClickListener { onBack() }
        }
        headerRow.addView(backBtn)

        // Title
        val titleLabel = TextView(context).apply {
            text = "\uD83D\uDE80 $matchName"
            setTextColor(0xFFFFFFFF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            typeface = Typeface.DEFAULT_BOLD
        }
        headerRow.addView(titleLabel)

        // Objective pill
        val obj = availableObjectives[selectedObjectiveIndex]
        val objPill = PillButton.create(context, "${obj.emoji} \u25BE", compact = true) { onObjectiveTap() }
        headerRow.addView(objPill)

        // Tone pill
        val tone = availableTones[selectedToneIndex]
        val tonePill = PillButton.create(context, "${tone.emoji} \u25BE", compact = true) { onToneTap() }
        headerRow.addView(tonePill)

        // Spacer
        headerRow.addView(android.view.View(context).apply {
            layoutParams = LinearLayout.LayoutParams(0, 0, 1f)
        })

        // Globe
        val globeBtn = TextView(context).apply {
            text = "\uD83C\uDF10"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            setOnClickListener { onSwitchKeyboard() }
        }
        headerRow.addView(globeBtn)

        root.addView(headerRow)

        if (isLoading && suggestions.isEmpty()) {
            // Loading state
            val loadingLayout = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f
                )
            }

            val spinner = ProgressBar(context).apply {
                layoutParams = LinearLayout.LayoutParams(
                    (28 * density).toInt(), (28 * density).toInt()
                ).apply { gravity = Gravity.CENTER_HORIZONTAL; bottomMargin = (12 * density).toInt() }
            }
            loadingLayout.addView(spinner)

            val loadLabel = TextView(context).apply {
                text = "Gerando aberturas..."
                setTextColor(Theme.textSecondary)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                gravity = Gravity.CENTER
            }
            loadingLayout.addView(loadLabel)

            root.addView(loadingLayout)
        } else if (suggestions.isNotEmpty()) {
            // Suggestions
            val scroll = ScrollView(context).apply {
                isVerticalScrollBarEnabled = true
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f
                )
            }
            val cardColumn = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                setPadding((10 * density).toInt(), (4 * density).toInt(), (10 * density).toInt(), (4 * density).toInt())
            }

            for ((index, suggestion) in suggestions.withIndex()) {
                val card = makeStartConvCard(index, suggestion)
                cardColumn.addView(card)
            }

            scroll.addView(cardColumn)
            root.addView(scroll)

            // Bottom bar
            val toolbar = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                setPadding((10 * density).toInt(), (4 * density).toInt(), (10 * density).toInt(), (6 * density).toInt())
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
            }

            // Write-own bar
            val writeBar = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                val bg = GradientDrawable().apply {
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
            writeBar.addView(TextView(context).apply {
                text = "\u270E"
                setTextColor(Theme.textSecondary)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
                setPadding(0, 0, (4 * density).toInt(), 0)
            })
            writeBar.addView(TextView(context).apply {
                text = "Escrever"
                setTextColor(Theme.textSecondary)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
            })
            toolbar.addView(writeBar)

            // Regen button
            val regenBtn = TextView(context).apply {
                text = "\u21BB"
                setTextColor(0xFFFFFFFF.toInt())
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
                typeface = Typeface.DEFAULT_BOLD
                gravity = Gravity.CENTER
                val bg = GradientDrawable().apply {
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

            // Compact pills in toolbar
            val objPillBottom = PillButton.create(context, "${obj.emoji} \u25BE", compact = true) { onObjectiveTap() }
            toolbar.addView(objPillBottom)
            val tonePillBottom = PillButton.create(context, "${tone.emoji} \u25BE", compact = true) { onToneTap() }
            toolbar.addView(tonePillBottom)

            root.addView(toolbar)
        }

        container.addView(root)
    }

    private fun makeStartConvCard(index: Int, text: String): LinearLayout {
        val bg = GradientDrawable().apply {
            setColor(Theme.suggestionBg)
            cornerRadius = 12 * density
            setStroke((0.5f * density).toInt(), Theme.withAlpha(Theme.rose, 0.2f))
        }

        return LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            background = bg
            setPadding(
                (12 * density).toInt(), (10 * density).toInt(),
                (8 * density).toInt(), (10 * density).toInt()
            )
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = (6 * density).toInt()
            }
            setOnClickListener { onSuggestionTap(text) }

            // Number
            addView(TextView(context).apply {
                this.text = "${index + 1}."
                setTextColor(Theme.rose)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                typeface = Typeface.DEFAULT_BOLD
                setPadding(0, 0, (6 * density).toInt(), 0)
            })

            // Text
            addView(TextView(context).apply {
                this.text = text
                setTextColor(0xFFFFFFFF.toInt())
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                maxLines = 4
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            })

            // Send button
            addView(TextView(context).apply {
                this.text = "\u27A4"
                setTextColor(Theme.rose)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
                typeface = Typeface.DEFAULT_BOLD
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(
                    (36 * density).toInt(), (36 * density).toInt()
                )
            })
        }
    }
}
