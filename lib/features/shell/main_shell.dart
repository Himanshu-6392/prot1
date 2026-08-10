import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../models/user_model.dart';
import '../../../main.dart';

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
    final userAsync = ref.watch(currentUserProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        extendBody: false,
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

  const _PeerLendNavBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: tabs.asMap().entries.map((entry) {
              final i = entry.key;
              final tab = entry.value;
              final isActive = selectedIndex == i;

              if (tab.isCenter) {
                return _NavCenterItem(
                  tab: tab,
                  isActive: isActive,
                  onTap: () => onTap(i),
                );
              }

              return Expanded(
                child: _NavTabItem(
                  tab: tab,
                  isActive: isActive,
                  onTap: () => onTap(i),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─── Regular Tab Item ─────────────────────────────────────────────────────────
class _NavTabItem extends StatelessWidget {
  final _TabItem tab;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTabItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.emerald : const Color(0xFFAAAAAA);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? tab.activeIcon : tab.icon,
                key: ValueKey(isActive),
                size: 24,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
                letterSpacing: 0.1,
              ),
              child: Text(tab.label),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Center FAB Item ──────────────────────────────────────────────────────────
class _NavCenterItem extends StatefulWidget {
  final _TabItem tab;
  final bool isActive;
  final VoidCallback onTap;

  const _NavCenterItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavCenterItem> createState() => _NavCenterItemState();
}

class _NavCenterItemState extends State<_NavCenterItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _ctrl.forward();
  void _onTapUp(_) {
    _ctrl.reverse();
    widget.onTap();
  }
  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: SizedBox(
        width: 72,
        height: 64,
        child: Center(
          child: AnimatedBuilder(
            animation: _scale,
            builder: (_, child) =>
                Transform.scale(scale: _scale.value, child: child),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6EE75A), Color(0xFF1DB954)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emerald.withValues(
                        alpha: widget.isActive ? 0.50 : 0.28),
                    blurRadius: widget.isActive ? 18 : 10,
                    spreadRadius: widget.isActive ? 1 : 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                widget.isActive ? widget.tab.activeIcon : widget.tab.icon,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
