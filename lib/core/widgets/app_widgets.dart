import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Primary gold gradient button with optional loading state
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Widget? icon;
  final double? width;
  final double height;
  final double borderRadius;
  final Color? color;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width,
    this.height = 52,
    this.borderRadius = 12,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return SizedBox(
        width:  width ?? double.infinity,
        height: height,
        child: OutlinedButton.icon(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color ?? AppColors.gold, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
          ),
          icon: isLoading
              ? _loader(color ?? AppColors.gold)
              : (icon ?? const SizedBox.shrink()),
          label: Text(label, style: AppTextStyles.button.copyWith(color: color ?? AppColors.gold)),
        ),
      );
    }

    return Container(
      width:  width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: isLoading || onPressed == null
            ? LinearGradient(colors: [Color(0x88F5A623), Color(0x88FFD166)])
            : AppColors.goldGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: onPressed != null ? [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ] : null,
      ),
      child: Material(
        color:         Colors.transparent,
        child: InkWell(
          onTap:          isLoading ? null : onPressed,
          borderRadius:   BorderRadius.circular(borderRadius),
          splashColor:    Colors.white12,
          highlightColor: Colors.white10,
          child: Center(
            child: isLoading
                ? _loader(AppColors.textInverse)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[icon!, SizedBox(width: 8)],
                      Text(label, style: AppTextStyles.button.copyWith(color: AppColors.textInverse)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _loader(Color color) => SizedBox(
    width: 20, height: 20,
    child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
  );
}

/// Icon-only circular button
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? bgColor;
  final double size;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.bgColor,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color:  bgColor ?? AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(size / 2),
      child: InkWell(
        onTap:        onPressed,
        borderRadius: BorderRadius.circular(size / 2),
        child: SizedBox(
          width:  size,
          height: size,
          child:  Icon(icon, color: color ?? AppColors.textPrimary, size: 20),
        ),
      ),
    );
  }
}

/// Small tag / badge chip
class TagChip extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? bgColor;
  final IconData? icon;

  TagChip({
    super.key,
    required this.label,
    this.color,
    this.bgColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final fg = color ?? AppColors.gold;
    final bg = bgColor ?? fg.withOpacity(0.12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(6),
        border:       Border.all(color: fg.withOpacity(0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: fg, size: 12),
            SizedBox(width: 4),
          ],
          Text(label, style: AppTextStyles.tag.copyWith(color: fg)),
        ],
      ),
    );
  }
}

/// Verified badge
class VerifiedBadge extends StatelessWidget {
  final bool small;
  VerifiedBadge({super.key, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8, vertical: small ? 2 : 4),
      decoration: BoxDecoration(
        color:        AppColors.emerald.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border:       Border.all(color: AppColors.emerald.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, color: AppColors.emerald, size: small ? 10 : 12),
          SizedBox(width: small ? 3 : 4),
          Text('Verified', style: AppTextStyles.tag.copyWith(
            color: AppColors.emerald,
            fontSize: small ? 9 : 11,
          )),
        ],
      ),
    );
  }
}

/// Star rating row
class StarRating extends StatelessWidget {
  final double rating;
  final int count;
  final bool compact;

  const StarRating({
    super.key,
    required this.rating,
    this.count = 0,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, color: AppColors.gold, size: compact ? 14 : 16),
        SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: AppTextStyles.labelMedium.copyWith(color: AppColors.gold),
        ),
        if (count > 0 && !compact) ...[
          SizedBox(width: 4),
          Text('($count)', style: AppTextStyles.caption),
        ],
      ],
    );
  }
}

/// Empty state widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color:        AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 48, color: AppColors.textMuted),
            ),
            SizedBox(height: 20),
            Text(title, style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
            if (subtitle != null) ...[
              SizedBox(height: 8),
              Text(subtitle!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted), textAlign: TextAlign.center),
            ],
            if (action != null) ...[SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

/// Section header with optional "See all" button or Expand toggle
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final bool isExpandable;
  final bool isExpanded;
  final VoidCallback? onToggle;

  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.isExpandable = false,
    this.isExpanded = true,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
      child: Row(
        children: [
          Text(title, style: AppTextStyles.h3),
          Spacer(),
          if (isExpandable)
            IconButton(
              onPressed: onToggle,
              icon: AnimatedRotation(
                turns: isExpanded ? 0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.keyboard_arrow_up_rounded, color: AppColors.gold),
              ),
            )
          else if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Text('See all', style: AppTextStyles.labelMedium.copyWith(color: AppColors.gold)),
            ),
        ],
      ),
    );
  }
}
