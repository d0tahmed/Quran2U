// lib/data/changelog_data.dart
//
// The release history, kept in the binary rather than fetched.
//
// Fetching it from GitHub would mean the one screen that explains "what
// changed in the version you are holding" is the one screen that needs a
// network connection to work. It is also the screen someone opens right after
// an update goes wrong — which is exactly when they may have no signal.
//
// Every entry below is transcribed from the real release notes at
// github.com/d0tahmed/Quran2U/releases.
//
// WHEN YOU CUT A NEW RELEASE:
//   1. Add an entry at the TOP of [kChangelog].
//   2. Clear `unreleased` on the previous top entry and set its real date.
// Nothing else needs touching — the screen finds the running version by
// matching the app's own version string, so no flag has to be moved by hand.

import 'package:flutter/material.dart';

/// Groups the bullet points of one release under a heading.
@immutable
class ChangeGroup {
  final String title;
  final IconData icon;
  final List<String> items;

  const ChangeGroup({
    required this.title,
    required this.icon,
    required this.items,
  });
}

@immutable
class ChangelogEntry {
  /// Version string exactly as it appears in pubspec, with no leading v.
  /// This is what gets matched against the running build.
  final String version;

  /// One line under the version — what this release was about.
  final String headline;

  /// Release date, split into parts so the whole list can stay `const`.
  /// (DateTime has no const constructor.)
  final int year;
  final int month;
  final int day;

  final List<ChangeGroup> groups;

  /// Finished work that has not been cut into a release yet.
  final bool unreleased;

  /// A short line shown in italics under the headline. Used sparingly.
  final String? note;

  const ChangelogEntry({
    required this.version,
    required this.headline,
    required this.year,
    required this.month,
    required this.day,
    required this.groups,
    this.unreleased = false,
    this.note,
  });

  DateTime get date => DateTime(year, month, day);

  /// Total bullet points, for the "18 changes" line on the collapsed card.
  int get changeCount => groups.fold<int>(0, (sum, g) => sum + g.items.length);

  /// The leading number of the version — 4 for "4.0.0".
  int get majorNumber =>
      int.tryParse(version.split('.').first.replaceAll(RegExp(r'\D'), '')) ?? 0;
}

/// Whether the entry at [index] crossed a major version boundary.
///
/// Derived rather than stored: a release is major when its leading number is
/// higher than the release before it — 3.0.3 → 4.0.0 is major, 3.0.2 → 3.0.3
/// is not. Nothing has to be flagged by hand when a new entry is added.
bool isMajorRelease(int index) {
  if (index < 0 || index >= kChangelog.length) return false;
  final previous = index + 1; // the list runs newest first
  if (previous >= kChangelog.length) return false; // the first release ever
  return kChangelog[index].majorNumber > kChangelog[previous].majorNumber;
}

/// True only for the oldest entry — the release that started everything.
bool isFirstRelease(int index) => index == kChangelog.length - 1;

// ── Icons, named once so the entries below stay readable ────────────────────

const IconData _new = Icons.auto_awesome_rounded;
const IconData _perf = Icons.bolt_rounded;
const IconData _fix = Icons.build_rounded;
const IconData _ui = Icons.palette_rounded;
const IconData _audio = Icons.graphic_eq_rounded;
const IconData _read = Icons.menu_book_rounded;
const IconData _under = Icons.settings_suggest_rounded;
const IconData _notify = Icons.notifications_active_rounded;

