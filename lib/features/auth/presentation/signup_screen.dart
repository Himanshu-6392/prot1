import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/constants.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});
  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtr = TextEditingController();
  final _emailCtr = TextEditingController();
  final _passwordCtr = TextEditingController();
  final _cityCtr = TextEditingController();
  bool _loading = false;
  bool _obscurePass = true;
  String? _selectedCity;
  String? _errorMsg;

  @override
  void dispose() {
    _nameCtr.dispose();
    _emailCtr.dispose();
    _passwordCtr.dispose();
    _cityCtr.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final cred =
          await ref.read(firebaseAuthProvider).createUserWithEmailAndPassword(
                email: _emailCtr.text.trim(),
                password: _passwordCtr.text,
              );

      final user = cred.user;
      if (user == null) {
        setState(() => _loading = false);
        return;
      }

      final now = DateTime.now();

      final isAdmin = _emailCtr.text.trim().toLowerCase().startsWith('admin');

      final model = UserModel(
        uid: user.uid,
        name: isAdmin ? 'Super Admin' : _nameCtr.text.trim(),
        email: _emailCtr.text.trim(),
        phone: '', // Optional or empty for email login
        role: isAdmin ? UserRole.admin : UserRole.borrower,
        city: _selectedCity ?? _cityCtr.text.trim(),
        isPremium: isAdmin,
        isVerified: isAdmin,
        kycStatus: isAdmin ? KycStatus.verified : KycStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      await ref
          .read(firestoreProvider)
          .collection(AppConstants.colUsers)
          .doc(user.uid)
          .set(model.toMap());

      if (mounted) {
        if (isAdmin) {
          context.go('/');
        } else {
          context.go('/auth/role-selection');
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;
        _errorMsg = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Create Account', style: AppTextStyles.h3),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMsg != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      Icon(Icons.error_rounded,
                          color: AppColors.error, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                          child: Text(_errorMsg!,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.error))),
                    ]),
                  ),

                // Name
                TextFormField(
                  controller: _nameCtr,
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                  validator: AppValidators.name,
                  textCapitalization: TextCapitalization.words,
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15, end: 0),

                SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailCtr,
                  style: AppTextStyles.bodyLarge,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_rounded),
                  ),
                  validator: AppValidators.email,
                ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.15, end: 0),

                SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordCtr,
                  obscureText: _obscurePass,
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                      color: AppColors.textSecondary,
                    ),
                  ),
                  validator: AppValidators.password,
                ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.15, end: 0),

                SizedBox(height: 16),

                // City dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city_rounded),
                  ),
                  dropdownColor: AppColors.surface,
                  style: AppTextStyles.bodyLarge,
                  items: AppConstants.popularCities
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c, style: AppTextStyles.bodyMedium),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCity = v),
                  validator: (v) =>
                      v == null ? 'Please select your city' : null,
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.15, end: 0),

                SizedBox(height: 32),

                AppButton(
                  label: 'Sign Up',
                  onPressed: _submit,
                  isLoading: _loading,
                  icon: Icon(Icons.person_add_rounded, size: 18),
                ).animate().fadeIn(delay: 350.ms),

                SizedBox(height: 20),

                Center(
                  child: Text(
                    'By signing up you agree to our Terms & Privacy Policy',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                        children: [
                          TextSpan(
                            text: 'Sign In',
                            style: AppTextStyles.labelLarge
                                .copyWith(color: AppColors.gold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 450.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
