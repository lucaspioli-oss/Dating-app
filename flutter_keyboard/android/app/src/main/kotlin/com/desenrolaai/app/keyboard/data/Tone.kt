package com.desenrolaai.app.keyboard.data

data class Tone(
    val id: String,
    val emoji: String,
    val label: String
)

val availableTones = listOf(
    Tone("automatico", "\uD83E\uDD16", "Auto"),
    Tone("engraçado", "\uD83D\uDE04", "Engraçado"),
    Tone("ousado", "\uD83D\uDD25", "Ousado"),
    Tone("romântico", "❤️", "Romântico"),
    Tone("casual", "\uD83D\uDE0E", "Casual"),
    Tone("confiante", "\uD83D\uDCAA", "Confiante"),
)
