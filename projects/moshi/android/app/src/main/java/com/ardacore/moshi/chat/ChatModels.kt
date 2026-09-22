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
    var status: String,
    val downloadPath: String,
) {
    init {
        // The backend marks an upload as "attached" once it belongs to a message.
        // At that point download_path is present and the attachment is downloadable.
        // Normalize that wire state to the UI's existing "ready" state so receivers
        // get the Open/Play action without weakening authenticated download checks.
        if (status == "attached" && downloadPath.isNotBlank()) {
            status = "ready"
        }
    }
}

data class UploadTicket(
    val id: String,
    val kind: String,
    val fileName: String,
    val contentType: String,
    val sizeBytes: Long,
    val status: String,
    val uploadPath: String,
)

data class CatalogMessageCard(
    val catalogItemId: String?,
    val sellerId: String,
    val businessName: String,
    val kind: String,
    val title: String,
    val description: String,
    val priceAmount: Long?,
    val currency: String,
    val availability: String,
    val stockQty: Int?,
    val imagePath: String?,
)

data class OrderMessageCard(
    val orderId: String,
    val buyerId: String,
    val sellerId: String,
    val status: String,
    val itemTitle: String,
    val quantity: Int,
    val totalAmount: Long?,
    val currency: String,
)

data class OrderDraftResult(
    val orderId: String,
    val status: String,
    val message: ChatMessage,
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
    val catalogCard: CatalogMessageCard?,
    val orderCard: OrderMessageCard?,
)

data class ChatConversation(
    val id: String,
    val kind: String,
    val peer: ChatUser?,
    val group: GroupPreview?,
    val latestMessage: ChatMessage?,
    val unreadCount: Int,
)
