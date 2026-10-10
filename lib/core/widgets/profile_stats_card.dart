import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../services/trust_score_service.dart';
import '../widgets/app_widgets.dart';
import '../../models/user_model.dart';

class ProfileStatsCard extends StatelessWidget {
  final UserModel? user;
  final TrustScoreBreakdown? breakdown;
  final VoidCallback onTrustScoreTap;
  final int? trustScore;
  final int? requestsCount;
  final int? matchesCount;
  final String? badgeText;
  final IconData? badgeIcon;
  final String? stat1Value;
  final String? stat1Label;
  final String? stat2Value;
  final String? stat2Label;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;

  const ProfileStatsCard({
    super.key,
    this.user,
    this.breakdown,
    required this.onTrustScoreTap,
    this.trustScore,
    this.requestsCount,
    this.matchesCount,
    this.badgeText,
    this.badgeIcon,
    this.stat1Value,
    this.stat1Label,
    this.stat2Value,
    this.stat2Label,
    this.buttonLabel,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final score = trustScore ?? 0;
    final badge = badgeText ?? 'Level 1';
    final icon = badgeIcon ?? Icons.star_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.insights_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'YOUR PROFILE STATS',
                style: AppTextStyles.tag.copyWith(
                  color: Colors.white70,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 12, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text(badge,
                        style: AppTextStyles.caption
                            .copyWith(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── Gauge + Stats row ────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Gauge
              GestureDetector(
                onTap: onTrustScoreTap,
                child: _TrustScoreGauge(score: score),
              ),
              const Spacer(),
              // Stat 1
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    stat1Value ?? '0',
                    style: AppTextStyles.amountLarge
                        .copyWith(color: Colors.white, fontSize: 24),
                  ),
                  Text(stat1Label ?? 'Active',
                      style: AppTextStyles.caption
                          .copyWith(color: Colors.white70)),
                ],
              ),
              const SizedBox(width: 24),
              // Stat 2
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    stat2Value ?? '0',
                    style: AppTextStyles.amountLarge
                        .copyWith(color: Colors.white, fontSize: 24),
                  ),
                  Text(stat2Label ?? 'Matches',
                      style: AppTextStyles.caption
                          .copyWith(color: Colors.white70)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── Full-width CTA button ────────────────────────
          if (buttonLabel != null && onButtonPressed != null)
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: buttonLabel!,
                onPressed: onButtonPressed,
                color: AppColors.emerald,
                icon: const Icon(Icons.add_rounded, size: 18),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

// ── Semi-circle trust score gauge (original) ─────────────────
class _TrustScoreGauge extends StatelessWidget {
  final int score;
  const _TrustScoreGauge({required this.score});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: score / 1000.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return CustomPaint(
          size: const Size(120, 60),
          painter: _TrustScorePainter(percentage: value),
          child: SizedBox(
            width: 120,
            height: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  (value * 1000).toInt().toString(),
                  style: AppTextStyles.amountLarge
                      .copyWith(color: Colors.white, fontSize: 24, height: 1.0),
                ),
                Text(
                  'Trust Score',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TrustScorePainter extends CustomPainter {
  final double percentage;
  _TrustScorePainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);
    const startAngle = math.pi;
    const sweepAngle = math.pi;

    // Background track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweepAngle, false, trackPaint);

    // Progress arc — Emerald → Gold gradient
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF34D399), Color(0xFFF59E0B)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
        rect, startAngle, sweepAngle * percentage, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _TrustScorePainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}
