package com.lingoflow.app

import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val METHOD_CHANNEL = "com.lingoflow.app/methods"
        private const val EVENT_CHANNEL = "com.lingoflow.app/notifications"
    }

    private var eventSink: EventChannel.EventSink? = null
    private var notificationReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isNotificationListenerEnabled" -> {
                    result.success(isNotificationServiceEnabled())
                }
                "openNotificationListenerSettings" -> {
                    openNotificationListenerSettings()
                    result.success(true)
                }
                "showTranslatedNotification" -> {
                    val id = call.argument<Int>("id") ?: System.currentTimeMillis().toInt()
                    val sender = call.argument<String>("sender") ?: "Sender"
                    val primary = call.argument<String>("primaryTranslation") ?: ""
                    val original = call.argument<String>("originalText") ?: ""
                    val secondary = call.argument<String>("secondaryTranslation")

                    LingoNotificationHelper.showTranslatedNotification(
                        context = this,
                        notificationId = id,
                        senderName = sender,
                        primaryTranslation = primary,
                        originalText = original,
                        secondaryTranslation = secondary
                    )
                    result.success(true)
                }
                "simulateNotification" -> {
                    val sender = call.argument<String>("sender") ?: "Kasun"
                    val message = call.argument<String>("message") ?: "mama heta ennam"
                    val timestamp = call.argument<Long>("timestamp") ?: System.currentTimeMillis()
                    val pkg = call.argument<String>("package") ?: "com.whatsapp"

                    val payload = mapOf(
                        "sender" to sender,
                        "message" to message,
                        "timestamp" to timestamp,
                        "package" to pkg
                    )
                    eventSink?.success(payload)
                    result.success(true)
                }
                "downloadAndInstallApk" -> {
                    val apkUrl = call.argument<String>("apkUrl") ?: ""
                    if (apkUrl.isNotBlank()) {
                        ApkInstallerHelper.downloadAndInstallApk(this, apkUrl)
                        result.success(true)
                    } else {
                        result.error("INVALID_URL", "Apk URL is empty", null)
                    }
                }
                "getAppVersionCode" -> {
                    val pInfo = packageManager.getPackageInfo(packageName, 0)
                    val vCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        pInfo.longVersionCode
                    } else {
                        @Suppress("DEPRECATION")
                        pInfo.versionCode.toLong()
                    }
                    result.success(vCode)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    registerNotificationReceiver()
                }

                override fun onCancel(arguments: Any?) {
                    unregisterNotificationReceiver()
                    eventSink = null
                }
            }
        )
    }

    private fun isNotificationServiceEnabled(): Boolean {
        val pkgName = packageName
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        if (!flat.isNullOrEmpty()) {
            val names = flat.split(":")
            for (name in names) {
                val cn = ComponentName.unflattenFromString(name)
                if (cn != null && cn.packageName == pkgName) {
                    return true
                }
            }
        }
        return false
    }

    private fun openNotificationListenerSettings() {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        } else {
            Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")
        }
        startActivity(intent)
    }

    private fun registerNotificationReceiver() {
        if (notificationReceiver == null) {
            notificationReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    if (intent?.action == LingoNotificationListenerService.ACTION_WHATSAPP_NOTIFICATION) {
                        val sender = intent.getStringExtra(LingoNotificationListenerService.EXTRA_SENDER) ?: ""
                        val message = intent.getStringExtra(LingoNotificationListenerService.EXTRA_MESSAGE) ?: ""
                        val timestamp = intent.getLongExtra(LingoNotificationListenerService.EXTRA_TIMESTAMP, System.currentTimeMillis())
                        val pkg = intent.getStringExtra(LingoNotificationListenerService.EXTRA_PACKAGE) ?: "com.whatsapp"

                        val payload = mapOf(
                            "sender" to sender,
                            "message" to message,
                            "timestamp" to timestamp,
                            "package" to pkg
                        )
                        eventSink?.success(payload)
                    }
                }
            }
            val filter = IntentFilter(LingoNotificationListenerService.ACTION_WHATSAPP_NOTIFICATION)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(notificationReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                registerReceiver(notificationReceiver, filter)
            }
        }
    }

    private fun unregisterNotificationReceiver() {
        notificationReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (e: Exception) {
                e.printStackTrace()
            }
            notificationReceiver = null
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterNotificationReceiver()
    }
}
