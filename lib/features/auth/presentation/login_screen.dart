import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _emailCtr = TextEditingController();
  final _passwordCtr = TextEditingController();
  bool _loading = false;
  bool _obscurePass = true;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtr.dispose();
    _passwordCtr.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      await ref.read(firebaseAuthProvider).signInWithEmailAndPassword(
            email: _emailCtr.text.trim(),
            password: _passwordCtr.text,
          );
      if (mounted) context.go('/');
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Top Brand Banner ──────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.compare_arrows_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'PeerLend',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 300.ms),

                    const SizedBox(height: 28),

                    Text(
                      'Welcome back',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 100.ms)
                        .slideX(begin: -0.1, end: 0),

                    const SizedBox(height: 6),

                    Text(
                      'Sign in to continue to your account',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textMuted),
                    ).animate().fadeIn(delay: 150.ms),
                  ],
                ),
              ),

              // ── Form Card ───────────────────────
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Error message
                      if (_errorMsg != null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.error.withOpacity(0.25)),
                          ),
                          child: Row(children: [
                            Icon(Icons.error_outline_rounded,
                                color: AppColors.error, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(_errorMsg!,
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: AppColors.error))),
                          ]),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Email
                      Text('Email Address', style: AppTextStyles.labelMedium),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailCtr,
                        keyboardType: TextInputType.emailAddress,
                        style: AppTextStyles.bodyMedium,
                        decoration: const InputDecoration(
                          hintText: 'you@example.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: AppValidators.email,
                      )
                          .animate()
                          .fadeIn(delay: 200.ms)
                          .slideY(begin: 0.15, end: 0),

                      const SizedBox(height: 20),

                      // Password
                      Text('Password', style: AppTextStyles.labelMedium),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordCtr,
                        obscureText: _obscurePass,
                        style: AppTextStyles.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePass
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePass = !_obscurePass),
                            color: AppColors.textMuted,
                          ),
                        ),
                        validator: AppValidators.password,
                        onFieldSubmitted: (_) => _login(),
                      )
                          .animate()
                          .fadeIn(delay: 250.ms)
                          .slideY(begin: 0.15, end: 0),

                      const SizedBox(height: 32),

                      // Login Button
                      AppButton(
                        label: 'Sign In',
                        onPressed: _login,
                        isLoading: _loading,
                        color: AppColors.gold,
                      )
                          .animate()
                          .fadeIn(delay: 300.ms)
                          .slideY(begin: 0.15, end: 0),

                      const SizedBox(height: 20),

                      // Divider
                      Row(children: [
                        Expanded(child: Divider(color: AppColors.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text('or', style: AppTextStyles.caption),
                        ),
                        Expanded(child: Divider(color: AppColors.border)),
                      ]).animate().fadeIn(delay: 350.ms),

                      const SizedBox(height: 20),

                      // Signup link
                      Center(
                        child: TextButton(
                          onPressed: () => context.push('/auth/signup'),
                          child: RichText(
                            text: TextSpan(
                              text: "Don't have an account? ",
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.textSecondary),
                              children: [
                                TextSpan(
                                  text: 'Create one',
                                  style: AppTextStyles.labelLarge
                                      .copyWith(color: AppColors.gold),
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
            ],
          ),
        ),
      ),
    );
  }
}
