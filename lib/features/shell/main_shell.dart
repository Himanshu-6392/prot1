import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../models/user_model.dart';
import '../../../main.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    _TabItem(icon: Icons.home_rounded, label: 'Home', path: '/'),
    _TabItem(icon: Icons.search_rounded, label: 'Search', path: '/search'),
    _TabItem(icon: Icons.chat_bubble_rounded, label: 'Chat', path: '/chat'),
    _TabItem(
        icon: Icons.notifications_rounded,
        label: 'Alerts',
        path: '/notifications'),
  ];

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    for (var i = 0; i < _tabs.length; i++) {
      if (i == 0 && (loc == '/' || loc.startsWith('/lender'))) return 0;
      if (_tabs[i].path != '/' && loc.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx = _currentIndex(context);
    final userAsync = ref.watch(currentUserProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        extendBody: true,
        body: child,
        bottomNavigationBar:
            _buildNavBar(context, idx, userAsync.valueOrNull, isDark),
      ),
    );
  }

  Widget _buildNavBar(
      BuildContext context, int idx, UserModel? user, bool isDark) {
    return Container(
      // Completely seamless with the dark background
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000000) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : const Color(0xFFE5E7EB),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: _tabs.asMap().entries.map((entry) {
              final i = entry.key;
              final tab = entry.value;
              final isSelected = i == idx;
              return Expanded(
                child: _NavItem(
                  icon: tab.icon,
                  label: tab.label,
                  isSelected: isSelected,
                  isDark: isDark,
                  onTap: () => context.go(tab.path),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  final String path;
  const _TabItem({required this.icon, required this.label, required this.path});
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeIconColor = isDark ? Colors.white : const Color(0xFF111827);
    final inactiveIconColor = isDark
        ? const Color(0xFF3D3D3D)
        : const Color(0xFFB0B0B0);
    final activeLabelColor = isDark
        ? const Color(0xFF52C41A)
        : const Color(0xFF111827);
    final inactiveLabelColor = isDark
        ? const Color(0xFF3D3D3D)
        : const Color(0xFFB0B0B0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: isSelected ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            // Top indicator dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: isSelected ? 18 : 0,
              height: isSelected ? 2.5 : 0,
              decoration: BoxDecoration(
                color: const Color(0xFF52C41A),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            // Icon
            Icon(
              icon,
              color: isSelected ? activeIconColor : inactiveIconColor,
              size: 22,
            ),
            const SizedBox(height: 4),
            // Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                fontFamily: 'Inter',
                color: isSelected ? activeLabelColor : inactiveLabelColor,
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 0.1,
              ),
              child: Text(label),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
