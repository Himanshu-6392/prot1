import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../models/user_model.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    _TabItem(icon: Icons.home_rounded,       label: 'Home',    path: '/'),
    _TabItem(icon: Icons.search_rounded,     label: 'Search',  path: '/search'),
    _TabItem(icon: Icons.chat_bubble_rounded,label: 'Chat',    path: '/chat'),
    _TabItem(icon: Icons.notifications_rounded, label: 'Alerts', path: '/notifications'),
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
    final idx     = _currentIndex(context);
    final userAsync = ref.watch(currentUserProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        extendBody: false,
        body: child,
        bottomNavigationBar: _buildNavBar(context, idx, userAsync.valueOrNull),
      ),
    );
  }

  Widget _buildNavBar(BuildContext context, int idx, UserModel? user) {
    return Container(
      color: AppColors.bg,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16, top: 8),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6), width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
                    onTap: () => context.go(tab.path),
                  ),
                );
              }).toList(),
            ),
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
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.goldGradient : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: AppTextStyles.labelSmall.copyWith(
              color: isSelected ? AppColors.gold : AppColors.textMuted,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}
