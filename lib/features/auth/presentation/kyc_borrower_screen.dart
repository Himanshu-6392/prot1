import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/constants.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../models/user_model.dart';

class KycBorrowerScreen extends ConsumerStatefulWidget {
  const KycBorrowerScreen({super.key});
  @override
  ConsumerState<KycBorrowerScreen> createState() => _KycBorrowerScreenState();
}

class _KycBorrowerScreenState extends ConsumerState<KycBorrowerScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _aadhaarCtr = TextEditingController();
  final _panCtr     = TextEditingController();
  final _addressCtr = TextEditingController();
  File? _selfieFile;
  File? _aadhaarFile;
  bool _loading     = false;
  int _step         = 0;

  Future<void> _pickSelfie() async {
    final img = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 70);
    if (img != null) setState(() => _selfieFile = File(img.path));
  }

  Future<void> _pickAadhaar() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null) setState(() => _aadhaarFile = File(img.path));
  }

  Future<String?> _uploadFile(File file, String path) async {
    final ref = FirebaseStorage.instance.ref(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selfieFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a selfie')));
      return;
    }
    setState(() => _loading = true);

    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) { setState(() => _loading = false); return; }

    String? selfieUrl;
    if (_selfieFile != null) {
      selfieUrl = await _uploadFile(_selfieFile!, 'kyc/${user.uid}/selfie.jpg');
    }

    await ref.read(firestoreProvider)
        .collection(AppConstants.colUsers)
        .doc(user.uid)
        .update({
          'kycStatus':    KycStatus.submitted.name,
          'kyc':          {
            'aadhaar':    _aadhaarCtr.text.trim(),
            'pan':        _panCtr.text.toUpperCase().trim(),
            'address':    _addressCtr.text.trim(),
            'selfieUrl':  selfieUrl,
            'submittedAt': FieldValue.serverTimestamp(),
          },
          'updatedAt':    FieldValue.serverTimestamp(),
        });

    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildStepIndicator(),
                        SizedBox(height: 28),
                        if (_step == 0) _buildStep0(),
                        if (_step == 1) _buildStep1(),
                        if (_step == 2) _buildStep2(),
                        SizedBox(height: 32),
                        _buildBottomButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppIconButton(icon: Icons.arrow_back_rounded, onPressed: () => context.pop(), bgColor: AppColors.surfaceAlt),
        SizedBox(height: 16),
        Text('Borrower KYC', style: AppTextStyles.h1),
        SizedBox(height: 4),
        Text('Complete verification to unlock full access', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Identity', 'Documents', 'Selfie'];
    return Row(
      children: steps.asMap().entries.map((e) {
        final i      = e.key;
        final active = i == _step;
        final done   = i < _step;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                decoration: BoxDecoration(
                  gradient: done || active ? AppColors.goldGradient : null,
                  color:    done || active ? null : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 6),
              Text(e.value, style: AppTextStyles.caption.copyWith(
                color: active ? AppColors.gold : done ? AppColors.emerald : AppColors.textMuted,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              )),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStep0() {
    return Column(children: [
      TextFormField(
        controller: _aadhaarCtr, keyboardType: TextInputType.number,
        style: AppTextStyles.bodyLarge,
        decoration: InputDecoration(labelText: 'Aadhaar Number', prefixIcon: Icon(Icons.badge_rounded)),
        validator: AppValidators.aadhaar,
      ).animate().fadeIn().slideY(begin: 0.15, end: 0),
      SizedBox(height: 16),
      TextFormField(
        controller: _panCtr, textCapitalization: TextCapitalization.characters,
        style: AppTextStyles.bodyLarge,
        decoration: InputDecoration(labelText: 'PAN Number', prefixIcon: Icon(Icons.credit_card_rounded)),
        validator: AppValidators.pan,
      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.15, end: 0),
      SizedBox(height: 16),
      TextFormField(
        controller: _addressCtr, maxLines: 3,
        style: AppTextStyles.bodyLarge,
        decoration: InputDecoration(labelText: 'Residential Address', prefixIcon: Icon(Icons.home_rounded)),
        validator: (v) => AppValidators.required(v, 'Address'),
      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15, end: 0),
    ]);
  }

  Widget _buildStep1() {
    return Column(children: [
      _DocUploadCard(
        title:    'Aadhaar Card',
        subtitle: 'Front side of your Aadhaar card',
        icon:     Icons.badge_rounded,
        file:     _aadhaarFile,
        onPick:   _pickAadhaar,
      ).animate().fadeIn().slideY(begin: 0.15, end: 0),
    ]);
  }

  Widget _buildStep2() {
    return Column(children: [
      Container(
        height: 280,
        decoration: BoxDecoration(
          color:        AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: AppColors.border),
        ),
        child: _selfieFile != null
            ? Stack(fit: StackFit.expand, children: [
                ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(_selfieFile!, fit: BoxFit.cover)),
                Positioned(
                  bottom: 12, right: 12,
                  child: IconButton.filled(
                    onPressed: _pickSelfie,
                    icon: Icon(Icons.refresh_rounded),
                    style: IconButton.styleFrom(backgroundColor: AppColors.gold),
                  ),
                ),
              ])
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.camera_alt_rounded, color: AppColors.textMuted, size: 48),
                SizedBox(height: 12),
                Text('Take a clear selfie', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
                SizedBox(height: 4),
                Text('Ensure good lighting and look directly at the camera',
                    style: AppTextStyles.caption, textAlign: TextAlign.center),
                SizedBox(height: 20),
                AppButton(label: 'Open Camera', onPressed: _pickSelfie, width: 160,
                    icon: Icon(Icons.camera_alt_rounded, size: 18)),
              ]),
      ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
    ]);
  }

  Widget _buildBottomButtons() {
    return Column(children: [
      if (_step < 2)
        AppButton(
          label:     'Next Step',
          onPressed: () => setState(() => _step++),
          icon:      Icon(Icons.arrow_forward_rounded, size: 18),
        )
      else
        AppButton(
          label:     'Submit KYC',
          onPressed: _submit,
          isLoading: _loading,
          icon:      Icon(Icons.verified_rounded, size: 18),
        ),
      if (_step > 0) ...[
        SizedBox(height: 12),
        AppButton(
          label:      'Back',
          onPressed:  () => setState(() => _step--),
          isOutlined: true,
        ),
      ],
    ]);
  }
}

class _DocUploadCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final File? file;
  final VoidCallback onPick;

  const _DocUploadCard({
    required this.title, required this.subtitle, required this.icon,
    required this.file, required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:        file != null ? AppColors.emerald.withOpacity(0.08) : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(
            color: file != null ? AppColors.emerald.withOpacity(0.4) : AppColors.border,
            width: file != null ? 1.5 : 1,
          ),
        ),
        child: file != null
            ? Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(file!, width: 72, height: 52, fit: BoxFit.cover),
                ),
                SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: AppTextStyles.labelLarge.copyWith(color: AppColors.emerald)),
                  Text('Tap to change', style: AppTextStyles.caption),
                ])),
                Icon(Icons.check_circle_rounded, color: AppColors.emerald, size: 24),
              ])
            : Row(children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: AppColors.textMuted, size: 24),
                ),
                SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: AppTextStyles.labelLarge),
                  SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption),
                ])),
                Icon(Icons.upload_rounded, color: AppColors.gold, size: 22),
              ]),
      ),
    );
  }
}
