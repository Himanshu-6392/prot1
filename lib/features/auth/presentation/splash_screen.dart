import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/theme/colors.dart';
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user != null) {
      context.go('/');
    } else {
      context.go('/auth/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.bgGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Premium Lottie Logo Reveal
              SizedBox(
                width: 180,
                height: 180,
                child: Lottie.network(
                  'https://assets9.lottiefiles.com/packages/lf20_jcikwtux.json',
                  repeat: true,
                  animate: true,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.account_balance_rounded,
                        color: Colors.black87, size: 36),
                  ),
                ),
              ).animate().scaleXY(begin: 0.8, end: 1.0, duration: 800.ms, curve: Curves.easeOutBack).fadeIn(),
              
              const SizedBox(height: 12),
              
              Text(
                'PeerLend',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: -1.0,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutBack),
            ],
          ),
        ),
      ),
    );
  }
}
