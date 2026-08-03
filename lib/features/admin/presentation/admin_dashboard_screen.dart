import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/providers/admin_stats_provider.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/activity_log_service.dart';
import '../../../main.dart';
import 'admin_kyc_review_screen.dart';
import 'admin_platform_health_widget.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // ─── Background Blobs ───
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
                // ── Header ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 8, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ADMIN',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.textMuted,
                                  letterSpacing: 2,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Command Center',
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
                        IconButton(
                          icon: Icon(Icons.settings_outlined,
                              color: AppColors.textSecondary, size: 22),
                          onPressed: () => _showSettings(context, ref),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Stats Strip ─────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ref.watch(adminStatsProvider).when(
                          data: (stats) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _StatPill(
                                    label: 'Users',
                                    value: '${stats.totalUsers}',
                                    color: AppColors.textPrimary),
                                _Divider(),
                                _StatPill(
                                    label: 'Lenders',
                                    value: '${stats.activeLenders}',
                                    color: AppColors.emerald),
                                _Divider(),
                                _StatPill(
                                    label: 'Requests',
                                    value: '${stats.openRequests}',
                                    color: AppColors.info),
                                _Divider(),
                                _StatPill(
                                    label: 'KYC',
                                    value: '${stats.kycPending}',
                                    color: AppColors.error),
                              ],
                            ),
                          ).animate().fadeIn(duration: 400.ms),
                          loading: () => const SizedBox(
                              height: 64,
                              child: Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))),
                          error: (e, _) => const SizedBox.shrink(),
                        ),
                  ),
                ),

                // ── Section: Pending Actions ─────────────────
                SliverToBoxAdapter(
                  child: _SectionLabel(label: 'Pending Actions'),
                ),
                SliverToBoxAdapter(
                  child: _PendingActionsSection(),
                ),

                // ── Section: Platform Health ─────────────────
                SliverToBoxAdapter(
                  child: _SectionLabel(label: 'Platform Health'),
                ),
                SliverToBoxAdapter(
                  child: _PlatformHealthChart(),
                ),

                // ── Section: Recent Activity ─────────────────
                SliverToBoxAdapter(
                  child: _SectionLabel(label: 'Recent Activity'),
                ),
                SliverToBoxAdapter(
                  child: _RecentActivityFeed(),
                ),

                // ── Section: Top Users ───────────────────────
                SliverToBoxAdapter(
                  child: _SectionLabel(label: 'Top Users'),
                ),
                SliverToBoxAdapter(
                  child: _TopUsersSection(),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (ctx) => _AdminSettingsSheet(ref: ref),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Admin-Only Settings Sheet
// This widget is ONLY instantiated from AdminDashboardScreen._showSettings,
// ensuring these options never appear in any other user's settings panel.
// ─────────────────────────────────────────────────────────────────────────────
class _AdminSettingsSheet extends StatefulWidget {
  final WidgetRef ref;
  const _AdminSettingsSheet({required this.ref});

  @override
  State<_AdminSettingsSheet> createState() => _AdminSettingsSheetState();
}

class _AdminSettingsSheetState extends State<_AdminSettingsSheet> {
  bool _maintenanceMode = false;
  bool _emailDigest = true;
  bool _twoFA = false;
  bool _notifKyc = true;
  bool _notifLoans = true;
  bool _notifDisputes = true;
  String _defaultView = 'Overview';
  String _refreshInterval = '30s';
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('platform')
          .get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _maintenanceMode = data['maintenanceMode'] ?? false;
          _emailDigest = data['emailDigest'] ?? true;
          _twoFA = data['twoFA'] ?? false;
          _notifKyc = data['notifKyc'] ?? true;
          _notifLoans = data['notifLoans'] ?? true;
          _notifDisputes = data['notifDisputes'] ?? true;
          _defaultView = data['defaultView'] ?? 'Overview';
          _refreshInterval = data['refreshInterval'] ?? '30s';
          _appVersion = data['appVersion'] ?? '1.0.0';
        });
      }
    } catch (_) {}
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('platform')
          .set({key: value}, SetOptions(merge: true));
    } catch (_) {}
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: AppTextStyles.tag.copyWith(
              color: color,
              fontSize: 10,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 19),
        ),
        title: Text(title,
            style: AppTextStyles.labelLarge
                .copyWith(color: AppColors.textPrimary, fontSize: 14)),
        subtitle: subtitle != null
            ? Text(subtitle,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textMuted, fontSize: 11))
            : null,
        trailing: trailing ??
            Icon(Icons.chevron_right,
                color: AppColors.textPrimary.withOpacity(0.25), size: 18),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ── Admin Profile Dialog ─────────────────────────────────────────
  void _showAdminProfileDialog() {
    final user = FirebaseAuth.instance.currentUser;
    final nameCtrl = TextEditingController(text: user?.displayName ?? '');
    String? _newPhotoUrl = user?.photoURL;
    bool _uploadingPhoto = false;
    bool _saving = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // Pick photo and upload to Firebase Storage
          Future<void> pickAndUpload() async {
            try {
              final picker = ImagePicker();
              final picked = await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 512,
                maxHeight: 512,
                imageQuality: 85,
              );
              if (picked == null) return;

              setDialogState(() => _uploadingPhoto = true);

              final uid = user!.uid;
              final ref = FirebaseStorage.instance
                  .ref()
                  .child('profile_pics')
                  .child('$uid.jpg');

              await ref.putData(
                await picked.readAsBytes(),
                SettableMetadata(contentType: 'image/jpeg'),
              );

              final downloadUrl = await ref.getDownloadURL();
              await user.updatePhotoURL(downloadUrl);

              setDialogState(() {
                _newPhotoUrl = downloadUrl;
                _uploadingPhoto = false;
              });
            } catch (e) {
              setDialogState(() => _uploadingPhoto = false);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Upload failed: $e'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            }
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF10B981).withOpacity(0.12), blurRadius: 40, offset: const Offset(0, 8)),
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 4)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ─────────────────────────────
                    Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 4))],
                          ),
                          child: const Icon(Icons.manage_accounts_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Admin Profile', style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                              Text('Update your photo & display name', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.close, size: 16, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Avatar with upload button ───────────
                    Center(
                      child: GestureDetector(
                        onTap: _uploadingPhoto ? null : pickAndUpload,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: const Color(0xFF10B981).withOpacity(0.15),
                              backgroundImage: _newPhotoUrl != null ? NetworkImage(_newPhotoUrl!) : null,
                              child: _newPhotoUrl == null
                                  ? Text(
                                      (nameCtrl.text.isNotEmpty ? nameCtrl.text[0] : user?.displayName?.isNotEmpty == true ? user!.displayName![0] : 'A').toUpperCase(),
                                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 30, fontWeight: FontWeight.w700),
                                    )
                                  : null,
                            ),

                            // Upload overlay
                            if (_uploadingPhoto)
                              Container(
                                width: 88, height: 88,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 24, height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                  ),
                                ),
                              ),

                            // Camera badge
                            if (!_uploadingPhoto)
                              Positioned(
                                bottom: 2, right: 2,
                                child: Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.surface, width: 2),
                                    boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.4), blurRadius: 8)],
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 13),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Center(
                      child: Text(
                        _uploadingPhoto ? 'Uploading...' : 'Tap to change photo',
                        style: TextStyle(color: const Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Email (read-only) ──────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                      child: Row(
                        children: [
                          Icon(Icons.email_outlined, size: 16, color: AppColors.textMuted),
                          const SizedBox(width: 10),
                          Expanded(child: Text(user?.email ?? 'No email', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                            child: const Text('Verified', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Display name field ─────────────────
                    Container(
                      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                      child: TextField(
                        controller: nameCtrl,
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.person_outline, size: 18, color: AppColors.textMuted),
                          hintText: 'Display name',
                          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Action buttons ─────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                              child: Center(child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 14))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: (_saving || _uploadingPhoto) ? null : () async {
                              setDialogState(() => _saving = true);
                              final name = nameCtrl.text.trim();
                              try {
                                if (name.isNotEmpty) {
                                  await user?.updateDisplayName(name);
                                }
                                if (_newPhotoUrl != null && _newPhotoUrl != user?.photoURL) {
                                  await user?.updatePhotoURL(_newPhotoUrl);
                                }
                                // Also update Firestore user doc
                                if (user != null) {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .update({
                                    if (name.isNotEmpty) 'name': name,
                                    if (_newPhotoUrl != null) 'photoUrl': _newPhotoUrl,
                                  });
                                }
                                if (mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: const Text('✅ Profile updated successfully'),
                                    backgroundColor: const Color(0xFF10B981),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ));
                                }
                              } catch (e) {
                                setDialogState(() => _saving = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                  ));
                                }
                              }
                            },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
                              ),
                              child: Center(
                                child: (_saving || _uploadingPhoto)
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.check_rounded, color: Colors.white, size: 18),
                                          SizedBox(width: 8),
                                          Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Change Password Dialog ────────────────────────────────────────
  Future<void> _showChangePasswordDialog() async {
    // ── Step 1: Biometric / lock-screen verification ──────────────
    if (!kIsWeb) {
      try {
        final auth = LocalAuthentication();
        final canCheck = await auth.canCheckBiometrics || await auth.isDeviceSupported();
        if (!canCheck) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('⚠️ Device lock not set up. Please set a PIN, pattern or fingerprint.'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
          }
          return;
        }

        final verified = await auth.authenticate(
          localizedReason: 'Verify your identity to change the admin password',
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
          ),
        );

        if (!verified) return; // User cancelled or failed
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Authentication error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }
    }

    // ── Step 2: Show Set New Password dialog ──────────────────────
    if (!mounted) return;
    _showSetNewPasswordDialog();
  }

  void _showSetNewPasswordDialog() {
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool _showNew = false;
    bool _showConfirm = false;
    bool _saving = false;
    String _error = '';

    int _strength(String p) {
      int s = 0;
      if (p.length >= 8) s++;
      if (RegExp(r'[A-Z]').hasMatch(p)) s++;
      if (RegExp(r'[0-9]').hasMatch(p)) s++;
      if (RegExp(r'[!@#\$%^&*]').hasMatch(p)) s++;
      return s;
    }

    Color _strengthColor(int s) {
      if (s <= 1) return const Color(0xFFEF4444);
      if (s == 2) return const Color(0xFFF59E0B);
      if (s == 3) return const Color(0xFF3B82F6);
      return const Color(0xFF10B981);
    }

    String _strengthLabel(int s) {
      if (s <= 1) return 'Weak';
      if (s == 2) return 'Fair';
      if (s == 3) return 'Good';
      return 'Strong';
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final strength = _strength(newPassCtrl.text);
          final strengthColor = _strengthColor(strength);
          final strengthLabel = _strengthLabel(strength);

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: double.maxFinite,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.12), blurRadius: 40, offset: const Offset(0, 8)),
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 4)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──────────────────────────────
                    Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 4))],
                          ),
                          child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Set New Password', style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                              Row(
                                children: [
                                  const Icon(Icons.verified_rounded, size: 12, color: Color(0xFF10B981)),
                                  const SizedBox(width: 4),
                                  Text('Identity verified', style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.close, size: 16, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── New Password field ───────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: newPassCtrl,
                        obscureText: !_showNew,
                        onChanged: (_) => setDialogState(() { _error = ''; }),
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.lock_outline, size: 18, color: AppColors.textMuted),
                          hintText: 'New password',
                          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          suffixIcon: IconButton(
                            icon: Icon(_showNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: AppColors.textMuted),
                            onPressed: () => setDialogState(() => _showNew = !_showNew),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    // ── Password strength bar ────────────────
                    if (newPassCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: List.generate(4, (i) => Expanded(
                                child: Container(
                                  margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: i < strength ? strengthColor : AppColors.border,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              )),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(strengthLabel, style: TextStyle(color: strengthColor, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),

                    // ── Confirm Password field ───────────────
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: confirmPassCtrl.text.isNotEmpty && confirmPassCtrl.text != newPassCtrl.text
                              ? AppColors.error.withOpacity(0.5)
                              : AppColors.border,
                        ),
                      ),
                      child: TextField(
                        controller: confirmPassCtrl,
                        obscureText: !_showConfirm,
                        onChanged: (_) => setDialogState(() { _error = ''; }),
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.lock_clock_outlined, size: 18, color: AppColors.textMuted),
                          hintText: 'Confirm new password',
                          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          suffixIcon: IconButton(
                            icon: Icon(_showConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: AppColors.textMuted),
                            onPressed: () => setDialogState(() => _showConfirm = !_showConfirm),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    // ── Match indicator ──────────────────────
                    if (confirmPassCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            confirmPassCtrl.text == newPassCtrl.text ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            size: 13,
                            color: confirmPassCtrl.text == newPassCtrl.text ? const Color(0xFF10B981) : AppColors.error,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            confirmPassCtrl.text == newPassCtrl.text ? 'Passwords match' : 'Passwords do not match',
                            style: TextStyle(
                              color: confirmPassCtrl.text == newPassCtrl.text ? const Color(0xFF10B981) : AppColors.error,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // ── Requirements hint ────────────────────
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Password requirements', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          ...[
                            ('At least 8 characters', newPassCtrl.text.length >= 8),
                            ('One uppercase letter', RegExp(r'[A-Z]').hasMatch(newPassCtrl.text)),
                            ('One number', RegExp(r'[0-9]').hasMatch(newPassCtrl.text)),
                            ('One special character (!@#\$)', RegExp(r'[!@#\$%^&*]').hasMatch(newPassCtrl.text)),
                          ].map((req) => Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Row(
                              children: [
                                Icon(req.$2 ? Icons.check_circle_rounded : Icons.radio_button_unchecked, size: 12, color: req.$2 ? const Color(0xFF10B981) : AppColors.textMuted),
                                const SizedBox(width: 6),
                                Expanded(child: Text(req.$1, overflow: TextOverflow.ellipsis, style: TextStyle(color: req.$2 ? AppColors.textSecondary : AppColors.textMuted, fontSize: 11))),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),

                    // ── Error message ────────────────────────
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, size: 14, color: AppColors.error),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error, style: TextStyle(color: AppColors.error, fontSize: 12))),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),


                    // ── Action buttons ───────────────────────
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Primary: Update Password (full width)
                        GestureDetector(
                          onTap: _saving ? null : () async {
                            final newPass = newPassCtrl.text;
                            final confirm = confirmPassCtrl.text;

                            if (newPass.length < 8) {
                              setDialogState(() => _error = 'Password must be at least 8 characters.');
                              return;
                            }
                            if (!RegExp(r'[A-Z]').hasMatch(newPass)) {
                              setDialogState(() => _error = 'Add at least one uppercase letter.');
                              return;
                            }
                            if (!RegExp(r'[0-9]').hasMatch(newPass)) {
                              setDialogState(() => _error = 'Add at least one number.');
                              return;
                            }
                            if (newPass != confirm) {
                              setDialogState(() => _error = 'Passwords do not match.');
                              return;
                            }

                            setDialogState(() => _saving = true);
                            try {
                              await FirebaseAuth.instance.currentUser?.updatePassword(newPass);
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: const Text('🔒 Password updated successfully'),
                                  backgroundColor: const Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ));
                              }
                            } on FirebaseAuthException catch (e) {
                              String msg = 'Failed to update password.';
                              if (e.code == 'requires-recent-login') {
                                msg = 'Session expired. Please sign out and sign in again.';
                              }
                              setDialogState(() { _saving = false; _error = msg; });
                            } catch (e) {
                              setDialogState(() { _saving = false; _error = e.toString(); });
                            }
                          },
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            child: Center(
                              child: _saving
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.lock_rounded, color: Colors.white, size: 16),
                                        SizedBox(width: 8),
                                        Text('Update Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Secondary: Cancel (text link)
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── 2FA Dialog ───────────────────────────────────────────────────
  void _show2FADialog(bool enabling) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
            boxShadow: [
              BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.12), blurRadius: 40, offset: const Offset(0, 8)),
              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 4)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: enabling ? [const Color(0xFF6366F1), const Color(0xFF4F46E5)] : [const Color(0xFF6B7280), const Color(0xFF4B5563)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: Icon(enabling ? Icons.verified_user_rounded : Icons.shield_outlined, color: Colors.white, size: 34),
                ),
                const SizedBox(height: 20),
                Text(
                  enabling ? 'Enable 2FA?' : 'Disable 2FA?',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
                const SizedBox(height: 10),
                Text(
                  enabling
                      ? 'Two-Factor Authentication adds an extra layer of security to your admin account. You\'ll receive a code on your email when signing in from a new device.'
                      : 'Disabling 2FA reduces your account security. Your admin account will only be protected by your password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6),
                ),

                if (enabling) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2))),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFF6366F1), size: 16),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Codes will be sent to ${FirebaseAuth.instance.currentUser?.email ?? 'your email'}', style: const TextStyle(color: Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.w500))),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                          child: Center(child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 14))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          setState(() => _twoFA = enabling);
                          await _saveSetting('twoFA', enabling);
                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(enabling ? '🛡️ 2FA enabled successfully' : '⚠️ 2FA has been disabled'),
                              backgroundColor: enabling ? const Color(0xFF6366F1) : AppColors.warning,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ));
                          }
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: enabling ? [const Color(0xFF6366F1), const Color(0xFF4F46E5)] : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: Center(
                            child: Text(
                              enabling ? 'Enable 2FA' : 'Disable 2FA',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTextInputDialog(String title, String hint, Function(String) onSave) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final charCount = controller.text.length;
          const maxChars = 280;
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.12),
                    blurRadius: 40,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ────────────────────────────
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Broadcast to all users instantly',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.close, size: 16, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Text Field ────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: controller,
                        maxLines: 4,
                        maxLength: maxChars,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        decoration: InputDecoration(
                          hintText: hint,
                          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          contentPadding: const EdgeInsets.all(16),
                          border: InputBorder.none,
                          counterText: '',
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Character counter ─────────────────
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$charCount / $maxChars',
                        style: TextStyle(
                          color: charCount > maxChars * 0.9
                              ? AppColors.error
                              : AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Actions ───────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Center(
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (controller.text.trim().isNotEmpty) {
                                onSave(controller.text.trim());
                              }
                              Navigator.pop(ctx);
                            },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8B5CF6).withOpacity(0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send_rounded, color: Colors.white, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'Broadcast',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  void _showPickerDialog(String title, List<String> options, String current, Function(String) onSelect) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map((opt) => RadioListTile<String>(
                    value: opt,
                    groupValue: current,
                    title: Text(opt, style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                    activeColor: AppColors.emerald,
                    onChanged: (val) {
                      if (val != null) {
                        onSelect(val);
                        Navigator.pop(ctx);
                      }
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  Future<void> _exportReports() async {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('📊 Generating report… You will be notified when ready.'),
        backgroundColor: AppColors.emerald,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    // TODO: Trigger Cloud Function / generate CSV and share
  }

  @override
  Widget build(BuildContext context) {
    final isLight = widget.ref.watch(themeModeProvider) == ThemeMode.light;

    // ── Sync AppColors palette in THIS widget tree ─────────────────────────
    // The sheet lives in a modal route outside main.dart's subtree, so
    // AppColors.set*() is never called for it. We sync it here on every
    // rebuild so toggling theme re-renders the sheet immediately.
    if (isLight) {
      AppColors.setLight();
    } else {
      AppColors.setDark();
    }
    // ───────────────────────────────────────────────────────────────────────

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.admin_panel_settings_rounded,
                      color: AppColors.gold, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Admin Settings',
                    style: AppTextStyles.h3.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon:
                      Icon(Icons.close, color: AppColors.textMuted, size: 20),
                ),
              ],
            ),
          ),
          Divider(color: AppColors.border, height: 1),
          // Scrollable body
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(16, 4, 16, 32 + MediaQuery.of(context).padding.bottom),
              children: [
                // ── Theme ─────────────────────────────────────
                _sectionHeader('Appearance', Icons.palette_outlined, Colors.amber),
                _settingTile(
                  icon: isLight ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                  iconColor: Colors.amber,
                  title: 'Toggle Theme',
                  subtitle: isLight ? 'Switch to dark mode' : 'Switch to light mode',
                  onTap: () {
                    final current = widget.ref.read(themeModeProvider);
                    widget.ref.read(themeModeProvider.notifier).state =
                        current == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
                    setState(() {});
                  },
                ),

                // ── Admin Controls ─────────────────────────────
                _sectionHeader('Admin Controls', Icons.shield_outlined, const Color(0xFF6366F1)),
                _settingTile(
                  icon: Icons.construction_outlined,
                  iconColor: const Color(0xFF6366F1),
                  title: 'Maintenance Mode',
                  subtitle: _maintenanceMode ? 'Platform is in maintenance' : 'Platform is live',
                  trailing: Switch(
                    value: _maintenanceMode,
                    activeColor: AppColors.emerald,
                    onChanged: (val) async {
                      setState(() => _maintenanceMode = val);
                      await _saveSetting('maintenanceMode', val);
                      ActivityLogService.log(
                        type: ActivityType.maintenance,
                        title: val ? '🔧 Maintenance Mode Enabled' : '✅ Platform Back Live',
                        detail: val ? 'All non-admin users will see the maintenance screen' : 'Platform is now accessible to all users',
                        meta: {'maintenanceMode': val},
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(val
                              ? '🔧 Maintenance mode ON — users see a banner'
                              : '✅ Platform is back live'),
                          backgroundColor: val ? Colors.orange : AppColors.emerald,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ));
                      }
                    },
                  ),
                ),
                _settingTile(
                  icon: Icons.campaign_outlined,
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'Platform Announcement',
                  subtitle: 'Push a system-wide message to all users',
                  onTap: () => _showTextInputDialog(
                    'Platform Announcement',
                    'Type your announcement here…',
                    (msg) async {
                      // 1. Save to admin_settings for record-keeping
                      await _saveSetting('announcement', msg);
                      await _saveSetting('announcementActive', true);
                      await _saveSetting('announcementSentAt',
                          FieldValue.serverTimestamp());

                      // 2. Fan-out to every user's notifications subcollection
                      try {
                        final usersSnap = await FirebaseFirestore.instance
                            .collection('users')
                            .get();

                        // Firestore batch supports max 500 ops; chunk if needed
                        const chunkSize = 400;
                        final docs = usersSnap.docs;
                        for (int i = 0; i < docs.length; i += chunkSize) {
                          final batch = FirebaseFirestore.instance.batch();
                          final chunk = docs.skip(i).take(chunkSize);
                          for (final userDoc in chunk) {
                            final notifRef = FirebaseFirestore.instance
                                .collection('users')
                                .doc(userDoc.id)
                                .collection('notifications')
                                .doc();
                            batch.set(notifRef, {
                              'title': '📢 Platform Announcement',
                              'body': msg,
                              'type': 'announcement',
                              'isRead': false,
                              'iconName': 'campaign',
                              'color': '0xFF8B5CF6',
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                          }
                          await batch.commit();
                        }

                        // ── Log announcement ───────────────────────
                        ActivityLogService.log(
                          type: ActivityType.announcement,
                          title: '📢 Global Announcement Sent',
                          detail: msg,
                          meta: {'audienceCount': docs.length},
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                '📢 Announcement sent to ${docs.length} users!'),
                            backgroundColor: const Color(0xFF8B5CF6),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ));
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Error sending announcement: $e'),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ));
                        }
                      }
                    },
                  ),
                ),
                _settingTile(
                  icon: Icons.download_outlined,
                  iconColor: const Color(0xFF0EA5E9),
                  title: 'Export Reports',
                  subtitle: 'Download CSV/PDF of users, loans & KYC data',
                  onTap: _exportReports,
                ),

                // ── Account & Profile ──────────────────────────
                _sectionHeader('Account & Profile', Icons.person_outline, const Color(0xFF10B981)),
                _settingTile(
                  icon: Icons.manage_accounts_outlined,
                  iconColor: const Color(0xFF10B981),
                  title: 'Admin Profile',
                  subtitle: 'Edit name, photo & contact info',
                  onTap: () => _showAdminProfileDialog(),
                ),
                _settingTile(
                  icon: Icons.lock_reset_outlined,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Change Password',
                  subtitle: 'Send password reset email',
                  onTap: () => _showChangePasswordDialog(),
                ),
                _settingTile(
                  icon: Icons.verified_user_outlined,
                  iconColor: const Color(0xFF6366F1),
                  title: 'Two-Factor Authentication',
                  subtitle: _twoFA ? 'Enabled' : 'Disabled',
                  trailing: Switch(
                    value: _twoFA,
                    activeColor: AppColors.emerald,
                    onChanged: (val) => _show2FADialog(val),
                  ),
                ),

                // ── Notifications ──────────────────────────────
                _sectionHeader('Notifications', Icons.notifications_none_rounded, const Color(0xFFEC4899)),
                _settingTile(
                  icon: Icons.assignment_ind_outlined,
                  iconColor: const Color(0xFFEC4899),
                  title: 'KYC Alerts',
                  subtitle: 'Notify on new KYC submissions',
                  trailing: Switch(
                    value: _notifKyc,
                    activeColor: AppColors.emerald,
                    onChanged: (val) async {
                      setState(() => _notifKyc = val);
                      await _saveSetting('notifKyc', val);
                    },
                  ),
                ),
                _settingTile(
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: const Color(0xFF10B981),
                  title: 'Loan Alerts',
                  subtitle: 'Notify on new loan requests',
                  trailing: Switch(
                    value: _notifLoans,
                    activeColor: AppColors.emerald,
                    onChanged: (val) async {
                      setState(() => _notifLoans = val);
                      await _saveSetting('notifLoans', val);
                    },
                  ),
                ),
                _settingTile(
                  icon: Icons.gavel_outlined,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Dispute Alerts',
                  subtitle: 'Notify on user disputes',
                  trailing: Switch(
                    value: _notifDisputes,
                    activeColor: AppColors.emerald,
                    onChanged: (val) async {
                      setState(() => _notifDisputes = val);
                      await _saveSetting('notifDisputes', val);
                    },
                  ),
                ),
                _settingTile(
                  icon: Icons.mark_email_read_outlined,
                  iconColor: const Color(0xFF0EA5E9),
                  title: 'Weekly Email Digest',
                  subtitle: 'Receive a weekly platform summary',
                  trailing: Switch(
                    value: _emailDigest,
                    activeColor: AppColors.emerald,
                    onChanged: (val) async {
                      setState(() => _emailDigest = val);
                      await _saveSetting('emailDigest', val);
                    },
                  ),
                ),

                // ── Dashboard Preferences ──────────────────────
                _sectionHeader('Dashboard Preferences', Icons.dashboard_outlined, const Color(0xFF64748B)),
                _settingTile(
                  icon: Icons.view_quilt_outlined,
                  iconColor: const Color(0xFF64748B),
                  title: 'Default View',
                  subtitle: _defaultView,
                  onTap: () => _showPickerDialog(
                    'Default Dashboard View',
                    ['Overview', 'KYC Queue', 'Users', 'Platform Health'],
                    _defaultView,
                    (val) async {
                      setState(() => _defaultView = val);
                      await _saveSetting('defaultView', val);
                    },
                  ),
                ),
                _settingTile(
                  icon: Icons.timer_outlined,
                  iconColor: const Color(0xFF64748B),
                  title: 'Data Refresh Interval',
                  subtitle: _refreshInterval,
                  onTap: () => _showPickerDialog(
                    'Auto-Refresh Interval',
                    ['15s', '30s', '1m', '5m', 'Manual'],
                    _refreshInterval,
                    (val) async {
                      setState(() => _refreshInterval = val);
                      await _saveSetting('refreshInterval', val);
                    },
                  ),
                ),

                // ── Security & Audit ───────────────────────────
                _sectionHeader('Security & Audit', Icons.security_outlined, const Color(0xFFEF4444)),
                _settingTile(
                  icon: Icons.history_outlined,
                  iconColor: const Color(0xFFEF4444),
                  title: 'Activity Log',
                  subtitle: 'View all admin actions & timestamps',
                  onTap: () {
                    Navigator.pop(context);
                    _showActivityLog(context);
                  },
                ),
                _settingTile(
                  icon: Icons.devices_outlined,
                  iconColor: const Color(0xFFF97316),
                  title: 'Session Management',
                  subtitle: 'View & invalidate active login sessions',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('Session management — coming soon'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ));
                  },
                ),

                // ── App Info ───────────────────────────────────
                _sectionHeader('App Info', Icons.info_outline_rounded, AppColors.textMuted),
                _settingTile(
                  icon: Icons.smartphone_outlined,
                  iconColor: AppColors.textMuted,
                  title: 'App Version',
                  subtitle: 'v$_appVersion',
                  trailing: const SizedBox.shrink(),
                ),

                // ── Sign Out ───────────────────────────────────
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.redAccent.withOpacity(0.2), width: 1),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.logout_rounded,
                          color: Colors.redAccent, size: 19),
                    ),
                    title: Text('Sign Out',
                        style: AppTextStyles.labelLarge.copyWith(
                            color: Colors.redAccent, fontSize: 14)),
                    trailing: const SizedBox.shrink(),
                    onTap: () async {
                      Navigator.pop(context);
                      await FirebaseAuth.instance.signOut();
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _showActivityLog(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        expand: false,
        builder: (__, sc) => Column(
          children: [
            // ── Handle ──────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 4),
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // ── Header ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Row(children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.history_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Activity Log',
                        style: AppTextStyles.h3.copyWith(
                            color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                    Text('Real-time app events', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
                const Spacer(),
                // Live indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      const Text('LIVE', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    ],
                  ),
                ),
              ]),
            ),
            Divider(color: AppColors.border, height: 1),
            // ── Stream ──────────────────────────────
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('admin_activity_log')
                    .orderBy('timestamp', descending: true)
                    .limit(100)
                    .snapshots(),
                builder: (_, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        const SizedBox(height: 12),
                        Text('Loading activity...', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      ]),
                    );
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.history_toggle_off_outlined, size: 56, color: AppColors.textMuted.withOpacity(0.4)),
                        const SizedBox(height: 16),
                        Text('No activity yet', style: TextStyle(color: AppColors.textMuted, fontSize: 15, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Text('Activity will appear here as users interact', style: TextStyle(color: AppColors.textMuted.withOpacity(0.6), fontSize: 12)),
                      ]),
                    );
                  }
                  return ListView.separated(
                    controller: sc,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 2),
                    itemBuilder: (_, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      final ts = (d['timestamp'] as Timestamp?)?.toDate();
                      final typeStr = d['type'] as String? ?? '';
                      final title = d['title'] as String? ?? d['action'] as String? ?? '—';
                      final detail = d['detail'] as String? ?? '';

                      // Map type → colour & icon
                      final config = _activityConfig(typeStr);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border.withOpacity(0.5)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon badge
                            Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color: config.$3.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(child: Text(config.$1, style: const TextStyle(fontSize: 18))),
                            ),
                            const SizedBox(width: 12),
                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                    ),
                                  ),
                                  if (detail.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      detail,
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.3),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: config.$3.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(config.$2, style: TextStyle(color: config.$3, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.access_time_rounded, size: 11, color: AppColors.textMuted),
                                      const SizedBox(width: 3),
                                      Text(
                                        ts != null ? _relativeTime(ts) : '—',
                                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns (emoji, label, color) for each activity type.
  (String, String, Color) _activityConfig(String type) {
    switch (type) {
      case 'login':        return ('🔑', 'LOGIN',        const Color(0xFF3B82F6));
      case 'signup':       return ('🆕', 'SIGNUP',       const Color(0xFF8B5CF6));
      case 'logout':       return ('👋', 'LOGOUT',       const Color(0xFF6B7280));
      case 'loanRequest':  return ('💰', 'LOAN REQ',     const Color(0xFFF59E0B));
      case 'loanUpdate':   return ('✏️', 'LOAN UPD',    const Color(0xFFEA580C));
      case 'lenderJoin':   return ('🏦', 'LENDER',       const Color(0xFF10B981));
      case 'kycSubmit':    return ('📋', 'KYC SUBMIT',   const Color(0xFF0EA5E9));
      case 'kycApprove':   return ('✅', 'KYC APPROVED', const Color(0xFF10B981));
      case 'kycReject':    return ('❌', 'KYC REJECTED', const Color(0xFFEF4444));
      case 'collateral':   return ('📎', 'COLLATERAL',   const Color(0xFF8B5CF6));
      case 'offer':        return ('🤝', 'OFFER',        const Color(0xFF06B6D4));
      case 'match':        return ('💫', 'MATCH',        const Color(0xFFF59E0B));
      case 'adminAction':  return ('⚙️', 'ADMIN',        const Color(0xFF6366F1));
      case 'maintenance':  return ('🔧', 'MAINT',        const Color(0xFFEA580C));
      case 'announcement': return ('📢', 'ANNOUNCE',     const Color(0xFF8B5CF6));
      case 'profileUpdate':return ('👤', 'PROFILE',      const Color(0xFF0EA5E9));
      case 'roleChange':   return ('🔄', 'ROLE',         const Color(0xFF10B981));
      case 'subscription': return ('⭐', 'SUBSCR',       const Color(0xFFF59E0B));
      case 'chat':         return ('💬', 'CHAT',         const Color(0xFF3B82F6));
      default:             return ('📌', 'EVENT',        const Color(0xFF6B7280));
    }
  }

  /// Human-friendly relative time: "just now", "5m ago", "2h ago", etc.
  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60)  return 'just now';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)    return '${diff.inHours}h ago';
    if (diff.inDays < 7)      return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }


