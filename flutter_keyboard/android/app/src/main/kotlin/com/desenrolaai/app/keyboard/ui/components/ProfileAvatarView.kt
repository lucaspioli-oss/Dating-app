package com.desenrolaai.app.keyboard.ui.components

import android.content.Context
import android.graphics.*
import android.util.Base64
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import com.desenrolaai.app.keyboard.Theme

object ProfileAvatarView {

    private val bitmapCache = android.util.LruCache<String, Bitmap>(20)

    /**
     * Creates a profile avatar with gradient border ring, photo/initials, and name label.
     * Total width: 64dp. Ring: 52dp. Photo: 48dp.
     */
    fun create(
        context: Context,
        name: String,
        faceImageBase64: String?,
        onClick: () -> Unit
    ): LinearLayout {
        val density = context.resources.displayMetrics.density
        val containerWidth = (64 * density).toInt()
        val ringSize = (52 * density).toInt()
        val photoSize = (48 * density).toInt()

        val container = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(containerWidth, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
                setMargins((4 * density).toInt(), 0, (4 * density).toInt(), 0)
            }
            setOnClickListener { onClick() }
        }

        // Ring + photo container
        val ringContainer = FrameLayout(context).apply {
            layoutParams = LinearLayout.LayoutParams(ringSize, ringSize).apply {
                gravity = Gravity.CENTER_HORIZONTAL
            }
        }

        // Gradient ring (custom drawn view)
        val ringView = GradientRingView(context, ringSize)
        ringContainer.addView(ringView, FrameLayout.LayoutParams(ringSize, ringSize))

        // Photo or initials
        val photoBitmap = decodeBase64(faceImageBase64)
        val photoView = if (photoBitmap != null) {
            CircularImageView(context, photoBitmap, photoSize)
        } else {
            InitialsView(context, name, photoSize)
        }

        val photoParams = FrameLayout.LayoutParams(photoSize, photoSize).apply {
            gravity = Gravity.CENTER
        }
        ringContainer.addView(photoView, photoParams)
        container.addView(ringContainer)

        // Name label
        val displayName = if (name.length > 7) name.take(7) + "…" else name
        val nameLabel = TextView(context).apply {
            text = displayName
            setTextColor(0xFFFFFFFF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 10f)
            gravity = Gravity.CENTER
            maxLines = 1
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                topMargin = (2 * density).toInt()
            }
        }
        container.addView(nameLabel)

        return container
    }

    private fun decodeBase64(base64: String?): Bitmap? {
        if (base64.isNullOrEmpty()) return null
        val cached = bitmapCache.get(base64.take(50))
        if (cached != null) return cached
        return try {
            val bytes = Base64.decode(base64, Base64.DEFAULT)
            val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            if (bitmap != null) bitmapCache.put(base64.take(50), bitmap)
            bitmap
        } catch (e: Exception) {
            null
        }
    }

    private class GradientRingView(context: Context, private val size: Int) : View(context) {
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = size * 0.04f // ~2dp ring width
            shader = LinearGradient(
                0f, 0f, size.toFloat(), size.toFloat(),
                Theme.gradientColors, null, Shader.TileMode.CLAMP
            )
        }

        override fun onDraw(canvas: Canvas) {
            val half = size / 2f
            val radius = half - paint.strokeWidth / 2
            canvas.drawCircle(half, half, radius, paint)
        }
    }

    private class CircularImageView(context: Context, bitmap: Bitmap, private val size: Int) : View(context) {
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        private val bmpShader: BitmapShader

        init {
            val scaled = Bitmap.createScaledBitmap(bitmap, size, size, true)
            bmpShader = BitmapShader(scaled, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP)
            paint.shader = bmpShader
        }

        override fun onDraw(canvas: Canvas) {
            val half = size / 2f
            canvas.drawCircle(half, half, half, paint)
        }
    }

    private class InitialsView(context: Context, name: String, private val size: Int) : View(context) {
        private val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Theme.cardBg }
        private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = 0xFFFFFFFF.toInt()
            textSize = size * 0.4f
            typeface = Typeface.DEFAULT_BOLD
            textAlign = Paint.Align.CENTER
        }
        private val initial = name.firstOrNull()?.uppercaseChar()?.toString() ?: "?"

        override fun onDraw(canvas: Canvas) {
            val half = size / 2f
            canvas.drawCircle(half, half, half, bgPaint)
            val yOffset = (textPaint.descent() + textPaint.ascent()) / 2
            canvas.drawText(initial, half, half - yOffset, textPaint)
        }
    }
}
