import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

class InteractiveEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String lottieUrl;

  const InteractiveEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.lottieUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          SizedBox(
            height: 120,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Center Lottie Illustration
                lottieUrl.startsWith('http')
                    ? Lottie.network(
                        lottieUrl,
                        height: 100,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.inbox_rounded,
                          size: 60,
                          color: Colors.white24,
                        ),
                      )
                    : Lottie.asset(
                        lottieUrl,
                        height: 100,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.inbox_rounded,
                          size: 60,
                          color: Colors.white24,
                        ),
                      ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Text Content
          Text(
            title,
            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ).animate().fadeIn().slideY(begin: 0.2, end: 0),
          
          const SizedBox(height: 4),
          
          Text(
            subtitle,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}

