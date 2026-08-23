// lib/screens/share_ayah_screen.dart
//
// Renders an ayah as a shareable image.
//
// The card is laid out at a fixed logical size (360 wide) inside a
// RepaintBoundary and captured at 3x, so the exported PNG is 1080px on its
// short edge regardless of the phone's screen density or font-scale setting.
// The on-screen preview is a scaled copy of the very same widget — what you
// see is exactly what gets shared.

import 'dart:io';
// Uint8List comes in via package:flutter/services.dart, which re-exports
// dart:typed_data — importing it directly is flagged as unnecessary.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:quran_recitation/models/share_card_style.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/ui_v2/app_typography.dart';
import 'package:quran_recitation/ui_v2/glass.dart';
import 'package:quran_recitation/ui_v2/widgets/q_kit.dart';

class ShareAyahScreen extends StatefulWidget {
  final String arabic;
  final String translation;

  /// "Al-Baqarah" — shown with the numeric reference.
  final String surahName;
  final int surahNumber;
  final int ayahNumber;

  /// Optional override for the reference line (used by Daily Inspiration,
  /// where the source is a hadith rather than a numbered ayah).
  final String? referenceOverride;

  const ShareAyahScreen({
    super.key,
    required this.arabic,
    required this.translation,
    this.surahName = '',
    this.surahNumber = 0,
    this.ayahNumber = 0,
    this.referenceOverride,
  });

  @override
  State<ShareAyahScreen> createState() => _ShareAyahScreenState();
}

class _ShareAyahScreenState extends State<ShareAyahScreen> {
  final GlobalKey _cardKey = GlobalKey();

  int _styleIndex = 0;
  ShareCardFormat _format = ShareCardFormat.square;
  bool _showTranslation = true;
  bool _busy = false;

  ShareCardStyle get _style => ShareCardStyle.presets[_styleIndex];

  String get _reference {
    if (widget.referenceOverride != null &&
        widget.referenceOverride!.isNotEmpty) {
      return widget.referenceOverride!;
    }
    if (widget.surahName.isEmpty) {
      return 'Surah ${widget.surahNumber} : ${widget.ayahNumber}';
    }
    return '${widget.surahName} · ${widget.surahNumber}:${widget.ayahNumber}';
  }

  /// Rasterises the card at 3× into PNG bytes. Returns null only after every
  /// retry has failed.
  ///
  /// BUG HISTORY — why there is no `debugNeedsPaint` here any more.
  ///
  /// This method used to guard the capture with `if (boundary.debugNeedsPaint)`.
  /// That getter is debug-only: its implementation assigns the result inside an
  /// `assert`, and asserts are stripped from release builds, so in a release
  /// APK reading it throws a LateInitializationError. The throw was swallowed
  /// by the catch below, `_capture` returned null, and every single share
  /// attempt failed with "Could not render the card" — while working perfectly
  /// in `flutter run`. Never branch on a `debug*` member in shipping code.
  ///
  /// The replacement is honest about what it needs: wait for the frame to
  /// finish so the boundary is guaranteed to have a composited layer, then
  /// retry a couple of times, because on a cold open the first attempt can
  /// still land before the card has painted.
  Future<Uint8List?> _capture() async {
    // Completes after the next frame is rasterised, and schedules one if none
    // is pending — so this resolves even when the UI is idle.
    await WidgetsBinding.instance.endOfFrame;

    for (var attempt = 0; attempt < 3; attempt++) {
      if (!mounted) return null;
      try {
        final object = _cardKey.currentContext?.findRenderObject();
        if (object is RenderRepaintBoundary) {
          final image = await object.toImage(pixelRatio: 3.0);
          try {
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            final bytes = data?.buffer.asUint8List();
            if (bytes != null && bytes.isNotEmpty) return bytes;
          } finally {
            // The original leaked this whenever toByteData threw.
            image.dispose();
          }
        }
      } catch (e) {
        debugPrint('[ShareAyah] capture attempt ${attempt + 1} failed: $e');
      }
      await Future<void>.delayed(const Duration(milliseconds: 90));
    }

    debugPrint('[ShareAyah] capture gave up after 3 attempts');
    return null;
  }

