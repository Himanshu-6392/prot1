import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ─── Subtle Theme Background ───
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.emerald.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            top: 200,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withOpacity(0.05),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.transparent),
          ),

          // ─── Main Content ───
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  expandedHeight: 80,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 16, right: 20),
                    title: Text('Search Users',
                        style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary, fontSize: 20)),
                  ),
                ),

                // Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by name or email...',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                          prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(20),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                      ),
                    ).animate().fadeIn(duration: 400.ms),
                  ),
                ),

                // Users List Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Row(
                      children: [
                        Icon(Icons.people_alt_rounded, color: AppColors.textSecondary, size: 20),
                        const SizedBox(width: 8),
                        Text('All Platform Users',
                            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ),

                // Users List
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: CircularProgressIndicator(color: Colors.blue)),
                        ),
                      );
                    }
                    
                    final docs = snap.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = (data['name'] as String?)?.toLowerCase() ?? '';
                      final email = (data['email'] as String?)?.toLowerCase() ?? '';
                      return name.contains(_searchQuery) || email.contains(_searchQuery);
                    }).toList();

                    if (docs.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text('No users found',
                                style: TextStyle(color: AppColors.textPrimary.withOpacity(0.54))),
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(bottom: 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final data = docs[i].data() as Map<String, dynamic>;
                            return _AdminUserTile(uid: docs[i].id, data: data)
                                .animate()
                                .fadeIn(delay: (30 * i).ms)
                                .slideY(begin: 0.1, end: 0);
                          },
                          childCount: docs.length,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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

    Color kycColor = AppColors.warning;
    if (kyc == 'verified') kycColor = AppColors.emerald;
    if (kyc == 'rejected') kycColor = AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular Profile Avatar (Compact size)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.textPrimary, width: 1.5),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: AppTextStyles.h3.copyWith(
                    color: AppColors.textPrimary, 
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name, Email, Tags
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(name, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                    if (isPremium) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                    ]
                  ],
                ),
                Text(email,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textPrimary.withOpacity(0.5), fontSize: 11)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _PillTag(
                      text: role.toUpperCase(),
                      textColor: Colors.amber.shade700,
                      bgColor: Colors.amber.withOpacity(0.15),
                      borderColor: Colors.amber.withOpacity(0.3),
                    ),
                    const SizedBox(width: 6),
                    _PillTag(
                      text: kyc.toUpperCase(),
                      textColor: kycColor,
                      bgColor: kycColor.withOpacity(0.15),
                      borderColor: kycColor.withOpacity(0.3),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Compact Manage Button
          GestureDetector(
            onTap: () => _showUserControls(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Manage',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.bg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, color: AppColors.bg, size: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserControls(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => _UserControlPanel(uid: uid, data: data),
    );
  }
}

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor, letterSpacing: 0.5),
      ),
    );
  }
}

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

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Manage $name', style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary, fontSize: 22)),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withOpacity(0.05),
                    shape: BoxShape.circle
                  ),
                  child: IconButton(
                    icon: Icon(Icons.close_rounded, color: AppColors.textPrimary.withOpacity(0.7)),
                    onPressed: () => Navigator.pop(context),
                  ),
                )
              ],
            ),
            const SizedBox(height: 32),

            // ─── KYC Controls ───
            Text('KYC STATUS',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textPrimary.withOpacity(0.4), letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Row(
              children: [
                _ControlButton(
                  label: 'Verified',
                  isActive: kyc == 'verified',
                  activeColor: AppColors.emerald,
                  onTap: () => _updateUser(context, {'kycStatus': 'verified', 'isVerified': true}),
                ),
                const SizedBox(width: 8),
                _ControlButton(
                  label: 'Pending',
                  isActive: kyc == 'pending',
                  activeColor: AppColors.warning,
                  onTap: () => _updateUser(context, {'kycStatus': 'pending', 'isVerified': false}),
                ),
                const SizedBox(width: 8),
                _ControlButton(
                  label: 'Rejected',
                  isActive: kyc == 'rejected',
                  activeColor: AppColors.error,
                  onTap: () => _updateUser(context, {'kycStatus': 'rejected', 'isVerified': false}),
                ),
              ],
            ),

            const SizedBox(height: 28),
            // ─── Premium Control ───
            Text('SUBSCRIPTION',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textPrimary.withOpacity(0.4), letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Row(
              children: [
                _ControlButton(
                  label: 'Premium',
                  isActive: isPremium,
                  activeColor: Colors.blueAccent,
                  onTap: () => _updateUser(context, {'isPremium': true}),
                ),
                const SizedBox(width: 8),
                _ControlButton(
                  label: 'Standard',
                  isActive: !isPremium,
                  activeColor: AppColors.textSecondary,
                  onTap: () => _updateUser(context, {'isPremium': false}),
                ),
              ],
            ),

            const SizedBox(height: 28),
            // ─── Role Control ───
            Text('USER ROLE',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textPrimary.withOpacity(0.4), letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Row(
              children: [
                _ControlButton(
                  label: 'Borrower',
                  isActive: role == 'borrower',
                  activeColor: Colors.blue,
                  onTap: () => _updateUser(context, {'role': 'borrower'}),
                ),
                const SizedBox(width: 8),
                _ControlButton(
                  label: 'Lender',
                  isActive: role == 'lender',
                  activeColor: AppColors.emerald,
                  onTap: () => _updateUser(context, {'role': 'lender'}),
                ),
                const SizedBox(width: 8),
                _ControlButton(
                  label: 'Admin',
                  isActive: role == 'admin',
                  activeColor: Colors.purple,
                  onTap: () => _updateUser(context, {'role': 'admin'}),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ));
  }

  void _updateUser(BuildContext context, Map<String, dynamic> updates) {
    FirebaseFirestore.instance.collection('users').doc(uid).update(updates);
    Navigator.pop(context); // Close panel on change
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withOpacity(0.12) : AppColors.textPrimary.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? activeColor.withOpacity(0.3) : Colors.transparent,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : AppColors.textPrimary.withOpacity(0.5),
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
