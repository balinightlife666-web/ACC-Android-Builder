package com.ardacore.moshi.chat

import com.ardacore.moshi.chat.local.ChatLocalStore
import com.ardacore.moshi.chat.local.OutboxMessageEntity
import okhttp3.RequestBody

fun ChatLocalStore.readPendingAttachment(item: OutboxMessageEntity): RequestBody = pendingAttachmentBody(item)
