package com.desenrolaai.app.keyboard

import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.view.View

object Theme {
    val bg = Color.parseColor("#120E16")
    val cardBg = Color.parseColor("#231C2D")
    val rose = Color.parseColor("#E81E64")
    val orange = Color.parseColor("#FF6B36")
    val purple = Color.parseColor("#7A2EBD")
    val textSecondary = Color.parseColor("#A196AB")
    val clipText = Color.parseColor("#FFB596")
    val suggestionBg = Color.parseColor("#282034")
    val overlayBg = 0xF8120E16.toInt()
    val selectedBg = 0x26E81E64.toInt()
    val errorText = Color.parseColor("#FF9966")
    val roseAlpha30 = 0x4DE81E64.toInt()
    val roseAlpha25 = 0x40E81E64.toInt()

    // Gradient colors (red-orange → rose → purple)
    val gradientStart = Color.parseColor("#FF3B30")
    val gradientMid = Color.parseColor("#E81E64")
    val gradientEnd = Color.parseColor("#7A2EBD")
    val gradientColors = intArrayOf(gradientStart, gradientMid, gradientEnd)

    fun withAlpha(color: Int, alpha: Float): Int {
        val a = (alpha * 255).toInt().coerceIn(0, 255)
        return (color and 0x00FFFFFF) or (a shl 24)
    }

    fun startCursorBlink(view: View) {
        val handler = Handler(Looper.getMainLooper())
        val blink = object : Runnable {
            override fun run() {
                view.alpha = if (view.alpha == 1f) 0f else 1f
                handler.postDelayed(this, 530)
            }
        }
        handler.post(blink)
    }
}
