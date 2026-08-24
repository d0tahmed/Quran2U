// lib/services/quiz_engine.dart
//
// The daily quiz.
//
// HOW UNIQUENESS IS ACHIEVED WITHOUT AUTHORING 3,650 QUESTIONS
// -----------------------------------------------------------
// Ten questions a day for a year is three and a half thousand questions, and
// in a Quran app every one has to be correct. Neither hand-writing them nor
// generating them with a language model survives that requirement — the first
// is a year of work, the second produces confident errors at a rate low enough
// to miss and high enough for users to find.
//
// So nothing here is authored and nothing is invented. Each generator reads a
// record the app already ships and phrases it as a question. The answer is
// correct by construction, because it IS the record. The wrong answers are
// drawn from other real records of the same kind, never from arithmetic — a
// distractor computed as `correct ± random(20)` will eventually equal the
// correct answer and mark a right choice wrong.
//
// THE DAY IS THE SEED
// -------------------
// `Random(dayIndex)` means everyone gets the same ten questions on the same
// date, the quiz survives a reinstall mid-attempt, and none of it needs a
// server or a network.

import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:quran_recitation/data/daily_inspiration_data.dart';
import 'package:quran_recitation/data/quran_surah_data.dart';
import 'package:quran_recitation/data/quran_theme_index.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

enum QuizCategory { surah, revelation, structure, themes, dailyAyah }

extension QuizCategoryX on QuizCategory {
  String get label {
    switch (this) {
      case QuizCategory.surah:
        return 'Surahs';
      case QuizCategory.revelation:
        return 'Revelation';
      case QuizCategory.structure:
        return 'Structure';
      case QuizCategory.themes:
        return 'Themes';
      case QuizCategory.dailyAyah:
        return 'Ayat';
    }
  }
}

enum QuizDifficulty { easy, medium, hard }

@immutable
class QuizQuestion {
  /// Stable across rebuilds of the same question — used by the review queue.
  final String id;
  final QuizCategory category;
  final QuizDifficulty difficulty;
  final String prompt;
  final List<String> options;
  final int correctIndex;

  /// One line shown after answering. Always states the fact, never a guess.
  final String why;

  /// Shown when the player asks for help, before answering.
  ///
  /// A hint has one job: cut the field down using a fact the player can
  /// reason from. It must never name the answer, never be a restatement of
  /// the question, and never be generic encouragement — "think carefully" is
  /// not a hint, it is a waste of a tap. Every hint below states a real,
  /// checkable property that at least one wrong option fails.
  final String hint;

  /// Where to send someone who wants to read more (surah number, or null).
  final int? openSurah;

  const QuizQuestion({
    required this.id,
    required this.category,
    required this.difficulty,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.why,
    required this.hint,
    this.openSurah,
  });

  String get correctAnswer => options[correctIndex];
}

@immutable
class DailyQuiz {
  final int dayIndex;
  final List<QuizQuestion> questions;
  const DailyQuiz({required this.dayIndex, required this.questions});
}

// ─────────────────────────────────────────────────────────────────────────────
// Generators
// ─────────────────────────────────────────────────────────────────────────────

/// A generator returns a question, or null when it cannot guarantee one for
/// the values it drew. Returning null is always better than returning a
/// question whose answer is arguable.
typedef QuizGenerator = QuizQuestion? Function(Random rng);

class QuizEngine {
  QuizEngine._();

  static const int questionsPerQuiz = 10;

  /// The mix the builder aims for. Easy first so the quiz opens winnably.
  static const Map<QuizDifficulty, int> mix = <QuizDifficulty, int>{
    QuizDifficulty.easy: 3,
    QuizDifficulty.medium: 4,
    QuizDifficulty.hard: 3,
  };

  // ── Helpers ────────────────────────────────────────────────────────────

  static SurahInfo _pickSurah(Random rng) => kSurahs[rng.nextInt(kSurahs.length)];

  /// Picks [count] distinct items satisfying [ok], excluding [exclude].
  ///
  /// Bounded rather than looping until success: a predicate that is nearly
  /// unsatisfiable would otherwise hang the isolate. Returning short lets the
  /// caller abandon the question, which is the correct outcome.
  static List<T> _distinct<T>(
    Random rng,
    List<T> pool,
    int count, {
    required bool Function(T) ok,
    required Set<String> exclude,
    required String Function(T) key,
  }) {
    final picked = <T>[];
    final seen = Set<String>.from(exclude);
    for (var attempt = 0; attempt < 300 && picked.length < count; attempt++) {
      final candidate = pool[rng.nextInt(pool.length)];
      final k = key(candidate);
      if (seen.contains(k) || !ok(candidate)) continue;
      seen.add(k);
      picked.add(candidate);
    }
    return picked;
  }

