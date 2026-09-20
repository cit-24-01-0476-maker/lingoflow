package com.lingoflow.lingoflow

import android.animation.ValueAnimator
import android.annotation.SuppressLint
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView

class FloatingBubbleService : Service() {

    companion object {
        const val ACTION_SHOW_MESSAGE = "com.lingoflow.ACTION_SHOW_FLOATING_MESSAGE"
        const val ACTION_SET_LANGUAGE = "com.lingoflow.ACTION_SET_FLOATING_LANGUAGE"
        const val EXTRA_SENDER = "sender"
        const val EXTRA_TRANSLATION = "translation"
        const val EXTRA_ORIGINAL = "original"
        const val EXTRA_LANGUAGE = "language"

        var isRunning = false
            private set
    }

    private var windowManager: WindowManager? = null
    private var rootLayout: FrameLayout? = null
    private var bubbleContainer: FrameLayout? = null
    private var popupCard: LinearLayout? = null
    private var popupSenderText: TextView? = null
    private var popupTranslatedText: TextView? = null
    private var popupOriginalText: TextView? = null
    private var bubbleBadge: TextView? = null

    private var currentLanguage = "sinhala" // "sinhala", "english", "dual"
    private var windowParams: WindowManager.LayoutParams? = null

    private val autoDismissHandler = Handler(Looper.getMainLooper())
    private val dismissRunnable = Runnable { hidePopup() }

