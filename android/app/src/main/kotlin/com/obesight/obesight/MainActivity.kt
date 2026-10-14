package com.obesight.obesight

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.obesight.obesight/device_activity"
    private var screenReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val prefs = getSharedPreferences("obesight_device_activity", Context.MODE_PRIVATE)
            when (call.method) {
                "getLastScreenOff" -> {
                    val lastOff = prefs.getLong("last_screen_off_millis", 0L)
                    result.success(lastOff)
                }
                "getLastScreenOn" -> {
                    val lastOn = prefs.getLong("last_screen_on_millis", 0L)
                    result.success(lastOn)
                }
                "clearScreenTimes" -> {
                    prefs.edit().remove("last_screen_off_millis").remove("last_screen_on_millis").apply()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        registerScreenReceiver()
    }

    private fun registerScreenReceiver() {
        if (screenReceiver != null) return
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_USER_PRESENT)
        }

        screenReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                val prefs = getSharedPreferences("obesight_device_activity", Context.MODE_PRIVATE)
                val now = System.currentTimeMillis()
                when (intent?.action) {
                    Intent.ACTION_SCREEN_OFF -> {
                        prefs.edit().putLong("last_screen_off_millis", now).apply()
                    }
                    Intent.ACTION_USER_PRESENT, Intent.ACTION_SCREEN_ON -> {
                        prefs.edit().putLong("last_screen_on_millis", now).apply()
                    }
                }
            }
        }
        registerReceiver(screenReceiver, filter)
    }

    override fun onDestroy() {
        super.onDestroy()
        screenReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (e: Exception) {
                // ignore
            }
        }
    }
}
