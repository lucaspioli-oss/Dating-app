package com.desenrolaai.app.keyboard.ui.components

import android.content.Context
import android.graphics.drawable.GradientDrawable
import android.util.TypedValue
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.TextView
import com.desenrolaai.app.keyboard.Theme

object PillButton {

    fun create(
        context: Context,
        text: String,
        compact: Boolean = false,
        onClick: () -> Unit
    ): TextView {
        val density = context.resources.displayMetrics.density
        val heightDp = if (compact) 24 else 28

        val bg = GradientDrawable().apply {
            setColor(Theme.cardBg)
            cornerRadius = (heightDp / 2f) * density
            setStroke((0.5f * density).toInt(), Theme.withAlpha(Theme.rose, 0.3f))
        }

        return TextView(context).apply {
            this.text = text
            setTextColor(0xFFFFFFFF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, if (compact) 11f else 12f)
            gravity = Gravity.CENTER
            background = bg
            setPadding(
                (10 * density).toInt(), 0,
                (10 * density).toInt(), 0
            )
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                (heightDp * density).toInt()
            ).apply {
                setMargins((4 * density).toInt(), 0, (4 * density).toInt(), 0)
            }
            setOnClickListener { onClick() }
        }
    }
}
