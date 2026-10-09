import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/utils/constants.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});
  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  int _selected = 1; // 0=basic, 1=premium

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        leading: AppIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () => context.pop(),
            bgColor: Colors.transparent),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8))
                ],
              ),
              child: Column(children: [
                const Icon(Icons.workspace_premium_rounded,
                    size: 48, color: Colors.white),
                const SizedBox(height: 12),
                Text('Go Premium',
                    style: AppTextStyles.displaySmall
                        .copyWith(color: Colors.white)),
                const SizedBox(height: 6),
                Text(
                    'Unlock more connections, verified badge,\nand priority ranking',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: Colors.white70),
                    textAlign: TextAlign.center),
              ]),
            ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

            const SizedBox(height: 28),

            // Plan Cards
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: _PlanCard(
                title: 'Basic',
                price: AppConstants.subscriptionBasic,
                features: AppConstants.subscriptionFeatures['Basic']!,
                isSelected: _selected == 0,
                color: AppColors.info,
                onTap: () {
                  setState(() => _selected = 0);
                  HapticFeedback.selectionClick();
                },
              ).animate().fadeIn(delay: 100.ms)),
              const SizedBox(width: 12),
              Expanded(
                  child: _PlanCard(
                title: 'Premium',
                price: AppConstants.subscriptionPremium,
                features: AppConstants.subscriptionFeatures['Premium']!,
                isSelected: _selected == 1,
                color: AppColors.gold,
                badge: 'POPULAR',
                onTap: () {
                  setState(() => _selected = 1);
                  HapticFeedback.selectionClick();
                },
              ).animate().fadeIn(delay: 150.ms)),
            ]),

            const SizedBox(height: 28),

            // Contact Unlock option
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pay Per Contact',
                        style: AppTextStyles.h3
                            .copyWith(color: AppColors.emerald)),
                    const SizedBox(height: 6),
                    Text(
                        'Unlock individual contact details without a subscription.',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 14),
                    const Row(children: [
                      Expanded(
                          child: _ContactUnlockOption(
                              price: AppConstants.contactUnlockBasic,
                              label: 'Standard Unlock')),
                      SizedBox(width: 10),
                      Expanded(
                          child: _ContactUnlockOption(
                              price: AppConstants.contactUnlockPremium,
                              label: 'Priority Unlock')),
                    ]),
                  ]),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 28),

            AppButton(
              label: _selected == 0
                  ? 'Subscribe Basic — ₹${AppConstants.subscriptionBasic}/mo'
                  : 'Subscribe Premium — ₹${AppConstants.subscriptionPremium}/mo',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Payment gateway coming soon!')));
              },
              icon: const Icon(Icons.payment_rounded, size: 18),
            ).animate().fadeIn(delay: 250.ms),

            const SizedBox(height: 12),
            Text('Cancel anytime. Auto-renewed monthly.',
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final int price;
  final List<String> features;
  final bool isSelected;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.features,
    required this.isSelected,
    required this.color,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 2 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: 0.15), blurRadius: 16)
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(4)),
                child: Text(badge!,
                    style: AppTextStyles.tag
                        .copyWith(color: Colors.white, fontSize: 9)),
              ),
            const SizedBox(height: 8),
            Text(title,
                style: AppTextStyles.h3.copyWith(
                    color: isSelected ? color : AppColors.textPrimary)),
            const SizedBox(height: 6),
            RichText(
                text: TextSpan(
              text: '₹$price',
              style: AppTextStyles.amountMedium.copyWith(color: color),
              children: [
                TextSpan(
                    text: '/mo',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary))
              ],
            )),
            const SizedBox(height: 14),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Icon(Icons.check_rounded, color: color, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(f,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary))),
                  ]),
                )),
            const SizedBox(height: 8),
            if (isSelected)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8)),
                child: Center(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle_rounded, color: color, size: 14),
                  const SizedBox(width: 4),
                  Text('Selected',
                      style: AppTextStyles.labelSmall.copyWith(color: color)),
                ])),
              ),
          ],
        ),
      ),
    );
  }
}

class _ContactUnlockOption extends StatelessWidget {
  final int price;
  final String label;
  const _ContactUnlockOption({required this.price, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        Text('₹$price',
            style: AppTextStyles.amountSmall
                .copyWith(color: AppColors.emerald, fontSize: 18)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────
// Contact Unlock Screen
// ─────────────────────────────────────────────────────
class ContactUnlockScreen extends StatefulWidget {
  final String matchId;
  const ContactUnlockScreen({super.key, required this.matchId});
  @override
  State<ContactUnlockScreen> createState() => _ContactUnlockScreenState();
}

class _ContactUnlockScreenState extends State<ContactUnlockScreen> {
  bool _loading = false;
  bool _unlocked = false;
  final _otpCtr = TextEditingController();
  bool _otpSent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Unlock Contact', style: AppTextStyles.h3),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: _unlocked
                    ? AppColors.emerald.withValues(alpha: 0.12)
                    : AppColors.gold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: _unlocked ? AppColors.emerald : AppColors.gold,
                    width: 2),
              ),
              child: Icon(
                _unlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                color: _unlocked ? AppColors.emerald : AppColors.gold,
                size: 40,
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(_unlocked ? 'Contact Unlocked!' : 'Unlock Contact Details',
                style: AppTextStyles.h2, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              _unlocked
                  ? 'You can now see the full contact number and reach out directly.'
                  : 'Pay ₹${AppConstants.contactUnlockBasic} to unlock this contact\'s full details via OTP.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (!_unlocked) ...[
              const SizedBox(height: 32),
              if (_otpSent)
                TextFormField(
                  controller: _otpCtr,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h1.copyWith(letterSpacing: 16),
                  decoration: const InputDecoration(
                      labelText: 'Enter OTP', hintText: '──────'),
                  maxLength: 6,
                ).animate().fadeIn(),
              const SizedBox(height: 24),
              AppButton(
                label: _otpSent
                    ? 'Verify & Unlock'
                    : 'Pay ₹${AppConstants.contactUnlockBasic} & Get OTP',
                isLoading: _loading,
                onPressed: () async {
                  setState(() => _loading = true);
                  await Future.delayed(const Duration(seconds: 1));
                  if (!_otpSent) {
                    setState(() {
                      _loading = false;
                      _otpSent = true;
                    });
                  } else {
                    setState(() {
                      _loading = false;
                      _unlocked = true;
                    });
                  }
                },
                icon: const Icon(Icons.payment_rounded, size: 18),
              ),
            ],
            if (_unlocked) ...[
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.emerald.withValues(alpha: 0.3)),
                ),
                child: Column(children: [
                  Text('+91 98765 43210',
                      style:
                          AppTextStyles.h2.copyWith(color: AppColors.emerald)),
                  const SizedBox(height: 4),
                  Text('Tap to call', style: AppTextStyles.caption),
                ]),
              ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            ],
          ],
        ),
      ),
    );
  }
}
