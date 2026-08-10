import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../models/user_model.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/services/activity_log_service.dart';

class AdminUserDetailScreen extends ConsumerStatefulWidget {
  final String userId;
  const AdminUserDetailScreen({super.key, required this.userId});

  @override
  ConsumerState<AdminUserDetailScreen> createState() =>
      _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends ConsumerState<AdminUserDetailScreen> {
  bool _loading = false;

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                makePremium ? 'Upgraded to Premium' : 'Downgraded to Basic')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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
        title: status == KycStatus.verified
            ? '✅ KYC Approved'
            : '❌ KYC Rejected',
        detail: 'User ID: ${widget.userId}',
        meta: {'targetUserId': widget.userId, 'status': status.name},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('KYC updated to $status')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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
          .update({
        'isBlocked': block,
      });

      ActivityLogService.log(
        type: ActivityType.adminAction,
        title: block ? '🚫 User Blocked' : '✅ User Unblocked',
        detail: 'User ID: ${widget.userId}',
        meta: {'targetUserId': widget.userId, 'blocked': block},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(block ? 'User Blocked' : 'User Unblocked')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: AppIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.of(context).pop(),
          bgColor: Colors.transparent,
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: AppColors.gold));
          }
          final doc = snapshot.data!;
          if (!doc.exists) {
            return const Center(child: Text('User not found', style: TextStyle(color: Colors.white)));
          }

          final data = doc.data() as Map<String, dynamic>;
          final user = UserModel.fromMap(data, doc.id);
          final kycMap = data['kyc'] as Map<String, dynamic>?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20).copyWith(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(user),
                const SizedBox(height: 32),
                _buildPersonalInfo(user),
                const SizedBox(height: 32),
                _buildKycDocs(user, kycMap),
                const SizedBox(height: 32),
                _buildCollateralsList(),
                const SizedBox(height: 32),
                _buildSubscription(user),
                const SizedBox(height: 32),
                _buildDangerZone(user),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(UserModel user) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.gold.withOpacity(0.2),
            backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            child: user.photoUrl == null
                ? Text(user.name[0].toUpperCase(),
                    style: AppTextStyles.h1.copyWith(color: AppColors.gold, fontSize: 32))
                : null,
          ),
          const SizedBox(height: 16),
          Text(user.name, style: AppTextStyles.h2),
          Text(user.email, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border)),
                child: Text(user.role.name.toUpperCase(),
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              ),
              if (user.isPremium) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.gold.withOpacity(0.5))),
                  child: Row(
                    children: [
                      Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
                      const SizedBox(width: 4),
                      Text('PREMIUM', style: AppTextStyles.caption.copyWith(color: AppColors.gold)),
                    ],
                  ),
                ),
              ],
              if (user.isBlocked) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withOpacity(0.5))),
                  child: Text('BLOCKED', style: AppTextStyles.caption.copyWith(color: AppColors.error)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo(UserModel user) {
    return _SectionCard(
      title: 'Personal Information',
      icon: Icons.person_outline_rounded,
      child: Column(
        children: [
          _InfoRow(label: 'Phone', value: user.phone.isNotEmpty ? user.phone : 'Not provided'),
          _InfoRow(label: 'City', value: user.city ?? 'Not provided'),
          _InfoRow(label: 'Gender', value: user.gender ?? 'Not provided'),
          _InfoRow(label: 'Joined', value: DateFormat.yMMMd().format(user.createdAt)),
          _InfoRow(label: 'User ID', value: user.uid, isCopyable: true),
        ],
      ),
    );
  }

  Widget _buildKycDocs(UserModel user, Map<String, dynamic>? kycMap) {
    return _SectionCard(
      title: 'KYC & Documents',
      icon: Icons.badge_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Status', style: AppTextStyles.bodyMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: user.kycStatus == KycStatus.verified
                        ? AppColors.emerald.withOpacity(0.2)
                        : user.kycStatus == KycStatus.rejected
                            ? AppColors.error.withOpacity(0.2)
                            : AppColors.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(
                  user.kycStatus.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: user.kycStatus == KycStatus.verified
                        ? AppColors.emerald
                        : user.kycStatus == KycStatus.rejected
                            ? AppColors.error
                            : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          if (kycMap != null) ...[
            Divider(color: AppColors.border, height: 24),
            _InfoRow(label: 'Aadhaar', value: kycMap['aadhaar'] ?? 'N/A'),
            _InfoRow(label: 'PAN', value: kycMap['pan'] ?? 'N/A'),
            _InfoRow(label: 'Address', value: kycMap['address'] ?? 'N/A'),
            
            if (kycMap['selfieUrl'] != null) ...[
              const SizedBox(height: 16),
              Text('Selfie Upload', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  kycMap['selfieUrl'],
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    height: 120,
                    color: AppColors.surfaceAlt,
                    child: Center(child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted)),
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Approve',
                  onPressed: (_loading || user.kycStatus == KycStatus.verified)
                      ? null
                      : () => _updateKycStatus(KycStatus.verified),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Reject',
                  isOutlined: true,
                  onPressed: (_loading || user.kycStatus == KycStatus.rejected)
                      ? null
                      : () => _updateKycStatus(KycStatus.rejected),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollateralsList() {
    return _SectionCard(
      title: 'Uploaded Collaterals',
      icon: Icons.inventory_2_outlined,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('collaterals')
            .where('userId', isEqualTo: widget.userId)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return Center(child: CircularProgressIndicator(color: AppColors.gold));
          
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('No collaterals uploaded', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
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
                      Text(data['type'] ?? 'Unknown Type', style: AppTextStyles.labelLarge),
                      Text('₹${data['estimatedValue'] ?? 0}', style: AppTextStyles.labelLarge.copyWith(color: AppColors.emerald)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(label: 'Serial/IMEI', value: data['serialNumber'] ?? 'N/A'),
                  _InfoRow(label: 'Condition', value: data['condition'] ?? 'N/A'),
                  if (data['description'] != null && data['description'].toString().isNotEmpty)
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
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              photos[j],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                width: 80,
                                height: 80,
                                color: AppColors.surfaceAlt,
                                child: Icon(Icons.image_not_supported_rounded, color: AppColors.textMuted),
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
      ),
    );
  }

  Widget _buildSubscription(UserModel user) {
    return _SectionCard(
      title: 'Subscription',
      icon: Icons.card_membership_rounded,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Current Plan:', style: AppTextStyles.bodyMedium),
              Text(user.isPremium ? 'PREMIUM' : 'BASIC',
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: user.isPremium ? AppColors.gold : AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          if (user.isPremium)
            AppButton(
                label: 'Revoke Premium',
                onPressed: _loading ? null : () => _updateSubscription(false),
                isOutlined: true)
          else
            AppButton(
                label: 'Grant Premium',
                onPressed: _loading ? null : () => _updateSubscription(true)),
        ],
      ),
    );
  }

  Widget _buildDangerZone(UserModel user) {
    return _SectionCard(
      title: 'Danger Zone',
      icon: Icons.warning_amber_rounded,
      titleColor: AppColors.error,
      child: Column(
        children: [
          Text(
            'Blocking a user prevents them from accessing the app entirely.',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (user.isBlocked)
            AppButton(
                label: 'Unblock User',
                onPressed: _loading ? null : () => _toggleBlock(false),
                color: AppColors.success)
          else
            AppButton(
                label: 'Block User',
                onPressed: _loading ? null : () => _toggleBlock(true),
                color: AppColors.error),
        ],
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
          border: Border.all(color: AppColors.border, width: 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: titleColor ?? AppColors.textSecondary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.h3.copyWith(color: titleColor ?? AppColors.textPrimary)),
            ],
          ),
          Divider(color: AppColors.border, height: 32),
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

  const _InfoRow({required this.label, required this.value, this.isCopyable = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
