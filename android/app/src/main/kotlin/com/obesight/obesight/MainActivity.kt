package com.obesight.obesight

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.PowerManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.obesight.obesight/device_activity"
    private var screenReceiver: BroadcastReceiver? = null
    private var sensorManager: SensorManager? = null
    private var lightSensor: Sensor? = null
    private var lightListener: SensorEventListener? = null
    private var currentAmbientLux: Float = -1f

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val prefs = getSharedPreferences("obesight_device_activity", Context.MODE_PRIVATE)
            when (call.method) {
                "recordNightInactive" -> {
                    // Hanya no-op atau kompatibilitas; jangan timpa waktu layar HP dengan waktu tutup aplikasi
                    result.success(true)
                }
                "recordMorningActive" -> {
                    // Hanya no-op atau kompatibilitas; jangan timpa waktu bangun HP dengan waktu buka aplikasi
                    result.success(true)
                }
                "getLastScreenOff" -> {
                    queryUsageStatsForSleep(applicationContext, prefs)
                    val lastOff = prefs.getLong("last_screen_off_millis", 0L)
                    result.success(lastOff)
                }
                "getLastScreenOn" -> {
                    queryUsageStatsForSleep(applicationContext, prefs)
                    val lastOn = prefs.getLong("last_screen_on_millis", 0L)
                    result.success(lastOn)
                }
                "getLastDarkTime" -> {
                    val lastDark = prefs.getLong("last_dark_millis", 0L)
                    result.success(lastDark)
                }
                "getLastLightRiseTime" -> {
                    val lastLightRise = prefs.getLong("last_light_rise_millis", 0L)
                    result.success(lastLightRise)
                }
                "getAmbientLux" -> {
                    result.success(currentAmbientLux)
                }
                "clearScreenTimes" -> {
                    prefs.edit()
                        .remove("last_screen_off_millis")
                        .remove("last_screen_on_millis")
                        .remove("last_dark_millis")
                        .remove("last_light_rise_millis")
                        .apply()
                    result.success(true)
                }
                "isScreenInteractive" -> {
                    val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
                    val isInteractive = powerManager?.isInteractive ?: false
                    result.success(isInteractive)
                }
                "checkHealthEcosystemAvailable" -> {
                    val healthPackages = listOf(
                        "com.google.android.apps.healthdata", // Android Health Connect
                        "com.google.android.apps.fitness",     // Google Fit
                        "com.sec.android.app.shealth"         // Samsung Health
                    )
                    var available = false
                    val pm = packageManager
                    for (pkg in healthPackages) {
                        try {
                            pm.getPackageInfo(pkg, 0)
                            available = true
                            break
                        } catch (_: Exception) {}
                    }
                    if (!available && Build.VERSION.SDK_INT >= 34) {
                        available = true
                    }
                    result.success(available)
                }
                else -> result.notImplemented()
            }
        }

        registerScreenReceiver()
        registerLightSensor()
    }

    private fun queryUsageStatsForSleep(context: Context, prefs: android.content.SharedPreferences) {
        try {
            val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as? android.app.usage.UsageStatsManager ?: return
            val now = System.currentTimeMillis()
            val cal = java.util.Calendar.getInstance().apply {
                set(java.util.Calendar.HOUR_OF_DAY, 20)
                set(java.util.Calendar.MINUTE, 0)
                set(java.util.Calendar.SECOND, 0)
                set(java.util.Calendar.MILLISECOND, 0)
            }
            val currentHour = java.util.Calendar.getInstance().get(java.util.Calendar.HOUR_OF_DAY)
            if (currentHour < 20) {
                cal.add(java.util.Calendar.DAY_OF_YEAR, -1)
            }
            val startTime = cal.timeInMillis

            val events = usm.queryEvents(startTime, now)
            var lastScreenOffTime = 0L
            var firstScreenOnTime = 0L

            val event = android.app.usage.UsageEvents.Event()
            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                val eventCal = java.util.Calendar.getInstance().apply { timeInMillis = event.timeStamp }
                val h = eventCal.get(java.util.Calendar.HOUR_OF_DAY)

                // Event 16: SCREEN_NON_INTERACTIVE (Layar HP mati)
                // Event 17: KEYGUARD_SHOWN (HP terkunci)
                if (event.eventType == 16 || event.eventType == 17) {
                    if (h >= 20 || h < 5) {
                        lastScreenOffTime = event.timeStamp
                    }
                }
                // Event 15: SCREEN_INTERACTIVE (Layar HP nyala)
                // Event 18: KEYGUARD_HIDDEN (Kunci HP dibuka)
                if (event.eventType == 15 || event.eventType == 18) {
                    if (h in 5..14 && lastScreenOffTime > 0L && event.timeStamp > lastScreenOffTime) {
                        if (firstScreenOnTime == 0L) {
                            firstScreenOnTime = event.timeStamp
                        }
                    }
                }
            }

            val existingOff = prefs.getLong("last_screen_off_millis", 0L)
            val existingOn = prefs.getLong("last_screen_on_millis", 0L)

            val editor = prefs.edit()
            if (existingOff == 0L && lastScreenOffTime > 0L) {
                editor.putLong("last_screen_off_millis", lastScreenOffTime)
            }
            if (existingOn == 0L && firstScreenOnTime > 0L) {
                editor.putLong("last_screen_on_millis", firstScreenOnTime)
            }
            editor.apply()
        } catch (_: Exception) {}
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
                val cal = java.util.Calendar.getInstance()
                val hour = cal.get(java.util.Calendar.HOUR_OF_DAY)

                when (intent?.action) {
                    Intent.ACTION_SCREEN_OFF -> {
                        // Titik terakhir layar mati pada rentang malam (>= 20.00 atau < 05.00)
                        if (hour >= 20 || hour < 5) {
                            prefs.edit().putLong("last_screen_off_millis", now).apply()
                        }
                    }
                    Intent.ACTION_USER_PRESENT, Intent.ACTION_SCREEN_ON -> {
                        // Titik bangun pertama di pagi hari (>= 05.00 dan <= 14.00)
                        val lastOff = prefs.getLong("last_screen_off_millis", 0L)
                        val lastOn = prefs.getLong("last_screen_on_millis", 0L)
                        if (hour in 5..14) {
                            // Rekam hanya waktu bangun pertama setelah layar mati di malam hari
                            if (lastOff > 0L && (lastOn == 0L || lastOn <= lastOff)) {
                                prefs.edit().putLong("last_screen_on_millis", now).apply()
                            }
                        }
                    }
                }
            }
        }
        applicationContext.registerReceiver(screenReceiver, filter)
    }

    private fun registerLightSensor() {
        try {
            sensorManager = getSystemService(Context.SENSOR_SERVICE) as? SensorManager
            lightSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_LIGHT)
            if (lightSensor != null) {
                lightListener = object : SensorEventListener {
                    override fun onSensorChanged(event: SensorEvent?) {
                        val lux = event?.values?.getOrNull(0) ?: return
                        currentAmbientLux = lux
                        val prefs = getSharedPreferences("obesight_device_activity", Context.MODE_PRIVATE)
                        val now = System.currentTimeMillis()
                        val cal = java.util.Calendar.getInstance()
                        val hour = cal.get(java.util.Calendar.HOUR_OF_DAY)

                        // 1. Deteksi lampu dimatikan / ruangan gelap (< 5 lux) di malam hari
                        if (lux < 5.0f && (hour >= 20 || hour < 5)) {
                            prefs.edit().putLong("last_dark_millis", now).apply()
                        }

                        // 2. Deteksi transisi terang / matahari / lampu pagi (> 40 lux) di pagi hari
                        if (lux > 40.0f && (hour in 5..14)) {
                            val lastOff = prefs.getLong("last_screen_off_millis", 0L)
                            val lastDark = prefs.getLong("last_dark_millis", 0L)
                            val nightStart = if (lastOff > 0L) lastOff else lastDark
                            val lastRise = prefs.getLong("last_light_rise_millis", 0L)
                            if (lastRise == 0L || lastRise < (now - 10 * 3600 * 1000L) || (nightStart > 0L && lastRise <= nightStart)) {
                                prefs.edit().putLong("last_light_rise_millis", now).apply()
                            }
                        }
                    }

                    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
                }
                sensorManager?.registerListener(lightListener, lightSensor, SensorManager.SENSOR_DELAY_NORMAL)
            }
        } catch (_: Exception) {}
    }

    override fun onDestroy() {
        super.onDestroy()
        screenReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (_: Exception) {}
        }
        lightListener?.let {
            try {
                sensorManager?.unregisterListener(it)
            } catch (_: Exception) {}
        }
    }
}
