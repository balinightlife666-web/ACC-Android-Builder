package com.ardacore.moshi.chat

data class ChatUser(
    val id: String,
    val username: String,
    val displayName: String,
    val businessMode: Boolean,
)

data class GroupPreview(
    val title: String,
    val description: String,
    val myRole: String,
    val memberCount: Int,
)

data class GroupMember(
    val user: ChatUser,
    val role: String,
    val joinedAt: String,
)

data class ReplyPreview(
    val id: String,
    val senderId: String,
    val body: String,
    val isDeleted: Boolean,
)

data class ReactionSummary(
    val emoji: String,
    val count: Int,
    val reactedByMe: Boolean,
)

data class ChatAttachment(
    val id: String,
    val kind: String,
    val fileName: String,
    val contentType: String,
    val sizeBytes: Long,
    val status: String,
    val downloadPath: String,
)

data class UploadTicket(
    val id: String,
    val kind: String,
    val fileName: String,
    val contentType: String,
    val sizeBytes: Long,
    val status: String,
    val uploadPath: String,
)

data class ChatMessage(
    val id: String,
    val conversationId: String,
    val senderId: String,
    val clientMessageId: String,
    val body: String,
    val createdAt: String,
    val editedAt: String?,
    val deletedAt: String?,
    val isDeleted: Boolean,
    val state: String,
    val replyTo: ReplyPreview?,
    val reactions: List<ReactionSummary>,
    val attachments: List<ChatAttachment>,
)

data class ChatConversation(
    val id: String,
    val kind: String,
    val peer: ChatUser?,
    val group: GroupPreview?,
    val latestMessage: ChatMessage?,
    val unreadCount: Int,
)
