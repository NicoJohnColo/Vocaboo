import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../motion_tokens.dart';
import 'interactive_back_gesture.dart';
import 'shared_axis_transition.dart';

/// Navigation transition types defining the spatial relationship between screens.
enum AppMotionType {
  /// Direction-aware 3D side slide transition (Moving left/right based on position/tab index without flicker).
  sideSlide,

  /// Sibling screens or horizontal tab flows (Material 3 Shared Axis X).
  sharedAxisX,

  /// Sequential step-by-step or quiz flows (Material 3 Shared Axis Y).
  sharedAxisY,

  /// Parent-to-child or detail drill-down navigation (Material 3 Shared Axis Z).
  sharedAxisZ,

  /// Non-hierarchical top-level destinations.
  fadeThrough,

  /// Full-screen or bottom sheet modal presentation with backdrop dimming.
  modalSheet,

  /// Platform-adaptive: Native Cupertino swipe-and-parallax on iOS, Shared Axis on Android.
  cupertinoAdaptive,
}

/// Global tracking of navigation history and spatial tab positions for direction-aware transitions.
class AppNavigationState {
  static String _previousPath = '/home';

  static const Map<String, double> routePositions = {
    '/': -1.0,
    '/login': -0.5,
    '/profile-setup': -0.3,
    '/pin-setup': -0.2,
    '/home': 0.0,
    '/category': 0.5,
    '/leaderboard': 1.0,
    '/sandbox': 1.5,
    '/dashboard': 2.0,
    '/wrong-answers': 2.2,
    '/progress': 2.5,
    '/settings': 3.0,
    '/language-preference': 3.2,
  };

  /// Determines if transitioning to [targetPath] moves forwards (right-to-left) or backwards (left-to-right).
  static bool isMovingForward(String targetPath) {
    final prevPos = _getRoutePosition(_previousPath);
    final targetPos = _getRoutePosition(targetPath);
    final isForward = targetPos >= prevPos;
    _previousPath = targetPath;
    return isForward;
  }

  static double _getRoutePosition(String path) {
    if (routePositions.containsKey(path)) {
      return routePositions[path]!;
    }
    for (final entry in routePositions.entries) {
      if (entry.key != '/' && path.startsWith(entry.key)) {
        return entry.value;
      }
    }
    if (path.startsWith('/category')) return 0.5;
    if (path.startsWith('/lesson') || path.startsWith('/session')) return 10.0;
    return 0.0;
  }
}

/// Centralized transition builder factory for GoRouter and Navigator routes.
class AppPageTransitions {
  const AppPageTransitions._();

  /// Builds a GoRouter [CustomTransitionPage] with direction-aware motion,
  /// optimal curves, and platform-tailored physics.
  static CustomTransitionPage<T> page<T>({
    required Widget child,
    AppMotionType type = AppMotionType.sideSlide,
    LocalKey? key,
    String? name,
    Object? arguments,
    String? restorationId,
    bool enableInteractiveBackGesture = true,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      name: name,
      arguments: arguments,
      restorationId: restorationId,
      transitionDuration: _getTransitionDuration(type),
      reverseTransitionDuration: _getReverseTransitionDuration(type),
      child: enableInteractiveBackGesture
          ? AppInteractiveBackGestureDetector(child: child)
          : child,
      transitionsBuilder: (context, animation, secondaryAnimation, childWidget) {
        return buildTransition(
          context: context,
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: childWidget,
          type: type,
          targetName: name,
        );
      },
    );
  }

  static Duration _getTransitionDuration(AppMotionType type) {
    switch (type) {
      case AppMotionType.sideSlide:
        return const Duration(milliseconds: 320);
      case AppMotionType.fadeThrough:
        return AppDurations.standard;
      case AppMotionType.modalSheet:
        return AppDurations.standard;
      case AppMotionType.sharedAxisX:
      case AppMotionType.sharedAxisY:
      case AppMotionType.sharedAxisZ:
      case AppMotionType.cupertinoAdaptive:
        return AppDurations.emphasized;
    }
  }

  static Duration _getReverseTransitionDuration(AppMotionType type) {
    switch (type) {
      case AppMotionType.sideSlide:
        return const Duration(milliseconds: 280);
      case AppMotionType.fadeThrough:
        return const Duration(milliseconds: 200);
      case AppMotionType.modalSheet:
        return const Duration(milliseconds: 250);
      case AppMotionType.sharedAxisX:
      case AppMotionType.sharedAxisY:
      case AppMotionType.sharedAxisZ:
      case AppMotionType.cupertinoAdaptive:
        return const Duration(milliseconds: 300);
    }
  }

