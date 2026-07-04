import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'firebase_providers.dart';

// ─── PIN & Blur State ─────────────────────────────

final sensitiveDataVisibleProvider = StateProvider<bool>((ref) => false);

final securityProvider = StateNotifierProvider<SecurityNotifier, SecurityState>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  return SecurityNotifier(ref, user?.uid ?? 'guest');
});

class SecurityState {
  final bool isPinSet;
  final bool isLoading;
  final bool useBiometrics;
  final bool appLocked;

  SecurityState({
    this.isPinSet = false, 
    this.isLoading = true,
    this.useBiometrics = false,
    this.appLocked = false,
  });

  SecurityState copyWith({bool? isPinSet, bool? isLoading, bool? useBiometrics, bool? appLocked}) {
    return SecurityState(
      isPinSet: isPinSet ?? this.isPinSet,
      isLoading: isLoading ?? this.isLoading,
      useBiometrics: useBiometrics ?? this.useBiometrics,
      appLocked: appLocked ?? this.appLocked,
    );
  }
}

class SecurityNotifier extends StateNotifier<SecurityState> {
  final Ref ref;
  final String uid;
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  SecurityNotifier(this.ref, this.uid) : super(SecurityState()) {
    _init();
  }

  String get _pinKey => 'user_secure_pin_$uid';
  String get _bioKey => 'use_biometrics_$uid';

  Future<void> _init() async {
    final pin = await _storage.read(key: _pinKey);
    final bio = await _storage.read(key: _bioKey);
    final useBio = bio != 'false'; // Default to true unless explicitly disabled
    
    if (!mounted) return;

    state = state.copyWith(
      isPinSet: pin != null && pin.isNotEmpty,
      useBiometrics: useBio,
      isLoading: false,
    );
  }

  Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
    state = state.copyWith(isPinSet: true);
    // Unblur automatically when setting a new PIN
    ref.read(sensitiveDataVisibleProvider.notifier).state = true;
  }

  Future<bool> verifyPin(String pin) async {
    final savedPin = await _storage.read(key: _pinKey);
    if (savedPin == pin) {
      ref.read(sensitiveDataVisibleProvider.notifier).state = true;
      return true;
    }
    return false;
  }

  Future<void> setUseBiometrics(bool value) async {
    await _storage.write(key: _bioKey, value: value.toString());
    state = state.copyWith(useBiometrics: value);
  }

  void lockSensitiveData() {
    ref.read(sensitiveDataVisibleProvider.notifier).state = false;
  }

  void lockApp() {
    state = state.copyWith(appLocked: true);
    lockSensitiveData();
  }
  
  void unlockApp() {
    state = state.copyWith(appLocked: false);
  }

  // ─── Device Lock ──────────────────────────────────

  Future<bool> authenticateWithDevice(String reason) async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        return true; // If device has no lock screen, just allow
      }

      // Small delay to ensure the activity is fully resumed/in foreground before calling native auth
      await Future.delayed(const Duration(milliseconds: 300));

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // fallback to device PIN/Pattern
        ),
      );
    } catch (e) {
      print('Biometric Error: $e');
      // In case of error (e.g. no hardware), return false to keep it locked, or prompt PIN?
      // Wait, if it fails due to no activity, it will just skip. Let's return false to enforce security if it crashes.
      return false;
    }
  }
}
