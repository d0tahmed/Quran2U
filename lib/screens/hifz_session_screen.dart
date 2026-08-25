// lib/screens/hifz_session_screen.dart
//
// The drill.
//
// HOW MEMORISATION ACTUALLY WORKS, AND WHAT THE SCREEN DOES ABOUT IT
// ------------------------------------------------------------------
// Reading an ayah over and over feels like learning and mostly is not. What
// moves an ayah into memory is RETRIEVAL — trying to produce it with the text
// gone, failing, and only then looking. So the screen has two states and the
// whole design is about the moment between them:
//
//   Study   the ayah is on screen, the recitation loops over it
//   Recall  the text is gone and you have to produce it yourself
//
// In Recall, tapping reveals ONE MORE WORD rather than the whole ayah. That
// matters: the usual "show answer" button removes the struggle at the exact
// moment the struggle is the thing doing the work. A single word is enough to
// unstick someone without handing them the rest.
//
// The verdict afterwards is "I knew it" or "Not yet", and it is asked only in
// Recall — a judgement made while the text is visible would be about
// recognition, which is not what is being trained.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quran_recitation/models/models.dart';
import 'package:quran_recitation/providers/providers.dart';
import 'package:quran_recitation/services/arabic_text_utils.dart';
import 'package:quran_recitation/services/hifz_audio.dart';
import 'package:quran_recitation/services/hifz_storage.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/ui_v2/app_typography.dart';
import 'package:quran_recitation/ui_v2/glass.dart';

/// One ayah to drill.
@immutable
class HifzTarget {
  final int surah;
  final int ayah;
  const HifzTarget(this.surah, this.ayah);
}

class HifzSessionScreen extends ConsumerStatefulWidget {
  final List<HifzTarget> targets;
  final String title;

  const HifzSessionScreen({
    super.key,
    required this.targets,
    required this.title,
  });

  @override
  ConsumerState<HifzSessionScreen> createState() => _HifzSessionScreenState();
}

class _HifzSessionScreenState extends ConsumerState<HifzSessionScreen> {
  final HifzAudio _audio = HifzAudio();

  int _index = 0;

  /// False while studying, true once the text has been hidden for recall.
  bool _recall = false;

  /// How many words are showing in recall mode.
  int _revealed = 0;

  int _repeat = 3;

  /// Verdicts given this session, for the summary line.
  int _knew = 0;
  int _missed = 0;

  bool _saving = false;

  HifzTarget get _target => widget.targets[_index];

  @override
  void initState() {
    super.initState();
    _loadRepeat();

    // One speaker, two players. The surah player has to be silenced before a
    // drill starts or the two overlap — and the user would have no obvious way
    // to work out which control stops which sound.
    WidgetsBinding.instance.addPostFrameCallback((_) => _silenceMainPlayer());
  }

  Future<void> _silenceMainPlayer() async {
    try {
      await ref.read(audioPlayerServiceProvider).pause();
    } catch (_) {
      // Nothing was playing, which is the common case.
    }
  }

  Future<void> _loadRepeat() async {
    final n = await HifzStorage.repeatCount();
    if (mounted) setState(() => _repeat = n);
  }

