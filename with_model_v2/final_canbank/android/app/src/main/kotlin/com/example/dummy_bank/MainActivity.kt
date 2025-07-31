package com.example.dummy_bank

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "phishsafe_sdk/screen_recording"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isScreenRecording" -> {
                    val isRecording = isScreenRecording()
                    result.success(isRecording)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isScreenRecording(): Boolean {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val processes = activityManager.runningAppProcesses ?: return false

        // Updated with stricter and known recorder keywords
        val screenRecordKeywords = listOf("az screen", "mobizen", "du recorder", "screen recorder", "recorder", "xrecorder", "vidma")

        for (process in processes) {
            val processName = process.processName.lowercase()
            if (screenRecordKeywords.any { keyword -> processName.contains(keyword) }) {
                Log.w("ScreenCheck", "Possible screen recording process detected: $processName")
                return true
            }
        }

        // Optional: Check if screen is capturable (FLAG_SECURE off)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
            val secureFlag = window?.attributes?.flags?.and(WindowManager.LayoutParams.FLAG_SECURE)
            if (secureFlag == 0) {
                // Log.w("ScreenCheck", "⚠ FLAG_SECURE is OFF - screen may be capturable")
                // You may return true here if you consider this risky
                // return true
            }
        }

        return false
    }
}
