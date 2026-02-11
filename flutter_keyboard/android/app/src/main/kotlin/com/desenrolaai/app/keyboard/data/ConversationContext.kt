package com.desenrolaai.app.keyboard.data

data class ConversationContext(
    val conversationId: String?,
    val profileId: String?,
    val matchName: String,
    val platform: String,
    val lastMessage: String?,
    val faceImageBase64: String?
)
