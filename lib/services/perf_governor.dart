// lib/services/perf_governor.dart
//
// Adaptive effect quality.
//
// THE PROBLEM WITH THE USUAL APPROACH
// -----------------------------------
// The normal way to decide "is this phone fast enough for blur" is to sniff a
// model name, a RAM figure, or an Android version, and keep a list. All three
// are bad proxies. A 2019 flagship outruns a 2024 budget phone; a device with
// 8 GB of RAM can still have a GPU that chokes on a full-screen gaussian; and
// the same handset throttles hard once it is warm, which no static check can
// see. A list also rots — it is wrong for every phone released after the build
// shipped, which is all of them.
//
// WHAT THIS DOES INSTEAD
// ----------------------
// It watches the frames the app is actually producing, on this device, right
// now, and turns effects down when the evidence says they are not affordable.
// The signal is RASTER time, not build time: a card that is expensive to blur
// costs raster milliseconds, while a screen that is slow to assemble costs
// build milliseconds, and turning off glass would not help the second one at
// all.
//
// It only ever degrades. Flipping effects back on mid-session would make the
// interface visibly change under the user's hands, and a phone that struggled
// once while cold is not going to do better once it is warm.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'package:quran_recitation/ui_v2/glass.dart';

class PerfGovernor {
  PerfGovernor._();

  /// Frames slower than this are counted as dropped.
  ///
  /// 20 ms rather than 16.7: a 60 Hz frame that lands a whisker late is normal
  /// and not worth reacting to. What matters is frames that are late enough
  /// for a person to see.
  static const double _budgetMs = 20;

  /// How many frames to watch before deciding anything. Roughly four seconds
  /// of scrolling — long enough to cover a real interaction rather than the
  /// first-run jank every Flutter app has while shaders warm up.
  static const int _sampleSize = 240;

  /// Frames to throw away first. Startup is never representative.
  static const int _warmup = 90;

  /// Degrade when more than this share of the sample missed the budget.
  static const double _badFraction = 0.22;

  static int _seen = 0;
  static int _late = 0;
  static bool _installed = false;
  static bool _decided = false;

  /// True once effects have been turned down. Surfaced in Settings so the
  /// change is explainable rather than mysterious.
  static bool get degraded => _decided && GlassConfig.reduced;

  /// Call once, after the first frame.
  static void start() {
    if (_installed || kDebugMode) {
      // Debug builds are slower than release for reasons that have nothing to
      // do with the GPU. Measuring them would degrade every developer's phone
      // and teach us nothing about anyone's.
      _installed = true;
      return;
    }
    _installed = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  static void _onTimings(List<FrameTiming> timings) {
    if (_decided) return;

    for (final t in timings) {
      _seen++;
      if (_seen <= _warmup) continue;

      // Raster duration is the one this can actually do something about.
      final rasterMs = t.rasterDuration.inMicroseconds / 1000.0;
      if (rasterMs > _budgetMs) _late++;

      if (_seen - _warmup >= _sampleSize) {
        _decide();
        return;
      }
    }
  }

  static void _decide() {
    _decided = true;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);

    final measured = _seen - _warmup;
    final ratio = measured == 0 ? 0.0 : _late / measured;

    if (ratio > _badFraction) {
      GlassConfig.reduceEffects();
      // Existing shaders were built for the settings we just abandoned.
      GlassRepaint.invalidate();
      debugPrint('[Perf] ${(ratio * 100).toStringAsFixed(0)}% of frames over '
          '${_budgetMs.toInt()}ms — effects reduced.');
    } else {
      debugPrint('[Perf] ${(ratio * 100).toStringAsFixed(0)}% of frames over '
          '${_budgetMs.toInt()}ms — full effects kept.');
    }
  }

  /// Screen geometry changed, so every cached size-dependent shader is stale.
  static void onMetricsChanged() => GlassRepaint.invalidate();

  /// Current device pixel count, for logging.
  static double pixelCount() {
    final view = ui.PlatformDispatcher.instance.implicitView;
    if (view == null) return 0;
    return view.physicalSize.width * view.physicalSize.height;
  }
}
