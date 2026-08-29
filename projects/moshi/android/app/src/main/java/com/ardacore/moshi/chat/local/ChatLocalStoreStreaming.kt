package com.ardacore.moshi.chat.local

import okhttp3.RequestBody

fun ChatLocalStore.readPendingAttachment(item: OutboxMessageEntity): RequestBody = pendingAttachmentBody(item)
