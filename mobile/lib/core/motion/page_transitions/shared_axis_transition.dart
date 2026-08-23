import 'package:flutter/material.dart';
import '../motion_tokens.dart';

/// The axis along which a Shared Axis transition occurs.
enum SharedAxisDirection {
  /// Horizontal movement: Left/Right transitions for sibling screens or horizontal tabs.
  horizontal,

  /// Vertical movement: Up/Down transitions for sequential steps (e.g. quiz or onboarding questions).
  vertical,

  /// Depth movement: Z-axis scaling for parent-child / detail drill-down navigation.
  depth,
}

/// A high-performance, Material 3 compliant Shared Axis transition widget.
///
/// Ensures compositor-friendly execution using [Transform] and [FadeTransition]
/// isolated within a [RepaintBoundary].
class AppSharedAxisTransition extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final SharedAxisDirection direction;
  final Widget child;
  final bool isForward;

  const AppSharedAxisTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.direction,
    required this.child,
    this.isForward = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool reducedMotion = AppMotion.isReducedMotion(context);

    if (reducedMotion) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.linear,
        ),
        child: child,
      );
    }

    switch (direction) {
      case SharedAxisDirection.horizontal:
        return _buildHorizontalTransition();
      case SharedAxisDirection.vertical:
        return _buildVerticalTransition();
      case SharedAxisDirection.depth:
        return _buildDepthTransition();
    }
  }

  Widget _buildHorizontalTransition() {
    // Incoming page: Slide in from 30dp offset + Fade in (first 35% of time).
    final slideIn = Tween<Offset>(
      begin: Offset(isForward ? 0.25 : -0.25, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: AppCurves.emphasizedDecelerate,
    ));

    final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
    ));

    // Outgoing page: Slide out slightly + Fade out (first 30% of time).
    final slideOut = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(isForward ? -0.15 : 0.15, 0.0),
    ).animate(CurvedAnimation(
      parent: secondaryAnimation,
      curve: AppCurves.emphasizedAccelerate,
    ));

    final fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(
      parent: secondaryAnimation,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    ));

    return RepaintBoundary(
      child: SlideTransition(
        position: slideOut,
        child: FadeTransition(
          opacity: fadeOut,
          child: SlideTransition(
            position: slideIn,
            child: FadeTransition(
              opacity: fadeIn,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalTransition() {
    // Sequential vertical flow (e.g. question to question).
    final slideIn = Tween<Offset>(
      begin: Offset(0.0, isForward ? 0.2 : -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: AppCurves.emphasizedDecelerate,
    ));

    final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    final slideOut = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(0.0, isForward ? -0.1 : 0.1),
    ).animate(CurvedAnimation(
      parent: secondaryAnimation,
      curve: AppCurves.emphasizedAccelerate,
    ));

    final fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(
      parent: secondaryAnimation,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    ));

    return RepaintBoundary(
      child: SlideTransition(
        position: slideOut,
        child: FadeTransition(
          opacity: fadeOut,
          child: SlideTransition(
            position: slideIn,
            child: FadeTransition(
              opacity: fadeIn,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDepthTransition() {
    // Parent-Child depth transition:
    // Incoming child screen zooms from 0.90x to 1.0x with slight upward elevation.
    final scaleIn = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: AppCurves.emphasizedDecelerate,
      ),
    );

    final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.55, curve: Curves.easeIn),
      ),
    );

    // Parent screen recedes (1.0 -> 0.96) and fades slightly (1.0 -> 0.80).
    final scaleOut = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: AppCurves.emphasizedAccelerate,
      ),
    );

    final fadeOut = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    return RepaintBoundary(
      child: ScaleTransition(
        scale: scaleOut,
        child: FadeTransition(
          opacity: fadeOut,
          child: ScaleTransition(
            scale: scaleIn,
            child: FadeTransition(
              opacity: fadeIn,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