  @override
  void dispose() {
    // Fire and forget: dispose() cannot await, and the player must not outlive
    // the screen or its next completion callback would touch a dead State.
    _audio.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────

  Future<void> _playCurrent() async {
    final imam = ref.read(selectedImamProvider);
    if (imam == null) return;
    HapticFeedback.selectionClick();
    await _audio.play(
      surah: _target.surah,
      ayah: _target.ayah,
      imamId: imam.id,
      times: _repeat,
    );
  }

  void _enterRecall() {
    HapticFeedback.selectionClick();
    setState(() {
      _recall = true;
      _revealed = 0;
    });
  }

  void _revealOneMore(int total) {
    if (_revealed >= total) return;
    HapticFeedback.selectionClick();
    setState(() => _revealed++);
  }

  Future<void> _verdict(bool remembered) async {
    if (_saving) return;
    setState(() => _saving = true);

    HapticFeedback.mediumImpact();
    await _audio.stop();
    await HifzStorage.record(
      surah: _target.surah,
      ayah: _target.ayah,
      remembered: remembered,
    );
    await HifzStorage.setLastPosition(_target.surah, _target.ayah);

    if (!mounted) return;

    final last = _index >= widget.targets.length - 1;
    setState(() {
      if (remembered) {
        _knew++;
      } else {
        _missed++;
      }
      _saving = false;
      if (!last) {
        _index++;
        _recall = false;
        _revealed = 0;
      }
    });

    if (last && mounted) _finish();
  }

  void _finish() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _SessionSummary(
        knew: _knew,
        missed: _missed,
        onDone: () {
          Navigator.of(dialogContext).pop();
          Navigator.of(context).pop(true);
        },
      ),
    );
  }

  Future<void> _setRepeat(int value) async {
    setState(() => _repeat = value);
    await HifzStorage.setRepeatCount(value);
  }

  void _skip() {
    if (_index >= widget.targets.length - 1) {
      _finish();
      return;
    }
    _audio.stop();
    setState(() {
      _index++;
      _recall = false;
      _revealed = 0;
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.targets.isEmpty) {
      return Scaffold(
        backgroundColor: AppColorsV2.bg,
        appBar: AppBar(title: Text(widget.title, style: AppTypeV2.title(size: 16))),
        body: Center(
          child: Text('Nothing to review.', style: AppTypeV2.body(size: 13.5)),
        ),
      );
    }

    final translationId = ref.watch(selectedTranslationProvider).id;
    final ayahsAsync =
        ref.watch(surahAyahsProvider((_target.surah, translationId)));

    return Scaffold(
      backgroundColor: AppColorsV2.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.title, style: AppTypeV2.title(size: 16)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Text(
                '${_index + 1} / ${widget.targets.length}',
                style: AppTypeV2.caption(
                    size: 12, color: AppColorsV2.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _Progress(value: (_index + 1) / widget.targets.length),
            Expanded(
              child: ayahsAsync.when(
                loading: () => const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColorsV2.primary),
                  ),
                ),
                error: (e, _) => _Failed(
                  onRetry: () => ref.invalidate(
                      surahAyahsProvider((_target.surah, translationId))),
                ),
                data: (ayahs) {
                  final ayah = _findAyah(ayahs, _target.ayah);
                  if (ayah == null) {
                    return _Failed(
                      message: 'Ayah ${_target.surah}:${_target.ayah} is not in '
                          'the cached text for this surah.',
                      onRetry: () => ref.invalidate(
                          surahAyahsProvider((_target.surah, translationId))),
                    );
                  }
                  return _AyahPane(
                    ayah: ayah,
                    surah: _target.surah,
                    recall: _recall,
                    revealed: _revealed,
                    onRevealWord: _revealOneMore,
                  );
                },
              ),
            ),
            _Controls(
              audio: _audio,
              recall: _recall,
              repeat: _repeat,
              saving: _saving,
              onPlay: _playCurrent,
              onHide: _enterRecall,
              onRepeatChanged: _setRepeat,
              onKnew: () => _verdict(true),
              onMissed: () => _verdict(false),
              onSkip: _skip,
            ),
          ],
        ),
      ),
    );
  }

  /// Linear rather than indexed: the API returns ayat in order but a cached
  /// payload from an older build could be short, and indexing into it would
  /// throw where a search simply reports the gap.
  static Ayah? _findAyah(List<Ayah> ayahs, int numberInSurah) {
    for (final a in ayahs) {
      if (a.numberInSurah == numberInSurah) return a;
    }
    return null;
  }
}

// ── The ayah ────────────────────────────────────────────────────────────────

class _AyahPane extends StatelessWidget {
  final Ayah ayah;
  final int surah;
  final bool recall;
  final int revealed;
  final ValueChanged<int> onRevealWord;

  const _AyahPane({
    required this.ayah,
    required this.surah,
    required this.recall,
    required this.revealed,
    required this.onRevealWord,
  });

  @override
  Widget build(BuildContext context) {
    final words = ArabicText.splitWords(ayah.text);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        Center(
          child: GlassPill(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
            child: Text(
              '$surah : ${ayah.numberInSurah}',
              style: AppTypeV2.caption(size: 11, color: AppColorsV2.tertiary),
            ),
          ),
        ),
        const SizedBox(height: 22),

        // The Arabic. Always scrollable — Al-Baqarah 282 is a page on its own,
        // and a fixed-height box would either clip it or squeeze the type down
        // to something nobody can recite from.
        FrostedCard(
          radius: 24,
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
          edgeColor: recall ? AppColorsV2.tertiary : null,
          edgeIntensity: recall ? 0.30 : 0.20,
          child: recall
              ? _RecallText(words: words, revealed: revealed, onTap: onRevealWord)
              : Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    ayah.text,
                    textAlign: TextAlign.center,
                    style: AppTypeV2.arabic(size: 27, height: 2.0),
                  ),
                ),
        ),

        if (!recall && ayah.translation.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            ayah.translation,
            textAlign: TextAlign.center,
            style: AppTypeV2.body(size: 13, height: 1.7),
          ),
        ],

        if (recall) ...[
          const SizedBox(height: 16),
          Center(
            child: Text(
              revealed == 0
                  ? 'Recite it from memory. Tap a blank for a word.'
                  : revealed >= words.length
                      ? 'Whole ayah revealed.'
                      : '$revealed of ${words.length} words revealed',
              textAlign: TextAlign.center,
              style: AppTypeV2.caption(
                  size: 11.5, color: AppColorsV2.onSurfaceVariant),
            ),
          ),
        ],
      ],
    );
  }
}

