import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/utils/validators.dart';
import '../../../core/providers/firebase_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtr     = TextEditingController();
  final _passwordCtr  = TextEditingController();
  bool _loading       = false;
  bool _obscurePass   = true;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtr.dispose();
    _passwordCtr.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMsg = null; });
    try {
      await ref.read(firebaseAuthProvider).signInWithEmailAndPassword(
        email:    _emailCtr.text.trim(),
        password: _passwordCtr.text,
      );
      if (mounted) context.go('/');
    } on FirebaseAuthException catch (e) {
      setState(() { _loading = false; _errorMsg = e.message; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back
                  AppIconButton(
                    icon:      Icons.arrow_back_rounded,
                    onPressed: () => context.go('/onboarding'),
                    bgColor:   AppColors.surfaceAlt,
                  ).animate().fadeIn(duration: 300.ms),

                  SizedBox(height: 32),

                  // Header
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      gradient:     AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 30),
                  ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),

                  SizedBox(height: 24),

                  Text('Welcome Back',
                      style: AppTextStyles.displaySmall)
                      .animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),

                  SizedBox(height: 8),

                  Text(
                    'Sign in to continue',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ).animate().fadeIn(delay: 150.ms),

                  SizedBox(height: 40),

                  // Error message
                  if (_errorMsg != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin:  const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color:        AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border:       Border.all(color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        Icon(Icons.error_rounded, color: AppColors.error, size: 18),
                        SizedBox(width: 10),
                        Expanded(child: Text(_errorMsg!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error))),
                      ]),
                    ),

                  // Email field
                  TextFormField(
                    controller:   _emailCtr,
                    keyboardType: TextInputType.emailAddress,
                    style:        AppTextStyles.bodyLarge,
                    decoration: InputDecoration(
                      labelText:   'Email Address',
                      prefixIcon:  Icon(Icons.email_rounded),
                    ),
                    validator: AppValidators.email,
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                  SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    controller:   _passwordCtr,
                    obscureText:  _obscurePass,
                    style:        AppTextStyles.bodyLarge,
                    decoration: InputDecoration(
                      labelText:   'Password',
                      prefixIcon:  Icon(Icons.lock_rounded),
                      suffixIcon:  IconButton(
                        icon: Icon(_obscurePass ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                        onPressed: () => setState(() => _obscurePass = !_obscurePass),
                        color: AppColors.textSecondary,
                      ),
                    ),
                    validator: AppValidators.password,
                  ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2, end: 0),

                  SizedBox(height: 32),

                  AppButton(
                    label:     'Login',
                    onPressed: _login,
                    isLoading: _loading,
                    icon:      Icon(Icons.login_rounded, size: 18),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

                  SizedBox(height: 24),

                  Row(children: [
                    Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child:   Text('or', style: AppTextStyles.caption),
                    ),
                    Expanded(child: Divider(color: AppColors.border)),
                  ]).animate().fadeIn(delay: 350.ms),

                  SizedBox(height: 16),

                  // New user
                  Center(
                    child: TextButton(
                      onPressed: () {
                        print('SIGN UP TAPPED');
                        context.push('/auth/signup');
                      },
                      child: RichText(
                        text: TextSpan(
                          text:     "Don't have an account? ",
                          style:    AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                          children: [
                            TextSpan(
                              text:  'Sign Up',
                              style: AppTextStyles.labelLarge.copyWith(color: AppColors.gold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

