<div align="center">

# Quran2U

**An immersive Quran companion for Android — built with Flutter.**

Read, listen, search, study and reflect. Quran2U pairs the complete Mushaf with
word-by-word linguistic analysis, interleaved audio translation, the six major
Hadith collections, a meaning-aware search engine, and official Quran.com cloud
sync.

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
eventually wants to **understand** — why a particular word was chosen, where
else it appears, what was happening when it was revealed, and what the Book
actually says about the thing they are living through today.

Three principles shape the codebase:

- **Offline first.** Reading, prayer times, Qibla, Hadith, supplications, the
  daily reminder and themed search all work with no connection. The network
  makes the app better, never functional.
- **Retrieve, never invent.** Every word the app displays is Quranic text, a
  published translation, a classical lexical note, or a hadith from a named
  collection — fetched and attributed. Nothing is generated.
- **No ads, no tracking.** See [Privacy](#privacy).

Released under the GPLv3.

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

### Search — *Ask the Quran*

A search box that answers a feeling as readily as a keyword. Two layers run
together, and their results are merged rather than chosen between.

| | |
|---|---|
| **Themed search** | 72 curated themes over 461 verified verse references. Ask *"i feel anxious"*, *"how should a husband treat his wife"* or *"trying to have a child"* and you get the ayat the tradition actually cites — not whichever verse happens to contain the word you typed. Entirely offline and effectively instant. |
| **Full-text search** | The same query is matched across the Arabic and roughly ninety published translations, so anything in the text is findable: *dhul qarnayn*, *she-camel*, *iron*, *honey*, or a half-remembered phrase. Matched words are highlighted, and every quote names its translator. |
| **Direct reference** | Type `2:255` and go straight there. |
| **Offline repeats** | Full-text results are cached per query, so a search you have run before still works with no connection — and says so rather than pretending otherwise. |

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
| **Hisnul Muslim** | Authentic supplications, categorised, with transliteration and references. |
| **Prayer times & Qibla** | Computed on-device (Karachi method, Hanafi) with a live countdown and a compass-based Qibla finder. |
| **Daily Inspiration** | A pool of 56 ayah-and-hadith pairs, one surfaced per calendar day. Every Arabic text is taken verbatim from the Quran.com API — never retyped — so the diacritics are exactly as published. |

### Sharing

| | |
|---|---|
| **Ayah cards** | Render any ayah as an image in four typographic styles — Obsidian, Manuscript, Jade and Paper — in square (1:1) or story (9:16) format. |
| **True 1080 px output** | Cards are laid out at a fixed 360 pt and captured at 3× scale, so the exported PNG is identical on every phone regardless of screen density. |

### Platform integration

| | |
|---|---|
| **Home-screen widget** | Six prayer times at a glance with the Hijri and Gregorian date. The active prayer is recalculated from the system clock on every redraw, so it cannot drift out of sync. |
| **Daily reminder** | One notification each morning carrying that day's actual ayah and reference, not a generic "tap to read". Settings shows how many days are armed and can fire a test immediately. |
| **Quran.com sync** | Sign in with your official Quran.com account over OAuth2 / OIDC; bookmarks stay unified with the website. |
| **In-app updates** | The app checks GitHub Releases and links you to the newest build when one is available. |

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

If `*.freezed.dart` or `*.g.dart` files are absent after cloning, generate them:

```bash
dart run build_runner build --delete-conflicting-outputs
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

Request credentials from the
[Quran Foundation developer portal](https://api-docs.quran.foundation/).
**The app builds and runs without them** — only cloud sync is disabled.

### Build and run

```bash
# Debug, on a connected device
flutter run

# Release APK, split per ABI
flutter build apk --split-per-abi

# Play Store bundle
flutter build appbundle
```

Release signing reads `android/key.properties`, which is git-ignored along with
`**/*.jks`. Neither the keystore nor its passwords are in this repository.

> **Test release builds, not just debug.** Two classes of bug only appear in a
> release APK: anything guarded by a `debug*` API (those getters assign inside
> an `assert`, and asserts are stripped, so reading one throws), and anything
> depending on tree-shaken reflection. `flutter run --release` catches both.

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
├── services/                  # API clients, audio, notifications, storage
├── data/                      # Bundled datasets
│   ├── quran_theme_index.dart      # 72 themes, 461 verse references
│   ├── quran_root_lexicon.dart     # Trilateral roots and surface forms
│   └── daily_inspiration_data.dart # 56 ayah + hadith pairs
└── ui_v2/                     # "Sakina" design system
    ├── app_colors.dart        # Palette
    ├── app_typography.dart    # Type scale
    ├── app_theme.dart         # Material theme
    ├── glass.dart             # Glass surface system
    └── widgets/               # Shared components
```

### Design system

The interface follows **Sakina** — a deliberately quiet visual language:
obsidian-green canvas, warm ivory text, a single interactive accent (jade), and
antique manuscript gold reserved for identity and Arabic. The eight-point star
(*Rub el Hizb*) is the recurring structural motif. All tokens live in
`lib/ui_v2/`; changing a value there re-skins the entire application.

Surfaces are built from two primitives with deliberately different costs, both
in `lib/ui_v2/glass.dart`:

- **`GlassSurface`** — a real `BackdropFilter` with a saturation boost, for
  chrome that genuinely floats above content: the navigation dock, modal
  sheets, dialogs.
- **`FrostedCard`** — the same visual language with no blur at all: a tint
  gradient plus a specular rim that reads as glass on a dark canvas for
  approximately zero cost. Everything that repeats in a list uses this one.

The rule the codebase enforces: **never put a `GlassSurface` inside a scrolling
list.** A backdrop blur forces a `saveLayer` and a gaussian pass on the raster
thread, and its cost scales with area; two of them in one scroll view is enough
to visibly drop frames on a mid-range phone. `GlassPanel` — the shared content
card — therefore defaults to the no-blur path, with an explicit `blur: true`
opt-in for the rare surface that earns it. `GlassConfig.blurEnabled = false`
degrades every glass surface to the zero-cost path in one line, for low-end
devices.

### Search architecture

`lib/services/quran_search_service.dart` implements the two layers described
above, and the interesting decisions are all about which layer answers what.

**Layer one — the concept index** (`lib/data/quran_theme_index.dart`) maps human
themes to the ayat the tradition consistently cites for them, plus the
vocabulary a person would actually type. Ranking is a small scoring function
over exact keywords, a crude English stemmer, and verbatim multi-word phrases.
It is pure, synchronous and offline, so the UI can paint matched themes in the
first frame after submit while the network layer is still in flight.

Critically, **the index stores verse keys only.** Arabic and translation text
are fetched separately, so a thematic grouping you might disagree with can
never cause the wrong text to be displayed.

**Layer two — full text** hands the raw query to the Quran.com search endpoint.
Curated hits lead (they are the trustworthy answer to *what does the Quran say
about X*); literal hits follow (they are the complete answer to *where does the
word X appear*), deduplicated against each other. Results are cached per query
under an LRU cap so repeats work offline.

**What this deliberately does not do** is send the query to a language model to
have an answer written. For religious content, a generated paraphrase that
reads like tafsīr is a liability rather than a feature — and an API key shipped
inside an APK is extractable by anyone who downloads it. Extending the index is
purely additive: append a `QuranTheme` and it becomes searchable.

### Performance

The app targets a smooth 60 fps on mid-range hardware, which on Android means
being deliberate about compositing layers. Four decisions carry most of it:

- **No full-screen backdrop blur.** The ambient background renders its glows as
  `RadialGradient`s that fade to transparent rather than hard circles softened
  by a `BackdropFilter`. The blurred version sat underneath every screen in the
  app and was re-rasterised on every frame of a 24-second animation.
- **Inactive tabs are `Offstage`, not faded.** An opacity strictly between 0 and
  1 forces a full-screen `saveLayer`, and a tab switch always has two tabs
  mid-animation. Hidden tabs keep their state and scroll position but are not
  painted, hit-tested or ticking; only the incoming tab animates.
- **Settings is lazy.** `ListView(children: [...])` evaluates its whole list on
  every build, so the heavy sections are wrapped in `Builder` and only
  constructed when scrolled into view. High-churn providers — download progress,
  the update check — are scoped into local `Consumer`s so a progress tick
  repaints a progress bar rather than the screen.
- **Font lookups are cached per weight.** `GoogleFonts.x()` runs a variant
  search and a registry check on every call; `AppTypeV2` resolves each family
  once, keyed by `FontWeight` (google_fonts returns a different family per
  weight, so a single cached string would silently render synthetic bold).

### Notable implementation details

- **The daily reminder arms fourteen independent alarms**, not one repeating
  alarm. Android drops every pending alarm an app owns when that app is
  force-stopped — and "clear all" in recents counts, as does any OEM battery
  cleaner. A single repeating alarm therefore dies quietly and never returns.
  Fourteen one-shots mean losing one does not lose the rest, and the window is
  refilled on every app resume. Scheduling attempts an exact alarm and falls
  back to inexact when `SCHEDULE_EXACT_ALARM` has not been granted, because a
  reminder that arrives late beats one that never arrives.
- **Hadith database** ships as a gzipped SQLite asset and is decompressed on
  first launch in a background isolate, written to a temp file and renamed
  atomically, so an interrupted install can never leave a corrupt database.
- **Word Study** resolves roots through a curated index of verified Quranic word
  forms, falling back to a built-in stemmer whose output is always labelled as
  an estimate rather than presented as fact.
- **Hijri dates** use a dependency-free tabular Islamic calendar implementation
  with a user-adjustable offset, matching the convention of established Islamic
  apps.
- **The prayer widget** stores each prayer as minutes-since-midnight and lets
  the native `AppWidgetProvider` decide which one is next at render time. The
  highlight is therefore self-correcting even when Android throttles background
  work.
- **Daily content rotates by day-of-epoch**, not day-of-month. The obvious
  `(day - 1) % length` caps at 31 and silently strands every entry past index
  30 — counting whole days from a fixed UTC epoch advances the index by exactly
  one per day and cycles the entire pool.
- **Text scaling** is clamped application-wide to 1.2×. Arabic set alongside
  English in a fixed-width card has very little slack, and an unbounded system
  font scale is the single most common source of layout overflow.

---

## Data sources

Quran2U is a client for established, authoritative services. All Quranic and
Hadith content is retrieved from or attributed to the sources below.

| Source | Used for |
|---|---|
| [Quran.com API v4](https://api-docs.quran.foundation/) | Surah metadata, Uthmani and Tajweed text, Mushaf pages, tafsir, translations, full-text search |
| [Quran Foundation OAuth2](https://api-docs.quran.foundation/) | Authentication and bookmark synchronisation |
| [EveryAyah](https://everyayah.com/) | Ayah-level recitation audio for Tarjumah Mode |
| [MP3Quran](https://mp3quran.net/) | Full-surah recitation audio |
| [fawazahmed0/hadith-api](https://github.com/fawazahmed0/hadith-api) | Source data for the bundled Hadith database |

Lexical notes in Word Study summarise the classical tradition — Ibn Fāris'
*Maqāyīs al-Lugha*, al-Rāghib al-Iṣfahānī's *Mufradāt*, and Lane's *Lexicon*.
The themed search index draws on commonly cited ayat.

**Neither is a fatwā.** Both are offered as starting points for reflection, and
the app says so in the interface. Always read the full passage and its tafsīr
in context.

---

## Privacy

- **No advertising, no analytics, no third-party trackers.** There is no
  telemetry SDK in the dependency tree.
- **Location never leaves the device.** Coordinates are used only to compute
  prayer times and the Qibla bearing locally, through the `adhan` package. They
  are not transmitted anywhere.
- **Credentials are stored in the Android keystore** via
  `flutter_secure_storage`, not in plain preferences.
- **Outbound traffic** goes only to the services listed under
  [Data sources](#data-sources), and only to fetch content you asked for.

---

## Roadmap

- [ ] **Daily Quiz** — ten questions a day, generated deterministically from the
      bundled datasets so every answer is correct by construction, with streaks
      and spaced repetition of missed questions
- [ ] Bundle surah metadata rather than fetching it, so a first launch works
      fully offline
- [ ] Expand the Word Study root lexicon beyond its current coverage
- [ ] Grow the search theme index — it is designed to be appended to
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

A few conventions worth knowing before sending a patch:

- Use the existing design tokens in `lib/ui_v2/` rather than introducing new
  colours or type styles.
- Prefer `FrostedCard` over `GlassSurface` for anything that appears more than
  once on screen, or anything inside a scroll view.
- New search themes belong in `lib/data/quran_theme_index.dart`; keep verse
  references verified, and store keys only — never text.
- New daily entries belong in `lib/data/daily_inspiration_data.dart`. Copy the
  Arabic from the API rather than typing it, and cut excerpts only at a clause
  boundary.
- Never branch on a `debug*` API. It compiles, passes in debug, and throws in
  release.

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
