package com.offgrid.mesh.discovery

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.ParcelUuid
import androidx.core.content.ContextCompat
import com.offgrid.mesh.core.DeviceIdentity
import com.offgrid.mesh.model.Peer
import java.util.UUID

class BleDiscoveryManager(
    private val context: Context,
    private val identity: DeviceIdentity,
    private val onPeersChanged: (List<Peer>) -> Unit,
    private val onStatus: (String) -> Unit
) {
    private val bluetoothManager = context.getSystemService(BluetoothManager::class.java)
    private val adapter: BluetoothAdapter? get() = bluetoothManager?.adapter
    private val scanner: BluetoothLeScanner? get() = adapter?.bluetoothLeScanner
    private val advertiser: BluetoothLeAdvertiser? get() = adapter?.bluetoothLeAdvertiser
    private val peers = linkedMapOf<String, Peer>()
    private val serviceUuid = ParcelUuid(SERVICE_UUID)
    private var running = false

    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
            onStatus("BLE advertising + scanning")
        }

        override fun onStartFailure(errorCode: Int) {
            onStatus("Advertise failed: $errorCode")
        }
    }

    private val scanCallback = object : ScanCallback() {
        @SuppressLint("MissingPermission")
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            // Phase 0 advertises only the OFFGRID service UUID so the payload stays
            // inside the 31-byte legacy advertising limit. A persistent OFFGRID
            // identity will be exchanged over the connection/GATT handshake in Phase 1.
            val remoteId = runCatching {
                result.device.address.replace(":", "").takeLast(12)
            }.getOrElse {
                "NODE${result.hashCode().toUInt().toString(16)}"
            }
            if (remoteId.isBlank()) return
            peers[remoteId] = Peer(
                id = remoteId,
                displayName = "OFFGRID-${remoteId.takeLast(6)}",
                rssi = result.rssi,
                lastSeenMs = System.currentTimeMillis()
            )
            pruneAndPublish()
        }

        override fun onScanFailed(errorCode: Int) {
            onStatus("Scan failed: $errorCode")
        }
    }

    @SuppressLint("MissingPermission")
    fun start() {
        if (running) return
        if (!hasPermissions()) {
            onStatus("Bluetooth permission required")
            return
        }
        val a = adapter ?: run {
            onStatus("Bluetooth unavailable")
            return
        }
        if (!a.isEnabled) {
            onStatus("Turn Bluetooth on")
            return
        }

        running = true
        val advertiseSettings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_MEDIUM)
            .setConnectable(true)
            .build()
        val advertiseData = AdvertiseData.Builder()
            .addServiceUuid(serviceUuid)
            .setIncludeDeviceName(false)
            .setIncludeTxPowerLevel(false)
            .build()

        if (a.isMultipleAdvertisementSupported) {
            advertiser?.startAdvertising(advertiseSettings, advertiseData, advertiseCallback)
        } else {
            onStatus("Scanning only: BLE advertising unsupported")
        }

        val filter = ScanFilter.Builder().setServiceUuid(serviceUuid).build()
        val scanSettings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .build()
        scanner?.startScan(listOf(filter), scanSettings, scanCallback)
    }

    @SuppressLint("MissingPermission")
    fun stop() {
        if (!running) return
        if (hasPermissions()) {
            scanner?.stopScan(scanCallback)
            advertiser?.stopAdvertising(advertiseCallback)
        }
        running = false
        onStatus("Discovery stopped")
    }

    private fun pruneAndPublish() {
        val cutoff = System.currentTimeMillis() - PEER_TIMEOUT_MS
        peers.entries.removeIf { it.value.lastSeenMs < cutoff }
        onPeersChanged(peers.values.sortedByDescending { it.rssi })
    }

    private fun hasPermissions(): Boolean = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        listOf(
            Manifest.permission.BLUETOOTH_SCAN,
            Manifest.permission.BLUETOOTH_CONNECT,
            Manifest.permission.BLUETOOTH_ADVERTISE
        ).all { ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED }
    } else {
        ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
    }

    companion object {
        private val SERVICE_UUID: UUID = UUID.fromString("9f92b6a8-d601-4db8-a2fc-0ff67f0a6b71")
        private const val PEER_TIMEOUT_MS = 20_000L
    }
}