  /// Shuffles options and reports where the correct one landed.
  static QuizQuestion _assemble({
    required String id,
    required QuizCategory category,
    required QuizDifficulty difficulty,
    required String prompt,
    required String correct,
    required List<String> wrong,
    required String why,
    required String hint,
    required Random rng,
    int? openSurah,
  }) {
    final options = <String>[correct, ...wrong];
    // Fisher-Yates from the day seed, so the correct answer is not always in
    // the same slot but is the same slot for everyone.
    for (var i = options.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final tmp = options[i];
      options[i] = options[j];
      options[j] = tmp;
    }
    return QuizQuestion(
      id: id,
      category: category,
      difficulty: difficulty,
      prompt: prompt,
      options: options,
      correctIndex: options.indexOf(correct),
      why: why,
      hint: hint,
      openSurah: openSurah,
    );
  }

  // ── Hint helpers ───────────────────────────────────────────────────────
  //
  // Every hint is phrased as something a reader can reason from, not as a
  // naked number: "fewer than Ya-Sin" is usable, "under 83" is trivia.

  /// Where a surah sits in the mushaf, in words.
  static String _regionOf(int number) {
    if (number <= 9) return 'the opening surahs';
    if (number <= 29) return 'the first third of the mushaf';
    if (number <= 57) return 'the middle of the mushaf';
    if (number <= 77) return 'the later half';
    if (number <= 99) return 'near the end';
    return 'the short surahs at the very end';
  }

  /// A length description that is true for every surah.
  static String _lengthOf(int ayat) {
    if (ayat <= 10) return 'one of the very short surahs';
    if (ayat <= 40) return 'a short surah';
    if (ayat <= 99) return 'a medium-length surah';
    if (ayat <= 200) return 'a long surah';
    return 'one of the longest surahs in the Quran';
  }

  /// "one of the two larger/smaller numbers on screen".
  ///
  /// Deliberately not "higher than N": with four options the median IS one of
  /// them, so half the time that phrasing names the answer outright. Splitting
  /// the field by rank instead is exact, always halves it, and can never leak.
  static String _halfOfField(int correct, List<int> all) {
    final sorted = List<int>.of(all)..sort();
    final rank = sorted.indexOf(correct);
    final upper = rank >= sorted.length / 2;
    return 'It is one of the two ${upper ? 'larger' : 'smaller'} '
        'numbers on screen';
  }

  // ── The generators ─────────────────────────────────────────────────────

  /// "Which surah is named 'The Cave'?"
  static QuizQuestion? surahByMeaning(Random rng) {
    final surah = _pickSurah(rng);
    final wrong = _distinct<SurahInfo>(
      rng, kSurahs, 3,
      ok: (s) => s.meaning != surah.meaning,
      exclude: <String>{surah.name},
      key: (s) => s.name,
    );
    if (wrong.length < 3) return null;

    return _assemble(
      id: 'surahByMeaning:${surah.number}',
      category: QuizCategory.surah,
      difficulty: QuizDifficulty.easy,
      prompt: 'Which surah is named "${surah.meaning}"?',
      correct: surah.name,
      wrong: wrong.map((s) => s.name).toList(),
      why: 'Surah ${surah.number}, ${surah.name} '
          '(${surah.nameArabic}) — "${surah.meaning}".',
      hint: 'In Arabic it is ${surah.nameArabic}. It was revealed in '
          '${surah.revelationPlace} and sits in ${_regionOf(surah.number)}.',
      rng: rng,
      openSurah: surah.number,
    );
  }

  /// "What does Al-Kahf mean?"
  static QuizQuestion? meaningBySurah(Random rng) {
    final surah = _pickSurah(rng);
    final wrong = _distinct<SurahInfo>(
      rng, kSurahs, 3,
      ok: (s) => s.meaning != surah.meaning,
      exclude: <String>{surah.name},
      key: (s) => s.meaning,
    );
    if (wrong.length < 3) return null;

    return _assemble(
      id: 'meaningBySurah:${surah.number}',
      category: QuizCategory.surah,
      difficulty: QuizDifficulty.easy,
      prompt: 'What does Surah ${surah.name} mean?',
      correct: surah.meaning,
      wrong: wrong.map((s) => s.meaning).toList(),
      why: '${surah.name} (${surah.nameArabic}) means "${surah.meaning}".',
      hint: 'The Arabic name is ${surah.nameArabic}. Read the root of that '
          'word and the meaning usually follows — it is surah '
          '${surah.number}, ${_lengthOf(surah.ayahCount)}.',
      rng: rng,
      openSurah: surah.number,
    );
  }