  /// Builds the motion animation widget for a given [type].
  static Widget buildTransition({
    required BuildContext context,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
    required AppMotionType type,
    String? targetName,
  }) {
    if (AppMotion.isReducedMotion(context)) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.linear),
        child: child,
      );
    }

    switch (type) {
      case AppMotionType.sideSlide:
        final bool isForward = AppNavigationState.isMovingForward(targetName ?? '');
        return _buildSideSlide(animation, secondaryAnimation, child, isForward: isForward);

      case AppMotionType.sharedAxisX:
        return AppSharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          direction: SharedAxisDirection.horizontal,
          child: child,
        );

      case AppMotionType.sharedAxisY:
        return AppSharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          direction: SharedAxisDirection.vertical,
          child: child,
        );

      case AppMotionType.sharedAxisZ:
        return AppSharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          direction: SharedAxisDirection.depth,
          child: child,
        );

      case AppMotionType.fadeThrough:
        return _buildFadeThrough(animation, secondaryAnimation, child);

      case AppMotionType.modalSheet:
        return _buildModalSheet(animation, secondaryAnimation, child);

      case AppMotionType.cupertinoAdaptive:
        return _buildCupertinoParallax(animation, secondaryAnimation, child);
    }
  }

  /// Direction-Aware 3D Side Slide: Smooth physics slide from side based on position,
  /// with parallax trailing push and depth shadow (Zero flicker).
  static Widget _buildSideSlide(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child, {
    required bool isForward,
  }) {
    // Incoming page: Slides in from right if moving forward (+1.0) or left if moving backward (-1.0)
    final slideIn = Tween<Offset>(
      begin: Offset(isForward ? 1.0 : -1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Cubic(0.16, 1.0, 0.3, 1.0), // Fast out, ultra-smooth physical deceleration
        reverseCurve: const Cubic(0.3, 0.0, 0.8, 0.15),
      ),
    );

    // Outgoing page: Pushes slightly in the opposite direction (-0.25 if forward, +0.25 if backward)
    final slideOut = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(isForward ? -0.25 : 0.25, 0.0),
    ).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: const Cubic(0.16, 1.0, 0.3, 1.0),
        reverseCurve: const Cubic(0.3, 0.0, 0.8, 0.15),
      ),
    );

    // Subtle dim scrim on outgoing screen for depth continuity
    final dimScrim = Tween<double>(begin: 0.0, end: 0.06).animate(secondaryAnimation);

    return RepaintBoundary(
      child: SlideTransition(
        position: slideOut,
        child: AnimatedBuilder(
          animation: secondaryAnimation,
          builder: (context, currentChild) {
            if (secondaryAnimation.value > 0.01) {
              return Stack(
                children: [
                  currentChild!,
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: dimScrim.value),
                    ),
                  ),
                ],
              );
            }
            return currentChild!;
          },
          child: SlideTransition(
            position: slideIn,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: Offset(isForward ? -4 : 4, 0),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  /// Material 3 Fade Through: Smooth cross-dissolve with scale.
  static Widget _buildFadeThrough(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.1, 1.0, curve: Curves.easeOut),
      ),
    );

    final scaleIn = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    final fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    return RepaintBoundary(
      child: FadeTransition(
        opacity: fadeOut,
        child: FadeTransition(
          opacity: fadeIn,
          child: ScaleTransition(
            scale: scaleIn,
            child: child,
          ),
        ),
      ),
    );
  }

  /// Modal Sheet: Slide up from bottom with spring deceleration & synchronized backdrop dimming.
  static Widget _buildModalSheet(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slideIn = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: AppCurves.emphasizedDecelerate,
        reverseCurve: AppCurves.emphasizedAccelerate,
      ),
    );

    final scaleOut = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: AppCurves.emphasizedAccelerate,
      ),
    );

    return RepaintBoundary(
      child: ScaleTransition(
        scale: scaleOut,
        child: SlideTransition(
          position: slideIn,
          child: child,
        ),
      ),
    );
  }

  /// Cupertino Parallax Transition: Native iOS-style slide with 30% parallax drag on outgoing screen.
  static Widget _buildCupertinoParallax(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slideIn = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: AppCurves.emphasizedDecelerate,
      ),
    );

    final slideOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.30, 0.0),
    ).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: AppCurves.emphasizedAccelerate,
      ),
    );

    return RepaintBoundary(
      child: SlideTransition(
        position: slideOut,
        child: SlideTransition(
          position: slideIn,
          child: child,
        ),
      ),
    );
  }
}
