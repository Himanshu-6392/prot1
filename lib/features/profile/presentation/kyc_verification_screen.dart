import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dotted_border/dotted_border.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../models/user_model.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/glass_widgets.dart';

class KycVerificationScreen extends ConsumerStatefulWidget {
  const KycVerificationScreen({super.key});

  @override
  ConsumerState<KycVerificationScreen> createState() =>
      _KycVerificationScreenState();
}

class _KycVerificationScreenState extends ConsumerState<KycVerificationScreen> {
  final ImagePicker _picker = ImagePicker();

  File? _aadhaarFront;
  File? _aadhaarBack;
  File? _panCard;

  bool _isUploading = false;
  double _uploadProgress = 0;

  Future<void> _pickImage(String type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() {
          if (type == 'aadhaar_front') _aadhaarFront = File(image.path);
          if (type == 'aadhaar_back') _aadhaarBack = File(image.path);
          if (type == 'pan') _panCard = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Future<void> _submitKyc() async {
    if (_aadhaarFront == null || _aadhaarBack == null || _panCard == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Please upload all required documents.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.1;
    });

    try {
      final storageRef =
          FirebaseStorage.instance.ref().child('kyc_documents/$uid');

      // Upload Aadhaar Front
      final aadhaarFrontRef = storageRef.child('aadhaar_front.jpg');
      await aadhaarFrontRef.putFile(_aadhaarFront!);
      setState(() => _uploadProgress = 0.4);
      final aadhaarFrontUrl = await aadhaarFrontRef.getDownloadURL();

      // Upload Aadhaar Back
      final aadhaarBackRef = storageRef.child('aadhaar_back.jpg');
      await aadhaarBackRef.putFile(_aadhaarBack!);
      setState(() => _uploadProgress = 0.7);
      final aadhaarBackUrl = await aadhaarBackRef.getDownloadURL();

      // Upload PAN
      final panRef = storageRef.child('pan_card.jpg');
      await panRef.putFile(_panCard!);
      setState(() => _uploadProgress = 0.9);
      final panUrl = await panRef.getDownloadURL();

      // Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'kycStatus': KycStatus.submitted.name,
        'isVerified': false,
        'kycDocuments': {
          'aadhaarFront': aadhaarFrontUrl,
          'aadhaarBack': aadhaarBackUrl,
          'panCard': panUrl,
          'submittedAt': Timestamp.now(),
        }
      });

      setState(() => _uploadProgress = 1.0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('KYC Submitted! Pending Admin Approval ⏳'),
          backgroundColor: AppColors.info,
          behavior: SnackBarBehavior.floating,
        ));
        context.pop();
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Widget _buildUploadBox({
    required String title,
    required File? file,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isUploading ? null : onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          NeumorphicContainer(
            padding: EdgeInsets.zero,
            child: DottedBorder(
              color: file != null
                  ? AppColors.emerald
                  : AppColors.gold.withValues(alpha: 0.3),
              strokeWidth: 2,
              dashPattern: const [8, 4],
              borderType: BorderType.RRect,
              radius: const Radius.circular(16),
              child: Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: file != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(file,
                                fit: BoxFit.cover, width: double.infinity),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.emerald,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check,
                                  color: Colors.white, size: 16),
                            ).animate().scale(),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.cloud_upload_outlined,
                                color: AppColors.gold, size: 32),
                          ),
                          const SizedBox(height: 12),
                          Text('Tap to browse',
                              style: AppTextStyles.button
                                  .copyWith(color: AppColors.gold)),
                          const SizedBox(height: 4),
                          Text('Supports JPG, PNG (Max 5MB)',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textMuted)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Identity Verification', style: AppTextStyles.h3),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold.withValues(alpha: 0.05),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .scale(
                          duration: 2.seconds,
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.2, 1.2))
                      .fade(end: 0),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.shield_outlined,
                        size: 40, color: Colors.white),
                  ),
                ],
              ),
            ).animate().scale(
                delay: 50.ms, duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text('Secure KYC',
                    style: AppTextStyles.h2, textAlign: TextAlign.center)
                .animate()
                .fadeIn(delay: 100.ms)
                .slideY(begin: 0.1),
            const SizedBox(height: 8),
            Text('Your documents are encrypted and securely stored. We need them to verify your identity before you can lend or borrow.',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textMuted, height: 1.5),
                    textAlign: TextAlign.center)
                .animate()
                .fadeIn(delay: 150.ms)
                .slideY(begin: 0.1),
            const SizedBox(height: 40),
            _buildUploadBox(
              title: 'Aadhaar Card (Front)',
              file: _aadhaarFront,
              onTap: () => _pickImage('aadhaar_front'),
            ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05),
            const SizedBox(height: 24),
            _buildUploadBox(
              title: 'Aadhaar Card (Back)',
              file: _aadhaarBack,
              onTap: () => _pickImage('aadhaar_back'),
            ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.05),
            const SizedBox(height: 24),
            _buildUploadBox(
              title: 'PAN Card',
              file: _panCard,
              onTap: () => _pickImage('pan'),
            ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.05),
            const SizedBox(height: 48),
            if (_isUploading) ...[
              Text('Encrypting and Uploading...',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.gold, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: AppColors.surfaceHigh,
                  color: AppColors.gold,
                  minHeight: 8,
                ),
              ),
            ] else
              AppButton(
                label: 'Submit Documents',
                icon: const Icon(Icons.lock_outline, size: 18),
                onPressed: (_aadhaarFront == null ||
                        _aadhaarBack == null ||
                        _panCard == null)
                    ? null
                    : _submitKyc,
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
