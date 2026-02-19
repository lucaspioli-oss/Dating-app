package com.desenrolaai.app.keyboard.accessibility

data class ParsedConversation(
    val contactName: String,
    val platform: String,       // "whatsapp", "tinder", "bumble", "hinge", "instagram"
    val messages: List<ParsedMessage>,
    val timestamp: Long = System.currentTimeMillis()
)

data class ParsedMessage(
    val text: String,
    val isFromUser: Boolean,
    val timestamp: String? = null
)
