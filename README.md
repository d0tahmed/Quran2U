# Quran2U

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
├── models/               # Freezed data models (Surah, Ayah, Bookmark, etc.)
├── providers/            # Riverpod state management and providers
├── screens/              # UI screens (Home, Read Tab, Surah Detail, Settings, etc.)
├── services/             # Core services (Quran APIs, Audio, Auth, Downloads)
└── ui_v2/                # Custom design system, typography, and widgets
```

## 🔐 Official Quran.com Integration

Quran2U is officially integrated with the **Quran.com API**. 

By signing in with your official Quran.com account, you can seamlessly synchronize your bookmarks and progress securely via the cloud. This ensures your reading journey is always saved, whether you are reading on the Quran.com website or inside the Quran2U app.
