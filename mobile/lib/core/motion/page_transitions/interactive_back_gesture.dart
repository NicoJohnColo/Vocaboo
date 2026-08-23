import 'package:flutter/material.dart';
import '../motion_tokens.dart';

/// A controller that manages an interactive 1:1 drag gesture for popping a route.
class AppBackGestureController<T> {
  final AnimationController controller;
  final NavigatorState navigator;

  AppBackGestureController({
    required this.controller,
    required this.navigator,
  });

  /// Updates drag progress based on horizontal delta.
  void dragUpdate(double deltaFraction) {
    controller.value -= deltaFraction;
  }

  /// Completes or cancels the back navigation based on drag distance and release velocity.
  void dragEnd(double velocityPxPerSec, double viewWidth) {
    const double minFlingVelocity = 800.0;
    const double dismissThreshold = 0.35;

    // Positive velocity means flinging towards right (completing pop).
    final bool shouldPop = (velocityPxPerSec > minFlingVelocity) ||
        (controller.value < (1.0 - dismissThreshold) && velocityPxPerSec > -minFlingVelocity);

    if (shouldPop) {
      // Complete pop navigation smoothly with emphasized curve
      controller.animateTo(
        0.0,
        duration: AppDurations.short,
        curve: AppCurves.emphasizedDecelerate,
      ).then((_) {
        navigator.pop();
      });
    } else {
      // Snap back to 1.0 (canceling back navigation)
      controller.animateTo(
        1.0,
        duration: AppDurations.short,
        curve: AppCurves.springBack,
      );
    }
  }
}

/// An interactive edge-swipe gesture recognizer widget that wraps screens
/// allowing users to swipe from the left edge to pop the route interactively.
class AppInteractiveBackGestureDetector extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final VoidCallback? onBackInitiated;

  const AppInteractiveBackGestureDetector({
    super.key,
    required this.child,
    this.enabled = true,
    this.onBackInitiated,
  });

  @override
  State<AppInteractiveBackGestureDetector> createState() =>
      _AppInteractiveBackGestureDetectorState();
}

class _AppInteractiveBackGestureDetectorState
    extends State<AppInteractiveBackGestureDetector>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dragController;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _dragController = AnimationController(
      vsync: this,
      value: 1.0,
      duration: AppDurations.standard,
    );
  }

  @override
  void dispose() {
    _dragController.dispose();
    super.dispose();
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    // Only initiate swipe if touch begins in the left 40px edge zone
    if (details.globalPosition.dx > 44.0) return;
    if (!widget.enabled || !Navigator.of(context).canPop()) return;

    _isDragging = true;
    widget.onBackInitiated?.call();
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    final width = MediaQuery.of(context).size.width;
    if (width <= 0) return;

    final deltaFraction = details.primaryDelta! / width;
    _dragController.value = (_dragController.value - deltaFraction).clamp(0.0, 1.0);
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    final velocity = details.primaryVelocity ?? 0.0;
    const double minFlingVelocity = 750.0;
    const double dismissThreshold = 0.35;

    final bool shouldPop = (velocity > minFlingVelocity) ||
        (_dragController.value < (1.0 - dismissThreshold) && velocity > -minFlingVelocity);

    if (shouldPop) {
      _dragController.animateTo(
        0.0,
        duration: AppDurations.short,
        curve: AppCurves.emphasizedDecelerate,
      ).then((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    } else {
      _dragController.animateTo(
        1.0,
        duration: AppDurations.short,
        curve: AppCurves.springBack,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || AppMotion.isReducedMotion(context)) {
      return widget.child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _handleHorizontalDragStart,
      onHorizontalDragUpdate: _handleHorizontalDragUpdate,
      onHorizontalDragEnd: _handleHorizontalDragEnd,
      child: AnimatedBuilder(
        animation: _dragController,
        builder: (context, child) {
          final progress = 1.0 - _dragController.value;
          final offset = Offset(progress, 0.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Subtle scrim / backdrop dimming during edge drag
              if (progress > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.black.withValues(alpha: (1.0 - progress) * 0.15),
                    ),
                  ),
                ),
              FractionalTranslation(
                translation: offset,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: progress > 0
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 18,
                              spreadRadius: 2,
                              offset: const Offset(-4, 0),
                            ),
                          ]
                        : null,
                  ),
                  child: child,
                ),
              ),
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}
