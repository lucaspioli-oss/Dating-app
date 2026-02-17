package com.desenrolaai.app.keyboard.ui

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.util.TypedValue
import android.view.Gravity
import android.widget.*
import com.desenrolaai.app.keyboard.Theme
import com.desenrolaai.app.keyboard.ui.components.GradientButton
import com.desenrolaai.app.keyboard.ui.components.HeaderBar

class ScreenshotAnalysisView(
    private val context: Context,
    private val container: FrameLayout,
    private val isAnalyzing: Boolean,
    private val screenshotBitmap: Bitmap?,
    private val onBack: () -> Unit,
    private val onPasteScreenshot: () -> Unit,
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
            context, "\uD83D\uDCF8 Screenshot",
            showBack = true, onBack = onBack,
            showGlobe = true, onGlobe = onSwitchKeyboard
        )
        root.addView(header)

        if (isAnalyzing) {
            // Analyzing state
            val centerLayout = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f
                )
            }

            // Thumbnail if available
            if (screenshotBitmap != null) {
                val thumbView = ImageView(context).apply {
                    setImageBitmap(screenshotBitmap)
                    scaleType = ImageView.ScaleType.CENTER_CROP
                    val bg = GradientDrawable().apply {
                        cornerRadius = 10 * density
                    }
                    clipToOutline = true
                    background = bg
                    layoutParams = LinearLayout.LayoutParams(
                        (60 * density).toInt(), (60 * density).toInt()
                    ).apply {
                        gravity = Gravity.CENTER_HORIZONTAL
                        bottomMargin = (12 * density).toInt()
                    }
                }
                centerLayout.addView(thumbView)
            }

            val analyzingLabel = TextView(context).apply {
                text = "Analisando screenshot..."
                setTextColor(0xFFFFFFFF.toInt())
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply { bottomMargin = (12 * density).toInt() }
            }
            centerLayout.addView(analyzingLabel)

            val spinner = ProgressBar(context).apply {
                layoutParams = LinearLayout.LayoutParams(
                    (24 * density).toInt(), (24 * density).toInt()
                ).apply { gravity = Gravity.CENTER_HORIZONTAL }
            }
            centerLayout.addView(spinner)

            val subtitleLabel = TextView(context).apply {
                text = "Extraindo mensagens com IA"
                setTextColor(Theme.textSecondary)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply { topMargin = (8 * density).toInt() }
            }
            centerLayout.addView(subtitleLabel)

            root.addView(centerLayout)
        } else {
            // Instructions state
            val instructionsLayout = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f
                )
                setPadding((20 * density).toInt(), 0, (20 * density).toInt(), 0)
            }

            val mainLabel = TextView(context).apply {
                text = "Copie o print da conversa"
                setTextColor(0xFFFFFFFF.toInt())
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                typeface = Typeface.DEFAULT_BOLD
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply { bottomMargin = (8 * density).toInt() }
            }
            instructionsLayout.addView(mainLabel)

            val steps = listOf(
                "1. Tire print da conversa",
                "2. Abra Fotos e copie a imagem",
                "3. Volte e toque o bot\u00e3o"
            )
            for (step in steps) {
                val stepLabel = TextView(context).apply {
                    text = step
                    setTextColor(Theme.textSecondary)
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
                    gravity = Gravity.CENTER
                    layoutParams = LinearLayout.LayoutParams(
                        LinearLayout.LayoutParams.MATCH_PARENT,
                        LinearLayout.LayoutParams.WRAP_CONTENT
                    ).apply { bottomMargin = (2 * density).toInt() }
                }
                instructionsLayout.addView(stepLabel)
            }

            root.addView(instructionsLayout)

            // Paste Screenshot button
            val pasteBtn = GradientButton.create(
                context, "\uD83D\uDCF8 Colar Screenshot", heightDp = 44, textSizeSp = 14f
            ) { onPasteScreenshot() }
            root.addView(pasteBtn)

            // Bottom spacer
            root.addView(android.view.View(context).apply {
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT, (8 * density).toInt()
                )
            })
        }

        container.addView(root)
    }
}
