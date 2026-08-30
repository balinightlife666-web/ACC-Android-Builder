package com.offgrid.mesh.core

import com.offgrid.mesh.model.MeshEnvelope
import com.offgrid.mesh.model.Peer
import kotlinx.coroutines.flow.Flow

interface MeshTransport {
    val peers: Flow<List<Peer>>
    val incoming: Flow<MeshEnvelope>
    suspend fun start()
    suspend fun stop()
    suspend fun send(peerId: String, envelope: MeshEnvelope): Result<Unit>
}
