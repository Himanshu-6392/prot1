import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/providers/firebase_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2800), () async {
      if (!mounted) return;

      // Check the Hive box (it is already initialized in main)
      final box = Hive.box('settings');
      final hasSeenOnboarding =
          box.get('hasSeenOnboarding', defaultValue: false) as bool;

      // Check if the user is already logged in
      final isLoggedIn = ref.read(authStateProvider).valueOrNull != null;

      if (!mounted) return;
      if (isLoggedIn) {
        context.go('/');
      } else if (hasSeenOnboarding) {
        context.go('/auth/login');
      } else {
        context.go('/onboarding');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo mark
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withOpacity(0.45),
                      blurRadius: 40,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 48),
              )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut)
                  .fadeIn(duration: 400.ms),

              SizedBox(height: 28),

              Text('PeerLend',
                      style: AppTextStyles.displaySmall.copyWith(
                        foreground: Paint()
                          ..shader = AppColors.goldGradient.createShader(
                            const Rect.fromLTWH(0, 0, 200, 60),
                          ),
                      ))
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.3, end: 0),

              SizedBox(height: 8),

              Text('Secure Lending, Peer to Peer',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary))
                  .animate(delay: 500.ms)
                  .fadeIn(duration: 400.ms),

              SizedBox(height: 80),

              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.gold.withOpacity(0.6),
                ),
              ).animate(delay: 800.ms).fadeIn(duration: 300.ms),
            ],
          ),
        ),
      ),
    );
  }
}
