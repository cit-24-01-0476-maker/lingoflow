# LingoFlow ⚡
> *"Understand every message."*

**LingoFlow** is a mobile application built with **Flutter & native Kotlin** that automatically intercepts incoming WhatsApp notification messages, detects whether the text is in **Singlish, Sinhala, or English**, transliterates/translates the content in real time, and renders an instant notification alongside a dashboard feed.

---

## 🌟 Key Features

1. **Native Android Notification Listener**:
   - Built on `NotificationListenerService` in Kotlin (`LingoNotificationListenerService.kt`).
   - Filters exclusively for `com.whatsapp` and `com.whatsapp.w4b` (WhatsApp Business).
   - In-memory SHA-256 hash deduplication to eliminate repeated sync pings.
   - Zero access to private WhatsApp chats or databases.

2. **Real-World Singlish Transliteration Engine**:
   - Rule-based vowel-consonant phonetic mapping.
   - Comprehensive Sri Lankan colloquial dictionary (`mama`, `oyata`, `kohomada`, `ada`, `heta`, `yanawa`, `enawa`, `puluwanda`, `ewwada`, etc.).
   - Smart loanword retention: Keeps technical English words intact (`class`, `assignment`, `submit`, `meeting`, `office`, `link`).

3. **Multi-Language Detection**:
   - Sinhala Unicode block detection (`\u0D80-\u0DFF`).
   - Singlish morphology and colloquial suffix detection.
   - English stop-word profiling and mixed-code detection.

4. **Multiple Translation Modes**:
   - **Auto Sinhala**: Converts English & Singlish to Sinhala.
   - **Auto English**: Converts Sinhala & Singlish to English.
   - **Dual Translation**: Displays Original, Sinhala, and English simultaneously.
   - **Smart Auto**: Automatically selects target language based on message origin.

5. **Contact-Specific Rules**:
   - Per-contact overrides (e.g. Nimal always receives Sinhala, Kasun always receives English, or pause translation for specific contacts).

6. **Privacy & Offline Priority**:
   - 100% offline fallback transliteration (<15ms response).
   - Local SQLite database.
   - Configurable auto-purge periods (Never, 24 Hours, 7 Days, 30 Days).
   - One-tap "Delete All Translation History".

7. **Extensible AI Provider**:
   - Built-in integration for Google Gemini API (`GEMINI_API_KEY`) when cloud translation is desired.

---

## 🏗 Project Architecture

```
e:\meesage translator/
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml
│       └── kotlin/com/lingoflow/app/
│           ├── LingoNotificationListenerService.kt # Background notification listener
│           ├── LingoNotificationHelper.kt          # Android NotificationChannel manager
│           └── MainActivity.kt                     # Platform MethodChannel & EventChannel
├── lib/
│   ├── core/
│   │   ├── services/native_bridge_service.dart     # Flutter-to-Kotlin bridge
│   │   └── theme/app_theme.dart                    # Dark/Light theme & color palette
│   ├── database/database_service.dart              # SQLite database implementation
│   ├── models/models.dart                          # Data models & Enums
│   ├── translation/
│   │   ├── engine/
│   │   │   ├── language_detector.dart              # Singlish / Sinhala / English detection
│   │   │   └── singlish_transliteration_engine.dart # Offline phonetic transliteration
│   │   └── providers/
│   │       ├── translation_provider.dart           # Modular provider interface
│   │       ├── singlish_local_provider.dart        # Local offline provider
│   │       ├── gemini_translation_provider.dart    # Cloud Gemini AI provider
│   │       └── translation_coordinator.dart        # Cache & routing coordinator
│   ├── services/translation_service.dart           # Riverpod state management & feed stream
│   ├── widgets/translation_card.dart               # Message card with actions
│   ├── screens/
│   │   ├── splash/splash_screen.dart               # Animated splash screen
│   │   ├── onboarding/onboarding_screen.dart       # 3-step onboarding walkthrough
│   │   ├── permission/permission_screen.dart       # Notification access setup & guidance
│   │   ├── home/home_screen.dart                   # Dashboard, controls, and live testing
│   │   ├── history/history_screen.dart             # Searchable translation archive
│   │   ├── contacts/contacts_screen.dart           # Per-contact rule manager
│   │   └── settings/settings_screen.dart           # Settings, API keys, and privacy
│   └── main.dart
└── pubspec.yaml
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (version 3.0.0 or higher)
- Android Studio / Android SDK (API level 24+)

### Installation
1. Clone or open the project folder in your terminal:
   ```bash
   cd "e:\meesage translator"
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run on an Android device or emulator:
   ```bash
   flutter run
   ```

---

## 🔑 Cloud AI Configuration (Optional)

LingoFlow operates completely offline out of the box. If you wish to enable Google Gemini AI translation:
1. Open the app and navigate to **Settings** > **Cloud AI Provider**.
2. Paste your Google Gemini API key.
3. Tap **Save**. LingoFlow will use Gemini for incoming messages with instant offline fallback.
