package com.sandarutharushka.dawasa

import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * FlutterFragmentActivity is required by local_auth (BiometricPrompt).
 */
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PLATFORM_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecureScreen" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        if (enabled) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ApkUpdates.METHOD_CHANNEL)
            .setMethodCallHandler { call, result -> ApkUpdates.handle(this, call, result) }
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, ApkUpdates.EVENT_CHANNEL)
            .setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                        ApkUpdates.events = events
                    }

                    override fun onCancel(arguments: Any?) {
                        ApkUpdates.events = null
                    }
                },
            )
    }

    companion object {
        private const val PLATFORM_CHANNEL = "com.sandarutharushka.dawasa/platform"
    }
}
