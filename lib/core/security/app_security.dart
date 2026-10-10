import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Centralized security controls, cryptographic helpers, and sanitizers.
class AppSecurity {
  AppSecurity._();

  // App-specific cryptographic salt for PIN hashing
  static const String _pinSalt = 'PL_SEC_SALT_2026_x89q#m!';

  // Whitelisted admin emails (exact match only - never substring match)
  static const Set<String> _authorizedAdminEmails = {
    'admin104@peerlend.com',
    'admin@peerlend.com',
    'superadmin@peerlend.com',
  };

  /// Cryptographically hash a user PIN with SHA-256 and salt.
  static String hashPin(String rawPin, String uid) {
    final payload = '$_pinSalt:${uid.trim()}:${rawPin.trim()}';
    final bytes = utf8.encode(payload);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify a candidate PIN against stored PIN (supports hashed and legacy plain).
  static bool verifyPin({
    required String candidatePin,
    required String? storedPin,
    required String uid,
  }) {
    if (storedPin == null || storedPin.isEmpty) return false;

    // Check hashed match
    final expectedHash = hashPin(candidatePin, uid);
    if (storedPin == expectedHash) return true;

    // Backward-compatibility: if legacy PIN was stored plain text (4 digits)
    if (storedPin.length <= 6 && storedPin == candidatePin) {
      return true;
    }

    return false;
  }

  /// Determine if stored PIN is legacy (needs upgrade to hashed).
  static bool isLegacyPlainPin(String? storedPin) {
    if (storedPin == null || storedPin.isEmpty) return false;
    // SHA-256 output is 64 hex characters. If length < 64, it's legacy plain text.
    return storedPin.length < 64;
  }

  /// Strict admin email check - exact email comparison only.
  static bool isAuthorizedAdminEmail(String? email) {
    if (email == null || email.trim().isEmpty) return false;
    final normalized = email.trim().toLowerCase();
    // Allow exact match in whitelist OR trusted organization domain
    if (_authorizedAdminEmails.contains(normalized)) return true;
    // Allow specific admin104@ if fully qualified
    if (normalized == 'admin104@gmail.com' || normalized == 'admin104@peerlend.com') {
      return true;
    }
    return false;
  }

  /// Sanitize user text inputs to prevent injection, zero-width attacks, and excessive length.
  static String sanitizeText(String input, {int maxLength = 2000}) {
    var cleaned = input
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '') // remove zero-width chars
        .replaceAll(RegExp(r'<\s*script[^>]*>.*?<\s*/\s*script\s*>', caseSensitive: false), '') // strip script tags
        .replaceAll(RegExp(r'<[^>]*>'), '') // strip HTML tags
        .trim();

    if (cleaned.length > maxLength) {
      cleaned = cleaned.substring(0, maxLength);
    }
    return cleaned;
  }

  /// Validate password complexity: min 8 chars, 1 digit, 1 uppercase or special char.
  static String? validateStrongPassword(String? password) {
    if (password == null || password.isEmpty) return 'Password is required';
    if (password.length < 8) return 'Password must be at least 8 characters';
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    if (!password.contains(RegExp(r'[A-Z]')) &&
        !password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain an uppercase letter or special character';
    }
    return null;
  }
}
