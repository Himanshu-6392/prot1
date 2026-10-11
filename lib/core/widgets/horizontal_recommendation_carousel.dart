import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/colors.dart';
import 'shimmer_widgets.dart';

/// A reusable horizontal swipe carousel for recommendation cards.
/// Includes:
/// - 4.5s auto-slide transition (450ms, easeInOut)
/// - Pause on touch/swipe/hover/lifecycle and resume after 5s
/// - Responsive viewport fraction (~1.2-1.4 cards visible with next card peeking)
/// - Smooth animated pagination pill/dots
/// - One-time entrance animation (~10px upward fade in over 350ms)
/// - Respects OS reduced-motion accessibility preference
class HorizontalRecommendationCarousel<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final double height;
  final bool showDots;
  final bool autoSlide;
  final ValueChanged<int>? onPageChanged;

  const HorizontalRecommendationCarousel({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.height = 208.0,
    this.showDots = true,
    this.autoSlide = false,
    this.onPageChanged,
  });

  @override
  State<HorizontalRecommendationCarousel<T>> createState() =>
      _HorizontalRecommendationCarouselState<T>();
}

class _HorizontalRecommendationCarouselState<T>
    extends State<HorizontalRecommendationCarousel<T>>
    with WidgetsBindingObserver {
  late PageController _pageController;
  int _currentPage = 0;
  double _currentFraction = 0.82;
  bool _initialized = false;

  Timer? _autoSlideTimer;
  Timer? _resumeTimer;
  bool _isUserInteracting = false;
  bool _isHovered = false;
  bool _isPausedByLifecycle = false;

  static const _autoSlideInterval = Duration(milliseconds: 4500);
  static const _transitionDuration = Duration(milliseconds: 450);
  static const _resumeDelay = Duration(milliseconds: 5000);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(
      initialPage: 0,
      viewportFraction: _currentFraction,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final targetFraction = (screenWidth > 600)
        ? (350.0 / screenWidth).clamp(0.25, 0.82)
        : 0.82;

    if (!_initialized || (_currentFraction - targetFraction).abs() > 0.01) {
      _initialized = true;
      _currentFraction = targetFraction;
      final oldPage = _currentPage;
      _pageController.dispose();
      _pageController = PageController(
        initialPage: oldPage,
        viewportFraction: _currentFraction,
      );
    }

    _checkAndStartAutoSlide();
  }

  @override
  void didUpdateWidget(covariant HorizontalRecommendationCarousel<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _checkAndStartAutoSlide();
    }
  }

  void _checkAndStartAutoSlide() {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!widget.autoSlide ||
        widget.items.length <= 1 ||
        disableAnimations ||
        _isUserInteracting ||
        _isHovered ||
        _isPausedByLifecycle) {
      _cancelAutoSlideTimer();
      return;
    }
    _startAutoSlideTimer();
  }

  void _startAutoSlideTimer() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(_autoSlideInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (widget.items.length <= 1 ||
          _isUserInteracting ||
          _isHovered ||
          _isPausedByLifecycle) {
        return;
      }
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % widget.items.length;
        _pageController.animateToPage(
          nextPage,
          duration: _transitionDuration,
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _cancelAutoSlideTimer() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = null;
  }

  void _onUserInteractionStart() {
    _isUserInteracting = true;
    _cancelAutoSlideTimer();
    _resumeTimer?.cancel();
  }

  void _onUserInteractionEnd() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(_resumeDelay, () {
      if (mounted) {
        setState(() {
          _isUserInteracting = false;
        });
        _checkAndStartAutoSlide();
      }
    });
  }

  void _onMouseEnter() {
    _isHovered = true;
    _cancelAutoSlideTimer();
    _resumeTimer?.cancel();
  }

  void _onMouseExit() {
    _isHovered = false;
    _resumeTimer?.cancel();
    _resumeTimer = Timer(_resumeDelay, () {
      if (mounted) {
        _checkAndStartAutoSlide();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isPausedByLifecycle = false;
      _onUserInteractionEnd();
    } else {
      _isPausedByLifecycle = true;
      _cancelAutoSlideTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelAutoSlideTimer();
    _resumeTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    Widget carousel = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: widget.height,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                if (notification.dragDetails != null) {
                  _onUserInteractionStart();
                }
              } else if (notification is ScrollEndNotification) {
                _onUserInteractionEnd();
              }
              return false;
            },
            child: MouseRegion(
              onEnter: (_) => _onMouseEnter(),
              onExit: (_) => _onMouseExit(),
              child: Listener(
                onPointerDown: (_) => _onUserInteractionStart(),
                onPointerUp: (_) => _onUserInteractionEnd(),
                onPointerCancel: (_) => _onUserInteractionEnd(),
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                      PointerDeviceKind.stylus,
                    },
                  ),
                  child: PageView.builder(
                    controller: _pageController,
                    padEnds: false,
                    physics: const BouncingScrollPhysics(),
                    itemCount: widget.items.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                      widget.onPageChanged?.call(index);
                    },
                    itemBuilder: (context, index) {
                      return widget.itemBuilder(
                          context, widget.items[index], index);
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.showDots && widget.items.length > 1) ...[
          const SizedBox(height: 10),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.items.length, (i) {
                final isActive = i == _currentPage;
                return GestureDetector(
                  onTap: () {
                    _pageController.jumpToPage(i);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.emerald
                          : AppColors.border.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ],
    );

    return carousel;
  }
}

/// Shimmer loader placeholder matching the carousel layout
class HorizontalRecommendationCarouselShimmer extends StatelessWidget {
  final double height;
  const HorizontalRecommendationCarouselShimmer({
    super.key,
    this.height = 208.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 20, right: 6),
        itemCount: 2,
        itemBuilder: (context, index) {
          final screenWidth = MediaQuery.sizeOf(context).width;
          final cardWidth = (screenWidth > 600) ? 350.0 : (screenWidth * 0.78);
          return Container(
            width: cardWidth,
            margin: const EdgeInsets.only(right: 14, top: 2, bottom: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ShimmerBox(width: 44, height: 44, borderRadius: 22),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 120, height: 14, borderRadius: 4),
                        SizedBox(height: 6),
                        ShimmerBox(width: 70, height: 10, borderRadius: 4),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 12),
                ShimmerBox(width: double.infinity, height: 50, borderRadius: 12),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(width: 80, height: 18, borderRadius: 9),
                    ShimmerBox(width: 100, height: 14, borderRadius: 4),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