/// Newest first. This order is what the screen renders.
const List<ChangelogEntry> kChangelog = <ChangelogEntry>[
  // ───────────────────────────────────────────────────────────────────────────
  ChangelogEntry(
    version: '4.0.0',
    headline: 'The adhan arrives, and the Quran starts '
        'asking the questions',
    year: 2026,
    month: 8,
    day: 24,
    unreleased: true,
    note: 'Finished and in testing — this is what lands in the next build.',
    groups: <ChangeGroup>[
      ChangeGroup(
        title: 'Adhan',
        icon: _audio,
        items: <String>[
          'The call to prayer now plays at Fajr, Dhuhr, Asr, Maghrib and '
              'Isha, scheduled through the Android alarm clock so it fires on '
              'time even in Doze with the app closed and swiped away.',
          'The recitation is the Madinah adhan by Shaykh Muhammad Marwan '
              'Qassas, bundled complete and uncut.',
          'It plays on the alarm stream, so it is heard on silent and through '
              'Do Not Disturb — the way an alarm should be.',
          'Per-prayer control: full adhan, a silent notification, or off. All '
              'five are set independently in Settings.',
          'A Stop action on the adhan notification, and a hard seven-minute '
              'ceiling on the wake lock so stuck playback can never drain the '
              'battery.',
          'It survives a reboot, a timezone change and a manual clock change — '
              'the alarms rearm themselves on all three.',
          'Sunrise is never audible by design — it marks the end of Fajr, not '
              'a prayer.',
        ],
      ),
      ChangeGroup(
        title: 'Daily Quiz',
        icon: _new,
        items: <String>[
          'Ten new questions every day, generated from the Quran\'s own '
              'structure — surah names and their meanings, Makki or Madani, '
              'order of revelation, ayah counts, themes, and the ayah of the '
              'day.',
          'Questions run easy to hard, and every device gets the same quiz on '
              'the same date — so it can be compared, and it cannot be '
              'rerolled for an easier one.',
          'Stars for your score, and a streak that counts the days you showed '
              'up rather than the days you scored well.',
          'A progress screen with a twelve-week calendar, mastery bars per '
              'topic, your weakest area called out, and all-time accuracy.',
          'Every answer explains itself the moment you tap, and links straight '
              'to the surah it came from.',
          'A Hint on every question — a real one, drawn from the same data the '
              'question was built from, that narrows the field without giving '
              'the answer away. Hints are counted, never penalised.',
          'The surah dataset behind it — all 114 chapters with names, '
              'meanings, revelation place and ayah counts — is bundled, so the '
              'quiz works with no connection.',
          'A progress calendar you can tap: any day shows what you scored, or '
              'when it unlocks if it has not come round yet.',
        ],
      ),
      ChangeGroup(
        title: 'Daily reminder',
        icon: _notify,
        items: <String>[
          'Rebuilt the daily notification, which used to arrive only rarely. '
              'It now schedules fourteen independent alarms ahead of time '
              'instead of trusting one repeating alarm that Android drops '
              'silently whenever the app is force-stopped.',
          'The notification carries the day\'s actual ayah instead of a '
              'generic line.',
          'Settings shows exactly how many days are armed and when the next '
              'one arrives, and can fire a test immediately — so you can see '
              'it is working rather than hope.',
          'When Android has withheld exact alarms, the app says so and offers '
              'the one setting that fixes it, instead of failing quietly.',
          'The daily pool grew to 56 ayat and ahadith with translations, every '
              'Arabic text taken verbatim from the Quran.com API rather than '
              'retyped.',
          'Fixed the rotation bug that made five of those entries unreachable '
              '— the index capped at 31 and never went past it.',
        ],
      ),
      ChangeGroup(
        title: 'Performance',
        icon: _perf,
        items: <String>[
          'Removed the full-screen blur that sat under every screen in the app '
              'and was redrawn on every frame of a 24-second animation. The '
              'background is painted gradients now — the same look for a '
              'fraction of the cost.',
          'Fixed the stutter when switching tabs quickly. Hidden tabs keep '
              'their scroll position but stop painting, stop being hit-tested '
              'and stop ticking entirely.',
          'Settings no longer builds every section on every rebuild, and the '
              'download and update-check state was scoped so a progress tick '
              'repaints a progress bar instead of the whole screen.',
          'Fonts are cached per weight. They were being re-resolved on every '
              'text style, which is why text-heavy screens hitched.',
          'Fixed the Daily section lagging while scrolling — a glass panel '
              'with a real backdrop blur had crept into a scroll view.',
          'Fixed the Settings scroll stutter. Two hundred and eight places in '
              'the app were re-resolving a font on every build; a list only '
              'builds the rows it is about to show, so that cost landed '
              'squarely on the frames doing the scrolling. Resolved once per '
              'weight now, and reused.',
          'Glass gradients are cached and shared between identical surfaces, '
              'so a long list no longer builds a hundred of them mid-fling.',
          'Pressing a card no longer rebuilds it — only the transform moves.',
          'Switching tabs is instant. The old fade left the incoming page '
              'translucent for a moment, which washed the screen dark and read '
              'as a shadow of the page you had just left.',
          'The app now measures its own frame times on the device it is '
              'actually running on and eases off the heavier effects if that '
              'phone cannot afford them — instead of guessing from a model '
              'name.',
        ],
      ),
      ChangeGroup(
        title: 'Design',
        icon: _ui,
        items: <String>[
          'A rebuilt glass system across the whole app: real depth on the '
              'surfaces that genuinely float — the nav dock, sheets, dialogs — '
              'and a convincing frosted surface everywhere blur would cost '
              'frames.',
          'The navigation dock is a proper glass island now. One highlight '
              'travels along it to whatever you tapped instead of four '
              'separate buttons fading against each other, and the fill is '
              'thin enough that the page actually shows through.',
          'Layered speculars, an inner bevel and a lit top edge on every glass '
              'surface, so they read as panes with thickness rather than flat '
              'tinted rectangles.',
          'Fixed quick-action tiles drawing their label outside the card, and '
              'the prayer countdown pill not sitting flush to the edge.',
          'Fixed the enabled toggle rendering as a solid green pill with no '
              'visible thumb.',
          'The adhan settings now unfold when you switch them on instead of '
              'snapping to their new height.',
        ],
      ),
      ChangeGroup(
        title: 'What\'s new screen',
        icon: _read,
        items: <String>[
          'This screen. Every release since v1.0.0, offline, with the major '
              'ones marked — because a changelog you can only read with a '
              'signal is the one thing you need after an update goes wrong.',
        ],
      ),
      ChangeGroup(
        title: 'Fixes',
        icon: _fix,
        items: <String>[
          'Fixed "Could not render the card." when sharing an ayah. The '
              'capture used a debug-only check that throws in release builds, '
              'which is why it failed on real phones and never in testing.',
          'Fixed an image leak in the same share flow.',
          'Fixed the adhan announcing the wrong prayer. An alarm used to be '
              'identified by its place in a queue, and that queue is rebuilt '
              'every time the app opens — so an alarm set for one prayer could '
              'be delivered carrying the next one\'s name. Each alarm now '
              'carries which prayer on which day, and the adhan refuses to '
              'sound at all if the clock does not agree with the schedule.',
          'Fixed the daily reminder row in Settings overlapping its own '
              'button.',
          'Fixed the quiz calendar running off the edge of its card.',
          'Fixed the progress calendar labelling itself a day early for '
              'anyone west of UTC.',
          'Report a Bug now opens Instagram, and the About panel has been '
              'trimmed to what people actually look for.',
          'Corrected a mislabelled Settings section.',
        ],
      ),
    ],
  ),

  // ───────────────────────────────────────────────────────────────────────────
  ChangelogEntry(
    version: '3.0.3',
    headline: '100+ text translations, and an update button inside the app',
    year: 2026,
    month: 5,
    day: 12,
    groups: <ChangeGroup>[
      ChangeGroup(
        title: 'What\'s new',
        icon: _new,
        items: <String>[
          'Over 100 languages of Quran text translation, through the '
              'Quran.com v4 API.',
          'An Update button in the top right of the home screen that takes '
              'you to the newest release whenever one exists.',
          'Search hadith by number inside a chapter.',
        ],
      ),
      ChangeGroup(
        title: 'What this version contains',
        icon: _read,
        items: <String>[
          'The Holy Quran and Tafseer, in a distraction-free reader powered '
              'by Quran.com.',
          'Interleaved audio translation — Arabic then English or Urdu, '
              'synchronised ayah by ayah.',
          'Kutub al-Sittah: all six major collections, fully offline, in '
              'English, Arabic and Urdu.',
          '300+ authentic supplications from Hisnul Muslim, categorised.',
          'Sign in with Quran.com over OAuth2 to sync bookmarks across your '
              'devices and the web.',
          'Daily Ayah and Hadith notifications at 6:00 AM local time.',
          'A home screen prayer times widget.',
        ],
      ),
    ],
  ),

  // ───────────────────────────────────────────────────────────────────────────
  ChangelogEntry(
    version: '3.0.2',
    headline: 'Offline hadith finished, and a large performance pass',
    year: 2026,
    month: 5,
    day: 7,
    groups: <ChangeGroup>[
      ChangeGroup(
        title: 'What\'s new',
        icon: _new,
        items: <String>[
          'The Kutub al-Sittah offline database is finished. Sahih Muslim and '
              'the rest read entirely offline with full Arabic, English and '
              'Urdu.',
          'The background notification engine was rewritten. The daily Ayah '
              'and Hadith arrive at 6:00 AM in your device\'s own timezone, '
              'and survive the app being swiped away.',
        ],
      ),
      ChangeGroup(
        title: 'Performance and UI',
        icon: _perf,
        items: <String>[
          'Smooth scrolling at 120Hz. We found and removed the heavy '
              'BackdropFilter glass panels sitting inside list views that '
              'were dropping frames on Bookmarks and Downloads.',
          'The navigation bar hides as you scroll, and the empty space at the '
              'bottom of Home, Bookmarks and Read is gone.',
          'Layouts reworked with Expanded and Flexible for zero pixel '
              'overflow, from small budget phones up to tablets.',
        ],
      ),
      ChangeGroup(
        title: 'Under the hood',
        icon: _under,
        items: <String>[
          'Hardened .gitignore so OAuth2 secrets and API keys stay out of the '
              'repository, while hadith.db still bundles into the build.',
          'Cleared every remaining analyzer warning, removed deprecated '
              'Workmanager flags, and rewrote the README.',
        ],
      ),
    ],
  ),

  // ───────────────────────────────────────────────────────────────────────────
  ChangelogEntry(
    version: '3.0.1',
    headline: 'Quran.com linked, Kutub al-Sittah, new interleaved audio',
    year: 2026,
    month: 5,
    day: 6,
    groups: <ChangeGroup>[
      ChangeGroup(
        title: 'What\'s new',
        icon: _new,
        items: <String>[
          'Official Quran.com account integration.',
          'The Kutub al-Sittah offline SQLite database, with multi-language '
              'support.',
          'A rewritten background engine for the Daily Inspiration '
              'notification.',
        ],
      ),
      ChangeGroup(
        title: 'Performance and UI',
        icon: _perf,
        items: <String>[
          'Removed glass blur from inside list views for smooth scrolling.',
          'An auto-hiding navigation bar, and no more dead space at the '
              'bottom of the main screens.',
          'Constraint fixes across the app for zero overflow errors.',
        ],
      ),
      ChangeGroup(
        title: 'Under the hood',
        icon: _under,
        items: <String>[
          'Security hardening around secrets and keys.',
          'Analyzer warnings cleared, deprecated flags removed.',
        ],
      ),
    ],
  ),

  // ───────────────────────────────────────────────────────────────────────────
  ChangelogEntry(
    version: '2.0.0',
    headline: 'The app rebuilt — glass design, Tarjumah mode, ten reciters',
    year: 2026,
    month: 4,
    day: 17,
    note: 'The biggest update in Quran2U\'s history.',
    groups: <ChangeGroup>[
      ChangeGroup(
        title: 'A new interface',
        icon: _ui,
        items: <String>[
          'A fully redesigned UI with glass panels, smooth animation, and a '
              'dark theme built for reading late at night.',
          'A new home screen with Daily Inspiration, Bookmarks and the next '
              'prayer at a glance.',
          'A persistent mini-player on every screen, so you never lose the '
              'recitation you were listening to.',
        ],
      ),
      ChangeGroup(
        title: 'Tarjumah mode',
        icon: _audio,
        items: <String>[
          'Listen to the Arabic recitation followed immediately by the Urdu '
              'translation of Shamshad Ali Khan, ayah by ayah.',
          'The screen highlights whether the Arabic or the Urdu segment is '
              'playing, so the meaning stays in step with the sound.',
        ],
      ),
      ChangeGroup(
        title: 'Ten reciters',
        icon: _audio,
        items: <String>[
          'Sheikh Abdul Rahman As-Sudais.',
          'Sheikh Mishary Rashid Alafasy.',
          'Sheikh Yasser Ad-Dusari.',
          'Sheikh Nasser Al-Qatami (new).',
          'Sheikh Muhammad Ayyoub (new).',
          'And five more.',
        ],
      ),
      ChangeGroup(
        title: 'Downloads and reading',
        icon: _read,
        items: <String>[
          'A download manager that saves either the full recitation or '
              'recitation plus Urdu tarjumah, with live progress.',
          'Urdu set in Noto Nastaliq Urdu, so every flourish renders properly '
              'with no clipping.',
          'One-tap ayah bookmarking.',
        ],
      ),
      ChangeGroup(
        title: 'Under the hood',
        icon: _under,
        items: <String>[
          'Large performance gains from moving to Riverpod.',
          'Fixed text overflow and audio looping bugs.',
        ],
      ),
    ],
  ),

  // ───────────────────────────────────────────────────────────────────────────
  ChangelogEntry(
    version: '1.2.1',
    headline: 'Open source compliance',
    year: 2026,
    month: 4,
    day: 6,
    groups: <ChangeGroup>[
      ChangeGroup(
        title: 'Changes',
        icon: _under,
        items: <String>[
          'Updated README.',
          'Added Fastlane metadata images.',
          'FOSS dependency overrides for geolocation.',
        ],
      ),
    ],
  ),

  // ───────────────────────────────────────────────────────────────────────────
  ChangelogEntry(
    version: '1.2.0',
    headline: 'Tajweed engine and advanced looping',
    year: 2026,
    month: 4,
    day: 6,
    groups: <ChangeGroup>[
      ChangeGroup(
        title: 'What\'s new',
        icon: _new,
        items: <String>[
          'An interactive Tajweed view with colour-coded text, so you can see '
              'the rules while you read.',
          'A Tajweed learning guide in Settings explaining what each colour '
              'means.',
          'Advanced audio looping. Repeat a single ayah for hifz, or loop a '
              'whole surah continuously.',
        ],
      ),
      ChangeGroup(
        title: 'Fixes',
        icon: _fix,
        items: <String>[
          'Corrected the transliteration of Surah Sad to "Suad" in the index.',
          'Fixed overflow in the full-screen player and the mini-player.',
          'General stability work on the offline experience.',
        ],
      ),
    ],
  ),

  // ───────────────────────────────────────────────────────────────────────────
  ChangelogEntry(
    version: '1.0.0',
    headline: 'The first release',
    year: 2026,
    month: 4,
    day: 4,
    note: 'A gift for my Mother and my late Grandmother. '
        'May Allah reward both.',
    groups: <ChangeGroup>[
      ChangeGroup(
        title: 'What shipped',
        icon: _new,
        items: <String>[
          'A smart offline caching engine — download one surah or all 114, '
              'then listen with no connection at all.',
          'Dual-audio interleaving that alternates Arabic recitation and Urdu '
              'tarjumah ayah by ayah without stuttering.',
          'Background playback with native lock-screen controls.',
          'Uthmani and Indo-Pak reading modes, cached for instant opening.',
          'Offline prayer times from your GPS coordinates, and a haptic Qibla '
              'compass.',
          'The Daily Inspiration engine — an exact alarm delivering an ayah '
              'and a hadith at 6:00 AM.',
          'Bookmarking for individual ayat and for whole surahs.',
        ],
      ),
      ChangeGroup(
        title: 'Built with',
        icon: _under,
        items: <String>[
          'Flutter, with unidirectional state flow through Riverpod.',
          'Dio with cancelable tokens for the large audio downloads.',
        ],
      ),
    ],
  ),
];

/// The newest entry that has actually been released.
ChangelogEntry get latestReleased =>
    kChangelog.firstWhere((e) => !e.unreleased, orElse: () => kChangelog.first);
