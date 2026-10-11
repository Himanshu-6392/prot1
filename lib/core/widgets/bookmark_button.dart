import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../providers/saved_borrowers_provider.dart';

class BookmarkButton extends ConsumerWidget {
  final String borrowerId;
  final String borrowerName;
  final String borrowerCity;
  final bool isVerified;
  final double? loanAmount;
  final double? maxInterestRatePerMonth;
  final int? tenureMonths;
  final String? collateralType;
  final double? collateralValue;
  final String? requestId;
  final double size;
  final EdgeInsetsGeometry padding;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showBackground;

  const BookmarkButton({
    super.key,
    required this.borrowerId,
    required this.borrowerName,
    required this.borrowerCity,
    required this.isVerified,
    this.loanAmount,
    this.maxInterestRatePerMonth,
    this.tenureMonths,
    this.collateralType,
    this.collateralValue,
    this.requestId,
    this.size = 20,
    this.padding = const EdgeInsets.all(8),
    this.activeColor,
    this.inactiveColor,
    this.showBackground = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedIds = ref.watch(savedBorrowerIdsProvider).valueOrNull ?? {};
    final isSaved = savedIds.contains(borrowerId);

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
      label: isSaved ? 'Remove borrower from saved' : 'Save borrower',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            toggleSaveBorrower(
              context: context,
              ref: ref,
              borrowerId: borrowerId,
              borrowerName: borrowerName,
              borrowerCity: borrowerCity,
              isVerified: isVerified,
              loanAmount: loanAmount,
              maxInterestRatePerMonth: maxInterestRatePerMonth,
              tenureMonths: tenureMonths,
              collateralType: collateralType,
              collateralValue: collateralValue,
              requestId: requestId,
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
