package com.gmail.joelc0193.st_james_park_app
import android.content.Context
import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel


class SpotifyCallbackActivity : AppCompatActivity() {
    private val CHANNEL = "com.gmail.joelc0193.st_james_park_app/spotify_callback"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Get the unique ID from SharedPreferences
        val sharedPreferences = getSharedPreferences("MyApp", Context.MODE_PRIVATE)
        val engineId = sharedPreferences.getString("engine_id", null)

        // If engineId is null, return early
        if (engineId == null) {
            finish()
            return
        }

        // Get the FlutterEngine instance
        val flutterEngine: FlutterEngine? = FlutterEngineCache.getInstance().get(engineId)

        // If flutterEngine or its DartExecutor or binaryMessenger is null, return early
        val binaryMessenger = flutterEngine?.dartExecutor?.binaryMessenger
        if (binaryMessenger == null) {
            finish()
            return
        }

        // Create a MethodChannel with the FlutterEngine's DartExecutor and the channel name
        val methodChannel = MethodChannel(binaryMessenger, CHANNEL)

        // Get the intent that started this activity
        val intent: Intent = intent

        // Get the data from the intent
        val data: String? = intent.data?.toString()

        // Invoke the spotifyCallback method on the MethodChannel and pass the data (access token) as an argument
        methodChannel.invokeMethod("spotifyCallback", data)

        // Finish this activity
        finish()
    }
}
