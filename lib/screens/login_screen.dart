import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_recitation/providers/providers.dart';
import 'package:quran_recitation/screens/main_shell.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/ui_v2/app_typography.dart';
import 'package:quran_recitation/ui_v2/widgets/glass_panel.dart';
import 'package:quran_recitation/ui_v2/widgets/q_kit.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _handleLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });

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
        setState(
            () => _error = 'Login was cancelled or failed. Please try again.');
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
          // Quiet jade veil, top
          Positioned(
            top: -100,
            left: 0,
            right: 0,
            child: Container(
              height: 340,
              decoration: BoxDecoration(
                gradient: RadialGradient(colors: [
                  AppColorsV2.primary.withValues(alpha: 0.08),
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
                          // ── Identity ─────────────────────────────────────
                          QStarMedallion(
                            size: 84,
                            color:
                                AppColorsV2.tertiary.withValues(alpha: 0.5),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: AppColorsV2.tertiary,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 26),
                          Text(
                            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                            style: AppTypeV2.arabic(
                              size: 20,
                              color: AppColorsV2.tertiary
                                  .withValues(alpha: 0.85),
                              height: 1.8,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text('Quran2U',
                              style: AppTypeV2.display(size: 38),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 14),
                          const QOrnamentDivider(),
                          const SizedBox(height: 16),
                          Text(
                            'Sign in with Quran.com to securely back up your saved Ayahs and Surahs to the cloud.',
                            style: AppTypeV2.body(size: 13.5),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 36),

                          const _FeatureRow(
                              icon: Icons.bookmark_rounded,
                              label: 'Sync saved Ayahs & Surahs'),
                          const SizedBox(height: 12),
                          const _FeatureRow(
                              icon: Icons.devices_rounded,
                              label: 'Access across your devices'),
                          const SizedBox(height: 12),
                          const _FeatureRow(
                              icon: Icons.security_rounded,
                              label: 'Secure cloud backup'),

                          const SizedBox(height: 40),

                          // Error message
                          if (_error != null) ...[
                            GlassPanel(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              borderRadius: BorderRadius.circular(14),
                              tint: AppColorsV2.dangerContainer
                                  .withValues(alpha: 0.25),
                              border: Border.all(
                                  color: AppColorsV2.danger
                                      .withValues(alpha: 0.3)),
                              child: Text(
                                _error!,
                                style: AppTypeV2.caption(
                                    size: 11.5, color: AppColorsV2.danger),
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
                                foregroundColor: AppColorsV2.onPrimary,
                                disabledBackgroundColor:
                                    AppColorsV2.primary.withValues(alpha: 0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                elevation: 0,
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: AppColorsV2.onPrimary,
                                      ),
                                    )
                                  : Text(
                                      'Sign in with Quran.com',
                                      style: AppTypeV2.title(
                                          size: 14.5,
                                          color: AppColorsV2.onPrimary),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () async {
                              await ref
                                  .read(quranAuthServiceProvider)
                                  .continueAsGuest();
                              if (!mounted) return;
                              // Show the welcome dialog only on the very first
                              // time the user taps 'Continue without login'.
                              // After that, the flag 'has_seen_welcome' is set
                              // in SharedPreferences and the dialog is skipped.
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const MainShell(
                                      showWelcome: true,
                                      isGuestWelcome: true),
                                ),
                              );
                            },
                            child: Text(
                              'Continue without login',
                              style: AppTypeV2.caption(
                                size: 13,
                                color: AppColorsV2.onSurfaceVariant,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                          Text(
                            'Your data is stored securely on Quran.com',
                            style: AppTypeV2.caption(
                              size: 10.5,
                              color: AppColorsV2.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                              weight: FontWeight.w600,
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
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColorsV2.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColorsV2.primary.withValues(alpha: 0.16)),
          ),
          child: Icon(icon, color: AppColorsV2.primary, size: 17),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: AppTypeV2.body(size: 13.5, height: 1.4),
          ),
        ),
      ],
    );
  }
}
