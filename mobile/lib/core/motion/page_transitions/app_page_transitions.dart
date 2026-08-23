import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../motion_tokens.dart';
import 'interactive_back_gesture.dart';
import 'shared_axis_transition.dart';

/// Navigation transition types defining the spatial relationship between screens.
enum AppMotionType {
  /// Sibling screens or horizontal tab flows (Material 3 Shared Axis X).
  sharedAxisX,

  /// Sequential step-by-step or quiz flows (Material 3 Shared Axis Y).
  sharedAxisY,

  /// Parent-to-child or detail drill-down navigation (Material 3 Shared Axis Z).
  /// Features layered forward depth zoom (0.92x -> 1.0x) on push, and quick pop.
  sharedAxisZ,

  /// Non-hierarchical top-level destinations (e.g. bottom nav items or settings tabs).
  fadeThrough,

  /// Full-screen or bottom sheet modal presentation with backdrop dimming.
  modalSheet,

  /// Platform-adaptive: Native Cupertino swipe-and-parallax on iOS, Material 3 Shared Axis on Android.
  cupertinoAdaptive,
}

/// Centralized transition builder factory for GoRouter and Navigator routes.
class AppPageTransitions {
  const AppPageTransitions._();

  /// Builds a GoRouter [CustomTransitionPage] with direction-aware motion,
  /// optimal curves, and platform-tailored physics.
  static CustomTransitionPage<T> page<T>({
    required Widget child,
    AppMotionType type = AppMotionType.sharedAxisZ,
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
        );
      },
    );
  }

  static Duration _getTransitionDuration(AppMotionType type) {
    switch (type) {
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
    // Reverse/back transitions are faster and lighter (lower commitment).
    switch (type) {
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
  }) {
    if (AppMotion.isReducedMotion(context)) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.linear),
        child: child,
      );
    }

    // Adapt based on platform if cupertinoAdaptive is requested
    final effectiveType = (type == AppMotionType.cupertinoAdaptive)
        ? (defaultTargetPlatform == TargetPlatform.iOS
            ? AppMotionType.cupertinoAdaptive
            : AppMotionType.sharedAxisZ)
        : type;

    switch (effectiveType) {
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

  /// Material 3 Fade Through: Elements fade out quickly, then incoming elements fade in and scale subtly.
  static Widget _buildFadeThrough(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.35, 1.0, curve: AppCurves.emphasizedDecelerate),
      ),
    );

    final scaleIn = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.35, 1.0, curve: AppCurves.emphasizedDecelerate),
      ),
    );

    final fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: const Interval(0.0, 0.35, curve: AppCurves.emphasizedAccelerate),
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
