# 📖 Quran2U 
**A Premium, Offline-First, Open-Source Quran Experience.**

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Architecture](https://img.shields.io/badge/Architecture-Riverpod-10B981)
![License](https://img.shields.io/badge/License-GPL_v3-blue)

Quran2U is a beautifully crafted, lightning-fast, and completely free Quran app. Designed with a stunning Glassmorphic UI, it features an advanced offline caching engine, dual-audio interleaved recitation, and robust background playback.
---

## ✨ Enterprise-Grade Features

* 🌍 **Smart Offline Engine:** Download entire Surahs—or the entire Quran—for true offline playback. The app intelligently manages your local storage.
* 🎧 **Dual-Audio Interleaving:** Listen to Arabic recitation seamlessly interleaved with Urdu translation of (Shamshad Ali Khan) ayah-by-ayah.
* 📖 **Instant Reading Engine:** High-speed, cached Uthmani and Indo-Pak script reading modes with a beautifully ornamented UI.
* 🕌 **Prayer Times & Qibla Compass:** 100% offline, mathematically calculated prayer times based on your GPS coordinates, featuring a buttery-smooth, haptic-enabled Qibla compass.
* 🌅 **Daily Inspiration Engine:** Wakes up with you. A scheduled background notification delivers a daily Ayah and Hadith exactly at 6:00 AM.
* 🔖 **Smart Bookmarking:** Save specific Ayahs or entire Surahs with a single tap, persisted safely to your local device.
* 📱 **Background Audio:** Full OS-level background playback integration with lock-screen media controls.

---

## 🛠️ The Tech Stack

This project abandons heavy, bloated architectures in favor of a lean, high-performance stack:

* **Framework:** Flutter (Material 3)
* **State Management:** `flutter_riverpod` (Unidirectional data flow)
* **Audio Engine:** `just_audio` & `just_audio_background`
* **Networking:** `dio` (with cancelable download tokens for large files)
* **Local Storage:** `shared_preferences` & `path_provider` (Direct File I/O)
* **Geolocation & Math:** `geolocator`, `flutter_compass`, and `adhan`
* **Background Tasks:** `flutter_local_notifications` (Android 14 Exact Alarm compliant)

---

## 🚀 Installation & Setup

### Prerequisites
* Flutter 3.0+
* Dart 3.0+
* Android Studio / VS Code

### Run Locally
```bash
# 1. Clone the repository
git clone [https://github.com/d0tahmed/quran-recitation.git](https://github.com/d0tahmed/quran-recitation.git)
cd quran-recitation

# 2. Fetch dependencies
flutter pub get

# 3. Generate Freezed models
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Run the app!
flutter run