  /// "Was Al-Muddaththir revealed in Makkah or Madinah?" — a real two-option
  /// question rather than four options with two obvious fillers.
  static QuizQuestion? revelationPlace(Random rng) {
    final surah = _pickSurah(rng);
    return _assemble(
      id: 'revelationPlace:${surah.number}',
      category: QuizCategory.revelation,
      difficulty: QuizDifficulty.easy,
      prompt: 'Where was Surah ${surah.name} revealed?',
      correct: surah.revelationPlace,
      wrong: <String>[surah.isMakki ? 'Madinah' : 'Makkah'],
      why: '${surah.name} is ${surah.isMakki ? 'Makki' : 'Madani'} — '
          'revealed in ${surah.revelationPlace}.',
      hint: 'It is surah ${surah.number} with ${surah.ayahCount} ayat — '
          '${_lengthOf(surah.ayahCount)}. As a rule Makki surahs are shorter '
          'and speak of belief, the resurrection and the earlier prophets; '
          'Madani surahs tend to be longer and deal with law, treaties and '
          'the life of the community.',
      rng: rng,
      openSurah: surah.number,
    );
  }

  /// "Which surah comes immediately after Ya-Sin?"
  static QuizQuestion? surahOrder(Random rng) {
    // 1..113 only, so there is always a following surah.
    final surah = kSurahs[rng.nextInt(kSurahs.length - 1)];
    final answer = kSurahs[surah.number]; // number is 1-based → next surah
    final wrong = _distinct<SurahInfo>(
      rng, kSurahs, 3,
      ok: (s) => (s.number - surah.number).abs() <= 6,
      exclude: <String>{surah.name, answer.name},
      key: (s) => s.name,
    );
    if (wrong.length < 3) return null;

    return _assemble(
      id: 'surahOrder:${surah.number}',
      category: QuizCategory.structure,
      difficulty: QuizDifficulty.medium,
      prompt: 'Which surah comes immediately after ${surah.name}?',
      correct: answer.name,
      wrong: wrong.map((s) => s.name).toList(),
      why: '${surah.name} is surah ${surah.number}, so '
          '${answer.name} (${answer.number}) follows it.',
      hint: '${surah.name} is surah ${surah.number}, so you are looking for '
          'number ${answer.number} — ${_lengthOf(answer.ayahCount)}, revealed '
          'in ${answer.revelationPlace}.',
      rng: rng,
      openSurah: answer.number,
    );
  }

  /// "How many ayat are in Surah Al-Kahf?"
  ///
  /// Distractors are other surahs' REAL ayah counts in a similar range — never
  /// `correct ± random`, which can collide with the right answer.
  static QuizQuestion? ayahCount(Random rng) {
    final surah = _pickSurah(rng);
    final low = (surah.ayahCount * 0.4).round();
    final high = (surah.ayahCount * 2.2).round() + 4;

    final wrong = _distinct<SurahInfo>(
      rng, kSurahs, 3,
      ok: (s) =>
          s.ayahCount != surah.ayahCount &&
          s.ayahCount >= low &&
          s.ayahCount <= high,
      exclude: <String>{'${surah.ayahCount}'},
      key: (s) => '${s.ayahCount}',
    );
    if (wrong.length < 3) return null;

    final counts = <int>[surah.ayahCount, ...wrong.map((s) => s.ayahCount)];
    final side = _halfOfField(surah.ayahCount, counts);

    return _assemble(
      id: 'ayahCount:${surah.number}',
      category: QuizCategory.structure,
      difficulty: QuizDifficulty.medium,
      prompt: 'How many ayat are in Surah ${surah.name}?',
      correct: '${surah.ayahCount}',
      wrong: wrong.map((s) => '${s.ayahCount}').toList(),
      why: '${surah.name} has ${surah.ayahCount} ayat.',
      hint: '${surah.name} is ${_lengthOf(surah.ayahCount)}, revealed in '
          '${surah.revelationPlace}. $side.',
      rng: rng,
      openSurah: surah.number,
    );
  }

