package com.guaraapp

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "app.clubee/deeplink"
    private var initialLink: String? = null
    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent, notifyFlutter = false)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Necessário para app_links / plugins lerem o Intent atualizado (singleTop)
        setIntent(intent)
        handleIntent(intent, notifyFlutter = true)
    }

    private fun handleIntent(intent: Intent?, notifyFlutter: Boolean) {
        val uri = intent?.data ?: return
        val link = uri.toString()
        initialLink = link

        if (notifyFlutter) {
            methodChannel?.invokeMethod("routeUpdated", link)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialLink" -> result.success(initialLink)
                    else -> result.notImplemented()
                }
            }

            // Se o Intent chegou no onCreate, envia assim que o engine estiver pronto
            initialLink?.let { link ->
                channel.invokeMethod("routeUpdated", link)
            }
        }
    }
}
