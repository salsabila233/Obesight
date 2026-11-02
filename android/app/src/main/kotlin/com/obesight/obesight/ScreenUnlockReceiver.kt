package com.obesight.obesight

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import java.util.Calendar

/**
 * Menerima siaran broadcast sistem Android saat pengguna membuka kunci layar (system screen unlock / USER_PRESENT).
 * Merekam waktu bangun tidur pertama kali di pagi hari (pukul 05.00 s.d. 14.00)
 * sehingga patokan waktu bangun tidur diambil dari aktivitas fisik pertama perangkat,
 * BUKAN dari saat pengguna membuka aplikasi ObeSight.
 */
class ScreenUnlockReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return
        if (Intent.ACTION_USER_PRESENT != intent.action) return

        val prefs = context.getSharedPreferences("obesight_device_activity", Context.MODE_PRIVATE)
        val now = System.currentTimeMillis()
        val cal = Calendar.getInstance()
        val hour = cal.get(Calendar.HOUR_OF_DAY)

        // Hanya proses jika berada pada jendela pagi/siang hari (05.00 s.d. 14.00)
        if (hour in 5..14) {
            val lastOff = prefs.getLong("last_screen_off_millis", 0L)
            val lastOn = prefs.getLong("last_screen_on_millis", 0L)

            // Batas awal jendela pagi hari ini (pukul 05:00:00)
            val todayMorning = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, 5)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }.timeInMillis

            // Catat waktu bangun pertama jika:
            // 1. Belum ada rekaman screen on hari ini sejak pukul 05:00 pagi (lastOn < todayMorning), ATAU
            // 2. Rekaman screen on masih sebelum/sama dengan layar mati semalam (lastOn <= lastOff)
            val isFirstUnlockToday = lastOn < todayMorning
            val isAfterNightOff = lastOff > 0L && lastOn <= lastOff

            if (isFirstUnlockToday || isAfterNightOff) {
                prefs.edit().putLong("last_screen_on_millis", now).apply()
            }
        }
    }
}

