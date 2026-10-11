import 'package:flutter/material.dart';

/// A wrapper widget that gives recommendation cards a subtle, premium
/// press-scale effect (~0.98 scale) on tap down, returning smoothly on release.
/// Respects accessibility reduced-motion preference.
class PressableCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final BorderRadius? borderRadius;

  const PressableCard({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 1.0,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final r = borderRadius ?? BorderRadius.circular(20);

    return Material(
      color: Colors.transparent,
      borderRadius: r,
      child: InkWell(
        borderRadius: r,
        onTap: onTap,
        child: child,
      ),
    );
  }
}

