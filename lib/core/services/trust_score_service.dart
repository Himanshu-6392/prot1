import 'package:flutter/material.dart';
import '../../models/user_model.dart';

// ─────────────────────────────────────────────────────────────
// Trust Score Breakdown — holds per-category points + totals
// ─────────────────────────────────────────────────────────────
class TrustScoreBreakdown {
  final int totalScore;   // 0–1000
  final int score;        // alias for totalScore
  final String badgeText;
  final IconData levelIcon;

  // Per-category points (max shown in parentheses)
  final int profilePoints;        // max 200
  final int kycPoints;            // max 200
  final int activityPoints;       // max 300 (requests + matches + collateral)
  final int verificationPoints;   // max 200
  final int premiumPoints;        // max 100

  TrustScoreBreakdown({
    required this.totalScore,
    required this.badgeText,
    required this.levelIcon,
    this.profilePoints = 0,
    this.kycPoints = 0,
    this.activityPoints = 0,
    this.verificationPoints = 0,
    this.premiumPoints = 0,
  }) : score = totalScore;
}

// ─────────────────────────────────────────────────────────────
// Trust Score Service
// Score starts at 0 for a brand-new user and grows based on:
//   • Profile completeness (name, phone, email, city, gender, photo) — up to 200
//   • KYC status (submitted / verified)                              — up to 200
//   • Identity verification flag                                      — up to 200
//   • Activity (requests posted, matches made, collateral added)      — up to 300
//   • Premium subscription                                            — up to 100
// Total: 1000 pts
// ─────────────────────────────────────────────────────────────
class TrustScoreService {
  static TrustScoreBreakdown calculate({
    UserModel? user,
    int? requestsCount,
    int? matchesCount,
    int? collateralCount,
  }) {
    int profile = 0;
    int kyc = 0;
    int verification = 0;
    int activity = 0;
    int premium = 0;

    if (user != null) {
      // ── 1. Profile completeness — max 200 ──────────────────
      if (user.name.isNotEmpty) profile += 30;
      if (user.email.isNotEmpty) profile += 30;
      if (user.phone.isNotEmpty) profile += 30;
      if (user.photoUrl != null && user.photoUrl!.isNotEmpty) profile += 40;
      if (user.city != null && user.city!.isNotEmpty) profile += 40;
      if (user.gender != null && user.gender!.isNotEmpty) profile += 30;
      profile = profile.clamp(0, 200);

      // ── 2. KYC status — max 200 ────────────────────────────
      switch (user.kycStatus) {
        case KycStatus.submitted:
          kyc = 100;
          break;
        case KycStatus.verified:
          kyc = 200;
          break;
        default:
          kyc = 0;
      }

      // ── 3. Identity verification flag — max 200 ────────────
      if (user.isVerified) verification = 200;

      // ── 4. Premium subscription — max 100 ──────────────────
      if (user.isPremium) premium = 100;
    }

    // ── 5. Activity — max 300 ────────────────────────────────
    // Requests: each request = 20pts, cap at 120
    final reqPts = ((requestsCount ?? 0) * 20).clamp(0, 120);
    // Matches: each match = 25pts, cap at 120
    final matchPts = ((matchesCount ?? 0) * 25).clamp(0, 120);
    // Collateral: each item = 30pts, cap at 60
    final colPts = ((collateralCount ?? 0) * 30).clamp(0, 60);
    activity = (reqPts + matchPts + colPts).clamp(0, 300);

    final total = (profile + kyc + verification + activity + premium).clamp(0, 1000);

    return TrustScoreBreakdown(
      totalScore: total,
      badgeText: _badge(total),
      levelIcon: _icon(total),
      profilePoints: profile,
      kycPoints: kyc,
      activityPoints: activity,
      verificationPoints: verification,
      premiumPoints: premium,
    );
  }

  static String _badge(int score) {
    if (score >= 900) return 'Elite';
    if (score >= 750) return 'Excellent';
    if (score >= 550) return 'Good';
    if (score >= 350) return 'Fair';
    if (score >= 100) return 'Starter';
    return 'New';
  }

  static IconData _icon(int score) {
    if (score >= 750) return Icons.star_rounded;
    if (score >= 450) return Icons.star_half_rounded;
    return Icons.star_border_rounded;
  }

  /// Shows a bottom sheet with the score breakdown details.
  static void showBreakdownSheet(
      BuildContext context, TrustScoreBreakdown b) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BreakdownSheet(breakdown: b),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Breakdown Bottom Sheet
// ─────────────────────────────────────────────────────────────
class _BreakdownSheet extends StatelessWidget {
  final TrustScoreBreakdown breakdown;
  const _BreakdownSheet({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final items = [
      _Item('Profile Completeness', breakdown.profilePoints, 200,
          Icons.person_rounded, const Color(0xFF6366F1)),
      _Item('KYC Verification', breakdown.kycPoints, 200,
          Icons.verified_user_rounded, const Color(0xFF10B981)),
      _Item('Identity Verified', breakdown.verificationPoints, 200,
          Icons.badge_rounded, const Color(0xFF3B82F6)),
      _Item('App Activity', breakdown.activityPoints, 300,
          Icons.bolt_rounded, const Color(0xFFF59E0B)),
      _Item('Premium Plan', breakdown.premiumPoints, 100,
          Icons.workspace_premium_rounded, const Color(0xFFEF4444)),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Row(
            children: [
              const Icon(Icons.analytics_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text('Score Breakdown',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${breakdown.totalScore} / 1000',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...items.map((item) => _buildRow(item)),
          const SizedBox(height: 12),
          // Tip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    color: Color(0xFFF59E0B), size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Complete KYC, add collateral & post requests to grow your score faster.',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(_Item item) {
    final pct = item.points / item.max;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, color: item.color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(item.label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
              Text('${item.points} / ${item.max}',
                  style: TextStyle(
                      color: item.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(item.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _Item {
  final String label;
  final int points;
  final int max;
  final IconData icon;
  final Color color;
  const _Item(this.label, this.points, this.max, this.icon, this.color);
}
