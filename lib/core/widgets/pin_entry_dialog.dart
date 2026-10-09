import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../providers/security_provider.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

// ─── Shared PIN Dialog entry point ─────────────────────────────────────────

/// Shows the PIN dialog.
/// - [forceSetup] = true → set/reset PIN directly (no current-PIN check)
/// - default            → verify mode (returns true if PIN matched)
Future<bool> showPinDialog(
  BuildContext context,
  WidgetRef ref, {
  bool forceSetup = false,
  bool isDismissible = true,
}) async {
  final securityState = ref.read(securityProvider);
  final isSetupMode = forceSetup || !securityState.isPinSet;
  final canDismiss = isDismissible && securityState.isPinSet;

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.6),
    useSafeArea: true,
    useRootNavigator: true,
    isDismissible: canDismiss,
    enableDrag: canDismiss,
    builder: (ctx) => PopScope(
      canPop: canDismiss,
      child: _PinEntrySheet(isSetup: isSetupMode, canDismiss: canDismiss),
    ),
  );
  return result ?? false;
}

/// Full change-PIN flow shown from Security & Privacy settings.
/// Step 1: verify any previously known PIN (with "Forgot PIN" tip).
/// Step 2: set a new PIN.
/// Returns true if the PIN was successfully changed.
Future<bool> showChangePinFlow(BuildContext context, WidgetRef ref) async {
  // Step 1 — verify old PIN
  final verified = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.6),
    useSafeArea: true,
    useRootNavigator: true,
    isDismissible: true,
    enableDrag: true,
    builder: (ctx) => const _VerifyOldPinSheet(),
  );
  if (verified != true || !context.mounted) return false;

  // Step 2 — set new PIN
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.6),
    useSafeArea: true,
    useRootNavigator: true,
    isDismissible: false,
    enableDrag: false,
    builder: (ctx) => const PopScope(canPop: false, child: _SetNewPinSheet()),
  );
  return changed ?? false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal sheets
// ─────────────────────────────────────────────────────────────────────────────

class _PinEntrySheet extends ConsumerStatefulWidget {
  final bool isSetup;
  final bool canDismiss;
  const _PinEntrySheet({required this.isSetup, this.canDismiss = true});

  @override
  ConsumerState<_PinEntrySheet> createState() => _PinEntrySheetState();
}