// ─────────────────────────────────────────────
// Shared Section Label
// ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.tag.copyWith(
          color: AppColors.textMuted,
          letterSpacing: 1.8,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 28, color: AppColors.border);
  }
}

// ─────────────────────────────────────────────
// Stats Strip Pill
// ─────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatPill(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTextStyles.h3
                .copyWith(color: color, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// 1. Pending Actions Section (fully interactive)
// ─────────────────────────────────────────────
class _PendingActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.colUsers)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const SizedBox(
                height: 60,
                child:
                    Center(child: CircularProgressIndicator(strokeWidth: 2)));
          }

          final docs = snap.data!.docs;

          final pendingKycDocs = docs
              .where((d) => (d.data() as Map)['kycStatus'] == 'pending')
              .toList();
          final blockedDocs = docs
              .where((d) => (d.data() as Map)['isBlocked'] == true)
              .toList();
          final unverifiedDocs = docs
              .where((d) =>
                  (d.data() as Map)['isVerified'] == false &&
                  (d.data() as Map)['kycStatus'] != 'pending')
              .toList();

          if (pendingKycDocs.isEmpty &&
              blockedDocs.isEmpty &&
              unverifiedDocs.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.emerald.withOpacity(0.15), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        color: AppColors.emerald, size: 18),
                    const SizedBox(width: 10),
                    Text('All clear — no pending actions',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.emerald)),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              if (pendingKycDocs.isNotEmpty)
                _PendingTile(
                  icon: Icons.badge_outlined,
                  label: 'KYC Reviews Pending',
                  count: pendingKycDocs.length,
                  color: AppColors.warning,
                  onTap: () => _showPendingSheet(
                    context,
                    title: 'KYC Pending',
                    docs: pendingKycDocs,
                    type: _PendingType.kyc,
                  ),
                ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05),
              if (blockedDocs.isNotEmpty)
                _PendingTile(
                  icon: Icons.block_rounded,
                  label: 'Blocked Accounts',
                  count: blockedDocs.length,
                  color: AppColors.error,
                  onTap: () => _showPendingSheet(
                    context,
                    title: 'Blocked Accounts',
                    docs: blockedDocs,
                    type: _PendingType.blocked,
                  ),
                ).animate().fadeIn(duration: 350.ms).slideX(begin: 0.05),
              if (unverifiedDocs.isNotEmpty)
                _PendingTile(
                  icon: Icons.person_outline_rounded,
                  label: 'Unverified Users',
                  count: unverifiedDocs.length,
                  color: AppColors.info,
                  onTap: () => _showPendingSheet(
                    context,
                    title: 'Unverified Users',
                    docs: unverifiedDocs,
                    type: _PendingType.unverified,
                  ),
                ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05),
            ],
          );
        },
      ),
    );
  }

  void _showPendingSheet(
    BuildContext context, {
    required String title,
    required List<QueryDocumentSnapshot> docs,
    required _PendingType type,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PendingUsersSheet(
          title: title, docs: docs, type: type),
    );
  }
}

