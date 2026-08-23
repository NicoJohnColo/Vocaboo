import 'package:flutter/material.dart';
import '../motion_tokens.dart';

typedef OpenContainerBuilder = Widget Function(BuildContext context, VoidCallback action);
typedef CloseContainerBuilder = Widget Function(BuildContext context, VoidCallback action);

/// A reusable Container Transform widget inspired by Material 3 Motion.
///
/// Seamlessly morphs a card / tile into a full-screen view or modal detail.
class AppContainerTransform extends StatefulWidget {
  final CloseContainerBuilder closedBuilder;
  final OpenContainerBuilder openBuilder;
  final Duration duration;
  final Duration reverseDuration;
  final ShapeBorder closedShape;
  final ShapeBorder openShape;
  final Color closedColor;
  final Color openColor;
  final double closedElevation;
  final double openElevation;

  const AppContainerTransform({
    super.key,
    required this.closedBuilder,
    required this.openBuilder,
    this.duration = AppDurations.emphasized,
    this.reverseDuration = const Duration(milliseconds: 300),
    this.closedShape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
    ),
    this.openShape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.zero,
    ),
    this.closedColor = Colors.white,
    this.openColor = Colors.white,
    this.closedElevation = 2.0,
    this.openElevation = 0.0,
  });

  @override
  State<AppContainerTransform> createState() => _AppContainerTransformState();
}

class _AppContainerTransformState extends State<AppContainerTransform> {
  void _openContainer() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: AppMotion.duration(context, widget.duration),
        reverseTransitionDuration: AppMotion.duration(context, widget.reverseDuration),
        pageBuilder: (context, animation, secondaryAnimation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final progress = CurvedAnimation(
                parent: animation,
                curve: AppCurves.emphasizedDecelerate,
                reverseCurve: AppCurves.emphasizedAccelerate,
              ).value;

              final shape = ShapeBorder.lerp(widget.closedShape, widget.openShape, progress)!;
              final elevation = widget.closedElevation + (widget.openElevation - widget.closedElevation) * progress;
              final color = Color.lerp(widget.closedColor, widget.openColor, progress)!;

              return Material(
                color: color,
                elevation: elevation,
                shape: shape,
                clipBehavior: Clip.antiAlias,
                child: Opacity(
                  opacity: progress.clamp(0.0, 1.0),
                  child: widget.openBuilder(context, () => Navigator.of(context).pop()),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.closedColor,
      elevation: widget.closedElevation,
      shape: widget.closedShape,
      clipBehavior: Clip.antiAlias,
      child: widget.closedBuilder(context, _openContainer),
    );
  }
}
