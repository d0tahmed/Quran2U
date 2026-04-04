import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adhan/adhan.dart';
import 'package:quran_recitation/providers/providers.dart';

const _kGreen = Color(0xFF10B981);
const _kBg = Color(0xFF05080F);

class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({super.key});

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen> {
  StreamSubscription<CompassEvent>? _compassSubscription;
  double _turns = 0.0;
  double _lastHeading = 0.0;
  bool _isFacingQibla = false;

  @override
  void initState() {
    super.initState();
    _initCompass();
  }

  void _initCompass() {
    _compassSubscription = FlutterCompass.events?.listen((event) {
      final heading = event.heading;
      if (heading == null) return;

      double delta = heading - _lastHeading;
      if (delta > 180) delta -= 360;
      if (delta < -180) delta += 360;
      
      _lastHeading = heading;
      
      setState(() {
        _turns -= delta / 360.0; 
      });
    });
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(locationProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          Positioned(
            top: 150, left: -50, right: -50,
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_kGreen.withValues(alpha: 0.1), Colors.transparent],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: locationAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: _kGreen)),
              error: (e, _) => _buildErrorState(),
              data: (coords) {
                final qiblaDir = Qibla(coords).direction;
                
                double diff = (_lastHeading - qiblaDir).abs() % 360;
                if (diff > 180) diff = 360 - diff;
                final currentlyFacing = diff < 2.0;

                if (currentlyFacing && !_isFacingQibla) {
                  HapticFeedback.heavyImpact(); 
                }
                _isFacingQibla = currentlyFacing;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                    
                    Text('Qibla Compass',
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${coords.latitude.toStringAsFixed(4)}, ${coords.longitude.toStringAsFixed(4)}',
                        style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13, letterSpacing: 1)),
                    
                    const Spacer(),

                    SizedBox(
                      height: 320,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedRotation(
                            turns: _turns,
                            duration: const Duration(milliseconds: 300),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 280,
                                  height: 280,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                                  ),
                                ),
                                Transform.rotate(
                                  angle: qiblaDir * (math.pi / 180),
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Container(
                                      margin: const EdgeInsets.only(top: 8), 
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.05),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                      ),
                                      child: const Icon(Icons.mosque, color: Colors.white70, size: 24), 
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.navigation_rounded, 
                                  size: 80, 
                                  color: _isFacingQibla ? _kGreen : Colors.white,
                                ),
                                const SizedBox(height: 8),
                                AnimatedOpacity(
                                  opacity: _isFacingQibla ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Text(
                                    'Facing Qibla',
                                    style: GoogleFonts.outfit(color: _kGreen, fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 2),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05))
                      ),
                      child: Text(
                        'Align the white needle upward',
                        style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off_rounded, color: Colors.white24, size: 50),
          const SizedBox(height: 16),
          Text('Location unavailable', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 16)),
        ],
      ),
    );
  }
}