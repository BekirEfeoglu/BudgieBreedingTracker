package com.budgiebreeding.budgie_breeding_tracker

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CONFIG_CHANNEL =
            "com.budgiebreeding.budgie_breeding_tracker/config"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CONFIG_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getConfig" -> {
                        result.success(
                            mapOf(
                                "SUPABASE_URL" to BuildConfig.SUPABASE_URL,
                                "SUPABASE_ANON_KEY" to BuildConfig.SUPABASE_ANON_KEY,
                                "SENTRY_DSN" to BuildConfig.SENTRY_DSN,
                                "SENTRY_ENVIRONMENT" to BuildConfig.SENTRY_ENVIRONMENT,
                                "REVENUECAT_API_KEY_IOS" to BuildConfig.REVENUECAT_API_KEY_IOS,
                                "REVENUECAT_API_KEY_ANDROID" to BuildConfig.REVENUECAT_API_KEY_ANDROID,
                                "GOOGLE_WEB_CLIENT_ID" to BuildConfig.GOOGLE_WEB_CLIENT_ID,
                                "GOOGLE_IOS_CLIENT_ID" to BuildConfig.GOOGLE_IOS_CLIENT_ID,
                            )
                        )
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
