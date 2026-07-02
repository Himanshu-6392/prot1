import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../providers/security_provider.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

Future<void> showPinDialog(BuildContext context, WidgetRef ref) async {
  final securityState = ref.read(securityProvider);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.6),
    useSafeArea: true,
    builder: (context) => _PinEntrySheet(isSetup: !securityState.isPinSet),
  );
}

class _PinEntrySheet extends ConsumerStatefulWidget {
  final bool isSetup;
  const _PinEntrySheet({required this.isSetup});

  @override
  ConsumerState<_PinEntrySheet> createState() => _PinEntrySheetState();
}

class _PinEntrySheetState extends ConsumerState<_PinEntrySheet> {
  final TextEditingController _pinController = TextEditingController();
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _onCompleted(String pin) async {
    if (widget.isSetup) {
      await ref.read(securityProvider.notifier).setPin(pin);
      if (mounted) Navigator.pop(context);
    } else {
      final success = await ref.read(securityProvider.notifier).verifyPin(pin);
      if (success) {
        if (mounted) Navigator.pop(context);
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Incorrect PIN. Please try again.';
          _pinController.clear();
        });
      }
    }
  }

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
          // ── Drag Handle ──────────────────────────
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

          // ── Icon Header ──────────────────────────
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
            child: Icon(
              widget.isSetup ? Icons.lock_outline_rounded : Icons.fingerprint_rounded,
              color: Colors.white,
              size: 34,
            ),
          )
              .animate()
              .scale(duration: 500.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 300.ms),

          const SizedBox(height: 20),

          // ── Title ──────────────────────────────
          Text(
            widget.isSetup ? 'Set Security PIN' : 'Enter Security PIN',
            style: AppTextStyles.h2.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              widget.isSetup
                  ? 'Create a 4-digit PIN to secure your sensitive financial details.'
                  : 'Enter your 4-digit PIN to view sensitive information.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 36),

          // ── PIN Fields ─────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: PinCodeTextField(
              appContext: context,
              length: 4,
              obscureText: true,
              obscuringCharacter: '●',
              animationType: AnimationType.scale,
              keyboardType: TextInputType.number,
              controller: _pinController,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(16),
                fieldHeight: 64,
                fieldWidth: 64,
                activeFillColor: AppColors.surfaceAlt,
                inactiveFillColor: AppColors.surfaceAlt,
                selectedFillColor: AppColors.gold.withOpacity(0.08),
                activeColor: _hasError ? AppColors.error : AppColors.gold,
                inactiveColor: AppColors.border,
                selectedColor: AppColors.gold,
                borderWidth: 2,
              ),
              enableActiveFill: true,
              textStyle: AppTextStyles.h2.copyWith(
                color: AppColors.textPrimary,
                fontSize: 20,
              ),
              onChanged: (value) {
                if (_hasError) setState(() { _hasError = false; _errorMessage = ''; });
              },
              onCompleted: _onCompleted,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),

          // ── Error Message ──────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: _hasError
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 16, color: AppColors.error),
                        const SizedBox(width: 6),
                        Text(
                          _errorMessage,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.error),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(height: 12),
          ),

          const SizedBox(height: 8),

          // ── Cancel Button ──────────────────────
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}
