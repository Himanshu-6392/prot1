import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

// ─── PIN & Blur State ─────────────────────────────

final sensitiveDataVisibleProvider = StateProvider<bool>((ref) => false);

final securityProvider = StateNotifierProvider<SecurityNotifier, SecurityState>((ref) {
  return SecurityNotifier(ref);
});

class SecurityState {
  final bool isPinSet;
  final bool isLoading;

  SecurityState({this.isPinSet = false, this.isLoading = true});

  SecurityState copyWith({bool? isPinSet, bool? isLoading}) {
    return SecurityState(
      isPinSet: isPinSet ?? this.isPinSet,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SecurityNotifier extends StateNotifier<SecurityState> {
  final Ref ref;
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  static const _pinKey = 'user_secure_pin';

  SecurityNotifier(this.ref) : super(SecurityState()) {
    _init();
  }

  Future<void> _init() async {
    final pin = await _storage.read(key: _pinKey);
    state = state.copyWith(isPinSet: pin != null && pin.isNotEmpty, isLoading: false);
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

  void lockSensitiveData() {
    ref.read(sensitiveDataVisibleProvider.notifier).state = false;
  }

  // ─── Device Lock ──────────────────────────────────

  Future<bool> authenticateWithDevice(String reason) async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        return true; // If device has no lock screen, just allow
      }

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // fallback to device PIN/Pattern
        ),
      );
    } catch (e) {
      // In case of error (e.g. no hardware), we might just allow or log
      return true;
    }
  }
}