  /// "Which of these surahs has the most ayat?"
  static QuizQuestion? longestSurah(Random rng) {
    final four = _distinct<SurahInfo>(
      rng, kSurahs, 4,
      ok: (_) => true,
      exclude: <String>{},
      key: (s) => s.name,
    );
    if (four.length < 4) return null;

    four.sort((a, b) => b.ayahCount.compareTo(a.ayahCount));
    // A tie would make two options equally correct.
    if (four[0].ayahCount == four[1].ayahCount) return null;

    final answer = four.first;
    return _assemble(
      id: 'longestSurah:${four.map((s) => s.number).join('-')}',
      category: QuizCategory.structure,
      difficulty: QuizDifficulty.medium,
      prompt: 'Which of these surahs has the most ayat?',
      correct: answer.name,
      wrong: four.skip(1).map((s) => s.name).toList(),
      why: '${answer.name} has ${answer.ayahCount} ayat — more than '
          '${four[1].name} (${four[1].ayahCount}).',
      // Eliminate the weakest candidate outright and give the scale of the
      // real answer, without naming it.
      hint: 'Rule out ${four.last.name} — it has only ${four.last.ayahCount} '
          'ayat. The winner is ${_lengthOf(answer.ayahCount)}.',
      rng: rng,
      openSurah: answer.number,
    );
  }

  /// "Surah An-Nur is which number in the mushaf?"
  static QuizQuestion? surahNumber(Random rng) {
    final surah = _pickSurah(rng);
    final wrong = _distinct<SurahInfo>(
      rng, kSurahs, 3,
      ok: (s) => (s.number - surah.number).abs() <= 12,
      exclude: <String>{'${surah.number}'},
      key: (s) => '${s.number}',
    );
    if (wrong.length < 3) return null;

    final numbers = <int>[surah.number, ...wrong.map((s) => s.number)];
    final side = _halfOfField(surah.number, numbers);

    return _assemble(
      id: 'surahNumber:${surah.number}',
      category: QuizCategory.structure,
      difficulty: QuizDifficulty.hard,
      prompt: 'What number is Surah ${surah.name} in the mushaf?',
      correct: '${surah.number}',
      wrong: wrong.map((s) => '${s.number}').toList(),
      why: '${surah.name} is surah ${surah.number} of 114.',
      // No ayah count here on purpose: the options are surah NUMBERS, and a
      // surah's ayah count can land inside the ±12 window the distractors are
      // drawn from — printing it would put a wrong option in the hint.
      hint: 'It falls in ${_regionOf(surah.number)}, and it is '
          '${_lengthOf(surah.ayahCount)}. $side.',
      rng: rng,
      openSurah: surah.number,
    );
  }

  /// "Which surah is this ayah from?" — uses the daily pool, whose Arabic and
  /// references were verified against the API.
  static QuizQuestion? ayahSource(Random rng) {
    final entry = kDailyInspirations[rng.nextInt(kDailyInspirations.length)];

    // "Surah Al-Baqarah 2:186" → surah number 2.
    final match = RegExp(r'(\d{1,3}):\d{1,3}').firstMatch(entry.referenceAyah);
    final number = int.tryParse(match?.group(1) ?? '');
    if (number == null || number < 1 || number > kSurahs.length) return null;
    final surah = kSurahs[number - 1];

    final wrong = _distinct<SurahInfo>(
      rng, kSurahs, 3,
      ok: (s) => s.number != surah.number,
      exclude: <String>{surah.name},
      key: (s) => s.name,
    );
    if (wrong.length < 3) return null;

    return _assemble(
      id: 'ayahSource:${entry.referenceAyah}',
      category: QuizCategory.dailyAyah,
      difficulty: QuizDifficulty.hard,
      prompt: 'Which surah is this from?\n\n"${entry.translationAyah}"',
      correct: surah.name,
      wrong: wrong.map((s) => s.name).toList(),
      why: entry.referenceAyah,
      hint: 'The surah it comes from was revealed in ${surah.revelationPlace} '
          'and is ${_lengthOf(surah.ayahCount)} — ${surah.ayahCount} ayat, '
          'sitting in ${_regionOf(surah.number)}.',
      rng: rng,
      openSurah: surah.number,
    );
  }

