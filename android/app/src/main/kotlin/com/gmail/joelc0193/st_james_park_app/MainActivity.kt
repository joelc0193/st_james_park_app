package com.gmail.joelc0193.st_james_park_app
import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.util.UUID


class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.gmail.joelc0193.st_james_park_app/spotify_callback"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)  // This line is important!

        // Start executing Dart code in the FlutterEngine
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )

        // Generate a unique ID for the FlutterEngine
        val uniqueID = UUID.randomUUID().toString()

        // Save the unique ID to SharedPreferences
        val sharedPreferences = getSharedPreferences("MyApp", Context.MODE_PRIVATE)
        with (sharedPreferences.edit()) {
            putString("engine_id", uniqueID)
            apply()
        }

        // Cache the FlutterEngine with the unique ID
        FlutterEngineCache.getInstance().put(uniqueID, flutterEngine)

        // Create a MethodChannel with the FlutterEngine's DartExecutor and the channel name
        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        // Set a MethodCallHandler on the MethodChannel
        methodChannel.setMethodCallHandler { call, result ->
            if (call.method == "spotifyCallback") {
                // Handle the spotifyCallback method call
                val data = call.arguments as? String
                // TODO: Use the data (access token) here
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
}