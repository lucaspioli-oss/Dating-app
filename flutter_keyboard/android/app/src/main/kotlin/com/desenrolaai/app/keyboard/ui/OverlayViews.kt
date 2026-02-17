package com.desenrolaai.app.keyboard.ui

import android.content.Context
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.util.TypedValue
import android.view.Gravity
import android.widget.*
import com.desenrolaai.app.keyboard.Theme
import com.desenrolaai.app.keyboard.data.Objective
import com.desenrolaai.app.keyboard.data.Tone
import com.desenrolaai.app.keyboard.data.availableObjectives
import com.desenrolaai.app.keyboard.data.availableTones

object OverlayViews {

    fun showObjectiveOverlay(
        context: Context,
        container: FrameLayout,
        selectedIndex: Int,
        onSelect: (Int) -> Unit,
        onClose: () -> Unit
    ) {
        val density = context.resources.displayMetrics.density

        val overlay = FrameLayout(context).apply {
            setBackgroundColor(Theme.overlayBg)
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
            // Block clicks from passing through
            setOnClickListener { }
        }

        val root = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding((12 * density).toInt(), (8 * density).toInt(), (12 * density).toInt(), (8 * density).toInt())
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }

        // Title row
        val titleRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }
        val title = TextView(context).apply {
            text = "Escolha um Objetivo"
            setTextColor(0xFFFFFFFF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            typeface = Typeface.DEFAULT_BOLD
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        }
        titleRow.addView(title)
        val closeBtn = TextView(context).apply {
            text = "✕"
            setTextColor(Theme.textSecondary)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            setPadding((8 * density).toInt(), 0, 0, 0)
            setOnClickListener { onClose() }
        }
        titleRow.addView(closeBtn)
        root.addView(titleRow)

        // Scrollable list
        val scroll = ScrollView(context).apply {
            isVerticalScrollBarEnabled = false
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f
            )
        }
        val list = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(0, (4 * density).toInt(), 0, 0)
        }

        for ((index, obj) in availableObjectives.withIndex()) {
            val isSelected = index == selectedIndex
            val card = makeObjectiveCard(context, obj, isSelected, density) {
                onSelect(index)
            }
            list.addView(card)
        }

        scroll.addView(list)
        root.addView(scroll)
        overlay.addView(root)
        container.addView(overlay)
    }

    fun showToneOverlay(
        context: Context,
        container: FrameLayout,
        selectedIndex: Int,
        onSelect: (Int) -> Unit,
        onClose: () -> Unit
    ) {
        val density = context.resources.displayMetrics.density

        val overlay = FrameLayout(context).apply {
            setBackgroundColor(Theme.overlayBg)
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
            setOnClickListener { }
        }

        val root = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding((12 * density).toInt(), (8 * density).toInt(), (12 * density).toInt(), (8 * density).toInt())
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }

        // Title row
        val titleRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }
        val title = TextView(context).apply {
            text = "Escolha o Tom"
            setTextColor(0xFFFFFFFF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            typeface = Typeface.DEFAULT_BOLD
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        }
        titleRow.addView(title)
        val closeBtn = TextView(context).apply {
            text = "✕"
            setTextColor(Theme.textSecondary)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            setPadding((8 * density).toInt(), 0, 0, 0)
            setOnClickListener { onClose() }
        }
        titleRow.addView(closeBtn)
        root.addView(titleRow)

        // Tone cards
        val scroll = ScrollView(context).apply {
            isVerticalScrollBarEnabled = false
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f
            )
        }
        val list = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(0, (8 * density).toInt(), 0, 0)
        }

        for ((index, tone) in availableTones.withIndex()) {
            val isSelected = index == selectedIndex
            val label = if (index == 0) "${tone.emoji} ${tone.label} (Recomendado)" else "${tone.emoji} ${tone.label}"
            val card = makeToneCard(context, label, isSelected, density) {
                onSelect(index)
            }
            list.addView(card)
        }

        scroll.addView(list)
        root.addView(scroll)
        overlay.addView(root)
        container.addView(overlay)
    }

    private fun makeObjectiveCard(
        context: Context,
        obj: Objective,
        isSelected: Boolean,
        density: Float,
        onClick: () -> Unit
    ): LinearLayout {
        val bgColor = if (isSelected) Theme.selectedBg else Theme.cardBg
        val borderColor = if (isSelected) Theme.rose else 0x00000000

        val bg = GradientDrawable().apply {
            setColor(bgColor)
            cornerRadius = 8 * density
            if (isSelected) setStroke((1 * density).toInt(), borderColor)
        }

        return LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            background = bg
            setPadding((10 * density).toInt(), (6 * density).toInt(), (10 * density).toInt(), (6 * density).toInt())
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, (62 * density).toInt()
            ).apply {
                bottomMargin = (3 * density).toInt()
            }
            setOnClickListener { onClick() }

            // Emoji
            addView(TextView(context).apply {
                text = obj.emoji
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
                gravity = Gravity.CENTER
                setPadding(0, 0, (8 * density).toInt(), 0)
            })

            // Title + description column (centered)
            val textCol = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER_VERTICAL
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.MATCH_PARENT, 1f)
            }
            textCol.addView(TextView(context).apply {
                text = obj.title
                setTextColor(0xFFFFFFFF.toInt())
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
                typeface = Typeface.DEFAULT_BOLD
                gravity = Gravity.CENTER
            })
            textCol.addView(TextView(context).apply {
                text = obj.description
                setTextColor(Theme.textSecondary)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 10f)
                gravity = Gravity.CENTER
            })
            addView(textCol)

            // Checkmark
            if (isSelected) {
                addView(TextView(context).apply {
                    text = "✓"
                    setTextColor(Theme.rose)
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
                    typeface = Typeface.DEFAULT_BOLD
                })
            }
        }
    }

    private fun makeToneCard(
        context: Context,
        label: String,
        isSelected: Boolean,
        density: Float,
        onClick: () -> Unit
    ): LinearLayout {
        val bgColor = if (isSelected) Theme.selectedBg else Theme.cardBg
        val borderColor = if (isSelected) Theme.orange else 0x00000000

        val bg = GradientDrawable().apply {
            setColor(bgColor)
            cornerRadius = 8 * density
            if (isSelected) setStroke((1 * density).toInt(), borderColor)
        }

        return LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            background = bg
            setPadding((12 * density).toInt(), (8 * density).toInt(), (12 * density).toInt(), (8 * density).toInt())
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, (36 * density).toInt()
            ).apply {
                bottomMargin = (3 * density).toInt()
            }
            setOnClickListener { onClick() }

            addView(TextView(context).apply {
                text = label
                setTextColor(0xFFFFFFFF.toInt())
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            })

            if (isSelected) {
                addView(TextView(context).apply {
                    text = "✓"
                    setTextColor(Theme.orange)
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
                    typeface = Typeface.DEFAULT_BOLD
                })
            }
        }
    }
}