    private val messageReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                ACTION_SHOW_MESSAGE -> {
                    val sender = intent.getStringExtra(EXTRA_SENDER) ?: "WhatsApp"
                    val translation = intent.getStringExtra(EXTRA_TRANSLATION) ?: ""
                    val original = intent.getStringExtra(EXTRA_ORIGINAL) ?: ""
                    displayMessagePopup(sender, translation, original)
                }
                ACTION_SET_LANGUAGE -> {
                    val lang = intent.getStringExtra(EXTRA_LANGUAGE) ?: "sinhala"
                    currentLanguage = lang
                    updateBadge()
                }
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        try {
            isRunning = true
            windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
            initFloatingBubbleView()

            val filter = IntentFilter().apply {
                addAction(ACTION_SHOW_MESSAGE)
                addAction(ACTION_SET_LANGUAGE)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(messageReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                registerReceiver(messageReceiver, filter)
            }
        } catch (e: Exception) {
            e.printStackTrace()
            stopSelf()
        }
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun initFloatingBubbleView() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            return
        }
        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        windowParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 30
            y = 350
        }

        rootLayout = FrameLayout(this).apply {
            clipChildren = false
            clipToPadding = false
        }

        val mainHorizontalLayout = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            clipChildren = false
            clipToPadding = false
        }

        bubbleContainer = FrameLayout(this).apply {
            val sizePx = dpToPx(56)
            layoutParams = LinearLayout.LayoutParams(sizePx, sizePx)
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                colors = intArrayOf(Color.parseColor("#2563EB"), Color.parseColor("#38BDF8"))
                orientation = GradientDrawable.Orientation.TL_BR
                setStroke(dpToPx(2), Color.parseColor("#FFFFFF"))
            }
            elevation = dpToPx(8).toFloat()
        }

        val iconView = ImageView(this).apply {
            val iconSize = dpToPx(28)
            layoutParams = FrameLayout.LayoutParams(iconSize, iconSize, Gravity.CENTER)
            setImageResource(android.R.drawable.ic_dialog_info)
            setColorFilter(Color.WHITE)
        }
        bubbleContainer?.addView(iconView)

        bubbleBadge = TextView(this).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT,
                FrameLayout.LayoutParams.WRAP_CONTENT,
                Gravity.BOTTOM or Gravity.END
            ).apply {
                setMargins(0, 0, dpToPx(2), dpToPx(2))
            }
            text = "සිං"
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 9f)
            setPadding(dpToPx(4), dpToPx(1), dpToPx(4), dpToPx(1))
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dpToPx(8).toFloat()
                setColor(Color.parseColor("#F59E0B"))
            }
        }
        bubbleContainer?.addView(bubbleBadge)

        popupCard = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            val maxWidthPx = dpToPx(240)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(dpToPx(10), 0, 0, 0)
            }
            setPadding(dpToPx(12), dpToPx(10), dpToPx(12), dpToPx(10))
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dpToPx(16).toFloat()
                setColor(Color.parseColor("#131B2E"))
                setStroke(dpToPx(1), Color.parseColor("#38BDF8"))
            }
            elevation = dpToPx(10).toFloat()
            visibility = View.GONE
        }

        popupSenderText = TextView(this).apply {
            setTextColor(Color.parseColor("#38BDF8"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            setTypeface(typeface, android.graphics.Typeface.BOLD)
            text = "WhatsApp"
        }
        popupCard?.addView(popupSenderText)

        popupTranslatedText = TextView(this).apply {
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            setTypeface(typeface, android.graphics.Typeface.BOLD)
            setPadding(0, dpToPx(2), 0, dpToPx(2))
            text = ""
        }
        popupCard?.addView(popupTranslatedText)

        popupOriginalText = TextView(this).apply {
            setTextColor(Color.parseColor("#94A3B8"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
            text = ""
        }
        popupCard?.addView(popupOriginalText)

        popupCard?.setOnClickListener { hidePopup() }

        mainHorizontalLayout.addView(bubbleContainer)
        mainHorizontalLayout.addView(popupCard)
        rootLayout?.addView(mainHorizontalLayout)

        setupBubbleTouchListener()

        try {
            windowManager?.addView(rootLayout, windowParams)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private var initialX = 0
    private var initialY = 0
    private var initialTouchX = 0f
    private var initialTouchY = 0f
    private var isDragging = false

    @SuppressLint("ClickableViewAccessibility")
    private fun setupBubbleTouchListener() {
        bubbleContainer?.setOnTouchListener { _, event ->
            val params = windowParams ?: return@setOnTouchListener false
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params.x
                    initialY = params.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    isDragging = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = (event.rawX - initialTouchX).toInt()
                    val dy = (event.rawY - initialTouchY).toInt()
                    if (Math.abs(dx) > 10 || Math.abs(dy) > 10) {
                        isDragging = true
                    }
                    if (isDragging) {
                        params.x = initialX + dx
                        params.y = initialY + dy
                        windowManager?.updateViewLayout(rootLayout, params)
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (!isDragging) {
                        onBubbleClicked()
                    }
                    true
                }
                else -> false
            }
        }
    }

    private fun onBubbleClicked() {
        if (popupCard?.visibility == View.VISIBLE) {
            hidePopup()
        } else {
            currentLanguage = when (currentLanguage) {
                "sinhala" -> "english"
                "english" -> "dual"
                else -> "sinhala"
            }
            updateBadge()
            displayMessagePopup("LingoFlow", "Language set to: ${currentLanguage.uppercase()}", "Tap WhatsApp chat to translate")
        }
    }

    fun displayMessagePopup(sender: String, translation: String, original: String) {
        autoDismissHandler.removeCallbacks(dismissRunnable)
        popupSenderText?.text = "💬 $sender"
        popupTranslatedText?.text = translation
        popupOriginalText?.text = if (original.isNotBlank()) "Original: $original" else ""
        popupCard?.visibility = View.VISIBLE

        autoDismissHandler.postDelayed(dismissRunnable, 6500)
    }

    fun hidePopup() {
        popupCard?.visibility = View.GONE
    }

    private fun updateBadge() {
        bubbleBadge?.text = when (currentLanguage) {
            "english" -> "EN"
            "dual" -> "ALL"
            else -> "සිං"
        }
        val badgeColor = when (currentLanguage) {
            "english" -> Color.parseColor("#06B6D4")
            "dual" -> Color.parseColor("#8B5CF6")
            else -> Color.parseColor("#F59E0B")
        }
        (bubbleBadge?.background as? GradientDrawable)?.setColor(badgeColor)
    }

    private fun dpToPx(dp: Int): Int {
        val density = resources.displayMetrics.density
        return (dp * density).toInt()
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        autoDismissHandler.removeCallbacks(dismissRunnable)
        try {
            unregisterReceiver(messageReceiver)
        } catch (e: Exception) {
            e.printStackTrace()
        }
        rootLayout?.let {
            try {
                windowManager?.removeView(it)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
