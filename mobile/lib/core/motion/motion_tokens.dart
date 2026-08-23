import 'package:flutter/material.dart';

/// Centralized Motion Design Tokens for the Vocaboo application.
///
/// Grounded in Material 3 Motion and iOS Human Interface Guidelines (HIG):
/// - Fast micro-interactions for tactile responsiveness (<200ms).
/// - Expressive, physical easing curves with natural deceleration.
/// - Layered transitions that preserve spatial continuity and user orientation.
/// - Automatic fallback for accessibility (Reduce Motion / `MediaQuery.disableAnimations`).
abstract class AppDurations {
  /// 100ms - Immediate feedback for micro-interactions:
  /// Button press-down, checkbox toggles, switch knob response.
  static const Duration micro = Duration(milliseconds: 100);

  /// 200ms - Small state transitions:
  /// Tooltip fade, chip selection, input focus border glow, badge scale-in.
  static const Duration short = Duration(milliseconds: 200);

  /// 300ms - Standard UI component transitions:
  /// Bottom sheet entry/exit, dialog popup, tab sliding indicator, toast slide.
  static const Duration standard = Duration(milliseconds: 300);

  /// 450ms - Emphasized screen-to-screen transitions & shared element morphs:
  /// Parent-child depth push/pop, container transforms, hero flight.
  static const Duration emphasized = Duration(milliseconds: 450);

  /// 550ms - Celebratory rewards for kids (ages 9-12):
  /// Correct answers, streak milestones, stars, badge unlocks.
  static const Duration celebratory = Duration(milliseconds: 550);

  /// 650ms - Ambient and multi-stage sequences:
  /// Shimmer sweeps, cold-start splash transitions.
  static const Duration long = Duration(milliseconds: 650);

  /// 900ms - Extended celebration or complex multi-step reveals.
  static const Duration veryLong = Duration(milliseconds: 900);
}

/// Centralized Animation Curves with physical easing.
abstract class AppCurves {
  /// Standard easing for subtle adjustments within screen boundaries.
  /// Cubic(0.2, 0.0, 0.0, 1.0) - Material 3 Standard.
  static const Curve standard = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Emphasized easing for elements entering or moving across major boundaries.
  /// Delivers a pronounced deceleration phase to guide eye movement smoothly.
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Emphasized deceleration for elements entering the viewport (cards, sheets, modals).
  /// Starts rapidly and gently settles into position (Material 3 Decelerate).
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);

  /// Emphasized acceleration for elements exiting the viewport.
  /// Leaves the screen quickly so it doesn't linger or block the next interaction.
  static const Curve emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);

  /// Tactile spring-back curve for button releases, bounce taps, and badge reveals.
  static const Curve springBack = Curves.easeOutBack;

  /// Celebratory curve for young learners (ages 9-12):
  /// Low-amplitude overshoot for a positive "yay" moment without cartoon jitter.
  static const Curve celebratory = Curves.easeOutBack;

  /// Expressive elastic curve for mascot reactions and celebratory achievements.
  static const Curve elastic = Curves.elasticOut;

  /// Smooth ease-in-out cubic curve.
  static const Curve easeInOutCubic = Curves.easeInOutCubic;
}

/// Central motion helper providing accessibility inspection, duration overrides,
/// and performance utilities.
class AppMotion {
  const AppMotion._();

  /// Determines if the user has requested reduced motion at the OS level.
  ///
  /// Checks both [MediaQueryData.disableAnimations] and [MediaQueryData.accessibleNavigation].
  static bool isReducedMotion(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery == null) return false;
    return mediaQuery.disableAnimations || mediaQuery.accessibleNavigation;
  }

  /// Returns [baseDuration] if animations are enabled, or [Duration.zero]
  /// (or [fallback]) if reduced motion is requested.
  static Duration duration(
    BuildContext context,
    Duration baseDuration, {
    Duration fallback = Duration.zero,
  }) {
    if (isReducedMotion(context)) {
      return fallback;
    }
    return baseDuration;
  }

  /// Returns [baseCurve] if animations are enabled, or [Curves.linear] if reduced motion is requested.
  static Curve curve(
    BuildContext context,
    Curve baseCurve, {
    Curve fallback = Curves.linear,
  }) {
    if (isReducedMotion(context)) {
      return fallback;
    }
    return baseCurve;
  }

  /// Pre-caches images for a smoother upcoming screen transition, preventing layout jank.
  static Future<void> precacheRouteImages(
    BuildContext context,
    List<ImageProvider> imageProviders,
  ) async {
    for (final provider in imageProviders) {
      await precacheImage(provider, context);
    }
  }
}
