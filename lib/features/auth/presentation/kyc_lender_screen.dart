import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/constants.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../models/user_model.dart';

class KycLenderScreen extends ConsumerStatefulWidget {
  const KycLenderScreen({super.key});
  @override
  ConsumerState<KycLenderScreen> createState() => _KycLenderScreenState();
}

class _KycLenderScreenState extends ConsumerState<KycLenderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aadhaarCtr = TextEditingController();
  final _panCtr = TextEditingController();
  final _gstCtr = TextEditingController();
  final _bankNameCtr = TextEditingController();
  final _accCtr = TextEditingController();
  final _ifscCtr = TextEditingController();
  bool _loading = false;
  int _step = 0;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    await ref
        .read(firestoreProvider)
        .collection(AppConstants.colUsers)
        .doc(user.uid)
        .update({
      'kycStatus': KycStatus.submitted.name,
      'kyc': {
        'aadhaar': _aadhaarCtr.text.trim(),
        'pan': _panCtr.text.toUpperCase().trim(),
        'gst': _gstCtr.text.toUpperCase().trim(),
        'bankName': _bankNameCtr.text.trim(),
        'account': _accCtr.text.trim(),
        'ifsc': _ifscCtr.text.toUpperCase().trim(),
        'submittedAt': FieldValue.serverTimestamp(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) context.go('/lender');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppIconButton(
                          icon: Icons.arrow_back_rounded,
                          onPressed: () => context.pop(),
                          bgColor: AppColors.surfaceAlt),
                      SizedBox(height: 16),
                      Text('Lender KYC', style: AppTextStyles.h1),
                      SizedBox(height: 4),
                      Text('Verified lenders get priority in search results',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondary)),
                    ]),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Step indicator
                        _StepIndicator(
                            step: _step,
                            steps: const ['Identity', 'Banking', 'Business']),
                        SizedBox(height: 28),

                        if (_step == 0) ...[
                          TextFormField(
                            controller: _aadhaarCtr,
                            keyboardType: TextInputType.number,
                            style: AppTextStyles.bodyLarge,
                            decoration: InputDecoration(
                                labelText: 'Aadhaar Number',
                                prefixIcon: Icon(Icons.badge_rounded)),
                            validator: AppValidators.aadhaar,
                          ).animate().fadeIn().slideY(begin: 0.15, end: 0),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _panCtr,
                            textCapitalization: TextCapitalization.characters,
                            style: AppTextStyles.bodyLarge,
                            decoration: InputDecoration(
                                labelText: 'PAN Number',
                                prefixIcon: Icon(Icons.credit_card_rounded)),
                            validator: AppValidators.pan,
                          )
                              .animate()
                              .fadeIn(delay: 100.ms)
                              .slideY(begin: 0.15, end: 0),
                        ],

                        if (_step == 1) ...[
                          TextFormField(
                            controller: _bankNameCtr,
                            style: AppTextStyles.bodyLarge,
                            decoration: InputDecoration(
                                labelText: 'Bank Name',
                                prefixIcon:
                                    Icon(Icons.account_balance_rounded)),
                            validator: (v) =>
                                AppValidators.required(v, 'Bank name'),
                          ).animate().fadeIn().slideY(begin: 0.15, end: 0),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _accCtr,
                            keyboardType: TextInputType.number,
                            style: AppTextStyles.bodyLarge,
                            decoration: InputDecoration(
                                labelText: 'Account Number',
                                prefixIcon: Icon(Icons.numbers_rounded)),
                            validator: (v) =>
                                AppValidators.required(v, 'Account number'),
                          )
                              .animate()
                              .fadeIn(delay: 100.ms)
                              .slideY(begin: 0.15, end: 0),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _ifscCtr,
                            textCapitalization: TextCapitalization.characters,
                            style: AppTextStyles.bodyLarge,
                            decoration: InputDecoration(
                                labelText: 'IFSC Code',
                                prefixIcon: Icon(Icons.code_rounded)),
                            validator: (v) =>
                                AppValidators.required(v, 'IFSC code'),
                          )
                              .animate()
                              .fadeIn(delay: 200.ms)
                              .slideY(begin: 0.15, end: 0),
                        ],

                        if (_step == 2) ...[
                          TextFormField(
                            controller: _gstCtr,
                            textCapitalization: TextCapitalization.characters,
                            style: AppTextStyles.bodyLarge,
                            decoration: InputDecoration(
                              labelText: 'GST Number (optional)',
                              prefixIcon: Icon(Icons.business_rounded),
                              helperText:
                                  'Only required if lending as a business',
                            ),
                            validator: AppValidators.gst,
                          ).animate().fadeIn().slideY(begin: 0.15, end: 0),
                          SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.emerald.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.emerald.withOpacity(0.2)),
                            ),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Icon(Icons.verified_rounded,
                                        color: AppColors.emerald, size: 18),
                                    SizedBox(width: 8),
                                    Text('What you get with verification:',
                                        style: AppTextStyles.labelLarge
                                            .copyWith(
                                                color: AppColors.emerald)),
                                  ]),
                                  SizedBox(height: 10),
                                  for (final f in [
                                    'Verified badge on your profile',
                                    'Higher ranking in search results',
                                    'Increased borrower trust'
                                  ])
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 3),
                                      child: Row(children: [
                                        Icon(Icons.check_rounded,
                                            color: AppColors.emerald, size: 14),
                                        SizedBox(width: 8),
                                        Text(f,
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                    color: AppColors
                                                        .textSecondary)),
                                      ]),
                                    ),
                                ]),
                          ).animate().fadeIn(delay: 150.ms),
                        ],

                        SizedBox(height: 32),

                        if (_step < 2)
                          AppButton(
                              label: 'Next',
                              onPressed: () => setState(() => _step++),
                              icon: Icon(Icons.arrow_forward_rounded, size: 18))
                        else
                          AppButton(
                              label: 'Submit KYC',
                              onPressed: _submit,
                              isLoading: _loading,
                              icon: Icon(Icons.verified_rounded, size: 18)),

                        if (_step > 0) ...[
                          SizedBox(height: 12),
                          AppButton(
                              label: 'Back',
                              onPressed: () => setState(() => _step--),
                              isOutlined: true),
                        ],
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
}

class _StepIndicator extends StatelessWidget {
  final int step;
  final List<String> steps;
  const _StepIndicator({required this.step, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: steps.asMap().entries.map((e) {
        final i = e.key;
        final done = i < step;
        final active = i == step;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                decoration: BoxDecoration(
                  gradient: done || active ? AppColors.goldGradient : null,
                  color: done || active ? null : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 6),
              Text(e.value,
                  style: AppTextStyles.caption.copyWith(
                    color: active
                        ? AppColors.gold
                        : done
                            ? AppColors.emerald
                            : AppColors.textMuted,
                  )),
            ]),
          ),
        );
      }).toList(),
    );
  }
}
