package com.desenrolaai.app.keyboard.ui.components

import android.content.Context
import android.graphics.Typeface
import android.util.TypedValue
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.TextView
import com.desenrolaai.app.keyboard.Theme

object HeaderBar {

    fun create(
        context: Context,
        title: String,
        showBack: Boolean = false,
        onBack: (() -> Unit)? = null,
        showGlobe: Boolean = false,
        onGlobe: (() -> Unit)? = null
    ): LinearLayout {
        val density = context.resources.displayMetrics.density

        val header = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(
                (12 * density).toInt(), (6 * density).toInt(),
                (12 * density).toInt(), (4 * density).toInt()
            )
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }

        if (showBack && onBack != null) {
            val backBtn = TextView(context).apply {
                text = "←"
                setTextColor(Theme.rose)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
                typeface = Typeface.DEFAULT_BOLD
                setPadding((4 * density).toInt(), 0, (8 * density).toInt(), 0)
                setOnClickListener { onBack() }
            }
            header.addView(backBtn)
        }

        val titleView = TextView(context).apply {
            text = title
            setTextColor(0xFFFFFFFF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            typeface = Typeface.DEFAULT_BOLD
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        }
        header.addView(titleView)

        if (showGlobe && onGlobe != null) {
            val globeBtn = TextView(context).apply {
                text = "\uD83C\uDF10"  // 🌐
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
                setPadding((8 * density).toInt(), 0, 0, 0)
                setOnClickListener { onGlobe() }
            }
            header.addView(globeBtn)
        }

        return header
    }
}
