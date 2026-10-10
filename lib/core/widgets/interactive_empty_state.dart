import 'package:flutter/foundation.dart';
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
            child: Center(
              child: kIsWeb
                  ? Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.inbox_outlined,
                        size: 34,
                        color: AppColors.emerald,
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .scale(begin: const Offset(0.96, 0.96), end: const Offset(1.04, 1.04), duration: 2.seconds)
                  : (lottieUrl.startsWith('http')
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
                        )),
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

