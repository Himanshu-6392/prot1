import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/validators.dart';
import '../../../core/providers/firebase_providers.dart';
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
  bool _isEmailValid = false;
  bool _rememberMe = false;
  String _displayName = "";

  // For shake animation
  int _shakeKey = 0;

  @override
  void initState() {
    super.initState();
    _emailCtr.addListener(_onEmailChanged);
    _loadSavedEmail();
  }

  void _loadSavedEmail() {
    final box = Hive.box('settings');
    final savedEmail = box.get('saved_email', defaultValue: '') as String;
    final savedName = box.get('saved_name', defaultValue: '') as String;
    if (savedEmail.isNotEmpty) {
      _emailCtr.text = savedEmail;
      _rememberMe = true;
      _isEmailValid = AppValidators.email(savedEmail) == null;
    }
    if (savedName.isNotEmpty) {
      setState(() => _displayName = savedName.split(' ').first);
    }
  }

  void _onEmailChanged() {
    final isValid = AppValidators.email(_emailCtr.text) == null;
    if (isValid != _isEmailValid) {
      setState(() => _isEmailValid = isValid);
    }
    if (!isValid && _displayName.isNotEmpty) {
      final box = Hive.box('settings');
      final savedEmail = box.get('saved_email', defaultValue: '') as String;
      if (_emailCtr.text != savedEmail) {
        setState(() => _displayName = "");
      }
    }
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Social Login coming soon!',
            style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: AppColors.gold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _errorMsg = null; });
    try {
      final googleProvider = GoogleAuthProvider();
      final cred = await ref.read(firebaseAuthProvider).signInWithPopup(googleProvider);
      
      final user = cred.user;
      
      if (user != null) {
        final box = Hive.box('settings');
        final realName = user.displayName ?? '';
        if (realName.isNotEmpty) {
          box.put('saved_name', realName);
        }
        if (mounted) context.go('/');
      }
    } catch (e) {
      setState(() { 
        _loading = false; 
        _errorMsg = 'Google Sign-In failed. Check Firebase console configuration.'; 
        _shakeKey++; 
      });
    }
  }

  Future<void> _signInWithApple() async {
    setState(() { _loading = true; _errorMsg = null; });
    try {
      // Using Firebase's built-in OAuth provider for Apple
      final appleProvider = AppleAuthProvider();
      final cred = await ref.read(firebaseAuthProvider).signInWithPopup(appleProvider);
      
      final user = cred.user;
      if (user != null) {
        if (mounted) context.go('/');
      }
    } catch (e) {
      setState(() { 
        _loading = false; 
        _errorMsg = 'Apple Sign-In failed. Check Apple Developer configuration.'; 
        _shakeKey++; 
      });
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() { _loading = true; _errorMsg = null; });
    try {
      final facebookProvider = FacebookAuthProvider();
      final cred = await ref.read(firebaseAuthProvider).signInWithPopup(facebookProvider);
      
      final user = cred.user;
      if (user != null) {
        final box = Hive.box('settings');
        final realName = user.displayName ?? '';
        if (realName.isNotEmpty) box.put('saved_name', realName);
        if (mounted) context.go('/');
      }
    } catch (e) {
      setState(() { 
        _loading = false; 
        _errorMsg = 'Facebook Sign-In failed. Check Facebook Developer App config.'; 
        _shakeKey++; 
      });
    }
  }

  void _showForgotPassword() {
    final emailCtr = TextEditingController(text: _emailCtr.text.trim());
    bool sent = false;
    bool sending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 30,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: sent
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.mark_email_read_rounded,
                            color: AppColors.emerald, size: 30),
                      ),
                      const SizedBox(height: 16),
                      Text('Check your inbox!',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87)),
                      const SizedBox(height: 8),
                      Text(
                        'We sent a password reset link to\n${emailCtr.text.trim()}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.black54,
                            height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.emerald,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50)),
                          ),
                          child: Text('Done',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                        ),
                      ),
                    ],
                  ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95))
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.emerald.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.lock_reset_rounded,
                                color: AppColors.emerald, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Forgot Password',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black87)),
                                Text('Enter your email to reset it',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.black45)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: emailCtr,
                        keyboardType: TextInputType.emailAddress,
                        autofocus: true,
                        style: GoogleFonts.inter(
                            fontSize: 15, color: Colors.black87),
                        decoration: _pillDecoration('Enter your email'),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: sending || emailCtr.text.isEmpty
                                ? null
                                : AppColors.emeraldGradient,
                            color: sending || emailCtr.text.isEmpty
                                ? Colors.grey.shade200
                                : null,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: ElevatedButton(
                            onPressed: sending
                                ? null
                                : () async {
                                    final email = emailCtr.text.trim();
                                    if (email.isEmpty) return;
                                    setModalState(() => sending = true);
                                    try {
                                      await ref
                                          .read(firebaseAuthProvider)
                                          .sendPasswordResetEmail(
                                              email: email);
                                      setModalState(() {
                                        sent = true;
                                        sending = false;
                                      });
                                    } catch (_) {
                                      setModalState(() => sending = false);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                        content: Text(
                                            'Could not send reset email. Check your email address.'),
                                        backgroundColor: Colors.redAccent,
                                      ));
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50)),
                            ),
                            child: sending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white))
                                : Text('Send Reset Link',
                                    style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
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

      final box = Hive.box('settings');
      if (_rememberMe) {
        box.put('saved_email', _emailCtr.text.trim());
      } else {
        box.delete('saved_email');
      }

      final user = ref.read(firebaseAuthProvider).currentUser;
      final realName = user?.displayName ?? '';
      if (realName.isNotEmpty) {
        box.put('saved_name', realName);
      }

      if (mounted) context.go('/');
    } on FirebaseAuthException catch (e) {
      // --- DEV AUTOLOGIN FALLBACK ---
      if (e.code == 'invalid-credential' || e.code == 'user-not-found') {
        try {
          await ref.read(firebaseAuthProvider).createUserWithEmailAndPassword(
                email: _emailCtr.text.trim(),
                password: _passwordCtr.text,
              );
          
          final box = Hive.box('settings');
          if (_rememberMe) box.put('saved_email', _emailCtr.text.trim());
          
          if (mounted) context.go('/');
          return;
        } catch (_) {
          // Fallback to original error if auto-signup fails
        }
      }
      // ------------------------------

      setState(() {
        _loading = false;
        _errorMsg = _friendlyError(e.code);
        _shakeKey++; // trigger shake
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
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please check and try again.';
      case 'invalid-email':
        return 'The email address is not valid. Please enter a correct email.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network and retry.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Try logging in.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters with a mix of letters and numbers.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  void dispose() {
    _emailCtr.removeListener(_onEmailChanged);
    _emailCtr.dispose();
    _passwordCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // ── Auto-dismiss keyboard on tap outside ──
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
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
                    onPressed: () => context.go('/auth/onboarding'),
                  ),
                ),

                // ── Animated Logo + Title ─────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Lottie animation (adjusted for built-in padding)
                      Transform.translate(
                        offset: const Offset(-20, 0),
                        child: SizedBox(
                          width: 160,
                          height: 140,
                          child: Lottie.network(
                            'https://assets9.lottiefiles.com/packages/lf20_jcikwtux.json',
                            repeat: true,
                            animate: true,
                            fit: BoxFit.contain,
                            alignment: Alignment.centerLeft,
                            errorBuilder: (ctx, e, s) => Container(
                              width: 56,
                              height: 56,
                              margin: const EdgeInsets.only(left: 20, top: 20, bottom: 20),
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
                              child: const Icon(Icons.account_balance_rounded,
                                  color: Colors.white, size: 28),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 0),

                      Text(
                        _displayName.isNotEmpty
                            ? 'Welcome back,\n$_displayName!'
                            : 'Welcome Back',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          height: 1.1,
                        ),
                      ).animate().fadeIn(delay: 50.ms).slideY(
                          begin: 0.1, end: 0, curve: Curves.easeOutBack),
                      const SizedBox(height: 6),
                      Text(
                        'Ready to continue your lending journey?',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.black54,
                            height: 1.5),
                      ).animate().fadeIn(delay: 100.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

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
                      padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Error banner with shake ───────────
                            if (_errorMsg != null)
                              AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                child: Container(
                                  key: ValueKey(_shakeKey),
                                  margin:
                                      const EdgeInsets.only(bottom: 20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF4D4F)
                                        .withOpacity(0.06),
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFFF4D4F)
                                          .withOpacity(0.25),
                                      width: 1,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(
                                              top: 1),
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF4D4F)
                                                .withOpacity(0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.lock_outline_rounded,
                                            color: Color(0xFFFF4D4F),
                                            size: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Login Failed',
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  color: const Color(
                                                      0xFFCC1F1F),
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                _errorMsg!,
                                                style: GoogleFonts.inter(
                                                  fontSize: 12.5,
                                                  color: const Color(
                                                          0xFFCC1F1F)
                                                      .withOpacity(0.85),
                                                  height: 1.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => setState(
                                              () => _errorMsg = null),
                                          child: Icon(
                                            Icons.close_rounded,
                                            size: 16,
                                            color: const Color(0xFFFF4D4F)
                                                .withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                                  .animate(key: ValueKey('shake_$_shakeKey'))
                                  .fadeIn()
                                  .slideY(begin: -0.1, end: 0)
                                  .then()
                                  .shakeX(
                                      amount: 4,
                                      duration: 400.ms,
                                      hz: 5),

                            // Email
                            TextFormField(
                              controller: _emailCtr,
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.inter(
                                  fontSize: 15, color: Colors.black87),
                              decoration:
                                  _pillDecoration('Enter email').copyWith(
                                suffixIcon: _isEmailValid
                                    ? Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.success,
                                        size: 20)
                                    : null,
                              ),
                              validator: AppValidators.email,
                            ).animate().fadeIn(delay: 150.ms),

                            const SizedBox(height: 16),

                            // Password
                            TextFormField(
                              controller: _passwordCtr,
                              obscureText: _obscurePass,
                              style: GoogleFonts.inter(
                                  fontSize: 15, color: Colors.black87),
                              decoration:
                                  _pillDecoration('Password').copyWith(
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
                              onFieldSubmitted: (_) => _login(),
                            ).animate().fadeIn(delay: 200.ms),

                            // Remember Me & Forgot Password
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: (val) => setState(
                                            () => _rememberMe =
                                                val ?? false),
                                        activeColor: AppColors.emerald,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4)),
                                        side: const BorderSide(
                                            color: Colors.black38),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Remember me',
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: Colors.black54),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  // ── Forgot password ──────────────
                                  onPressed: _showForgotPassword,
                                  child: Text(
                                    'Forgot password?',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppColors.emerald,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ).animate().fadeIn(delay: 220.ms),

                            const SizedBox(height: 8),

                            // ── Shimmer loading button ────────────
                            _GradientPillButton(
                              label: 'Log In',
                              onPressed: _loading ? null : _login,
                              isLoading: _loading,
                            ).animate().fadeIn(delay: 250.ms),

                            const SizedBox(height: 36),

                            // Social section
                            Center(
                              child: Text('Sign in with',
                                  style: GoogleFonts.inter(
                                      color: Colors.black38,
                                      fontSize: 13)),
                            ).animate().fadeIn(delay: 300.ms),

                            const SizedBox(height: 16),

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
                                          color: Colors.blue[800],
                                          size: 22)),
                                ),
                                const SizedBox(width: 16),
                                GestureDetector(
                                  onTap: _signInWithApple,
                                  child: _SocialCircle(
                                      child: const Icon(Icons.apple,
                                          color: Colors.black87,
                                          size: 22)),
                                ),
                              ],
                            ).animate().fadeIn(delay: 340.ms),

                            const SizedBox(height: 36),

                            Center(
                              child: TextButton(
                                onPressed: () =>
                                    context.go('/auth/signup'),
                                child: RichText(
                                  text: TextSpan(
                                    text: "Don't have an account? ",
                                    style: GoogleFonts.inter(
                                        color: Colors.black45,
                                        fontSize: 14),
                                    children: [
                                      TextSpan(
                                        text: 'Sign Up',
                                        style: GoogleFonts.inter(
                                            color: AppColors.emerald,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: 380.ms),
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
      ),
    );
  }
}

// ── Shimmer loading pill button ──────────────────────────────────────────
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
                      'Please wait...',
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
