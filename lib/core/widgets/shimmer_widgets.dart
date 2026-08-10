import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/colors.dart';

/// Generic shimmer placeholder
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceAlt,
      highlightColor: AppColors.surfaceHigh,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Shimmer for a lender card
class LenderCardShimmer extends StatelessWidget {
  const LenderCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            ShimmerBox(width: 52, height: 52, borderRadius: 26),
            SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ShimmerBox(width: 140, height: 14, borderRadius: 4),
              SizedBox(height: 6),
              ShimmerBox(width: 90, height: 10, borderRadius: 4),
            ]),
          ]),
          SizedBox(height: 16),
          Row(children: [
            ShimmerBox(width: 80, height: 10, borderRadius: 4),
            Spacer(),
            ShimmerBox(width: 80, height: 10, borderRadius: 4),
          ]),
          SizedBox(height: 12),
          ShimmerBox(width: double.infinity, height: 10, borderRadius: 4),
          SizedBox(height: 8),
          ShimmerBox(width: 200, height: 10, borderRadius: 4),
          SizedBox(height: 16),
          Row(children: [
            ShimmerBox(width: 60, height: 28, borderRadius: 8),
            SizedBox(width: 8),
            ShimmerBox(width: 60, height: 28, borderRadius: 8),
            SizedBox(width: 8),
            ShimmerBox(width: 60, height: 28, borderRadius: 8),
          ]),
        ],
      ),
    );
  }
}

/// Shimmer for a borrower request card
class RequestCardShimmer extends StatelessWidget {
  const RequestCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            ShimmerBox(width: 110, height: 14, borderRadius: 4),
            Spacer(),
            ShimmerBox(width: 70, height: 12, borderRadius: 4),
          ]),
          SizedBox(height: 12),
          ShimmerBox(width: double.infinity, height: 10, borderRadius: 4),
          SizedBox(height: 6),
          ShimmerBox(width: 180, height: 10, borderRadius: 4),
          SizedBox(height: 14),
          Row(children: [
            ShimmerBox(width: 70, height: 26, borderRadius: 6),
            SizedBox(width: 8),
            ShimmerBox(width: 70, height: 26, borderRadius: 6),
          ]),
        ],
      ),
    );
  }
}
