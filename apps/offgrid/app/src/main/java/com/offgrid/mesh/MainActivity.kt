package com.offgrid.mesh

import android.Manifest
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.offgrid.mesh.core.DeviceIdentity
import com.offgrid.mesh.discovery.BleDiscoveryManager
import com.offgrid.mesh.model.Peer
import com.offgrid.mesh.ui.OffgridScreen

class MainActivity : ComponentActivity() {
    private lateinit var identity: DeviceIdentity
    private lateinit var discovery: BleDiscoveryManager
    private var peers by mutableStateOf<List<Peer>>(emptyList())
    private var status by mutableStateOf("Idle")

    private val permissionLauncher = registerForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { grants ->
        if (grants.values.all { it }) discovery.start() else status = "Permission denied"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        identity = DeviceIdentity(this)
        discovery = BleDiscoveryManager(this, identity, { peers = it }, { status = it })
        setContent {
            MaterialTheme {
                OffgridScreen(identity.shortId, status, peers, { requestPermissionsAndStart() }, { discovery.stop() })
            }
        }
    }

    override fun onDestroy() {
        discovery.stop()
        super.onDestroy()
    }

    private fun requestPermissionsAndStart() {
        val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            arrayOf(Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT, Manifest.permission.BLUETOOTH_ADVERTISE)
        } else arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)
        permissionLauncher.launch(permissions)
    }
}
