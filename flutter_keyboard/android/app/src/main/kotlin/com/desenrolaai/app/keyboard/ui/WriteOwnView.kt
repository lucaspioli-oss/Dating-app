package com.desenrolaai.app.keyboard.ui

import android.content.Context
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.text.InputType
import android.util.TypedValue
import android.view.Gravity
import android.view.inputmethod.EditorInfo
import android.widget.*
import com.desenrolaai.app.keyboard.Theme
import com.desenrolaai.app.keyboard.data.ConversationContext
import com.desenrolaai.app.keyboard.ui.components.GradientButton

class WriteOwnView(
    private val context: Context,
    private val container: FrameLayout,
    private val conversation: ConversationContext?,
    private val clipboardText: String?,
    private val onBack: () -> Unit,
    private val onInsert: (String) -> Unit,
    private val initialText: String = ""
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
        val matchName = conversation?.matchName ?: ""
        val headerText = if (matchName.isNotEmpty()) "\uD83D\uDC64 $matchName | Ela disse:" else "Escreva sua resposta:"
        val header = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding((12 * density).toInt(), (8 * density).toInt(), (12 * density).toInt(), (4 * density).toInt())
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }

        val headerLabel = TextView(context).apply {
            text = headerText
            setTextColor(0xFFFFFFFF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            typeface = Typeface.DEFAULT_BOLD
        }
        header.addView(headerLabel)
        root.addView(header)

        // Clipboard quote
        if (!clipboardText.isNullOrEmpty()) {
            val preview = clipboardText.take(80)
            val quoteLabel = TextView(context).apply {
                text = "\uD83D\uDCAC \"$preview\""
                setTextColor(Theme.clipText)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
                maxLines = 2
                setPadding((16 * density).toInt(), 0, (16 * density).toInt(), (4 * density).toInt())
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
            }
            root.addView(quoteLabel)
        }

        // Text input
        val inputBg = GradientDrawable().apply {
            setColor(Theme.cardBg)
            cornerRadius = 10 * density
            setStroke((0.5f * density).toInt(), Theme.withAlpha(Theme.rose, 0.3f))
        }

        val editText = EditText(context).apply {
            hint = "Digite sua resposta..."
            setHintTextColor(Theme.textSecondary)
            setTextColor(0xFFFFFFFF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            background = inputBg
            setPadding((12 * density).toInt(), (8 * density).toInt(), (12 * density).toInt(), (8 * density).toInt())
            inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_AUTO_CORRECT
            imeOptions = EditorInfo.IME_FLAG_NO_EXTRACT_UI
            maxLines = 3
            setText(initialText)
            setSelection(initialText.length)
            isFocusable = true
            isFocusableInTouchMode = true
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, (40 * density).toInt()
            ).apply {
                setMargins((16 * density).toInt(), (4 * density).toInt(), (16 * density).toInt(), (4 * density).toInt())
            }
        }
        root.addView(editText)

        // Spacer
        val spacer = android.view.View(context).apply {
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f)
        }
        root.addView(spacer)

        // Bottom buttons row
        val btnRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding((12 * density).toInt(), (4 * density).toInt(), (12 * density).toInt(), (8 * density).toInt())
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }

        // Back button
        val backBtn = TextView(context).apply {
            text = "← Voltar"
            setTextColor(Theme.textSecondary)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            setPadding((8 * density).toInt(), (8 * density).toInt(), (16 * density).toInt(), (8 * density).toInt())
            setOnClickListener { onBack() }
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        }
        btnRow.addView(backBtn)

        // Insert button
        val insertBg = GradientDrawable(
            GradientDrawable.Orientation.LEFT_RIGHT,
            Theme.gradientColors
        ).apply {
            cornerRadius = 18 * density
        }
        val insertBtn = TextView(context).apply {
            text = "Inserir ↗"
            setTextColor(0xFFFFFFFF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            background = insertBg
            setPadding((20 * density).toInt(), (8 * density).toInt(), (20 * density).toInt(), (8 * density).toInt())
            layoutParams = LinearLayout.LayoutParams(
                (110 * density).toInt(), (36 * density).toInt()
            )
            setOnClickListener {
                val text = editText.text.toString().trim()
                if (text.isNotEmpty()) onInsert(text)
            }
        }
        btnRow.addView(insertBtn)

        root.addView(btnRow)
        container.addView(root)
    }
}
