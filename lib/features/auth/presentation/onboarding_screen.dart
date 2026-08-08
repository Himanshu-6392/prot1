import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/colors.dart';

void _markOnboardingDone(BuildContext context, String destination) {
  Hive.box('settings').put('hasSeenOnboarding', true);
  context.go(destination);
}

class _Slide {
  final String lottieUrl;
  final IconData fallbackIcon;
  final String title;
  final String subtitle;
  const _Slide({
    required this.lottieUrl,
    required this.fallbackIcon,
    required this.title,
    required this.subtitle,
  });
}

final _slides = [
  _Slide(
    lottieUrl: 'assets/animations/onboarding_1.json',
    fallbackIcon: Icons.handshake_rounded,
    title: 'Welcome to PeerLend',
    subtitle:
        "We're here to help you connect with lenders & borrowers. No middlemen, no hidden fees.",
  ),
  _Slide(
    lottieUrl: 'assets/animations/onboarding_2.json', // Shield/Security
    fallbackIcon: Icons.shield_rounded,
    title: 'Secure & Transparent',
    subtitle:
        'Verified users and transparent terms ensure your money is always safe.',
  ),
  _Slide(
    lottieUrl: 'assets/animations/onboarding_3.json', // Rocket/Growth
    fallbackIcon: Icons.rocket_launch_rounded,
    title: 'Flexible Options',
    subtitle:
        'Use digital assets, gold, or property as collateral for better rates.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(
          children: [
            // ── Top section ──────────────────────────────
            Expanded(
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Slides
                    Expanded(
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: _slides.length,
                        onPageChanged: (i) => setState(() => _current = i),
                        itemBuilder: (context, i) =>
                            _SlideView(slide: _slides[i], idx: i),
                      ),
                    ),

                    // Interactive Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _current ? 32 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _current
                                ? AppColors.emerald
                                : Colors.black.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ── White bottom card ────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 36, 28, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Expanding Primary Button
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: _GradientButton(
                        key: ValueKey<int>(_current),
                        label: _current < _slides.length - 1
                            ? 'Next'
                            : 'Get Started',
                        onPressed: () {
                          if (_current < _slides.length - 1) {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutCubic,
                            );
                          } else {
                            _markOnboardingDone(context, '/auth/signup');
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Outline "Log In" button
                    SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () =>
                            _markOnboardingDone(context, '/auth/login'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: Colors.black.withOpacity(0.2)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: Text(
                          'Log In',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Skip Button moved to bottom
                    if (_current < _slides.length - 1)
                      Center(
                        child: TextButton(
                          onPressed: () =>
                              _markOnboardingDone(context, '/auth/login'),
                          child: Text(
                            'Skip for now',
                            style: GoogleFonts.inter(
                              color: Colors.black45,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms)
                    else
                      const SizedBox(height: 48), // Spacer to prevent jitter
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  final int idx;
  const _SlideView({required this.slide, required this.idx});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie Animation
          SizedBox(
            width: 200,
            height: 200,
            child: Lottie.asset(
              slide.lottieUrl,
              repeat: true,
              animate: true,
              fit: BoxFit.contain,
              errorBuilder: (ctx, e, s) => Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.45),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(slide.fallbackIcon, size: 58, color: Colors.black87),
                ),
              ),
            ),
          )
              .animate(key: ValueKey('icon_$idx'))
              .scale(duration: 600.ms, curve: Curves.easeOutBack)
              .fadeIn(),

          const SizedBox(height: 40),

          Text(
            slide.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          )
              .animate(key: ValueKey('title_$idx'), delay: 100.ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.2, end: 0, curve: Curves.easeOutBack),

          const SizedBox(height: 16),

          Text(
            slide.subtitle,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.black54,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          )
              .animate(key: ValueKey('sub_$idx'), delay: 200.ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
        ],
      ),
    );
  }
}

/// Shared gradient pill button used across auth screens
class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _GradientButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.emeraldGradient,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: AppColors.emerald.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
