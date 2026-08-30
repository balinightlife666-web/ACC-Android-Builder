package com.offgrid.mesh.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.offgrid.mesh.model.Peer

@Composable
fun OffgridScreen(myId: String, status: String, peers: List<Peer>, onStart: () -> Unit, onStop: () -> Unit) {
    Scaffold { padding ->
        Column(Modifier.fillMaxSize().padding(padding).padding(20.dp)) {
            Text("OFFGRID", style = MaterialTheme.typography.headlineLarge)
            Text("Phase 0 • BLE mesh discovery")
            Spacer(Modifier.height(16.dp))
            Text("This device: $myId")
            Text("Status: $status")
            Spacer(Modifier.height(16.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Button(onClick = onStart) { Text("START DISCOVERY") }
                Button(onClick = onStop) { Text("STOP") }
            }
            Spacer(Modifier.height(24.dp))
            Text("Nearby OFFGRID nodes (${peers.size})", style = MaterialTheme.typography.titleMedium)
            Spacer(Modifier.height(8.dp))
            LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                items(peers, key = { it.id }) { peer ->
                    Card(Modifier.fillMaxWidth()) { Column(Modifier.padding(14.dp)) { Text(peer.displayName); Text("RSSI ${peer.rssi} dBm • ${peer.id}") } }
                }
            }
        }
    }
}