  Future<File?> _writeTempFile(Uint8List bytes) async {
    try {
      final dir = await getTemporaryDirectory();
      final name = widget.surahNumber > 0
          ? 'quran2u_${widget.surahNumber}_${widget.ayahNumber}.png'
          : 'quran2u_ayah.png';
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (e) {
      debugPrint('[ShareAyah] write failed: $e');
      return null;
    }
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColorsV2.surfaceHigh,
        content: Text(
          message,
          style: AppTypeV2.caption(
            size: 12.5,
            color: error ? AppColorsV2.danger : AppColorsV2.onSurface,
          ),
        ),
      ),
    );
  }

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _capture();
      if (bytes == null) {
        _toast('Could not render the card.', error: true);
        return;
      }
      final file = await _writeTempFile(bytes);
      if (file == null) {
        _toast('Could not save the image.', error: true);
        return;
      }

      final caption = _showTranslation && widget.translation.trim().isNotEmpty
          ? '${widget.translation.trim()}\n— $_reference'
          : _reference;

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: '$caption\n\nShared from Quran2U',
      );
    } catch (e) {
      debugPrint('[ShareAyah] share failed: $e');
      _toast('Sharing is unavailable on this device.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyText() async {
    final text = widget.translation.trim().isEmpty
        ? '${widget.arabic}\n— $_reference'
        : '${widget.arabic}\n\n${widget.translation.trim()}\n— $_reference';
    await Clipboard.setData(ClipboardData(text: text));
    _toast('Ayah copied');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    // Leave room for the controls; never upscale past 1:1.
    final previewScale =
        ((screenWidth - 48) / _format.width).clamp(0.35, 1.0).toDouble();

    return Scaffold(
      backgroundColor: AppColorsV2.bg,
      appBar: AppBar(
        title: Text('Share Ayah', style: AppTypeV2.title(size: 16)),
        actions: [
          IconButton(
            tooltip: 'Copy text',
            onPressed: _copyText,
            icon: const Icon(Icons.copy_rounded, size: 20),
            color: AppColorsV2.onSurfaceVariant,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Preview ───────────────────────────────────────────────────
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Transform.scale(
                  scale: previewScale,
                  child: RepaintBoundary(
                    key: _cardKey,
                    child: _AyahCard(
                      arabic: widget.arabic,
                      translation: _showTranslation ? widget.translation : '',
                      reference: _reference,
                      style: _style,
                      format: _format,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Controls ──────────────────────────────────────────────────
          GlassSurface(
            tier: GlassTier.sheet,
            borderRadius: kGlassSheetRadius,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            tint: AppColorsV2.surface,
            edgeIntensity: 0.28,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Style swatches
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: ShareCardStyle.presets.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final preset = ShareCardStyle.presets[i];
                        final selected = i == _styleIndex;
                        return GlassPill(
                          selected: selected,
                          accentColor: preset.accent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          onTap: () => setState(() => _styleIndex = i),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                      colors: preset.background),
                                  border: Border.all(color: preset.accent),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                preset.name,
                                style: AppTypeV2.caption(
                                  size: 11.5,
                                  color: selected
                                      ? AppColorsV2.onSurface
                                      : AppColorsV2.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      // Format toggle
                      for (final f in ShareCardFormat.values) ...[
                        QChip(
                          label: f.label,
                          selected: _format == f,
                          onTap: () => setState(() => _format = f),
                          leading: Icon(
                            f.icon,
                            size: 13,
                            color: _format == f
                                ? AppColorsV2.primary
                                : AppColorsV2.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Spacer(),
                      if (widget.translation.trim().isNotEmpty)
                        QChip(
                          label: 'Translation',
                          selected: _showTranslation,
                          onTap: () => setState(
                              () => _showTranslation = !_showTranslation),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _busy ? null : _share,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorsV2.primary,
                        foregroundColor: AppColorsV2.onPrimary,
                        disabledBackgroundColor:
                            AppColorsV2.primary.withValues(alpha: 0.4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: _busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColorsV2.onPrimary,
                              ),
                            )
                          : const Icon(Icons.ios_share_rounded, size: 18),
                      label: Text(
                        _busy ? 'Preparing…' : 'Share image',
                        style: AppTypeV2.title(
                            size: 14, color: AppColorsV2.onPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// The card itself — this exact widget is what gets rasterised.
// ─────────────────────────────────────────────────────────────────────────────

class _AyahCard extends StatelessWidget {
  final String arabic;
  final String translation;
  final String reference;
  final ShareCardStyle style;
  final ShareCardFormat format;

  const _AyahCard({
    required this.arabic,
    required this.translation,
    required this.reference,
    required this.style,
    required this.format,
  });

  /// Long ayahs need smaller type. Chosen by grapheme count rather than
  /// FittedBox alone so line-height stays proportional.
  double get _arabicSize {
    final n = arabic.characters.length;
    final base = format == ShareCardFormat.story ? 34.0 : 30.0;
    if (n > 320) return base * 0.52;
    if (n > 200) return base * 0.62;
    if (n > 120) return base * 0.74;
    if (n > 70) return base * 0.86;
    return base;
  }

  double get _translationSize {
    final n = translation.characters.length;
    final base = format == ShareCardFormat.story ? 14.0 : 12.5;
    if (n > 300) return base * 0.78;
    if (n > 180) return base * 0.88;
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final hasTranslation = translation.trim().isNotEmpty;

    return Container(
      width: format.width,
      height: format.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: style.background,
        ),
      ),
      child: Stack(
        children: [
          // Faint star lattice, top corner
          Positioned(
            top: -20,
            right: -20,
            child: Opacity(
              opacity: style.isLight ? 0.30 : 0.5,
              child: CustomPaint(
                size: const Size(150, 150),
                painter: EightPointStarPainter(
                  color: style.accent.withValues(alpha: 0.12),
                  strokeWidth: 1,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -30,
            child: Opacity(
              opacity: style.isLight ? 0.25 : 0.4,
              child: CustomPaint(
                size: const Size(180, 180),
                painter: EightPointStarPainter(
                  color: style.accent.withValues(alpha: 0.10),
                  strokeWidth: 1,
                ),
              ),
            ),
          ),

          // Inner hairline frame
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: style.frame),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 30,
              vertical: format == ShareCardFormat.story ? 46 : 32,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Arabic
                Flexible(
                  flex: 6,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: format.width - 76),
                      child: Text(
                        arabic,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: AppTypeV2.arabic(
                          size: _arabicSize,
                          color: style.arabicColor,
                          height: 1.95,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: hasTranslation ? 18 : 10),

                // Ornament
                SizedBox(
                  width: 90,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: style.accent.withValues(alpha: 0.35),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        child: Transform.rotate(
                          angle: 0.785398, // 45°
                          child: Container(
                            width: 4,
                            height: 4,
                            color: style.accent,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: style.accent.withValues(alpha: 0.35),
                        ),
                      ),
                    ],
                  ),
                ),

                if (hasTranslation) ...[
                  const SizedBox(height: 16),
                  Flexible(
                    flex: 4,
                    child: Text(
                      translation.trim(),
                      textAlign: TextAlign.center,
                      style: AppTypeV2.body(
                        size: _translationSize,
                        color: style.translationColor,
                        height: 1.65,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Reference
                Text(
                  reference,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypeV2.caption(
                    size: 11,
                    color: style.accent,
                    weight: FontWeight.w800,
                  ),
                ),

                const Spacer(),

                // Wordmark
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(11, 11),
                      painter: EightPointStarPainter(
                        color: style.accent.withValues(alpha: 0.8),
                        strokeWidth: 0.9,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'QURAN2U',
                      style: AppTypeV2.caption(
                        size: 8.5,
                        color: style.accent.withValues(alpha: 0.75),
                        weight: FontWeight.w800,
                      ).copyWith(letterSpacing: 2.4),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
