package com.example.bneeds_taxi_driver

import android.app.Service
import android.content.Intent
import android.os.IBinder
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
// Intha import theva illa, so eduthudalam.
// import io.flutter.view.FlutterCallbackInformation

class OverlayService : Service() {
    // Itha 'private var' ah ve vechukalam, aana use panra edathula correct ah handle pannanum
    private var flutterEngine : FlutterEngine? = null
    private val CHANNEL = "overlay_channel"

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return android.app.Service.START_STICKY
    }

    override fun onCreate() {
        super.onCreate()
        val engine = FlutterEngine(this)
        flutterEngine = engine

        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )

        // Indha Service ku thaniya MethodChannel create panrom
        // Ippo 'engine' variable ah use panrom
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openApp") {
                // Service la irundhu app ah open panrom
                val mainActivityIntent = Intent(this, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                }
                startActivity(mainActivityIntent)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        flutterEngine?.destroy()
        flutterEngine = null
    }
}
