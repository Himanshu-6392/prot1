import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Shown when a user's account is blocked/suspended.
/// Automatically redirects to /auth/login after 5 seconds.
class AccountSuspendedScreen extends StatefulWidget {
  const AccountSuspendedScreen({super.key});

  @override
  State<AccountSuspendedScreen> createState() => _AccountSuspendedScreenState();
}

class _AccountSuspendedScreenState extends State<AccountSuspendedScreen> {
  int _secondsLeft = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        _signOutAndRedirect();
      }
    });
  }

  Future<void> _signOutAndRedirect() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) context.go('/auth/login');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _secondsLeft / 5.0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // ─── Background blobs ───
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withValues(alpha: 0.04),
              ),
            ),
          ),

          // ─── Main Content ───
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ─── Icon ───
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.gavel_rounded,
                        size: 48,
                        color: AppColors.error,
                      ),
                    )
                        .animate()
                        .scale(
                            duration: 600.ms,
                            curve: Curves.elasticOut,
                            begin: const Offset(0.3, 0.3))
                        .fadeIn(duration: 400.ms),

                    const SizedBox(height: 32),

                    // ─── Title ───
                    Text(
                      'Account Suspended',
                      style: AppTextStyles.h1.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                      ),
                      textAlign: TextAlign.center,
                    )
                        .animate(delay: 200.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 16),

                    // ─── Message ───
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Your account has been suspended by an administrator.',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'If you believe this is a mistake, please contact support.',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textMuted,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                        .animate(delay: 300.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 40),

                    // ─── Countdown ring ───
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 4,
                            backgroundColor: AppColors.border,
                            color: AppColors.error,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_secondsLeft',
                              style: AppTextStyles.h1.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w800,
                                fontSize: 28,
                              ),
                            ),
                            Text(
                              'sec',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ).animate(delay: 400.ms).fadeIn(duration: 300.ms),

                    const SizedBox(height: 8),
                    Text(
                      'Redirecting to login...',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ).animate(delay: 400.ms).fadeIn(),

                    const SizedBox(height: 32),

                    // ─── OK Button ───
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () {
                          _timer?.cancel();
                          _signOutAndRedirect();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'OK, Take me back',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                        .animate(delay: 500.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.15, end: 0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
