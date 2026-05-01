import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_recitation/providers/providers.dart';
import 'package:quran_recitation/screens/main_shell.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/ui_v2/widgets/glass_panel.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _handleLogin() async {
    setState(() { _loading = true; _error = null; });

    try {
      final authService = ref.read(quranAuthServiceProvider);
      final success = await authService.login();

      if (!mounted) return;

      if (success) {
        ref.invalidate(isLoggedInProvider);
        ref.invalidate(userProfileProvider);

        // Always land on the Home (Surahs) tab regardless of where the user
        // was before opening the login screen.
        ref.read(shellIndexProvider.notifier).state = 0;

        // Automatically sync bookmarks upon successful login
        ref.read(bookmarkSyncProvider.notifier).syncToCloud();

        // Navigate FIRST (don't await — context is dead after pushReplacement).
        // Pass showWelcome:true so MainShell shows the dialog via initState
        // post-frame callback on its own live context.
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainShell(showWelcome: true)),
          );
        }

      } else {
        setState(() => _error = 'Login was cancelled or failed. Please try again.');
      }
    } catch (e) {
      debugPrint('================ OAUTH ERROR ================');
      debugPrint(e.toString());
      debugPrint('=============================================');
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsV2.bg,
      body: Stack(
        children: [
          // Glow
          Positioned(
            top: -80, left: -60,
            child: Container(
              width: 320, height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColorsV2.primary.withValues(alpha: 0.12),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top -
                            MediaQuery.of(context).padding.bottom,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                        // Logo area
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColorsV2.primary.withValues(alpha: 0.12),
                            border: Border.all(
                              color: AppColorsV2.primary.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: AppColorsV2.primary,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 28),

                        Text(
                          'Connect to Quran.com',
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        
                        // 👇 STRICTLY BOOKMARKS ONLY 👇
                        Text(
                          'Sign in to securely back up your saved Ayahs and Surahs to the cloud.',
                          style: GoogleFonts.manrope(
                            color: AppColorsV2.onSurfaceVariant,
                            fontSize: 14,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // 👇 STRICTLY BOOKMARKS ONLY 👇
                        const _FeatureRow(icon: Icons.bookmark_rounded, label: 'Sync saved Ayahs & Surahs'),
                        const SizedBox(height: 12),
                        const _FeatureRow(icon: Icons.devices_rounded, label: 'Access across your devices'),
                        const SizedBox(height: 12),
                        const _FeatureRow(icon: Icons.security_rounded, label: 'Secure cloud backup'),

                        const SizedBox(height: 44),

                        // Error message
                        if (_error != null) ...[
                          GlassPanel(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            borderRadius: BorderRadius.circular(12),
                            tint: Colors.red.withValues(alpha: 0.08),
                            border: Border.all(
                                color: Colors.red.withValues(alpha: 0.25)),
                            child: Text(
                              _error!,
                              style: GoogleFonts.manrope(
                                  color: Colors.redAccent, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Sign in button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColorsV2.primary,
                              foregroundColor: const Color(0xFF00311F),
                              disabledBackgroundColor:
                                  AppColorsV2.primary.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Color(0xFF00311F),
                                    ),
                                  )
                                : Text(
                                    'Sign in with Quran.com',
                                    style: GoogleFonts.manrope(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () async {
                            await ref.read(quranAuthServiceProvider).continueAsGuest();
                            if (!mounted) return;
                            // Show the welcome dialog only on the very first
                            // time the user taps 'Continue without login'.
                            // After that, the flag 'has_seen_welcome' is set
                            // in SharedPreferences and the dialog is skipped.
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const MainShell(showWelcome: true, isGuestWelcome: true),
                              ),
                            );
                          },
                          child: Text(
                            'Continue without login',
                            style: GoogleFonts.manrope(
                              color: Colors.white54, 
                              fontSize: 14, 
                              fontWeight: FontWeight.w600
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        Text(
                          'Your data is stored securely on Quran.com',
                          style: GoogleFonts.manrope(
                            color: Colors.white24,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppColorsV2.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColorsV2.primary, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.manrope(
              color: AppColorsV2.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}