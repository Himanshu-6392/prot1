import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/providers/firebase_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController nameCtr;
  late TextEditingController displayIdCtr;
  late TextEditingController cityCtr;
  late TextEditingController phoneCtr;
  String? selectedGender;
  bool isLoading = false;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider).valueOrNull;
    nameCtr =
        TextEditingController(text: user?.name == 'User' ? '' : user?.name);
    displayIdCtr = TextEditingController(text: user?.displayId);
    cityCtr = TextEditingController(
        text: user?.city == 'India' ? '' : (user?.city ?? ''));
    phoneCtr = TextEditingController(text: user?.phone);
    selectedGender = user?.gender;
  }

  @override
  void dispose() {
    nameCtr.dispose();
    displayIdCtr.dispose();
    cityCtr.dispose();
    phoneCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    final memberSince =
        user != null ? DateFormat.yMMMMd().format(user.createdAt) : 'Unknown';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Edit Profile', style: AppTextStyles.h3),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Member Since (Read Only)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt.withValues(alpha: 0.5),
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
              controller: TextEditingController(text: user?.email ?? ''),
              readOnly: true,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              decoration: InputDecoration(
                labelText: 'Email Address',
                labelStyle: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textMuted),
                prefixIcon:
                    Icon(Icons.email_outlined, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surfaceAlt.withValues(alpha: 0.5),
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
                prefixIcon:
                    Icon(Icons.person_outline_rounded, color: AppColors.gold),
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

            // User ID Field
            TextField(
              controller: displayIdCtr,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                labelText: 'User ID (Unique)',
                labelStyle: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textMuted),
                prefixIcon:
                    Icon(Icons.alternate_email_rounded, color: AppColors.info),
                filled: true,
                fillColor: AppColors.surfaceAlt,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ).animate().fadeIn(delay: 175.ms).slideX(begin: 0.05),
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
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
                prefixIcon:
                    Icon(Icons.location_on_outlined, color: AppColors.info),
                filled: true,
                fillColor: AppColors.surfaceAlt,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              textCapitalization: TextCapitalization.words,
            ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.05),

            if (errorMsg != null) ...[
              const SizedBox(height: 16),
              Text(errorMsg!,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.error),
                      textAlign: TextAlign.center)
                  .animate()
                  .fadeIn(),
            ],

            const SizedBox(height: 48),

            // Save Button
            GestureDetector(
              onTap: isLoading
                  ? null
                  : () async {
                      final newName = nameCtr.text.trim();
                      final newDisplayId = displayIdCtr.text.trim();
                      final newCity = cityCtr.text.trim();
                      final newPhone = phoneCtr.text.trim();
                      if (newName.isEmpty) return;

                      setState(() {
                        isLoading = true;
                        errorMsg = null;
                      });

                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid != null) {
                        try {
                          // Check if UserID is taken
                          if (newDisplayId.isNotEmpty &&
                              newDisplayId != user?.displayId) {
                            try {
                              final snap = await FirebaseFirestore.instance
                                  .collection('users')
                                  .where('displayId', isEqualTo: newDisplayId)
                                  .limit(1)
                                  .get();

                              if (snap.docs.isNotEmpty) {
                                setState(() {
                                  isLoading = false;
                                  errorMsg =
                                      'This UserID is already taken. Please choose another one.';
                                });
                                return;
                              }
                            } catch (e) {
                              // If rules prevent this query, just skip the validation and try to save
                              print('Validation check error: $e');
                            }
                          }

                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .set({
                            'name': newName,
                            'displayId':
                                newDisplayId.isEmpty ? null : newDisplayId,
                            'city': newCity.isEmpty ? 'India' : newCity,
                            'phone': newPhone,
                            if (selectedGender != null)
                              'gender': selectedGender,
                          }, SetOptions(merge: true));

                          if (context.mounted) {
                            context.pop();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: const Text('Profile updated! 🎉'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ));
                          }
                        } catch (e) {
                          print('Update error: $e');
                          setState(() {
                            isLoading = false;
                            errorMsg =
                                'Failed: ${e.toString().replaceAll('FirebaseException', '').trim()}';
                          });
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
                        color: AppColors.gold.withValues(alpha: 0.3),
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
                        style: AppTextStyles.h4.copyWith(color: Colors.white)),
              ),
            ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }
}