// ─── Sheet showing users for a pending category ───
enum _PendingType { kyc, blocked, unverified }

class _PendingUsersSheet extends StatelessWidget {
  final String title;
  final List<QueryDocumentSnapshot> docs;
  final _PendingType type;

  const _PendingUsersSheet(
      {required this.title, required this.docs, required this.type});

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(title,
                    style: AppTextStyles.h3
                        .copyWith(color: AppColors.textPrimary)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${docs.length}',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.border, height: 1),
          // User list
          Flexible(
            child: ListView.separated(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                      .copyWith(bottom: 32),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                final uid = docs[i].id;
                return _PendingUserRow(
                    uid: uid, data: data, type: type);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Single user row with inline action buttons ───
class _PendingUserRow extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> data;
  final _PendingType type;

  const _PendingUserRow(
      {required this.uid, required this.data, required this.type});

  @override
  State<_PendingUserRow> createState() => _PendingUserRowState();
}

class _PendingUserRowState extends State<_PendingUserRow> {
  bool _loading = false;

  Future<void> _act(Map<String, dynamic> updates,
      {String? successMsg}) async {
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.colUsers)
          .doc(widget.uid)
          .update(updates);
      if (mounted && successMsg != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(successMsg),
          backgroundColor: AppColors.emerald,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navigateToKycReview(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AdminKycReviewScreen(
        uid: widget.uid,
        userData: widget.data,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.data['name'] ?? 'Unknown';
    final email = widget.data['email'] ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final isKyc = widget.type == _PendingType.kyc;

    return GestureDetector(
      onTap: isKyc ? () => _navigateToKycReview(context) : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info row
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: Center(
                    child: Text(initial,
                        style: AppTextStyles.labelMedium
                            .copyWith(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(email,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (_loading)
                  const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                else if (isKyc)
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: AppColors.textMuted),
              ],
            ),
            const SizedBox(height: 12),
            // Action buttons (differ by type; KYC goes to detail screen)
            if (!_loading && !isKyc) ..._buildActions(),
            // For KYC: show a subtle hint
            if (isKyc)
              Text(
                'Tap to review documents',
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted, fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions() {
    switch (widget.type) {
      case _PendingType.kyc:
        return [
          Row(children: [
            Expanded(
              child: _ActionBtn(
                label: 'Approve KYC',
                color: AppColors.emerald,
                onTap: () => _act({
                  'kycStatus': 'verified',
                  'isVerified': true,
                }, successMsg: 'KYC approved for ${widget.data['name']}'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionBtn(
                label: 'Reject KYC',
                color: AppColors.error,
                outlined: true,
                onTap: () => _act({
                  'kycStatus': 'rejected',
                  'isVerified': false,
                }, successMsg: 'KYC rejected for ${widget.data['name']}'),
              ),
            ),
          ]),
        ];
      case _PendingType.blocked:
        return [
          _ActionBtn(
            label: 'Unblock User',
            color: AppColors.emerald,
            onTap: () => _act({
              'isBlocked': false,
            }, successMsg: '${widget.data['name']} has been unblocked'),
          ),
        ];
      case _PendingType.unverified:
        return [
          Row(children: [
            Expanded(
              child: _ActionBtn(
                label: 'Verify',
                color: AppColors.info,
                onTap: () => _act({
                  'kycStatus': 'verified',
                  'isVerified': true,
                }, successMsg: '${widget.data['name']} verified'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionBtn(
                label: 'Block',
                color: AppColors.error,
                outlined: true,
                onTap: () => _act({
                  'isBlocked': true,
                }, successMsg: '${widget.data['name']} blocked'),
              ),
            ),
          ]),
        ];
    }
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: outlined ? color.withOpacity(0.5) : color.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _PendingTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.textPrimary)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$count',
                  style: AppTextStyles.labelSmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 2. Platform Health Chart (7-day signups bar)
// ─────────────────────────────────────────────
class _PlatformHealthChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AdminPlatformHealthChart();
  }
}

// ─────────────────────────────────────────────
// 3. Recent Activity Feed
// ─────────────────────────────────────────────
class _RecentActivityFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.colUsers)
            .orderBy('createdAt', descending: true)
            .limit(5)
            .snapshots(),
        builder: (context, userSnap) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(AppConstants.colRequests)
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, reqSnap) {
              // Merge and sort both streams
              final List<_ActivityItem> items = [];

              if (userSnap.hasData) {
                for (var doc in userSnap.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final ts = data['createdAt'];
                  DateTime? time;
                  if (ts is Timestamp) time = ts.toDate();
                  items.add(_ActivityItem(
                    icon: Icons.person_add_outlined,
                    title: '${data['name'] ?? 'Someone'} joined',
                    subtitle: data['role'] ?? 'user',
                    time: time,
                    color: AppColors.info,
                  ));
                }
              }

              if (reqSnap.hasData) {
                for (var doc in reqSnap.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final ts = data['createdAt'];
                  DateTime? time;
                  if (ts is Timestamp) time = ts.toDate();
                  final amount = (data['loanAmount'] ?? 0).toDouble();
                  items.add(_ActivityItem(
                    icon: Icons.receipt_long_outlined,
                    title: 'Loan request posted',
                    subtitle: AppFormatters.formatINRCompact(amount),
                    time: time,
                    color: AppColors.emerald,
                  ));
                }
              }

              // Sort newest first
              items.sort((a, b) {
                if (a.time == null && b.time == null) return 0;
                if (a.time == null) return 1;
                if (b.time == null) return -1;
                return b.time!.compareTo(a.time!);
              });

              final display = items.take(6).toList();

              if (display.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('No recent activity',
                      style: AppTextStyles.caption),
                );
              }

              return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                child: Column(
                  children: List.generate(display.length, (i) {
                    final item = display[i];
                    final isLast = i == display.length - 1;
                    return _ActivityTile(
                        item: item, isLast: isLast, index: i);
                  }),
                ),
              ).animate().fadeIn(duration: 500.ms);
            },
          );
        },
      ),
    );
  }
}

class _ActivityItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final DateTime? time;
  final Color color;
  _ActivityItem(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.time,
      required this.color});
}

