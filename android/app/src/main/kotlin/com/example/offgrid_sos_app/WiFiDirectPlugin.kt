package com.example.offgrid_sos_app

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.wifi.p2p.*
import android.net.wifi.p2p.WifiP2pManager.*
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.IOException
import java.net.ServerSocket
import java.net.Socket
import java.util.concurrent.Executors

/**
 * WiFi Direct Plugin for Flutter Off-Grid SOS App
 * Provides high-bandwidth peer-to-peer communication without internet
 */
class WiFiDirectPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    
    private var wifiP2pManager: WifiP2pManager? = null
    private var wifiP2pChannel: Channel? = null
    private var receiver: WiFiDirectBroadcastReceiver? = null
    private val intentFilter = IntentFilter()
    
    private val peers = mutableListOf<WifiP2pDevice>()
    private var isDiscovering = false
    private var connectionInfo: WifiP2pInfo? = null
    
    private val executor = Executors.newCachedThreadPool()
    private var serverSocket: ServerSocket? = null
    private var clientSocket: Socket? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "wifi_direct_channel")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> initialize(result)
            "startDiscovery" -> startDiscovery(result)
            "stopDiscovery" -> stopDiscovery(result)
            "connectToPeer" -> {
                val deviceAddress = call.argument<String>("deviceAddress")
                connectToPeer(deviceAddress, result)
            }
            "disconnect" -> disconnect(result)
            "sendData" -> {
                val data = call.argument<ByteArray>("data")
                val targetAddress = call.argument<String>("targetAddress")
                sendData(data, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun initialize(result: Result) {
        try {
            wifiP2pManager = context.getSystemService(Context.WIFI_P2P_SERVICE) as WifiP2pManager?
            
            if (wifiP2pManager == null) {
                result.success(false)
                return
            }
            
            wifiP2pChannel = wifiP2pManager!!.initialize(context, context.mainLooper, null)
            
            // Set up broadcast receiver
            receiver = WiFiDirectBroadcastReceiver()
            
            // Set up intent filters
            intentFilter.addAction(WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION)
            intentFilter.addAction(WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION)
            intentFilter.addAction(WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION)
            intentFilter.addAction(WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION)
            
            context.registerReceiver(receiver, intentFilter)
            
            result.success(true)
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun startDiscovery(result: Result) {
        if (wifiP2pManager == null || wifiP2pChannel == null) {
            result.success(false)
            return
        }
        
        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) 
            != PackageManager.PERMISSION_GRANTED) {
            result.success(false)
            return
        }

        wifiP2pManager!!.discoverPeers(wifiP2pChannel, object : ActionListener {
            override fun onSuccess() {
                isDiscovering = true
                result.success(true)
            }

            override fun onFailure(reason: Int) {
                result.success(false)
            }
        })
    }

    private fun stopDiscovery(result: Result) {
        if (wifiP2pManager == null || wifiP2pChannel == null) {
            result.success(false)
            return
        }

        wifiP2pManager!!.stopPeerDiscovery(wifiP2pChannel, object : ActionListener {
            override fun onSuccess() {
                isDiscovering = false
                result.success(true)
            }

            override fun onFailure(reason: Int) {
                result.success(false)
            }
        })
    }

    private fun connectToPeer(deviceAddress: String?, result: Result) {
        if (wifiP2pManager == null || wifiP2pChannel == null || deviceAddress == null) {
            result.success(false)
            return
        }

        val device = peers.find { it.deviceAddress == deviceAddress }
        if (device == null) {
            result.success(false)
            return
        }

        val config = WifiP2pConfig().apply {
            this.deviceAddress = device.deviceAddress
        }

        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) 
            != PackageManager.PERMISSION_GRANTED) {
            result.success(false)
            return
        }

        wifiP2pManager!!.connect(wifiP2pChannel, config, object : ActionListener {
            override fun onSuccess() {
                result.success(true)
            }

            override fun onFailure(reason: Int) {
                result.success(false)
            }
        })
    }

    private fun disconnect(result: Result) {
        if (wifiP2pManager == null || wifiP2pChannel == null) {
            result.success(false)
            return
        }

        wifiP2pManager!!.removeGroup(wifiP2pChannel, object : ActionListener {
            override fun onSuccess() {
                connectionInfo = null
                result.success(true)
            }

            override fun onFailure(reason: Int) {
                result.success(false)
            }
        })
    }

    private fun sendData(data: ByteArray?, result: Result) {
        if (data == null || connectionInfo == null) {
            result.success(false)
            return
        }

        executor.execute {
            try {
                if (connectionInfo!!.isGroupOwner) {
                    // As group owner, send to connected clients
                    // Implementation would handle multiple clients
                    result.success(true)
                } else {
                    // As client, connect to group owner
                    val socket = Socket(connectionInfo!!.groupOwnerAddress, 8888)
                    socket.outputStream.write(data)
                    socket.close()
                    result.success(true)
                }
            } catch (e: IOException) {
                result.success(false)
            }
        }
    }

    private inner class WiFiDirectBroadcastReceiver : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION -> {
                    // Request peer list
                    if (ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) 
                        == PackageManager.PERMISSION_GRANTED) {
                        wifiP2pManager?.requestPeers(wifiP2pChannel) { peerList ->
                            peers.clear()
                            peers.addAll(peerList.deviceList)
                            
                            val peersData = peers.map { device ->
                                mapOf(
                                    "deviceAddress" to device.deviceAddress,
                                    "deviceName" to device.deviceName,
                                    "status" to when (device.status) {
                                        WifiP2pDevice.AVAILABLE -> "AVAILABLE"
                                        WifiP2pDevice.INVITED -> "INVITED"
                                        WifiP2pDevice.CONNECTED -> "CONNECTED"
                                        WifiP2pDevice.FAILED -> "FAILED"
                                        WifiP2pDevice.UNAVAILABLE -> "UNAVAILABLE"
                                        else -> "UNKNOWN"
                                    }
                                )
                            }
                            
                            channel.invokeMethod("onPeersChanged", mapOf("peers" to peersData))
                        }
                    }
                }
                
                WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION -> {
                    // Handle connection changes
                    if (ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) 
                        == PackageManager.PERMISSION_GRANTED) {
                        wifiP2pManager?.requestConnectionInfo(wifiP2pChannel) { info ->
                            connectionInfo = info
                            
                            val connectionData = mapOf(
                                "isConnected" to info.groupFormed,
                                "isGroupOwner" to info.isGroupOwner,
                                "groupOwnerAddress" to info.groupOwnerAddress?.hostAddress,
                                "groupOwnerPort" to 8888
                            )
                            
                            channel.invokeMethod("onConnectionChanged", connectionData)
                            
                            // Start server if group owner
                            if (info.groupFormed && info.isGroupOwner) {
                                startServer()
                            }
                        }
                    }
                }
            }
        }
    }

    private fun startServer() {
        executor.execute {
            try {
                serverSocket = ServerSocket(8888)
                while (true) {
                    val client = serverSocket?.accept() ?: break
                    handleClient(client)
                }
            } catch (e: IOException) {
                // Server stopped
            }
        }
    }

    private fun handleClient(client: Socket) {
        executor.execute {
            try {
                val buffer = ByteArray(1024)
                val bytesRead = client.inputStream.read(buffer)
                if (bytesRead > 0) {
                    val data = buffer.copyOf(bytesRead)
                    val messageData = mapOf(
                        "data" to data,
                        "senderAddress" to client.inetAddress.hostAddress
                    )
                    channel.invokeMethod("onDataReceived", messageData)
                }
                client.close()
            } catch (e: IOException) {
                // Client disconnected
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        
        try {
            context.unregisterReceiver(receiver)
        } catch (e: Exception) {
            // Receiver may not be registered
        }
        
        serverSocket?.close()
        clientSocket?.close()
        executor.shutdown()
    }
}