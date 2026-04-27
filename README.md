# 📖 Quran2U
**A Premium, Offline-First, Open-Source Quran Experience.**

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Architecture](https://img.shields.io/badge/Architecture-Riverpod-10B981)
![License](https://img.shields.io/badge/License-GPL_v3-blue)

Quran2U is a beautifully crafted, lightning-fast, and completely free Quran app. Designed with a stunning Glassmorphic UI, it features an advanced offline caching engine, dual-audio interleaved recitation with Urdu & English translation, Tajweed-coloured Mushaf, Tafseer, Prayer Times, a Qibla compass, and Quran.com cloud bookmark sync.

---

## ✨ Features

- 🎧 **Normal Recitation** — Full-surah MP3 playback with 10 reciters, fetched from **mp3quran.net**
- 🔁 **Interleaved Tarjumah** — Ayah-by-ayah Arabic + Urdu/English translation audio from **everyayah.com**
- 📖 **Mushaf / Digital Quran** — Page-by-page Uthmani & Indo-Pak script from **Quran.com API v4**
- 🎨 **Tajweed Mode** — Colour-coded tajweed text per mushaf page from **Quran.com API v4**
- 📚 **Tafseer** — Ibn Kathir (English) & Ma'ariful Quran (Urdu) from **Quran.com API v4**
- 🔖 **Smart Bookmarking** — Local bookmarks + cloud sync via **Quran Foundation Prelive API**
- 🔑 **OAuth2 Login** — Sign in with your Quran.com account via **Quran Foundation OAuth2**
- 🕌 **Prayer Times & Qibla** — 100% offline, GPS-based, Hanafi calculation (no API needed)
- 🌅 **Daily Ayah Notification** — Scheduled 6 AM notification (offline)
- 📱 **Background Audio** — OS-level lock-screen media controls via `just_audio_background`
- 💾 **Offline Downloads** — Download entire Surahs or the whole Quran for offline playback

---

## 🌐 APIs Used

### 1. Quran.com API v4
**Base URL:** `https://api.quran.com/api/v4`
**Auth:** None (public, no key required)

| Endpoint | Used In | Purpose |
|---|---|---|
| `GET /chapters` | `QuranApiService.fetchAllSurahs()` | Fetch the list of all 114 Surahs |
| `GET /verses/by_chapter/{surah}` | `QuranApiService.fetchSurahWithAyahs()` | Fetch ayah text + translations for a Surah |
| `GET /chapter_recitations/{qariId}/{surah}` | `QuranApiService.fetchAudioUrl()` | Fetch a Quran.com hosted audio URL (defined but not used in active playback) |
| `GET /resources/chapter_reciters` | `QuranApiService.fetchImams()` | Fetch available reciters from Quran.com (defined but imams are hardcoded in providers) |
| `GET /tafsirs/{tafsirId}/by_chapter/{surah}` | `TafseerService.fetchTafseerForSurah()` | Fetch Tafseer (Ibn Kathir / Ma'ariful Quran) |
| `GET /quran/verses/{script}?page_number={n}` | `MushafApiService.getPageText()` | Fetch Mushaf page text (Uthmani / Indo-Pak) |
| `GET /quran/verses/uthmani_tajweed?page_number={n}` | `MushafApiService.getPageTajweedData()` | Fetch tajweed-encoded HTML for a mushaf page |

**Files:** `lib/services/quran_api_service.dart`, `lib/services/tafseer_service.dart`, `lib/services/mushaf_api_service.dart`

---

### 2. mp3quran.net CDN
**Base URLs:** `https://server{N}.mp3quran.net/{reciter_folder}`
**Auth:** None (public CDN, no key required)

Used for **normal (non-interleaved) recitation mode**. Audio URLs are constructed entirely client-side as:
```
{imam.identifier}/{surahNumber_padded_3_digits}.mp3
// e.g. https://server11.mp3quran.net/sds/001.mp3
```

| Reciter | Server |
|---|---|
| Sheikh Abdul Rahman As-Sudais | `server11.mp3quran.net/sds` |
| Sheikh Mishary Rashid Alafasy | `server8.mp3quran.net/afs` |
| Sheikh Yasser Ad-Dusari | `server11.mp3quran.net/yasser` |
| Sheikh Mahir Al-Muaqily | `server12.mp3quran.net/maher` |
| Sheikh Saud As-Shuraim | `server7.mp3quran.net/shur` |
| Sheikh Ali Jabir | `server11.mp3quran.net/a_jbr` |
| Sheikh Bandar Al-Balilah | `server6.mp3quran.net/balilah` |
| Sheikh Nasser Al-Qatami | `server6.mp3quran.net/qtm` |
| Sheikh Muhammad Ayyoub | `server8.mp3quran.net/ayyub` |
| Sheikh Badr Al-Turki | `server10.mp3quran.net/bader/Rewayat-Hafs-A-n-Assem` |

**Files:** `lib/providers/providers.dart` (`audioUrlProvider`, `imamsProvider`), `lib/services/download_service.dart` (`downloadRecitation()`, `downloadEntireQuran()`)

---

### 3. everyayah.com CDN
**Base URL:** `https://www.everyayah.com/data`
**Auth:** None (public CDN, no key required)

Used for **interleaved Tarjumah mode** (ayah-by-ayah Arabic + translation audio). URL pattern:
```
https://www.everyayah.com/data/{folder}/{surah_3digits}{ayah_3digits}.mp3
// Arabic:  .../Abdurrahmaan_As-Sudais_192kbps/001001.mp3
// Urdu:    .../translations/urdu_shamshad_ali_khan_46kbps/001001.mp3
// English: .../English/Sahih_Intnl_Ibrahim_Walk_192kbps/001001.mp3
```

| Folder | Language | Reciter |
|---|---|---|
| `Abdurrahmaan_As-Sudais_192kbps` | Arabic | Sudais |
| `Alafasy_128kbps` | Arabic | Alafasy |
| `Yasser_Ad-Dussary_128kbps` | Arabic | Ad-Dusari |
| `MaherAlMuaiqly128kbps` | Arabic | Mahir Al-Muaqily |
| `Saood_ash-Shuraym_128kbps` | Arabic | Shuraim |
| `Ali_Jaber_64kbps` | Arabic | Ali Jabir |
| `Nasser_Alqatami_128kbps` | Arabic | Nasser Al-Qatami |
| `Muhammad_Ayyoub_128kbps` | Arabic | Muhammad Ayyoub |
| `translations/urdu_shamshad_ali_khan_46kbps` | Urdu | Shamshad Ali Khan |
| `English/Sahih_Intnl_Ibrahim_Walk_192kbps` | English | Ibrahim Walk |

**Files:** `lib/services/interleaved_audio_service.dart`, `lib/services/download_service.dart`

---

### 4. Quran Foundation Prelive API (OAuth2 + Cloud Sync)
**Base URLs:**
- Auth: `https://prelive-oauth2.quran.foundation`
- API:  `https://apis-prelive.quran.foundation`

**Auth:** OAuth2 OIDC with `flutter_appauth`. Tokens stored in `flutter_secure_storage`.

| Endpoint | Used In | Purpose |
|---|---|---|
| `POST /oauth2/auth` | `QuranAuthService.login()` | OAuth2 authorization (PKCE flow) |
| `POST /oauth2/token` | `QuranAuthService.login()` / `refreshToken()` | Exchange code / refresh access token |
| `POST /auth/v1/bookmarks` | `QuranAuthService.syncBookmark()` | Push a local bookmark to Quran.com cloud |
| `GET /auth/v1/bookmarks?mushafId=1&first=20` | `QuranAuthService.getBookmarks()` | Pull cloud bookmarks |
| `GET /auth/v1/collections` | `QuranAuthService.getCollections()` | Fetch user's Quran.com collections |

**Scopes used:** `openid`, `offline_access`, `user`, `collection`, `bookmark`, `profile`

**Files:** `lib/services/quran_auth_service.dart`, `lib/providers/providers.dart` (`BookmarkSyncNotifier`)

---

## 🛠️ Tech Stack

| Concern | Library |
|---|---|
| Framework | Flutter (Material 3) |
| State Management | `flutter_riverpod` |
| Audio Engine | `just_audio` + `just_audio_background` |
| Networking | `dio` (cancelable tokens), `http` |
| Local Storage | `shared_preferences`, `path_provider` |
| Secure Storage | `flutter_secure_storage` |
| OAuth2 | `flutter_appauth` |
| Geolocation | `geolocator`, `flutter_compass` |
| Prayer Time Math | `adhan` |
| Notifications | `flutter_local_notifications` |
| Code Generation | `freezed`, `build_runner` |

---

## 🚀 Installation & Setup

### Prerequisites
- Flutter 3.0+
- Dart 3.0+
- Android Studio / VS Code

### Run Locally
```bash
# 1. Clone the repository
git clone https://github.com/d0tahmed/quran-recitation.git
cd quran-recitation

# 2. Fetch dependencies
flutter pub get

# 3. Generate Freezed models
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Run the app!
flutter run
```

### OAuth2 Setup (Optional — only needed for cloud bookmark sync)
The app uses the **Quran Foundation prelive (staging)** environment.
- Client credentials are hardcoded in `lib/services/quran_auth_service.dart`
- The redirect URI `quran2u://oauth2redirect` must be registered in your Quran Foundation app dashboard
- On Android, the intent filter in `android/app/src/main/AndroidManifest.xml` must match the redirect URI scheme

> ⚠️ The prelive environment is a staging server. For production, update the endpoint constants in `QuranAuthService` to the production Quran Foundation URLs.

---

## 📦 Building for Production / Release

```bash
flutter build apk --release --split-per-abi (Updated README.md)

## 📁 Project Structure

```
lib/
├── main.dart                        # App entry point, JustAudioBackground init
├── models/                          # Freezed data models (Surah, Ayah, Imam, Bookmark…)
├── providers/
│   └── providers.dart               # All Riverpod providers (audio URL builder, imams, sync…)
├── screens/                         # UI screens
│   ├── home_screen.dart
│   ├── surah_detail_screen.dart     # Main recitation + tarjumah screen
│   ├── now_playing_screen.dart
│   ├── mushaf_screen.dart
│   ├── bookmarks_screen.dart
│   ├── settings_screen.dart
│   └── login_screen.dart
└── services/
    ├── quran_api_service.dart        # Quran.com API v4 (surahs, ayahs, tafseer, mushaf)
    ├── tafseer_service.dart          # Quran.com API v4 (tafseer)
    ├── mushaf_api_service.dart       # Quran.com API v4 (mushaf pages, tajweed)
    ├── audio_player_service.dart     # Normal recitation player (mp3quran.net)
    ├── interleaved_audio_service.dart # Tarjumah player (everyayah.com)
    ├── download_service.dart         # Offline downloads (mp3quran.net + everyayah.com)
    └── quran_auth_service.dart       # OAuth2 + Quran Foundation cloud sync
```

---

## 📜 License

This project is licensed under the **GNU General Public License v3.0**. See [LICENSE](LICENSE) for details.