class _ActivityTile extends StatelessWidget {
  final _ActivityItem item;
  final bool isLast;
  final int index;
  const _ActivityTile(
      {required this.item, required this.isLast, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.textPrimary, fontSize: 12)),
                const SizedBox(height: 1),
                Text(item.subtitle,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          Text(
            item.time != null
                ? AppFormatters.formatRelative(item.time!)
                : '—',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 60 * index));
  }
}

// ─────────────────────────────────────────────
// 4. Top Lenders / Top Borrowers
// ─────────────────────────────────────────────
class _TopUsersSection extends StatefulWidget {
  @override
  State<_TopUsersSection> createState() => _TopUsersSectionState();
}

class _TopUsersSectionState extends State<_TopUsersSection>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle tabs
          Container(
            height: 36,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tab,
              labelPadding: EdgeInsets.zero,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ],
              ),
              dividerColor: Colors.transparent,
              labelStyle: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w700),
              unselectedLabelStyle: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textMuted),
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textMuted,
              tabs: const [
                Tab(text: 'Top Lenders'),
                Tab(text: 'Top Borrowers'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Tab content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _tab.index == 0
                ? _TopRoleList(role: 'lender', key: const ValueKey('lenders'))
                : _TopRoleList(
                    role: 'borrower', key: const ValueKey('borrowers')),
          ),
        ],
      ),
    );
  }
}