  /// "Which theme does this app file 2:153 under?"
  ///
  /// Phrased as what THIS APP's index says, not as a claim about the Quran —
  /// a thematic grouping is curation, and the question should not pretend
  /// otherwise.
  static QuizQuestion? verseTheme(Random rng) {
    final themes = kQuranThemes.where((t) => t.verses.isNotEmpty).toList();
    if (themes.length < 4) return null;

    final theme = themes[rng.nextInt(themes.length)];
    final verseKey = theme.verses[rng.nextInt(theme.verses.length)];

    // A verse listed under more than one theme has more than one right answer.
    final owners = themes.where((t) => t.verses.contains(verseKey)).length;
    if (owners != 1) return null;

    final wrong = _distinct<QuranTheme>(
      rng, themes, 3,
      ok: (t) => !t.verses.contains(verseKey),
      exclude: <String>{theme.title},
      key: (t) => t.title,
    );
    if (wrong.length < 3) return null;

    final number = int.tryParse(verseKey.split(':').first);
    final surahName = (number != null && number >= 1 && number <= kSurahs.length)
        ? kSurahs[number - 1].name
        : null;

    // The theme's own search words, minus two kinds of bad clue: anything
    // already in the correct title (that is the answer with extra steps), and
    // anything appearing in a WRONG title — a clue that points at a distractor
    // is worse than no hint at all.
    final lowerTitle = theme.title.toLowerCase();
    final wrongTitles = wrong.map((t) => t.title.toLowerCase()).toList();
    final clues = theme.keywords
        .where((k) =>
            k.length > 3 &&
            !lowerTitle.contains(k) &&
            !wrongTitles.any((w) => w.contains(k)))
        .take(3)
        .toList();

    return _assemble(
      id: 'verseTheme:$verseKey',
      category: QuizCategory.themes,
      difficulty: QuizDifficulty.hard,
      prompt: 'Under which theme does Quran2U list $verseKey?',
      correct: theme.title,
      wrong: wrong.map((t) => t.title).toList(),
      why: '$verseKey — ${theme.blurb}.',
      hint: clues.isEmpty
          ? 'The verse is from Surah ${surahName ?? verseKey.split(':').first}. '
              'Read it, then ask which of the four a person in that state '
              'would actually search for.'
          : 'Someone would reach this verse by searching for '
              '${clues.map((c) => '"$c"').join(', ')}'
              '${surahName == null ? '' : ' — it is in Surah $surahName'}.',
      rng: rng,
      openSurah: number,
    );
  }

  /// Every generator, grouped by the band it serves.
  static const Map<QuizDifficulty, List<QuizGenerator>> generators =
      <QuizDifficulty, List<QuizGenerator>>{
    QuizDifficulty.easy: <QuizGenerator>[
      surahByMeaning,
      meaningBySurah,
      revelationPlace,
    ],
    QuizDifficulty.medium: <QuizGenerator>[
      surahOrder,
      ayahCount,
      longestSurah,
    ],
    QuizDifficulty.hard: <QuizGenerator>[
      surahNumber,
      ayahSource,
      verseTheme,
    ],
  };

  // ── Building a quiz ────────────────────────────────────────────────────

  /// Builds the quiz for [dayIndex]. Deterministic: the same index always
  /// produces the same ten questions, on every device.
  static DailyQuiz build(int dayIndex) {
    final rng = Random(dayIndex);
    final questions = <QuizQuestion>[];
    final usedIds = <String>{};

    for (final band in <QuizDifficulty>[
      QuizDifficulty.easy,
      QuizDifficulty.medium,
      QuizDifficulty.hard,
    ]) {
      final want = mix[band] ?? 0;
      final pool = generators[band] ?? const <QuizGenerator>[];
      if (pool.isEmpty) continue;

      var made = 0;
      // Bounded: a generator that keeps returning null must not spin forever.
      for (var attempt = 0; attempt < want * 40 && made < want; attempt++) {
        final q = pool[rng.nextInt(pool.length)](rng);
        if (q == null || usedIds.contains(q.id)) continue;
        usedIds.add(q.id);
        questions.add(q);
        made++;
      }
    }

    // Top up from any band if a generator was unusually unlucky, so the quiz
    // is always exactly ten questions long.
    final all = generators.values.expand((g) => g).toList();
    for (var attempt = 0;
        attempt < 400 && questions.length < questionsPerQuiz;
        attempt++) {
      final q = all[rng.nextInt(all.length)](rng);
      if (q == null || usedIds.contains(q.id)) continue;
      usedIds.add(q.id);
      questions.add(q);
    }

    return DailyQuiz(dayIndex: dayIndex, questions: questions);
  }

  /// Stars for a score. Bands rather than a percentage, so a hard day still
  /// feels survivable.
  static int starsFor(int correct, int total) {
    if (total <= 0) return 0;
    final pct = correct / total;
    if (pct >= 0.9) return 3;
    if (pct >= 0.7) return 2;
    if (pct >= 0.5) return 1;
    return 0;
  }
}
