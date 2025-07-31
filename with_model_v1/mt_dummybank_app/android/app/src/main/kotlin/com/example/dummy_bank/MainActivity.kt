package com.example.dummy_bank

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "phishsafe_sdk/screen_recording"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            if (call.method == "isScreenRecording") {
                // 🚫 Placeholder logic: always return false
                val isRecording = false
                result.success(isRecording)
            } else {
                result.notImplemented()
            }
        }
    }
}
