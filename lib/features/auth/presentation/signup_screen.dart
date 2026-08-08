import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/constants.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/colors.dart';

InputDecoration _pillDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(
        color: Colors.black38, fontSize: 15, fontWeight: FontWeight.w400),
    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
    filled: true,
    fillColor: const Color(0xFFF5F5F7),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(50),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(50),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(50),
      borderSide: BorderSide(color: AppColors.emerald, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(50),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(50),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
    ),
  );
}

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
  bool _loading = false;
  bool _obscurePass = true;
  String? _selectedCity;
  String? _errorMsg;

  bool _isEmailValid = false;
  double _passwordStrength = 0.0;
  Color _passwordStrengthColor = Colors.grey.shade300;
  bool _agreeToTerms = false;
  int _shakeKey = 0;

  @override
  void initState() {
    super.initState();
    _emailCtr.addListener(_onEmailChanged);
    _passwordCtr.addListener(_onPasswordChanged);
  }

  void _onEmailChanged() {
    final isValid = AppValidators.email(_emailCtr.text) == null;
    if (isValid != _isEmailValid) {
      setState(() => _isEmailValid = isValid);
    }
  }

  void _onPasswordChanged() {
    final text = _passwordCtr.text;
    double strength = 0.0;
    if (text.length > 5) strength += 0.33;
    if (text.contains(RegExp(r'[A-Z]'))) strength += 0.33;
    if (text.contains(RegExp(r'[0-9!@#\$&*~]'))) strength += 0.34;

    Color color = Colors.grey.shade300;
    if (strength > 0.0 && strength <= 0.33) color = Colors.redAccent;
    else if (strength > 0.33 && strength <= 0.66) color = Colors.orangeAccent;
    else if (strength > 0.66) color = AppColors.success;

    setState(() {
      _passwordStrength = strength;
      _passwordStrengthColor = color;
    });
  }

  @override
  void dispose() {
    _nameCtr.dispose();
    _emailCtr.dispose();
    _passwordCtr.dispose();
    super.dispose();
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Social Login coming soon!', style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: AppColors.gold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleSocialAuth(UserCredential cred, String name) async {
    final user = cred.user;
    if (user == null) return;

    final doc = await ref.read(firestoreProvider).collection(AppConstants.colUsers).doc(user.uid).get();
    
    if (!doc.exists) {
      final now = DateTime.now();
      final model = UserModel(
        uid: user.uid,
        name: user.displayName ?? name,
        email: user.email ?? '',
        phone: user.phoneNumber ?? '',
        role: UserRole.borrower,
        city: '',
        isPremium: false,
        isVerified: false,
        kycStatus: KycStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(firestoreProvider).collection(AppConstants.colUsers).doc(user.uid).set(model.toMap());
    }

    final realName = user.displayName ?? name;
    final box = Hive.box('settings');
    if (realName.isNotEmpty) box.put('saved_name', realName);
    if (user.email != null) box.put('saved_email', user.email!);

    if (mounted) {
      if (doc.exists) {
        context.go('/');
      } else {
        context.go('/auth/role-selection');
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _errorMsg = null; });
    try {
      final googleProvider = GoogleAuthProvider();
      final cred = await ref.read(firebaseAuthProvider).signInWithPopup(googleProvider);
      await _handleSocialAuth(cred, cred.user?.displayName ?? 'Google User');
    } catch (e) {
      setState(() { 
        _loading = false; 
        _errorMsg = 'Google Sign-Up failed. Check Firebase console configuration.'; 
        _shakeKey++; 
      });
    }
  }

  Future<void> _signInWithApple() async {
    setState(() { _loading = true; _errorMsg = null; });
    try {
      final appleProvider = AppleAuthProvider();
      final cred = await ref.read(firebaseAuthProvider).signInWithPopup(appleProvider);
      await _handleSocialAuth(cred, 'Apple User');
    } catch (e) {
      setState(() { 
        _loading = false; 
        _errorMsg = 'Apple Sign-Up failed. Check Apple Developer configuration.'; 
        _shakeKey++; 
      });
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() { _loading = true; _errorMsg = null; });
    try {
      final facebookProvider = FacebookAuthProvider();
      final cred = await ref.read(firebaseAuthProvider).signInWithPopup(facebookProvider);
      await _handleSocialAuth(cred, cred.user?.displayName ?? 'Facebook User');
    } catch (e) {
      setState(() { 
        _loading = false; 
        _errorMsg = 'Facebook Sign-Up failed. Check Facebook Developer App config.'; 
        _shakeKey++; 
      });
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please agree to the Terms & Conditions to continue.',
              style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
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
      final isAdmin =
          _emailCtr.text.trim().toLowerCase().startsWith('admin');

      final model = UserModel(
        uid: user.uid,
        name: isAdmin ? 'Super Admin' : _nameCtr.text.trim(),
        email: _emailCtr.text.trim(),
        phone: '',
        role: isAdmin ? UserRole.admin : UserRole.borrower,
        city: _selectedCity ?? '',
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

      // Save name + email so login screen can greet user by their real name
      final realName = isAdmin ? 'Super Admin' : _nameCtr.text.trim();
      await user.updateDisplayName(realName);
      final box = Hive.box('settings');
      box.put('saved_name', realName);
      box.put('saved_email', _emailCtr.text.trim());

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
        _errorMsg = _friendlyError(e.code);
        _shakeKey++;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _errorMsg = 'Something went wrong. Please try again.';
        _shakeKey++;
      });
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists. Try logging in instead.';
      case 'invalid-email':
        return 'The email address is not valid. Please enter a correct email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters with a mix of letters and numbers.';
      case 'operation-not-allowed':
        return 'Email sign-up is not enabled. Please contact support.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network and retry.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      // Gradient fills entire scaffold background — no Stack, no pointer issues
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Back button ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 8),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 20, color: Colors.black54),
                  onPressed: () => context.pop(),
                ),
              ),

              // ── Animated Logo + Title ─────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Animated logo icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppColors.emeraldGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emerald.withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person_add_alt_1_rounded,
                          color: Colors.white, size: 26),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(
                          begin: 1.0,
                          end: 1.06,
                          duration: 1800.ms,
                          curve: Curves.easeInOut,
                        ),
                    const SizedBox(height: 12),
                    Text(
                      'Create Your Account',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ).animate().fadeIn(delay: 50.ms).slideY(
                        begin: 0.1, end: 0, curve: Curves.easeOutBack),
                    const SizedBox(height: 6),
                    Text(
                      "Join thousands on their financial journey.",
                      style: GoogleFonts.inter(
                          fontSize: 14, color: Colors.black54, height: 1.5),
                    ).animate().fadeIn(delay: 100.ms),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── White card ───────────────────────────────────
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(36),
                      topRight: Radius.circular(36),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_errorMsg != null)
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF4D4F).withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFFF4D4F).withOpacity(0.25),
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 1),
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF4D4F).withOpacity(0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.error_outline_rounded,
                                          color: Color(0xFFFF4D4F),
                                          size: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Sign Up Failed',
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFFCC1F1F),
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              _errorMsg!,
                                              style: GoogleFonts.inter(
                                                fontSize: 12.5,
                                                color: const Color(0xFFCC1F1F).withOpacity(0.85),
                                                height: 1.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => setState(() => _errorMsg = null),
                                        child: Icon(
                                          Icons.close_rounded,
                                          size: 16,
                                          color: const Color(0xFFFF4D4F).withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ).animate(key: ValueKey('shake_$_shakeKey'))
                                .fadeIn()
                                .slideY(begin: -0.1, end: 0)
                                .then()
                                .shakeX(amount: 4, duration: 400.ms, hz: 5),

                          // Full Name
                          TextFormField(
                            controller: _nameCtr,
                            style: GoogleFonts.inter(
                                fontSize: 15, color: Colors.black87),
                            decoration: _pillDecoration('Enter full name'),
                            validator: AppValidators.name,
                            textCapitalization: TextCapitalization.words,
                          ).animate().fadeIn(delay: 150.ms),

                          const SizedBox(height: 12),

                          // Email
                          TextFormField(
                            controller: _emailCtr,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.inter(
                                fontSize: 15, color: Colors.black87),
                            decoration: _pillDecoration('Enter email').copyWith(
                              suffixIcon: _isEmailValid
                                  ? Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20)
                                  : null,
                            ),
                            validator: AppValidators.email,
                          ).animate().fadeIn(delay: 190.ms),

                          const SizedBox(height: 12),

                          // Password
                          TextFormField(
                            controller: _passwordCtr,
                            obscureText: _obscurePass,
                            style: GoogleFonts.inter(
                                fontSize: 15, color: Colors.black87),
                            decoration: _pillDecoration('Enter password')
                                .copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePass
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: Colors.black38,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePass = !_obscurePass),
                              ),
                            ),
                            validator: AppValidators.password,
                          ).animate().fadeIn(delay: 220.ms),

                          if (_passwordCtr.text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearProgressIndicator(
                                        value: _passwordStrength,
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
                                        minHeight: 4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _passwordStrength > 0.66 ? 'Strong' : (_passwordStrength > 0.33 ? 'Fair' : 'Weak'),
                                    style: GoogleFonts.inter(fontSize: 11, color: _passwordStrengthColor, fontWeight: FontWeight.w600),
                                  )
                                ],
                              ),
                            ).animate().fadeIn(),

                          const SizedBox(height: 12),

                          // City dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedCity,
                            decoration: _pillDecoration('Select city'),
                            dropdownColor: Colors.white,
                            style: GoogleFonts.inter(
                                fontSize: 15, color: Colors.black87),
                            borderRadius: BorderRadius.circular(20),
                            items: AppConstants.popularCities
                                .map((c) =>
                                    DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedCity = v),
                            validator: (v) =>
                                v == null ? 'Please select your city' : null,
                          ).animate().fadeIn(delay: 250.ms),

                          const SizedBox(height: 16),

                          // ── Terms & Conditions checkbox ──────────
                          GestureDetector(
                            onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _agreeToTerms,
                                    onChanged: (val) => setState(() => _agreeToTerms = val ?? false),
                                    activeColor: AppColors.emerald,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    side: BorderSide(color: _agreeToTerms ? AppColors.emerald : Colors.black38),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      text: 'I agree to the ',
                                      style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
                                      children: [
                                        TextSpan(
                                          text: 'Terms & Conditions',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: AppColors.emerald,
                                            fontWeight: FontWeight.w600,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' and ',
                                          style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
                                        ),
                                        TextSpan(
                                          text: 'Privacy Policy',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: AppColors.emerald,
                                            fontWeight: FontWeight.w600,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 280.ms),

                          const SizedBox(height: 16),

                          // Get Started button (with shimmer loading)
                          _GradientPillButton(
                            label: 'Get Started',
                            onPressed: _loading ? null : _submit,
                            isLoading: _loading,
                          ).animate().fadeIn(delay: 300.ms),

                          const SizedBox(height: 20),

                          Center(
                            child: Text('Sign up with',
                                style: GoogleFonts.inter(
                                    color: Colors.black38, fontSize: 13)),
                          ).animate().fadeIn(delay: 320.ms),

                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: _signInWithGoogle,
                                child: _SocialCircle(
                                    child: Text('G',
                                        style: GoogleFonts.poppins(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17))),
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: _signInWithFacebook,
                                child: _SocialCircle(
                                    child: Icon(Icons.facebook,
                                        color: Colors.blue[800], size: 22)),
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: _signInWithApple,
                                child: _SocialCircle(
                                    child: const Icon(Icons.apple,
                                        color: Colors.black87, size: 22)),
                              ),
                            ],
                          ).animate().fadeIn(delay: 360.ms),

                          const SizedBox(height: 16),

                          Center(
                            child: TextButton(
                              onPressed: () => context.go('/auth/login'),
                              child: RichText(
                                text: TextSpan(
                                  text: 'Already have an account? ',
                                  style: GoogleFonts.inter(
                                      color: Colors.black45, fontSize: 14),
                                  children: [
                                    TextSpan(
                                      text: 'Log In',
                                      style: GoogleFonts.inter(
                                          color: AppColors.emerald,
                                          fontWeight: FontWeight.w700),
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
                ).animate().slideY(
                    begin: 0.05,
                    end: 0,
                    delay: 50.ms,
                    duration: 500.ms,
                    curve: Curves.easeOutCubic),
              ),
            ],
          ),
        ),
      ),
    ), // closes GestureDetector child: Scaffold
    ); // closes GestureDetector
  }
}

class _GradientPillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _GradientPillButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.emeraldGradient,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: AppColors.emerald.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          child: isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Creating account...',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(
                      duration: 1200.ms,
                      color: Colors.white.withOpacity(0.3),
                    )
              : Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

class _SocialCircle extends StatelessWidget {
  final Widget child;
  const _SocialCircle({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
