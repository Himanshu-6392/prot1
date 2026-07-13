import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../models/user_model.dart';
import '../../../core/widgets/pin_entry_dialog.dart';
import '../../../core/providers/security_provider.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../core/widgets/app_widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isUploading = false;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ─── Photo Picker ─────────────────────────────

  // Sheet returns the chosen ImageSource as result, then we pick
  Future<void> _showPhotoOptions() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PhotoPickerSheet(),
    );
    if (source != null && mounted) {
      await _pickImage(source);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    Uint8List? bytes;

    if (kIsWeb) {
      // ── Web: use file_picker (directly triggers <input type="file">) ──
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      bytes = result.files.first.bytes;
    } else {
      // ── Native Android/iOS: use image_picker + permissions ──
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          if (mounted) _showSnack('Camera permission denied', isError: true);
          return;
        }
      } else {
        final status = await Permission.photos.request();
        if (!status.isGranted) {
          final storage = await Permission.storage.request();
          if (!storage.isGranted) {
            if (mounted) _showSnack('Storage permission denied', isError: true);
            return;
          }
        }
      }
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (picked == null) return;
      bytes = await picked.readAsBytes();
    }

    if (bytes == null || bytes.isEmpty) return;
    await _uploadBytes(bytes);
  }

  Future<void> _uploadBytes(Uint8List bytes) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      final storageRef =
          FirebaseStorage.instance.ref().child('profile_photos/$uid.jpg');

      final uploadTask = storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      uploadTask.snapshotEvents.listen((snap) {
        if (!mounted) return;
        setState(() {
          _uploadProgress = snap.bytesTransferred / snap.totalBytes;
        });
      });

      await uploadTask;
      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'photoUrl': downloadUrl});

      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        _showSnack('Profile photo updated! ✓', isError: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        _showSnack('Upload failed: ${e.toString()}', isError: true);
      }
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Background Gradient Mesh (Borrower Dashboard Style)
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.emerald.withValues(alpha: 0.05),
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
                color: AppColors.gold.withValues(alpha: 0.05),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.transparent),
          ),
          
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeroHeader(user),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _ProfileCompletionBar(user: user),
                      const SizedBox(height: 20),
                      _StatsRow(user: user),
                      const SizedBox(height: 24),
                      _KycStatusCard(user: user),
                      const SizedBox(height: 24),
                      _MenuSection(user: user),
                      const SizedBox(height: 24),
                      const _LogoutButton(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(UserModel? user) {
    final initials = user?.name.isNotEmpty == true
        ? user!.name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : 'U';

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: NeumorphicContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
                    ),
                  ),
                  Text('My Profile', style: AppTextStyles.h3),
                  GestureDetector(
                    onTap: () => _showSettingsDialog(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.settings_rounded, color: AppColors.textPrimary, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _isUploading ? null : _showPhotoOptions,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, __) => Container(
                        width: 100 + _pulseController.value * 4,
                        height: 100 + _pulseController.value * 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              AppColors.emerald,
                              AppColors.gold,
                              AppColors.emerald,
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surface,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: ClipOval(
                              child: _buildAvatarContent(user, initials),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_isUploading)
                      SizedBox(
                        width: 104,
                        height: 104,
                        child: CircularProgressIndicator(
                          value: _uploadProgress > 0 ? _uploadProgress : null,
                          strokeWidth: 3,
                          color: AppColors.gold,
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Icon(
                          _isUploading ? Icons.hourglass_top_rounded : Icons.camera_alt_rounded,
                          color: AppColors.gold,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 16),
              Text(
                user?.name ?? 'User',
                style: AppTextStyles.h2,
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? '',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildAvatarContent(UserModel? user, String initials) {
    if (_isUploading) {
      return Container(
        color: AppColors.surfaceAlt,
        child: Center(
          child: Text(
            '${(_uploadProgress * 100).toInt()}%',
            style: AppTextStyles.h4.copyWith(color: AppColors.gold),
          ),
        ),
      );
    }
    if (user?.photoUrl != null && user!.photoUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: user.photoUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: AppColors.surfaceAlt,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)),
        ),
        errorWidget: (_, __, ___) => _initialsWidget(initials),
      );
    }
    return _initialsWidget(initials);
  }

  Widget _initialsWidget(String initials) {
    return Container(
      decoration: BoxDecoration(gradient: AppColors.bgGradient),
      child: Center(
        child: Text(initials,
            style: AppTextStyles.h1.copyWith(color: AppColors.gold, fontSize: 32)),
      ),
    );
  }
}

