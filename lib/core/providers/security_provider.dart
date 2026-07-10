import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_providers.dart';

// ─── PIN & Blur State ─────────────────────────────

final sensitiveDataVisibleProvider = StateProvider<bool>((ref) => false);

final securityProvider =
    StateNotifierProvider<SecurityNotifier, SecurityState>((ref) {
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
  final _localAuth = LocalAuthentication();
  // Sentinel: guaranteed to differ from any real UID (including null on logout)
  static const _sentinel = '__uninitialized__';
  String? _lastUid = _sentinel;

  SecurityNotifier(this.ref) : super(SecurityState()) {
    // ref.listen must be called synchronously in the constructor
    ref.listen(currentUserProvider, (previous, next) {
      final user = next.valueOrNull;
      final uid = user?.uid; // null when logged out

      // Any uid change from the sentinel OR from a different user → re-lock
      if (uid != _lastUid) {
        _lastUid = uid;
        if (mounted) {
          // Always blur when user changes (login, logout, account switch)
          ref.read(sensitiveDataVisibleProvider.notifier).state = false;
        }
      }

      if (user != null) {
        final hasPin = user.securityPin != null && user.securityPin!.isNotEmpty;
        if (mounted) state = state.copyWith(isPinSet: hasPin, isLoading: false);
      } else if (next.hasValue) {
        if (mounted) state = state.copyWith(isPinSet: false, isLoading: false);
      }
    }, fireImmediately: true);
  }

  Future<void> setPin(String pin) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'securityPin': pin});
      if (mounted) state = state.copyWith(isPinSet: true);
      // After setting PIN, unblur so user can see their data right away
      // (they just proved identity by going through the change-PIN flow)
      ref.read(sensitiveDataVisibleProvider.notifier).state = true;
    }
  }

  Future<bool> verifyPin(String pin) async {
    // Always fetch fresh from Firestore to avoid stale cache issues
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return false;

    // Try cached value first
    if (user.securityPin != null && user.securityPin == pin) {
      ref.read(sensitiveDataVisibleProvider.notifier).state = true;
      return true;
    }

    // Fallback: fetch directly from Firestore
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final freshPin = doc.data()?['securityPin'] as String?;
      if (freshPin != null && freshPin == pin) {
        ref.read(sensitiveDataVisibleProvider.notifier).state = true;
        return true;
      }
    } catch (_) {}
    return false;
  }

  void lockSensitiveData() {
    ref.read(sensitiveDataVisibleProvider.notifier).state = false;
  }

  // ─── Device Lock ──────────────────────────────────

  Future<bool> authenticateWithDevice(String reason) async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) return true;

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      return true;
    }
  }
}
