import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeroHeader(user),
          SliverToBoxAdapter(
            child: Column(
              children: [
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
    );
  }

  // ─── Hero Header with tap-to-upload avatar ────

  Widget _buildHeroHeader(UserModel? user) {
    final initials = user?.name.isNotEmpty == true
        ? user!.name
            .trim()
            .split(' ')
            .map((w) => w[0])
            .take(2)
            .join()
            .toUpperCase()
        : 'U';

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 260,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Gradient banner
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient, // Deep Indigo → Indigo
                ),
                child: Stack(
                  children: [
                    Positioned(
                        top: -30,
                        right: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.08)),
                        )),
                    Positioned(
                        bottom: -20,
                        left: -20,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.06)),
                        )),
                    Positioned(
                      top: 48,
                      left: 16,
                      child: GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                    ),
                    Positioned(
                      top: 48,
                      right: 16,
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.settings_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ).animate().fadeIn(delay: 150.ms),
                    ),
                  ],
                ),
              ),
            ),

            // Avatar — inside SizedBox(260) bounds so taps register correctly
            Positioned(
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _isUploading ? null : _showPhotoOptions,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, __) => Container(
                        width: 114 + _pulseController.value * 4,
                        height: 114 + _pulseController.value * 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              Color(0xFF6366F1),
                              Color(0xFF8B5CF6),
                              Color(0xFF00C78B),
                              Color(0xFF6366F1)
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.bg,
                            ),
                            padding: const EdgeInsets.all(3),
                            child: ClipOval(
                              child: _buildAvatarContent(user, initials),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_isUploading)
                      SizedBox(
                        width: 118,
                        height: 118,
                        child: CircularProgressIndicator(
                          value: _uploadProgress > 0 ? _uploadProgress : null,
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.bg, width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.gold.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Icon(
                          _isUploading
                              ? Icons.hourglass_top_rounded
                              : Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarContent(UserModel? user, String initials) {
    if (_isUploading) {
      return Container(
        color: AppColors.gold.withOpacity(0.2),
        child: Center(
          child: Text(
            '${(_uploadProgress * 100).toInt()}%',
            style: AppTextStyles.h3.copyWith(color: AppColors.gold),
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
          child: Center(
              child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.gold,
          )),
        ),
        errorWidget: (_, __, ___) => _initialsWidget(initials),
      );
    }

    return _initialsWidget(initials);
  }

  Widget _initialsWidget(String initials) {
    return Container(
      decoration: BoxDecoration(gradient: AppColors.goldGradient),
      child: Center(
        child: Text(initials,
            style:
                AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 32)),
      ),
    );
  }
}

// ─── Photo Picker Bottom Sheet ───────────────────────────────────────────────

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Text('Update Profile Photo', style: AppTextStyles.h3),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Choose a clear photo of yourself',
              style: AppTextStyles.bodySmall,
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _PickerOption(
                    icon: Icons.photo_camera_rounded,
                    label: 'Camera',
                    subtitle: 'Take a photo',
                    color: AppColors.gold,
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    subtitle: 'Pick from gallery',
                    color: AppColors.emerald,
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: AppColors.border),
                ),
              ),
              child: Text('Cancel',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  )),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ).animate().slideY(
        begin: 0.3, end: 0, duration: 300.ms, curve: Curves.easeOutCubic);
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _PickerOption(
      {required this.icon,
      required this.label,
      required this.subtitle,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(label, style: AppTextStyles.h4.copyWith(color: color)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: AppTextStyles.caption, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Stats Row ───────────────────────────────────────────────────────────────

class _StatsRow extends StatefulWidget {
  final UserModel? user;
  const _StatsRow({this.user});

  @override
  State<_StatsRow> createState() => _StatsRowState();
}

class _StatsRowState extends State<_StatsRow> {
  bool _isFetchingLocation = false;

  Future<void> _fetchLocation() async {
    if (widget.user == null) return;

    setState(() {
      _isFetchingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Location permissions are permanently denied, we cannot request permissions.');
      }

      final position = await Geolocator.getCurrentPosition();
      String city = 'Unknown City';

      if (kIsWeb) {
        // Fallback for Web since native geocoding plugin doesn't work on browsers
        try {
          final dio = Dio();
          final response = await dio.get(
              'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${position.latitude}&longitude=${position.longitude}&localityLanguage=en');
          if (response.statusCode == 200) {
            city = response.data['city'] ??
                response.data['locality'] ??
                response.data['principalSubdivision'] ??
                'Unknown City';
          }
        } catch (_) {}
      } else {
        // Native Android/iOS Geocoding
        final placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          city =
              place.locality ?? place.subAdministrativeArea ?? 'Unknown City';
        }
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user!.uid)
          .update({
        'city': city,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Location updated to $city'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
        });
      }
    }
  }

  Future<void> _showEditRoleDialog(
      BuildContext context, String uid, UserRole? currentRole) async {
    UserRole selectedRole = currentRole ?? UserRole.borrower;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Change Role', style: AppTextStyles.h3),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<UserRole>(
                  title: Text('Borrower', style: AppTextStyles.bodyMedium),
                  activeColor: AppColors.gold,
                  value: UserRole.borrower,
                  groupValue: selectedRole,
                  onChanged: (val) => setState(() => selectedRole = val!),
                ),
                RadioListTile<UserRole>(
                  title: Text('Lender', style: AppTextStyles.bodyMedium),
                  activeColor: AppColors.emerald,
                  value: UserRole.lender,
                  groupValue: selectedRole,
                  onChanged: (val) => setState(() => selectedRole = val!),
                ),
                RadioListTile<UserRole>(
                  title: Text('Both', style: AppTextStyles.bodyMedium),
                  activeColor: AppColors.gold,
                  value: UserRole.both,
                  groupValue: selectedRole,
                  onChanged: (val) => setState(() => selectedRole = val!),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .update({
                    'role': selectedRole.name,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        (widget.user?.name != null && widget.user!.name.trim().isNotEmpty)
            ? widget.user!.name.trim()
            : 'User';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          GestureDetector(
            onTap: widget.user != null
                ? () => showGlobalEditProfileDialog(context, widget.user!)
                : null,
            child: Text(displayName,
                style: AppTextStyles.h1, textAlign: TextAlign.center),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: (widget.user != null && !_isFetchingLocation)
                    ? _fetchLocation
                    : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _isFetchingLocation
                          ? SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.gold))
                          : Icon(Icons.my_location_rounded,
                              size: 13, color: AppColors.gold),
                      const SizedBox(width: 4),
                      Text(widget.user?.city ?? 'India',
                          style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _RoleBadge(role: widget.user?.role),
              if (widget.user?.isPremium == true) ...[
                const SizedBox(width: 8),
                const _PremiumBadge(),
              ],
            ],
          ).animate().fadeIn(delay: 250.ms),
          const SizedBox(height: 24),
          Row(
            children: [
              _MiniStat(
                value: _roleLabel(widget.user?.role),
                label: 'Role',
                icon: Icons.badge_rounded,
                color: AppColors.gold,
                onTap: widget.user != null
                    ? () => _showEditRoleDialog(
                        context, widget.user!.uid, widget.user!.role)
                    : null,
              ),
              const SizedBox(width: 12),
              _MiniStat(
                value: _kycLabel(widget.user?.kycStatus),
                label: 'KYC',
                icon: Icons.verified_user_rounded,
                color: _kycColor(widget.user?.kycStatus),
                onTap: () {},
              ),
              const SizedBox(width: 12),
              _MiniStat(
                value: widget.user?.isPremium == true ? 'Active' : 'Free',
                label: 'Plan',
                icon: Icons.workspace_premium_rounded,
                color: widget.user?.isPremium == true
                    ? AppColors.warning
                    : AppColors.textMuted,
                onTap: () => context.push('/plans'),
              ),
            ],
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  String _roleLabel(UserRole? role) {
    switch (role) {
      case UserRole.lender:
        return 'Lender';
      case UserRole.borrower:
        return 'Borrower';
      case UserRole.both:
        return 'Both';
      case UserRole.admin:
        return 'Admin';
      default:
        return 'User';
    }
  }

  String _kycLabel(KycStatus? status) {
    switch (status) {
      case KycStatus.verified:
        return 'Verified';
      case KycStatus.submitted:
        return 'Pending';
      case KycStatus.rejected:
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  Color _kycColor(KycStatus? status) {
    switch (status) {
      case KycStatus.verified:
        return AppColors.success;
      case KycStatus.submitted:
        return AppColors.warning;
      case KycStatus.rejected:
        return AppColors.error;
      default:
        return AppColors.textMuted;
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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 8),
              Text(value,
                  style: AppTextStyles.h4.copyWith(color: color, fontSize: 13)),
              Text(label, style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final UserRole? role;
  const _RoleBadge({this.role});

  @override
  Widget build(BuildContext context) {
    final bool isBoth = role == UserRole.both;
    final bool isLender = role == UserRole.lender;

    Gradient gradient;
    IconData icon;
    String text;

    if (isBoth) {
      gradient = LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF8A63F8)]);
      icon = Icons.sync_alt_rounded;
      text = 'Both';
    } else if (isLender) {
      gradient = AppColors.emeraldGradient;
      icon = Icons.savings_rounded;
      text = 'Lender';
    } else {
      gradient = AppColors.goldGradient;
      icon = Icons.person_rounded;
      text = 'Borrower';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: Colors.white),
        const SizedBox(width: 4),
        Text(text,
            style: AppTextStyles.labelSmall
                .copyWith(color: Colors.white, fontSize: 11)),
      ]),
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient:
            LinearGradient(colors: [Color(0xFFF5A623), Color(0xFFE8900A)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.star_rounded, size: 12, color: Colors.white),
        const SizedBox(width: 4),
        Text('Premium',
            style: AppTextStyles.labelSmall
                .copyWith(color: Colors.white, fontSize: 11)),
      ]),
    );
  }
}