/// The ayah with the first [revealed] words showing and the rest as blanks.
///
/// Words are revealed from the RIGHT, because that is where an Arabic ayah
/// starts. Revealing from the left would hand out the ending first, which is
/// not a hint — it is the answer to a different question.
class _RecallText extends StatelessWidget {
  /// Shared with [_Blank] so a hidden word and a revealed one occupy exactly
  /// the same line box. Changing either of these without the other brings the
  /// row-height jitter straight back.
  static const double fontSize = 25;
  static const double lineGap = 1.6;

  final List<String> words;
  final int revealed;
  final ValueChanged<int> onTap;

  const _RecallText({
    required this.words,
    required this.revealed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(words.length),
        child: Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 9,
          runSpacing: 6,
          children: [
            for (var i = 0; i < words.length; i++)
              i < revealed
                  ? SizedBox(
                      height: fontSize * lineGap,
                      child: Center(
                        child: Text(
                          words[i],
                          style: AppTypeV2.arabic(size: fontSize, height: 1.0),
                        ),
                      ),
                    )
                  : _Blank(word: words[i]),
          ],
        ),
      ),
    );
  }
}

/// A hidden word.
///
/// Two measurements matter here and both are deliberate.
///
/// WIDTH is taken from the real word. A uniform placeholder would flatten the
/// ayah into a row of identical boxes and throw away its rhythm — and that
/// rhythm, the shape of long and short words, is itself one of the cues
/// someone reciting from memory leans on.
///
/// HEIGHT matches the line box of a revealed word exactly. This is the part
/// that is easy to get wrong: a Wrap lays its children out in rows as tall as
/// the tallest child, so a 26-pixel blank sitting beside a 40-pixel word makes
/// every row change height as words are revealed, and the whole ayah jumps
/// around under the reader's finger. Same height, no reflow.
class _Blank extends StatelessWidget {
  final String word;
  const _Blank({required this.word});

  /// Must equal the revealed word's font size × its line height.
  static const double _lineHeight = _RecallText.fontSize * _RecallText.lineGap;

  @override
  Widget build(BuildContext context) {
    final width = (word.characters.length * 11.0).clamp(26.0, 150.0);

    return SizedBox(
      height: _lineHeight,
      width: width,
      child: Center(
        child: Container(
          height: 24,
          decoration: BoxDecoration(
            color: AppColorsV2.surfaceHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: AppColorsV2.hairline),
          ),
        ),
      ),
    );
  }
}

// ── Controls ────────────────────────────────────────────────────────────────

class _Controls extends StatelessWidget {
  final HifzAudio audio;
  final bool recall;
  final int repeat;
  final bool saving;
  final VoidCallback onPlay;
  final VoidCallback onHide;
  final ValueChanged<int> onRepeatChanged;
  final VoidCallback onKnew;
  final VoidCallback onMissed;
  final VoidCallback onSkip;

