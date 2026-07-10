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
        'kycStatus': 'verified', // Auto-verify for testing
        'isVerified': true,
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
          content: const Text('KYC Verified successfully! 🎉'),
          backgroundColor: AppColors.success,
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
          const SizedBox(height: 8),
          DottedBorder(
            color: AppColors.gold,
            strokeWidth: 2,
            dashPattern: const [8, 4],
            borderType: BorderType.RRect,
            radius: const Radius.circular(16),
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
              ),
              child: file != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(file,
                          fit: BoxFit.cover, width: double.infinity),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload_rounded,
                            color: AppColors.gold, size: 32),
                        const SizedBox(height: 8),
                        Text('Tap to upload',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textMuted)),
                      ],
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
        title: Text('KYC Verification', style: AppTextStyles.h3),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.1),
              ),
              child: Icon(Icons.verified_user_rounded,
                  size: 48, color: AppColors.gold),
            ).animate().scale(
                delay: 50.ms, duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 16),
            Text('Upload Documents',
                    style: AppTextStyles.h2, textAlign: TextAlign.center)
                .animate()
                .fadeIn(delay: 100.ms),
            const SizedBox(height: 8),
            Text('Please upload clear images of your Aadhaar and PAN card to verify your identity.',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textMuted),
                    textAlign: TextAlign.center)
                .animate()
                .fadeIn(delay: 150.ms),
            const SizedBox(height: 32),
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
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: AppColors.surfaceAlt,
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 16),
              Text('Uploading documents... ${(_uploadProgress * 100).toInt()}%',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(color: AppColors.gold)),
              const SizedBox(height: 32),
            ],
            GestureDetector(
              onTap: _isUploading ? null : _submitKyc,
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
                child: Text('Submit for Verification',
                    style: AppTextStyles.h4.copyWith(color: Colors.white)),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }
}
