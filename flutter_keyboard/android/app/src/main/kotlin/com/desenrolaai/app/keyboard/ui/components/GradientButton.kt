package com.desenrolaai.app.keyboard.ui.components

import android.content.Context
import android.graphics.drawable.GradientDrawable
import android.util.TypedValue
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.TextView
import com.desenrolaai.app.keyboard.Theme

object GradientButton {

    fun create(
        context: Context,
        text: String,
        heightDp: Int = 40,
        textSizeSp: Float = 13f,
        cornerRadiusDp: Int = 20,
        onClick: () -> Unit
    ): TextView {
        val density = context.resources.displayMetrics.density

        val bg = GradientDrawable(
            GradientDrawable.Orientation.LEFT_RIGHT,
            Theme.gradientColors
        ).apply {
            cornerRadius = cornerRadiusDp * density
        }

        return TextView(context).apply {
            this.text = text
            setTextColor(0xFFFFFFFF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, textSizeSp)
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            background = bg
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                (heightDp * density).toInt()
            ).apply {
                setMargins(
                    (12 * density).toInt(), (4 * density).toInt(),
                    (12 * density).toInt(), (4 * density).toInt()
                )
            }
            setOnClickListener { onClick() }
        }
    }
}
