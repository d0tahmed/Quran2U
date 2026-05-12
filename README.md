# Quran2U

Welcome to **Quran2U**, a beautifully designed, feature-rich Islamic application built with Flutter. Quran2U goes beyond simply reading the Quran by offering an immersive, deeply integrated ecosystem featuring cloud sync, audio interleaving, and comprehensive Hadith collections.

## ✨ Key Features

*   **📖 The Holy Quran & Tafseer:** Read the Quran in a beautiful, distraction-free interface with built-in, detailed Tafseer powered by Quran.com.
*   **🎧 Interleaved Audio Translations:** Listen to world-renowned reciters with groundbreaking English & Urdu interleaved audio translation, perfectly synchronized Ayah-by-Ayah.
*   **📚 Kutub al-Sittah (Hadith Library):** A fully offline-capable Hadith reader featuring the six major authentic collections (Sahih al-Bukhari, Sahih Muslim, Sunan Abu Dawood, Jami' at-Tirmidhi, Sunan an-Nasa'i, and Sunan Ibn Majah) with seamless multi-language support (English, Arabic, Urdu). search hadith numbers inside chapters
*   **🤲 300+ Daily Duas (Hisnul Muslim):** A vast, categorized collection of authentic supplications from Hisnul Muslim, directly integrated into the app.
*   **☁️ Official Quran.com Integration:** Sign in with your official Quran.com account using secure OAuth2 to instantly sync your bookmarks across all your devices and the web.
*   **🌅 Daily Inspirations:** Wake up to daily Ayah and Hadith notifications triggered precisely at 6:00 AM local time.
*   **📱 Home Screen Prayer Widget:** Keep track of your daily Salah times right from your Android home screen with a sleek, natively updating widget.
*   **📚 Upto 100 Languages+ Text Translations of Quran:** By Using Quran.com API v4, THIS UPDATE NOW SUPPORTS OVER 100 languages+ text translation of Quran
*   **⚙️ UPDATE BUTTON IN THE APP:** Now you can click on "UPDATE" button at the top right corner of the app's homepage which then will redirect user to the github releases which the user can download the new release if there is new version available.
## 🚀 Setup Instructions

1. Clone the repository:
   ```bash
   git clone https://github.com/d0tahmed/Quran2U.git
   cd Quran2U
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Generate Freezed models:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
4. Run the application:
   ```bash
   flutter run
   ```

## 🔌 APIs Used & Their Purpose

Quran2U is powered by several robust, official APIs to deliver an authentic and synchronized experience:

### 1. Quran.com API v4 (`api.quran.com/api/v4`)
The primary backbone for all textual and metadata content in the application.
* **Surah & Ayah Data:** Fetches the complete list of Surahs, their names, revelation places, and Ayah counts.
* **Tafseer:** Retrieves comprehensive, multi-language Tafseer text (e.g., Ibn Kathir, Maariful Quran) mapped precisely to individual Ayahs.
* **Mushaf Pages:** Fetches the Arabic Uthmani Tajweed script for rendering the physical-style Mushaf reading pages.
* **Translations:** Downloads user-selected text translations for offline or online reading.

### 2. Quran Foundation OAuth2 (`oauth2.quran.foundation` & `apis.quran.foundation`)
* **Authentication:** Provides secure OAuth2 / OpenID Connect login using official Quran.com accounts.
* **Cloud Sync:** Synchronizes user collections, bookmarks, and reading progress directly to the Quran.com ecosystem, ensuring data is unified across the web and the Quran2U app.

### 3. EveryAyah API (`everyayah.com`)
* **Audio Recitations:** Streams and downloads high-quality MP3 recitations from world-renowned Imams (e.g., Mishary Alafasy, Abdul Rahman Al-Sudais).
* **Interleaved Audio:** Used to fetch segmented Arabic and Translation audio files for the synchronized "Tarjumah Mode" playback.

## 🔐 Environment Setup (Secrets)

To run the app locally with full cloud-sync support, you must configure your OAuth2 credentials. The project uses a Git-ignored `secret.dart` file to prevent leaking credentials.

1. Create a file named `secret.dart` inside the `lib/` directory.
2. Add your Quran Foundation OAuth2 client credentials:
   ```dart
   // lib/secret.dart
   class Secrets {
     static const String clientId = 'YOUR_QURAN_FOUNDATION_CLIENT_ID';
     static const String clientSecret = 'YOUR_QURAN_FOUNDATION_CLIENT_SECRET';
   }
   ```
*(Note: `lib/secret.dart` and `.env` files are already excluded in `.gitignore`)*

## 📁 Project Structure

```text
lib/
├── main.dart             # Application entry point and initialization
├── secret.dart           # (You must create this) OAuth2 environment variables
├── models/               # Freezed data models (Surah, Ayah, Bookmark, Hadith, etc.)
├── providers/            # Riverpod state management and providers
├── screens/              # UI screens (Home, Read Tab, Hadith Reader, etc.)
├── services/             # Core services (Quran APIs, Audio, OAuth, Background Tasks)
└── ui_v2/                # Custom design system, typography, and widgets
```

## 🔐 Cloud Sync

Quran2U is officially integrated with the **Quran.com API**. By signing in, you can seamlessly synchronize your bookmarks and progress securely via the cloud, ensuring your reading journey is always saved whether you are reading on the Quran.com website or inside the Quran2U app.
