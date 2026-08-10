import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  String _searchQuery = '';
  String _roleFilter = 'All';
  String _kycFilter = 'All';
  String _subscriptionFilter = 'All';
  bool _showBlocked = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // ─── Background Blobs ───
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.emerald.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            left: -100,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withOpacity(0.05),
              ),
            ),
          ),

          // ─── Main Content ───
          Column(
            children: [
              // ─── Sticky Premium Header ───────────────────────────
              _StickyHeader(topPad: topPad),
              const SizedBox(height: 12),

              // ─── Search Bar ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SearchBar(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),

              const SizedBox(height: 10),

              // ─── Filter Row ──────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip('Role', _roleFilter, ['All', 'borrower', 'lender', 'admin'],
                        (v) => setState(() => _roleFilter = v!)),
                    const SizedBox(width: 8),
                    _buildFilterChip('KYC', _kycFilter,
                        ['All', 'pending', 'submitted', 'verified', 'rejected'],
                        (v) => setState(() => _kycFilter = v!)),
                    const SizedBox(width: 8),
                    _buildFilterChip('Plan', _subscriptionFilter, ['All', 'Basic', 'Premium'],
                        (v) => setState(() => _subscriptionFilter = v!)),
                    const SizedBox(width: 8),
                    _BlockedChip(
                      value: _showBlocked,
                      onChanged: (v) => setState(() => _showBlocked = v),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

              const SizedBox(height: 16),

              // ─── User List ───────────────────────────────────────
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.emerald,
                        ),
                      );
                    }

                    final docs = snap.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      final name = (data['name'] as String?)?.toLowerCase() ?? '';
                      final email = (data['email'] as String?)?.toLowerCase() ?? '';
                      if (!name.contains(_searchQuery) && !email.contains(_searchQuery)) return false;

                      if (_roleFilter != 'All' && data['role'] != _roleFilter) return false;
                      if (_kycFilter != 'All' && data['kycStatus'] != _kycFilter) return false;

                      final isPremium = data['isPremium'] == true;
                      if (_subscriptionFilter == 'Premium' && !isPremium) return false;
                      if (_subscriptionFilter == 'Basic' && isPremium) return false;

                      final isBlocked = data['isBlocked'] == true;
                      if (_showBlocked && !isBlocked) return false;

                      return true;
                    }).toList();

                    if (docs.isEmpty) {
                      return _EmptyState(query: _searchQuery);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      physics: const BouncingScrollPhysics(),
                      itemCount: docs.length + 1,
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          // Section Label
                          return Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 12),
                            child: Row(
                              children: [
                                Icon(Icons.people_alt_rounded,
                                    color: AppColors.textSecondary, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  '${docs.length} ${docs.length == 1 ? 'User' : 'Users'} Found',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 150.ms);
                        }
                        final idx = i - 1;
                        final data = docs[idx].data() as Map<String, dynamic>;
                        return _AdminUserTile(uid: docs[idx].id, data: data)
                            .animate()
                            .fadeIn(delay: (40 * idx).ms)
                            .slideY(begin: 0.06, end: 0);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    final isActive = value != 'All';
    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) => _FilterPickerSheet(label: label, current: value, options: items),
        );
        if (result != null) onChanged(result);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isActive ? AppColors.textPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.textPrimary : AppColors.border,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.textPrimary.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isActive ? '$label: ${value.toUpperCase()}' : label,
              style: AppTextStyles.caption.copyWith(
                color: isActive ? AppColors.bg : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: isActive ? AppColors.bg : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Sticky Premium Header
// ─────────────────────────────────────────────
class _StickyHeader extends StatelessWidget {
  final double topPad;
  const _StickyHeader({required this.topPad});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Padding(
        padding: EdgeInsets.only(
          top: topPad + 12,
          left: 8,
          right: 16,
          bottom: 16,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Back button
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20, color: AppColors.textPrimary),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'USER DIRECTORY',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                      letterSpacing: 2,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'All Platform Users',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Stats badge
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (ctx, snap) {
                final count = snap.data?.docs.length ?? 0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: AppColors.emerald,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$count total',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Premium Search Bar
// ─────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
              ),
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Blocked Chip
// ─────────────────────────────────────────────
class _BlockedChip extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _BlockedChip({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: value ? AppColors.error : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: value ? AppColors.error : AppColors.border),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: AppColors.error.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.block_rounded,
              size: 13,
              color: value ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              'Blocked',
              style: AppTextStyles.caption.copyWith(
                color: value ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Filter Picker Bottom Sheet
// ─────────────────────────────────────────────
class _FilterPickerSheet extends StatelessWidget {
  final String label;
  final String current;
  final List<String> options;
  const _FilterPickerSheet({required this.label, required this.current, required this.options});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Filter by $label',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ...options.map((opt) {
                final isSelected = opt == current;
                return GestureDetector(
                  onTap: () => Navigator.pop(context, opt),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.textPrimary : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            opt == 'All' ? 'All' : opt.toUpperCase(),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isSelected ? AppColors.bg : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_rounded, size: 18, color: AppColors.bg),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_search_rounded, size: 36, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          Text(
            query.isEmpty ? 'No users found' : 'No results for "$query"',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your filters',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// User Tile
// ─────────────────────────────────────────────
class _AdminUserTile extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> data;

  const _AdminUserTile({required this.uid, required this.data});

  @override
  Widget build(BuildContext context) {
    final String name = data['name'] ?? 'Unknown';
    final String email = data['email'] ?? 'No email';
    final String role = data['role'] ?? 'borrower';
    final bool isPremium = data['isPremium'] ?? false;
    final String kyc = data['kycStatus'] ?? 'pending';
    final bool isBlocked = data['isBlocked'] ?? false;

    Color kycColor = const Color(0xFFF59E0B);
    String kycLabel = 'PENDING';
    if (kyc == 'verified') { kycColor = const Color(0xFF10B981); kycLabel = 'VERIFIED'; }
    if (kyc == 'submitted') { kycColor = const Color(0xFF3B82F6); kycLabel = 'SUBMITTED'; }
    if (kyc == 'rejected') { kycColor = const Color(0xFFEF4444); kycLabel = 'REJECTED'; }

    Color roleColor = const Color(0xFF3B82F6);
    if (role == 'lender') roleColor = const Color(0xFF10B981);
    if (role == 'admin') roleColor = const Color(0xFF8B5CF6);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isBlocked ? AppColors.error.withOpacity(0.3) : AppColors.border,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showUserControls(context),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // ─── Avatar ───
                _Avatar(name: name, role: role, roleColor: roleColor, isPremium: isPremium),
                const SizedBox(width: 12),

                // ─── Info ───
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isPremium) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                          ],
                          if (isBlocked) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.block_rounded, color: AppColors.error, size: 13),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          _PillTag(
                            text: role.toUpperCase(),
                            textColor: roleColor,
                            bgColor: roleColor.withOpacity(0.1),
                            borderColor: roleColor.withOpacity(0.25),
                          ),
                          const SizedBox(width: 6),
                          _PillTag(
                            text: kycLabel,
                            textColor: kycColor,
                            bgColor: kycColor.withOpacity(0.1),
                            borderColor: kycColor.withOpacity(0.25),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // ─── Manage Arrow ───
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUserControls(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _UserControlPanel(uid: uid, data: data),
    );
  }
}

// ─────────────────────────────────────────────
// Avatar Widget
// ─────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String name;
  final String role;
  final Color roleColor;
  final bool isPremium;

  const _Avatar({required this.name, required this.role, required this.roleColor, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: roleColor.withOpacity(0.12),
            border: Border.all(color: roleColor.withOpacity(0.3), width: 1.5),
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: AppTextStyles.h3.copyWith(
                color: roleColor,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
        ),
        if (isPremium)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Color(0xFFF59E0B),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_rounded, size: 10, color: Colors.white),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Pill Tag
// ─────────────────────────────────────────────
class _PillTag extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color bgColor;
  final Color borderColor;

  const _PillTag({
    required this.text,
    required this.textColor,
    required this.bgColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// User Control Panel
// ─────────────────────────────────────────────
class _UserControlPanel extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> data;

  const _UserControlPanel({required this.uid, required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'User';
    final role = data['role'] ?? 'borrower';
    final kyc = data['kycStatus'] ?? 'pending';
    final isPremium = data['isPremium'] ?? false;
    final isBlocked = data['isBlocked'] ?? false;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          data['email'] ?? '',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceAlt,
                      shape: const CircleBorder(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ─── KYC Controls ───
              _SectionTitle(title: 'KYC STATUS'),
              const SizedBox(height: 10),
              Row(
                children: [
                  _ControlButton(label: 'Verified', isActive: kyc == 'verified',
                      activeColor: const Color(0xFF10B981),
                      onTap: () => _updateUser(context, {'kycStatus': 'verified', 'isVerified': true})),
                  const SizedBox(width: 8),
                  _ControlButton(label: 'Pending', isActive: kyc == 'pending',
                      activeColor: const Color(0xFFF59E0B),
                      onTap: () => _updateUser(context, {'kycStatus': 'pending', 'isVerified': false})),
                  const SizedBox(width: 8),
                  _ControlButton(label: 'Rejected', isActive: kyc == 'rejected',
                      activeColor: const Color(0xFFEF4444),
                      onTap: () => _updateUser(context, {'kycStatus': 'rejected', 'isVerified': false})),
                ],
              ),

              const SizedBox(height: 24),

              // ─── Premium Control ───
              _SectionTitle(title: 'SUBSCRIPTION'),
              const SizedBox(height: 10),
              Row(
                children: [
                  _ControlButton(label: 'Premium', isActive: isPremium,
                      activeColor: const Color(0xFF6366F1),
                      onTap: () => _updateUser(context, {'isPremium': true})),
                  const SizedBox(width: 8),
                  _ControlButton(label: 'Standard', isActive: !isPremium,
                      activeColor: AppColors.textSecondary,
                      onTap: () => _updateUser(context, {'isPremium': false})),
                ],
              ),

              const SizedBox(height: 24),

              // ─── Role Control ───
              _SectionTitle(title: 'USER ROLE'),
              const SizedBox(height: 10),
              Row(
                children: [
                  _ControlButton(label: 'Borrower', isActive: role == 'borrower',
                      activeColor: const Color(0xFF3B82F6),
                      onTap: () => _updateUser(context, {'role': 'borrower'})),
                  const SizedBox(width: 8),
                  _ControlButton(label: 'Lender', isActive: role == 'lender',
                      activeColor: const Color(0xFF10B981),
                      onTap: () => _updateUser(context, {'role': 'lender'})),
                  const SizedBox(width: 8),
                  _ControlButton(label: 'Admin', isActive: role == 'admin',
                      activeColor: const Color(0xFF8B5CF6),
                      onTap: () => _updateUser(context, {'role': 'admin'})),
                ],
              ),

              const SizedBox(height: 24),

              // ─── Block/Unblock ───
              _SectionTitle(title: 'ACCOUNT STATUS'),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _updateUser(context, {'isBlocked': !isBlocked}),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isBlocked
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : const Color(0xFFEF4444).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isBlocked
                          ? const Color(0xFF10B981).withOpacity(0.3)
                          : const Color(0xFFEF4444).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                        size: 16,
                        color: isBlocked ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isBlocked ? 'Unblock User' : 'Block User',
                        style: TextStyle(
                          color: isBlocked ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateUser(BuildContext context, Map<String, dynamic> updates) {
    FirebaseFirestore.instance.collection('users').doc(uid).update(updates);
    Navigator.pop(context);
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.caption.copyWith(
        color: AppColors.textMuted,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w700,
        fontSize: 10,
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _ControlButton({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withOpacity(0.12) : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? activeColor.withOpacity(0.35) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
