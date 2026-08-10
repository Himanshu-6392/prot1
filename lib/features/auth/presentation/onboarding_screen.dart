import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_widgets.dart';

void _markOnboardingDone(BuildContext context, String destination) {
  Hive.box('settings').put('hasSeenOnboarding', true);
  context.go(destination);
}

class _Slide {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  const _Slide(
      {required this.icon,
      required this.iconColor,
      required this.title,
      required this.subtitle});
}

final _slides = [
  _Slide(
    icon: Icons.handshake_rounded,
    iconColor: AppColors.gold,
    title: 'Peer-to-Peer\nLending Made Easy',
    subtitle:
        'Connect directly with lenders and borrowers. No middlemen, no hidden fees.',
  ),
  _Slide(
    icon: Icons.shield_rounded,
    iconColor: AppColors.emerald,
    title: 'Secure & Transparent\nTransactions',
    subtitle:
        'Verified users and transparent terms ensure your money is always safe.',
  ),
  _Slide(
    icon: Icons.account_balance_wallet_rounded,
    iconColor: AppColors.goldLight,
    title: 'Flexible Collateral\nOptions',
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
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 20),
                child: TextButton(
                  onPressed: () => _markOnboardingDone(context, '/auth/login'),
                  child: Text('Skip',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.textSecondary)),
                ),
              ),
            ),

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

            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  _slides.length,
                  (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _current ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _current
                              ? AppColors.gold
                              : AppColors.textMuted.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )),
            ),

            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _current < _slides.length - 1
                  ? AppButton(
                      label: 'Next',
                      onPressed: () => _controller.nextPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    )
                  : AppButton(
                      label: 'Get Started',
                      onPressed: () =>
                          _markOnboardingDone(context, '/auth/login'),
                      icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                    ),
            ),

            const SizedBox(height: 16),

            if (_current < _slides.length - 1)
              TextButton(
                onPressed: () => _markOnboardingDone(context, '/auth/login'),
                child: Text('Already have an account? Sign in',
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.textSecondary)),
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
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: slide.iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                  color: slide.iconColor.withOpacity(0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: slide.iconColor.withOpacity(0.15),
                    blurRadius: 40,
                    spreadRadius: 4),
              ],
            ),
            child: Icon(slide.icon, size: 64, color: slide.iconColor),
          )
              .animate(key: ValueKey('icon_$idx'))
              .scale(duration: 500.ms, curve: Curves.elasticOut)
              .fadeIn(),
          const SizedBox(height: 40),
          Text(slide.title,
                  style: AppTextStyles.h1, textAlign: TextAlign.center)
              .animate(key: ValueKey('title_$idx'), delay: 100.ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.3, end: 0),
          const SizedBox(height: 16),
          Text(
            slide.subtitle,
            style: AppTextStyles.bodyLarge
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          )
              .animate(key: ValueKey('sub_$idx'), delay: 200.ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }
}
