import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../providers/saved_lenders_provider.dart';

class LenderBookmarkButton extends ConsumerWidget {
  final String lenderId;
  final String businessName;
  final String city;
  final bool isVerified;
  final double? maxLoanAmount;
  final double? minLoanAmount;
  final double? interestRatePerMonth;
  final int? maxTenureMonths;
  final List<String>? acceptedCollateral;
  final double? rating;
  final double size;
  final EdgeInsetsGeometry padding;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showBackground;

  const LenderBookmarkButton({
    super.key,
    required this.lenderId,
    required this.businessName,
    required this.city,
    required this.isVerified,
    this.maxLoanAmount,
    this.minLoanAmount,
    this.interestRatePerMonth,
    this.maxTenureMonths,
    this.acceptedCollateral,
    this.rating,
    this.size = 20,
    this.padding = const EdgeInsets.all(8),
    this.activeColor,
    this.inactiveColor,
    this.showBackground = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedIds = ref.watch(savedLenderIdsProvider).valueOrNull ?? {};
    final isSaved = savedIds.contains(lenderId);

    final resolvedActive = activeColor ?? AppColors.emerald;
    final resolvedInactive = inactiveColor ?? AppColors.textMuted;

    Widget iconWidget = Icon(
      isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
      color: isSaved ? resolvedActive : resolvedInactive,
      size: size,
    );

    if (showBackground) {
      iconWidget = Container(
        padding: padding,
        decoration: BoxDecoration(
          color: isSaved
              ? resolvedActive.withValues(alpha: 0.12)
              : AppColors.surfaceAlt,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSaved
                ? resolvedActive.withValues(alpha: 0.3)
                : AppColors.border.withValues(alpha: 0.6),
          ),
        ),
        child: iconWidget,
      );
    }

    return Semantics(
      button: true,
      label: isSaved ? 'Remove lender from saved' : 'Save lender',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            toggleSaveLender(
              context: context,
              ref: ref,
              lenderId: lenderId,
              businessName: businessName,
              city: city,
              isVerified: isVerified,
              maxLoanAmount: maxLoanAmount,
              minLoanAmount: minLoanAmount,
              interestRatePerMonth: interestRatePerMonth,
              maxTenureMonths: maxTenureMonths,
              acceptedCollateral: acceptedCollateral,
              rating: rating,
            );
          },
          child: Padding(
            padding: showBackground ? EdgeInsets.zero : padding,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: child,
              ),
              child: KeyedSubtree(
                key: ValueKey(isSaved),
                child: iconWidget,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
