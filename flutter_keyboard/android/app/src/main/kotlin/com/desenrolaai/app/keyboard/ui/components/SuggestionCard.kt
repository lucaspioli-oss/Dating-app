package com.desenrolaai.app.keyboard.ui.components

import android.content.Context
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.util.TypedValue
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.TextView
import com.desenrolaai.app.keyboard.Theme

object SuggestionCard {

    fun create(
        context: Context,
        text: String,
        onEdit: (() -> Unit)? = null,
        onClick: () -> Unit
    ): LinearLayout {
        val density = context.resources.displayMetrics.density

        val bg = GradientDrawable().apply {
            setColor(Theme.suggestionBg)
            cornerRadius = 12 * density
            setStroke((0.5f * density).toInt(), Theme.withAlpha(Theme.rose, 0.2f))
        }

        val card = LinearLayout(context).apply {
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
                setMargins(
                    (12 * density).toInt(), (3 * density).toInt(),
                    (12 * density).toInt(), (3 * density).toInt()
                )
            }
            setOnClickListener { onClick() }
        }

        // Text
        val textView = TextView(context).apply {
            this.text = text
            setTextColor(0xFFFFFFFF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            maxLines = 4
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        }
        card.addView(textView)

        // Edit button (pencil icon)
        if (onEdit != null) {
            val editBtn = TextView(context).apply {
                this.text = "\u270F"
                setTextColor(Theme.orange)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(
                    (32 * density).toInt(), (36 * density).toInt()
                )
                setOnClickListener { onEdit() }
            }
            card.addView(editBtn)
        }

        // Send button (arrow icon as text)
        val sendBtn = TextView(context).apply {
            this.text = "➤"
            setTextColor(Theme.rose)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                (36 * density).toInt(),
                (36 * density).toInt()
            )
        }
        card.addView(sendBtn)

        return card
    }
}
