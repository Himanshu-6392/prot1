import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/user_model.dart';
import '../../../core/services/activity_log_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN USER DETAIL SCREEN — Full Profile with Interactions & Chat Viewer
// ─────────────────────────────────────────────────────────────────────────────

class AdminUserDetailScreen extends ConsumerStatefulWidget {
  final String userId;
  const AdminUserDetailScreen({super.key, required this.userId});

  @override
  ConsumerState<AdminUserDetailScreen> createState() =>
      _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends ConsumerState<AdminUserDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  Future<void> _updateSubscription(bool makePremium) async {
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'isPremium': makePremium,
        'subscriptionPlan': makePremium ? 'premium' : 'basic',
        if (makePremium)
          'subscriptionExpiry':
              DateTime.now().add(const Duration(days: 30)).toIso8601String()
        else
          'subscriptionExpiry': FieldValue.delete(),
      });
      if (mounted) {
        _snack(makePremium ? '⭐ Upgraded to Premium' : 'Downgraded to Basic',
            isError: false);
      }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateKycStatus(KycStatus status) async {
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'kycStatus': status.name,
        'isVerified': status == KycStatus.verified,
      });

      ActivityLogService.log(
        type: status == KycStatus.verified
            ? ActivityType.kycApprove
            : ActivityType.kycReject,
        title: status == KycStatus.verified ? '✅ KYC Approved' : '❌ KYC Rejected',
        detail: 'User ID: ${widget.userId}',
        meta: {'targetUserId': widget.userId, 'status': status.name},
      );

      if (mounted) {
        _snack(
          status == KycStatus.verified ? 'KYC Approved ✅' : 'KYC Rejected ❌',
          isError: status != KycStatus.verified,
        );
      }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleBlock(bool block) async {
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'isBlocked': block});

      ActivityLogService.log(
        type: ActivityType.adminAction,
        title: block ? '🚫 User Blocked' : '✅ User Unblocked',
        detail: 'User ID: ${widget.userId}',
        meta: {'targetUserId': widget.userId, 'blocked': block},
      );

      if (mounted) {
        _snack(block ? 'User Blocked 🚫' : 'User Unblocked ✅',
            isError: block);
      }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.emerald,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
                child: CircularProgressIndicator(color: AppColors.gold));
          }
          final doc = snapshot.data!;
          if (!doc.exists) {
            return const Center(
                child: Text('User not found',
                    style: TextStyle(color: Colors.white)));
          }

          final data = doc.data() as Map<String, dynamic>;
          final user = UserModel.fromMap(data, doc.id);
          final kycMap = data['kyc'] as Map<String, dynamic>?;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              // ── Sliver App Bar with Hero Header ──
              SliverAppBar(
                expandedHeight: 260,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.bg,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  if (user.isBlocked)
                    _ActionChip(
                      label: 'BLOCKED',
                      color: AppColors.error,
                      icon: Icons.block_rounded,
                    ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeroHeader(user),
                ),
              ),

              // ── Tab Bar ──
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.gold,
                    indicatorWeight: 2.5,
                    labelColor: AppColors.gold,
                    unselectedLabelColor: AppColors.textMuted,
                    labelStyle: AppTextStyles.labelLarge
                        .copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                    unselectedLabelStyle:
                        AppTextStyles.labelLarge.copyWith(fontSize: 13),
                    tabs: const [
                      Tab(text: 'Profile'),
                      Tab(text: 'Documents'),
                      Tab(text: 'Interactions'),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _ProfileTab(user: user, data: data, onBlock: _toggleBlock, onSubscription: _updateSubscription, loading: _loading),
                _DocumentsTab(userId: widget.userId, kycMap: kycMap, user: user, onKyc: _updateKycStatus, loading: _loading),
                _InteractionsTab(userId: widget.userId),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroHeader(UserModel user) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surface,
            AppColors.bg,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 48),
            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                backgroundImage: user.photoUrl != null
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: user.photoUrl == null
                    ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: AppTextStyles.h1
                            .copyWith(color: AppColors.gold, fontSize: 34))
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Text(user.name, style: AppTextStyles.h2),
            const SizedBox(height: 4),
            Text(user.email,
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _StatusBadge(
                  label: user.role.name.toUpperCase(),
                  color: AppColors.emerald,
                ),
                if (user.isPremium)
                  _StatusBadge(label: '⭐ PREMIUM', color: AppColors.gold),
                if (user.isBlocked)
                  _StatusBadge(label: '🚫 BLOCKED', color: AppColors.error),
                if (user.isVerified)
                  _StatusBadge(label: '✓ VERIFIED', color: AppColors.info),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — PROFILE
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final UserModel user;
  final Map<String, dynamic> data;
  final Future<void> Function(bool) onBlock;
  final Future<void> Function(bool) onSubscription;
  final bool loading;

  const _ProfileTab({
    required this.user,
    required this.data,
    required this.onBlock,
    required this.onSubscription,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20).copyWith(bottom: 100),
      children: [
        // ── Personal Info ──
        _SectionCard(
          title: 'Personal Information',
          icon: Icons.person_outline_rounded,
          child: Column(
            children: [
              _InfoRow(label: 'Phone', value: user.phone.isNotEmpty ? user.phone : 'Not provided'),
              _InfoRow(label: 'City', value: user.city ?? 'Not provided'),
              _InfoRow(label: 'Gender', value: user.gender ?? 'Not provided'),
              _InfoRow(label: 'Display ID', value: user.displayId ?? 'N/A'),
              _InfoRow(label: 'Joined', value: DateFormat.yMMMd().format(user.createdAt)),
              _InfoRow(label: 'Last Updated', value: DateFormat.yMMMd().format(user.updatedAt)),
              _InfoRow(label: 'User UID', value: user.uid, isCopyable: true),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── KYC Status ──
        _SectionCard(
          title: 'KYC Status',
          icon: Icons.verified_user_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Status', style: AppTextStyles.bodyMedium),
                  _KycBadge(status: user.kycStatus),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Identity Verified', style: AppTextStyles.bodyMedium),
                  Icon(
                    user.isVerified ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: user.isVerified ? AppColors.emerald : AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Loan Requests ──
        _SectionCard(
          title: 'Loan Requests',
          icon: Icons.request_page_outlined,
          child: _LoanRequestsList(userId: user.uid),
        ),
        const SizedBox(height: 20),

        // ── Subscription ──
        _SectionCard(
          title: 'Subscription',
          icon: Icons.card_membership_rounded,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Current Plan', style: AppTextStyles.bodyMedium),
                  Text(
                    user.isPremium ? 'PREMIUM' : 'BASIC',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: user.isPremium ? AppColors.gold : AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (user.subscriptionExpiry != null) ...[
                const SizedBox(height: 6),
                _InfoRow(
                  label: 'Expires',
                  value: DateFormat.yMMMd().format(user.subscriptionExpiry!),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: user.isPremium ? 'Revoke Premium' : 'Grant Premium',
                      onPressed: loading ? null : () => onSubscription(!user.isPremium),
                      isOutlined: user.isPremium,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Danger Zone ──
        _SectionCard(
          title: 'Danger Zone',
          icon: Icons.warning_amber_rounded,
          titleColor: AppColors.error,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Blocking a user immediately suspends their access to the app.',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: user.isBlocked ? 'Unblock User ✅' : 'Block User 🚫',
                  onPressed: loading ? null : () => onBlock(!user.isBlocked),
                  color: user.isBlocked ? AppColors.emerald : AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — DOCUMENTS
// ─────────────────────────────────────────────────────────────────────────────
class _DocumentsTab extends StatelessWidget {
  final String userId;
  final Map<String, dynamic>? kycMap;
  final UserModel user;
  final Future<void> Function(KycStatus) onKyc;
  final bool loading;

  const _DocumentsTab({
    required this.userId,
    required this.kycMap,
    required this.user,
    required this.onKyc,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20).copyWith(bottom: 100),
      children: [
        // ── KYC Documents ──
        _SectionCard(
          title: 'KYC Documents',
          icon: Icons.badge_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Verification Status', style: AppTextStyles.bodyMedium),
                  _KycBadge(status: user.kycStatus),
                ],
              ),
              if (kycMap != null) ...[
                Divider(color: AppColors.border, height: 24),
                if (kycMap!['aadhaar'] != null)
                  _InfoRow(label: 'Aadhaar', value: kycMap!['aadhaar']),
                if (kycMap!['pan'] != null)
                  _InfoRow(label: 'PAN', value: kycMap!['pan']),
                if (kycMap!['address'] != null)
                  _InfoRow(label: 'Address', value: kycMap!['address']),
                if (kycMap!['dob'] != null)
                  _InfoRow(label: 'Date of Birth', value: kycMap!['dob']),
                if (kycMap!['occupation'] != null)
                  _InfoRow(label: 'Occupation', value: kycMap!['occupation']),
                if (kycMap!['income'] != null)
                  _InfoRow(label: 'Income', value: '₹${kycMap!['income']}'),

                // Document Images
                const SizedBox(height: 16),
                Text('Submitted Documents',
                    style: AppTextStyles.h3.copyWith(fontSize: 14)),
                const SizedBox(height: 12),
                _DocImageGrid(kycMap: kycMap!),
              ] else ...[
                Divider(color: AppColors.border, height: 24),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Icon(Icons.description_outlined,
                            color: AppColors.textMuted, size: 36),
                        const SizedBox(height: 8),
                        Text('No KYC data submitted',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              // Approve / Reject Buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: '✅ Approve',
                      onPressed: (loading || user.kycStatus == KycStatus.verified)
                          ? null
                          : () => onKyc(KycStatus.verified),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: '❌ Reject',
                      isOutlined: true,
                      onPressed: (loading || user.kycStatus == KycStatus.rejected)
                          ? null
                          : () => onKyc(KycStatus.rejected),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Uploaded Collaterals ──
        _SectionCard(
          title: 'Uploaded Collaterals',
          icon: Icons.inventory_2_outlined,
          child: _CollateralsList(userId: userId),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3 — INTERACTIONS
// ─────────────────────────────────────────────────────────────────────────────
class _InteractionsTab extends StatelessWidget {
  final String userId;
  const _InteractionsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.colMatches)
          .where('status', whereIn: [
            'pending',
            'accepted',
            'completed',
          ])
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Center(child: CircularProgressIndicator(color: AppColors.gold));
        }

        // Filter matches where this user is either borrower or lender
        final matches = snap.data!.docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['borrowerId'] == userId || data['lenderId'] == userId;
        }).toList();

        if (matches.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline_rounded,
                    color: AppColors.textMuted, size: 56),
                const SizedBox(height: 16),
                Text('No Interactions Yet',
                    style: AppTextStyles.h3.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Text('This user hasn\'t interacted with anyone',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20).copyWith(bottom: 100),
          itemCount: matches.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final matchDoc = matches[index];
            final matchData = matchDoc.data() as Map<String, dynamic>;
            final isBorrower = matchData['borrowerId'] == userId;
            final otherUserId = isBorrower
                ? (matchData['lenderId'] as String)
                : (matchData['borrowerId'] as String);
            final chatRoomId = matchData['chatRoomId'] as String?;
            final status = matchData['status'] as String? ?? 'pending';
            final updatedAt = (matchData['updatedAt'] as Timestamp?)?.toDate();

            return _InteractionCard(
              otherUserId: otherUserId,
              chatRoomId: chatRoomId,
              myRole: isBorrower ? 'Borrower' : 'Lender',
              otherRole: isBorrower ? 'Lender' : 'Borrower',
              status: status,
              updatedAt: updatedAt,
              matchData: matchData,
            ).animate(delay: Duration(milliseconds: index * 60))
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.05, end: 0);
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INTERACTION CARD — Shows the other user + opens their chat
// ─────────────────────────────────────────────────────────────────────────────
class _InteractionCard extends StatelessWidget {
  final String otherUserId;
  final String? chatRoomId;
  final String myRole;
  final String otherRole;
  final String status;
  final DateTime? updatedAt;
  final Map<String, dynamic> matchData;

  const _InteractionCard({
    required this.otherUserId,
    required this.chatRoomId,
    required this.myRole,
    required this.otherRole,
    required this.status,
    required this.updatedAt,
    required this.matchData,
  });

  Color get _statusColor {
    switch (status) {
      case 'accepted': return AppColors.emerald;
      case 'completed': return AppColors.info;
      case 'declined': return AppColors.error;
      default: return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
      builder: (context, snap) {
        String name = 'Loading...';
        String email = '';
        String? photoUrl;
        UserModel? otherUser;

        if (snap.hasData && snap.data!.exists) {
          final data = snap.data!.data() as Map<String, dynamic>;
          otherUser = UserModel.fromMap(data, otherUserId);
          name = otherUser.name;
          email = otherUser.email;
          photoUrl = otherUser.photoUrl;
        }

        return GestureDetector(
          onTap: () {
            if (chatRoomId != null && chatRoomId!.isNotEmpty) {
              // ── Open chat between these two users ──
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => _AdminChatPreviewSheet(
                  chatRoomId: chatRoomId!,
                  otherUser: otherUser,
                  status: status,
                  matchData: matchData,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('No chat started for this interaction'),
                  backgroundColor: AppColors.warning,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.emerald.withValues(alpha: 0.15),
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: AppTextStyles.h3
                              .copyWith(color: AppColors.emerald))
                      : null,
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              snap.connectionState == ConnectionState.waiting
                                  ? 'Loading...'
                                  : name,
                              style: AppTextStyles.labelLarge.copyWith(
                                  fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                  color: _statusColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        email,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.info.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              otherRole,
                              style: TextStyle(
                                  color: AppColors.info,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (updatedAt != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              AppFormatters.formatRelative(updatedAt!),
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Chat icon
                const SizedBox(width: 8),
                Icon(
                  chatRoomId != null
                      ? Icons.chat_bubble_outline_rounded
                      : Icons.chat_bubble_outline_rounded,
                  color: chatRoomId != null
                      ? AppColors.gold
                      : AppColors.textMuted,
                  size: 22,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN CHAT PREVIEW SHEET — Read-only view of a conversation
// ─────────────────────────────────────────────────────────────────────────────
class _AdminChatPreviewSheet extends StatelessWidget {
  final String chatRoomId;
  final UserModel? otherUser;
  final String status;
  final Map<String, dynamic> matchData;

  const _AdminChatPreviewSheet({
    required this.chatRoomId,
    required this.otherUser,
    required this.status,
    required this.matchData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Handle ──
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // ── Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.emerald.withValues(alpha: 0.15),
                  backgroundImage: otherUser?.photoUrl != null
                      ? NetworkImage(otherUser!.photoUrl!)
                      : null,
                  child: otherUser?.photoUrl == null
                      ? Text(
                          otherUser?.name.isNotEmpty == true
                              ? otherUser!.name[0].toUpperCase()
                              : '?',
                          style: AppTextStyles.h3
                              .copyWith(color: AppColors.emerald))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherUser?.name ?? 'Unknown User',
                        style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Chat Room — Admin View (Read Only)',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.gold),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '👁 ADMIN',
                    style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 10,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),

          Divider(color: AppColors.border, height: 24),

          // ── Match Details Strip ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MatchStat(
                  label: 'Amount',
                  value: matchData['offeredAmount'] != null
                      ? AppFormatters.formatINRCompact(matchData['offeredAmount'] as double)
                      : 'N/A',
                ),
                _MatchStat(
                  label: 'Interest',
                  value: matchData['offeredInterestRate'] != null
                      ? '${matchData['offeredInterestRate']}%'
                      : 'N/A',
                ),
                _MatchStat(
                  label: 'Status',
                  value: status.toUpperCase(),
                ),
              ],
            ),
          ),

          Divider(color: AppColors.border, height: 24),

          // ── Messages ──
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(AppConstants.colChats)
                  .doc(chatRoomId)
                  .collection(AppConstants.colMessages)
                  .orderBy('sentAt', descending: false)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return Center(
                      child: CircularProgressIndicator(color: AppColors.gold));
                }

                final msgs = snap.data!.docs;
                if (msgs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            color: AppColors.textMuted, size: 40),
                        const SizedBox(height: 12),
                        Text('No messages yet',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final msgData = msgs[i].data() as Map<String, dynamic>;
                    final senderId = msgData['senderId'] as String? ?? '';
                    final content = msgData['content'] as String? ?? '';
                    final type = msgData['type'] as String? ?? 'text';
                    final sentAt = (msgData['sentAt'] as Timestamp?)?.toDate();

                    return _AdminMessageBubble(
                      content: content,
                      senderId: senderId,
                      type: type,
                      sentAt: sentAt,
                    );
                  },
                );
              },
            ),
          ),

          // ── Read-only notice ──
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline_rounded, color: AppColors.warning, size: 18),
                const SizedBox(width: 10),
                Text(
                  'Admin view — read only. You cannot send messages.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.warning),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _AdminMessageBubble extends StatelessWidget {
  final String content;
  final String senderId;
  final String type;
  final DateTime? sentAt;

  const _AdminMessageBubble({
    required this.content,
    required this.senderId,
    required this.type,
    required this.sentAt,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(senderId).get(),
      builder: (context, snap) {
        final name = snap.hasData && snap.data!.exists
            ? ((snap.data!.data() as Map<String, dynamic>)['name'] as String? ?? 'Unknown')
            : 'Loading...';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: type == 'image'
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.image_outlined,
                                    color: AppColors.textMuted, size: 16),
                                const SizedBox(width: 6),
                                Text('📷 Photo',
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textSecondary)),
                              ],
                            )
                          : type == 'document'
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.attach_file_rounded,
                                        color: AppColors.textMuted, size: 16),
                                    const SizedBox(width: 6),
                                    Text(content.split('/').last,
                                        style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textSecondary)),
                                  ],
                                )
                              : Text(
                                  content,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textPrimary),
                                ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (sentAt != null)
                    Text(
                      DateFormat.jm().format(sentAt!),
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted, fontSize: 10),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LoanRequestsList extends StatelessWidget {
  final String userId;
  const _LoanRequestsList({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.colRequests)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Center(
              child: CircularProgressIndicator(color: AppColors.gold));
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text('No loan requests',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted)),
            ),
          );
        }
        return Column(
          children: docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            final amount = data['amount'] ?? 0;
            final purpose = data['purpose'] ?? 'N/A';
            final status = data['status'] ?? 'pending';
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppFormatters.formatINRCompact(amount.toDouble()),
                            style: AppTextStyles.labelLarge
                                .copyWith(color: AppColors.emerald)),
                        Text(purpose,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status.toString().toUpperCase(),
                          style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 9,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (createdAt != null)
                        Text(
                          DateFormat.MMMd().format(createdAt),
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textMuted, fontSize: 10),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _CollateralsList extends StatelessWidget {
  final String userId;
  const _CollateralsList({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('collaterals')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Center(child: CircularProgressIndicator(color: AppColors.gold));
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined,
                      color: AppColors.textMuted, size: 32),
                  const SizedBox(height: 8),
                  Text('No collaterals uploaded',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => Divider(color: AppColors.border, height: 24),
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final photos = List<String>.from(data['photoUrls'] ?? []);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(data['type'] ?? 'Unknown', style: AppTextStyles.labelLarge),
                    Text('₹${data['estimatedValue'] ?? 0}',
                        style: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.emerald)),
                  ],
                ),
                const SizedBox(height: 8),
                _InfoRow(
                    label: 'Serial/IMEI', value: data['serialNumber'] ?? 'N/A'),
                _InfoRow(label: 'Condition', value: data['condition'] ?? 'N/A'),
                if (data['description'] != null &&
                    data['description'].toString().isNotEmpty)
                  _InfoRow(label: 'Notes', value: data['description']),
                if (photos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, j) {
                        return GestureDetector(
                          onTap: () => _showFullImage(context, photos[j]),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              photos[j],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                width: 80,
                                height: 80,
                                color: AppColors.surfaceAlt,
                                child: Icon(Icons.image_not_supported_rounded,
                                    color: AppColors.textMuted),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain,
                  width: double.infinity, height: double.infinity),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocImageGrid extends StatelessWidget {
  final Map<String, dynamic> kycMap;
  const _DocImageGrid({required this.kycMap});

  @override
  Widget build(BuildContext context) {
    final docItems = <Map<String, String>>[];
    if (kycMap['selfieUrl'] != null) {
      docItems.add({'label': 'Selfie', 'url': kycMap['selfieUrl']});
    }
    if (kycMap['idFrontUrl'] != null) {
      docItems.add({'label': 'ID Front', 'url': kycMap['idFrontUrl']});
    }
    if (kycMap['idBackUrl'] != null) {
      docItems.add({'label': 'ID Back', 'url': kycMap['idBackUrl']});
    }
    if (kycMap['incomeProofUrl'] != null) {
      docItems.add({'label': 'Income Proof', 'url': kycMap['incomeProofUrl']});
    }
    if (kycMap['addressProofUrl'] != null) {
      docItems.add({'label': 'Address Proof', 'url': kycMap['addressProofUrl']});
    }

    if (docItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('No documents uploaded',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.2,
      ),
      itemCount: docItems.length,
      itemBuilder: (context, i) {
        final item = docItems[i];
        return GestureDetector(
          onTap: () => _showFullImage(context, item['url']!),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item['url']!,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      color: AppColors.surfaceAlt,
                      child: Center(
                        child: Icon(Icons.image_not_supported_rounded,
                            color: AppColors.textMuted),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item['label']!,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: Center(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 48,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchStat extends StatelessWidget {
  final String label;
  final String value;
  const _MatchStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTextStyles.h3
                .copyWith(fontWeight: FontWeight.w800, fontSize: 15)),
        Text(label,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: AppTextStyles.caption
              .copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _ActionChip(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _KycBadge extends StatelessWidget {
  final KycStatus status;
  const _KycBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case KycStatus.verified:
        color = AppColors.emerald;
        break;
      case KycStatus.rejected:
        color = AppColors.error;
        break;
      case KycStatus.submitted:
        color = AppColors.info;
        break;
      default:
        color = AppColors.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.5),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color? titleColor;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: titleColor ?? AppColors.textSecondary, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: AppTextStyles.h3
                      .copyWith(color: titleColor ?? AppColors.textPrimary)),
            ],
          ),
          Divider(color: AppColors.border, height: 28),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isCopyable;

  const _InfoRow(
      {required this.label, required this.value, this.isCopyable = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: GestureDetector(
              onTap: isCopyable
                  ? () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied: $value'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  : null,
              child: Row(
                children: [
                  Expanded(
                    child: Text(value,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textPrimary)),
                  ),
                  if (isCopyable) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.copy_rounded,
                        size: 14, color: AppColors.textMuted),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(
        color: AppColors.bg,
        child: tabBar,
      );

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) =>
      oldDelegate.tabBar != tabBar;
}
