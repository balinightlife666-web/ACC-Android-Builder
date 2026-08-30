package com.offgrid.mesh.model

import java.util.UUID

data class MeshEnvelope(
    val messageId: String = UUID.randomUUID().toString(),
    val sourceId: String,
    val destinationId: String?,
    val createdAtMs: Long,
    val expiresAtMs: Long,
    val hopCount: Int = 0,
    val maxHops: Int = 8,
    val payloadType: PayloadType,
    val ciphertext: ByteArray
) {
    enum class PayloadType { TEXT, SOS, LOCATION, ACK }
    fun canRelay(nowMs: Long): Boolean = nowMs < expiresAtMs && hopCount < maxHops
}