class _TopRoleList extends StatelessWidget {
  final String role;
  const _TopRoleList({required this.role, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.colUsers)
          .where('role', isEqualTo: role)
          .limit(5)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox(
              height: 60,
              child:
                  Center(child: CircularProgressIndicator(strokeWidth: 2)));
        }

        final docs = snap.data!.docs;

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text('No ${role}s yet',
                  style: AppTextStyles.caption),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 24,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            children: List.generate(docs.length, (i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Unknown';
              final initial =
                  name.isNotEmpty ? name[0].toUpperCase() : '?';
              final kycStatus = data['kycStatus'] ?? '';
              final isVerified = data['isVerified'] == true;
              final isLast = i == docs.length - 1;

              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(
                              color: AppColors.border, width: 1)),
                ),
                child: Row(
                  children: [
                    // Rank
                    SizedBox(
                      width: 20,
                      child: Text(
                        '${i + 1}',
                        style: AppTextStyles.caption.copyWith(
                            color: i == 0
                                ? AppColors.emerald
                                : AppColors.textMuted,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Avatar
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(initial,
                            style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 1),
                          Text(
                            data['email'] ?? '',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status badge
                    if (isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Verified',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.emerald,
                                fontWeight: FontWeight.w700,
                                fontSize: 9)),
                      )
                    else if (kycStatus == 'pending')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Pending',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w700,
                                fontSize: 9)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.textMuted.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('New',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w700,
                                fontSize: 9)),
                      ),
                  ],
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 50 * i));
            }),
          ),
        );
      },
    );
  }
}




