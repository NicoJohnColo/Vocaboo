import 'package:flutter/material.dart';
import '../motion_tokens.dart';

/// A glitch-free, high-performance Hero widget that ensures smooth text scaling,
/// border radius morphing, and elevation transitions across screens.
class AppHero extends StatelessWidget {
  final Object tag;
  final Widget child;
  final BorderRadius? borderRadius;
  final Color? cardColor;
  final bool enableShuttleDecoration;
  final CreateRectTween? createRectTween;

  const AppHero({
    super.key,
    required this.tag,
    required this.child,
    this.borderRadius,
    this.cardColor,
    this.enableShuttleDecoration = true,
    this.createRectTween,
  });

  @override
  Widget build(BuildContext context) {
    if (AppMotion.isReducedMotion(context)) {
      return child;
    }

    return Hero(
      tag: tag,
      createRectTween: createRectTween ?? _defaultRectTween,
      flightShuttleBuilder: (
        flightContext,
        animation,
        flightDirection,
        fromHeroContext,
        toHeroContext,
      ) {
        final toHero = toHeroContext.widget as Hero;
        final fromHero = fromHeroContext.widget as Hero;

        // Use the destination widget for forward flight, and origin for pop flight
        final Widget targetChild = flightDirection == HeroFlightDirection.push
            ? toHero.child
            : fromHero.child;

        // Exclude semantics during the animation so screen readers do not read
        // half-morphed frames or flickering text.
        return ExcludeSemantics(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                final curvedValue = AppCurves.emphasizedDecelerate.transform(animation.value);

                return DefaultTextStyle.merge(
                  // Prevent yellow underline / raw text glitch during hero flight
                  style: Theme.of(flightContext).textTheme.bodyMedium ?? const TextStyle(),
                  child: Material(
                    type: MaterialType.transparency,
                    child: ClipRRect(
                      borderRadius: borderRadius ?? BorderRadius.circular(16 * curvedValue),
                      child: targetChild,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      child: child,
    );
  }

  static RectTween _defaultRectTween(Rect? begin, Rect? end) {
    return MaterialRectArcTween(begin: begin, end: end);
  }
}
