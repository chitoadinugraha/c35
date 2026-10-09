package id.alienai

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.util.Log
import java.io.OutputStream
import java.util.UUID

/** Bluetooth Classic SPP raw bytes for ESC/POS thermal printers (Android only). */
object ThermalBluetoothPrint {
    private const val TAG = "ThermalBluetoothPrint"
    private val sppUuid: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

    private var socket: BluetoothSocket? = null
    private var outputStream: OutputStream? = null
    private var connectedMac: String? = null

    fun bluetoothEnabled(): Boolean {
        val adapter = BluetoothAdapter.getDefaultAdapter()
        return adapter?.isEnabled == true
    }

    fun pairedDevices(): List<Map<String, String>> {
        val items = mutableListOf<Map<String, String>>()
        try {
            val adapter = BluetoothAdapter.getDefaultAdapter()
            val bonded = adapter?.bondedDevices ?: return items
            for (device in bonded) {
                val name = device.name ?: ""
                items.add(mapOf("name" to name, "mac" to device.address))
            }
        } catch (e: SecurityException) {
            Log.w(TAG, "pairedDevices permission: ${e.message}")
        }
        return items
    }

    fun printBytes(context: Context, mac: String, bytes: ByteArray): Boolean {
        val target = mac.trim()
        if (target.isEmpty() || bytes.isEmpty()) return false
        return try {
            ensureConnected(target)
            val stream = outputStream ?: return false
            val chunkSize = 16 * 1024
            var offset = 0
            while (offset < bytes.size) {
                val end = minOf(offset + chunkSize, bytes.size)
                stream.write(bytes, offset, end - offset)
                stream.flush()
                offset = end
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "printBytes failed: ${e.message}")
            disconnect()
            false
        }
    }

    fun disconnect() {
        try {
            outputStream?.close()
        } catch (_: Exception) {
        }
        try {
            socket?.close()
        } catch (_: Exception) {
        }
        outputStream = null
        socket = null
        connectedMac = null
    }

    private fun ensureConnected(mac: String) {
        if (connectedMac == mac && outputStream != null) {
            return
        }
        disconnect()
        val adapter = BluetoothAdapter.getDefaultAdapter()
            ?: throw IllegalStateException("No Bluetooth adapter")
        if (!adapter.isEnabled) {
            throw IllegalStateException("Bluetooth disabled")
        }
        val device: BluetoothDevice = adapter.getRemoteDevice(mac)
        val sock = device.createRfcommSocketToServiceRecord(sppUuid)
        adapter.cancelDiscovery()
        sock.connect()
        if (!sock.isConnected) {
            sock.close()
            throw IllegalStateException("Socket not connected")
        }
        socket = sock
        outputStream = sock.outputStream
        connectedMac = mac
    }
}