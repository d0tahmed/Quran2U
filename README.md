# Quran2U

Welcome to **Quran2U**, a beautifully designed, feature-rich Islamic application built with Flutter. Quran2U goes beyond simply reading the Quran by offering an immersive, deeply integrated ecosystem featuring cloud sync, audio interleaving, and comprehensive Hadith collections.

## ✨ Key Features

*   **📖 The Holy Quran & Tafseer:** Read the Quran in a beautiful, distraction-free interface with built-in, detailed Tafseer powered by Quran.com.
*   **🎧 Interleaved Audio Translations:** Listen to world-renowned reciters with groundbreaking English & Urdu interleaved audio translation, perfectly synchronized Ayah-by-Ayah.
*   **📚 Kutub al-Sittah (Hadith Library):** A fully offline-capable Hadith reader featuring the six major authentic collections (Sahih al-Bukhari, Sahih Muslim, Sunan Abu Dawood, Jami' at-Tirmidhi, Sunan an-Nasa'i, and Sunan Ibn Majah) with seamless multi-language support (English, Arabic, Urdu).
*   **🤲 300+ Daily Duas (Hisnul Muslim):** A vast, categorized collection of authentic supplications from Hisnul Muslim, directly integrated into the app.
*   **☁️ Official Quran.com Integration:** Sign in with your official Quran.com account using secure OAuth2 to instantly sync your bookmarks across all your devices and the web.
*   **🌅 Daily Inspirations:** Wake up to daily Ayah and Hadith notifications triggered precisely at 6:00 AM local time.
*   **📱 Home Screen Prayer Widget:** Keep track of your daily Salah times right from your Android home screen with a sleek, natively updating widget.
*   **⚙️ UPDATE BUTTON IN THE APP:** Now you can click on "UPDATE" button at the top right corner of the app's homepage which then will redirect user to the github releases which the user can download the new release if there is new version available.
## 🚀 Setup Instructions

1. Clone the repository:
   ```bash
   git clone https://github.com/d0tahmed/quran-recitation.git
   cd quran-recitation
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

## 📁 Project Structure

```text
lib/
├── main.dart             # Application entry point and initialization
├── models/               # Freezed data models (Surah, Ayah, Bookmark, Hadith, etc.)
├── providers/            # Riverpod state management and providers
├── screens/              # UI screens (Home, Read Tab, Hadith Reader, etc.)
├── services/             # Core services (Quran APIs, Audio, OAuth, Background Tasks)
└── ui_v2/                # Custom design system, typography, and widgets
```

## 🔐 Cloud Sync

Quran2U is officially integrated with the **Quran.com API**. By signing in, you can seamlessly synchronize your bookmarks and progress securely via the cloud, ensuring your reading journey is always saved whether you are reading on the Quran.com website or inside the Quran2U app.
