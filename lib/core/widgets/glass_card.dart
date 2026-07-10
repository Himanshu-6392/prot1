import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// A frosted-glass card with optional gradient border glow.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;
  final Color? borderColor;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final bool glowOnHover;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 20,
    this.blur = 12,
    this.borderColor,
    this.gradient,
    this.onTap,
    this.glowOnHover = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            width: width,
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              gradient: gradient ??
                  LinearGradient(
                    colors: [Color(0x22FFFFFF), Color(0x0AFFFFFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? AppColors.glassBorder,
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Gradient container that matches the brand gold gradient.
class GoldContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double? width;
  final double? height;

  const GoldContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.borderRadius = 12,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