// ─── KYC Status Card ─────────────────────────────────────────────────────────

class _KycStatusCard extends StatelessWidget {
  final UserModel? user;
  const _KycStatusCard({this.user});
  @override
  Widget build(BuildContext context) {
    final isVerified = user?.kycStatus == KycStatus.verified;
    final color = isVerified ? AppColors.success : AppColors.warning;
    final icon = isVerified ? Icons.verified_rounded : Icons.pending_rounded;
    final msg = isVerified
        ? 'Your identity has been verified successfully.'
        : 'Complete KYC to unlock full platform access.';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(isVerified ? 'KYC Verified' : 'KYC Pending',
                    style: AppTextStyles.h4.copyWith(color: color)),
                const SizedBox(height: 3),
                Text(msg, style: AppTextStyles.bodySmall),
              ])),
          if (!isVerified) Icon(Icons.chevron_right_rounded, color: color),
        ]),
      ).animate().fadeIn(delay: 350.ms).slideX(begin: 0.1, end: 0),
    );
  }
}

// ─── Menu Section ────────────────────────────────────────────────────────────

class _MenuSection extends ConsumerWidget {
  final UserModel? user;
  const _MenuSection({this.user});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = (user?.name != null && user!.name.trim().isNotEmpty)
        ? user!.name.trim()
        : 'User';
    final items = [
      _MenuItem(
        icon: Icons.person_rounded,
        label: 'Edit Profile',
        subtitle: 'Update your info',
        color: AppColors.gold,
        onTap: () {
          if (user != null) {
            showGlobalEditProfileDialog(context, user!);
          }
        },
      ),
      _MenuItem(
        icon: Icons.account_balance_rounded,
        label: 'My Bank Details',
        subtitle: 'Manage bank accounts',
        color: AppColors.info,
        onTap: () {
          if (user != null) {
            showBankDetailsDialog(context, user!);
          }
        },
      ),
      _MenuItem(
          icon: Icons.workspace_premium_rounded,
          label: 'Subscription Plan',
          subtitle:
              user?.isPremium == true ? 'Premium active' : 'Upgrade to premium',
          color: AppColors.warning,
          onTap: () => context.push('/plans')),
      _MenuItem(
          icon: Icons.notifications_rounded,
          label: 'Notifications',
          subtitle: 'Manage alerts',
          color: AppColors.emerald,
          onTap: () => context.go('/notifications')),
      _MenuItem(
          icon: Icons.security_rounded,
          label: 'Security & Privacy',
          subtitle: 'Change PIN & privacy settings',
          color: AppColors.goldLight,
          onTap: () async {
            final changed = await showChangePinFlow(context, ref);
            if (changed && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(children: [
                    Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('PIN updated successfully'),
                  ]),
                  backgroundColor: AppColors.emerald,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          }),
      _MenuItem(
          icon: Icons.help_outline_rounded,
          label: 'Help & Support',
          subtitle: 'FAQs and contact us',
          color: AppColors.textSecondary,
          onTap: () {}),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: AppColors.gold.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ],
        ),
        child: Column(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              items[i]
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 100 * i + 400))
                  .slideX(begin: 0.05, end: 0),
              if (i < items.length - 1)
                Padding(
                  padding: const EdgeInsets.only(left: 68, right: 20),
                  child: Divider(color: AppColors.border, height: 1),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _MenuItem(
      {required this.icon,
      required this.label,
      required this.subtitle,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      style: AppTextStyles.bodyLarge
                          .copyWith(fontWeight: FontWeight.w600)),
                  Text(subtitle, style: AppTextStyles.caption),
                ])),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20),
          ]),
        ),
      ),
    );
  }
}

// ─── Logout Button ────────────────────────────────────────────────────────────

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Explicitly lock sensitive data before logging out to ensure it's blurred on next login
            ref.read(sensitiveDataVisibleProvider.notifier).state = false;
            await FirebaseAuth.instance.signOut();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.error.withOpacity(0.2)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.logout_rounded,
                    color: AppColors.error, size: 18),
              ),
              const SizedBox(width: 12),
              Text('Log Out',
                  style: AppTextStyles.h4.copyWith(color: AppColors.error)),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded,
                  color: AppColors.error, size: 16),
            ]),
          ),
        ),
      ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0),
    );
  }
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
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 40,
                    offset: const Offset(0, 10))
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
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 40,
                    offset: const Offset(0, 10))
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