class _ProfileCompletionBar extends StatelessWidget {
  final UserModel? user;
  const _ProfileCompletionBar({this.user});

  @override
  Widget build(BuildContext context) {
    int score = 20; // Base score for creating account
    if (user?.photoUrl != null && user!.photoUrl!.isNotEmpty) score += 20;
    if (user?.name != null && user!.name.trim().isNotEmpty) score += 20;
    if (user?.city != null && user!.city!.isNotEmpty) score += 10;
    if (user?.kycStatus == KycStatus.verified) score += 20;
    if (user?.phone != null && user!.phone.isNotEmpty) score += 10;

    score = score.clamp(0, 100);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: NeumorphicContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Profile Strength', style: AppTextStyles.h4),
                Text('$score%', style: AppTextStyles.h4.copyWith(color: AppColors.emerald)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 8,
                backgroundColor: AppColors.surfaceHigh,
                valueColor: AlwaysStoppedAnimation<Color>(
                  score == 100 ? AppColors.emerald : AppColors.gold,
                ),
              ),
            ),
            if (score < 100) ...[
              const SizedBox(height: 12),
              Text(
                'Complete your profile to unlock all features.',
                style: AppTextStyles.caption,
              ),
            ]
          ],
        ),
      ),
    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1);
  }
}

class _StatsRow extends ConsumerWidget {
  final UserModel? user;
  const _StatsRow({this.user});

