<div align="center">

# Quran2U

**An immersive Quran companion for Android — built with Flutter.**

Read, listen, study and reflect. Quran2U pairs the complete Mushaf with
word-by-word linguistic analysis, interleaved audio translation, the six major
Hadith collections, and official Quran.com cloud sync.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)](#)
[![License](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/d0tahmed/Quran2U)](https://github.com/d0tahmed/Quran2U/releases)

[Download](https://github.com/d0tahmed/Quran2U/releases) ·
[Report a bug](https://github.com/d0tahmed/Quran2U/issues) ·
[Request a feature](https://github.com/d0tahmed/Quran2U/issues)

</div>

---

## Overview

Most Quran apps let you read. Quran2U is built around the idea that a reader
eventually wants to *understand* — why a particular word was chosen, where else
it appears, and what was happening when it was revealed.

The app is fully functional offline once content is cached, ships no
advertising or tracking, and is released under the GPLv3.

---

## Features

### Reading

| | |
|---|---|
| **Complete Mushaf** | All 604 pages in Uthmani, Indo-Pak and colour-coded Tajweed scripts, with page-accurate navigation. |
| **Word Study** | Press and hold any word to open its trilateral root, morphology, classical lexical meaning, and every other place that form appears in the Quran. |
| **Tafsir** | Verse-level commentary from Ibn Kathīr and Maʿāriful Qurʾān, served by Quran.com. |
| **100+ translations** | Any translation published through the Quran.com API v4, cached for offline reading. |
| **Continue reading** | The home screen resumes at your exact page. Long-press a page, or bookmark an ayah, to set the marker yourself. |

### Listening

| | |
|---|---|
| **Ten reciters** | As-Sudais, Alafasy, Al-Muaiqly, Ash-Shuraim, Yasser Ad-Dussary and more. |
| **Tarjumah Mode** | Interleaved playback — each ayah in Arabic, immediately followed by its English or Urdu recitation, synchronised ayah by ayah. |
| **Background audio** | Full lock-screen and notification controls via a media session. |
| **Offline downloads** | Per-surah or whole-Quran downloads, with or without the translation track. |

### Study & practice

| | |
|---|---|
| **Kutub al-Sittah** | All six canonical collections — Bukhari, Muslim, Abū Dāwūd, Tirmidhī, Nasāʾī and Ibn Mājah — in English, Arabic and Urdu, fully offline from a bundled database. Searchable by hadith number within a chapter. |
| **Hisnul Muslim** | 300+ authentic supplications, categorised, with transliteration and references. |
| **Prayer times & Qibla** | Computed on-device (Karachi method, Hanafi) with a live countdown and a compass-based Qibla finder. |
| **Daily Inspiration** | An ayah and a hadith delivered every morning at 6:00 AM local time. |

### Platform integration

| | |
|---|---|
| **Home-screen widget** | Six prayer times at a glance with the Hijri and Gregorian date. The active prayer is recalculated from the system clock on every redraw, so it cannot drift out of sync. |
| **Quran.com sync** | Sign in with your official Quran.com account over OAuth2 / OIDC; bookmarks stay unified with the website. |
| **In-app updates** | The app checks GitHub Releases and links you to the newest build when one is available. |

---

## Screenshots

> _Add screenshots to `docs/screenshots/` and reference them here._

| Home | Mushaf | Word Study | Widget |
|:---:|:---:|:---:|:---:|
| — | — | — | — |

---

## Getting started

### Prerequisites

- Flutter **3.x** (Dart SDK ≥ 3.0)
- JDK **17**
- Android SDK with **compileSdk 36**
- Android Gradle Plugin **8.11.1**

### Installation

```bash
git clone https://github.com/d0tahmed/Quran2U.git
cd Quran2U
flutter pub get
```

### Credentials

Cloud sync requires Quran Foundation OAuth2 credentials. Create
`lib/secret.dart` — the file is git-ignored, so your keys never leave your
machine:

```dart
// lib/secret.dart
class Secrets {
  static const String clientId     = 'YOUR_QURAN_FOUNDATION_CLIENT_ID';
  static const String clientSecret = 'YOUR_QURAN_FOUNDATION_CLIENT_SECRET';
}
```

Request credentials from the [Quran Foundation developer
portal](https://api-docs.quran.foundation/). The app builds and runs without
them — only cloud sync is disabled.

### Build and run

```bash
# Debug
flutter run

# Release APK, split per ABI
flutter build apk --split-per-abi
```

> **Note:** the data models are hand-written; `build_runner` is only needed if
> you modify the Freezed models in `lib/models/models.dart`:
> ```bash
> dart run build_runner build --delete-conflicting-outputs
> ```

---

## Architecture

Riverpod for state, a thin service layer over the network and database, and a
self-contained design system.

```text
lib/
├── main.dart                  # Entry point, auth gate, lifecycle hooks
├── secret.dart                # OAuth2 credentials (git-ignored — create this)
│
├── models/                    # Freezed models + hand-written value types
├── providers/                 # Riverpod providers and notifiers
├── screens/                   # UI, one file per screen
├── services/                  # API clients, audio, storage, background work
├── data/                      # Bundled datasets (Hisnul Muslim, root lexicon)
└── ui_v2/                     # "Sakina" design system
    ├── app_colors.dart        # Palette
    ├── app_typography.dart    # Type scale
    ├── app_theme.dart         # Material theme
    └── widgets/               # Shared components
```

### Design system

The interface follows **Sakina** — a deliberately quiet visual language:
obsidian-green canvas, warm ivory text, a single interactive accent (jade), and
antique manuscript gold reserved for identity and Arabic. The eight-point star
(*Rub el Hizb*) is the recurring structural motif. All tokens live in
`lib/ui_v2/`; changing a value there re-skins the entire application.

### Notable implementation details

- **Hadith database** ships as a 20 MB gzip asset and is decompressed on first
  launch in a background isolate, written to a temp file and renamed atomically
  so an interrupted install can never leave a corrupt database.
- **Word Study** resolves roots through a curated index of verified Quranic word
  forms, falling back to a built-in stemmer that is always labelled as an
  estimate rather than presented as fact.
- **Hijri dates** use a dependency-free tabular Islamic calendar implementation
  with a user-adjustable offset, matching the convention of established Islamic
  apps.
- **The prayer widget** stores each prayer as minutes-since-midnight and lets
  the native `AppWidgetProvider` decide which one is next at render time. The
  highlight is therefore self-correcting even when Android throttles background
  work.

---

## Data sources

Quran2U is a client for established, authoritative services. All Quranic and
Hadith content is retrieved from or attributed to the sources below.

| Source | Used for |
|---|---|
| [Quran.com API v4](https://api-docs.quran.foundation/) | Surah metadata, Uthmani and Tajweed text, Mushaf pages, tafsir, translations |
| [Quran Foundation OAuth2](https://api-docs.quran.foundation/) | Authentication and bookmark synchronisation |
| [EveryAyah](https://everyayah.com/) | Ayah-level recitation audio for Tarjumah Mode |
| [MP3Quran](https://mp3quran.net/) | Full-surah recitation audio |
| [fawazahmed0/hadith-api](https://github.com/fawazahmed0/hadith-api) | Source data for the bundled Hadith database |

Lexical notes in Word Study summarise the classical tradition — Ibn Fāris'
*Maqāyīs al-Lugha*, al-Rāghib al-Iṣfahānī's *Mufradāt*, and Lane's *Lexicon*.
They are offered for reflection, not as religious rulings.

---

## Roadmap

- [ ] Expand the Word Study root lexicon beyond its current coverage
- [ ] Hijri date adjustment control in Settings
- [ ] Configurable prayer calculation method and madhab
- [ ] Per-prayer adhan notifications
- [ ] iOS support

---

## Contributing

Issues and pull requests are welcome. For substantial changes, please open an
issue first so the approach can be discussed.

```bash
flutter analyze   # must be clean
flutter test
```

Please keep to the existing design tokens in `lib/ui_v2/` rather than
introducing new colours or type styles.

---

## License

Released under the **GNU General Public License v3.0**. See [LICENSE](LICENSE).

Quranic text, translations, tafsir and Hadith content remain the property of
their respective publishers and are used in accordance with their terms.

---

<div align="center">

Built by [@d0tahmed](https://github.com/d0tahmed)

*"And We have certainly made the Qurʾān easy for remembrance, so is there any who will remember?"* — **Al-Qamar 54:17**

</div>
