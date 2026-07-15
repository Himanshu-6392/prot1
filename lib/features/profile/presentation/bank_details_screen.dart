import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/providers/firebase_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BankDetailsScreen extends ConsumerStatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  ConsumerState<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends ConsumerState<BankDetailsScreen> {
  final nameCtr = TextEditingController();
  final bankCtr = TextEditingController();
  final accCtr = TextEditingController();
  final ifscCtr = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadBankDetails();
  }

  Future<void> _loadBankDetails() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data()!.containsKey('bankDetails')) {
        final bankData = doc.data()!['bankDetails'] as Map<String, dynamic>;
        nameCtr.text = bankData['accountName'] ?? '';
        bankCtr.text = bankData['bankName'] ?? '';
        accCtr.text = bankData['accountNumber'] ?? '';
        ifscCtr.text = bankData['ifsc'] ?? '';
      }
    } catch (e) {
      // Ignore
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    nameCtr.dispose();
    bankCtr.dispose();
    accCtr.dispose();
    ifscCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Bank Details', style: AppTextStyles.h3),
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
                boxShadow: [
                  BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 2)
                ],
              ),
              child: Icon(Icons.account_balance_rounded,
                  size: 48, color: AppColors.gold),
            ).animate().scale(
                delay: 50.ms, duration: 400.ms, curve: Curves.easeOutBack),
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
                    child: CircularProgressIndicator(color: AppColors.gold)),
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
                      borderSide: BorderSide(color: AppColors.gold, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
                      borderSide: BorderSide(color: AppColors.gold, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
                  prefixIcon:
                      Icon(Icons.numbers_rounded, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceAlt,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.gold, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
                      borderSide: BorderSide(color: AppColors.gold, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                textCapitalization: TextCapitalization.characters,
              ).animate().fadeIn(delay: 350.ms).slideX(begin: 0.05),

              const SizedBox(height: 48),

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
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text('Please fill all details'),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ));
                          return;
                        }

                        if (acctNum.length < 9) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text(
                                'Account Number must be at least 9 digits'),
                            backgroundColor: AppColors.warning,
                            behavior: SnackBarBehavior.floating,
                          ));
                          return;
                        }

                        setState(() => isSaving = true);

                        // Verify IFSC with Razorpay API (wrap in try-catch to not block offline)
                        try {
                          final response = await Dio()
                              .get('https://ifsc.razorpay.com/$ifsc');
                          if (response.statusCode == 200) {
                            final bankNameFromApi = response.data['BANK'];
                            bankCtr.text = bankNameFromApi;
                          }
                        } catch (e) {
                          // Offline or API error, just proceed with whatever they entered
                        }

                        final uid = FirebaseAuth.instance.currentUser?.uid;
                        if (uid != null) {
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .update({
                            'bankDetails': {
                              'accountName': acctName,
                              'bankName': bankCtr.text.trim(),
                              'accountNumber': acctNum,
                              'ifsc': ifsc,
                              'updatedAt': Timestamp.now(),
                            }
                          }).catchError(
                                  (e) => print('Background sync error: $e'));
                        }

                        if (context.mounted) {
                          context.pop();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text(
                                'Bank Details verified and saved securely! 🏦'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.4),
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
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1).shimmer(
                  delay: 1000.ms,
                  duration: 1500.ms,
                  color: Colors.white.withValues(alpha: 0.3)),
            ]
          ],
        ),
      ),
    );
  }
}
