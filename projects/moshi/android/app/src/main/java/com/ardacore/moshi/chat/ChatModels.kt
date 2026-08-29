package com.ardacore.moshi.chat

data class ChatUser(
    val id: String,
    val username: String,
    val displayName: String,
    val businessMode: Boolean,
)

data class ChatMessage(
    val id: String,
    val conversationId: String,
    val senderId: String,
    val clientMessageId: String,
    val body: String,
    val createdAt: String,
    val state: String,
)

data class ChatConversation(
    val id: String,
    val kind: String,
    val peer: ChatUser?,
    val latestMessage: ChatMessage?,
    val unreadCount: Int,
)
