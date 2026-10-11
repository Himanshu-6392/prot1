import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../../models/user_model.dart';
import '../providers/firebase_providers.dart';
import '../router/app_router.dart';

/// Premium Left-Aligned Slide Swipe Role Switcher
/// A minimal, stylish fintech capsule positioned on the LEFT side below the navbar.
/// The draggable handle starts on the LEFT and slides to the RIGHT to switch roles.
class RoleSwipeCapsule extends ConsumerStatefulWidget {
  const RoleSwipeCapsule({super.key});

  @override
  ConsumerState<RoleSwipeCapsule> createState() => _RoleSwipeCapsuleState();
}

class _RoleSwipeCapsuleState extends ConsumerState<RoleSwipeCapsule>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnimation;

  double _currentOffset = 0.0; // Starts at 0.0 (LEFT end)
  bool _isDragging = false;
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isSuccess = false;
  bool _isSwitching = false;

  double _dragDistance = 0.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _performSwitch(UserRole targetRole, UserModel? user) async {
    if (_isSwitching) return;
    _isSwitching = true;

    try {
      // 1. Immediately update active dashboard role in app router for instantaneous feedback
      ref.read(activeDashboardRoleProvider.notifier).state = targetRole;

      // 2. Persist updated role in Firestore
      if (user != null) {
        await ref
            .read(firestoreProvider)
            .collection('users')
            .doc(user.uid)
            .update({'role': targetRole.name});
      }
    } catch (e) {
      debugPrint('Error updating role: $e');
    } finally {
      _isSwitching = false;
      if (mounted) {
        setState(() {
          _isSuccess = false;
          _currentOffset = 0.0;
        });
      }
    }
  }

  void _animateToRest() {
    _slideAnimation = Tween<double>(
      begin: _currentOffset,
      end: 0.0,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    )..addListener(() {
        if (mounted) {
          setState(() {
            _currentOffset = _slideAnimation.value;
          });
        }
      });
    _animController.duration = const Duration(milliseconds: 250);
    _animController.forward(from: 0.0);
  }

  void _triggerSuccess(
      UserRole targetRole, UserModel? user, double maxDistance) {
    if (_isSuccess || _isSwitching) return;
    setState(() => _isSuccess = true);

    _slideAnimation = Tween<double>(
      begin: _currentOffset,
      end: maxDistance,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    )..addListener(() {
        if (mounted) {
          setState(() {
            _currentOffset = _slideAnimation.value;
          });
        }
      });
    _animController.duration = const Duration(milliseconds: 220);
    _animController.forward(from: 0.0).then((_) async {
      await Future.delayed(const Duration(milliseconds: 180));
      if (mounted) {
        await _performSwitch(targetRole, user);
      }
    });
  }

  void _handleTapOrEnter(
      UserRole targetRole, UserModel? user, double maxDistance) {
    if (_isSwitching || _isSuccess || _isDragging) return;
    _triggerSuccess(targetRole, user, maxDistance);
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;
    final overrideRole = ref.watch(activeDashboardRoleProvider);
    final effectiveRole = overrideRole ?? user?.role ?? UserRole.borrower;

    final isLender = effectiveRole == UserRole.lender;
    final label = isLender ? 'Switch to Borrower' : 'Switch to Lender';
    final targetRole = isLender ? UserRole.borrower : UserRole.lender;

    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        // Compact & Centered: min(320px, calc(100% - 32px)), ~290–320px on desktop
        final double capsuleWidth =
            math.min(312.0, availableWidth - 32.0).clamp(260.0, 312.0);
        const double capsuleHeight = 68.0; // 66–72px
        const double handleSize = 48.0;   // 44–48px
        const double padding = 10.0;       // Perfectly centers handle: (68 - 48) / 2
        const double mainFontSize = 14.5; // 14–15px
        const double helperFontSize = 11.5; // 11–12px

        final double maxDistance =
            math.max(0.0, capsuleWidth - handleSize - (padding * 2));

        if (!_isDragging &&
            !_animController.isAnimating &&
            !_isSuccess &&
            _currentOffset > maxDistance) {
          _currentOffset = 0.0;
        }

        final double currentPos = _currentOffset.clamp(0.0, maxDistance);
        final double dragProgress = maxDistance > 0
            ? (currentPos / maxDistance).clamp(0.0, 1.0)
            : 0.0;

        return Semantics(
          button: true,
          label: '$label. Swipe right or tap to switch role.',
          child: Focus(
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.enter ||
                    event.logicalKey == LogicalKeyboardKey.space) {
                  _handleTapOrEnter(targetRole, user, maxDistance);
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            onFocusChange: (focused) => setState(() => _isFocused = focused),
            child: FocusableActionDetector(
              onShowFocusHighlight: (val) => setState(() => _isFocused = val),
              onShowHoverHighlight: (val) => setState(() => _isHovered = val),
              mouseCursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _handleTapOrEnter(targetRole, user, maxDistance),
                onHorizontalDragStart: (details) {
                  if (_isSwitching || _isSuccess) return;
                  _animController.stop();
                  _dragDistance = 0.0;
                  setState(() => _isDragging = true);
                },
                onHorizontalDragUpdate: (details) {
                  if (_isSwitching || _isSuccess) return;
                  _dragDistance += details.delta.dx.abs();
                  setState(() {
                    // Moving right -> details.delta.dx > 0
                    _currentOffset = (_currentOffset + details.delta.dx)
                        .clamp(0.0, maxDistance);
                  });
                },
                onHorizontalDragEnd: (details) {
                  if (_isSwitching || _isSuccess) return;
                  _isDragging = false;
                  // If gesture had almost no movement, treat as tap
                  if (_dragDistance < 10.0) {
                    _triggerSuccess(targetRole, user, maxDistance);
                    return;
                  }
                  final progress = maxDistance > 0
                      ? (_currentOffset / maxDistance)
                      : 0.0;
                  // Threshold: approximately 75% toward the right
                  if (progress >= 0.75) {
                    _triggerSuccess(targetRole, user, maxDistance);
                  } else {
                    _animateToRest();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  width: capsuleWidth,
                  height: capsuleHeight,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(
                      color: _isFocused
                          ? AppColors.emerald
                          : (_isHovered
                              ? const Color(0xFF10B981).withValues(alpha: 0.40)
                              : const Color(0xFFD4E2D8)), // Delicate gray-green border
                      width: _isFocused ? 1.6 : 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isHovered
                            ? const Color(0xFF10B981).withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.035),
                        blurRadius: _isHovered ? 14 : 8,
                        offset: Offset(0, _isHovered ? 4 : 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // Subtle mint wash that extends from LEFT behind handle
                      Positioned(
                        left: padding,
                        top: padding,
                        bottom: padding,
                        width: (currentPos + handleSize)
                            .clamp(handleSize, capsuleWidth - (padding * 2)),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF10B981).withValues(alpha: 0.12),
                                const Color(0xFF10B981).withValues(alpha: 0.03),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ),

                      // Text content in track with improved typography hierarchy
                      Positioned(
                        left: padding + handleSize + 12.0,
                        top: 0,
                        bottom: 0,
                        right: padding + 8.0,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Main destination label (strong hierarchy, rich dark tone)
                              Text(
                                _isSuccess ? 'Switching...' : label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                  fontSize: mainFontSize,
                                  letterSpacing: -0.25,
                                ),
                              ),
                              const SizedBox(height: 2),

                              // Helper hint (subtle slate tone with directional chevron)
                              AnimatedOpacity(
                                opacity: _isSuccess
                                    ? 0.0
                                    : ((1.0 - dragProgress * 1.6)
                                        .clamp(0.0, 1.0)),
                                duration: const Duration(milliseconds: 140),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Swipe right to switch role',
                                      style: AppTextStyles.caption.copyWith(
                                        color: const Color(0xFF64748B),
                                        fontSize: helperFontSize,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Mint-green circular draggable handle (subtle mint gradient + soft shadow)
                      Positioned(
                        left: padding + currentPos,
                        top: padding,
                        child: MouseRegion(
                          cursor: _isDragging
                              ? SystemMouseCursors.grabbing
                              : SystemMouseCursors.grab,
                          child: Container(
                            width: handleSize,
                            height: handleSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF4ADE80), // Soft luminous mint
                                  Color(0xFF10B981), // Refined emerald green
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981)
                                      .withValues(alpha: 0.24),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2.5),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: _isSuccess
                                    ? const Icon(
                                        Icons.check_rounded,
                                        key: ValueKey('check'),
                                        color: Colors.white,
                                        size: 24,
                                      )
                                    : Transform.rotate(
                                        angle: disableAnimations
                                            ? 0.0
                                            : dragProgress * math.pi,
                                        child: const Icon(
                                          Icons.swap_horiz_rounded,
                                          key: ValueKey('swap'),
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Baseline track for bottom progress line
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 2.5,
                        child: Container(
                          color: const Color(0xFFF1F5F9),
                        ),
                      ),

                      // Thin animated progress line that fills from left to right as user swipes
                      Positioned(
                        left: 0,
                        bottom: 0,
                        height: 2.5,
                        width: (capsuleWidth * dragProgress)
                            .clamp(0.0, capsuleWidth),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF34D399), // Mint
                                Color(0xFF10B981), // Emerald
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
