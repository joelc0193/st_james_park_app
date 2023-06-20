package com.gmail.joelc0193.st_james_park_app

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val API_KEY = "YOUR_API_KEY"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.gmail.joelc0193.st_james_park_app/key")
            .setMethodCallHandler { call, result ->
                if (call.method == "getMapboxKey") {
                    result.success(API_KEY)
                } else {
                    result.notImplemented()
                }
            }
    }
}