class _PinEntrySheetState extends ConsumerState<_PinEntrySheet> {
  TextEditingController _ctrl = TextEditingController();
  bool _hasError = false;
  String _errorMessage = '';
  bool _loading = false;
  int _fieldKey = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Creates a fresh controller so the old one (which PinCodeTextField
  /// may have disposed internally on key change) is never reused.
  void _resetField(String errorMsg) {
    final old = _ctrl;
    setState(() {
      _ctrl = TextEditingController();
      _hasError = true;
      _errorMessage = errorMsg;
      _loading = false;
      _fieldKey++;
    });
    // Defer disposal until after the frame so Flutter can clean up safely
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  Future<void> _onCompleted(String pin) async {
    if (_loading) return;
    setState(() => _loading = true);

    if (widget.isSetup) {
      await ref.read(securityProvider.notifier).setPin(pin);
      if (mounted) Navigator.pop(context, true);
    } else {
      final success = await ref.read(securityProvider.notifier).verifyPin(pin);
      if (!mounted) return;
      if (success) {
        Navigator.pop(context, true);
      } else {
        _resetField('Incorrect PIN. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PinSheetScaffold(
      icon: widget.isSetup
          ? Icons.lock_outline_rounded
          : Icons.fingerprint_rounded,
      title: widget.isSetup ? 'Set Security PIN' : 'Enter Security PIN',
      subtitle: widget.isSetup
          ? 'Create a 4-digit PIN to secure your sensitive financial details.'
          : 'Enter your 4-digit PIN to view sensitive information.',
      ctrl: _ctrl,
      pinFieldKey: _fieldKey,
      hasError: _hasError,
      errorMessage: _errorMessage,
      loading: _loading,
      canDismiss: widget.canDismiss,
      onChanged: (v) {
        if (_hasError) {
          setState(() {
            _hasError = false;
            _errorMessage = '';
          });
        }
      },
      onCompleted: _onCompleted,
    );
  }
}

// ── Step 1 of Change-PIN flow: verify any remembered PIN ───────────────────

class _VerifyOldPinSheet extends ConsumerStatefulWidget {
  const _VerifyOldPinSheet();

  @override
  ConsumerState<_VerifyOldPinSheet> createState() => _VerifyOldPinSheetState();
}

class _VerifyOldPinSheetState extends ConsumerState<_VerifyOldPinSheet> {
  TextEditingController _ctrl = TextEditingController();
  bool _hasError = false;
  String _errorMessage = '';
  bool _loading = false;
  int _fieldKey = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _resetField(String errorMsg) {
    final old = _ctrl;
    setState(() {
      _ctrl = TextEditingController();
      _hasError = true;
      _errorMessage = errorMsg;
      _loading = false;
      _fieldKey++;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  Future<void> _onCompleted(String pin) async {
    if (_loading) return;
    setState(() => _loading = true);

    final success = await ref.read(securityProvider.notifier).verifyPin(pin);
    if (!mounted) return;

    if (success) {
      ref.read(sensitiveDataVisibleProvider.notifier).state = false;
      Navigator.pop(context, true);
    } else {
      _resetField('PIN did not match. Try another PIN you remember.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PinSheetScaffold(
      icon: Icons.history_rounded,
      title: 'Verify Your PIN',
      subtitle:
          'Enter any PIN you have previously used.\nThis protects your account from unauthorized changes.',
      ctrl: _ctrl,
      pinFieldKey: _fieldKey,
      hasError: _hasError,
      errorMessage: _errorMessage,
      loading: _loading,
      canDismiss: true,
      onChanged: (v) {
        if (_hasError) {
          setState(() {
            _hasError = false;
            _errorMessage = '';
          });
        }
      },
      onCompleted: _onCompleted,
    );
  }
}

// ── Step 2 of Change-PIN flow: set the new PIN ──────────────────────────────

class _SetNewPinSheet extends ConsumerStatefulWidget {
  const _SetNewPinSheet();

  @override
  ConsumerState<_SetNewPinSheet> createState() => _SetNewPinSheetState();
}

class _SetNewPinSheetState extends ConsumerState<_SetNewPinSheet> {
  final TextEditingController _ctrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onCompleted(String pin) async {
    if (_loading) return;
    setState(() => _loading = true);
    await ref.read(securityProvider.notifier).setPin(pin);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return _PinSheetScaffold(
      icon: Icons.lock_reset_rounded,
      title: 'Set New PIN',
      subtitle:
          'Choose a new 4-digit PIN. Make it something only you will remember.',
      ctrl: _ctrl,
      hasError: false,
      errorMessage: '',
      loading: _loading,
      canDismiss: false,
      onChanged: (_) {},
      onCompleted: _onCompleted,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared PIN sheet UI scaffold
// ─────────────────────────────────────────────────────────────────────────────

class _PinSheetScaffold extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final TextEditingController ctrl;
  final int pinFieldKey; // incremented to force full PIN field reset
  final bool hasError;
  final String errorMessage;
  final bool loading;
  final bool canDismiss;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCompleted;

  const _PinSheetScaffold({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.ctrl,
    this.pinFieldKey = 0,
    required this.hasError,
    required this.errorMessage,
    required this.loading,
    required this.canDismiss,
    required this.onChanged,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 40,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Icon(icon, color: Colors.white, size: 34),
          )
              .animate()
              .scale(duration: 500.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 300.ms),

          const SizedBox(height: 20),

          Text(
            title,
            style: AppTextStyles.h2
                .copyWith(fontSize: 22, fontWeight: FontWeight.w700),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 36),

          // PIN field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: PinCodeTextField(
              key: ValueKey('pin_field_$pinFieldKey'),
              appContext: context,
              length: 4,
              obscureText: true,
              obscuringCharacter: '\u25cf',
              animationType: AnimationType.scale,
              keyboardType: TextInputType.number,
              controller: ctrl,
              enabled: !loading,
              autoFocus: true,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(16),
                fieldHeight: 64,
                fieldWidth: 64,
                activeFillColor: AppColors.surfaceAlt,
                inactiveFillColor: AppColors.surfaceAlt,
                selectedFillColor: AppColors.gold.withOpacity(0.08),
                activeColor: hasError ? AppColors.error : AppColors.gold,
                inactiveColor: AppColors.border,
                selectedColor: AppColors.gold,
                borderWidth: 2,
              ),
              enableActiveFill: true,
              textStyle: AppTextStyles.h2.copyWith(
                color: AppColors.textPrimary,
                fontSize: 20,
              ),
              onChanged: onChanged,
              onCompleted: onCompleted,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),

          // Error message
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: hasError
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 16, color: AppColors.error),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            errorMessage,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.error),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(height: 12),
          ),

          const SizedBox(height: 8),

          // Cancel button (only shown when dismissible)
          if (canDismiss)
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Cancel',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.textSecondary)),
            ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}