  Future<void> _switchRole(BuildContext context, WidgetRef ref) async {
    if (user == null) return;
    final currentRole = user!.role;
    // Allow switching between lender and borrower
    final newRole = currentRole == UserRole.lender ? UserRole.borrower : UserRole.lender;

    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(Icons.swap_horiz_rounded, color: AppColors.gold, size: 48),
            const SizedBox(height: 16),
            Text('Switch Role', style: AppTextStyles.h2),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to switch your role to ${newRole.name.toUpperCase()}?',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Cancel', style: AppTextStyles.button.copyWith(color: AppColors.textPrimary)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppButton(
                    label: 'Switch to ${newRole.name}',
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(firestoreProvider).collection('users').doc(user!.uid).update({
          'role': newRole.name,
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Role switched to ${newRole.name}!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to switch role: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _MiniStat(
            value: _roleLabel(user?.role),
            label: 'Role',
            icon: Icons.badge_rounded,
            color: AppColors.gold,
            onTap: () => _switchRole(context, ref),
          ),
          const SizedBox(width: 12),
          _MiniStat(
            value: user?.kycStatus == KycStatus.verified ? 'Verified' : 'Pending',
            label: 'KYC',
            icon: Icons.verified_user_rounded,
            color: user?.kycStatus == KycStatus.verified ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 12),
          _MiniStat(
            value: user?.isPremium == true ? 'Premium' : 'Free',
            label: 'Plan',
            icon: Icons.workspace_premium_rounded,
            color: user?.isPremium == true ? AppColors.warning : AppColors.textMuted,
          ),
        ],
      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
    );
  }

  String _roleLabel(UserRole? role) {
    switch (role) {
      case UserRole.lender: return 'Lender';
      case UserRole.borrower: return 'Borrower';
      case UserRole.both: return 'Both';
      case UserRole.admin: return 'Admin';
      default: return 'User';
    }
  }
}

class _MiniStat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _MiniStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: NeumorphicContainer(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(value, style: AppTextStyles.h4.copyWith(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(label, style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }
}

class _KycStatusCard extends StatelessWidget {
  final UserModel? user;
  const _KycStatusCard({this.user});

  @override
  Widget build(BuildContext context) {
    final status = user?.kycStatus ?? KycStatus.pending;
    final isVerified = status == KycStatus.verified;
    final isSubmitted = status == KycStatus.submitted;
    
    final color = isVerified ? AppColors.success : (isSubmitted ? AppColors.info : AppColors.warning);
    final icon = isVerified ? Icons.verified_rounded : (isSubmitted ? Icons.hourglass_top_rounded : Icons.pending_rounded);
    
    String title = 'KYC Pending';
    String msg = 'Complete KYC to unlock full platform access.';
    if (isVerified) {
      title = 'KYC Verified';
      msg = 'Your identity has been verified successfully.';
    } else if (isSubmitted) {
      title = 'KYC Under Review';
      msg = 'Your documents are currently being verified by an admin.';
    } else if (status == KycStatus.rejected) {
      title = 'KYC Rejected';
      msg = 'Your KYC was rejected. Please resubmit your documents.';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          if (status == KycStatus.pending || status == KycStatus.rejected) {
            context.push('/kyc');
          }
        },
        child: NeumorphicContainer(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.h3),
                    const SizedBox(height: 4),
                    Text(msg, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              if (status == KycStatus.pending || status == KycStatus.rejected) 
                Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
    );
  }
}

class _MenuSection extends ConsumerWidget {
  final UserModel? user;
  const _MenuSection({this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryTitle('Account'),
          NeumorphicContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _MenuItem(
                  icon: Icons.person_rounded,
                  label: 'Edit Profile',
                  color: AppColors.info,
                  onTap: () {
                    if (user != null) showGlobalEditProfileDialog(context, user!);
                  },
                ),
                _buildDivider(),
                _MenuItem(
                  icon: Icons.account_balance_rounded,
                  label: 'Bank Details',
                  color: AppColors.emerald,
                  onTap: () {
                    if (user != null) showBankDetailsDialog(context, user!);
                  },
                ),
                _buildDivider(),
                _MenuItem(
                  icon: Icons.workspace_premium_rounded,
                  label: 'Subscription Plan',
                  color: AppColors.warning,
                  onTap: () => context.push('/plans'),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
          
          const SizedBox(height: 24),
          _buildCategoryTitle('Preferences'),
          NeumorphicContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _MenuItem(
                  icon: Icons.notifications_rounded,
                  label: 'Notifications',
                  color: AppColors.gold,
                  onTap: () => context.go('/notifications'),
                ),
                _buildDivider(),
                _MenuItem(
                  icon: Icons.security_rounded,
                  label: 'Security & Privacy',
                  color: AppColors.textPrimary,
                  onTap: () async {
                    final changed = await showChangePinFlow(context, ref);
                    if (changed && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('PIN updated successfully'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
          
          const SizedBox(height: 24),
          _buildCategoryTitle('Other'),
          NeumorphicContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _MenuItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  color: AppColors.textSecondary,
                  onTap: () => _showHelpSupportDialog(context),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildCategoryTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textMuted,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.surfaceHigh.withValues(alpha: 0.5),
      indent: 64,
      endIndent: 20,
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(label, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () async {
          ref.read(sensitiveDataVisibleProvider.notifier).state = false;
          await FirebaseAuth.instance.signOut();
        },
        child: NeumorphicContainer(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
              const SizedBox(width: 12),
              Text(
                'Log Out',
                style: AppTextStyles.h4.copyWith(color: AppColors.error),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),
    );
  }
}

class _PhotoPickerSheet extends StatelessWidget {
  const _PhotoPickerSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text('Update Profile Photo', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text('Choose a clear photo of yourself', style: AppTextStyles.bodySmall),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _PickerOption(
                    icon: Icons.photo_camera_rounded,
                    label: 'Camera',
                    color: AppColors.gold,
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: AppColors.emerald,
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTextStyles.bodyLarge),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: NeumorphicContainer(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(label, style: AppTextStyles.h4.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

void _showSettingsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: NeumorphicContainer(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('App Settings', style: AppTextStyles.h2),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppColors.surfaceAlt, shape: BoxShape.circle),
                    child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: Text('Dark Mode', style: AppTextStyles.bodyLarge),
              subtitle: Text('Toggle app theme', style: AppTextStyles.caption),
              value: AppColors.isDarkMode,
              activeColor: AppColors.emerald,
              onChanged: (val) {
                AppColors.toggleTheme(context);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

void _showHelpSupportDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: NeumorphicContainer(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Help & Support', style: AppTextStyles.h2),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppColors.surfaceAlt, shape: BoxShape.circle),
                    child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(Icons.email_rounded, color: AppColors.gold),
              title: Text('Email Us', style: AppTextStyles.bodyMedium),
              subtitle: Text('support@peerlend.com', style: AppTextStyles.caption),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: Icon(Icons.phone_rounded, color: AppColors.emerald),
              title: Text('Call Us', style: AppTextStyles.bodyMedium),
              subtitle: Text('+1 (800) 123-4567', style: AppTextStyles.caption),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showGlobalEditProfileDialog(
    BuildContext context, UserModel user) async {
  final nameCtr =
      TextEditingController(text: user.name == 'User' ? '' : user.name);
  final cityCtr = TextEditingController(
      text: user.city == 'India' ? '' : (user.city ?? ''));
  final phoneCtr = TextEditingController(text: user.phone);

  String? selectedGender = user.gender;
  final memberSince = DateFormat.yMMMMd().format(user.createdAt);

  bool isLoading = false;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                )
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Edit Profile', style: AppTextStyles.h2),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close_rounded,
                              size: 18, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Member Since (Read Only)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month_rounded,
                            color: AppColors.gold, size: 20),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Member Since',
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: AppColors.textMuted)),
                            Text(memberSince, style: AppTextStyles.bodyMedium),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 50.ms).slideX(begin: 0.05),
                  const SizedBox(height: 16),

                  // Email Field (Read Only)
                  TextField(
                    controller: TextEditingController(text: user.email),
                    readOnly: true,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      labelStyle: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textMuted),
                      prefixIcon: Icon(Icons.email_outlined,
                          color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surfaceAlt.withOpacity(0.5),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.05),
                  const SizedBox(height: 16),

                  // Name Field
                  TextField(
                    controller: nameCtr,
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textMuted),
                      prefixIcon: Icon(Icons.person_outline_rounded,
                          color: AppColors.gold),
                      filled: true,
                      fillColor: AppColors.surfaceAlt,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.05),
                  const SizedBox(height: 16),

                  // Phone Field
                  TextField(
                    controller: phoneCtr,
                    style: AppTextStyles.bodyMedium,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textMuted),
                      prefixIcon:
                          Icon(Icons.phone_outlined, color: AppColors.emerald),
                      filled: true,
                      fillColor: AppColors.surfaceAlt,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05),
                  const SizedBox(height: 16),

                  // Gender Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedGender,
                    dropdownColor: AppColors.surfaceAlt,
                    style: AppTextStyles.bodyMedium,
                    icon: Icon(Icons.arrow_drop_down_rounded,
                        color: AppColors.textMuted),
                    decoration: InputDecoration(
                      labelText: 'Gender',
                      labelStyle: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textMuted),
                      prefixIcon: Icon(Icons.wc_rounded, color: AppColors.gold),
                      filled: true,
                      fillColor: AppColors.surfaceAlt,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                      DropdownMenuItem(
                          value: 'Prefer not to say',
                          child: Text('Prefer not to say')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => selectedGender = val);
                    },
                  ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.05),
                  const SizedBox(height: 16),

                  // City Field
                  TextField(
                    controller: cityCtr,
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      labelText: 'City',
                      labelStyle: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textMuted),
                      prefixIcon: Icon(Icons.location_on_outlined,
                          color: AppColors.info),
                      filled: true,
                      fillColor: AppColors.surfaceAlt,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.05),

                  const SizedBox(height: 32),

                  // Save Button
                  GestureDetector(
                    onTap: isLoading
                        ? null
                        : () async {
                            final newName = nameCtr.text.trim();
                            final newCity = cityCtr.text.trim();
                            final newPhone = phoneCtr.text.trim();
                            if (newName.isEmpty) return;

                            setState(() => isLoading = true);
                            try {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .update({
                                'name': newName,
                                'city': newCity.isEmpty ? 'India' : newCity,
                                'phone': newPhone,
                                if (selectedGender != null)
                                  'gender': selectedGender,
                              });
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: const Text(
                                      'Profile updated successfully! 🎉'),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                ));
                              }
                            } catch (e) {
                              setState(() => isLoading = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                ));
                              }
                            }
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.gold.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      alignment: Alignment.center,
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text('Save Changes',
                              style: AppTextStyles.h4
                                  .copyWith(color: Colors.white)),
                    ),
                  ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

Future<void> showBankDetailsDialog(BuildContext context, UserModel user) async {
  final nameCtr = TextEditingController();
  final bankCtr = TextEditingController();
  final accCtr = TextEditingController();
  final ifscCtr = TextEditingController();
  bool isLoading = true;
  bool isSaving = false;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        // Load existing bank details once
        if (isLoading) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get()
              .then((doc) {
            if (doc.exists && doc.data()!.containsKey('bankDetails')) {
              final bankData =
                  doc.data()!['bankDetails'] as Map<String, dynamic>;
              nameCtr.text = bankData['accountName'] ?? '';
              bankCtr.text = bankData['bankName'] ?? '';
              accCtr.text = bankData['accountNumber'] ?? '';
              ifscCtr.text = bankData['ifsc'] ?? '';
            }
            if (ctx.mounted) {
              setState(() => isLoading = false);
            }
          });
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                )
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 32), // Spacer
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.gold.withOpacity(0.1),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.gold.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 2)
                          ],
                        ),
                        child: Icon(Icons.account_balance_rounded,
                            size: 32, color: AppColors.gold),
                      ).animate().scale(
                          delay: 50.ms,
                          duration: 400.ms,
                          curve: Curves.easeOutBack),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close_rounded,
                              size: 18, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Secure Bank Details',
                          style: AppTextStyles.h2.copyWith(fontSize: 22),
                          textAlign: TextAlign.center)
                      .animate()
                      .fadeIn(delay: 100.ms)
                      .slideY(begin: -0.2),
                  const SizedBox(height: 4),
                  Text('Your information is encrypted & secure.',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textMuted),
                          textAlign: TextAlign.center)
                      .animate()
                      .fadeIn(delay: 150.ms),
                  const SizedBox(height: 32),
                  if (isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                          child:
                              CircularProgressIndicator(color: AppColors.gold)),
                    )
                  else ...[
                    // Account Name Field
                    TextField(
                      controller: nameCtr,
                      style: AppTextStyles.bodyMedium,
                      decoration: InputDecoration(
                        labelText: 'Account Holder Name',
                        labelStyle: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textMuted),
                        prefixIcon: Icon(Icons.person_outline_rounded,
                            color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surfaceAlt,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: AppColors.gold, width: 2)),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05),
                    const SizedBox(height: 16),

                    // Bank Name Field
                    TextField(
                      controller: bankCtr,
                      style: AppTextStyles.bodyMedium,
                      decoration: InputDecoration(
                        labelText: 'Bank Name',
                        labelStyle: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textMuted),
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined,
                            color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surfaceAlt,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: AppColors.gold, width: 2)),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.05),
                    const SizedBox(height: 16),

                    // Account Number Field
                    TextField(
                      controller: accCtr,
                      style: AppTextStyles.bodyMedium,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Account Number',
                        labelStyle: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textMuted),
                        prefixIcon: Icon(Icons.numbers_rounded,
                            color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surfaceAlt,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: AppColors.gold, width: 2)),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.05),
                    const SizedBox(height: 16),

                    // IFSC Code Field
                    TextField(
                      controller: ifscCtr,
                      style: AppTextStyles.bodyMedium,
                      decoration: InputDecoration(
                        labelText: 'IFSC Code',
                        labelStyle: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textMuted),
                        prefixIcon:
                            Icon(Icons.pin_rounded, color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surfaceAlt,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: AppColors.gold, width: 2)),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ).animate().fadeIn(delay: 350.ms).slideX(begin: 0.05),

                    const SizedBox(height: 32),

                    // Save Button
                    GestureDetector(
                      onTap: isSaving
                          ? null
                          : () async {
                              final acctName = nameCtr.text.trim();
                              final acctNum = accCtr.text.trim();
                              final ifsc = ifscCtr.text.trim().toUpperCase();

                              if (acctName.isEmpty ||
                                  acctNum.isEmpty ||
                                  ifsc.isEmpty) {
                                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                  content:
                                      const Text('Please fill all details'),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                ));
                                return;
                              }

                              if (acctNum.length < 9) {
                                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                  content: const Text(
                                      'Account Number must be at least 9 digits'),
                                  backgroundColor: AppColors.warning,
                                  behavior: SnackBarBehavior.floating,
                                ));
                                return;
                              }

                              setState(() => isSaving = true);

                              // Verify IFSC with Razorpay API
                              try {
                                final response = await Dio()
                                    .get('https://ifsc.razorpay.com/$ifsc');
                                if (response.statusCode == 200) {
                                  final bankNameFromApi = response.data['BANK'];
                                  bankCtr.text =
                                      bankNameFromApi; // Auto-update bank name
                                }
                              } on DioException catch (e) {
                                setState(() => isSaving = false);
                                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                  content: const Text(
                                      'Invalid IFSC Code. Please verify your details.'),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                ));
                                return;
                              } catch (e) {
                                // Ignore other errors to not block the user entirely if API is down
                              }

                              try {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .update({
                                  'bankDetails': {
                                    'accountName': acctName,
                                    'bankName': bankCtr.text.trim(),
                                    'accountNumber': acctNum,
                                    'ifsc': ifsc,
                                    'updatedAt': Timestamp.now(),
                                  }
                                });
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: const Text(
                                        'Bank Details verified and saved securely! 🏦'),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                  ));
                                }
                              } catch (e) {
                                setState(() => isSaving = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx)
                                      .showSnackBar(SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                  ));
                                }
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.gold.withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6))
                          ],
                        ),
                        alignment: Alignment.center,
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.verified_user_rounded,
                                      color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text('Verify & Save',
                                      style: AppTextStyles.h4
                                          .copyWith(color: Colors.white)),
                                ],
                              ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .slideY(begin: 0.1)
                        .shimmer(
                            delay: 1000.ms,
                            duration: 1500.ms,
                            color: Colors.white.withOpacity(0.3)),
                  ]
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
