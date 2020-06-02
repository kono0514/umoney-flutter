package com.example.umoney_flutter

import android.content.Intent
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.tech.IsoDep
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import kotlin.concurrent.thread

class ScanActivity: FlutterActivity() {
    private val CHANNEL: String = "app.channel.shared.tag"
    private var sharedValue: String = ""
    private var sharedState: String = "querying"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getSharedBalance") {
                result.success(hashMapOf("state" to sharedState, "value" to sharedValue))
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        intent.putExtra("background_mode", "transparent")
        intent.putExtra("route", "/intentScanner")
        if (NfcAdapter.ACTION_TECH_DISCOVERED == intent.action) {
            thread {
                handleSendTag(intent)
            }
        }
        super.onCreate(savedInstanceState)
    }

    private fun handleSendTag(intent: Intent) {
        val tag: Tag = intent.getParcelableExtra(NfcAdapter.EXTRA_TAG)

        if (tag == null) {
            sharedState = "error"
            sharedValue = "Error reading tag"
            return
        }

        val defaultAdapter = NfcAdapter.getDefaultAdapter(this)
        if (defaultAdapter == null || !defaultAdapter.isEnabled) {
            sharedState = "error"
            sharedValue = "Error reading tag"
            return
        }


        val isoDep = IsoDep.get(tag)
        if (isoDep == null) {
            sharedState = "error"
            sharedValue = "Error parsing tag"
            return
        }

        isoDep.runCatching {
            this.connect()
            this.transceive("00a4040007d410000003000100".hexStringToByteArray())
            val balanceRecv = this.transceive("904c000004".hexStringToByteArray())
            this.close()
            return@runCatching balanceRecv
        }.onFailure {
            sharedState = "error"
            sharedValue = "Error querying card"
        }.onSuccess { byteArray ->
            if (byteArray.isEmpty()) {
                sharedState = "error"
                sharedValue = "Error querying card"
                return
            }

            runCatching {
                var balance = byteArray.copyOfRange(0, byteArray.size - 2).toHex()
                balance = Integer.parseInt(balance, 16).toString()
                return@runCatching balance
            }.onSuccess { balance ->
                sharedState = "success"
                sharedValue = balance
            }.onFailure {
                sharedState = "error"
                sharedValue = "Error parsing balance"
            }
        }
    }

    fun String.hexStringToByteArray(): ByteArray {
        if (length % 2 != 0) {
            throw IllegalArgumentException("Bad input string: $this")
        }

        return ByteArray(length / 2) {
            ((hexDigitToInt(this[2 * it]) shl 4) or hexDigitToInt(
                    this[2 * it + 1]
            )).toByte()
        }
    }

    fun hexDigitToInt(c: Char): Int = when (c) {
        in '0'..'9' -> c - '0'
        in 'a'..'f' -> c - 'a' + 10
        in 'A'..'F' -> c - 'A' + 10
        else -> throw IllegalArgumentException("Bad hex digit $c")
    }

    fun ByteArray.toHex(): String {
        val result = StringBuilder()

        forEach {
            result.append(((it.toInt() and 0xff) or 0x100).toString(16).substring(1))
        }
        return result.toString()
    }
}