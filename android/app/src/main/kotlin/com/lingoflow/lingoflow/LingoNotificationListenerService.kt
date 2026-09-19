package com.lingoflow.lingoflow

import android.app.Notification
import android.content.Intent
import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import java.security.MessageDigest

class LingoNotificationListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "LingoNotifListener"
        const val ACTION_WHATSAPP_NOTIFICATION = "com.lingoflow.WHATSAPP_NOTIFICATION"
        const val EXTRA_SENDER = "sender"
        const val EXTRA_MESSAGE = "message"
        const val EXTRA_TIMESTAMP = "timestamp"
        const val EXTRA_PACKAGE = "package"
        const val EXTRA_ID = "notification_id"

        private val SUPPORTED_PACKAGES = setOf(
            "com.whatsapp",
            "com.whatsapp.w4b"
        )

        // Deduplication cache: Hash -> Timestamp
        private val recentNotificationHashes = LinkedHashMap<String, Long>()
        private const val DEDUPLICATION_WINDOW_MS = 2500L
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.i(TAG, "LingoFlow Notification Listener connected successfully.")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        val packageName = sbn.packageName ?: return
        if (!SUPPORTED_PACKAGES.contains(packageName)) {
            return
        }

        val notification = sbn.notification ?: return
        val extras: Bundle = notification.extras ?: return

        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()

        val finalMessage = if (!bigText.isNullOrBlank()) bigText else text

        if (title.isBlank() || finalMessage.isBlank()) return
        if (finalMessage.contains("messages from") || finalMessage.contains("new messages")) return

        val messageKey = "$packageName|$title|$finalMessage"
        val hash = sha256(messageKey)
        val now = System.currentTimeMillis()

        synchronized(recentNotificationHashes) {
            val lastSeen = recentNotificationHashes[hash]
            if (lastSeen != null && (now - lastSeen) < DEDUPLICATION_WINDOW_MS) {
                return // Skip duplicate
            }
            recentNotificationHashes[hash] = now
            if (recentNotificationHashes.size > 100) {
                val oldestKey = recentNotificationHashes.keys.first()
                recentNotificationHashes.remove(oldestKey)
            }
        }

        Log.d(TAG, "Valid WhatsApp notification detected from '$title': $finalMessage")

        val intent = Intent(ACTION_WHATSAPP_NOTIFICATION).apply {
            putExtra(EXTRA_PACKAGE, packageName)
            putExtra(EXTRA_SENDER, title)
            putExtra(EXTRA_MESSAGE, finalMessage)
            putExtra(EXTRA_TIMESTAMP, sbn.postTime)
            putExtra(EXTRA_ID, sbn.id)
            setPackage(this@LingoNotificationListenerService.packageName)
        }
        sendBroadcast(intent)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
    }

    private fun sha256(input: String): String {
        val md = MessageDigest.getInstance("SHA-256")
        val bytes = md.digest(input.toByteArray(Charsets.UTF_8))
        return bytes.joinToString("") { "%02x".format(it) }
    }
}