  const _Controls({
    required this.audio,
    required this.recall,
    required this.repeat,
    required this.saving,
    required this.onPlay,
    required this.onHide,
    required this.onRepeatChanged,
    required this.onKnew,
    required this.onMissed,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColorsV2.hairline)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Play + repeat ────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<HifzPlayState>(
                  valueListenable: audio.state,
                  builder: (context, state, _) => _PlayButton(
                    state: state,
                    audio: audio,
                    repeat: repeat,
                    onTap: onPlay,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _RepeatStepper(value: repeat, onChanged: onRepeatChanged),
            ],
          ),
          const SizedBox(height: 12),

          // ── Study / recall ───────────────────────────────────────────
          if (!recall)
            Row(
              children: [
                Expanded(
                  child: _Action(
                    icon: Icons.visibility_off_rounded,
                    label: 'Hide it — test me',
                    filled: true,
                    onTap: onHide,
                  ),
                ),
                const SizedBox(width: 10),
                _Action(
                  icon: Icons.skip_next_rounded,
                  label: 'Skip',
                  onTap: onSkip,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _Action(
                    icon: Icons.refresh_rounded,
                    label: 'Not yet',
                    tone: AppColorsV2.tertiary,
                    onTap: saving ? null : onMissed,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Action(
                    icon: Icons.check_rounded,
                    label: 'I knew it',
                    filled: true,
                    onTap: saving ? null : onKnew,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final HifzPlayState state;
  final HifzAudio audio;
  final int repeat;
  final VoidCallback onTap;

  const _PlayButton({
    required this.state,
    required this.audio,
    required this.repeat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final playing = state == HifzPlayState.playing;
    final loading = state == HifzPlayState.loading;
    final failed = state == HifzPlayState.error;

    return GlassPressable(
      onTap: loading ? null : (playing ? audio.stop : onTap),
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: failed
              ? AppColorsV2.danger.withValues(alpha: 0.12)
              : AppColorsV2.surfaceHigh,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: playing
                ? AppColorsV2.primary.withValues(alpha: 0.5)
                : AppColorsV2.hairline,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColorsV2.primary),
              )
            else
              Icon(
                failed
                    ? Icons.wifi_off_rounded
                    : playing
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,
                size: 20,
                color: failed ? AppColorsV2.danger : AppColorsV2.primary,
              ),
            const SizedBox(width: 9),
            Flexible(
              child: ValueListenableBuilder<int>(
                valueListenable: audio.repetition,
                builder: (context, done, _) => Text(
                  failed
                      ? 'Audio unavailable'
                      : playing
                          ? 'Playing  ${done + 1} of $repeat'
                          : 'Listen  ×$repeat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypeV2.title(
                    size: 13.5,
                    color: failed ? AppColorsV2.danger : AppColorsV2.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepeatStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _RepeatStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColorsV2.surfaceHigh,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColorsV2.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Step(
            icon: Icons.remove_rounded,
            enabled: value > 1,
            onTap: () => onChanged(value - 1),
          ),
          SizedBox(
            width: 26,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: AppTypeV2.title(size: 14),
            ),
          ),
          _Step(
            icon: Icons.add_rounded,
            enabled: value < 10,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _Step({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: SizedBox(
        width: 34,
        height: 50,
        child: Icon(
          icon,
          size: 17,
          color: enabled
              ? AppColorsV2.onSurface
              : AppColorsV2.onSurfaceVariant.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final Color? tone;
  final VoidCallback? onTap;

  const _Action({
    required this.icon,
    required this.label,
    this.filled = false,
    this.tone,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = tone ?? AppColorsV2.primary;
    final fg = filled ? AppColorsV2.onPrimary : accent;
    final disabled = onTap == null;

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: GlassPressable(
        onTap: onTap,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? accent : accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: filled ? Colors.transparent : accent.withValues(alpha: 0.32),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: fg),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypeV2.title(size: 13, color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small parts ─────────────────────────────────────────────────────────────

class _Progress extends StatelessWidget {
  final double value;
  const _Progress({required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: value),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => LinearProgressIndicator(
            value: v,
            minHeight: 4,
            backgroundColor: AppColorsV2.surfaceHighest,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColorsV2.primary),
          ),
        ),
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;

  const _Failed({required this.onRetry, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 40, color: AppColorsV2.outlineVariant),
            const SizedBox(height: 14),
            Text(
              message ??
                  'Could not load this surah. Open it once in the reader and '
                      'it will be available offline from then on.',
              textAlign: TextAlign.center,
              style: AppTypeV2.body(size: 13, height: 1.6),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColorsV2.primary,
                side: const BorderSide(color: AppColorsV2.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Try again', style: AppTypeV2.title(size: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionSummary extends StatelessWidget {
  final int knew;
  final int missed;
  final VoidCallback onDone;

  const _SessionSummary({
    required this.knew,
    required this.missed,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final total = knew + missed;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 30),
      child: FrostedCard(
        radius: 26,
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
        elevated: true,
        accent: AppColorsV2.primary,
        edgeColor: AppColorsV2.primary,
        edgeIntensity: 0.34,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.done_all_rounded,
                size: 34, color: AppColorsV2.primary),
            const SizedBox(height: 14),
            Text('Session complete', style: AppTypeV2.title(size: 17)),
            const SizedBox(height: 8),
            Text(
              total == 0
                  ? 'Nothing recorded.'
                  : 'You held $knew of $total. '
                      '${missed == 0 ? 'Every one of them.' : 'The other '
                          '${missed == 1 ? 'one comes' : '$missed come'} back '
                          'sooner.'}',
              textAlign: TextAlign.center,
              style: AppTypeV2.body(size: 13, height: 1.6),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsV2.primary,
                  foregroundColor: AppColorsV2.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Done',
                    style: AppTypeV2.title(
                        size: 14, color: AppColorsV2.onPrimary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
