import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../models/user_model.dart';

// ─── Tab model ───────────────────────────────────────────────────────────────
class _TabItem {
  final IconData icon;       // outline (inactive)
  final IconData activeIcon; // filled (active)
  final String label;
  final String path;
  final bool isCenter;

  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
    this.isCenter = false,
  });
}

// ─── Shell ───────────────────────────────────────────────────────────────────
class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  // Layout: Home | Search | [FAB = Match] | Chat | Profile
  static const _tabs = [
    _TabItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
      path: '/',
    ),
    _TabItem(
      icon: Icons.search_outlined,
      activeIcon: Icons.search_rounded,
      label: 'Search',
      path: '/search',
    ),
    _TabItem(
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
      label: 'Match',
      path: '/match',
      isCenter: true,
    ),
    _TabItem(
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      label: 'Chat',
      path: '/chat',
    ),
    _TabItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
      path: '/profile',
    ),
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        extendBody: true,
        body: child,
        bottomNavigationBar: _PeerLendNavBar(
          tabs: _tabs,
          selectedIndex: idx,
          onTap: (i) => context.go(_tabs[i].path),
        ),
      ),
    );
  }
}

// ─── Nav Bar ─────────────────────────────────────────────────────────────────
class _PeerLendNavBar extends StatelessWidget {
  final List<_TabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const double _fabSize = 54.0;
  static const double _fabOverflow = 18.0;
  static const double _barHeight = 64.0;

  const _PeerLendNavBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.gold;
    final activeDark = const Color(0xFF3F3F46); // dark zinc for gradient

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
        child: SizedBox(
          height: _barHeight + _fabOverflow,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // ── Pill bar ─────────────────────────────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBar(context, activeColor),
              ),

              // ── Floating center FAB ───────────────────────────────────────
              Positioned(
                top: 0,
                child: _buildCenterFab(activeColor, activeDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBar(BuildContext context, Color emerald) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: _barHeight,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.8),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: tabs.asMap().entries.map((e) {
              final i = e.key;
              final tab = e.value;

              // Empty slot for center FAB
              if (tab.isCenter) {
                return const Expanded(child: SizedBox());
              }

              return Expanded(
                child: _NavRegularItem(
                  tab: tab,
                  isSelected: selectedIndex == i,
                  activeColor: emerald,
                  onTap: () => onTap(i),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterFab(Color activeColor, Color activeDark) {
    final isActive = selectedIndex == 2;
    final tab = tabs[2];

    return GestureDetector(
      onTap: () => onTap(2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: _fabSize,
        height: _fabSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [activeColor, activeDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: activeColor.withValues(alpha: isActive ? 0.45 : 0.20),
              blurRadius: isActive ? 18 : 10,
              spreadRadius: isActive ? 2 : 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isActive ? tab.activeIcon : tab.icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

// ─── Regular Nav Item ─────────────────────────────────────────────────────────
class _NavRegularItem extends StatelessWidget {
  final _TabItem tab;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _NavRegularItem({
    required this.tab,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isSelected ? tab.activeIcon : tab.icon,
              size: 22,
              color: isSelected ? activeColor : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: AppTextStyles.labelSmall.copyWith(
              fontSize: 10.5,
              color: isSelected ? activeColor : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
            child: Text(tab.label),
          ),
        ],
      ),
    );
  }
}
